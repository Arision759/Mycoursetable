/**
 * 统一日志工具类
 * 封装 hilog，提供分级日志输出
 */
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志级别枚举
 */
export enum LogLevel {
  DEBUG = 3,
  INFO = 4,
  WARN = 5,
  ERROR = 6
}

/**
 * 日志配置
 */
interface LogConfig {
  domain: number;
  enableDebug: boolean;
}

/**
 * 日志管理器
 */
export class Logger {
  private static config: LogConfig = {
    domain: 0x0001, // 课程表应用域
    enableDebug: false // 生产环境关闭调试日志
  };

  /**
   * 配置日志
   */
  public static configure(config: Partial<LogConfig>): void {
    if (config.domain !== undefined) {
      Logger.config.domain = config.domain;
    }
    if (config.enableDebug !== undefined) {
      Logger.config.enableDebug = config.enableDebug;
    }
  }

  /**
   * DEBUG 级别日志
   */
  public static debug(tag: string, format: string, ...args: string[]): void {
    if (Logger.config.enableDebug) {
      hilog.debug(Logger.config.domain, tag, format, ...args);
    }
  }

  /**
   * INFO 级别日志
   */
  public static info(tag: string, format: string, ...args: string[]): void {
    hilog.info(Logger.config.domain, tag, format, ...args);
  }

  /**
   * WARN 级别日志
   */
  public static warn(tag: string, format: string, ...args: string[]): void {
    hilog.warn(Logger.config.domain, tag, format, ...args);
  }

  /**
   * ERROR 级别日志
   */
  public static error(tag: string, format: string, ...args: string[]): void {
    hilog.error(Logger.config.domain, tag, format, ...args);
  }

  /**
   * 格式化日志消息（模块 + 方法名）
   */
  public static formatMsg(module: string, method: string, msg: string): string {
    return `[${module}][${method}] ${msg}`;
  }
}