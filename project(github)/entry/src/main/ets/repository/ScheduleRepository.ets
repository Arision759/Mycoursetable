/**
 * 课程表数据仓储
 * 封装 CourseDao，提供课程数据访问
 */
import { Logger } from '../common/logger/Logger';
import { Result } from '../error/Result';
import { AppError } from '../error/AppError';
import { CourseEntity } from '../model/entity/CourseEntity';
import { CourseDao } from '../datasource/db/dao/CourseDao';

/**
 * 课程表仓储类
 */
export class ScheduleRepository {
  private static readonly TAG: string = 'ScheduleRepository';

  /**
   * 添加课程
   */
  public async addCourse(course: CourseEntity): Promise<Result<void>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'addCourse', `Adding course: ${course.name}`)
    );

    const result = await CourseDao.insert(course);
    return result.map(() => undefined);
  }

  /**
   * 批量添加课程
   */
  public async batchAddCourses(courses: CourseEntity[]): Promise<Result<number>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'batchAddCourses', `Adding ${courses.length} courses`)
    );

    return await CourseDao.batchInsert(courses);
  }

  /**
   * 更新课程
   */
  public async updateCourse(course: CourseEntity): Promise<Result<void>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'updateCourse', `Updating course: ${course.id}`)
    );

    const result = await CourseDao.update(course);
    if (result.isSuccess() && result.getData() === 0) {
      return Result.failure(AppError.dataNotFound('课程不存在'));
    }
    return result.map(() => undefined);
  }

  /**
   * 删除课程
   */
  public async deleteCourse(courseId: string): Promise<Result<void>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'deleteCourse', `Deleting course: ${courseId}`)
    );

    const result = await CourseDao.delete(courseId);
    if (result.isSuccess() && result.getData() === 0) {
      return Result.failure(AppError.dataNotFound('课程不存在'));
    }
    return result.map(() => undefined);
  }

  /**
   * 根据ID获取课程
   */
  public async getCourseById(courseId: string): Promise<Result<CourseEntity | null>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'getCourseById', `Getting course: ${courseId}`)
    );

    return await CourseDao.queryById(courseId);
  }

  /**
   * 获取指定学期、周次、星期的课程列表
   */
  public async getCoursesByWeekAndDay(
    termId: string,
    week: number,
    dayOfWeek: number
  ): Promise<Result<CourseEntity[]>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(
        ScheduleRepository.TAG,
        'getCoursesByWeekAndDay',
        `Getting courses: term=${termId}, week=${week}, day=${dayOfWeek}`
      )
    );

    return await CourseDao.queryByTermWeekDay(termId, week, dayOfWeek);
  }

  /**
   * 获取指定学期的所有课程
   */
  public async getCoursesByTermId(termId: string): Promise<Result<CourseEntity[]>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'getCoursesByTermId', `Getting courses for term: ${termId}`)
    );

    return await CourseDao.queryByTermId(termId);
  }

  /**
   * 删除指定学期的所有课程
   */
  public async deleteAllCoursesByTermId(termId: string): Promise<Result<void>> {
    Logger.debug(
      ScheduleRepository.TAG,
      Logger.formatMsg(ScheduleRepository.TAG, 'deleteAllCoursesByTermId', `Deleting all courses for term: ${termId}`)
    );

    const result = await CourseDao.deleteByTermId(termId);
    return result.map(() => undefined);
  }
}
