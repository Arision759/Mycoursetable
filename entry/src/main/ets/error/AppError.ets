/**
 * 应用错误类
 * 统一封装所有错误信息
 */
import { ErrorCode, ERROR_MESSAGE_MAP } from '../model/constants/ErrorCodeConstants';

/**
 * 应用错误类
 */
export class AppError {
  /** 错误码 */
  public readonly code: ErrorCode;

  /** 用户可读错误信息 */
  public readonly message: string;

  /** 原始错误（仅用于日志） */
  public readonly cause?: Error;

  /** 是否可重试 */
  public readonly retriable: boolean;

  /**
   * 构造函数
   */
  constructor(code: ErrorCode, message?: string, cause?: Error, retriable: boolean = false) {
    this.code = code;
    this.message = message || ERROR_MESSAGE_MAP.get(code) || '未知错误';
    this.cause = cause;
    this.retriable = retriable;
  }

  /**
   * 创建通用错误
   */
  public static unknown(cause?: Error): AppError {
    return new AppError(ErrorCode.UNKNOWN_ERROR, undefined, cause, false);
  }

  /**
   * 创建参数错误
   */
  public static invalidParameter(message?: string): AppError {
    return new AppError(ErrorCode.INVALID_PARAMETER, message, undefined, false);
  }

  /**
   * 创建数据不存在错误
   */
  public static dataNotFound(message?: string): AppError {
    return new AppError(ErrorCode.DATA_NOT_FOUND, message, undefined, false);
  }

  /**
   * 创建数据库错误
   */
  public static dbError(code: ErrorCode, cause?: Error): AppError {
    return new AppError(code, undefined, cause, true);
  }

  /**
   * 创建网络错误
   */
  public static networkError(code: ErrorCode, cause?: Error): AppError {
    return new AppError(code, undefined, cause, true);
  }

  /**
   * 创建业务错误
   */
  public static businessError(code: ErrorCode, message?: string, cause?: Error): AppError {
    return new AppError(code, message, cause, false);
  }

  /**
   * 创建导入错误
   */
  public static importError(code: ErrorCode, message?: string, cause?: Error): AppError {
    return new AppError(code, message, undefined, false);
  }

  /**
   * 转为字符串
   */
  public toString(): string {
    return `AppError(code=${this.code}, message=${this.message}, retriable=${this.retriable})`;
  }
}