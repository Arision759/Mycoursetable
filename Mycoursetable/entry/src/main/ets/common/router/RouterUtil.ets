/**
 * 路由工具类
 * 封装页面跳转逻辑
 */
import { router } from '@kit.ArkUI';
import { Logger } from '../logger/Logger';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 路由参数接口
 */
export interface RouterParams {
  [key: string]: Object;
}

/**
 * 路由工具类
 */
export class RouterUtil {
  private static readonly TAG: string = 'RouterUtil';

  /**
   * 跳转到指定页面
   * @param url 页面路径
   * @param params 路由参数
   */
  public static async push(url: string, params?: RouterParams): Promise<void> {
    try {
      await router.pushUrl({
        url: url,
        params: params
      });
      Logger.info(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'push', `Navigate to ${url}`)
      );
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'push', `Failed to navigate: ${error.message}`)
      );
    }
  }

  /**
   * 替换当前页面
   * @param url 页面路径
   * @param params 路由参数
   */
  public static async replace(url: string, params?: RouterParams): Promise<void> {
    try {
      await router.replaceUrl({
        url: url,
        params: params
      });
      Logger.info(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'replace', `Replace to ${url}`)
      );
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'replace', `Failed to replace: ${error.message}`)
      );
    }
  }

  /**
   * 返回上一页
   */
  public static back(): void {
    router.back();
    Logger.info(
      RouterUtil.TAG,
      Logger.formatMsg(RouterUtil.TAG, 'back', 'Navigate back')
    );
  }

  /**
   * 返回到指定页面
   * @param url 页面路径
   */
  public static async backToPage(url: string): Promise<void> {
    try {
      await router.back({
        url: url
      });
      Logger.info(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'backToPage', `Back to ${url}`)
      );
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'backToPage', `Failed to back: ${error.message}`)
      );
    }
  }

  /**
   * 清空路由栈并跳转
   * @param url 页面路径
   * @param params 路由参数
   */
  public static async clear(url: string, params?: RouterParams): Promise<void> {
    try {
      await router.clear();
      await RouterUtil.push(url, params);
      Logger.info(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'clear', `Clear and navigate to ${url}`)
      );
    } catch (err) {
      const error = err as BusinessError;
      Logger.error(
        RouterUtil.TAG,
        Logger.formatMsg(RouterUtil.TAG, 'clear', `Failed to clear: ${error.message}`)
      );
    }
  }

  /**
   * 获取当前页面参数
   */
  public static getParams(): RouterParams {
    const params = router.getParams();
    return params as RouterParams;
  }

  /**
   * 获取路由栈长度
   */
  public static getLength(): number {
    return router.getLength();
  }
}