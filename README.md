# 课程表 App (HarmonyOS Next)

一个基于 HarmonyOS Next 开发的课程表应用，支持从教务系统自动导入课程数据。

## ✨ 功能特性

- 🔐 **教务系统登录**：支持 CAS 单点登录认证
- 📥 **课程自动导入**：自动解析教务系统课表 HTML
- 📅 **周课表显示**：清晰直观的周课程表界面
- 🔄 **周次切换**：支持查看任意周次的课程
- 📱 **课程详情**：点击课程卡片查看详细信息
- 💾 **本地存储**：RelationalStore 数据库持久化

## 🛠️ 技术栈

- **平台**：HarmonyOS Next (API 12)
- **语言**：ArkTS
- **数据库**：RelationalStore
- **网络**：HTTP 模块
- **UI框架**：ArkUI (Stack 布局)

## 📦 项目结构

```
Entry/src/main/ets/
├── common/              # 公共工具
│   ├── logger/         # 日志工具
│   ├── router/         # 路由工具
│   └── util/           # 工具类
├── components/          # UI组件
│   ├── CourseCard.ets           # 课程卡片
│   └── CourseDetailDialog.ets   # 课程详情弹窗
├── constants/           # 常量定义
├── datasource/          # 数据源层
│   ├── db/             # 数据库
│   │   ├── dao/        # 数据访问对象
│   │   ├── RdbManager.ets      # 数据库管理器
│   │   └── RdbMigration.ets    # 数据库迁移
│   └── prefs/          # 偏好设置
├── model/              # 数据模型
│   ├── entity/         # 数据实体
│   └── dto/            # 数据传输对象
├── pages/              # 页面
│   ├── Index.ets               # 启动页
│   ├── LoginImportPage.ets     # 登录导入页
│   └── WeekSchedulePage.ets    # 周课表页
├── repository/         # 仓储层
├── service/            # 服务层
│   ├── EamsLoginService.ets    # 教务系统登录
│   ├── ScheduleService.ets     # 课程表服务
│   └── TermService.ets         # 学期服务
├── utils/              # 工具类
│   ├── CourseParserFromJS.ets  # 课程解析器
│   └── TimeTableParser.ets     # 时间表解析器
└── viewmodel/          # 视图模型
    └── WeekScheduleViewModel.ets
```

## 🚀 快速开始

### 环境要求

- DevEco Studio 5.0+
- HarmonyOS Next SDK (API 12)

### 运行步骤

1. 克隆项目
```bash
git clone <repository-url>
cd project
```

2. 打开 DevEco Studio，导入项目

3. 配置签名证书（自动签名或手动签名）

4. 运行项目到模拟器或真机

## 📝 使用说明

### 首次使用

1. 启动应用，点击**登录并导入**
2. 输入教务系统账号密码
3. 等待课程数据导入完成
4. 自动跳转到周课表页面

### 查看课表

- **切换周次**：点击顶部的 ◀ ▶ 按钮
- **查看详情**：点击课程卡片查看详细信息
- **滚动查看**：上下滚动查看全天课程

## 🐛 已知问题

- 未开学时显示"第0周"（未来优化）
- 课程颜色随机生成（未来支持自定义）

## 🔧 开发调试

### 数据库结构

**term 表**（学期）
- id: TEXT PRIMARY KEY
- name: TEXT
- startDate: TEXT
- endDate: TEXT

**course 表**（课程）
- id: TEXT PRIMARY KEY
- termId: TEXT
- name: TEXT
- teacher: TEXT
- dayOfWeek: INTEGER (1-7)
- startSection: INTEGER (1-12)
- endSection: INTEGER (1-12)
- startWeek: INTEGER
- endWeek: INTEGER
- location: TEXT
- color: TEXT

### 关键修复记录

#### 1. 周次解析偏移 +1
**问题**：所有课程周次都偏移 +1（1-6周显示为2-7周）

**原因**：`CourseParserFromJS.parseValidWeeks()` 错误地对索引 +1

**修复**：
```typescript
// 修复前
startWeek = i + 1;  // ❌

// 修复后
startWeek = i === 0 ? 1 : i;  // ✅
```

#### 2. 课程卡片铺满整天
**问题**：所有课程卡片铺满1-11节，无法正确显示节次范围

**原因**：HarmonyOS Grid 的 `onGetRectByIndex` 在不规则布局时存在问题

**修复**：放弃 Grid，改用 **Stack + 绝对定位**
```typescript
// 新方案
Stack() {
  // 背景网格
  Column({ space: 4 }) { ... }
  
  // 课程卡片（绝对定位）
  ForEach(courses) {
    CourseCard()
      .position({
        x: `${(dayOfWeek-1) * 100 / 7}%`,
        y: (startSection-1) * (56 + 4)
      })
      .width(`${100/7 - 0.5}%`)
      .height(节次数 × 56 + 间隙)
  }
}
```

## 📄 开源协议

MIT License

## 👨‍💻 作者

31106

## 📅 版本历史

### v1.0 (2026-08-15)
- ✨ 完成核心功能开发
- 🐛 修复周次解析和布局问题
- 📦 首次 Git 提交
