/**
 * 课程详情弹窗
 */
import { CourseDetailItem } from '../viewmodel/CourseDetailItem';

@CustomDialog
export struct CourseDetailDialog {
  controller: CustomDialogController;
  @State detail: CourseDetailItem = {
    courseName: '',
    courseCode: '',
    teachers: '',
    dayOfWeek: '',
    sectionRange: '',
    timeRange: '',
    classrooms: []
  };

  build() {
    Column({ space: 16 }) {
      // 标题
      Column({ space: 4 }) {
        Text(this.detail.courseName)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)

        Text(this.detail.courseCode)
          .fontSize(14)
          .fontColor('#666666')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Divider()

      // 时间信息
      Column({ space: 8 }) {
        Row() {
          Text('📅')
            .fontSize(16)
            .width(30)

          Text(`${this.detail.dayOfWeek} ${this.detail.sectionRange}`)
            .fontSize(15)
        }
        .width('100%')

        Row() {
          Text('⏰')
            .fontSize(16)
            .width(30)

          Text(this.detail.timeRange)
            .fontSize(15)
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      Divider()

      // 教师
      Row() {
        Text('👨‍🏫')
          .fontSize(16)
          .width(30)

        Text(this.detail.teachers)
          .fontSize(15)
      }
      .width('100%')

      Divider()

      // 教室
      Column({ space: 8 }) {
        Row() {
          Text('📍')
            .fontSize(16)
            .width(30)

          Text('教室')
            .fontSize(15)
            .fontWeight(FontWeight.Medium)
        }
        .width('100%')

        ForEach(this.detail.classrooms, (classroom: string) => {
          Text(classroom)
            .fontSize(14)
            .fontColor('#666666')
            .padding({ left: 30 })
        })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // 关闭按钮
      Button('关闭')
        .width('100%')
        .onClick(() => {
          this.controller.close();
        })
    }
    .padding(20)
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
