import router from '@ohos.router';
import { Logger } from '../common/logger/Logger';

@Entry
@ComponentV2
struct Index {
  async aboutToAppear() {
    Logger.info('Index', Logger.formatMsg('Index', 'aboutToAppear', '应用启动'));

    // 跳转到登录导入页面
    setTimeout(() => {
      router.replaceUrl({
        url: 'pages/LoginImportPage'
      });
    }, 1000);
  }

  build() {
    Column() {
      Text('课程表')
        .fontSize(50)
        .fontWeight(FontWeight.Bold)

      Text('加载中...')
        .fontSize(16)
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
