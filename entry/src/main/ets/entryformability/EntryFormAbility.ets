/**
 * 服务卡片扩展 Ability
 * 负责在卡片创建、更新时刷新下一节课程数据。
 */
import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { DesktopCardService, DesktopCardData } from '../service/DesktopCardService';
import { Logger } from '../common/logger/Logger';

export default class EntryFormAbility extends FormExtensionAbility {
  private static readonly TAG: string = 'EntryFormAbility';

  onAddForm(want: Want): formBindingData.FormBindingData {
    Logger.info(
      EntryFormAbility.TAG,
      Logger.formatMsg(EntryFormAbility.TAG, 'onAddForm', '创建卡片并加载数据')
    );

    // 异步加载真实数据前，先给出一份可显示的占位数据。
    const initialData = DesktopCardService.buildInitialCardData();
    const formId = want?.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string;

    if (formId) {
      this.refreshForm(formId);
    }

    return formBindingData.createFormBindingData(initialData);
  }

  onUpdateForm(formId: string, wantParams?: Record<string, Object>): void {
    Logger.info(
      EntryFormAbility.TAG,
      Logger.formatMsg(EntryFormAbility.TAG, 'onUpdateForm', `刷新卡片：${formId}`)
    );

    this.refreshForm(formId);
  }

  /**
   * 异步刷新指定卡片。
   * FormExtensionAbility 生命周期接口必须保持同步返回，因此这里使用 Promise 回调处理。
   */
  private refreshForm(formId: string): void {
    DesktopCardService.buildCardData(this.context)
      .then((cardData: DesktopCardData): void => {
        const bindingData = formBindingData.createFormBindingData(cardData);
        formProvider.updateForm(formId, bindingData);

        const delayMinutes = DesktopCardService.getNextRefreshDelayMinutes(
          cardData.nextRefreshTimestamp,
          Date.now()
        );
        if (delayMinutes > 0) {
          formProvider.setFormNextRefreshTime(formId, delayMinutes)
            .catch((scheduleErr: Error): void => {
              Logger.warn(
                EntryFormAbility.TAG,
                Logger.formatMsg(EntryFormAbility.TAG, 'refreshForm', '安排下次刷新失败: %{public}s'),
                JSON.stringify(scheduleErr)
              );
            });
        }
      })
      .catch((err: Error): void => {
        Logger.error(
          EntryFormAbility.TAG,
          Logger.formatMsg(EntryFormAbility.TAG, 'refreshForm', '刷新卡片异常: %{public}s'),
          JSON.stringify(err)
        );
      });
  }
}
