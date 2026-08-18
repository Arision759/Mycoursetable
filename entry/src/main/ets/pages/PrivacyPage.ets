import { router } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { AppInitializer } from '../service/AppInitializer';
import { PrivacyConsentManager } from '../service/PrivacyConsentManager';

@Entry
@Component
struct PrivacyPage {
  @State agreed: boolean = false;
  @State noRemind: boolean = false;
  @State initializing: boolean = false;

  private async agree(): Promise<void> {
    if (!this.agreed || this.initializing) {
      return;
    }

    this.initializing = true;
    try {
      await AppInitializer.initialize(getContext(this));
      await PrivacyConsentManager.setNoRemind(getContext(this), this.noRemind);
      router.replaceUrl({ url: 'pages/WeekSchedulePage' });
    } finally {
      this.initializing = false;
    }
  }

  private disagree(): void {
    const context = getContext(this) as common.UIAbilityContext;
    context.terminateSelf();
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      Column({ space: 16 }) {
        Text('隐私政策与用户协议')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1A1A1A')

        Scroll() {
          Column({ space: 12 }) {
            Text('1. 本应用仅在本地存储课程表数据，不上传至第三方服务器。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor('#333333')
            Text('2. 登录教务系统时，账号信息仅用于学校教务系统认证，应用不会保存明文密码。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor('#333333')
            Text('3. 导入课程表时，应用需要访问学校教务网站，并读取课表页面数据。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor('#333333')
            Text('4. 继续使用即表示你已阅读并同意上述说明。')
              .fontSize(14)
              .lineHeight(22)
              .fontColor('#333333')
          }
          .width('100%')
          .padding({ left: 6, right: 6 })
        }
        .layoutWeight(1)
        .width('100%')
        .align(Alignment.TopStart)

        Row({ space: 8 }) {
          Checkbox()
            .select(this.agreed)
            .onChange((value: boolean) => {
              this.agreed = value;
            })
          Text('我已阅读并同意')
            .fontSize(14)
            .fontColor('#333333')
        }
        .width('100%')

        Row({ space: 8 }) {
          Checkbox()
            .select(this.noRemind)
            .onChange((value: boolean) => {
              this.noRemind = value;
            })
          Text('下次不再提醒（永久生效）')
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('100%')

        Row({ space: 12 }) {
          Button('不同意并退出')
            .layoutWeight(1)
            .height(42)
            .fontSize(15)
            .backgroundColor('#E5E5E5')
            .fontColor('#333333')
            .onClick(() => {
              this.disagree();
            })

          Button(this.initializing ? '初始化中...' : '同意并继续')
            .layoutWeight(1)
            .height(42)
            .fontSize(15)
            .backgroundColor(this.agreed ? '#007DFF' : '#AFCFFF')
            .fontColor(Color.White)
            .enabled(this.agreed && !this.initializing)
            .onClick(() => {
              this.agree();
            })
        }
        .width('100%')
      }
      .width('88%')
      .height(500)
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(20)
      .shadow({
        radius: 24,
        color: '#33000000',
        offsetX: 0,
        offsetY: 8
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#99000000')
  }
}
