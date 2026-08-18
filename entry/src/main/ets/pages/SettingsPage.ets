/**
 * 设置页面
 * 功能：
 * - 学期选择（教务系统未解析出学期信息时手动选择）
 * - 开学日期设置（影响周次计算和课表日期显示）
 */
import { TermService } from '../service/TermService';
import { Logger } from '../common/logger/Logger';
import { DateUtil } from '../common/util/DateUtil';
import router from '@ohos.router';
import { promptAction } from '@kit.ArkUI';

// 预设学期选项
const TERM_OPTIONS: string[] = [
  '2025-2026学年第2学期',
  '2026-2027学年第1学期',
  '2026-2027学年第2学期',
  '2027-2028学年第1学期',
  '2027-2028学年第2学期',
  '2028-2029学年第1学期'
];

@Entry
@ComponentV2
struct SettingsPage {
  // 学期信息
  @Local termId: string = '';
  @Local termName: string = '';
  @Local startDateText: string = '';
  @Local selectedTermIndex: number = 1;
  @Local pickerDate: Date = new Date('2026-09-01');
  @Local isLoading: boolean = true;

  async aboutToAppear() {
    Logger.info('SettingsPage', Logger.formatMsg('SettingsPage', 'aboutToAppear', '设置页面初始化'));
    await this.loadTerm();
  }

  /**
   * 加载当前学期信息
   */
  private async loadTerm() {
    try {
      const result = await TermService.getInstance().getCurrentTerm();
      if (result.isSuccess() && result.getData()) {
        const term = result.getData()!;
        this.termId = term.id;
        this.termName = term.name;
        this.startDateText = DateUtil.formatDate(term.startDate);
        this.pickerDate = new Date(term.startDate);

        // 匹配预设学期选项（当前学期可能在预设列表之外，保持不选中状态）
        const idx = TERM_OPTIONS.indexOf(term.name);
        if (idx >= 0) {
          this.selectedTermIndex = idx;
        }

        Logger.info('SettingsPage',
          Logger.formatMsg('SettingsPage', 'loadTerm', `学期：${term.name}，开学日期：${this.startDateText}`));
      } else {
        Logger.warn('SettingsPage', Logger.formatMsg('SettingsPage', 'loadTerm', '未找到当前学期'));
      }
    } catch (err) {
      Logger.error('SettingsPage', Logger.formatMsg('SettingsPage', 'loadTerm', '加载学期异常: %{public}s'),
        JSON.stringify(err));
    }
    this.isLoading = false;
  }

  /**
   * 保存设置
   */
  private async saveSettings() {
    try {
      // 1. 获取当前学期
      const result = await TermService.getInstance().getCurrentTerm();
      if (!result.isSuccess() || !result.getData()) {
        promptAction.showToast({ message: '未找到学期信息' });
        return;
      }

      // 2. 更新学期名称和开学日期
      const term = result.getData()!;
      term.name = this.termName;
      term.startDate = this.pickerDate.getTime();
      term.updatedAt = Date.now();

      const updateResult = await TermService.getInstance().updateTerm(term);
      if (updateResult.isSuccess()) {
        Logger.info('SettingsPage',
          Logger.formatMsg('SettingsPage', 'saveSettings',
            `保存成功：${term.name}，开学日期 ${DateUtil.formatDate(term.startDate)}`));
        promptAction.showToast({ message: '保存成功' });
        router.back();
      } else {
        Logger.error('SettingsPage',
          Logger.formatMsg('SettingsPage', 'saveSettings', '保存失败: %{public}s'),
          updateResult.getError().message);
        promptAction.showToast({ message: '保存失败，请重试' });
      }
    } catch (err) {
      Logger.error('SettingsPage', Logger.formatMsg('SettingsPage', 'saveSettings', '保存异常: %{public}s'),
        JSON.stringify(err));
      promptAction.showToast({ message: '保存失败，请重试' });
    }
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('←')
          .fontSize(20)
          .backgroundColor(Color.Transparent)
          .fontColor('#333333')
          .onClick(() => {
            router.back();
          })

        Text('设置')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Button('保存')
          .fontSize(15)
          .backgroundColor(Color.Transparent)
          .fontColor('#007DFF')
          .onClick(() => {
            this.saveSettings();
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor(Color.White)

      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: 16 }) {
            // 学期选择卡片
            Column({ space: 8 }) {
              Text('学期选择')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)

              Text('教务系统未提供学期信息，请手动选择当前学期')
                .fontSize(12)
                .fontColor('#999999')

              TextPicker({ range: TERM_OPTIONS, selected: this.selectedTermIndex })
                .onChange((value: string | string[], index: number | number[]) => {
                  this.termName = value as string;
                  this.selectedTermIndex = index as number;
                })
                .height(130)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 开学日期卡片
            Column({ space: 8 }) {
              Text('开学日期')
                .fontSize(15)
                .fontWeight(FontWeight.Medium)

              Text(`当前：${this.startDateText}`)
                .fontSize(12)
                .fontColor('#999999')

              DatePicker({
                start: new Date('2024-01-01'),
                end: new Date('2030-12-31'),
                selected: this.pickerDate
              })
                .onChange((value: DatePickerResult) => {
                  this.pickerDate = new Date(value.year ?? 0, value.month ?? 0, value.day ?? 1);
                  this.startDateText = DateUtil.formatDate(this.pickerDate.getTime());
                })
                .height(200)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(Color.White)
            .borderRadius(12)
            .alignItems(HorizontalAlign.Start)

            // 说明
            Text('说明：开学日期为第1周的周一，用于计算当前周次和课表上方每天对应的日期。')
              .fontSize(12)
              .fontColor('#999999')
              .padding({ left: 16, right: 16 })
          }
          .width('100%')
          .padding({ top: 16, bottom: 24 })
        }
        .scrollBar(BarState.Auto)
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
