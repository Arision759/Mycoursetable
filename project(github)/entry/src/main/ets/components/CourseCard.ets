/**
 * 课程卡片组件（无状态）
 * ⚠️ 关键：使用 @Param，不订阅任何全局状态
 */
import { CourseCardItem } from '../viewmodel/CourseCardItem';

@ComponentV2
export struct CourseCard {
  @Param course: CourseCardItem = {
    id: '',
    name: '',
    teacher: '',
    room: '',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 1,
    startWeek: 1,
    endWeek: 1,
    color: Color.Blue,
    isCurrentWeek: true
  };
  @Event onCardClick: (id: string) => void = () => {}; // 点击回调

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 背景层：非本周课程仅淡化背景色，文字层保持不透明以确保对比度
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(this.course.color)
        .borderRadius(8)
        .opacity(this.course.isCurrentWeek ? 1.0 : 0.55)

      // 内容层
      Column({ space: 2 }) {
        // 课程名
        Text(this.course.name)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_on_card'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        // 教师（自动换行，不截断）
        Text(this.course.teacher)
          .fontSize(11)
          .fontColor($r('app.color.text_on_card'))

        // 教室（自动换行到下一个格子，显示完整信息）
        Text(this.course.room)
          .fontSize(10)
          .fontColor($r('app.color.text_on_card'))
      }
      .width('100%')
      .height('100%')
      .padding(4)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .onClick(() => {
      this.onCardClick(this.course.id); // 触发点击回调
    })
  }
}
