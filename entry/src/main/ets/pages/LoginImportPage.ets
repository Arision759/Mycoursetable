/**
 * 登录导入页面
 * 用户输入账号密码，自动登录并导入课表
 */
import { EamsLoginService } from '../service/EamsLoginService';
import { CourseParserFromJS } from '../utils/CourseParserFromJS';
import { ScheduleService } from '../service/ScheduleService';
import { TermService } from '../service/TermService';
import { Logger } from '../common/logger/Logger';
import router from '@ohos.router';

const TAG = 'LoginImportPage';

@Entry
@Component
struct LoginImportPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State statusText: string = '';
  @State errorText: string = '';

  build() {
    Column() {
      // 顶部留白
      Column().height(80)

      // 标题
      Text('📚 课程表')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Text('长安大学教务系统')
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 48 })

      // 学号输入
      TextInput({ placeholder: '请输入学号', text: this.username })
        .type(InputType.Number)
        .width('80%')
        .height(48)
        .fontSize(16)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          this.username = value;
        })

      // 密码输入
      TextInput({ placeholder: '请输入密码', text: this.password })
        .type(InputType.Password)
        .width('80%')
        .height(48)
        .fontSize(16)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')
        .padding({ left: 16, right: 16 })
        .margin({ bottom: 32 })
        .onChange((value: string) => {
          this.password = value;
        })

      // 登录按钮
      Button('登录并导入课表')
        .width('80%')
        .height(48)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .borderRadius(24)
        .enabled(!this.isLoading)
        .opacity(this.isLoading ? 0.6 : 1.0)
        .onClick(() => {
          this.startImport();
        })

      // 状态提示
      if (this.statusText.length > 0) {
        Text(this.statusText)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 24 })
      }

      // 加载动画
      if (this.isLoading) {
        LoadingProgress()
          .width(36)
          .height(36)
          .color('#007DFF')
          .margin({ top: 16 })
      }

      // 错误提示
      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(14)
          .fontColor('#FF3B30')
          .margin({ top: 24 })
          .textAlign(TextAlign.Center)
      }

      // 底部留白
      Blank()

      Text('首次使用需要登录教务系统导入课表')
        .fontSize(12)
        .fontColor('#CCCCCC')
        .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.White)
  }

  /**
   * 开始导入流程
   */
  private async startImport(): Promise<void> {
    // 验证输入
    if (this.username.length === 0) {
      this.errorText = '请输入学号';
      return;
    }
    if (this.password.length === 0) {
      this.errorText = '请输入密码';
      return;
    }

    this.isLoading = true;
    this.errorText = '';
    this.statusText = '正在登录...';

    Logger.info(TAG, Logger.formatMsg(TAG, 'startImport', '开始导入流程'));

    try {
      // 1. 登录并获取课表 HTML
      this.statusText = '正在登录教务系统...';
      const loginService = EamsLoginService.getInstance();
      const result = await loginService.loginAndGetCourseTable(this.username, this.password);

      if (!result.success) {
        this.errorText = result.message;
        this.statusText = '';
        this.isLoading = false;
        Logger.error(TAG, Logger.formatMsg(TAG, 'startImport', `登录失败: ${result.message}`));
        return;
      }

      // 2. 获取当前学期
      this.statusText = '正在解析课程...';
      const termResult = await TermService.getInstance().getCurrentTerm();
      if (!termResult.isSuccess() || !termResult.getData()) {
        this.errorText = '未找到当前学期信息';
        this.statusText = '';
        this.isLoading = false;
        return;
      }
      const termId = termResult.getData()!.id;

      // 3. 解析课程
      const courses = CourseParserFromJS.parse(result.courseHtml, termId);

      if (courses.length === 0) {
        this.errorText = '未解析到课程信息，请稍后重试';
        this.statusText = '';
        this.isLoading = false;
        Logger.error(TAG, Logger.formatMsg(TAG, 'startImport', '解析到 0 门课程'));
        return;
      }

      Logger.info(TAG, Logger.formatMsg(TAG, 'startImport', `解析到 ${courses.length} 门课程`));

      // 4. 清空旧数据
      this.statusText = '正在导入课程...';
      await ScheduleService.getInstance().clearAllCourses(termId);

      // 5. 导入新课程
      const importResult = await ScheduleService.getInstance().importCourses(courses);

      if (!importResult.isSuccess()) {
        this.errorText = '导入数据库失败';
        this.statusText = '';
        this.isLoading = false;
        return;
      }

      // 6. 成功
      this.statusText = `导入成功！共 ${courses.length} 门课程`;
      Logger.info(TAG, Logger.formatMsg(TAG, 'startImport',
        `✅ 导入成功，共 ${courses.length} 门课程`));

      // 延迟跳转到课表页
      setTimeout(() => {
        router.replaceUrl({
          url: 'pages/WeekSchedulePage'
        });
      }, 1500);

    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'startImport', `异常: ${JSON.stringify(err)}`));
      this.errorText = '导入过程出错，请重试';
      this.statusText = '';
      this.isLoading = false;
    }
  }
}
