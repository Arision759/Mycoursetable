import { RdbManager } from '../datasource/db/RdbManager';
import { PreferencesManager } from '../datasource/prefs/PreferencesManager';
import { Logger } from '../common/logger/Logger';
import { TermEntity } from '../model/entity/TermEntity';
import { TermService } from './TermService';

/**
 * 用户同意隐私政策后，再执行数据层初始化。
 * 避免在未获得授权前访问数据库、偏好设置等本地存储。
 */
export class AppInitializer {
  private static initialized: boolean = false;

  public static async initialize(context: Context): Promise<void> {
    if (AppInitializer.initialized) {
      return;
    }

    const prefsResult = await PreferencesManager.getInstance().init(context);
    if (!prefsResult.isSuccess()) {
      Logger.error('AppInitializer', Logger.formatMsg('AppInitializer', 'initialize', 'Preferences 初始化失败'));
      return;
    }

    const dbResult = await RdbManager.getInstance().init(context);
    if (!dbResult.isSuccess()) {
      Logger.error('AppInitializer', Logger.formatMsg('AppInitializer', 'initialize', '数据库初始化失败'));
      return;
    }

    await AppInitializer.createDefaultTerm();
    AppInitializer.initialized = true;
  }

  /**
   * 首次安装时创建默认学期，已存在则不覆盖。
   */
  private static async createDefaultTerm(): Promise<void> {
    try {
      const termService = TermService.getInstance();
      const existingResult = await termService.getCurrentTerm();
      if (existingResult.isSuccess() && existingResult.getData()) {
        return;
      }

      const term = new TermEntity();
      term.name = '2026-2027学年第1学期';
      term.startDate = new Date('2026-09-01').getTime();
      term.weekCount = 20;
      term.isCurrent = 1;
      term.createdAt = Date.now();
      term.updatedAt = Date.now();

      const result = await termService.createTerm(term);
      if (!result.isSuccess()) {
        Logger.error('AppInitializer', Logger.formatMsg('AppInitializer', 'createDefaultTerm', '创建学期失败: %{public}s'),
          result.getError().message);
      }
    } catch (err) {
      Logger.error('AppInitializer', Logger.formatMsg('AppInitializer', 'createDefaultTerm', '创建默认学期异常: %{public}s'),
        JSON.stringify(err));
    }
  }
}
