/**
 * 统一结果类型
 * 用于封装操作结果，避免异常抛出
 */
import { AppError } from './AppError';

/**
 * 结果类型基类
 */
export abstract class Result<T> {
  /**
   * 判断是否成功
   */
  public abstract isSuccess(): boolean;

  /**
   * 判断是否失败
   */
  public abstract isFailure(): boolean;

  /**
   * 获取数据（仅成功时有效）
   */
  public abstract getData(): T;

  /**
   * 获取错误（仅失败时有效）
   */
  public abstract getError(): AppError;

  /**
   * 创建成功结果
   */
  public static success<T>(data: T): Result<T> {
    return new Success(data);
  }

  /**
   * 创建失败结果
   */
  public static failure<T>(error: AppError): Result<T> {
    return new Failure(error);
  }

  /**
   * map 转换（仅对成功结果生效）
   */
  public map<U>(fn: (data: T) => U): Result<U> {
    if (this.isSuccess()) {
      try {
        return Result.success(fn(this.getData()));
      } catch (e) {
        return Result.failure(AppError.unknown(e as Error));
      }
    }
    return Result.failure(this.getError());
  }

  /**
   * flatMap 转换（仅对成功结果生效）
   */
  public flatMap<U>(fn: (data: T) => Result<U>): Result<U> {
    if (this.isSuccess()) {
      try {
        return fn(this.getData());
      } catch (e) {
        return Result.failure(AppError.unknown(e as Error));
      }
    }
    return Result.failure(this.getError());
  }

  /**
   * 获取数据或默认值
   */
  public getOrDefault(defaultValue: T): T {
    return this.isSuccess() ? this.getData() : defaultValue;
  }

  /**
   * 获取数据或执行函数
   */
  public getOrElse(fn: (error: AppError) => T): T {
    return this.isSuccess() ? this.getData() : fn(this.getError());
  }
}

/**
 * 成功结果
 */
class Success<T> extends Result<T> {
  private readonly data: T;

  constructor(data: T) {
    super();
    this.data = data;
  }

  public isSuccess(): boolean {
    return true;
  }

  public isFailure(): boolean {
    return false;
  }

  public getData(): T {
    return this.data;
  }

  public getError(): AppError {
    throw new Error('Success result has no error');
  }
}

/**
 * 失败结果
 */
class Failure<T> extends Result<T> {
  private readonly error: AppError;

  constructor(error: AppError) {
    super();
    this.error = error;
  }

  public isSuccess(): boolean {
    return false;
  }

  public isFailure(): boolean {
    return true;
  }

  public getData(): T {
    throw new Error('Failure result has no data');
  }

  public getError(): AppError {
    return this.error;
  }
}