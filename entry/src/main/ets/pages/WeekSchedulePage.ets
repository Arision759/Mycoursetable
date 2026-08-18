/**
 * 周课表主页面
 * 核心：Grid + onGetRectByIndex 实现课表布局
 */
import { CourseCard } from '../components/CourseCard';
import { CourseCardItem } from '../viewmodel/CourseCardItem';
import { SectionLabel } from '../viewmodel/SectionLabel';
import { WeekScheduleViewModel } from '../viewmodel/WeekScheduleViewModel';
import { ScheduleConstants } from '../constants/ScheduleConstants';
import { Logger } from '../common/logger/Logger';
import { CourseDetailDialog } from '../components/CourseDetailDialog';
import { CourseDetailItem } from '../viewmodel/CourseDetailItem';
import { TimeTableParser } from '../utils/TimeTableParser';
import router from '@ohos.router';
import { ScheduleService } from '../service/ScheduleService';
import { TermService } from '../service/TermService';
import { CourseEntity } from '../model/entity/CourseEntity';
import { DateUtil } from '../common/util/DateUtil';

@Entry
@ComponentV2
struct WeekSchedulePage {
  // ViewModel
  private viewModel: WeekScheduleViewModel = new WeekScheduleViewModel();

  // 状态
  @Local courses: CourseCardItem[] = [];
  @Local sectionLabels: SectionLabel[] = [];
  @Local currentWeek: number = 1;
  @Local weekDateRange: string = '';
  @Local termNameLine1: string = '';
  @Local termNameLine2: string = '';
  @Local dayDates: string[] = [];
  @Local isLoading: boolean = true;
  private dialogController: CustomDialogController | null = null;
  private hasShown: boolean = false;

  // 布局常量
  private readonly SECTION_HEIGHT = ScheduleConstants.SECTION_HEIGHT;
  private readonly GAP = ScheduleConstants.GAP;
  private readonly DAY_COUNT = ScheduleConstants.DAY_COUNT;
  private readonly SECTION_COUNT = ScheduleConstants.SECTION_COUNT;

  async aboutToAppear() {
    Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'aboutToAppear', '页面初始化'));

    // ✅ 临时注释掉，避免干扰真实导入测试
    // await this.insertTestData();

    // 1. 生成时间轴标签
    this.sectionLabels = this.viewModel.generateSectionLabels();

    // 2. 获取当前周次
    const currentWeek = await this.viewModel.getCurrentWeek();

    // 3. 决定显示哪一周
    // - 如果未开学（currentWeek <= 0），默认显示第1周
    // - 如果已开学，显示当前周
    // - 用户可以随时切换到任意周
    if (currentWeek > 0) {
      this.currentWeek = currentWeek;
    } else {
      this.currentWeek = 1;
      Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'aboutToAppear',
        '未开学，默认显示第1周（用户可切换到任意周查看课程）'));
    }

    // 4. 加载课程
    await this.loadWeek(this.currentWeek);

    this.isLoading = false;
  }

  /**
   * 加载指定周的课程
   */
  private async loadWeek(week: number) {
    Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'loadWeek', `加载第${week}周`));

    this.isLoading = true;

    // 加载课程数据
    this.courses = await this.viewModel.loadWeekCourses(week);

    // 获取日期范围
    this.weekDateRange = await this.viewModel.getWeekDateRange(week);

    // 刷新学期名和每天对应的日期
    await this.updateTermName();
    await this.updateDayDates(week);

    this.isLoading = false;
  }

  /**
   * 页面重新显示时触发（含从设置页返回）
   * 开学日期/学期可能在设置页被修改，需要刷新
   */
  onPageShow() {
    // 首次显示由 aboutToAppear 负责加载，这里只处理从其他页面返回的刷新
    if (this.hasShown) {
      this.refreshAll();
    }
    this.hasShown = true;
  }

  /**
   * 从设置页返回后刷新全部数据
   */
  private async refreshAll() {
    Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'refreshAll', '设置可能已变更，刷新页面'));

    // 重新计算当前周（开学日期可能已修改）
    const currentWeek = await this.viewModel.getCurrentWeek();
    this.currentWeek = currentWeek > 0 ? currentWeek : 1;

    await this.loadWeek(this.currentWeek);
  }

  /**
   * 更新学期名称（左上角两行小字显示）
   * 拆分规则："2026-2027学年第1学期" → "2026-2027" / "学年第1学期"
   */
  private async updateTermName() {
    const result = await TermService.getInstance().getCurrentTerm();
    if (result.isSuccess() && result.getData()) {
      const name = result.getData()!.name;
      const idx = name.indexOf('学年');
      if (idx > 0) {
        this.termNameLine1 = name.substring(0, idx);
        this.termNameLine2 = name.substring(idx);
      } else {
        // 名称中不含"学年"时退化为单行显示
        this.termNameLine1 = name;
        this.termNameLine2 = '';
      }
    }
  }

  /**
   * 计算当前显示周每天对应的日期（如 9.1）
   */
  private async updateDayDates(week: number) {
    const result = await TermService.getInstance().getCurrentTerm();
    if (!result.isSuccess() || !result.getData()) {
      this.dayDates = [];
      return;
    }

    const startDate = result.getData()!.startDate;
    const dates: string[] = [];
    for (let d = 1; d <= 7; d++) {
      const ts = DateUtil.getDateByWeekAndDay(startDate, week, d);
      const dt = new Date(ts);
      dates.push(`${dt.getMonth() + 1}.${dt.getDate()}`);
    }
    this.dayDates = dates;
  }

  /**
   * 切换到上一周
   */
  private async previousWeek() {
    if (this.currentWeek > 1) {
      this.currentWeek--;
      await this.loadWeek(this.currentWeek);
    }
  }

  /**
   * 切换到下一周
   */
  private async nextWeek() {
    if (this.currentWeek < 20) {
      this.currentWeek++;
      await this.loadWeek(this.currentWeek);
    }
  }

  /**
   * 临时：插入测试数据
   */
  private async insertTestData() {
    try {
      const scheduleService = ScheduleService.getInstance();

      // 检查是否已有数据
      const termResult = await TermService.getInstance().getCurrentTerm();
      if (!termResult.isSuccess() || !termResult.getData()) {
        Logger.error('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'insertTestData', '未找到学期数据'));
        return;
      }

      const termId = termResult.getData()!.id;

      // 插入测试课程
      const testCourses: CourseEntity[] = [];

      const course1 = new CourseEntity();
      course1.termId = termId;
      course1.name = '高等数学Ⅱ';
      course1.teacher = '韩少锋';
      course1.dayOfWeek = 1;
      course1.startSection = 3;
      course1.endSection = 4;
      course1.startTime = '10:25';
      course1.endTime = '12:00';
      course1.startWeek = 1;
      course1.endWeek = 16;
      course1.location = '明远楼 WH1102';
      course1.color = '#FF6B9D';
      course1.weekType = 0;
      course1.sourceType = 0;
      course1.createdAt = Date.now();
      course1.updatedAt = Date.now();
      testCourses.push(course1);

      const course2 = new CourseEntity();
      course2.termId = termId;
      course2.name = '大学英语';
      course2.teacher = '王娟';
      course2.dayOfWeek = 1;
      course2.startSection = 1;
      course2.endSection = 2;
      course2.startTime = '08:30';
      course2.endTime = '10:05';
      course2.startWeek = 1;
      course2.endWeek = 16;
      course2.location = '唐韵楼 TH1014';
      course2.color = '#6BB6FF';
      course2.weekType = 0;
      course2.sourceType = 0;
      course2.createdAt = Date.now();
      course2.updatedAt = Date.now();
      testCourses.push(course2);

      const course3 = new CourseEntity();
      course3.termId = termId;
      course3.name = '数据结构';
      course3.teacher = '李耀,丁明海';
      course3.dayOfWeek = 2;
      course3.startSection = 3;
      course3.endSection = 4;
      course3.startTime = '10:25';
      course3.endTime = '12:00';
      course3.startWeek = 1;
      course3.endWeek = 16;
      course3.location = '明远楼 WH1403';
      course3.color = '#FFA36C';
      course3.weekType = 0;
      course3.sourceType = 0;
      course3.createdAt = Date.now();
      course3.updatedAt = Date.now();
      testCourses.push(course3);

      const course4 = new CourseEntity();
      course4.termId = termId;
      course4.name = '大学物理';
      course4.teacher = '张教授';
      course4.dayOfWeek = 3;
      course4.startSection = 5;
      course4.endSection = 6;
      course4.startTime = '14:00';
      course4.endTime = '15:35';
      course4.startWeek = 1;
      course4.endWeek = 16;
      course4.location = '明远楼 WH2201';
      course4.color = '#6BCF7F';
      course4.weekType = 0;
      course4.sourceType = 0;
      course4.createdAt = Date.now();
      course4.updatedAt = Date.now();
      testCourses.push(course4);

      const course5 = new CourseEntity();
      course5.termId = termId;
      course5.name = '体育';
      course5.teacher = '刘教练';
      course5.dayOfWeek = 4;
      course5.startSection = 5;
      course5.endSection = 6;
      course5.startTime = '14:00';
      course5.endTime = '15:35';
      course5.startWeek = 1;
      course5.endWeek = 16;
      course5.location = '体育馆 操场';
      course5.color = '#A78BFA';
      course5.weekType = 0;
      course5.sourceType = 0;
      course5.createdAt = Date.now();
      course5.updatedAt = Date.now();
      testCourses.push(course5);

      const course6 = new CourseEntity();
      course6.termId = termId;
      course6.name = '计算机网络';
      course6.teacher = '王老师';
      course6.dayOfWeek = 5;
      course6.startSection = 1;
      course6.endSection = 2;
      course6.startTime = '08:30';
      course6.endTime = '10:05';
      course6.startWeek = 1;
      course6.endWeek = 16;
      course6.location = '明远楼 WH1501';
      course6.color = '#FB7185';
      course6.weekType = 0;
      course6.sourceType = 0;
      course6.createdAt = Date.now();
      course6.updatedAt = Date.now();
      testCourses.push(course6);

      for (const course of testCourses) {
        await scheduleService.insertCourse(course);
      }

      Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'insertTestData', '测试数据插入完成'));
    } catch (err) {
      Logger.error('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'insertTestData', '插入测试数据失败: %{public}s'), JSON.stringify(err));
    }
  }

  /**
   * 计算网格总高度
   */
  private gridHeight(): number {
    return this.SECTION_COUNT * this.SECTION_HEIGHT + (this.SECTION_COUNT - 1) * this.GAP;
  }

  /**
   * 处理课程卡片点击
   */
  private handleCourseClick(courseId: string) {
    Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'handleCourseClick', `点击课程：${courseId}`));

    // 查找课程
    const course = this.courses.find(c => c.id === courseId);
    if (!course) {
      return;
    }

    // 构建详情数据
    const detail: CourseDetailItem = {
      courseName: course.name,
      courseCode: '', // TODO: 从数据库查询完整信息
      teachers: course.teacher,
      dayOfWeek: this.getDayOfWeekText(course.dayOfWeek),
      sectionRange: `第${course.startSection}-${course.endSection}节`,
      timeRange: `${TimeTableParser.getStartTime(course.startSection)}-${TimeTableParser.getEndTime(course.endSection)}`,
      weekRange: `${course.startWeek}-${course.endWeek}周`,
      classrooms: [course.room]
    };

    // 显示弹窗
    this.dialogController = new CustomDialogController({
      builder: CourseDetailDialog({ detail: detail }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });

    this.dialogController.open();
  }

  /**
   * 获取星期几文字
   */
  private getDayOfWeekText(dayOfWeek: number): string {
    const days = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return days[dayOfWeek] || '';
  }

  build() {
    Column() {
      // 顶部栏
      this.buildTopBar();

      // 日期行
      this.buildDateRow();

      if (this.isLoading) {
        // 加载中
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 课表内容
        this.buildScheduleContent();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  /**
   * 顶部栏：周次切换 + 设置按钮
   */
  @Builder
  buildTopBar() {
    Row() {
      // 左上角：学期名称（两行小字显示，如 2026-2027 / 学年第1学期）
      Column({ space: 1 }) {
        Text(this.termNameLine1)
          .fontSize(10)
          .fontColor('#999999')

        if (this.termNameLine2.length > 0) {
          Text(this.termNameLine2)
            .fontSize(10)
            .fontColor('#999999')
        }
      }
      .alignItems(HorizontalAlign.Start)

      // 上一周按钮
      Button('◀')
        .fontSize(20)
        .backgroundColor(Color.Transparent)
        .fontColor('#333333')
        .onClick(() => this.previousWeek())

      // 周次信息
      Column() {
        Text(`第${this.currentWeek}周`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)

        if (this.weekDateRange) {
          Text(this.weekDateRange)
            .fontSize(12)
            .fontColor('#666666')
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Center)

      // 下一周按钮
      Button('▶')
        .fontSize(20)
        .backgroundColor(Color.Transparent)
        .fontColor('#333333')
        .onClick(() => this.nextWeek())

      // 导入按钮（点击后选择学校 → 登录导入课表）
      Button('📥')
        .fontSize(20)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'onClick', '打开学校选择页'));
          router.pushUrl({ url: 'pages/SchoolSelectPage' });
        })

      // 设置按钮
      Button('⚙️')
        .fontSize(20)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          Logger.info('WeekSchedulePage', Logger.formatMsg('WeekSchedulePage', 'onClick', '打开设置页面'));
          router.pushUrl({ url: 'pages/SettingsPage' });
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .backgroundColor(Color.White)
  }

  /**
   * 日期行：周一到周日（下方显示该周对应的日期，如 9.1）
   */
  @Builder
  buildDateRow() {
    Row() {
      // 左侧占位（对齐时间轴）
      Text('')
        .width(ScheduleConstants.TIME_COLUMN_WIDTH)

      // 周一到周日
      ForEach(['一', '二', '三', '四', '五', '六', '日'], (day: string, index: number) => {
        Column({ space: 2 }) {
          Text(day)
            .fontSize(14)
            .fontColor('#666666')

          if (this.dayDates.length === 7) {
            Text(this.dayDates[index])
              .fontSize(10)
              .fontColor('#999999')
          }
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      })
    }
    .width('100%')
    .height(52)
    .backgroundColor(Color.White)
  }

  /**
   * 课表内容：时间轴 + 课程网格
   */
  @Builder
  buildScheduleContent() {
    Scroll() {
      Row({ space: 8 }) {
        // 左侧时间轴
        Column({ space: this.GAP }) {
          ForEach(this.sectionLabels, (label: SectionLabel) => {
            Column() {
              Text(label.section.toString())
                .fontSize(12)
                .fontColor('#999999')

              Text(label.startTime)
                .fontSize(10)
                .fontColor('#CCCCCC')
            }
            .width(ScheduleConstants.TIME_COLUMN_WIDTH)
            .height(this.SECTION_HEIGHT)
            .justifyContent(FlexAlign.Center)
          })
        }

        // 右侧课程区域：使用 Stack + RelativeContainer 实现绝对定位
        Stack() {
          // 背景网格（用于显示分隔线和空白格子）
          Column({ space: this.GAP }) {
            ForEach(Array.from({ length: this.SECTION_COUNT }), (_: number, sectionIndex: number) => {
              Row({ space: this.GAP }) {
                ForEach(Array.from({ length: this.DAY_COUNT }), (_: number, dayIndex: number) => {
                  Column()
                    .layoutWeight(1)
                    .height(this.SECTION_HEIGHT)
                    .backgroundColor('#FAFAFA')
                    .borderRadius(4)
                })
              }
              .width('100%')
            })
          }
          .width('100%')

          // 课程卡片层（绝对定位）
          ForEach(this.courses, (course: CourseCardItem, index: number) => {
            CourseCard({
              course: course,
              onCardClick: (id: string): void => this.handleCourseClick(id)
            })
              .position(this.calculateCardPosition(course))
              .width(`${100 / this.DAY_COUNT - 0.5}%`) // 每列占 1/7，减去间隙
              .height(this.calculateCardHeight(course))
              .zIndex(10) // 确保在背景网格之上
          }, (course: CourseCardItem) => course.id)
        }
        .width('100%')
        .height(this.gridHeight())
        .layoutWeight(1)
        .alignContent(Alignment.TopStart)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
      .padding({ left: 8, right: 8, bottom: 16 })
    }
    .scrollBar(BarState.Auto)
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 计算课程卡片位置（百分比）
   */
  private calculateCardPosition(course: CourseCardItem): Position {
    const columnIndex = course.dayOfWeek - 1; // 0-based
    const rowIndex = course.startSection - 1; // 0-based

    // 计算左侧位置（百分比）
    const leftPercent = (columnIndex * 100) / this.DAY_COUNT;

    // 计算顶部位置（像素）
    const topPixels = rowIndex * (this.SECTION_HEIGHT + this.GAP);

    return {
      x: `${leftPercent}%`,
      y: topPixels
    };
  }

  /**
   * 计算课程卡片高度
   */
  private calculateCardHeight(course: CourseCardItem): number {
    const sectionSpan = course.endSection - course.startSection + 1;
    return sectionSpan * this.SECTION_HEIGHT + (sectionSpan - 1) * this.GAP;
  }
}
