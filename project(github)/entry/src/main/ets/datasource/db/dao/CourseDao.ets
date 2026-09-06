/**
 * Course DAO
 * 课程表数据访问对象
 */
import { relationalStore } from '@kit.ArkData';
import { Logger } from '../../../common/logger/Logger';
import { Result } from '../../../error/Result';
import { AppError } from '../../../error/AppError';
import { ErrorCode } from '../../../model/constants/ErrorCodeConstants';
import { CourseEntity } from '../../../model/entity/CourseEntity';
import { RdbManager } from '../RdbManager';
import { TableName } from '../../../model/constants/AppConstants';

/**
 * 课程数据访问对象
 */
export class CourseDao {
  private static readonly TAG: string = 'CourseDao';

  /**
   * 插入课程
   */
  public static async insert(course: CourseEntity): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const rowId = await store.insert(TableName.COURSE, course.toRow());

      Logger.debug(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'insert', `Inserted course: ${course.id}`)
      );

      return Result.success(rowId);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'insert', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 批量插入课程
   */
  public static async batchInsert(courses: CourseEntity[]): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const rows = courses.map(course => course.toRow());
      const count = await store.batchInsert(TableName.COURSE, rows);

      Logger.debug(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'batchInsert', `Inserted ${count} courses`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'batchInsert', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 更新课程
   */
  public static async update(course: CourseEntity): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.COURSE);
      predicates.equalTo('id', course.id);

      const count = await store.update(course.toRow(), predicates);

      Logger.debug(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'update', `Updated course: ${course.id}`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'update', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 删除课程
   */
  public static async delete(courseId: string): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.COURSE);
      predicates.equalTo('id', courseId);

      const count = await store.delete(predicates);

      Logger.debug(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'delete', `Deleted course: ${courseId}`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'delete', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 根据 ID 查询课程
   */
  public static async queryById(courseId: string): Promise<Result<CourseEntity | null>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.COURSE);
      predicates.equalTo('id', courseId);

      resultSet = await store.query(predicates);

      if (resultSet.goToFirstRow()) {
        const course = CourseDao.parseResultSet(resultSet);
        return Result.success(course);
      }

      return Result.success(null);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'queryById', 'Failed: %{public}s'),
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
   * 查询某学期某天某周的课程
   */
  public static async queryByTermWeekDay(
    termId: string,
    week: number,
    dayOfWeek: number
  ): Promise<Result<CourseEntity[]>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.COURSE);
      predicates.equalTo('termId', termId)
        .and()
        .equalTo('dayOfWeek', dayOfWeek)
        .and()
        .lessThanOrEqualTo('startWeek', week)
        .and()
        .greaterThanOrEqualTo('endWeek', week)
        .orderByAsc('startSection');

      resultSet = await store.query(predicates);

      const courses: CourseEntity[] = [];
      while (resultSet.goToNextRow()) {
        courses.push(CourseDao.parseResultSet(resultSet));
      }

      return Result.success(courses);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'queryByTermWeekDay', 'Failed: %{public}s'),
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
   * 查询某学期的所有课程
   */
  public static async queryByTermId(termId: string): Promise<Result<CourseEntity[]>> {
    let resultSet: relationalStore.ResultSet | null = null;
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.COURSE);
      predicates.equalTo('termId', termId);

      resultSet = await store.query(predicates);

      const courses: CourseEntity[] = [];
      while (resultSet.goToNextRow()) {
        courses.push(CourseDao.parseResultSet(resultSet));
      }

      return Result.success(courses);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'queryByTermId', 'Failed: %{public}s'),
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
   * 删除某学期的所有课程
   */
  public static async deleteByTermId(termId: string): Promise<Result<number>> {
    try {
      const store = RdbManager.getInstance().getStore();
      if (!store) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      const predicates = new relationalStore.RdbPredicates(TableName.COURSE);
      predicates.equalTo('termId', termId);

      const count = await store.delete(predicates);

      Logger.debug(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'deleteByTermId', `Deleted ${count} courses`)
      );

      return Result.success(count);
    } catch (err) {
      Logger.error(
        CourseDao.TAG,
        Logger.formatMsg(CourseDao.TAG, 'deleteByTermId', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 解析 ResultSet 为 CourseEntity
   */
  private static parseResultSet(resultSet: relationalStore.ResultSet): CourseEntity {
    const row: relationalStore.ValuesBucket = {};
    const columnNames = resultSet.columnNames;

    for (const columnName of columnNames) {
      const columnIndex = resultSet.getColumnIndex(columnName);
      row[columnName] = resultSet.getValue(columnIndex);
    }

    return CourseEntity.fromRow(row);
  }
}