/**
 * 课表导入页面
 * 使用 WebView 登录教务系统并解析课表
 */
import webview from '@ohos.web.webview';
import { CourseParser } from '../utils/CourseParser';
import { CourseParserFromJS } from '../utils/CourseParserFromJS';
import { ScheduleService } from '../service/ScheduleService';
import { TermService } from '../service/TermService';
import { Logger } from '../common/logger/Logger';
import router from '@ohos.router';

@Entry
@Component
struct ImportPage {
  @State isLoading: boolean = true;
  @State loadingText: string = '正在加载...';
  @State debugInfo: string = '';
  private controller: webview.WebviewController = new webview.WebviewController();
  private pageLoaded: boolean = false;
  private hasTriggeredParse: boolean = false;  // 防止重复触发解析
  private hasRedirectedToCourse: boolean = false;  // 防止重复跳转课表页

  aboutToAppear(): void {
    // 加载超时保护
    setTimeout(() => {
      if (!this.pageLoaded && this.isLoading) {
        this.isLoading = false;
      }
    }, 15000);
  }

  build() {
    Stack() {
      // WebView
      Web({
        src: 'http://bkjw.chd.edu.cn/eams/login.action',
        controller: this.controller
      })
        .javaScriptAccess(true)
        .domStorageAccess(false)
        .mixedMode(MixedMode.None)
        .cacheMode(CacheMode.None)
        .onPageEnd((event) => {
          if (event) {
            this.pageLoaded = true;
            const url = event.url || '';
            Logger.info(
              'ImportPage',
              Logger.formatMsg('ImportPage', 'onPageEnd', `页面加载完成: ${url.split('?')[0]}`)
            );

            // 判断当前页面类型并执行对应操作
            this.handlePageLoaded(url);
          }
        })
        .onPageBegin(() => {
          Logger.info('ImportPage', Logger.formatMsg('ImportPage', 'onPageBegin', '页面开始加载'));
        })
        .onErrorReceive((event) => {
          if (event) {
            const errorCode = event.error.getErrorCode();
            const errorInfo = event.error.getErrorInfo();
            const requestUrl = event.request.getRequestUrl();
            const isMainFrame = event.request.isMainFrame();
            Logger.error(
              'ImportPage',
              Logger.formatMsg(
                'ImportPage',
                'onErrorReceive',
                `WebView 错误: code=${errorCode}, info=${errorInfo}, url=${requestUrl.split('?')[0]}, mainFrame=${isMainFrame}`
              )
            );

            if (isMainFrame) {
              this.pageLoaded = true;
              this.showError(`页面加载失败（${errorCode}）`);
            }
          }
        })
        .width('100%')
        .height('100%')
        .visibility(this.isLoading ? Visibility.None : Visibility.Visible)

      // WebView 可见时，底部显示"解析课表"按钮
      // 因为教务系统可能通过 Ajax/iframe 加载课表，不触发 onPageEnd
      if (!this.isLoading && this.debugInfo.length === 0) {
        Column() {
          Button('导入课表')
            .width('60%')
            .height(44)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .backgroundColor($r('app.color.accent'))
            .fontColor($r('app.color.card_bg'))
            .borderRadius(22)
            .shadow({ radius: 8, color: '#33007DFF' })
            .onClick(() => {
              this.isLoading = true;
              this.loadingText = '正在解析课表...';
              this.hasTriggeredParse = true;
              this.extractAndParseHtml();
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.End)
        .alignItems(HorizontalAlign.Center)
        .padding({ bottom: 40 })
        .hitTestBehavior(HitTestMode.Transparent)
      }
      // 加载提示
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color($r('app.color.accent'))

          Text(this.loadingText)
            .fontSize(16)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.card_bg'))
      }

      // 解析失败提示
      if (this.debugInfo.length > 0) {
        Column() {
          Text('课程表解析失败')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 12 })

          Text(this.debugInfo)
            .fontSize(15)
            .textAlign(TextAlign.Start)
            .lineHeight(22)

          Button('关闭')
            .width('100%')
            .margin({ top: 12 })
            .onClick(() => {
              this.debugInfo = '';
            })
        }
        .width('92%')
        .height('84%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(10)
        .shadow({ radius: 20, color: '#33000000' })
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 根据加载完成的页面 URL 执行对应操作
   */
  private handlePageLoaded(url: string): void {
    const path = url.split('?')[0];

    // 情况 1：课表页加载完成 → 自动解析
    if (this.isScheduleUrl(url)) {
      Logger.info(
        'ImportPage',
        Logger.formatMsg('ImportPage', 'handlePageLoaded', '✅ 检测到课表页，自动开始解析')
      );

      if (!this.hasTriggeredParse) {
        this.hasTriggeredParse = true;
        this.isLoading = true;
        this.loadingText = '正在解析课表...';

        // 延迟 3 秒等待 JavaScript 渲染完成（fillTable 等）
        setTimeout(() => {
          this.extractAndParseHtml();
        }, 3000);
      }
      return;
    }

    // 情况 2：登录成功，到达主页 → 显示 WebView，让用户点击"我的课表"
    if (this.isLoggedIn(url)) {
      Logger.info(
        'ImportPage',
        Logger.formatMsg('ImportPage', 'handlePageLoaded', '✅ 已登录，等待用户点击"我的课表"')
      );
      this.isLoading = false;
      return;
    }

    // 情况 3：登录页 → 显示 WebView 让用户登录
    this.isLoading = false;
    Logger.info(
      'ImportPage',
      Logger.formatMsg('ImportPage', 'handlePageLoaded', '显示登录页，等待用户登录')
    );
  }

  /**
   * 判断是否已登录（到达主页或其他非登录页）
   */
  private isLoggedIn(url: string): boolean {
    // 登录成功后通常会跳转到 home.action 或其他页面
    // 排除登录页本身和统一认证页
    const isLoginPage = url.includes('login') || url.includes('authserver');
    const isEamsPage = url.includes('bkjw.chd.edu.cn/eams');

    // 在教务系统域名下，且不是登录页 = 已登录
    return isEamsPage && !isLoginPage;
  }

  /**
   * 判断是否是课表页面
   */
  private isScheduleUrl(url: string): boolean {
    const path = url.split('?')[0];
    return path.includes('courseTable') ||
      path.includes('kebiao') ||
      path.includes('stdSchedule');
  }

  /**
   * 获取课表 HTML。
   * 树维教务系统的课表数据通过 Ajax 加载后，存储在全局变量中。
   * 优先尝试从 window.table0 等全局对象序列化，其次才是 HTML。
   */
  private async getCourseTableHtml(): Promise<string> {
    // 策略 1：尝试序列化 window.table0.activities（课程活动数组）
    const scriptTable0 = `(function(){
      try {
        if (typeof table0 !== 'undefined' && table0.activities) {
          var html = '<script>';
          html += 'var unitCount = ' + table0.unitCount + ';\\n';
          for (var i = 0; i < table0.activities.length; i++) {
            var act = table0.activities[i];
            html += 'var courseName = "' + act.name + '";\\n';
            html += 'activity = new TaskActivity(';
            html += "'" + act.teachers.join(',') + "',";
            html += "'" + act.teachers.join(',') + "',";
            html += "'" + act.id + "',";
            html += "'" + act.name + "',";
            html += "'" + act.code + "',";
            html += "'" + (act.room || '') + "',";
            html += "'" + (act.room || '') + "',";
            html += "'" + (act.vaildWeeks || '') + "',";
            html += "null,'','',''";
            html += ');\\n';
            html += 'index = ' + act.index + ';\\n';
          }
          html += '<' + '/script>';
          return html;
        }
      } catch(e) { return ''; }
      return '';
    })()`;

    Logger.info('ImportPage', Logger.formatMsg('ImportPage', 'getCourseTableHtml',
      '尝试从 window.table0 序列化课程数据...'));

    const serialized = await this.controller.runJavaScript(scriptTable0);
    if (serialized && serialized.length > 100) {
      Logger.info('ImportPage', Logger.formatMsg('ImportPage', 'getCourseTableHtml',
        `✅ 从 window.table0 序列化成功 (长度: ${serialized.length})`));
      return serialized;
    }

    // 策略 2：获取包含 script 标签的完整页面 HTML（可能在 iframe 或动态插入的内容中）
    const scriptInnerHTML = `(function(){
      try {
        var scripts = document.getElementsByTagName('script');
        for (var i = 0; i < scripts.length; i++) {
          var code = scripts[i].innerHTML || scripts[i].textContent || '';
          if (code.indexOf('TaskActivity') > -1 && code.indexOf('new TaskActivity') > -1) {
            return '<script>' + code + '<' + '/script>';
          }
        }
      } catch(e) {}
      return '';
    })()`;

    Logger.info('ImportPage', Logger.formatMsg('ImportPage', 'getCourseTableHtml',
      '尝试从 <script> 标签提取 TaskActivity...'));

    for (let i = 0; i < 20; i++) {
      const scriptCode = await this.controller.runJavaScript(scriptInnerHTML);
      if (scriptCode && scriptCode.length > 0) {
        Logger.info('ImportPage', Logger.formatMsg('ImportPage', 'getCourseTableHtml',
          `✅ 从 <script> 标签提取成功 (长度: ${scriptCode.length})`));
        return scriptCode;
      }
      await new Promise<void>((resolve) => setTimeout(resolve, 500));
    }

    // 策略 3：兜底 - 返回完整 HTML
    Logger.warn('ImportPage', Logger.formatMsg('ImportPage', 'getCourseTableHtml',
      '所有策略失败，返回完整 HTML'));
    return await this.controller.runJavaScript('document.documentElement.outerHTML');
  }

  /**
   * 提取并解析 HTML
   */
  private async extractAndParseHtml(): Promise<void> {
    try {
      this.isLoading = true;
      this.loadingText = '正在解析课表...';

      // 1. 获取当前页面 URL，并等待课表单元格（td[title]）出现后抓取 HTML。
      //    教务系统的课表可能是 AJAX 动态渲染，直接抓会拿到还没渲染的空壳页面。
      const currentUrl = await this.controller.runJavaScript('location.href');
      const html = await this.getCourseTableHtml();

      if (!html || html.length === 0) {
        Logger.error(
          'ImportPage',
          Logger.formatMsg('ImportPage', 'extractAndParseHtml', '获取 HTML 失败')
        );
        this.showError('获取课表失败');
        return;
      }

      Logger.info(
        'ImportPage',
        Logger.formatMsg('ImportPage', 'extractAndParseHtml', `获取 HTML 成功，长度：${html.length}`)
      );

      // 2. 获取当前学期
      const termResult = await TermService.getInstance().getCurrentTerm();

      if (!termResult.isSuccess() || !termResult.getData()) {
        Logger.error(
          'ImportPage',
          Logger.formatMsg('ImportPage', 'extractAndParseHtml', '获取当前学期失败')
        );
        this.showError('未找到当前学期');
        return;
      }

      const termId = termResult.getData()!.id;

      // 3. 解析课表（双解析器策略：先尝试 HTML 表格，失败后尝试 JavaScript 对象）
      this.loadingText = '正在解析课程...';
      let courses = CourseParser.parse(html, termId);

      if (courses.length === 0) {
        Logger.warn(
          'ImportPage',
          Logger.formatMsg('ImportPage', 'extractAndParseHtml', '⚠️ HTML 表格解析失败，尝试 JavaScript 对象解析')
        );

        // 回退到 JavaScript 对象解析器
        courses = CourseParserFromJS.parse(html, termId);

        if (courses.length === 0) {
          Logger.warn(
            'ImportPage',
            Logger.formatMsg('ImportPage', 'extractAndParseHtml', '❌ 两种解析器都未找到课程')
          );
          this.showParseDiagnostic(html, currentUrl);
          return;
        }

        Logger.info(
          'ImportPage',
          Logger.formatMsg('ImportPage', 'extractAndParseHtml', `✅ JavaScript 解析成功，共${courses.length}门课程`)
        );
      }

      Logger.info(
        'ImportPage',
        Logger.formatMsg('ImportPage', 'extractAndParseHtml', `解析成功，共${courses.length}门课程`)
      );

      // 4. 清空旧课程
      this.loadingText = '正在清空旧数据...';
      await ScheduleService.getInstance().clearAllCourses(termId);

      // 5. 导入新课程
      this.loadingText = '正在导入课程...';
      const importResult = await ScheduleService.getInstance().importCourses(courses);

      if (importResult.isSuccess()) {
        Logger.info(
          'ImportPage',
          Logger.formatMsg('ImportPage', 'extractAndParseHtml', '课程导入成功')
        );
        this.showSuccess(courses.length);
      } else {
        Logger.error(
          'ImportPage',
          Logger.formatMsg('ImportPage', 'extractAndParseHtml', '课程导入失败: %{public}s'),
          importResult.getError().message
        );
        this.showError('导入课程失败');
      }
    } catch (err) {
      Logger.error(
        'ImportPage',
        Logger.formatMsg('ImportPage', 'extractAndParseHtml', '解析课表异常: %{public}s'),
        JSON.stringify(err)
      );
      this.showError('解析课表失败');
    }
  }

  /**
   * 显示成功并返回
   */
  private showSuccess(count: number): void {
    this.loadingText = `导入成功！共${count}门课程`;

    setTimeout(() => {
      router.back();
    }, 1500);
  }

  /**
   * 解析失败时仅展示可理解的提示，不暴露真实 HTML 和可能包含会话信息的 URL。
   */
  private showParseDiagnostic(html: string, url: string = ''): void {
    const safeUrl = url.split('?')[0];
    const tdCount = (html.match(/<td\b/gi) || []).length;
    const iframeCount = (html.match(/<iframe\b/gi) || []).length;
    const frameCount = (html.match(/<frame\b/gi) || []).length;

    this.isLoading = false;
    this.debugInfo = '未能识别课程表。请确认已登录教务系统并进入课程表页面后重试。';
    Logger.warn(
      'ImportPage',
      Logger.formatMsg('ImportPage', 'showParseDiagnostic', `解析失败，页面：${safeUrl}，td=${tdCount}，iframe=${iframeCount}，frame=${frameCount}`)
    );
  }

  /**
   * 显示错误
   */
  private showError(message: string): void {
    this.isLoading = false;
    this.loadingText = message;

    Logger.error('ImportPage', Logger.formatMsg('ImportPage', 'showError', message));

    // 显示错误弹窗
    this.getUIContext().showAlertDialog({
      title: '导入失败',
      message: message,
      primaryButton: {
        value: '重试',
        action: () => {
          this.controller.refresh();
        }
      },
      secondaryButton: {
        value: '返回',
        action: () => {
          router.back();
        }
      }
    });
  }
}
