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

// 路由参数（学校选择页传入）
class LoginRouteParams {
  schoolName: string = '';
}

@Entry
@Component
struct LoginImportPage {
  @State username: string = '';
  @State password: string = '';
  @State isLoading: boolean = false;
  @State statusText: string = '';
  @State errorText: string = '';
  @State schoolName: string = '长安大学';

  aboutToAppear() {
    // 读取学校选择页传入的学校名
    try {
      const params = router.getParams() as LoginRouteParams;
      if (params && params.schoolName.length > 0) {
        this.schoolName = params.schoolName;
      }
    } catch (err) {
      // 无参数时使用默认学校名
    }
  }

  build() {
    Column() {
      // 顶部留白
      Column().height(80)

      // 标题
      Text('📚 课程表')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 8 })

      Text(`${this.schoolName}教务系统`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 48 })

      // 学号输入
      TextInput({ placeholder: '请输入学号', text: this.username })
        .type(InputType.Number)
        .width('80%')
        .height(48)
        .fontSize(16)
        .placeholderColor($r('app.color.text_secondary'))
        .borderRadius(8)
        .backgroundColor($r('app.color.page_bg'))
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
        .placeholderColor($r('app.color.text_secondary'))
        .borderRadius(8)
        .backgroundColor($r('app.color.page_bg'))
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
        .backgroundColor($r('app.color.accent'))
        .fontColor($r('app.color.card_bg'))
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
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 24 })
      }

      // 加载动画
      if (this.isLoading) {
        LoadingProgress()
          .width(36)
          .height(36)
          .color($r('app.color.accent'))
          .margin({ top: 16 })
      }

      // 错误提示
      if (this.errorText.length > 0) {
        Text(this.errorText)
          .fontSize(14)
          .fontColor('#C62828')
          .margin({ top: 24 })
          .textAlign(TextAlign.Center)
      }

      // 底部留白
      Blank()

      Text('首次使用需要登录教务系统导入课表')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.card_bg'))
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

      // 延迟返回课表主页（返回已有页面，触发 onPageShow 自动刷新课程）
      setTimeout(() => {
        router.back({
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
