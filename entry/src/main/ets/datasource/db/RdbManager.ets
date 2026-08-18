/**
 * 关系型数据库管理器
 * 统一管理数据库生命周期、连接、事务
 */
import { relationalStore } from '@kit.ArkData';
import { Logger } from '../../common/logger/Logger';
import { AppError } from '../../error/AppError';
import { Result } from '../../error/Result';
import { ErrorCode } from '../../model/constants/ErrorCodeConstants';
import { DbConstants, TableName } from '../../model/constants/AppConstants';

/**
 * RDB 管理器
 * 单例模式
 */
export class RdbManager {
  private static readonly TAG: string = 'RdbManager';
  private static instance: RdbManager | null = null;
  private rdbStore: relationalStore.RdbStore | null = null;
  private context: Context | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
  }

  /**
   * 获取单例
   */
  public static getInstance(): RdbManager {
    if (RdbManager.instance === null) {
      RdbManager.instance = new RdbManager();
    }
    return RdbManager.instance;
  }

  /**
   * 初始化数据库
   */
  public async init(context: Context): Promise<Result<void>> {
    try {
      this.context = context;

      const config: relationalStore.StoreConfig = {
        name: DbConstants.DB_NAME,
        securityLevel: relationalStore.SecurityLevel.S3,
        encrypt: true
      };

      this.rdbStore = await relationalStore.getRdbStore(context, config);

      Logger.info(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'init', 'Database initialized successfully')
      );

      // 创建表结构
      const createResult = await this.createTables();
      if (createResult.isFailure()) {
        return createResult;
      }

      // 开启外键约束
      await this.rdbStore.executeSql('PRAGMA foreign_keys = ON');

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'init', 'Failed to initialize database: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED, err as Error));
    }
  }

  /**
   * 创建表结构
   */
  private async createTables(): Promise<Result<void>> {
    try {
      if (!this.rdbStore) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }

      // 创建 school 表
      await this.rdbStore.executeSql(`
        CREATE TABLE IF NOT EXISTS ${TableName.SCHOOL} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          adapterKey TEXT NOT NULL,
          importType INTEGER NOT NULL,
          enabled INTEGER DEFAULT 1,
          createdAt INTEGER,
          updatedAt INTEGER
        )
      `);

      // 创建 term 表
      await this.rdbStore.executeSql(`
        CREATE TABLE IF NOT EXISTS ${TableName.TERM} (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          startDate INTEGER NOT NULL,
          weekCount INTEGER NOT NULL,
          isCurrent INTEGER DEFAULT 0,
          createdAt INTEGER,
          updatedAt INTEGER
        )
      `);

      // 创建 term.isCurrent 索引
      await this.rdbStore.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_term_current ON ${TableName.TERM}(isCurrent)
      `);

      // 创建 course 表
      await this.rdbStore.executeSql(`
        CREATE TABLE IF NOT EXISTS ${TableName.COURSE} (
          id TEXT PRIMARY KEY,
          termId TEXT NOT NULL,
          name TEXT NOT NULL,
          teacher TEXT,
          location TEXT,
          dayOfWeek INTEGER NOT NULL,
          startSection INTEGER NOT NULL,
          endSection INTEGER NOT NULL,
          startTime TEXT,
          endTime TEXT,
          startWeek INTEGER NOT NULL,
          endWeek INTEGER NOT NULL,
          weekType INTEGER DEFAULT 0,
          color TEXT DEFAULT '#FF6B9D',
          remark TEXT,
          sourceType INTEGER DEFAULT 0,
          createdAt INTEGER,
          updatedAt INTEGER,
          FOREIGN KEY (termId) REFERENCES ${TableName.TERM}(id) ON DELETE CASCADE
        )
      `);

      // 创建 course 联合索引
      await this.rdbStore.executeSql(`
        CREATE INDEX IF NOT EXISTS idx_course_query
        ON ${TableName.COURSE}(termId, dayOfWeek, startSection)
      `);

      Logger.info(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'createTables', 'Tables created successfully')
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'createTables', 'Failed to create tables: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 获取数据库实例
   */
  public getStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  /**
   * 开始事务
   */
  public async beginTransaction(): Promise<Result<void>> {
    try {
      if (!this.rdbStore) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }
      await this.rdbStore.beginTransaction();
      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'beginTransaction', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_TRANSACTION_FAILED, err as Error));
    }
  }

  /**
   * 提交事务
   */
  public async commit(): Promise<Result<void>> {
    try {
      if (!this.rdbStore) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }
      await this.rdbStore.commit();
      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'commit', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_TRANSACTION_FAILED, err as Error));
    }
  }

  /**
   * 回滚事务
   */
  public async rollback(): Promise<Result<void>> {
    try {
      if (!this.rdbStore) {
        return Result.failure(AppError.dbError(ErrorCode.DB_OPEN_FAILED));
      }
      await this.rdbStore.rollBack();
      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'rollback', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_TRANSACTION_FAILED, err as Error));
    }
  }

  /**
   * 关闭数据库
   */
  public async close(): Promise<void> {
    if (this.rdbStore) {
      await relationalStore.deleteRdbStore(this.context!, DbConstants.DB_NAME);
      this.rdbStore = null;
      Logger.info(
        RdbManager.TAG,
        Logger.formatMsg(RdbManager.TAG, 'close', 'Database closed')
      );
    }
  }
}