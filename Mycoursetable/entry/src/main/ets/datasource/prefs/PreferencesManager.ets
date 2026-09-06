/**
 * Preferences 管理器
 * 统一管理轻量级键值对配置
 */
import { preferences } from '@kit.ArkData';
import { Logger } from '../../common/logger/Logger';
import { Result } from '../../error/Result';
import { AppError } from '../../error/AppError';
import { ErrorCode } from '../../model/constants/ErrorCodeConstants';

/**
 * Preferences 管理器
 * 单例模式
 */
export class PreferencesManager {
  private static readonly TAG: string = 'PreferencesManager';
  private static readonly PREFS_NAME: string = 'schedule_prefs';
  private static instance: PreferencesManager | null = null;
  private dataPreferences: preferences.Preferences | null = null;

  /**
   * 私有构造函数
   */
  private constructor() {
  }

  /**
   * 获取单例
   */
  public static getInstance(): PreferencesManager {
    if (PreferencesManager.instance === null) {
      PreferencesManager.instance = new PreferencesManager();
    }
    return PreferencesManager.instance;
  }

  /**
   * 初始化 Preferences
   */
  public async init(context: Context): Promise<Result<void>> {
    try {
      const options: preferences.Options = {
        name: PreferencesManager.PREFS_NAME
      };

      this.dataPreferences = await preferences.getPreferences(context, options);

      Logger.info(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'init', 'Preferences initialized successfully')
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'init', 'Failed to initialize: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED, err as Error));
    }
  }

  /**
   * 保存字符串
   */
  public async putString(key: string, value: string): Promise<Result<void>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED));
      }

      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();

      Logger.debug(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'putString', `Saved key: ${key}`)
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'putString', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 读取字符串
   */
  public async getString(key: string, defaultValue: string = ''): Promise<Result<string>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED));
      }

      const value = await this.dataPreferences.get(key, defaultValue);

      return Result.success(value as string);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'getString', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED, err as Error));
    }
  }

  /**
   * 保存数字
   */
  public async putNumber(key: string, value: number): Promise<Result<void>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED));
      }

      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();

      Logger.debug(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'putNumber', `Saved key: ${key}`)
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'putNumber', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 读取数字
   */
  public async getNumber(key: string, defaultValue: number = 0): Promise<Result<number>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED));
      }

      const value = await this.dataPreferences.get(key, defaultValue);

      return Result.success(value as number);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'getNumber', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED, err as Error));
    }
  }

  /**
   * 保存布尔值
   */
  public async putBoolean(key: string, value: boolean): Promise<Result<void>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED));
      }

      await this.dataPreferences.put(key, value);
      await this.dataPreferences.flush();

      Logger.debug(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'putBoolean', `Saved key: ${key}`)
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'putBoolean', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 读取布尔值
   */
  public async getBoolean(key: string, defaultValue: boolean = false): Promise<Result<boolean>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED));
      }

      const value = await this.dataPreferences.get(key, defaultValue);

      return Result.success(value as boolean);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'getBoolean', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_READ_FAILED, err as Error));
    }
  }

  /**
   * 删除键值对
   */
  public async delete(key: string): Promise<Result<void>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED));
      }

      await this.dataPreferences.delete(key);
      await this.dataPreferences.flush();

      Logger.debug(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'delete', `Deleted key: ${key}`)
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'delete', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 清空所有数据
   */
  public async clear(): Promise<Result<void>> {
    try {
      if (!this.dataPreferences) {
        return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED));
      }

      await this.dataPreferences.clear();
      await this.dataPreferences.flush();

      Logger.debug(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'clear', 'Cleared all preferences')
      );

      return Result.success(undefined);
    } catch (err) {
      Logger.error(
        PreferencesManager.TAG,
        Logger.formatMsg(PreferencesManager.TAG, 'clear', 'Failed: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.PREFS_WRITE_FAILED, err as Error));
    }
  }
}