/**
 * 全局错误处理器
 * 提供统一的错误处理与兜底机制
 */
import { Logger } from '../common/logger/Logger';
import { AppError } from './AppError';
import { ErrorCode } from '../model/constants/ErrorCodeConstants';

/**
 * 错误处理器
 */
export class ErrorHandler {
  private static readonly TAG: string = 'ErrorHandler';

  /**
   * 处理错误（记录日志）
   */
  public static handle(error: AppError, context?: string): void {
    const contextMsg = context ? `[${context}] ` : '';
    const logMsg = Logger.formatMsg(
      ErrorHandler.TAG,
      'handle',
      `${contextMsg}${error.toString()}`
    );

    if (error.cause) {
      Logger.error(ErrorHandler.TAG, logMsg + ', cause: %{public}s', JSON.stringify(error.cause));
    } else {
      Logger.error(ErrorHandler.TAG, logMsg);
    }
  }

  /**
   * 处理未捕获的异常
   */
  public static handleUncaught(err: Error, context?: string): AppError {
    const appError = AppError.unknown(err);
    ErrorHandler.handle(appError, context || 'Uncaught');
    return appError;
  }

  /**
   * 从系统错误转换为 AppError
   */
  public static fromSystemError(err: Error, defaultCode: ErrorCode): AppError {
    // 根据错误消息判断错误类型
    const errMsg = err.message.toLowerCase();

    if (errMsg.includes('timeout')) {
      return new AppError(ErrorCode.NETWORK_TIMEOUT, undefined, err, true);
    }

    if (errMsg.includes('network') || errMsg.includes('connection')) {
      return new AppError(ErrorCode.NETWORK_DISCONNECTED, undefined, err, true);
    }

    if (errMsg.includes('database') || errMsg.includes('rdb')) {
      return new AppError(defaultCode, undefined, err, true);
    }

    // 默认使用传入的错误码
    return new AppError(defaultCode, undefined, err, false);
  }

  /**
   * 判断是否为可重试错误
   */
  public static isRetriable(error: AppError): boolean {
    return error.retriable;
  }

  /**
   * 获取用户友好的错误提示
   */
  public static getUserMessage(error: AppError): string {
    return error.message;
  }
}