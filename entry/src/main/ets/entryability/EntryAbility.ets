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
   * 临时：创建或更新测试学期
   *
   * 设计原则：
   * 1. 开学日期应该是真实的日期（不要为了显示课程而伪造）
   * 2. 课程显示只依赖周次，不依赖日期
   * 3. "当前周"只用于：页面初始化时跳转 + 高亮标记
   */
  private async createTestTerm(): Promise<void> {
    try {
      const termService = TermService.getInstance();

      // 检查是否已有当前学期
      const existingResult = await termService.getCurrentTerm();

      const term = new TermEntity();
      term.name = '2026-2027学年第1学期';
      term.startDate = new Date('2026-09-01').getTime();  // 真实的开学日期：9月1日
      term.weekCount = 20;
      term.isCurrent = 1;
      term.createdAt = Date.now();
      term.updatedAt = Date.now();

      if (existingResult.isSuccess() && existingResult.getData()) {
        // 已有学期，更新它
        const existing = existingResult.getData()!;
        term.id = existing.id;
        term.createdAt = existing.createdAt;

        const updateResult = await termService.updateTerm(term);
        if (updateResult.isSuccess()) {
          Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '测试学期更新成功'));
        } else {
          Logger.error('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '更新学期失败: %{public}s'),
            updateResult.getError().message);
        }
      } else {
        // 没有学期，创建新的
        const result = await termService.createTerm(term);
        if (result.isSuccess()) {
          Logger.info('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '测试学期创建成功'));
        } else {
          Logger.error('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '创建学期失败: %{public}s'),
            result.getError().message);
        }
      }
    } catch (err) {
      Logger.error('EntryAbility', Logger.formatMsg('EntryAbility', 'createTestTerm', '创建测试学期异常: %{public}s'),
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