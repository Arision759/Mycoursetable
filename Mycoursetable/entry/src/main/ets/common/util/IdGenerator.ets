/**
 * ID 生成器
 * 生成全局唯一的字符串 ID
 */

/**
 * ID 生成器类
 */
export class IdGenerator {
  private static counter: number = 0;

  /**
   * 生成唯一 ID
   * 格式：时间戳 + 随机数 + 计数器
   */
  public static generate(): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000);
    const count = ++IdGenerator.counter;
    return `${timestamp}${random}${count}`;
  }

  /**
   * 生成带前缀的 ID
   */
  public static generateWithPrefix(prefix: string): string {
    return `${prefix}_${IdGenerator.generate()}`;
  }

  /**
   * 生成指定前缀的 ID
   */
  public static generateId(prefix: string): string {
    return IdGenerator.generateWithPrefix(prefix);
  }

  /**
   * 生成课程 ID
   */
  public static generateCourseId(): string {
    return IdGenerator.generateWithPrefix('course');
  }

  /**
   * 生成学期 ID
   */
  public static generateTermId(): string {
    return IdGenerator.generateWithPrefix('term');
  }

  /**
   * 生成学校 ID
   */
  public static generateSchoolId(): string {
    return IdGenerator.generateWithPrefix('school');
  }

  /**
   * 生成哈希（用于数据去重）
   * 简单实现：对字符串进行哈希
   */
  public static hash(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // 转换为32位整数
    }
    return hash.toString(36);
  }
}