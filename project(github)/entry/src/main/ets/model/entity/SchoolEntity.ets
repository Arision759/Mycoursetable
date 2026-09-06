/**
 * 学校实体
 * 对应 school 表
 */

import { relationalStore } from '@kit.ArkData';

/**
 * 学校实体类
 */
export class SchoolEntity {
  /** 学校 ID */
  public id: string = '';

  /** 学校名称 */
  public name: string = '';

  /** 适配器标识 */
  public adapterKey: string = '';

  /** 导入类型（0=HTML 1=API） */
  public importType: number = 0;

  /** 是否启用 */
  public enabled: number = 1;

  /** 创建时间 */
  public createdAt: number = 0;

  /** 更新时间 */
  public updatedAt: number = 0;

  /**
   * 从数据库行构造实体
   */
  public static fromRow(row: relationalStore.ValuesBucket): SchoolEntity {
    const entity = new SchoolEntity();
    entity.id = row['id'] as string;
    entity.name = row['name'] as string;
    entity.adapterKey = row['adapterKey'] as string;
    entity.importType = row['importType'] as number;
    entity.enabled = row['enabled'] as number;
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
      'adapterKey': this.adapterKey,
      'importType': this.importType,
      'enabled': this.enabled,
      'createdAt': this.createdAt,
      'updatedAt': this.updatedAt
    };
  }
}