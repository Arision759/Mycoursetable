/**
 * 课表常量
 */
export class ScheduleConstants {
  // 布局常量
  static readonly SECTION_COUNT: number = 12;          // 一天12节课
  static readonly DAY_COUNT: number = 7;               // 一周7天
  static readonly SECTION_HEIGHT: number = 56;         // 每节课高度（vp）
  static readonly TIME_COLUMN_WIDTH: number = 44;      // 时间轴宽度（vp）
  static readonly GAP: number = 4;                     // 网格间距（vp）

  // 颜色常量
  static readonly GRID_LINE_COLOR: string = '#E0E0E0'; // 网格线颜色
  static readonly CURRENT_DAY_BG: string = '#F5F9FF';  // 今日列背景色
  static readonly NON_WEEK_OPACITY: number = 0.55;     // 非本周课程透明度
}
