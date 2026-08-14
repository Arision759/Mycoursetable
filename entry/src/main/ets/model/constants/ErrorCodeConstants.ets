/**
 * 错误码常量定义
 * 分段管理：1xxxx通用 2xxxx数据层 3xxxx网络层 4xxxx导入层 5xxxxUI层
 */

/**
 * 错误码枚举
 */
export enum ErrorCode {
  // ========== 1xxxx 通用错误 ==========
  UNKNOWN_ERROR = 10000,
  INVALID_PARAMETER = 10001,
  DATA_NOT_FOUND = 10002,
  OPERATION_CANCELLED = 10003,
  BUSINESS_ERROR = 10004,

  // ========== 2xxxx 数据层错误 ==========
  DB_OPEN_FAILED = 20001,
  DB_WRITE_FAILED = 20002,
  DB_READ_FAILED = 20003,
  DB_MIGRATION_FAILED = 20004,
  DB_DISK_FULL = 20005,
  DB_TRANSACTION_FAILED = 20006,
  PREFS_READ_FAILED = 20011,
  PREFS_WRITE_FAILED = 20012,

  // ========== 3xxxx 网络层错误 ==========
  NETWORK_TIMEOUT = 30001,
  NETWORK_DISCONNECTED = 30002,
  NETWORK_DNS_FAILED = 30003,
  NETWORK_SERVER_ERROR = 30004,
  NETWORK_BUSINESS_ERROR = 30005,
  NETWORK_UNAUTHORIZED = 30006,

  // ========== 4xxxx 导入层错误 ==========
  IMPORT_PARSE_FAILED = 40001,
  IMPORT_FORMAT_UNSUPPORTED = 40002,
  IMPORT_SESSION_EXPIRED = 40003,
  IMPORT_CAPTCHA_ERROR = 40004,
  IMPORT_CREDENTIAL_INVALID = 40005,
  IMPORT_DATA_CONFLICT = 40006,

  // ========== 5xxxx UI层错误 ==========
  ROUTER_INVALID = 50001,
  RESOURCE_MISSING = 50002,
  RENDER_DATA_INVALID = 50003
}

/**
 * 错误码到用户提示文案的映射
 */
export const ERROR_MESSAGE_MAP: Map<ErrorCode, string> = new Map<ErrorCode, string>([
  // 通用错误
  [ErrorCode.UNKNOWN_ERROR, '未知错误，请稍后重试'],
  [ErrorCode.INVALID_PARAMETER, '参数错误'],
  [ErrorCode.DATA_NOT_FOUND, '数据不存在'],
  [ErrorCode.OPERATION_CANCELLED, '操作已取消'],

  // 数据层错误
  [ErrorCode.DB_OPEN_FAILED, '数据库打开失败'],
  [ErrorCode.DB_WRITE_FAILED, '数据保存失败'],
  [ErrorCode.DB_READ_FAILED, '数据读取失败'],
  [ErrorCode.DB_MIGRATION_FAILED, '数据库升级失败'],
  [ErrorCode.DB_DISK_FULL, '存储空间不足'],
  [ErrorCode.DB_TRANSACTION_FAILED, '事务执行失败'],
  [ErrorCode.PREFS_READ_FAILED, '配置读取失败'],
  [ErrorCode.PREFS_WRITE_FAILED, '配置保存失败'],

  // 网络层错误
  [ErrorCode.NETWORK_TIMEOUT, '网络超时，请稍后重试'],
  [ErrorCode.NETWORK_DISCONNECTED, '网络连接失败，请检查网络'],
  [ErrorCode.NETWORK_DNS_FAILED, 'DNS解析失败'],
  [ErrorCode.NETWORK_SERVER_ERROR, '服务器错误，请稍后重试'],
  [ErrorCode.NETWORK_BUSINESS_ERROR, '业务处理失败'],
  [ErrorCode.NETWORK_UNAUTHORIZED, '认证失败，请重新登录'],

  // 导入层错误
  [ErrorCode.IMPORT_PARSE_FAILED, '课表解析失败'],
  [ErrorCode.IMPORT_FORMAT_UNSUPPORTED, '不支持的课表格式'],
  [ErrorCode.IMPORT_SESSION_EXPIRED, '会话已过期，请重新登录'],
  [ErrorCode.IMPORT_CAPTCHA_ERROR, '验证码错误'],
  [ErrorCode.IMPORT_CREDENTIAL_INVALID, '用户名或密码错误'],
  [ErrorCode.IMPORT_DATA_CONFLICT, '课表数据冲突'],

  // UI层错误
  [ErrorCode.ROUTER_INVALID, '页面跳转失败'],
  [ErrorCode.RESOURCE_MISSING, '资源文件缺失'],
  [ErrorCode.RENDER_DATA_INVALID, '数据格式错误']
]);