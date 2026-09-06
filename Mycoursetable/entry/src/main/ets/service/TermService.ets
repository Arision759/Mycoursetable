/**
 * 学期业务服务
 * 职责：
 * - 学期管理
 * - 当前周次计算
 * - 日期范围查询
 */
import { TermEntity } from '../model/entity/TermEntity';
import { TermRepository } from '../repository/TermRepository';
import { Result } from '../error/Result';
import { AppError } from '../error/AppError';
import { ErrorCode } from '../model/constants/ErrorCodeConstants';
import { Logger } from '../common/logger/Logger';
import { DateUtil } from '../common/util/DateUtil';

export interface WeekDateRange {
  start: number;
  end: number;
}

export class TermService {
  private static instance: TermService | null = null;
  private repository: TermRepository;

  private constructor() {
    this.repository = new TermRepository();
  }

  public static getInstance(): TermService {
    if (!TermService.instance) {
      TermService.instance = new TermService();
    }
    return TermService.instance;
  }

  /**
   * 创建学期
   */
  public async createTerm(term: TermEntity): Promise<Result<void>> {
    try {
      const result = await this.repository.createTerm(term);

      if (result.isSuccess()) {
        Logger.info(
          'TermService',
          Logger.formatMsg('TermService', 'createTerm', `学期创建成功，ID: ${term.id}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'TermService',
          Logger.formatMsg('TermService', 'createTerm', '学期创建失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'createTerm', '创建学期异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 更新学期
   */
  public async updateTerm(term: TermEntity): Promise<Result<void>> {
    try {
      const result = await this.repository.updateTerm(term);

      if (result.isSuccess()) {
        Logger.info(
          'TermService',
          Logger.formatMsg('TermService', 'updateTerm', `学期更新成功，ID: ${term.id}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'TermService',
          Logger.formatMsg('TermService', 'updateTerm', '学期更新失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'updateTerm', '更新学期异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 获取当前学期
   */
  public async getCurrentTerm(): Promise<Result<TermEntity | null>> {
    try {
      const result = await this.repository.getCurrentTerm();

      if (result.isSuccess()) {
        if (result.getData()) {
          Logger.info(
            'TermService',
            Logger.formatMsg('TermService', 'getCurrentTerm', `当前学期：${result.getData()!.name}`)
          );
        } else {
          Logger.warn(
            'TermService',
            Logger.formatMsg('TermService', 'getCurrentTerm', '未找到当前学期')
          );
        }
        return result;
      } else {
        Logger.error(
          'TermService',
          Logger.formatMsg('TermService', 'getCurrentTerm', '查询当前学期失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'getCurrentTerm', '查询当前学期异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    }
  }

  /**
   * 计算当前周次
   */
  public async getCurrentWeek(): Promise<Result<number>> {
    try {
      // 1. 获取当前学期
      const termResult = await this.getCurrentTerm();

      if (!termResult.isSuccess() || !termResult.getData()) {
        return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '未找到当前学期'));
      }

      const term = termResult.getData()!;
      const now = Date.now();

      // 2. 计算周次（从开学日期算起）
      const weekNumber = DateUtil.calculateWeek(term.startDate, now);

      // 3. 未开学时返回 0
      if (weekNumber <= 0) {
        Logger.info(
          'TermService',
          Logger.formatMsg('TermService', 'getCurrentWeek', `未开学（当前周次 = ${weekNumber}）`)
        );
        return Result.success(0);
      }

      // 4. 学期结束后返回最后一周
      const validWeek = Math.min(weekNumber, term.weekCount);

      Logger.info(
        'TermService',
        Logger.formatMsg('TermService', 'getCurrentWeek', `当前是第${validWeek}周`)
      );

      return Result.success(validWeek);
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'getCurrentWeek', '计算当前周次异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '计算当前周次失败', err as Error));
    }
  }

  /**
   * 获取指定周的日期范围
   */
  public async getWeekDateRange(week: number): Promise<Result<WeekDateRange>> {
    try {
      // 1. 获取当前学期
      const termResult = await this.getCurrentTerm();

      if (!termResult.isSuccess() || !termResult.getData()) {
        return Result.failure(AppError.businessError(ErrorCode.BUSINESS_ERROR, '未找到当前学期'));
      }

      const term = termResult.getData()!;

      // 2. 计算该周的起止日期
      const startDate = DateUtil.addDays(term.startDate, (week - 1) * 7);
      const endDate = DateUtil.addDays(startDate, 6);

      Logger.info(
        'TermService',
        Logger.formatMsg(
          'TermService',
          'getWeekDateRange',
          `第${week}周日期范围：${DateUtil.formatDate(startDate)} - ${DateUtil.formatDate(endDate)}`
        )
      );

      const range: WeekDateRange = {
        start: startDate,
        end: endDate
      };
      return Result.success(range);
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'getWeekDateRange', '查询周日期范围异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(
        AppError.businessError(ErrorCode.BUSINESS_ERROR, '查询周日期范围失败', err as Error)
      );
    }
  }

  /**
   * 获取所有学期
   */
  public async getAllTerms(): Promise<Result<TermEntity[]>> {
    try {
      const result = await this.repository.getAllTerms();

      if (result.isSuccess()) {
        Logger.info(
          'TermService',
          Logger.formatMsg('TermService', 'getAllTerms', `查询到${result.getData()?.length || 0}个学期`)
        );
        return result;
      } else {
        Logger.error(
          'TermService',
          Logger.formatMsg('TermService', 'getAllTerms', '查询所有学期失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'getAllTerms', '查询所有学期异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    }
  }

  /**
   * 切换当前学期
   */
  public async switchTerm(termId: string): Promise<Result<void>> {
    try {
      const result = await this.repository.setCurrentTerm(termId);

      if (result.isSuccess()) {
        Logger.info(
          'TermService',
          Logger.formatMsg('TermService', 'switchTerm', `已切换到学期：${termId}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'TermService',
          Logger.formatMsg('TermService', 'switchTerm', '切换学期失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'TermService',
        Logger.formatMsg('TermService', 'switchTerm', '切换学期异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }
}
