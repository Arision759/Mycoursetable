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
