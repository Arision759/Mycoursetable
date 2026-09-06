/**
 * 课程表解析器（长安大学教务系统专用）
 * 根据真实 HTML 格式优化
 */
import { CourseImportDTO } from '../model/dto/CourseImportDTO';
import { Logger } from '../common/logger/Logger';
import { TimeTableParser } from './TimeTableParser';

/**
 * 教室信息
 */
export interface ClassroomInfo {
  building: string;
  room: string;
}

export class CourseParser {
  private static readonly TAG: string = 'CourseParser';

  /**
   * 解析教务系统课表 HTML
   */
  public static parse(html: string, termId: string): CourseImportDTO[] {
    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parse', '=== 开始解析课表 HTML ===')
    );
    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parse', `HTML 总长度: ${html.length} 字符`)
    );

    const courses: CourseImportDTO[] = [];

    try {
      // 1. 提取所有课程单元格（有 title 属性的 td）
      Logger.info(
        CourseParser.TAG,
        Logger.formatMsg(CourseParser.TAG, 'parse', '步骤1: 提取所有课程单元格')
      );

      // 真实 HTML 中 td 的属性顺序是 id → style → rowspan → class → title，
      // 不能用“title 必须在 id/rowspan 之前”的顺序性正则去匹配。
      // 先取出整个 <td ...> 开标签，再分别提取 title / id / rowspan。
      const tdPattern = /<td\b[^>]*>/gi;

      let match: RegExpExecArray | null;
      let cellCount = 0;

      while ((match = tdPattern.exec(html)) !== null) {
        const tag = match[0];

        const titleMatch = tag.match(/title="([^"]*)"/i);
        if (!titleMatch) {
          continue;
        }
        const idMatch = tag.match(/id="TD(\d)(\d+)_\d+"/i);
        if (!idMatch) {
          continue;
        }
        const rowspanMatch = tag.match(/rowspan="(\d+)"/i);
        if (!rowspanMatch) {
          continue;
        }

        cellCount++;

        const title = titleMatch[1]; // title 属性内容
        const dayOfWeek = parseInt(idMatch[1]); // 星期几（1-7）
        const startSection = parseInt(idMatch[2]); // 起始节次
        const rowspan = parseInt(rowspanMatch[1]); // 跨几节
        const endSection = startSection + rowspan - 1; // 结束节次

        Logger.info(
          CourseParser.TAG,
          Logger.formatMsg(
            CourseParser.TAG,
            'parse',
            `处理第 ${cellCount} 个单元格: 周${dayOfWeek} 第${startSection}-${endSection}节`
          )
        );
        Logger.info(
          CourseParser.TAG,
          Logger.formatMsg(CourseParser.TAG, 'parse', `Title 内容: ${title}`)
        );

        // 2. 解析 title 内容（可能包含多个时间段，用 ;;; 分隔）
        const timeSegments = title.split(';;;');

        for (const segment of timeSegments) {
          if (!segment || segment.trim().length === 0) {
            continue;
          }

          // 跳过"实践周"这种非课程信息
          if (segment.includes('实践周') || segment.includes('考试周')) {
            Logger.info(
              CourseParser.TAG,
              Logger.formatMsg(CourseParser.TAG, 'parse', `跳过非课程信息: ${segment}`)
            );
            continue;
          }

          try {
            const course = CourseParser.parseSegment(
              segment,
              termId,
              dayOfWeek,
              startSection,
              endSection
            );

            if (course) {
              courses.push(course);
              Logger.info(
                CourseParser.TAG,
                Logger.formatMsg(CourseParser.TAG, 'parse', `✅ 解析成功: ${course.courseName}`)
              );
            }
          } catch (err) {
            Logger.error(
              CourseParser.TAG,
              Logger.formatMsg(CourseParser.TAG, 'parse', `解析失败: ${segment}`),
              JSON.stringify(err)
            );
          }
        }
      }

      if (cellCount === 0) {
        // 诊断：未匹配到课程单元格时，打印 HTML 中带 title 的 td 样例，便于排查属性顺序 / id 格式
        const tdSamples = html.match(/<td[^>]*\btitle\s*=[^>]*>/gi);
        Logger.warn(
          CourseParser.TAG,
          Logger.formatMsg(
            CourseParser.TAG,
            'parse',
            `⚠️ 未匹配到课程单元格。HTML 中带 title 的 td 样例：${tdSamples ? tdSamples.slice(0, 5).join(' ||| ') : '无'}`
          )
        );
      }

      Logger.info(
        CourseParser.TAG,
        Logger.formatMsg(
          CourseParser.TAG,
          'parse',
          `=== 解析完成: 共处理 ${cellCount} 个单元格，解析出 ${courses.length} 门课程 ===`
        )
      );
    } catch (err) {
      Logger.error(
        CourseParser.TAG,
        Logger.formatMsg(CourseParser.TAG, 'parse', '解析异常: %{public}s'),
        JSON.stringify(err)
      );
    }

    return courses;
  }

  /**
   * 解析单个时间段
   * 格式：数据库原理(26ZY1403.05) (吉伟勇)(1-6,*WH2201)
   *      或：数据结构(26ZY1402.01) (李昭,丁明海,王轩)(1-5,*WM3203)
   */
  private static parseSegment(
    segment: string,
    termId: string,
    dayOfWeek: number,
    startSection: number,
    endSection: number
  ): CourseImportDTO | null {
    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parseSegment', `解析片段: ${segment}`)
    );

    // 去除"实践周"等干扰信息
    const cleanSegment = segment.split(';实践周')[0].split(';考试周')[0].trim();

    // 正则匹配：课程名(课程代码) (教师)(周次,*教室)
    // 教师可能有多个，用逗号分隔：(李昭,丁明海,王轩)
    const pattern = /^([^(]+)\(([^)]+)\)\s*\(([^)]+)\)\((\d+)-(\d+),\*([^)]+)\)/;
    const match = cleanSegment.match(pattern);

    if (!match) {
      Logger.warn(
        CourseParser.TAG,
        Logger.formatMsg(CourseParser.TAG, 'parseSegment', `正则不匹配: ${cleanSegment}`)
      );
      return null;
    }

    const courseName = match[1].trim(); // 课程名
    const courseCode = match[2].trim(); // 课程代码
    const teachers = match[3].trim(); // 教师（可能多个，逗号分隔）
    const startWeek = parseInt(match[4]); // 开始周
    const endWeek = parseInt(match[5]); // 结束周
    const classroom = match[6].trim(); // 教室（如 WH2201、WM3203）

    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parseSegment', `✓ 课程: ${courseName}`)
    );
    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parseSegment', `  教师: ${teachers}`)
    );
    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parseSegment', `  教室: ${classroom}`)
    );
    Logger.info(
      CourseParser.TAG,
      Logger.formatMsg(CourseParser.TAG, 'parseSegment', `  周次: ${startWeek}-${endWeek}周`)
    );

    // 解析教室信息（提取教学楼）
    const classroomInfo = CourseParser.parseClassroom(classroom);

    // 获取时间
    const startTimeRange = TimeTableParser.getSectionTime(startSection);
    const endTimeRange = TimeTableParser.getSectionTime(endSection);

    // 创建 DTO
    const dto = new CourseImportDTO();
    dto.termId = termId;
    dto.courseCode = courseCode;
    dto.courseName = courseName;
    dto.teachers = teachers; // 保持逗号分隔格式
    dto.dayOfWeek = dayOfWeek;
    dto.startSection = startSection;
    dto.endSection = endSection;
    dto.startTime = startTimeRange.start;
    dto.endTime = endTimeRange.end;
    dto.startWeek = startWeek;
    dto.endWeek = endWeek;
    dto.classroom = classroomInfo.room;

    return dto;
  }

  /**
   * 解析教室（WH2201 → 明远楼 + WH2201）
   *          （WM3203 → 明远楼 + WM3203）
   *          （WX2407 → 西禾楼 + WX2407）
   */
  private static parseClassroom(classroom: string): ClassroomInfo {
    // 教学楼映射（根据截图推断）
    const buildingMap = new Map<string, string>([
      ['WH', '明远楼'], // WH = 明远楼
      ['WM', '明远楼'], // WM = 明远楼
      ['WX', '西禾楼'], // WX = 西禾楼
      ['TH', '唐韵楼'], // TH = 唐韵楼
      ['XH', '西禾楼'], // XH = 西禾楼
      ['JX', '教学楼'], // JX = 教学楼
      ['SY', '实验楼'] // SY = 实验楼
    ]);

    // 提取前缀（前2个字母，如 WH、WM、WX）
    const prefix = classroom.substring(0, 2).toUpperCase();
    const building = buildingMap.get(prefix) || '教学楼';

    const info: ClassroomInfo = {
      building: building,
      room: classroom
    };
    return info;
  }

  /**
   * 中文星期转数字
   */
  private static parseDayOfWeek(day: string): number {
    const dayMap = new Map<string, number>([
      ['一', 1],
      ['二', 2],
      ['三', 3],
      ['四', 4],
      ['五', 5],
      ['六', 6],
      ['日', 7],
      ['天', 7]
    ]);
    return dayMap.get(day) || 1;
  }
}
