/**
 * 课程卡片 UI 数据（不可变快照）
 * 用于渲染，不包含业务逻辑
 */
export interface CourseCardItem {
  id: string;                    // 课程ID
  name: string;                  // 课程名
  teacher: string;               // 教师（多个用/分隔）
  room: string;                  // 教室（含教学楼，如"明远WH3203"）
  dayOfWeek: number;             // 星期几（1-7）
  startSection: number;          // 开始节次（1-12）
  endSection: number;            // 结束节次（1-12）
  startWeek: number;             // 开始周次（1-20）
  endWeek: number;               // 结束周次（1-20）
  color: ResourceColor;          // 卡片颜色
  isCurrentWeek: boolean;        // 是否本周课程
}
