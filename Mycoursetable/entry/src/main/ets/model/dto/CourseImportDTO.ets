/**
 * 课程导入 DTO
 * 教务系统解析后的标准化输出
 */

/**
 * 课程导入数据传输对象
 */
export class CourseImportDTO {
  /** 学校 ID */
  public schoolId: string = '';

  /** 学期名称 */
  public termName: string = '';

  /** 课程名称 */
  public courseName: string = '';

  /** 教师 */
  public teacher: string = '';

  /** 上课地点 */
  public location: string = '';

  /** 星期几（1-7） */
  public dayOfWeek: number = 1;

  /** 起始节次 */
  public startSection: number = 1;

  /** 结束节次 */
  public endSection: number = 1;

  /** 起始周 */
  public startWeek: number = 1;

  /** 结束周 */
  public endWeek: number = 1;

  /** 周类型（0=每周 1=单周 2=双周） */
  public weekType: number = 0;

  /** 原始记录哈希（用于冲突检测/去重） */
  public rawHash: string = '';

  /** 备注 */
  public remark: string = '';

  /** 所属学期 ID */
  public termId: string = '';

  /** 课程代码 */
  public courseCode: string = '';

  /** 教师（多个教师用逗号分隔） */
  public teachers: string = '';

  /** 起始时间（格式：\"08:30\"） */
  public startTime: string = '';

  /** 结束时间（格式：\"10:05\"） */
  public endTime: string = '';

  /** 教室 */
  public classroom: string = '';

  /**
   * 计算课程的冲突键
   * 用于检测时间冲突
   */
  public getConflictKey(): string {
    return `${this.dayOfWeek}_${this.startSection}_${this.startWeek}_${this.endWeek}`;
  }

  /**
   * 验证数据有效性
   */
  public isValid(): boolean {
    if (!this.courseName || this.courseName.trim().length === 0) {
      return false;
    }

    if (this.dayOfWeek < 1 || this.dayOfWeek > 7) {
      return false;
    }

    if (this.startSection < 1 || this.endSection < 1 || this.startSection > this.endSection) {
      return false;
    }

    if (this.startWeek < 1 || this.endWeek < 1 || this.startWeek > this.endWeek) {
      return false;
    }

    if (this.weekType < 0 || this.weekType > 2) {
      return false;
    }

    return true;
  }
}