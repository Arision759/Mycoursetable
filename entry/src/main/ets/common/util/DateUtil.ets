/**
 * 日期工具类
 * 提供周次计算、日期格式化等功能
 */

/**
 * 日期工具类
 */
export class DateUtil {
  /**
   * 根据学期起始日期和当前日期计算当前周次
   * @param startDate 学期起始日期（时间戳）
   * @param currentDate 当前日期（时间戳，默认为今天）
   * @returns 当前周次（从1开始），如果未开学返回0
   */
  public static getCurrentWeek(startDate: number, currentDate: number = Date.now()): number {
    const daysDiff = Math.floor((currentDate - startDate) / (24 * 60 * 60 * 1000));

    // 如果当前日期在开学日期之前，返回 0（未开学）
    if (daysDiff < 0) {
      return 0;
    }

    return Math.floor(daysDiff / 7) + 1;
  }

  /**
   * 计算当前周次（与 getCurrentWeek 等价）
   */
  public static calculateWeek(startDate: number, currentDate: number = Date.now()): number {
    return DateUtil.getCurrentWeek(startDate, currentDate);
  }

  /**
   * 在指定日期上增加天数
   */
  public static addDays(date: number, days: number): number {
    return date + days * 24 * 60 * 60 * 1000;
  }

  /**
   * 根据周次和星期几计算具体日期
   * @param startDate 学期起始日期（时间戳）
   * @param week 周次（从1开始）
   * @param dayOfWeek 星期几（1-7，周一到周日）
   * @returns 日期时间戳
   */
  public static getDateByWeekAndDay(startDate: number, week: number, dayOfWeek: number): number {
    const daysOffset = (week - 1) * 7 + (dayOfWeek - 1);
    return startDate + daysOffset * 24 * 60 * 60 * 1000;
  }

  /**
   * 获取指定周的起始日期（周一）
   * @param startDate 学期起始日期（时间戳）
   * @param week 周次（从1开始）
   * @returns 该周周一的时间戳
   */
  public static getWeekStartDate(startDate: number, week: number): number {
    return DateUtil.getDateByWeekAndDay(startDate, week, 1);
  }

  /**
   * 获取指定周的结束日期（周日）
   * @param startDate 学期起始日期（时间戳）
   * @param week 周次（从1开始）
   * @returns 该周周日的时间戳
   */
  public static getWeekEndDate(startDate: number, week: number): number {
    return DateUtil.getDateByWeekAndDay(startDate, week, 7);
  }

  /**
   * 格式化日期为 YYYY-MM-DD
   */
  public static formatDate(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${year}-${month}-${day}`;
  }

  /**
   * 格式化日期为 MM月DD日
   */
  public static formatDateCN(timestamp: number): string {
    const date = new Date(timestamp);
    const month = date.getMonth() + 1;
    const day = date.getDate();
    return `${month}月${day}日`;
  }

  /**
   * 格式化时间为 HH:mm
   */
  public static formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * 获取星期几的中文名称
   */
  public static getDayOfWeekName(dayOfWeek: number): string {
    const names = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return names[dayOfWeek] || '';
  }

  /**
   * 判断指定日期是否在某个周次的单双周范围内
   * @param week 周次
   * @param weekType 周类型（0=每周 1=单周 2=双周）
   * @returns 是否匹配
   */
  public static matchWeekType(week: number, weekType: number): boolean {
    if (weekType === 0) {
      // 每周
      return true;
    } else if (weekType === 1) {
      // 单周
      return week % 2 === 1;
    } else if (weekType === 2) {
      // 双周
      return week % 2 === 0;
    }
    return false;
  }

  /**
   * 判断课程是否在指定周次上课
   * @param week 周次
   * @param startWeek 起始周
   * @param endWeek 结束周
   * @param weekType 周类型
   * @returns 是否上课
   */
  public static isCourseActiveInWeek(
    week: number,
    startWeek: number,
    endWeek: number,
    weekType: number
  ): boolean {
    if (week < startWeek || week > endWeek) {
      return false;
    }
    return DateUtil.matchWeekType(week, weekType);
  }

  /**
   * 获取今天是星期几（1-7）
   */
  public static getTodayDayOfWeek(): number {
    const day = new Date().getDay();
    return day === 0 ? 7 : day; // 周日转换为7
  }

  /**
   * 获取今天的时间戳（00:00:00）
   */
  public static getTodayTimestamp(): number {
    const now = new Date();
    now.setHours(0, 0, 0, 0);
    return now.getTime();
  }
}