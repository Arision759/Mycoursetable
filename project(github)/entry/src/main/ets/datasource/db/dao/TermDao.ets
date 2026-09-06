/**
 * Term DAO
 * 学期表数据访问对象
 */
import { relationalStore } from '@kit.ArkData';
import { Logger } from '../../../common/logger/Logger';
import { Result } from '../../../error/Result';
import { AppError } from '../../../error/AppError';
import { ErrorCode } from '../../../model/constants/ErrorCodeConstants';
import { TermEntity } from '../../../model/entity/TermEntity';
import { RdbManager } from '../RdbManager';
import { TableName } from '../../../model/constants/AppConstants';

/**
 * 学期数据访问对象
 */
export class TermDao {
  private static readonly TAG: string = 'TermDao';

  /**
   * 插入学期
   */
  public static async insert(term: TermEntity): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const rowId = await store.insert(TableName.TERM, term.toRow());

      Logger.debug(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'insert', `Inserted term: ${term.id}`)
      );

      return Result.success(rowId);
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'insert', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 更新学期
   */
  public static async update(term: TermEntity): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.TERM);
      predicates.equalTo('id', term.id);

      const count = await store.update(term.toRow(), predicates);

      Logger.debug(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'update', `Updated term: ${term.id}`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'update', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 删除学期
   */
  public static async delete(termId: string): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.TERM);
      predicates.equalTo('id', termId);

      const count = await store.delete(predicates);

      Logger.debug(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'delete', `Deleted term: ${termId}`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'delete', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 根据 ID 查询学期
   */
  public static async queryById(termId: string): Promise<Result<TermEntity | null>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.TERM);
      predicates.equalTo('id', termId);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        const term = TermDao.parseResultSet(resultSet);
        return Result.success(term);
      }

      return Result.success(null);
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'queryById', 'Failed: %{public}s'),
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
   * 查询当前学期
   */
  public static async queryCurrentTerm(): Promise<Result<TermEntity | null>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.TERM);
      predicates.equalTo('isCurrent', 1);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        const term = TermDao.parseResultSet(resultSet);
        return Result.success(term);
      }

      return Result.success(null);
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'queryCurrentTerm', 'Failed: %{public}s'),
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
   * 查询所有学期
   */
  public static async queryAll(): Promise<Result<TermEntity[]>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.TERM);
      predicates.orderByDesc('startDate');

      resultSet = await store.query(predicates);

      const terms: TermEntity[] = [];
      while (resultSet.goToNextRow()) {
        terms.push(TermDao.parseResultSet(resultSet));
      }

      return Result.success(terms);
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'queryAll', 'Failed: %{public}s'),
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
   * 设置当前学期
   * 先清除所有学期的 isCurrent 标记，再设置指定学期为当前
   */
  public static async setCurrentTerm(termId: string): Promise<Result<void>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      // 开始事务
      await store.beginTransaction();

      try {
        // 清除所有 isCurrent 标记
        const clearPredicates = new relationalStore.RdbPredicates(TableName.TERM);
        await store.update({ 'isCurrent': 0 }, clearPredicates);

        // 设置当前学期
        const setPredicates = new relationalStore.RdbPredicates(TableName.TERM);
        setPredicates.equalTo('id', termId);
        await store.update({ 'isCurrent': 1 }, setPredicates);

        // 提交事务
        await store.commit();

        Logger.debug(
          TermDao.TAG,
          Logger.formatMsg(TermDao.TAG, 'setCurrentTerm', `Set current term: ${termId}`)
        );

        return Result.success(undefined);
      } catch (err) {
        // 回滚事务
        await store.rollBack();
        throw err as Error;
      }
    } catch (err) {
      Logger.error(
        TermDao.TAG,
        Logger.formatMsg(TermDao.TAG, 'setCurrentTerm', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_TRANSACTION_FAILED, err as Error));
    }
  }

  /**
   * 解析 ResultSet 为 TermEntity
   */
  private static parseResultSet(resultSet: relationalStore.ResultSet): TermEntity {
    const row: relationalStore.ValuesBucket = {};
    const columnNames = resultSet.columnNames;

    for (const columnName of columnNames) {
      const columnIndex = resultSet.getColumnIndex(columnName);
      row[columnName] = resultSet.getValue(columnIndex);
    }

    return TermEntity.fromRow(row);
  }
}