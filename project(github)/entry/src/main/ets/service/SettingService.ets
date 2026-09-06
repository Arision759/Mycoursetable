/**
 * 设置业务服务
 * 职责：
 * - 提醒设置管理
 * - 通知开关管理
 */
import { SettingRepository } from '../repository/SettingRepository';
import { Result } from '../error/Result';
import { AppError } from '../error/AppError';
import { ErrorCode } from '../model/constants/ErrorCodeConstants';
import { Logger } from '../common/logger/Logger';
import { PrefsKey } from '../model/constants/AppConstants';

export class SettingService {
  private static instance: SettingService | null = null;
  private repository: SettingRepository;

  private constructor() {
    this.repository = new SettingRepository();
  }

  public static getInstance(): SettingService {
    if (!SettingService.instance) {
      SettingService.instance = new SettingService();
    }
    return SettingService.instance;
  }

  /**
   * 获取提醒时间（提前几小时）
   * 默认4小时
   */
  public async getReminderHours(): Promise<Result<number>> {
    try {
      const result = await this.repository.getString('reminder_hours', '4');

      if (result.isSuccess() && result.getData()) {
        const hours = parseInt(result.getData()!);
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'getReminderHours', `提醒时间：提前${hours}小时`)
        );
        return Result.success(hours);
      } else {
        return Result.success(4); // 默认4小时
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'getReminderHours', '获取提醒时间异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.success(4);
    }
  }

  /**
   * 设置提醒时间
   * @param hours - 提前几小时（1/2/4/8）
   */
  public async setReminderHours(hours: number): Promise<Result<void>> {
    try {
      // 验证参数
      if (![1, 2, 4, 8].includes(hours)) {
        return Result.failure(
          AppError.invalidParameter('提醒时间必须是 1、2、4 或 8 小时')
        );
      }

      const result = await this.repository.putString('reminder_hours', hours.toString());

      if (result.isSuccess()) {
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'setReminderHours', `提醒时间已设置为：提前${hours}小时`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'SettingService',
          Logger.formatMsg('SettingService', 'setReminderHours', '设置提醒时间失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'setReminderHours', '设置提醒时间异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '设置提醒时间失败', err as Error));
    }
  }

  /**
   * 获取通知开关状态
   * 默认true
   */
  public async isNotificationEnabled(): Promise<Result<boolean>> {
    try {
      const result = await this.repository.getBoolean('notification_enabled', true);

      if (result.isSuccess()) {
        const enabled = result.getData()!;
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'isNotificationEnabled', `通知开关：${enabled ? '开启' : '关闭'}`)
        );
        return Result.success(enabled);
      } else {
        return Result.success(true); // 默认开启
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'isNotificationEnabled', '获取通知开关异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.success(true);
    }
  }

  /**
   * 设置通知开关
   */
  public async setNotificationEnabled(enabled: boolean): Promise<Result<void>> {
    try {
      const result = await this.repository.putBoolean('notification_enabled', enabled);

      if (result.isSuccess()) {
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'setNotificationEnabled', `通知开关已${enabled ? '开启' : '关闭'}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'SettingService',
          Logger.formatMsg('SettingService', 'setNotificationEnabled', '设置通知开关失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'setNotificationEnabled', '设置通知开关异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '设置通知开关失败', err as Error));
    }
  }

  /**
   * 获取桌面下节课提醒是否启用
   * 默认开启
   */
  public async isDesktopReminderEnabled(): Promise<Result<boolean>> {
    try {
      const result = await this.repository.getBoolean(PrefsKey.DESKTOP_REMINDER_ENABLED, true);
      if (result.isSuccess()) {
        const enabled = result.getData()!;
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'isDesktopReminderEnabled', `桌面提醒：${enabled ? '开启' : '关闭'}`)
        );
        return Result.success(enabled);
      } else {
        return Result.success(true);
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'isDesktopReminderEnabled', '获取桌面提醒开关异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.success(true);
    }
  }

  /**
   * 设置桌面下节课提醒是否启用
   */
  public async setDesktopReminderEnabled(enabled: boolean): Promise<Result<void>> {
    try {
      const result = await this.repository.putBoolean(PrefsKey.DESKTOP_REMINDER_ENABLED, enabled);
      if (result.isSuccess()) {
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'setDesktopReminderEnabled', `桌面提醒已${enabled ? '开启' : '关闭'}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'SettingService',
          Logger.formatMsg('SettingService', 'setDesktopReminderEnabled', '设置桌面提醒开关失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'setDesktopReminderEnabled', '设置桌面提醒开关异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '设置桌面提醒开关失败', err as Error));
    }
  }

  /**
   * 获取桌面下节课提醒提前时间（分钟）
   * 默认120分钟（2小时）
   */
  public async getDesktopReminderAdvanceMinutes(): Promise<Result<number>> {
    try {
      const result = await this.repository.getNumber(PrefsKey.DESKTOP_REMINDER_ADVANCE_MINUTES, 120);
      if (result.isSuccess()) {
        const minutes = result.getData()!;
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'getDesktopReminderAdvanceMinutes', `桌面提醒提前：${minutes}分钟`)
        );
        return Result.success(minutes);
      } else {
        return Result.success(120);
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'getDesktopReminderAdvanceMinutes', '获取桌面提醒时间异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.success(120);
    }
  }

  /**
   * 设置桌面下节课提醒提前时间（分钟）
   */
  public async setDesktopReminderAdvanceMinutes(minutes: number): Promise<Result<void>> {
    try {
      if (minutes <= 0) {
        return Result.failure(
          AppError.invalidParameter('桌面提醒提前时间必须大于0分钟')
        );
      }

      const result = await this.repository.putNumber(PrefsKey.DESKTOP_REMINDER_ADVANCE_MINUTES, minutes);
      if (result.isSuccess()) {
        Logger.info(
          'SettingService',
          Logger.formatMsg('SettingService', 'setDesktopReminderAdvanceMinutes', `桌面提醒时间已设置为：提前${minutes}分钟`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'SettingService',
          Logger.formatMsg('SettingService', 'setDesktopReminderAdvanceMinutes', '设置桌面提醒时间失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'SettingService',
        Logger.formatMsg('SettingService', 'setDesktopReminderAdvanceMinutes', '设置桌面提醒时间异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '设置桌面提醒时间失败', err as Error));
    }
  }
}
