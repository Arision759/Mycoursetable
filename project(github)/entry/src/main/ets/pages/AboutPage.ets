import router from '@ohos.router';

/**
 * 关于我们页面
 * 用途：
 * - 展示应用名称、开发者名称、版本号等基础信息。
 * - 用于上架、备案、商户服务开通等场景下的主体信息截图材料。
 */
@Entry
@Component
struct AboutPage {
  build() {
    Column() {
      // 顶部导航
      Row({ space: 12 }) {
        Text('‹')
          .fontSize(28)
          .fontColor($r('app.color.text_heading'))
          .onClick(() => {
            router.back();
          })

        Text('关于我们')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_heading'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      Column({ space: 24 }) {
        Column({ space: 8 }) {
          Text('我的课表')
            .fontSize(26)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_heading'))

          Text('长安大学课程表导入与展示工具')
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')

        Column({ space: 0 }) {
          Row() {
            Text('应用名称')
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Text('我的课表')
              .fontSize(15)
              .fontColor($r('app.color.text_heading'))
          }
          .width('100%')
          .padding(16)

          Divider()
            .color($r('app.color.divider_color'))

          Row() {
            Text('开发者')
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Text('开发者')
              .fontSize(15)
              .fontColor($r('app.color.text_heading'))
          }
          .width('100%')
          .padding(16)

          Divider()
            .color($r('app.color.divider_color'))

          Row() {
            Text('版本号')
              .fontSize(15)
              .fontColor($r('app.color.text_primary'))
            Blank()
            Text('1.0.0')
              .fontSize(15)
              .fontColor($r('app.color.text_heading'))
          }
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(12)

        Text('本应用仅用于帮助用户导入、管理并展示个人课程表。课程数据仅保存在本机，账号信息仅用于学校教务系统认证。')
          .fontSize(13)
          .lineHeight(20)
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      }
      .width('100%')
      .padding(16)
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
