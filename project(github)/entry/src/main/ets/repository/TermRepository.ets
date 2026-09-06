/**
 * 学期数据仓储
 * 封装 TermDao，提供学期数据访问
 */
import { Logger } from '../common/logger/Logger';
import { Result } from '../error/Result';
import { AppError } from '../error/AppError';
import { TermEntity } from '../model/entity/TermEntity';
import { TermDao } from '../datasource/db/dao/TermDao';

/**
 * 学期仓储类
 */
export class TermRepository {
  private static readonly TAG: string = 'TermRepository';

  /**
   * 创建学期
   */
  public async createTerm(term: TermEntity): Promise<Result<void>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'createTerm', `Creating term: ${term.name}`)
    );

    const result = await TermDao.insert(term);
    return result.map(() => undefined);
  }

  /**
   * 更新学期
   */
  public async updateTerm(term: TermEntity): Promise<Result<void>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'updateTerm', `Updating term: ${term.id}`)
    );

    const result = await TermDao.update(term);
    if (result.isSuccess() && result.getData() === 0) {
      return Result.failure(AppError.dataNotFound('学期不存在'));
    }
    return result.map(() => undefined);
  }

  /**
   * 删除学期
   */
  public async deleteTerm(termId: string): Promise<Result<void>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'deleteTerm', `Deleting term: ${termId}`)
    );

    const result = await TermDao.delete(termId);
    if (result.isSuccess() && result.getData() === 0) {
      return Result.failure(AppError.dataNotFound('学期不存在'));
    }
    return result.map(() => undefined);
  }

  /**
   * 根据ID获取学期
   */
  public async getTermById(termId: string): Promise<Result<TermEntity | null>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'getTermById', `Getting term: ${termId}`)
    );

    return await TermDao.queryById(termId);
  }

  /**
   * 获取当前学期
   */
  public async getCurrentTerm(): Promise<Result<TermEntity | null>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'getCurrentTerm', 'Getting current term')
    );

    return await TermDao.queryCurrentTerm();
  }

  /**
   * 获取所有学期
   */
  public async getAllTerms(): Promise<Result<TermEntity[]>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'getAllTerms', 'Getting all terms')
    );

    return await TermDao.queryAll();
  }

  /**
   * 设置当前学期
   */
  public async setCurrentTerm(termId: string): Promise<Result<void>> {
    Logger.debug(
      TermRepository.TAG,
      Logger.formatMsg(TermRepository.TAG, 'setCurrentTerm', `Setting current term: ${termId}`)
    );

    return await TermDao.setCurrentTerm(termId);
  }
}
