/**
 * 课程表业务服务
 * 职责：
 * - 课程导入
 * - 课程查询（按周、按天）
 * - 课程增删改
 */
import { CourseEntity } from '../model/entity/CourseEntity';
import { CourseImportDTO } from '../model/dto/CourseImportDTO';
import { ScheduleRepository } from '../repository/ScheduleRepository';
import { Result } from '../error/Result';
import { AppError } from '../error/AppError';
import { ErrorCode } from '../model/constants/ErrorCodeConstants';
import { Logger } from '../common/logger/Logger';
import { ColorService } from './ColorService';
import { IdGenerator } from '../common/util/IdGenerator';

export class ScheduleService {
  private static instance: ScheduleService | null = null;
  private repository: ScheduleRepository;
  private colorService: ColorService;

  private constructor() {
    this.repository = new ScheduleRepository();
    this.colorService = ColorService.getInstance();
  }

  public static getInstance(): ScheduleService {
    if (!ScheduleService.instance) {
      ScheduleService.instance = new ScheduleService();
    }
    return ScheduleService.instance;
  }

  /**
   * 导入课程列表
   */
  public async importCourses(courses: CourseImportDTO[]): Promise<Result<void>> {
    try {
      Logger.info(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'importCourses', `开始导入 ${courses.length} 门课程`)
      );

      // 转换 DTO 为 Entity，并分配颜色
      const entities: CourseEntity[] = courses.map(dto => {
        const entity = new CourseEntity();
        entity.id = IdGenerator.generateId('course');
        entity.termId = dto.termId;
        entity.name = dto.courseName;
        entity.teacher = dto.teachers;
        entity.dayOfWeek = dto.dayOfWeek;
        entity.startSection = dto.startSection;
        entity.endSection = dto.endSection;
        entity.startTime = dto.startTime;
        entity.endTime = dto.endTime;
        entity.startWeek = dto.startWeek;
        entity.endWeek = dto.endWeek;
        entity.location = dto.classroom;
        entity.weekType = 0;
        entity.sourceType = 1;

        // 自动分配颜色（同课程代码同颜色）
        entity.color = this.colorService.getCourseColor(dto.courseCode);

        entity.createdAt = Date.now();
        entity.updatedAt = Date.now();
        return entity;
      });

      // 批量插入数据库
      const result = await this.repository.batchAddCourses(entities);

      if (result.isSuccess()) {
        Logger.info(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'importCourses', '课程导入成功')
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'importCourses', '课程导入失败: %{public}s'),
          result.getError().message
        );
        return result.map(() => undefined);
      }
    } catch (err) {
      Logger.error(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'importCourses', '导入课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 获取指定周的所有课程
   */
  public async getWeekCourses(termId: string, week: number): Promise<Result<CourseEntity[]>> {
    try {
      const allCourses: CourseEntity[] = [];

      // 查询每一天的课程
      for (let day = 1; day <= 7; day++) {
        const dayResult = await this.repository.getCoursesByWeekAndDay(termId, week, day);
        if (dayResult.isSuccess() && dayResult.getData()) {
          allCourses.push(...dayResult.getData()!);
        }
      }

      Logger.info(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'getWeekCourses', `查询第${week}周课程，共${allCourses.length}门`)
      );

      return Result.success(allCourses);
    } catch (err) {
      Logger.error(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'getWeekCourses', '查询周课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    }
  }

  /**
   * 获取指定某一天的课程
   */
  public async getDayCourses(
    termId: string,
    week: number,
    dayOfWeek: number
  ): Promise<Result<CourseEntity[]>> {
    try {
      const result = await this.repository.getCoursesByWeekAndDay(termId, week, dayOfWeek);

      if (result.isSuccess() && result.getData()) {
        const courses = result.getData()!;
        // 按开始节次排序
        courses.sort((a, b) => a.startSection - b.startSection);

        Logger.info(
          'ScheduleService',
          Logger.formatMsg(
            'ScheduleService',
            'getDayCourses',
            `查询第${week}周星期${dayOfWeek}课程，共${courses.length}门`
          )
        );

        return Result.success(courses);
      } else {
        return result;
      }
    } catch (err) {
      Logger.error(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'getDayCourses', '查询当日课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_READ_FAILED, err as Error));
    }
  }

  /**
   * 清空指定学期的所有课程
   */
  public async clearAllCourses(termId: string): Promise<Result<void>> {
    try {
      Logger.info(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'clearAllCourses', `开始清空学期${termId}的所有课程`)
      );

      const result = await this.repository.deleteAllCoursesByTermId(termId);

      if (result.isSuccess()) {
        Logger.info(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'clearAllCourses', '课程清空成功')
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'clearAllCourses', '课程清空失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'clearAllCourses', '清空课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 插入单个课程
   */
  public async insertCourse(course: CourseEntity): Promise<Result<void>> {
    try {
      // 自动分配颜色
      if (!course.color || course.color === '') {
        course.color = this.colorService.getRandomColor();
      }

      const result = await this.repository.addCourse(course);

      if (result.isSuccess()) {
        Logger.info(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'insertCourse', `课程插入成功，ID: ${course.id}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'insertCourse', '课程插入失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'insertCourse', '插入课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }

  /**
   * 删除课程
   */
  public async deleteCourse(id: string): Promise<Result<void>> {
    try {
      const result = await this.repository.deleteCourse(id);

      if (result.isSuccess()) {
        Logger.info(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'deleteCourse', `课程删除成功，ID: ${id}`)
        );
        return Result.success(undefined);
      } else {
        Logger.error(
          'ScheduleService',
          Logger.formatMsg('ScheduleService', 'deleteCourse', '课程删除失败: %{public}s'),
          result.getError().message
        );
        return result;
      }
    } catch (err) {
      Logger.error(
        'ScheduleService',
        Logger.formatMsg('ScheduleService', 'deleteCourse', '删除课程异常: %{public}s'),
        JSON.stringify(err)
      );
      return Result.failure(AppError.dbError(ErrorCode.DB_WRITE_FAILED, err as Error));
    }
  }
}
