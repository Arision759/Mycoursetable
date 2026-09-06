/**
 * 课程实体
 * 对应 course 表
 */

import { relationalStore } from '@kit.ArkData';

/**
 * 课程实体类
 */
export class CourseEntity {
  /** 课程 ID */
  public id: string = '';

  /** 所属学期 ID */
  public termId: string = '';

  /** 课程名称 */
  public name: string = '';

  /** 教师（多个教师用逗号分隔） */
  public teacher: string = '';

  /** 上课地点 */
  public location: string = '';

  /** 星期几（1-7，周一到周日） */
  public dayOfWeek: number = 1;

  /** 起始节次（1-12） */
  public startSection: number = 1;

  /** 结束节次（1-12） */
  public endSection: number = 1;

  /** 起始时间（格式："08:30"） */
  public startTime: string = '';

  /** 结束时间（格式："10:05"） */
  public endTime: string = '';

  /** 起始周 */
  public startWeek: number = 1;

  /** 结束周 */
  public endWeek: number = 1;

  /** 周类型（0=每周 1=单周 2=双周） */
  public weekType: number = 0;

  /** 课程颜色（格式："#FF6B9D"） */
  public color: string = '#FF6B9D';

  /** 备注 */
  public remark: string = '';

  /** 来源类型（0=手动 1=教务导入） */
  public sourceType: number = 0;

  /** 创建时间 */
  public createdAt: number = 0;

  /** 更新时间 */
  public updatedAt: number = 0;

  /**
   * 从数据库行构造实体
   */
  public static fromRow(row: relationalStore.ValuesBucket): CourseEntity {
    const entity = new CourseEntity();
    entity.id = row['id'] as string;
    entity.termId = row['termId'] as string;
    entity.name = row['name'] as string;
    entity.teacher = row['teacher'] as string;
    entity.location = row['location'] as string;
    entity.dayOfWeek = row['dayOfWeek'] as number;
    entity.startSection = row['startSection'] as number;
    entity.endSection = row['endSection'] as number;
    entity.startTime = row['startTime'] as string;
    entity.endTime = row['endTime'] as string;
    entity.startWeek = row['startWeek'] as number;
    entity.endWeek = row['endWeek'] as number;
    entity.weekType = row['weekType'] as number;
    entity.color = row['color'] as string;
    entity.remark = row['remark'] as string;
    entity.sourceType = row['sourceType'] as number;
    entity.createdAt = row['createdAt'] as number;
    entity.updatedAt = row['updatedAt'] as number;
    return entity;
  }

  /**
   * 转换为数据库行
   */
  public toRow(): relationalStore.ValuesBucket {
    return {
      'id': this.id,
      'termId': this.termId,
      'name': this.name,
      'teacher': this.teacher,
      'location': this.location,
      'dayOfWeek': this.dayOfWeek,
      'startSection': this.startSection,
      'endSection': this.endSection,
      'startTime': this.startTime,
      'endTime': this.endTime,
      'startWeek': this.startWeek,
      'endWeek': this.endWeek,
      'weekType': this.weekType,
      'color': this.color,
      'remark': this.remark,
      'sourceType': this.sourceType,
      'createdAt': this.createdAt,
      'updatedAt': this.updatedAt
    };
  }
}