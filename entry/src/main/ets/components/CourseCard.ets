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
    color: Color.Blue,
    isCurrentWeek: true
  };
  @Event onCardClick: (id: string) => void = () => {}; // 点击回调

  build() {
    Column({ space: 2 }) {
      // 课程名
      Text(this.course.name)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 教师
      Text(this.course.teacher)
        .fontSize(11)
        .fontColor(Color.White)
        .opacity(0.85)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 教室
      Text(this.course.room)
        .fontSize(10)
        .fontColor(Color.White)
        .opacity(0.7)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height('100%')
    .padding(4)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
    .backgroundColor(this.course.color)
    .borderRadius(8)
    .opacity(this.course.isCurrentWeek ? 1.0 : 0.3) // 非本周课程半透明
    .onClick(() => {
      this.onCardClick(this.course.id); // 触发点击回调
    })
  }
}
