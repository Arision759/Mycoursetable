/**
 * 设置数据仓储
 * 封装 PreferencesManager，提供配置数据访问
 */
import { Logger } from '../common/logger/Logger';
import { Result } from '../error/Result';
import { PreferencesManager } from '../datasource/prefs/PreferencesManager';
import { PrefsKey } from '../model/constants/AppConstants';

/**
 * 设置仓储类
 */
export class SettingRepository {
  private static readonly TAG: string = 'SettingRepository';
  private prefsManager: PreferencesManager;

  constructor() {
    this.prefsManager = PreferencesManager.getInstance();
  }

  /**
   * 保存当前学期ID
   */
  public async saveCurrentTermId(termId: string): Promise<Result<void>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'saveCurrentTermId', `Saving term ID: ${termId}`)
    );

    return await this.prefsManager.putString(PrefsKey.CURRENT_TERM_ID, termId);
  }

  /**
   * 获取当前学期ID
   */
  public async getCurrentTermId(): Promise<Result<string>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'getCurrentTermId', 'Getting current term ID')
    );

    return await this.prefsManager.getString(PrefsKey.CURRENT_TERM_ID);
  }

  /**
   * 保存当前周次
   */
  public async saveCurrentWeek(week: number): Promise<Result<void>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'saveCurrentWeek', `Saving week: ${week}`)
    );

    return await this.prefsManager.putNumber(PrefsKey.CURRENT_WEEK, week);
  }

  /**
   * 获取当前周次
   */
  public async getCurrentWeek(): Promise<Result<number>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'getCurrentWeek', 'Getting current week')
    );

    return await this.prefsManager.getNumber(PrefsKey.CURRENT_WEEK, 1);
  }

  /**
   * 保存主题模式
   */
  public async saveThemeMode(mode: string): Promise<Result<void>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'saveThemeMode', `Saving theme mode: ${mode}`)
    );

    return await this.prefsManager.putString(PrefsKey.THEME_MODE, mode);
  }

  /**
   * 获取主题模式
   */
  public async getThemeMode(): Promise<Result<string>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'getThemeMode', 'Getting theme mode')
    );

    return await this.prefsManager.getString(PrefsKey.THEME_MODE, 'auto');
  }

  /**
   * 保存首次启动标记
   */
  public async saveIsFirstLaunch(isFirst: boolean): Promise<Result<void>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'saveIsFirstLaunch', `Saving first launch: ${isFirst}`)
    );

    return await this.prefsManager.putBoolean(PrefsKey.IS_FIRST_LAUNCH, isFirst);
  }

  /**
   * 获取首次启动标记
   */
  public async isFirstLaunch(): Promise<Result<boolean>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'isFirstLaunch', 'Checking first launch')
    );

    return await this.prefsManager.getBoolean(PrefsKey.IS_FIRST_LAUNCH, true);
  }

  /**
   * 读取字符串配置
   */
  public async getString(key: string, defaultValue: string = ''): Promise<Result<string>> {
    return await this.prefsManager.getString(key, defaultValue);
  }

  /**
   * 保存字符串配置
   */
  public async putString(key: string, value: string): Promise<Result<void>> {
    return await this.prefsManager.putString(key, value);
  }

  /**
   * 读取布尔配置
   */
  public async getBoolean(key: string, defaultValue: boolean = false): Promise<Result<boolean>> {
    return await this.prefsManager.getBoolean(key, defaultValue);
  }

  /**
   * 保存布尔配置
   */
  public async putBoolean(key: string, value: boolean): Promise<Result<void>> {
    return await this.prefsManager.putBoolean(key, value);
  }

  /**
   * 读取数字配置
   */
  public async getNumber(key: string, defaultValue: number = 0): Promise<Result<number>> {
    return await this.prefsManager.getNumber(key, defaultValue);
  }

  /**
   * 保存数字配置
   */
  public async putNumber(key: string, value: number): Promise<Result<void>> {
    return await this.prefsManager.putNumber(key, value);
  }

  /**
   * 清除所有设置
   */
  public async clearAll(): Promise<Result<void>> {
    Logger.debug(
      SettingRepository.TAG,
      Logger.formatMsg(SettingRepository.TAG, 'clearAll', 'Clearing all settings')
    );

    return await this.prefsManager.clear();
  }
}
