/**
 * 学期实体
 * 对应 term 表
 */

import { relationalStore } from '@kit.ArkData';

/**
 * 学期实体类
 */
export class TermEntity {
  /** 学期 ID */
  public id: string = '';

  /** 学期名称 */
  public name: string = '';

  /** 学期起始日期（时间戳） */
  public startDate: number = 0;

  /** 总周数 */
  public weekCount: number = 0;

  /** 是否当前学期 */
  public isCurrent: number = 0;

  /** 创建时间 */
  public createdAt: number = 0;

  /** 更新时间 */
  public updatedAt: number = 0;

  /**
   * 从数据库行构造实体
   */
  public static fromRow(row: relationalStore.ValuesBucket): TermEntity {
    const entity = new TermEntity();
    entity.id = row['id'] as string;
    entity.name = row['name'] as string;
    entity.startDate = row['startDate'] as number;
    entity.weekCount = row['weekCount'] as number;
    entity.isCurrent = row['isCurrent'] as number;
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
      'name': this.name,
      'startDate': this.startDate,
      'weekCount': this.weekCount,
      'isCurrent': this.isCurrent,
      'createdAt': this.createdAt,
      'updatedAt': this.updatedAt
    };
  }
}