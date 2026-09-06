/**
 * 周课表 ViewModel
 * 职责：
 * - 加载课程数据
 * - 生成 UI 快照
 * - 周次切换
 */
import { CourseCardItem } from './CourseCardItem';
import { SectionLabel } from './SectionLabel';
import { ScheduleService } from '../service/ScheduleService';
import { TermService } from '../service/TermService';
import { CourseEntity } from '../model/entity/CourseEntity';
import { Logger } from '../common/logger/Logger';
import { TimeTableParser } from '../utils/TimeTableParser';
import { ScheduleConstants } from '../constants/ScheduleConstants';
import { DateUtil } from '../common/util/DateUtil';

export class WeekScheduleViewModel {
  private scheduleService: ScheduleService;
  private termService: TermService;

  constructor() {
    this.scheduleService = ScheduleService.getInstance();
    this.termService = TermService.getInstance();
  }

  /**
   * 加载指定周的课程快照
   */
  public async loadWeekCourses(week: number): Promise<CourseCardItem[]> {
    try {
      Logger.info(
        'WeekScheduleViewModel',
        Logger.formatMsg('WeekScheduleViewModel', 'loadWeekCourses', `加载第${week}周课程`)
      );

      // 1. 获取当前学期
      const termResult = await this.termService.getCurrentTerm();
      if (!termResult.isSuccess() || !termResult.getData()) {
        Logger.error(
          'WeekScheduleViewModel',
          Logger.formatMsg('WeekScheduleViewModel', 'loadWeekCourses', '未找到当前学期')
        );
        return [];
      }

      const termId = termResult.getData()!.id;

      // 2. 查询课程
      const coursesResult = await this.scheduleService.getWeekCourses(termId, week);
      if (!coursesResult.isSuccess() || !coursesResult.getData()) {
        Logger.error(
          'WeekScheduleViewModel',
          Logger.formatMsg('WeekScheduleViewModel', 'loadWeekCourses', '查询课程失败')
        );
        return [];
      }

      const courses = coursesResult.getData()!;

      // 打印前3门课程的详细信息（调试用）
      if (courses.length > 0) {
        const sample = courses.slice(0, 3);
        for (const c of sample) {
          Logger.info('WeekScheduleViewModel',
            Logger.formatMsg('WeekScheduleViewModel', 'loadWeekCourses',
              `📝 ${c.name} | 周${c.dayOfWeek} ${c.startSection}-${c.endSection}节 | ${c.startWeek}-${c.endWeek}周`));
        }
      }

      // 3. 转换为 UI 快照
      const cards: CourseCardItem[] = courses.map(entity => this.toCardItem(entity, week));

      Logger.info(
        'WeekScheduleViewModel',
        Logger.formatMsg('WeekScheduleViewModel', 'loadWeekCourses', `第${week}周共${cards.length}门课程`)
      );

      return cards;
    } catch (err) {
      Logger.error(
        'WeekScheduleViewModel',
        Logger.formatMsg('WeekScheduleViewModel', 'loadWeekCourses', '加载课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return [];
    }
  }

  /**
   * 将 CourseEntity 转换为 CourseCardItem
   */
  private toCardItem(entity: CourseEntity, currentWeek: number): CourseCardItem {
    // 判断是否本周课程
    const isCurrentWeek = currentWeek >= entity.startWeek && currentWeek <= entity.endWeek;

    const card: CourseCardItem = {
      id: entity.id,
      name: entity.name,
      teacher: entity.teacher || '',
      room: entity.location || '',
      dayOfWeek: entity.dayOfWeek,
      startSection: entity.startSection,
      endSection: entity.endSection,
      startWeek: entity.startWeek,
      endWeek: entity.endWeek,
      color: entity.color,
      isCurrentWeek: isCurrentWeek
    };

    // 🔍 详细日志：输出每个字段
    Logger.info(
      'WeekScheduleViewModel',
      Logger.formatMsg('WeekScheduleViewModel', 'toCardItem',
        `📦 ${card.name} | 周${card.dayOfWeek} | 节次: ${card.startSection}-${card.endSection} | 周范围: ${entity.startWeek}-${entity.endWeek}`)
    );

    return card;
  }

  /**
   * 生成时间轴标签
   */
  public generateSectionLabels(): SectionLabel[] {
    const labels: SectionLabel[] = [];

    for (let i = 1; i <= ScheduleConstants.SECTION_COUNT; i++) {
      labels.push({
        section: i,
        startTime: TimeTableParser.getStartTime(i)
      });
    }

    return labels;
  }

  /**
   * 获取当前周次
   */
  public async getCurrentWeek(): Promise<number> {
    const result = await this.termService.getCurrentWeek();
    return result.isSuccess() ? result.getData()! : 1;
  }

  /**
   * 获取周次日期范围
   * @param week - 周次
   * @returns "9.15-9.21"
   */
  public async getWeekDateRange(week: number): Promise<string> {
    const result = await this.termService.getWeekDateRange(week);

    if (result.isSuccess() && result.getData()) {
      const start = result.getData()!.start;
      const end = result.getData()!.end;

      const startDate = new Date(start);
      const endDate = new Date(end);

      return `${startDate.getMonth() + 1}.${startDate.getDate()}-${endDate.getMonth() + 1}.${endDate.getDate()}`;
    }

    return '';
  }
}
