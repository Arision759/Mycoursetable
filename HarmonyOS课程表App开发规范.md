# HarmonyOS NEXT 大学生课程表 App 开发规范

> 文档版本：v1.0
> 适用平台：HarmonyOS NEXT（API 12+，DevEco Studio 5.0+）
> 技术栈：ArkTS / ArkUI / Stage 模型
> 目标形态：无广告、纯本地、高性能、可扩展的商业级应用
> 读者：执行开发的 AI 程序员 / 工程团队
> 约束：本规范只定义架构、边界、接口与规则，不包含具体业务实现代码。

---

## 0. 规范总则与设计原则

| 原则 | 说明 |
|---|---|
| **分层解耦** | UI、状态、业务、数据、基础设施严格分层，禁止跨层直接调用 |
| **本地优先** | 核心功能（课表查询、增删改）100% 离线可用，网络仅用于"教务导入"等增值能力 |
| **可扩展优先** | 教务系统按"学校适配器"插件化设计，新增学校不改动核心代码 |
| **类型安全** | 全面使用 ArkTS 强类型，禁止 `any`/`unknown` 滥用、禁止无类型对象字面量 |
| **单一数据源** | 所有课表数据以本地 RDB 为唯一可信来源，内存态仅为 UI 渲染副本 |
| **性能预算** | 首屏 < 800ms；周课表切换 < 100ms；导入 500 节课 < 3s（含解析） |
| **可交付性** | 每个模块必须有明确的输入/输出契约，接口优先、实现后置 |

---

## 1. 项目整体架构

### 1.1 架构风格：分层 MVVM + 仓储模式 + 适配器模式

```
┌─────────────────────────────────────────────────────────────┐
│                        UI 层（ArkUI）                        │
│   Page(页面) → ViewComponent(业务组件) → BaseComponent(原子组件) │
└──────────────────────────┬──────────────────────────────────┘
                           │ @Local/@Param/@Event/@Provider 驱动
┌──────────────────────────▼──────────────────────────────────┐
│                     ViewModel 层（状态编排）                   │
│   页面级状态、命令(Command)、用户意图(Intent)、UI 派生逻辑      │
└──────────────────────────┬──────────────────────────────────┘
                           │ 调用 Service
┌──────────────────────────▼──────────────────────────────────┐
│                     Service 层（业务用例）                     │
│  ScheduleService / TermService / ImportService / SettingService │
└───────────────┬──────────────────────────┬───────────────────┘
                │                          │
     ┌──────────▼──────────┐     ┌─────────▼──────────┐
     │  Repository 层       │     │  Adapter 层(教务插件) │
     │  ScheduleRepository │     │  SchoolAdapter 接口  │
     │  TermRepository     │     │  ├─ HtmlParser 策略   │
     │  SettingRepository  │     │  └─ ApiParser 策略    │
     └──────────┬──────────┘     └─────────┬──────────┘
                │                          │
     ┌──────────▼──────────────────────────▼──────────┐
     │              Data Source 层（数据源）             │
     │  RDB(课表/学期/课程) │ Preferences(设置) │ 文件(缓存) │
     └─────────────────────────────────────────────────┘
     ┌─────────────────────────────────────────────────┐
     │              Common 层（横切能力）                 │
     │  日志 hilog │ 错误处理 ErrorKit │ 任务 TaskPool │ 工具 Util │
     └─────────────────────────────────────────────────┘
```

### 1.2 各层职责边界（红线）

| 层 | 允许依赖 | 禁止事项 |
|---|---|---|
| UI 层 | 仅依赖 ViewModel 与组件自身状态 | 禁止直接操作 RDB/Preferences/网络；禁止在 `build()` 中执行副作用 |
| ViewModel 层 | 仅依赖 Service | 禁止持有 UI 上下文做数据操作；禁止直接 import 数据库 API |
| Service 层 | 仅依赖 Repository / Adapter | 禁止直接执行 SQL、拼接 URL |
| Repository 层 | 仅依赖 Data Source | 禁止向 UI 抛出原始异常，必须返回统一 `Result` |
| Adapter 层 | 依赖网络层与解析工具 | 禁止反向依赖 UI/ViewModel；禁止修改核心课表模型 |
| Data Source 层 | 仅依赖系统 Kit | 禁止包含任何业务判断逻辑 |

### 1.3 依赖方向

依赖只能**从上向下**单向流动。任何下层模块不得 `import` 上层模块。跨模块通信一律通过接口 + 事件回调（见第 5 章状态管理）。

---

## 2. 推荐目录结构

基于 Stage 模型，业务代码全部位于 `entry/src/main/ets/` 下。

```
entry/src/main/
├── ets/
│   ├── entryability/
│   │   └── EntryAbility.ets          # UIAbility 入口，仅做初始化编排
│   ├── pages/                        # 页面（@Entry）
│   │   ├── IndexPage.ets             # 主框架页（底部 Tab 容器）
│   │   ├── schedule/                 # 课表模块
│   │   │   ├── WeekSchedulePage.ets  # 周课表主页
│   │   │   ├── CourseDetailPage.ets  # 课程详情
│   │   │   └── CourseEditPage.ets    # 添加/编辑课程
│   │   ├── import/                   # 教务导入模块
│   │   │   ├── ImportEntryPage.ets
│   │   │   ├── SchoolSelectPage.ets
│   │   │   └── ImportResultPage.ets
│   │   └── settings/
│   │       └── SettingsPage.ets
│   ├── viewmodel/                    # 与页面一一对应
│   │   ├── WeekScheduleViewModel.ets
│   │   ├── CourseDetailViewModel.ets
│   │   ├── CourseEditViewModel.ets
│   │   ├── ImportViewModel.ets
│   │   └── SettingsViewModel.ets
│   ├── components/                   # 可复用业务组件
│   │   ├── schedule/
│   │   │   ├── WeekGridComponent.ets      # 周网格容器
│   │   │   ├── CourseCardComponent.ets    # 课程卡片
│   │   │   └── WeekSwitcherComponent.ets  # 周切换器
│   │   ├── import/
│   │   │   ├── CaptchaInputComponent.ets
│   │   │   └── ImportProgressComponent.ets
│   │   └── common/                   # 通用业务组件
│   │       ├── EmptyStateComponent.ets
│   │       ├── LoadingStateComponent.ets
│   │       └── ConfirmDialogComponent.ets
│   ├── base/                         # 原子/基础组件（无业务语义）
│   │   ├── BaseButton.ets
│   │   ├── BaseTag.ets
│   │   └── BaseTextField.ets
│   ├── service/                      # 业务用例层
│   │   ├── ScheduleService.ets
│   │   ├── TermService.ets
│   │   ├── ImportService.ets
│   │   └── SettingService.ets
│   ├── repository/                   # 仓储层
│   │   ├── ScheduleRepository.ets
│   │   ├── TermRepository.ets
│   │   └── SettingRepository.ets
│   ├── model/                        # 领域模型 & DTO & 常量
│   │   ├── entity/                   # RDB 表映射实体
│   │   │   ├── CourseEntity.ets
│   │   │   ├── TermEntity.ets
│   │   │   └── SchoolEntity.ets
│   │   ├── dto/                      # 教务解析标准化输出
│   │   │   └── CourseImportDTO.ets
│   │   └── constants/
│   │       ├── AppConstants.ets
│   │       └── ErrorCodeConstants.ets
│   ├── datasource/                   # 数据源封装（系统 Kit 唯一入口）
│   │   ├── db/
│   │   │   ├── RdbManager.ets        # 建库/连接/事务/队列
│   │   │   ├── RdbMigration.ets      # schema 版本迁移
│   │   │   └── dao/                  # 每个表一个 DAO
│   │   │       ├── CourseDao.ets
│   │   │       ├── TermDao.ets
│   │   │       └── SchoolDao.ets
│   │   └── prefs/
│   │       └── PreferencesManager.ets
│   ├── network/                      # 网络层（见第 7 章）
│   │   ├── HttpClient.ets
│   │   ├── Interceptor.ets
│   │   ├── ApiResult.ets
│   │   └── NetConfig.ets
│   ├── import/                       # 教务系统解析模块（见第 8 章）
│   │   ├── adapter/
│   │   │   ├── SchoolAdapter.ets     # 适配器统一接口
│   │   │   ├── SchoolAdapterRegistry.ets
│   │   │   └── schools/              # 每校一个适配器实现
│   │   │       ├── DefaultSchoolAdapter.ets
│   │   │       └── ...               # 未来扩展
│   │   ├── parser/
│   │   │   ├── HtmlScheduleParser.ets
│   │   │   ├── ApiScheduleParser.ets
│   │   │   └── NormalizeRule.ets     # 字段归一化规则
│   │   └── task/
│   │       └── ParseTask.ets         # TaskPool 并发解析任务
│   ├── error/                        # 错误处理（见第 9 章）
│   │   ├── Result.ets
│   │   ├── AppError.ets
│   │   └── ErrorHandler.ets
│   └── common/                       # 横切工具
│       ├── logger/
│       │   └── Logger.ets            # 统一封装 hilog
│       ├── util/
│       │   ├── DateUtil.ets          # 周次/日期计算
│       │   └── IdGenerator.ets
│       └── router/
│           └── RouterUtil.ets
├── resources/                        # 资源：base/ 与限定词目录
│   ├── base/
│   │   ├── element/                  # color.json / string.json / float.json
│   │   ├── media/                    # 图标、图片
│   │   └── profile/
│   │       └── main_pages.json       # 页面路由注册表
│   └── ...
└── module.json5                      # 模块配置（权限、Ability、存储扩展）
```

> 规则：目录层级不允许出现同名多义词；新增模块必须先在本规范中登记目录位置再编码。

---

## 3. 页面设计规范

### 3.1 页面清单与路由（main_pages.json 注册）

| 路由名 | 页面 | 说明 |
|---|---|---|
| `pages/IndexPage` | 主框架页 | 底部 Tab：课表 / 课程 / 我的 |
| `pages/schedule/WeekSchedulePage` | 周课表 | 核心页，网格布局 |
| `pages/schedule/CourseDetailPage` | 课程详情 | 只读展示 |
| `pages/schedule/CourseEditPage` | 课程编辑 | 新增/编辑共用 |
| `pages/import/ImportEntryPage` | 导入入口 | 引导 + 学校选择 |
| `pages/import/SchoolSelectPage` | 学校选择 | 搜索、最近使用 |
| `pages/import/ImportResultPage` | 导入结果 | 冲突对比、确认导入 |
| `pages/settings/SettingsPage` | 设置 | 学期、周数、主题等 |

### 3.2 页面结构模板（每个 Page 必须遵守）

```text
Page 职责
├── 静态配置：路由名、页面标题、是否全屏
├── 状态声明：@Local 页面级状态（禁止散落裸变量）
├── 依赖注入：在 aboutToAppear 中实例化 ViewModel
├── 生命周期：
│   ├── aboutToAppear  → 只做订阅与只读初始化
│   ├── onPageShow     → 触发数据刷新（从后台返回时）
│   └── aboutToDisappear → 取消订阅、释放定时器/网络任务
├── build()：
│   └── 纯声明式 UI，禁止出现 if 之外的副作用（如 await、DB 调用）
└── 事件回调：一律转发给 ViewModel 方法，页面不留业务逻辑
```

### 3.3 UI 硬性要求

1. **状态完备**：任何数据区必须有 加载中 / 成功 / 空 / 失败 四态，禁止直接白屏。
2. **响应式**：基于 `vp`、百分比、`GridRow`/`GridCol` 布局，适配折叠屏与横竖屏。
3. **无障碍**：所有可交互组件设置 `accessibilityText`，字号跟随系统（用 fp）。
4. **主题**：颜色、圆角、间距统一从 `resources/base/element` 的 `color.json`/`float.json` 读取，禁止硬编码色值（除调试外）。
5. **深色模式**：颜色使用系统资源或自定义资源限定词目录适配，禁止固定黑白。
6. **周课表布局基准**：横向 7 列（周一至周日），纵向按节次（默认 12 节/天），跨节课程用行跨度，时间冲突在同一格内纵向堆叠并标红提示。

### 3.4 性能红线（页面级）

- 页面 `build()` 不得包含循环内的复杂计算，复杂数据派生在 ViewModel 中完成。
- 长列表（学校列表、课程列表）必须使用 `LazyForEach` + 独立 `IDataSource`，禁止 `ForEach` 渲染大数据集。
- 周课表网格允许一次构建全部格子，但单格内部禁止再嵌套可观察对象引发的整树刷新（见第 5 章）。

---

## 4. ArkTS 代码规范

### 4.1 类型安全（强制）

| 规则 | 说明 |
|---|---|
| 禁止 `any` | 所有函数参数、返回值、变量必须显式声明类型 |
| 禁止无类型对象字面量 | 对象字面量必须归属已定义的 `interface`/`class`，或显式类型断言 |
| 禁止 `Function` 类型 | 回调一律使用具名函数类型 |
| 禁止 `var` | 一律 `let`/`const`，优先 `const` |
| 避免对象解构 | ArkTS 限制，改用属性访问 |
| 类成员显式可见性 | 统一使用 `private`/`public` |
| 返回类型必写 | 所有方法（含 `build`）显式标注返回类型 |

### 4.2 命名与风格

- 类/接口/枚举：`PascalCase`（`CourseService`、`CourseEntity`）
- 函数/变量/属性：`camelCase`（`getWeekCourses`、`startTime`）
- 常量：`UPPER_SNAKE_CASE`（`MAX_COURSE_COUNT`）
- 枚举值：`UPPER_SNAKE_CASE`
- 单文件单主类型；导入使用 `@kit.*` 官方聚合包（`@kit.ArkData` 等），禁止裸 `@ohos.*` 分散导入

### 4.3 结构约束

- 每个 `.ets` 文件建议 ≤ 300 行，超过必须拆分。
- `build()` 方法 ≤ 150 行，超长拆分子组件。
- 单个函数 ≤ 50 行；圈复杂度 ≤ 10。
- 嵌套层级 ≤ 4 层。
- 注释：类/接口写职责说明；复杂方法写 `@param`/`@returns`；魔法数字必须命名常量。

### 4.4 日志与调试

- 统一通过 `common/logger/Logger.ets` 输出，禁止直接散落 `console.log`。
- 日志分级：`DEBUG` / `INFO` / `WARN` / `ERROR`，生产环境仅保留 `WARN` 与 `ERROR`。
- 日志必须携带 domain 与 TAG，格式：`[模块][方法名] 关键信息`，不得打印密码、Token 等敏感数据。

---

## 5. 状态管理方案

### 5.1 总策略：V2 状态管理 + AppStorage 兜底

HarmonyOS NEXT 新项目统一采用 **ArkUI V2 状态管理**（`@ComponentV2`/`@Local`/`@Param`/`@Event`/`@Provider`/`@Consumer`/`@ObservedV2`/`@Trace`），不再使用 V1 的 `@State`/`@Prop`/`@Link` 混用体系。

### 5.2 场景 → 方案映射（强制遵守）

| 场景 | 方案 | 说明 |
|---|---|---|
| 组件私有 UI 状态 | `@Local` | 输入框内容、弹窗开关等 |
| 父→子单向数据 | `@Param` | 子组件接收只读数据 |
| 子→父事件通知 | `@Event` | 子组件回调父组件，不直接改父状态 |
| 祖先→后代跨层共享 | `@Provider`/`@Consumer` | 如"当前学期""当前周" |
| 领域模型内部字段变化 | `@ObservedV2` + `@Trace` | 仅对需要驱动 UI 的字段加 `@Trace` |
| 跨页面全局配置 | `AppStorage`/`PersistentStorage` | 主题、当前学期 ID、周次起点等 |
| 复杂全局业务状态 | 独立 Store | 如导入任务状态机，仅在必要时引入 |

### 5.3 状态边界规则

1. **UI 不直接持有领域模型**：Page 持有 ViewModel，ViewModel 持有 Service 返回的可观察模型。
2. **禁止状态漂移**：同一份数据不得在 Page 与 ViewModel 各存一份可变副本。
3. **最小观察粒度**：`@Trace` 只标注"会变化且需刷新 UI"的字段。
4. **写操作单向流**：`UI 事件 → ViewModel 命令 → Service → Repository → RDB`，数据回流走 `Result` 回执。
5. **生命周期绑定**：`aboutToDisappear` 中必须取消订阅、关闭定时器、中止未完成任务。

### 5.4 周课表性能专项

- 网格容器只依赖一份可观察的 `WeekScheduleSnapshot`。
- 单节课程卡片使用 `@Param` 接收不可变快照，卡片内部不订阅全局状态。
- 切换周次时，先在 ViewModel 生成新快照，再一次性替换，禁止逐格赋值。

---

## 6. 数据模型设计规范

### 6.1 存储选型（强制）

| 数据类型 | 存储方案 | 理由 |
|---|---|---|
| 课表/课程/学期/学校等结构化关系数据 | RDB（`@kit.ArkData` relationalStore） | 需要复杂查询、索引、事务 |
| 用户设置（主题、周起始日、当前学期） | Preferences（`@kit.ArkData` preferences） | 轻量 KV，≤50MB |
| 导入的原始 JSON/HTML 缓存 | 文件系统（`@kit.CoreFileKit`，沙盒 `files/import_cache/`） | 大体积、可丢弃 |
| 敏感凭据（如有） | HUKS 安全存储，禁止明文落盘 | 安全要求 |

### 6.2 RDB 表设计（概念字段，非最终 DDL）

**school（学校）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | TEXT | PK | 学校唯一 ID |
| name | TEXT | NOT NULL | 学校名 |
| adapterKey | TEXT | NOT NULL | 对应适配器标识 |
| importType | INTEGER | NOT NULL | 0=HTML 抓取 1=API |
| enabled | INTEGER | DEFAULT 1 | 是否启用 |

**term（学期）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | TEXT | PK | 学期 ID |
| name | TEXT | NOT NULL | 学期名 |
| startDate | INTEGER | NOT NULL | 学期起始日期（时间戳） |
| weekCount | INTEGER | NOT NULL | 总周数 |
| isCurrent | INTEGER | DEFAULT 0 | 是否当前学期 |

**course（课程，核心表）**

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | TEXT | PK | 课程 ID |
| termId | TEXT | FK→term.id | 所属学期 |
| name | TEXT | NOT NULL | 课程名 |
| teacher | TEXT | - | 教师 |
| location | TEXT | - | 上课地点 |
| dayOfWeek | INTEGER | NOT NULL | 1-7 周一至周日 |
| startSection | INTEGER | NOT NULL | 起始节次 |
| endSection | INTEGER | NOT NULL | 结束节次 |
| startWeek | INTEGER | NOT NULL | 起始周 |
| endWeek | INTEGER | NOT NULL | 结束周 |
| weekType | INTEGER | DEFAULT 0 | 0=每周 1=单周 2=双周 |
| colorIndex | INTEGER | DEFAULT 0 | 课程配色索引 |
| remark | TEXT | - | 备注 |
| sourceType | INTEGER | DEFAULT 0 | 0=手动 1=教务导入 |
| createdAt/updatedAt | INTEGER | - | 时间戳 |

### 6.3 索引与约束

- `course` 表建联合索引：`(termId, dayOfWeek, startSection)`。
- `term.isCurrent` 建普通索引。
- 初始化时执行 `PRAGMA foreign_keys = ON`。
- 所有 `TEXT` 主键由 `IdGenerator` 统一生成，禁止自增整数暴露业务。

### 6.4 数据库访问规范

1. 所有 SQL 通过 `dao/` 层执行，DAO 是唯一允许写 SQL 的地方。
2. 查询一律使用 `RdbPredicates` 构建条件，禁止字符串拼接 SQL。
3. `ResultSet` 使用后**必须 `close()`**，用 `try-finally` 包裹。
4. 批量写入必须走事务：`beginTransaction` → 批量 insert → `commit`，异常 `rollback`。
5. RDB 单写连接，多操作通过 `RdbManager` 内部串行任务队列调度。
6. **Schema 版本管理**：`RdbManager` 记录 `DB_VERSION`，`RdbMigration` 提供逐版本迁移函数；新增字段/表必须新增迁移步骤。

### 6.5 数据模型映射原则

- Entity（表映射）与 UI 展示模型分离：UI 使用轻量快照/DTO。
- 所有跨层传递使用 `Result<T>` 包装，数据本身不可变（`readonly` 字段）。

---

## 7. 网络请求层设计

> 当前版本网络仅服务于"教务系统导入"与"学校列表远程配置"（可选），不参与课表日常查询。

### 7.1 分层结构

```
业务层(ImportService)
   │  调用 ApiResult<T> request(...)
   ▼
HttpClient（统一入口：超时、重试、拦截器、并发控制）
   ▼
传输层：rcp（@kit.NetworkKit）为主，@ohos.net.http 为兼容兜底
```

### 7.2 HttpClient 契约

```text
- 统一 request<T>(config): Promise<ApiResult<T>>
- 注入请求拦截器（加 UA、设备信息、签名）
- 注入响应拦截器（HTTP 状态码映射、业务 code 映射）
- 超时策略：connectTimeout 15s / readTimeout 30s（教务接口可配置）
- 重试策略：仅对网络层错误与 5xx 重试，最多 3 次，指数退避 + 随机抖动
- 取消：返回可取消句柄，页面销毁时取消未完成请求
```

### 7.3 规则

1. `module.json5` 声明 `ohos.permission.INTERNET`。
2. **禁止业务层直接 new http/rcp 对象**，必须走 HttpClient。
3. 统一响应模型：`{ code, message, data }`。
4. 401/403 等鉴权错误统一由拦截器处理。
5. 日志脱敏：不得打印 Cookie、Token、密码、学号。
6. 断网时直接返回本地缓存或友好错误，不发起无效请求。
7. 开发环境允许 Mock 数据源，通过 `NetConfig.isMock` 开关切换。
8. 所有 URL、域名、环境配置集中在 `NetConfig`。

---

## 8. 教务系统解析模块设计（核心扩展点）

### 8.1 目标

将"每个学校各不相同"的教务页面/接口，归一化为统一 `CourseImportDTO` 列表，核心业务只消费标准 DTO，**不感知学校差异**。

### 8.2 插件化适配器架构

```text
ImportService
   │
   ▼
SchoolAdapterRegistry（按 school.adapterKey 查找适配器）
   │
   ▼
SchoolAdapter（统一接口）
   ├── login(credential): Promise<Result<Session>>
   ├── fetchRaw(session, term): Promise<Result<RawData>>
   └── normalize(raw): Result<CourseImportDTO[]>
        ├── HtmlScheduleParser  → 处理 HTML 课表页
        └── ApiScheduleParser   → 处理 JSON 接口
```

### 8.3 统一接口约束

- 每个学校一个适配器类，实现 `SchoolAdapter` 接口，并在 `SchoolAdapterRegistry` 注册。
- 适配器**只做"取数 + 归一化"**，不写库、不弹 UI、不持有页面上下文。
- 未知学校自动降级为"手动导入模板"。

### 8.4 归一化输出 `CourseImportDTO`（必含字段）

| 字段 | 说明 |
|---|---|
| schoolId | 学校 ID |
| termName | 学期名 |
| courseName / teacher / location | 课程基础信息 |
| dayOfWeek | 1-7 |
| startSection / endSection | 节次区间 |
| startWeek / endWeek | 周次区间 |
| weekType | 单双周 |
| rawHash | 原始记录哈希（用于冲突检测/去重） |

### 8.5 解析性能与并发

1. HTML/JSON 解析必须放到 `TaskPool`（`@kit.ArkTS`）执行，禁止主线程解析大文件。
2. 解析函数使用 `@Concurrent` 标记，参数与返回值必须为可序列化类型。
3. 单次解析 ≤ 500 条课程，超量分批提交。
4. 解析过程提供进度回调（0-100）。

### 8.6 冲突处理规则

- 冲突键：`termId + dayOfWeek + startSection + startWeek/endWeek`。
- 无冲突：直接入库。
- 冲突：展示对比列表，支持"覆盖 / 跳过 / 保留两者"，用户确认后事务提交。
- `rawHash` 相同视为重复记录，自动去重。

### 8.7 新增学校流程（维护标准动作）

1. 新增适配器类于 `import/adapter/schools/`。
2. 在 `SchoolAdapterRegistry` 注册 `adapterKey`。
3. 在 `school` 表插入学校记录。
4. 编写解析单元测试样例。
5. 核心代码零改动。

---

## 9. 错误处理规范

### 9.1 统一结果类型

```text
Result<T> = Success(data) | Failure(AppError)

AppError = {
  code: ErrorCode,      // 稳定错误码
  message: string,      // 用户可读文案（中文）
  cause?: Error,        // 原始异常（仅日志，不外显）
  retriable: boolean    // 是否可重试
}
```

### 9.2 错误码分段（ErrorCodeConstants 维护）

| 段位 | 范围 | 含义 |
|---|---|---|
| 1xxxx | 通用 | 未知错误、参数非法、数据不存在 |
| 2xxxx | 数据层 | RDB 打开失败、写入失败、迁移失败、磁盘满 |
| 3xxxx | 网络层 | 超时、断网、DNS 失败、HTTP 5xx、业务码错误 |
| 4xxxx | 导入层 | 解析失败、格式不支持、会话过期、验证码错误 |
| 5xxxx | UI 层 | 路由非法、资源缺失、渲染数据越界 |

### 9.3 分层处理原则

| 层 | 处理方式 |
|---|---|
| Data Source 层 | 捕获系统异常 → 转为 `AppError` → 返回 `Result`，错误不出层 |
| Repository/Service | 透传 `Result`，可补充业务上下文，不弹 Toast |
| ViewModel | 根据 `Result` 与 `retriable` 决定 UI 状态 |
| UI 层 | 只做展示与重试触发，不解析异常 |

### 9.4 用户可感知错误规范

- 网络/系统错误：提示"网络异常，请稍后重试"，并提供重试入口。
- 业务错误：提示明确下一步动作。
- **禁止将英文异常信息直接展示给用户**。
- 所有用户可见文案放入 `string.json`。

### 9.5 全局兜底

- `ErrorHandler` 提供全局未捕获异常记录，并展示统一崩溃兜底页。
- UI 渲染数据越界、空值场景必须做防御性判断。

---

## 10. 文件命名规则

### 10.1 代码文件

| 类型 | 命名 | 示例 |
|---|---|---|
| 页面 | `XxxPage.ets` | `WeekSchedulePage.ets` |
| ViewModel | `XxxViewModel.ets` | `ImportViewModel.ets` |
| 业务组件 | `XxxComponent.ets` | `CourseCardComponent.ets` |
| 原子组件 | `BaseXxx.ets` | `BaseButton.ets` |
| Service | `XxxService.ets` | `ScheduleService.ets` |
| Repository | `XxxRepository.ets` | `TermRepository.ets` |
| 实体 | `XxxEntity.ets` | `CourseEntity.ets` |
| DTO | `XxxDTO.ets` | `CourseImportDTO.ets` |
| DAO | `XxxDao.ets` | `CourseDao.ets` |
| 适配器 | `XxxSchoolAdapter.ets` | `DefaultSchoolAdapter.ets` |
| 工具 | `XxxUtil.ets` | `DateUtil.ets` |
| 常量 | `XxxConstants.ets` | `ErrorCodeConstants.ets` |
| 接口定义 | `IXxx.ets` 或 `XxxInterface.ets` | `ISchoolAdapter.ets` |

### 10.2 资源文件

- 图标：`ic_功能_状态.png`。
- 颜色：语义化命名，如 `color_primary`、`color_text_secondary`。
- 字符串：`模块_含义`，如 `schedule_week_title`。
- 资源全部小写蛇形（snake_case）。

### 10.3 目录与分支

- 目录名：小写英文、语义化。
- Git 分支：`feature/模块-功能`、`fix/问题简述`、`release/x.y.z`。
- 提交信息：`type(scope): 描述`，type 限定 `feat/fix/docs/refactor/perf/test/chore`。

---

## 11. 组件拆分规则

### 11.1 组件分级

| 级别 | 目录 | 特征 | 示例 |
|---|---|---|---|
| 原子组件 | `base/` | 无业务语义、无数据请求 | `BaseButton` |
| 通用业务组件 | `components/common/` | 有业务含义但不绑定具体页面 | `EmptyStateComponent` |
| 模块业务组件 | `components/<module>/` | 仅服务某模块 | `WeekGridComponent` |
| 页面 | `pages/` | `@Entry`，负责组装与编排 | `WeekSchedulePage` |

### 11.2 拆分判断标准（满足任一即拆分）

1. 组件代码 > 300 行。
2. 组件承担 > 1 个独立职责。
3. 相同 UI 结构在 ≥ 2 处出现。
4. `build()` 中出现可读性差的多层嵌套或重复分支。
5. 需要被不同页面复用。

### 11.3 组件设计约束

- 组件对外只暴露：`@Param`（入参）、`@Event`（出参），内部状态用 `@Local`。
- **禁止组件内部直接调用 Service/Repository**，数据一律由父级注入。
- 组件不感知路由、不感知页面生命周期。
- 复用组件必须写职责注释与参数说明。

---

## 12. 后续维护规范

### 12.1 版本与数据库迁移

- 每次发布标记语义化版本号（`x.y.z`）。
- RDB `DB_VERSION` 只增不减，新增字段/表必须写迁移脚本。
- 旧数据迁移失败不得静默跳过。

### 12.2 学校扩展

- 严格按 8.7 流程执行，不得修改 `CourseImportDTO` 核心字段。
- 学校适配器必须附带至少 1 份脱敏 fixture 测试数据。

### 12.3 代码质量门禁

- 提交前：编译零 error、零 warning。
- 核心模块必须有单元测试（`ohosTest`）。
- 新增页面/组件必须过无障碍与深色模式检查。
- 周课表切换、导入 500 节课两条主路径必须跑基准测试。

### 12.4 依赖管理

- 第三方库统一通过 `ohpm` 引入，版本锁定。
- 新增依赖必须评审。

### 12.5 日志与可观测性

- 生产环境保留 WARN/ERROR 日志文件。
- 关键流程（导入、数据库迁移）必须埋点记录耗时与结果。

### 12.6 文档与接口契约维护

- 每次新增/修改 Service、Repository、Adapter 接口，必须同步更新文档注释。
- 领域模型字段变更必须同步更新第 6 章与迁移脚本。
- 本规范纳入版本管理。

---

## 附录 A：交付物清单（AI 程序员执行顺序）

| 阶段 | 交付物 | 对应章节 |
|---|---|---|
| 1 | 工程脚手架 + 目录结构 + 模块配置 | 第 2 章 |
| 2 | Common 层（Logger/Result/AppError/工具） | 第 4、9 章 |
| 3 | Data Source 层（RdbManager/DAO/Prefs/Migration） | 第 6 章 |
| 4 | Repository + Service 层 | 第 1、6 章 |
| 5 | 状态管理基础设施 + 原子组件 | 第 5、11 章 |
| 6 | 页面与 ViewModel（先课表主流程） | 第 3 章 |
| 7 | 网络层 + 教务适配器框架 + 解析任务 | 第 7、8 章 |
| 8 | 测试、性能基准、无障碍/深色检查 | 第 12 章 |

## 附录 B：关键禁止清单（红线速查）

1. UI/ViewModel 直接操作 RDB、Preferences、网络。
2. 使用 `any`、无类型对象字面量、`Function` 类型。
3. 主线程执行 HTML/JSON 大文件解析。
4. 业务代码字符串拼接 SQL。
5. `ResultSet` 不关闭、批量写入不用事务。
6. 错误信息英文直接抛给用户、敏感信息写入日志。
7. 页面 `build()` 中执行副作用。
8. 新增学校适配器时修改核心课表模型或 DTO 主字段。