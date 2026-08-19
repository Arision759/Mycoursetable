/**
 * 桌面服务卡片页面
 * 仅使用基础声明式组件，通过 LocalStorageProp 接收 FormBindingData 数据。
 */
@Entry
@Component
struct WidgetCard {
  @LocalStorageProp('reminderEnabled') reminderEnabled: boolean = false;
  @LocalStorageProp('title') title: string = '下一节课';
  @LocalStorageProp('courseName') courseName: string = '';
  @LocalStorageProp('timeText') timeText: string = '--';
  @LocalStorageProp('locationText') locationText: string = '--';
  @LocalStorageProp('teacherText') teacherText: string = '--';
  @LocalStorageProp('message') message: string = '';

  private readonly warmColors: string[] = [
    '#FFF3E0', '#FFE0B2', '#FFECB3', '#FFCCBC', '#FFE8D6',
    '#FDE2D0', '#FFE5CA', '#FFD9B8', '#FFEFD5', '#FCE4D0'
  ];

  private getRandomWarmColor(): string {
    return this.warmColors[Math.floor(Math.random() * this.warmColors.length)];
  }

  build() {
    Stack() {
      Column({ space: 4 }) {
        Text(this.title)
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor('#8C8C8C')

        if (this.reminderEnabled && this.message.length === 0) {
          Text(this.courseName.length > 0 ? this.courseName : '未填写课程名称')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1F1F1F')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })

          this.InfoRow('时间', this.timeText)
          this.InfoRow('教室', this.locationText)
          this.InfoRow('老师', this.teacherText)
        } else {
          Text(this.message.length > 0 ? this.message : '--')
            .fontSize(13)
            .fontColor('#666666')
            .margin({ top: 4 })
        }
      }
      .width('100%')
      .padding(12)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.White)
      .borderRadius(12)
    }
    .width('100%')
    .height('100%')
    .padding(10)
    .backgroundColor(this.getRandomWarmColor())
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row({ space: 6 }) {
      Text(`${label} `)
        .fontSize(12)
        .fontColor('#8C8C8C')

      Text(value)
        .fontSize(12)
        .fontColor('#1F1F1F')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
  }
}
