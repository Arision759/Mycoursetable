/**
 * 桌面卡片数据服务
 * 职责：
 * - 初始化应用数据环境
 * - 根据当前设置、学期、课表计算下一节课程
 * - 生成仅包含基础类型字段的卡片数据，避免卡片页面直接依赖业务模型
 */
import { AppInitializer } from './AppInitializer';
import { TermService } from './TermService';
import { ScheduleService } from './ScheduleService';
import { SettingService } from './SettingService';
import { CourseEntity } from '../model/entity/CourseEntity';
import { DateUtil } from '../common/util/DateUtil';
import { Logger } from '../common/logger/Logger';
import { formBindingData, formInfo, formProvider } from '@kit.FormKit';

/**
 * 桌面卡片可序列化数据
 */
export class DesktopCardData {
  /** 是否已开启桌面提醒 */
  public reminderEnabled: boolean = false;

  /** 卡片标题 */
  public title: string = '下一节课';

  /** 下一节课课程名称 */
  public courseName: string = '';

  /** 上课时间，如 08:00 - 09:40 */
  public timeText: string = '--';

  /** 上课教室 */
  public locationText: string = '--';

  /** 授课老师 */
  public teacherText: string = '--';

  /** 提示语，当无课程或未开启时展示 */
  public message: string = '';

  /** 下一节课结束时间戳，用于安排下一次卡片刷新；0 表示无需安排 */
  public nextRefreshTimestamp: number = 0;
}

interface NextCourseInfo {
  course: CourseEntity;
  courseDate: Date;
}

export class DesktopCardService {
  private static readonly TAG: string = 'DesktopCardService';
  private static readonly MAX_SCAN_DAYS: number = 14;
  private static initialized: boolean = false;

  /**
   * 确保数据库与 Preferences 已初始化。
   * FormExtensionAbility 可能在应用主 Ability 之前被拉起，因此必须显式初始化。
   */
  public static async ensureInitialized(context: Context): Promise<void> {
    if (DesktopCardService.initialized) {
      return;
    }

    await AppInitializer.initialize(context);
    DesktopCardService.initialized = true;
  }

  /**
   * 构建卡片初始占位数据，用于 FormExtensionAbility 同步返回。
   */
  public static buildInitialCardData(): DesktopCardData {
    const data = new DesktopCardData();
    data.title = '下一节课';
    data.message = '正在加载…';
    return data;
  }

  /**
   * 构建卡片数据
   */
  public static async buildCardData(context: Context): Promise<DesktopCardData> {
    const data = new DesktopCardData();

    try {
      await DesktopCardService.ensureInitialized(context);

      const enabledResult = await SettingService.getInstance().isDesktopReminderEnabled();
      if (enabledResult.isSuccess()) {
        data.reminderEnabled = enabledResult.getData() ?? false;
      }

      if (!data.reminderEnabled) {
        data.title = '桌面提醒已关闭';
        data.message = '请在设置中开启后查看下一节课';
        return data;
      }

      const termResult = await TermService.getInstance().getCurrentTerm();
      if (!termResult.isSuccess() || !termResult.getData()) {
        data.message = '暂未设置当前学期';
        return data;
      }

      const term = termResult.getData()!;
      const now = new Date();
      const currentWeek = DateUtil.getCurrentWeek(term.startDate);

      if (currentWeek < 1) {
        data.message = '尚未开学';
        return data;
      }

      if (currentWeek > term.weekCount) {
        data.message = '学期已结束';
        return data;
      }

      const nextCourseInfo = await DesktopCardService.findNextCourse(term.id, term.startDate, term.weekCount, now);
      if (nextCourseInfo) {
        const nextCourse = nextCourseInfo.course;
        data.courseName = nextCourse.name.trim().length > 0 ? nextCourse.name : '未填写课程名称';
        data.timeText = `${nextCourse.startTime} - ${nextCourse.endTime}`;
        data.locationText = nextCourse.location.trim().length > 0 ? nextCourse.location : '未填写';
        data.teacherText = nextCourse.teacher.trim().length > 0 ? nextCourse.teacher : '未填写';
        data.nextRefreshTimestamp = DesktopCardService.buildCourseEndTimestamp(
          nextCourseInfo.courseDate,
          nextCourse.endTime
        );
      } else {
        data.message = '暂无下一节课';
      }

      return data;
    } catch (err) {
      Logger.error(
        DesktopCardService.TAG,
        Logger.formatMsg(DesktopCardService.TAG, 'buildCardData', '构建卡片数据异常: %{public}s'),
        JSON.stringify(err)
      );
      data.message = '数据加载失败';
      return data;
    }
  }

  /**
   * 主动刷新当前应用已发布的所有桌面卡片。
   * 用于设置页修改桌面提醒开关后立即生效。
   */
  public static async refreshAllCards(context: Context): Promise<void> {
    try {
      const cardData = await DesktopCardService.buildCardData(context);
      const forms: formInfo.RunningFormInfo[] = await formProvider.getPublishedRunningFormInfos();
      const bindingData = formBindingData.createFormBindingData(cardData);

      for (let i = 0; i < forms.length; i++) {
        const formId = forms[i].formId;
        if (formId) {
          await formProvider.updateForm(formId, bindingData);

          const delayMinutes = DesktopCardService.getNextRefreshDelayMinutes(
            cardData.nextRefreshTimestamp,
            Date.now()
          );
          if (delayMinutes > 0) {
            try {
              await formProvider.setFormNextRefreshTime(formId, delayMinutes);
            } catch (scheduleErr) {
              Logger.warn(
                DesktopCardService.TAG,
                Logger.formatMsg(DesktopCardService.TAG, 'refreshAllCards', '安排下次刷新失败，卡片将等待系统下次更新'),
                JSON.stringify(scheduleErr)
              );
            }
          }
        }
      }

      Logger.info(
        DesktopCardService.TAG,
        Logger.formatMsg(DesktopCardService.TAG, 'refreshAllCards', `已刷新卡片数量: ${forms.length}`)
      );
    } catch (err) {
      Logger.error(
        DesktopCardService.TAG,
        Logger.formatMsg(DesktopCardService.TAG, 'refreshAllCards', '刷新桌面卡片异常: %{public}s'),
        JSON.stringify(err)
      );
    }
  }

  /**
   * 查找最近可上课程。
   * 最多扫描 14 天，兼顾查询开销与跨周末/考试周场景。
   */
  private static async findNextCourse(
    termId: string,
    termStartDate: number,
    weekCount: number,
    now: Date
  ): Promise<NextCourseInfo | null> {
    const maxDays = Math.min(DesktopCardService.MAX_SCAN_DAYS, weekCount * 7);
    const currentMinutes = now.getHours() * 60 + now.getMinutes();

    for (let offset = 0; offset < maxDays; offset++) {
      const date = new Date(now.getTime() + offset * 24 * 60 * 60 * 1000);
      const week = DateUtil.getCurrentWeek(termStartDate, date.getTime());

      if (week < 1 || week > weekCount) {
        continue;
      }

      const dayOfWeek = date.getDay() === 0 ? 7 : date.getDay();
      const dayResult = await ScheduleService.getInstance().getDayCourses(termId, week, dayOfWeek);

      if (!dayResult.isSuccess() || !dayResult.getData()) {
        continue;
      }

      const courses = dayResult.getData()!
        .filter((course: CourseEntity): boolean => {
          return DesktopCardService.isWeekMatched(course, week);
        })
        .sort((a: CourseEntity, b: CourseEntity): number => {
          return DesktopCardService.timeToMinutes(a.startTime) - DesktopCardService.timeToMinutes(b.startTime);
        });

      for (const course of courses) {
        if (offset === 0) {
          const endMinutes = DesktopCardService.timeToMinutes(course.endTime);
          if (endMinutes <= currentMinutes) {
            continue;
          }
        }
        return {
          course,
          courseDate: date
        };
      }
    }

    return null;
  }

  /**
   * 将课程日期与 HH:mm 结束时间合并为时间戳。
   */
  private static buildCourseEndTimestamp(courseDate: Date, endTime: string): number {
    const endMinutes = DesktopCardService.timeToMinutes(endTime);
    if (endMinutes === Number.MAX_SAFE_INTEGER) {
      return 0;
    }

    const endDate = new Date(courseDate.getTime());
    endDate.setHours(0, 0, 0, 0);
    return endDate.getTime() + endMinutes * 60 * 1000;
  }

  /**
   * 计算距下次刷新需要等待的分钟数。
   * 系统要求 setFormNextRefreshTime 的最小值为 5 分钟。
   */
  public static getNextRefreshDelayMinutes(nextRefreshTimestamp: number, now: number): number {
    if (nextRefreshTimestamp <= now) {
      return 0;
    }
    const minutes = Math.ceil((nextRefreshTimestamp - now) / 60000);
    return Math.max(5, minutes);
  }

  /**
   * 校验课程是否在本周有效。
   * 周类型：0=每周，1=单周，2=双周。
   */
  private static isWeekMatched(course: CourseEntity, week: number): boolean {
    if (week < course.startWeek || week > course.endWeek) {
      return false;
    }

    if (course.weekType === 1 && week % 2 === 0) {
      return false;
    }

    if (course.weekType === 2 && week % 2 !== 0) {
      return false;
    }

    return true;
  }

  /**
   * 将 HH:mm 转为当天分钟数，解析失败时返回极大值以排到后面。
   */
  private static timeToMinutes(time: string): number {
    const parts = time.split(':');
    if (parts.length !== 2) {
      return Number.MAX_SAFE_INTEGER;
    }

    const hour = Number(parts[0]);
    const minute = Number(parts[1]);
    if (Number.isNaN(hour) || Number.isNaN(minute)) {
      return Number.MAX_SAFE_INTEGER;
    }

    return hour * 60 + minute;
  }
}
