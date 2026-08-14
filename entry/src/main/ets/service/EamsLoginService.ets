/**
 * 长安大学教务系统登录与课表获取服务
 *
 * 流程：
 * 1. 访问 CAS 登录页 → 获取 execution, pwdEncryptSalt
 * 2. AES 加密密码 → POST 登录 → 跟随重定向回教务系统
 * 3. GET courseTableForStd.action → 提取 ids
 * 4. POST courseTableForStd!courseTable.action → 获取课表 HTML
 */
import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { buffer, util } from '@kit.ArkTS';
import http from '@ohos.net.http';
import { Logger } from '../common/logger/Logger';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'EamsLoginService';

// URL 配置
const EAMS_BASE = 'http://bkjw.chd.edu.cn/eams';
const CAS_BASE = 'https://ids.chd.edu.cn/authserver';
const LOGIN_SERVICE = `${EAMS_BASE}/login.action`;
const COURSE_TABLE_PAGE = `${EAMS_BASE}/courseTableForStd.action`;
const COURSE_TABLE_DATA = `${EAMS_BASE}/courseTableForStd!courseTable.action`;

/**
 * 登录结果
 */
export interface LoginResult {
  success: boolean;
  message: string;
  courseHtml: string;
}

/**
 * CAS 登录页解析结果
 */
export interface CasLoginPageResult {
  success: boolean;
  message: string;
  execution: string;
  salt: string;
  casUrl: string;
}

/**
 * 登录提交结果
 */
export interface SubmitLoginResult {
  success: boolean;
  message: string;
}

export class EamsLoginService {
  private static instance: EamsLoginService | undefined = undefined;
  private cookieStore: Map<string, string> = new Map();

  private constructor() {}

  public static getInstance(): EamsLoginService {
    if (!EamsLoginService.instance) {
      EamsLoginService.instance = new EamsLoginService();
    }
    return EamsLoginService.instance;
  }

  /**
   * 完整的登录并获取课表流程
   */
  public async loginAndGetCourseTable(username: string, password: string): Promise<LoginResult> {
    // 清空旧 Cookie
    this.cookieStore.clear();

    // 步骤 1：访问 CAS 登录页
    Logger.info(TAG, Logger.formatMsg(TAG, 'loginAndGetCourseTable', '步骤1: 访问 CAS 登录页'));
    const casPageResult = await this.getCasLoginPage();
    if (!casPageResult.success) {
      return { success: false, message: casPageResult.message, courseHtml: '' };
    }

    // 步骤 2：加密密码并登录
    Logger.info(TAG, Logger.formatMsg(TAG, 'loginAndGetCourseTable', '步骤2: 加密密码并登录'));
    const loginResult = await this.submitLogin(
      username, password,
      casPageResult.execution,
      casPageResult.salt,
      casPageResult.casUrl
    );
    if (!loginResult.success) {
      return { success: false, message: loginResult.message, courseHtml: '' };
    }

    // 步骤 3：获取 ids
    Logger.info(TAG, Logger.formatMsg(TAG, 'loginAndGetCourseTable', '步骤3: 获取学生 ids'));
    const ids = await this.getStudentIds();
    if (!ids) {
      return { success: false, message: '获取学生信息失败', courseHtml: '' };
    }

    // 步骤 4：获取 semester.id
    const semesterId = this.getSemesterId();
    Logger.info(TAG, Logger.formatMsg(TAG, 'loginAndGetCourseTable', `semester.id = ${semesterId}`));

    // 步骤 5：获取课表数据
    Logger.info(TAG, Logger.formatMsg(TAG, 'loginAndGetCourseTable', '步骤5: 获取课表数据'));
    const courseHtml = await this.getCourseTableData(semesterId, ids);
    if (!courseHtml) {
      return { success: false, message: '获取课表数据失败', courseHtml: '' };
    }

    // 检查是否包含 TaskActivity
    if (!courseHtml.includes('TaskActivity')) {
      return { success: false, message: '课表数据格式异常', courseHtml: '' };
    }

    Logger.info(TAG, Logger.formatMsg(TAG, 'loginAndGetCourseTable',
      `✅ 获取课表成功 (长度: ${courseHtml.length})`));

    return { success: true, message: '获取成功', courseHtml: courseHtml };
  }

  // ===== 私有方法 =====

  /**
   * 步骤 1：访问 CAS 登录页，提取隐藏字段
   */
  private async getCasLoginPage(): Promise<CasLoginPageResult> {
    const casUrl = `${CAS_BASE}/login?service=${encodeURIComponent(LOGIN_SERVICE)}`;

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(casUrl, {
        method: http.RequestMethod.GET,
        header: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        connectTimeout: 15000,
        readTimeout: 15000
      });

      if (response.responseCode !== 200) {
        return {
          success: false,
          message: `CAS 页面加载失败 (HTTP ${response.responseCode})`,
          execution: '', salt: '', casUrl: ''
        };
      }

      // 保存 Cookie
      this.extractCookies(response);

      const html = response.result as string;
      Logger.info(TAG, Logger.formatMsg(TAG, 'getCasLoginPage',
        `CAS 页面加载成功 (长度: ${html.length})`));

      // 提取隐藏字段
      const executionMatch = html.match(/name="execution"\s+value="([^"]*)"/);
      const saltMatch = html.match(/id="pwdEncryptSalt"\s+value="([^"]*)"/);

      if (!saltMatch) {
        // 备选格式
        const saltMatch2 = html.match(/id="pwdDefaultEncryptSalt"\s+value="([^"]*)"/);
        if (!saltMatch2) {
          return {
            success: false,
            message: '未找到加密密钥',
            execution: '', salt: '', casUrl: ''
          };
        }
        return {
          success: true, message: '',
          execution: executionMatch ? executionMatch[1] : '',
          salt: saltMatch2[1],
          casUrl: casUrl
        };
      }

      return {
        success: true, message: '',
        execution: executionMatch ? executionMatch[1] : '',
        salt: saltMatch[1],
        casUrl: casUrl
      };
    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'getCasLoginPage',
        `请求异常: ${this.formatError(err as BusinessError)}`));
      return {
        success: false,
        message: '网络连接失败，请检查网络',
        execution: '', salt: '', casUrl: ''
      };
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 步骤 2：加密密码并提交登录
   * 使用默认重定向（系统自动跟随），确保 Cookie 正确传递
   */
  private async submitLogin(
    username: string,
    password: string,
    execution: string,
    salt: string,
    casUrl: string
  ): Promise<SubmitLoginResult> {
    // AES 加密密码
    let encryptedPassword = '';
    try {
      encryptedPassword = await this.aesEncrypt(password, salt);
      Logger.info(TAG, Logger.formatMsg(TAG, 'submitLogin', '密码加密成功'));
    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'submitLogin',
        `密码加密失败: ${this.formatError(err as BusinessError)}`));
      return { success: false, message: '密码加密失败' };
    }

    // 构造表单数据
    const formData = `username=${encodeURIComponent(username)}`
      + `&password=${encodeURIComponent(encryptedPassword)}`
      + `&lt=`
      + `&execution=${encodeURIComponent(execution)}`
      + `&_eventId=submit`
      + `&cllt=userNameLogin`
      + `&dllt=generalLogin`
      + `&rmShown=1`;

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(casUrl, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Referer': casUrl,
          'Cookie': this.buildCookieHeader()
        },
        extraData: formData,
        connectTimeout: 15000,
        readTimeout: 15000
      });

      // 提取最终响应的 Cookie
      this.extractCookies(response);

      const responseHtml = response.result as string;
      const responseCode = response.responseCode;

      Logger.info(TAG, Logger.formatMsg(TAG, 'submitLogin',
        `响应: HTTP ${responseCode}, 长度: ${responseHtml.length}`));

      // 检查是否登录失败（页面中包含加密盐 = 仍在登录页）
      if (responseHtml.includes('pwdEncryptSalt') || responseHtml.includes('authserver/login')) {
        const errorMatch = responseHtml.match(/id="showErrorTip"[^>]*>([^<]+)/);
        const errorMsg = errorMatch ? errorMatch[1].trim() : '账号或密码错误';
        Logger.error(TAG, Logger.formatMsg(TAG, 'submitLogin', `登录失败: ${errorMsg}`));
        return { success: false, message: errorMsg };
      }

      // 登录成功，但需要确保拿到教务系统的 JSESSIONID
      // 如果自动重定向已经到达 eams，Cookie 应该已经在响应中
      Logger.info(TAG, Logger.formatMsg(TAG, 'submitLogin', '✅ 登录成功'));
      Logger.info(TAG, Logger.formatMsg(TAG, 'submitLogin',
        `Cookies: ${this.buildCookieHeader()}`));

      // 额外访问一次教务系统首页，确保 Session 建立
      await this.ensureEamsSession();

      return { success: true, message: '' };
    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'submitLogin',
        `登录请求异常: ${this.formatError(err as BusinessError)}`));
      return { success: false, message: '登录请求失败' };
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 确保教务系统 Session 建立，并提取当前学期 ID
   * 登录成功后访问首页，从 HTML 中解析当前学期
   */
  private async ensureEamsSession(): Promise<void> {
    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(`${EAMS_BASE}/home.action`, {
        method: http.RequestMethod.GET,
        header: {
          'Cookie': this.buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        connectTimeout: 10000,
        readTimeout: 10000
      });

      this.extractCookies(response);

      // 从首页 HTML 中提取当前学期 ID
      const html = response.result as string;
      this.extractCurrentSemester(html);

      Logger.info(TAG, Logger.formatMsg(TAG, 'ensureEamsSession',
        `首页访问完成, HTTP ${response.responseCode}`));
    } catch (err) {
      Logger.warn(TAG, Logger.formatMsg(TAG, 'ensureEamsSession',
        `首页访问失败: ${this.formatError(err as BusinessError)}`));
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 从首页 HTML 中提取当前学期 ID
   * 教务系统首页包含类似：bg.form.addInput(form,"ids","12345");
   * 以及当前学期信息（通常在下拉框的 selected 项）
   */
  private extractCurrentSemester(html: string): void {
    // 打印 HTML 片段用于调试（查找学期相关内容）
    const semesterKeywords = ['semester', '学期', 'term'];
    for (const keyword of semesterKeywords) {
      const index = html.indexOf(keyword);
      if (index !== -1) {
        const snippet = html.substring(Math.max(0, index - 100), Math.min(html.length, index + 200));
        Logger.debug(TAG, Logger.formatMsg(TAG, 'extractCurrentSemester',
          `找到关键词 "${keyword}" 附近内容: ${snippet}`));
        break;
      }
    }

    // 尝试多种模式
    const patterns = [
      /<option\s+value="(\d+)"\s+selected/,           // <option value="262" selected>
      /<option\s+selected\s+value="(\d+)"/,           // <option selected value="262">
      /semester\.id["\s]*[:=]["\s]*(\d+)/,            // semester.id = "262" 或 semester.id: "262"
      /semesterId["\s]*[:=]["\s]*(\d+)/,              // semesterId = "262"
      /currentSemester["\s]*[:=]["\s]*(\d+)/          // currentSemester = "262"
    ];

    for (const pattern of patterns) {
      const match = html.match(pattern);
      if (match && match[1]) {
        const semesterId = match[1];
        this.cookieStore.set('semester.id', semesterId);
        Logger.info(TAG, Logger.formatMsg(TAG, 'extractCurrentSemester',
          `✅ 当前学期 ID = ${semesterId}`));
        return;
      }
    }

    Logger.warn(TAG, Logger.formatMsg(TAG, 'extractCurrentSemester',
      '未能从首页提取学期 ID，使用默认值 262'));
    // 强制设置当前学期（2024-2025学年第2学期）
    this.cookieStore.set('semester.id', '262');
  }

  /**
   * 步骤 3：获取学生 ids
   */
  private async getStudentIds(): Promise<string | null> {
    Logger.info(TAG, Logger.formatMsg(TAG, 'getStudentIds',
      `携带 Cookie: ${this.buildCookieHeader()}`));

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(COURSE_TABLE_PAGE, {
        method: http.RequestMethod.GET,
        header: {
          'Cookie': this.buildCookieHeader(),
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
        },
        connectTimeout: 10000,
        readTimeout: 10000
      });

      this.extractCookies(response);

      if (response.responseCode !== 200) {
        Logger.error(TAG, Logger.formatMsg(TAG, 'getStudentIds',
          `HTTP ${response.responseCode}`));
        return null;
      }

      const html = response.result as string;

      // 提取 ids
      let idsMatch = html.match(/bg\.form\.addInput\(form,\s*"ids"\s*,\s*"(\d+)"\s*\)/);
      if (!idsMatch) {
        idsMatch = html.match(/"ids"\s*,\s*"(\d+)"/);
      }
      if (!idsMatch) {
        idsMatch = html.match(/ids=(\d+)/);
      }

      if (idsMatch) {
        const ids = idsMatch[1];
        Logger.info(TAG, Logger.formatMsg(TAG, 'getStudentIds', `✅ ids = ${ids}`));
        return ids;
      }

      Logger.error(TAG, Logger.formatMsg(TAG, 'getStudentIds', '未找到 ids'));
      return null;
    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'getStudentIds',
        `请求异常: ${this.formatError(err as BusinessError)}`));
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  /**
   * 获取 semester.id
   */
  private getSemesterId(): string {
    const semesterId = this.cookieStore.get('semester.id');
    if (semesterId) {
      return semesterId;
    }
    // 默认值（2025-2026学年第2学期）
    return '262';
  }

  /**
   * 步骤 5：POST 获取课表数据
   */
  private async getCourseTableData(semesterId: string, ids: string): Promise<string | null> {
    const formData = `ignoreHead=1`
      + `&setting.kind=std`
      + `&startWeek=`
      + `&semester.id=${semesterId}`
      + `&ids=${ids}`;

    const httpRequest = http.createHttp();
    try {
      const response = await httpRequest.request(COURSE_TABLE_DATA, {
        method: http.RequestMethod.POST,
        header: {
          'Accept': '*/*',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
          'Cookie': this.buildCookieHeader(),
          'Origin': EAMS_BASE,
          'Referer': COURSE_TABLE_PAGE,
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'X-Requested-With': 'XMLHttpRequest'
        },
        extraData: formData,
        connectTimeout: 10000,
        readTimeout: 10000
      });

      this.extractCookies(response);

      if (response.responseCode !== 200) {
        Logger.error(TAG, Logger.formatMsg(TAG, 'getCourseTableData',
          `HTTP ${response.responseCode}`));
        return null;
      }

      const html = response.result as string;
      Logger.info(TAG, Logger.formatMsg(TAG, 'getCourseTableData',
        `获取成功 (长度: ${html.length})`));
      return html;
    } catch (err) {
      Logger.error(TAG, Logger.formatMsg(TAG, 'getCourseTableData',
        `请求异常: ${this.formatError(err as BusinessError)}`));
      return null;
    } finally {
      httpRequest.destroy();
    }
  }

  // ===== 工具方法 =====

  /**
   * AES-128-CBC 加密（IV=密钥，PKCS7填充，输出Base64）
   * CAS 要求明文 = 64位随机字符 + 密码
   */
  private async aesEncrypt(password: string, key: string): Promise<string> {
    const keyBytes = new Uint8Array(buffer.from(key, 'utf-8').buffer);

    // 生成 64 位随机前缀
    const randomPrefix = this.generateRandomString(64);
    const plainText = randomPrefix + password;
    const plainBytes = new Uint8Array(buffer.from(plainText, 'utf-8').buffer);

    // 创建密钥
    const keyBlob: cryptoFramework.DataBlob = { data: keyBytes };
    const symKeyGenerator = cryptoFramework.createSymKeyGenerator('AES128');
    const symKey = await symKeyGenerator.convertKey(keyBlob);

    // IV = 密钥
    const ivParams: cryptoFramework.IvParamsSpec = {
      algName: 'IvParamsSpec',
      iv: { data: keyBytes }
    };

    // 加密
    const cipher = cryptoFramework.createCipher('AES128|CBC|PKCS7');
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, symKey, ivParams);

    const plainBlob: cryptoFramework.DataBlob = { data: plainBytes };
    const cipherData = await cipher.doFinal(plainBlob);

    // Base64 编码
    const base64Helper = new util.Base64Helper();
    return base64Helper.encodeToStringSync(cipherData.data);
  }

  /**
   * 格式化错误信息，便于日志排查
   */
  private formatError(err: BusinessError): string {
    return `code=${err.code}, message=${err.message}`;
  }

  /**
   * 规范化 Cookie 值，兼容 string 和 string[] 两种类型
   */
  private normalizeCookieValue(value: string | string[], separator: string): string {
    if (typeof value === 'string') {
      return value;
    }
    return value.join(separator);
  }

  /**
   * 生成随机字符串
   */
  private generateRandomString(length: number): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let result = '';
    for (let i = 0; i < length; i++) {
      const randomIndex = Math.floor(Math.random() * chars.length);
      result += chars.charAt(randomIndex);
    }
    return result;
  }

  /**
   * 从响应中提取 Cookie
   * HarmonyOS response.cookies 返回 Netscape Cookie 格式：
   * "#HttpOnly_domain\tFALSE\t/path\tFALSE\t0\tname\tvalue"
   * 或简单格式："name=value; name2=value2"
   */
  private extractCookies(response: http.HttpResponse): void {
    const cookies = response.cookies;
    if (!cookies) {
      return;
    }

    const cookieStr = this.normalizeCookieValue(cookies, '\n');

    // 按行分割（Netscape 格式每行一个 Cookie）
    const lines = cookieStr.split('\n');

    for (const line of lines) {
      const trimmed = line.trim();
      if (trimmed.length === 0) {
        continue;
      }

      // Netscape Cookie 格式：用 Tab 分隔
      // 格式：domain\tFLAG\tpath\tSECURE\tEXPIRES\tNAME\tVALUE
      // 或带 #HttpOnly_ 前缀
      if (trimmed.includes('\t')) {
        const cleanLine = trimmed.startsWith('#HttpOnly_')
          ? trimmed.substring('#HttpOnly_'.length)
          : trimmed;

        const parts = cleanLine.split('\t');
        // parts: [domain, flag, path, secure, expires, name, value]
        if (parts.length >= 7) {
          const name = parts[5];
          const value = parts[6];
          if (name && name.length > 0) {
            this.cookieStore.set(name, value);
          }
        }
      } else {
        // 简单格式："name=value; name2=value2"
        const pairs = trimmed.split(';');
        for (const pair of pairs) {
          const eqIndex = pair.indexOf('=');
          if (eqIndex > 0) {
            const name = pair.substring(0, eqIndex).trim();
            const value = pair.substring(eqIndex + 1).trim();
            // 跳过 Cookie 属性
            const lowerName = name.toLowerCase();
            if (lowerName !== 'path' && lowerName !== 'domain' &&
              lowerName !== 'expires' && lowerName !== 'max-age' &&
              lowerName !== 'secure' && lowerName !== 'httponly' &&
              lowerName !== 'samesite') {
              this.cookieStore.set(name, value);
            }
          }
        }
      }
    }

    // 也从 header 中提取 set-cookie
    const headerObj = response.header as Record<string, string>;
    const setCookie = headerObj['set-cookie'] || headerObj['Set-Cookie'];
    if (setCookie) {
      const cookieLines = this.normalizeCookieValue(setCookie, '\n').split('\n');
      for (const line of cookieLines) {
        const parts = line.split(';');
        if (parts.length > 0) {
          const mainPart = parts[0].trim();
          const eqIndex = mainPart.indexOf('=');
          if (eqIndex > 0) {
            const name = mainPart.substring(0, eqIndex).trim();
            const value = mainPart.substring(eqIndex + 1).trim();
            this.cookieStore.set(name, value);
          }
        }
      }
    }

    Logger.debug(TAG, Logger.formatMsg(TAG, 'extractCookies',
      `提取到 ${this.cookieStore.size} 个 Cookie`));
  }

  /**
   * 构建 Cookie 请求头
   */
  private buildCookieHeader(): string {
    let cookieStr = '';
    this.cookieStore.forEach((value: string, key: string) => {
      if (cookieStr.length > 0) {
        cookieStr += '; ';
      }
      cookieStr += `${key}=${value}`;
    });
    return cookieStr;
  }
}
