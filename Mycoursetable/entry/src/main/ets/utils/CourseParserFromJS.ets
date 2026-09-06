/**
 * 课程解析器 - 从 JavaScript TaskActivity 对象解析
 * 适配树维（Supwisdom）EAMS 教务系统
 */
import { CourseImportDTO } from '../model/dto/CourseImportDTO';
import { Logger } from '../common/logger/Logger';
import { TimeTableParser } from './TimeTableParser';

const TAG = 'CourseParserFromJS';

export class CourseParserFromJS {
  /**
   * 从课表 HTML 中解析课程
   * HTML 中包含 JavaScript 代码，课程数据以 TaskActivity 对象形式存在
   */
  public static parse(html: string, termId: string): CourseImportDTO[] {
    Logger.info(TAG, Logger.formatMsg(TAG, 'parse', `开始解析 (HTML 长度: ${html.length})`));

    const courses: CourseImportDTO[] = [];

    try {
      // 1. 提取 unitCount（每天节次数）
      const unitMatch = html.match(/var\s+unitCount\s*=\s*(\d+)/);
      if (!unitMatch) {
        Logger.error(TAG, Logger.formatMsg(TAG, 'parse', '未找到 unitCount'));
        return courses;
      }
      const unitCount = parseInt(unitMatch[1]);
      Logger.info(TAG, Logger.formatMsg(TAG, 'parse', `unitCount = ${unitCount}`));

      // 2. 按 "var teachers" 分块
      const blocks = html.split(/(?=var\s+teachers\s*=\s*\[)/);
      Logger.info(TAG, Logger.formatMsg(TAG, 'parse', `分割为 ${blocks.length} 个块`));

      const seen = new Map<string, boolean>();

      for (let blockIndex = 0; blockIndex < blocks.length; blockIndex++) {
        const block = blocks[blockIndex];

        // 提取教师名称
        const teacherMatches = CourseParserFromJS.matchAll(block, /name:"([^"]+)"/g);
        if (teacherMatches.length === 0) {
          continue;
        }

        // 提取课程名称
        const courseNameMatch = block.match(/var\s+courseName\s*=\s*"([^"]+)"/);
        if (!courseNameMatch) {
          continue;
        }
        const courseNameFull = courseNameMatch[1];

        // 提取 TaskActivity 参数
        const taPattern = /new\s+TaskActivity\(actTeacherId\.join\('[^']*'\)\s*,\s*actTeacherName\.join\('[^']*'\)\s*,"([^"]*)",courseName,"([^"]*)","\d*","([^"]*)","([^"]*)"/;
        const taMatch = block.match(taPattern);
        if (!taMatch) {
          continue;
        }

        const courseCode = taMatch[2];
        const classroom = taMatch[3].replace(/^\*/, '');
        const validWeeks = taMatch[4];

        // 解析课程名（去除括号中的代码）
        const nameOnly = courseNameFull.match(/^([^(]+)/);
        const courseName = nameOnly ? nameOnly[1].trim() : courseNameFull;

        // 解析有效周
        const weekRange = CourseParserFromJS.parseValidWeeks(validWeeks);

        // 教师去重
        const uniqueTeachers: string[] = [];
        for (const t of teacherMatches) {
          if (!uniqueTeachers.includes(t)) {
            uniqueTeachers.push(t);
          }
        }
        const teachersStr = uniqueTeachers.join(',');

        // 提取所有 index 赋值
        const indexMatches = CourseParserFromJS.matchAll(
          block,
          /index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+)/g
        );
        if (indexMatches.length === 0) {
          continue;
        }

        // 解析 index：格式为 [day, section] 对
        const indexPairs: Array<[number, number]> = [];
        // matchAll 返回的是捕获组内容，每两个为一对
        for (let i = 0; i < indexMatches.length; i += 2) {
          const day = parseInt(indexMatches[i]);
          const section = parseInt(indexMatches[i + 1]);
          indexPairs.push([day, section]);
        }

        Logger.debug(TAG, Logger.formatMsg(TAG, 'parse',
          `📝 ${courseName}: 提取到 ${indexPairs.length} 个时间点: ${JSON.stringify(indexPairs)}`))

        // 按星期分组，每个星期的节次可能不连续
        // 例如：周一1-2节 + 周一5-6节 → 应该拆分成两条记录
        const groupedByDay = new Map<number, number[]>();
        for (const pair of indexPairs) {
          const day = pair[0] + 1; // 0-based → 1-based
          const section = pair[1] + 1; // 0-based → 1-based

          if (!groupedByDay.has(day)) {
            groupedByDay.set(day, []);
          }
          groupedByDay.get(day)!.push(section);
        }

        // 对每个星期的节次排序，找连续段
        groupedByDay.forEach((sections: number[], dayOfWeek: number) => {
          sections.sort((a, b) => a - b);

          Logger.debug(TAG, Logger.formatMsg(TAG, 'parse',
            `  周${dayOfWeek}: 节次 ${JSON.stringify(sections)}`));

          // 合并连续节次
          let startSection = sections[0];
          let endSection = sections[0];

          for (let i = 1; i < sections.length; i++) {
            if (sections[i] === endSection + 1) {
              // 连续，扩展
              endSection = sections[i];
            } else {
              // 不连续，保存当前段，开始新段
              CourseParserFromJS.createCourse(courses, seen, termId, courseCode, courseName, teachersStr,
                dayOfWeek, startSection, endSection, weekRange, classroom);

              startSection = sections[i];
              endSection = sections[i];
            }
          }

          // 保存最后一段
          CourseParserFromJS.createCourse(courses, seen, termId, courseCode, courseName, teachersStr,
            dayOfWeek, startSection, endSection, weekRange, classroom);
        });
      }

      Logger.info(TAG, Logger.formatMsg(TAG, 'parse', `解析完成，共 ${courses.length} 门课程`));
    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'parse', `解析异常: ${JSON.stringify(err)}`));
    }

    return courses;
  }

  /**
   * 创建课程记录（辅助方法）
   */
  private static createCourse(
    courses: CourseImportDTO[],
    seen: Map<string, boolean>,
    termId: string,
    courseCode: string,
    courseName: string,
    teachers: string,
    dayOfWeek: number,
    startSection: number,
    endSection: number,
    weekRange: [number, number],
    classroom: string
  ): void {
    // 去重
    const key = `${courseCode}_${dayOfWeek}_${startSection}`;
    if (seen.has(key)) {
      return;
    }
    seen.set(key, true);

    // 获取时间
    const startTime = TimeTableParser.getSectionTime(startSection);
    const endTime = TimeTableParser.getSectionTime(endSection);

    // 创建 DTO
    const dto = new CourseImportDTO();
    dto.termId = termId;
    dto.courseCode = courseCode;
    dto.courseName = courseName;
    dto.teachers = teachers;
    dto.dayOfWeek = dayOfWeek;
    dto.startSection = startSection;
    dto.endSection = endSection;
    dto.startTime = startTime.start;
    dto.endTime = endTime.end;
    dto.startWeek = weekRange[0];
    dto.endWeek = weekRange[1];
    dto.classroom = classroom;

    courses.push(dto);
    Logger.info(TAG, Logger.formatMsg(TAG, 'createCourse',
      `✅ ${courseName} | ${teachers} | 周${dayOfWeek} ${startSection}-${endSection}节 | ${weekRange[0]}-${weekRange[1]}周 | ${classroom}`));
  }

  /**
   * 解析有效周二进制字符串
   * "01111111110000..." → [1, 9]（第1周到第9周）
   * 注意：教务系统的二进制字符串索引位置直接对应周次
   * 即 index=0 表示第0周（不使用），index=1 表示第1周
   */
  private static parseValidWeeks(weeksStr: string): [number, number] {
    let startWeek = -1;
    let endWeek = -1;

    for (let i = 0; i < weeksStr.length; i++) {
      if (weeksStr[i] === '1') {
        if (startWeek === -1) {
          // 直接使用索引值，不加1
          // 特殊处理：如果索引为0，视为第1周（避免week=0的情况）
          startWeek = i === 0 ? 1 : i;
        }
        endWeek = i === 0 ? 1 : i;
      }
    }

    if (startWeek === -1) {
      return [1, 20];
    }
    return [startWeek, endWeek];
  }

  /**
   * 正则全局匹配，返回所有捕获组内容
   * ArkTS 中 RegExp.exec 循环替代 matchAll
   */
  private static matchAll(text: string, pattern: RegExp): string[] {
    const results: string[] = [];
    let match: RegExpExecArray | null = pattern.exec(text);
    while (match !== null) {
      // 将所有捕获组加入结果
      for (let i = 1; i < match.length; i++) {
        results.push(match[i]);
      }
      match = pattern.exec(text);
    }
    return results;
  }
}
