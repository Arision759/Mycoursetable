/**
 * School DAO
 * 学校表数据访问对象
 */
import { relationalStore } from '@kit.ArkData';
import { Logger } from '../../../common/logger/Logger';
import { Result } from '../../../error/Result';
import { AppError } from '../../../error/AppError';
import { ErrorCode } from '../../../model/constants/ErrorCodeConstants';
import { SchoolEntity } from '../../../model/entity/SchoolEntity';
import { RdbManager } from '../RdbManager';
import { TableName } from '../../../model/constants/AppConstants';

/**
 * 学校数据访问对象
 */
export class SchoolDao {
  private static readonly TAG: string = 'SchoolDao';

  /**
   * 插入学校
   */
  public static async insert(school: SchoolEntity): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const rowId = await store.insert(TableName.SCHOOL, school.toRow());

      Logger.debug(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'insert', `Inserted school: ${school.id}`)
      );

      return Result.success(rowId);
    } catch (err) {
      Logger.error(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'insert', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 更新学校
   */
  public static async update(school: SchoolEntity): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.SCHOOL);
      predicates.equalTo('id', school.id);

      const count = await store.update(school.toRow(), predicates);

      Logger.debug(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'update', `Updated school: ${school.id}`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'update', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 根据 ID 查询学校
   */
  public static async queryById(schoolId: string): Promise<Result<SchoolEntity | null>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.SCHOOL);
      predicates.equalTo('id', schoolId);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        const school = SchoolDao.parseResultSet(resultSet);
        return Result.success(school);
      }

      return Result.success(null);
    } catch (err) {
      Logger.error(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'queryById', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 查询所有启用的学校
   */
  public static async queryEnabled(): Promise<Result<SchoolEntity[]>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.SCHOOL);
      predicates.equalTo('enabled', 1).orderByAsc('name');

      resultSet = await store.query(predicates);

      const schools: SchoolEntity[] = [];
      while (resultSet.goToNextRow()) {
        schools.push(SchoolDao.parseResultSet(resultSet));
      }

      return Result.success(schools);
    } catch (err) {
      Logger.error(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'queryEnabled', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 查询所有学校
   */
  public static async queryAll(): Promise<Result<SchoolEntity[]>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.SCHOOL);
      predicates.orderByAsc('name');

      resultSet = await store.query(predicates);

      const schools: SchoolEntity[] = [];
      while (resultSet.goToNextRow()) {
        schools.push(SchoolDao.parseResultSet(resultSet));
      }

      return Result.success(schools);
    } catch (err) {
      Logger.error(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'queryAll', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 根据名称模糊搜索学校
   */
  public static async searchByName(keyword: string): Promise<Result<SchoolEntity[]>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.SCHOOL);
      predicates.like('name', `%${keyword}%`)
        .and()
        .equalTo('enabled', 1)
        .orderByAsc('name');

      resultSet = await store.query(predicates);

      const schools: SchoolEntity[] = [];
      while (resultSet.goToNextRow()) {
        schools.push(SchoolDao.parseResultSet(resultSet));
      }

      return Result.success(schools);
    } catch (err) {
      Logger.error(
        SchoolDao.TAG,
        Logger.formatMsg(SchoolDao.TAG, 'searchByName', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    } finally {
      if (resultSet) {
        resultSet.close();
      }
    }
  }

  /**
   * 解析 ResultSet 为 SchoolEntity
   */
  private static parseResultSet(resultSet: relationalStore.ResultSet): SchoolEntity {
    const row: relationalStore.ValuesBucket = {};
    const columnNames = resultSet.columnNames;

    for (const columnName of columnNames) {
      const columnIndex = resultSet.getColumnIndex(columnName);
      row[columnName] = resultSet.getValue(columnIndex);
    }

    return SchoolEntity.fromRow(row);
  }
}