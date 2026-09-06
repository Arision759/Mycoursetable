/**
 * 时间表解析器
 * 职责：节次 → 具体时间转换
 */
export interface TimeRange {
  start: string;
  end: string;
}

export class TimeTableParser {
  // 长安大学作息时间表
  private static readonly TIME_TABLE: Map<number, TimeRange> = TimeTableParser.initTimeTable();

  private static initTimeTable(): Map<number, TimeRange> {
    const map = new Map<number, TimeRange>();
    map.set(1, TimeTableParser.time('08:30', '09:15'));
    map.set(2, TimeTableParser.time('09:20', '10:05'));
    map.set(3, TimeTableParser.time('10:25', '11:10'));
    map.set(4, TimeTableParser.time('11:15', '12:00'));
    map.set(5, TimeTableParser.time('14:00', '14:45'));
    map.set(6, TimeTableParser.time('14:50', '15:35'));
    map.set(7, TimeTableParser.time('15:55', '16:40'));
    map.set(8, TimeTableParser.time('16:45', '17:30'));
    map.set(9, TimeTableParser.time('19:00', '19:45'));
    map.set(10, TimeTableParser.time('19:50', '20:35'));
    map.set(11, TimeTableParser.time('20:40', '21:25'));
    map.set(12, TimeTableParser.time('21:30', '22:15'));
    return map;
  }

  private static time(start: string, end: string): TimeRange {
    const range: TimeRange = {
      start: start,
      end: end
    };
    return range;
  }

  /**
   * 获取指定节次的开始时间
   * @param section - 节次（1-12）
   * @returns 时间字符串（如"08:30"）
   */
  public static getStartTime(section: number): string {
    const time = TimeTableParser.TIME_TABLE.get(section);
    return time ? time.start : '00:00';
  }

  /**
   * 获取指定节次的结束时间
   * @param section - 节次（1-12）
   * @returns 时间字符串（如"09:15"）
   */
  public static getEndTime(section: number): string {
    const time = TimeTableParser.TIME_TABLE.get(section);
    return time ? time.end : '00:00';
  }

  /**
   * 获取指定节次的完整时间范围
   * @param section - 节次（1-12）
   * @returns TimeRange
   */
  public static getSectionTime(section: number): TimeRange {
    const time = TimeTableParser.TIME_TABLE.get(section);
    if (time) {
      return time;
    }
    // 如果没找到，返回默认值
    return { start: '08:00', end: '08:45' };
  }

  /**
   * 获取跨节课程的起止时间
   * @param startSection - 开始节次
   * @param endSection - 结束节次
   * @returns 时间范围
   */
  public static getTimeRange(startSection: number, endSection: number): TimeRange {
    const range: TimeRange = {
      start: TimeTableParser.getStartTime(startSection),
      end: TimeTableParser.getEndTime(endSection)
    };
    return range;
  }
}
