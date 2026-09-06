/**
 * 颜色分配服务
 * 职责：
 * - 为课程自动分配颜色
 * - 保证同课程代码同颜色
 */
import { Logger } from '../common/logger/Logger';

export class ColorService {
  private static instance: ColorService | null = null;

  // 颜色池（8种颜色）
  private static readonly COLOR_POOL: string[] = [
    '#FF6B9D', // 粉色
    '#FFA36C', // 橙色
    '#FFD93D', // 黄色
    '#6BCF7F', // 绿色
    '#6BB6FF', // 蓝色
    '#A78BFA', // 紫色
    '#FB7185', // 红粉
    '#60A5FA'  // 天蓝
  ];

  private constructor() {
  }

  public static getInstance(): ColorService {
    if (!ColorService.instance) {
      ColorService.instance = new ColorService();
    }
    return ColorService.instance;
  }

  /**
   * 根据课程代码分配颜色
   * 算法：对课程代码字符求和，模颜色池大小
   * 保证同课程代码永远返回同一颜色
   *
   * @param courseCode - 课程代码（如"26ZY1402.01"）
   * @returns 颜色值（如"#FF6B9D"）
   */
  public getCourseColor(courseCode: string): string {
    if (!courseCode || courseCode.length === 0) {
      Logger.warn(
        'ColorService',
        Logger.formatMsg('ColorService', 'getCourseColor', '课程代码为空，使用默认颜色')
      );
      return ColorService.COLOR_POOL[0];
    }

    // 计算课程代码的 hash 值
    let hash = 0;
    for (let i = 0; i < courseCode.length; i++) {
      hash += courseCode.charCodeAt(i);
    }

    // 取模获取颜色索引
    const colorIndex = hash % ColorService.COLOR_POOL.length;
    const color = ColorService.COLOR_POOL[colorIndex];

    Logger.debug(
      'ColorService',
      Logger.formatMsg('ColorService', 'getCourseColor', `课程 ${courseCode} 分配颜色 ${color}`)
    );

    return color;
  }

  /**
   * 获取随机颜色（用于手动添加课程）
   */
  public getRandomColor(): string {
    const randomIndex = Math.floor(Math.random() * ColorService.COLOR_POOL.length);
    return ColorService.COLOR_POOL[randomIndex];
  }

  /**
   * 获取颜色池（供UI选择）
   */
  public getColorPool(): string[] {
    return [...ColorService.COLOR_POOL];
  }
}
