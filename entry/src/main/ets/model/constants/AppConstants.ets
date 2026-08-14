/**
 * 应用全局常量定义
 */

/**
 * 数据库相关常量
 */
export class DbConstants {
  /** 数据库名称 */
  public static readonly DB_NAME: string = 'schedule.db';

  /** 数据库版本 */
  public static readonly DB_VERSION: number = 1;

  /** 数据库加密密钥（空表示不加密） */
  public static readonly DB_ENCRYPT_KEY: Uint8Array = new Uint8Array(0);
}

/**
 * 表名常量
 */
export class TableName {
  public static readonly SCHOOL: string = 'school';
  public static readonly TERM: string = 'term';
  public static readonly COURSE: string = 'course';
}

/**
 * Preferences 键名常量
 */
export class PrefsKey {
  /** 当前学期ID */
  public static readonly CURRENT_TERM_ID: string = 'current_term_id';

  /** 当前周次 */
  public static readonly CURRENT_WEEK: string = 'current_week';

  /** 主题模式 */
  public static readonly THEME_MODE: string = 'theme_mode';

  /** 是否首次启动 */
  public static readonly IS_FIRST_LAUNCH: string = 'is_first_launch';
}

/**
 * 课程相关常量
 */
export class CourseConstants {
  /** 每天最大节次数 */
  public static readonly MAX_SECTIONS_PER_DAY: number = 12;

  /** 每周天数 */
  public static readonly DAYS_PER_WEEK: number = 7;

  /** 单次导入最大课程数 */
  public static readonly MAX_IMPORT_COURSES: number = 500;

  /** 课程卡片颜色数量 */
  public static readonly COURSE_COLOR_COUNT: number = 10;
}

/**
 * 周类型枚举
 */
export enum WeekType {
  /** 每周 */
  EVERY_WEEK = 0,

  /** 单周 */
  ODD_WEEK = 1,

  /** 双周 */
  EVEN_WEEK = 2
}

/**
 * 课程来源类型枚举
 */
export enum CourseSourceType {
  /** 手动添加 */
  MANUAL = 0,

  /** 教务导入 */
  IMPORTED = 1
}

/**
 * 导入类型枚举
 */
export enum ImportType {
  /** HTML 页面抓取 */
  HTML = 0,

  /** API 接口 */
  API = 1
}

/**
 * 性能预算常量（单位：毫秒）
 */
export class PerformanceConstants {
  /** 首屏加载时间 */
  public static readonly FIRST_SCREEN_LOAD_TIME: number = 800;

  /** 周课表切换时间 */
  public static readonly WEEK_SWITCH_TIME: number = 100;

  /** 导入500节课时间 */
  public static readonly IMPORT_500_COURSES_TIME: number = 3000;
}

/**
 * 路由路径常量
 */
export class RoutePath {
  public static readonly INDEX: string = 'pages/IndexPage';
  public static readonly WEEK_SCHEDULE: string = 'pages/schedule/WeekSchedulePage';
  public static readonly COURSE_DETAIL: string = 'pages/schedule/CourseDetailPage';
  public static readonly COURSE_EDIT: string = 'pages/schedule/CourseEditPage';
  public static readonly IMPORT_ENTRY: string = 'pages/import/ImportEntryPage';
  public static readonly SCHOOL_SELECT: string = 'pages/import/SchoolSelectPage';
  public static readonly IMPORT_RESULT: string = 'pages/import/ImportResultPage';
  public static readonly SETTINGS: string = 'pages/settings/SettingsPage';
}