/**
 * 学校选择页面
 * 功能：
 * - 搜索/选择学校后进入登录导入流程
 * - 为后期扩展多学校支持做铺垫（schoolList 可扩展为数据库/远程配置）
 */
import router from '@ohos.router';
import { Logger } from '../common/logger/Logger';
import { promptAction } from '@kit.ArkUI';

// 学校信息
interface SchoolOption {
  name: string;       // 学校名称
  logo: string;       // 图标
  supported: boolean; // 是否支持导入
}

// 学校列表（当前仅支持长安大学，其余为扩展预留）
const SCHOOL_LIST: SchoolOption[] = [
  { name: '长安大学', logo: '🏫', supported: true },
  { name: '西安交通大学', logo: '🏫', supported: false },
  { name: '西北工业大学', logo: '🏫', supported: false },
  { name: '陕西师范大学', logo: '🏫', supported: false }
];

// 路由参数
class SchoolRouteParams {
  schoolName: string = '';
}

@Entry
@ComponentV2
struct SchoolSelectPage {
  @Local searchText: string = '';

  /**
   * 按搜索词过滤学校列表
   */
  private getFilteredSchools(): SchoolOption[] {
    if (this.searchText.length === 0) {
      return SCHOOL_LIST;
    }
    return SCHOOL_LIST.filter((school: SchoolOption) => school.name.includes(this.searchText));
  }

  /**
   * 点击学校
   */
  private onSchoolClick(school: SchoolOption) {
    if (!school.supported) {
      promptAction.showToast({ message: `${school.name} 即将支持，敬请期待` });
      return;
    }

    Logger.info('SchoolSelectPage', Logger.formatMsg('SchoolSelectPage', 'onSchoolClick', `选择学校：${school.name}`));

    const params = new SchoolRouteParams();
    params.schoolName = school.name;
    router.pushUrl({ url: 'pages/LoginImportPage', params: params });
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button('←')
          .fontSize(20)
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.text_primary'))
          .onClick(() => {
            router.back();
          })

        Text('选择学校')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 右侧占位，保持标题居中
        Text('')
          .width(56)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor($r('app.color.card_bg'))

      // 搜索框
      TextInput({ placeholder: '搜索学校', text: this.searchText })
        .width('92%')
        .height(44)
        .fontSize(15)
        .placeholderColor($r('app.color.text_secondary'))
        .borderRadius(22)
        .backgroundColor($r('app.color.input_bg'))
        .padding({ left: 20, right: 20 })
        .margin({ top: 16, bottom: 8 })
        .onChange((value: string) => {
          this.searchText = value;
        })

      // 学校列表
      List({ space: 12 }) {
        ForEach(this.getFilteredSchools(), (school: SchoolOption) => {
          ListItem() {
            Row({ space: 12 }) {
              // 学校图标
              Text(school.logo)
                .fontSize(28)

              // 学校名
              Column({ space: 2 }) {
                Text(school.name)
                  .fontSize(16)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 支持状态标签
              if (school.supported) {
                Text('支持导入')
                  .fontSize(11)
                  .fontColor($r('app.color.accent'))
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor($r('app.color.accent_bg'))
                  .borderRadius(10)
              } else {
                Text('即将支持')
                  .fontSize(11)
                  .fontColor($r('app.color.text_secondary'))
                  .padding({ left: 8, right: 8, top: 3, bottom: 3 })
                  .backgroundColor($r('app.color.divider_color'))
                  .borderRadius(10)
              }
            }
            .width('100%')
            .padding(16)
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(12)
            .onClick(() => {
              this.onSchoolClick(school);
            })
          }
        }, (school: SchoolOption) => school.name)
      }
      .width('92%')
      .layoutWeight(1)
      .edgeEffect(EdgeEffect.Spring)
      .padding({ top: 8 })

      // 底部提示
      Text('更多学校陆续支持中，敬请期待')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 24 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }
}
