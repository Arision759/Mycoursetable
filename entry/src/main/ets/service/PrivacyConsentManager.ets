import { PreferencesManager } from '../datasource/prefs/PreferencesManager';
import { Logger } from '../common/logger/Logger';

/**
 * 隐私政策授权记录管理。
 * 仅负责“下次不再提醒”偏好，供启动页判断是否跳过隐私弹窗。
 */
export class PrivacyConsentManager {
  private static readonly TAG: string = 'PrivacyConsentManager';
  private static readonly NO_REMIND_KEY: string = 'privacy_no_remind';

  /**
   * 是否需要显示隐私政策弹窗。
   * 读取偏好失败时默认显示，避免绕过授权提示。
   */
  public static async shouldShowDialog(context: Context): Promise<boolean> {
    const prefsResult = await PreferencesManager.getInstance().init(context);
    if (!prefsResult.isSuccess()) {
      return true;
    }

    const noRemindResult = await PreferencesManager.getInstance()
      .getBoolean(PrivacyConsentManager.NO_REMIND_KEY, false);
    if (!noRemindResult.isSuccess()) {
      return true;
    }

    return !noRemindResult.getData();
  }

  /**
   * 保存“下次不再提醒”偏好。
   */
  public static async setNoRemind(context: Context, enabled: boolean): Promise<void> {
    const prefsResult = await PreferencesManager.getInstance().init(context);
    if (!prefsResult.isSuccess()) {
      Logger.error(PrivacyConsentManager.TAG,
        Logger.formatMsg(PrivacyConsentManager.TAG, 'setNoRemind', 'Preferences 初始化失败'));
      return;
    }

    await PreferencesManager.getInstance().putBoolean(PrivacyConsentManager.NO_REMIND_KEY, enabled);
  }
}
