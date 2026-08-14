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
          AppError.paramError(ErrorCode.PARAM_ERROR, '提醒时间必须是 1、2、4 或 8 小时')
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
      return Result.failure(AppError.systemError(ErrorCode.SYSTEM_ERROR, '设置提醒时间失败', err as Error));
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
      return Result.failure(AppError.systemError(ErrorCode.SYSTEM_ERROR, '设置通知开关失败', err as Error));
    }
  }
}
