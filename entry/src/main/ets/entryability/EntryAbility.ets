import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { RdbManager } from '../datasource/db/RdbManager';
import { PreferencesManager } from '../datasource/prefs/PreferencesManager';
import { Logger } from '../common/logger/Logger';
import { TermEntity } from '../model/entity/TermEntity';
import { TermService } from '../service/TermService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');

    // 1. 初始化 Logger
    Logger.configure({ enableDebug: true });
    Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'onCreate', 'Application starting...'));

    // 2. 初始化数据库
    try {
      const dbResult = await RdbManager.getInstance().init(this.context);
      if (dbResult.isSuccess()) {
        Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'onCreate', 'Database initialized'));
      } else {
        Logger.error(
          'EntryAbility',
          Logger.formatMsg('EntryAbility', 'onCreate', 'Database init failed: %{public}s'),
          dbResult.getError().message
        );
      }
    } catch (err) {
      Logger.error(
        'EntryAbility',
        Logger.formatMsg('EntryAbility', 'onCreate', 'Database init exception: %{public}s'),
        JSON.stringify(err)
      );
    }

    // 3. 初始化 Preferences
    try {
      const prefsResult = await PreferencesManager.getInstance().init(this.context);
      if (prefsResult.isSuccess()) {
        Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'onCreate', 'Preferences initialized'));
      } else {
        Logger.error(
          'EntryAbility',
          Logger.formatMsg('EntryAbility', 'onCreate', 'Preferences init failed: %{public}s'),
          prefsResult.getError().message
        );
      }
    } catch (err) {
      Logger.error(
        'EntryAbility',
        Logger.formatMsg('EntryAbility', 'onCreate', 'Preferences init exception: %{public}s'),
        JSON.stringify(err)
      );
    }

    // ✅ 4. 创建测试学期
    await this.createTestTerm();

    // 5. 处理通知跳转参数（为后续通知功能预留）
    this.handleWantParameters(want);
  }

  private handleWantParameters(want: Want): void {
    const params = want.parameters;
    if (params) {
      // 存储跳转参数到 AppStorage
      if (params.targetPage) {
        AppStorage.setOrCreate('jumpToPage', params.targetPage);
      }
      if (params.focusDate) {
        AppStorage.setOrCreate('jumpToDate', params.focusDate);
      }
    }
  }

  /**
   * 初始化默认学期
   *
   * 设计原则：
   * 1. 只在数据库没有学期时创建默认值（首次安装）
   * 2. 已存在学期时不覆盖，避免重置用户在设置页修改的开学日期/学期名称
   * 3. "当前周"只用于：页面初始化时跳转 + 高亮标记
   */
  private async createTestTerm(): Promise<void> {
    try {
      const termService = TermService.getInstance();

      // 检查是否已有当前学期
      const existingResult = await termService.getCurrentTerm();
      if (existingResult.isSuccess() && existingResult.getData()) {
        // 已有学期（可能已被用户在设置页修改过），不再覆盖
        Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '学期已存在，跳过初始化'));
        return;
      }

      const term = new TermEntity();
      term.name = '2026-2027学年第1学期';
      term.startDate = new Date('2026-09-01').getTime();  // 默认开学日期：9月1日
      term.weekCount = 20;
      term.isCurrent = 1;
      term.createdAt = Date.now();
      term.updatedAt = Date.now();

      const result = await termService.createTerm(term);
      if (result.isSuccess()) {
        Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '默认学期创建成功'));
      } else {
        Logger.error('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '创建学期失败: %{public}s'),
          result.getError().message);
      }
    } catch (err) {
      Logger.error('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '创建默认学期异常: %{public}s'),
        JSON.stringify(err));
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 热启动时处理通知跳转
    this.handleWantParameters(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}