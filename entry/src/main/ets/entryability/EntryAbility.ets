import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AppInitializer } from '../service/AppInitializer';

const DOMAIN = 0x0000;
const TAG = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }

    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');

    // 处理跳转参数（如桌面卡片或通知跳转到指定页面）。
    this.handleWantParameters(want);
  }

  private handleWantParameters(want: Want): void {
    const params = want.parameters;
    if (params) {
      if (params.targetPage) {
        AppStorage.setOrCreate('jumpToPage', params.targetPage);
      }
      if (params.focusDate) {
        AppStorage.setOrCreate('jumpToDate', params.focusDate);
      }
    }
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.handleWantParameters(want);
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');
    this.loadInitialPage(windowStage);
  }

  private async loadInitialPage(windowStage: window.WindowStage): Promise<void> {
    const page = 'pages/WeekSchedulePage';

    try {
      await AppInitializer.initialize(this.context);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to initialize app. Cause: %{public}s', JSON.stringify(err));
    }

    windowStage.loadContent(page, (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }
}
