/**
 * 课程详情数据
 */
export interface CourseDetailItem {
  courseName: string;        // 课程名
  courseCode: string;        // 课程代码
  teachers: string;          // 教师（多个用 / 分隔）
  dayOfWeek: string;         // 星期几（如"周三"）
  sectionRange: string;      // 节次范围（如"第3-4节"）
  timeRange: string;         // 时间范围（如"10:10-11:45"）
  weekRange: string;         // 周次范围（如"1-6周"）
  classrooms: string[];      // 教室列表（支持多周不同教室）
}
