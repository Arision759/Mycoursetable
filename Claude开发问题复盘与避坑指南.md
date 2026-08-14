# Claude 开发问题复盘与 HarmonyOS 编码避坑指南

> 文档版本：v1.1
> 生成时间：2026-08-13
> 最近更新：2026-08-13（补充实体类对象字面量初始化问题）
> 适用范围：本 HarmonyOS NEXT 课表 App（`entry` 模块）
> 关联文档：`HarmonyOS课程表App开发规范.md`、`TASK_PHASE_0.md`、`TASK_PHASE_1.md`、`TASK_PHASE_2.md`
> 读者：后续接手的 AI 程序员（尤其是 Claude）

本文档复盘了「Claude 最初生成的代码无法正常进入应用，经修复后目前已可正常进入并跳转」过程中的全部问题与修改，并总结出后续写 HarmonyOS 代码必须遵守的规则，目标是让 Claude 之后尽量少犯同类错误。

---

## 1. 问题背景

### 1.1 初始现象：启动后一直停在加载页

应用启动后显示「课程表 / 加载中...」，随后卡住，无法进入实际功能页。

**根因：**

`entry/src/main/resources/base/profile/main_pages.json` 原先只注册了首页：

```json
{
  "src": [
    "pages/Index"
  ]
}
```

但 `Index.ets` 的 `aboutToAppear` 会通过 `router.replaceUrl` 跳转到：

- `pages/ImportPage`（未导入课表时）
- `pages/WeekSchedulePage`（已导入课表时）

这两个页面都没有在 `main_pages.json` 中注册，导致路由跳转失败，界面一直停留在 `Index` 的「加载中...」。

### 1.2 注册页面后暴露的连锁问题

补注册页面后，原先未参与编译的 `ImportPage`、`WeekSchedulePage` 及其依赖文件开始参与 ArkTS 编译，暴露出大量 **ArkTS 严格语法不兼容** 的问题。

### 1.3 运行时新现象：进入后跳转到教务系统，但看不到画面

修复编译后，应用能正常进入并跳转到 `ImportPage`，但该页是 WebView 加载远程 HTTP 网页，出现了白屏/空白。

**根因：**

1. `module.json5` 未声明 `ohos.permission.INTERNET` 网络权限。
2. WebView 加载的是 `http://` 明文地址，未设置 `mixedMode(MixedMode.All)`。

---

## 2. 全部修改清单

下面按「文件 / 原问题 / 修复方式 / 当前正确写法」完整记录本次修复。

---

### 2.1 路由与页面注册

#### 文件：`entry/src/main/resources/base/profile/main_pages.json`

**问题：** 只注册了 `Index`，其余页面未注册。

**修复：** 补充所有页面。

```json
{
  "src": [
    "pages/Index",
    "pages/WeekSchedulePage",
    "pages/ImportPage"
  ]
}
```

**注意事项：**

- 每新增一个页面，必须同步加入 `main_pages.json`。
- 页面路径不要带 `.ets` 后缀，也不要带斜杠前缀。

---

### 2.2 ArkTS 语法兼容

#### 文件：`entry/src/main/ets/common/logger/Logger.ets`

**问题：** 原先使用了 TS 的对象展开写法，ArkTS 会报 `arkts-no-spread` / `arkts-no-untyped-obj-literals`。

**修复：** 改为逐字段赋值。

当前正确写法（配置对象）：

```typescript
interface LogConfig {
  domain: number;
  enableDebug: boolean;
}

private static config: LogConfig = {
  domain: 0x0001,
  enableDebug: true
};
```

配置更新时逐字段判断：

```typescript
public static configure(config: Partial<LogConfig>): void {
  if (config.domain !== undefined) {
    Logger.config.domain = config.domain;
  }
  if (config.enableDebug !== undefined) {
    Logger.config.enableDebug = config.enableDebug;
  }
}
```

#### 文件：`entry/src/main/ets/model/constants/ErrorCodeConstants.ets`

**问题：** 原先使用 `Record<ErrorCode, string>` + 计算属性名（`[ErrorCode.XXX]`）构造错误文案表。ArkTS 不支持计算属性名，也不推荐用 `Record` 承载枚举键。

**修复：** 改为 `Map<ErrorCode, string>`，并补充 `BUSINESS_ERROR` 错误码。

当前正确写法：

```typescript
export enum ErrorCode {
  UNKNOWN_ERROR = 10000,
  INVALID_PARAMETER = 10001,
  DATA_NOT_FOUND = 10002,
  OPERATION_CANCELLED = 10003,
  BUSINESS_ERROR = 10004,
  // ...
}

export const ERROR_MESSAGE_MAP = new Map<ErrorCode, string>([
  [ErrorCode.UNKNOWN_ERROR, '未知错误'],
  [ErrorCode.INVALID_PARAMETER, '参数无效'],
  [ErrorCode.DATA_NOT_FOUND, '数据不存在'],
  [ErrorCode.OPERATION_CANCELLED, '操作已取消'],
  [ErrorCode.BUSINESS_ERROR, '业务处理失败']
]);
```

#### 文件：`entry/src/main/ets/error/AppError.ets`

**问题：** 原先按 `ERROR_MESSAGE_MAP[code]` 读取，改为 `Map` 后需用 `.get()`。

**修复：** 使用 `Map.get()`，并新增 `businessError()` 静态工厂。

当前正确写法：

```typescript
constructor(code: ErrorCode, message?: string, cause?: Error, retriable: boolean = false) {
  this.code = code;
  this.message = message || ERROR_MESSAGE_MAP.get(code) || '未知错误';
  this.cause = cause;
  this.retriable = retriable;
}
```

---

### 2.3 模型 / 工具方法补全

#### 文件：`entry/src/main/ets/model/dto/CourseImportDTO.ets`

**问题：** 原先 DTO 缺少 `termId`、`courseCode`、`teachers`、`startTime`、`endTime`、`classroom` 等字段，导致 `CourseParser` 对象字面量赋值缺字段、字段名不一致。

**修复：** 补齐与解析/入库链路一致的字段。

当前关键字段：

```typescript
export class CourseImportDTO {
  public schoolId: string = '';
  public termName: string = '';
  public courseName: string = '';
  public teacher: string = '';
  public location: string = '';
  public dayOfWeek: number = 1;
  public startSection: number = 1;
  public endSection: number = 1;
  public startWeek: number = 1;
  public endWeek: number = 1;
  public weekType: number = 0;
  public rawHash: string = '';
  public remark: string = '';

  public termId: string = '';
  public courseCode: string = '';
  public teachers: string = '';
  public startTime: string = '';
  public endTime: string = '';
  public classroom: string = '';
}
```

#### 文件：`entry/src/main/ets/common/util/IdGenerator.ets`

**问题：** 调用方使用了 `IdGenerator.generateId(prefix)`，但原先工具类未提供该方法。

**修复：** 补充 `generateId(prefix)`，并保留原 `generateWithPrefix(prefix)` 能力。

```typescript
public static generate(): string {
  const timestamp = Date.now();
  const random = Math.floor(Math.random() * 10000);
  const count = ++IdGenerator.counter;
  return `${timestamp}${random}${count}`;
}

public static generateWithPrefix(prefix: string): string {
  return `${prefix}_${IdGenerator.generate()}`;
}

public static generateId(prefix: string): string {
  return IdGenerator.generateWithPrefix(prefix);
}
```

#### 文件：`entry/src/main/ets/common/util/DateUtil.ets`

**问题：** 调用方使用了 `DateUtil.calculateWeek(...)` 和 `DateUtil.addDays(...)`，但原先工具类未提供。

**修复：** 补充周次计算与日期偏移方法。

```typescript
public static getCurrentWeek(startDate: number, currentDate: number = Date.now()): number {
  const daysDiff = Math.floor((currentDate - startDate) / (24 * 60 * 60 * 1000));
  return Math.floor(daysDiff / 7) + 1;
}

public static calculateWeek(startDate: number, currentDate: number = Date.now()): number {
  return DateUtil.getCurrentWeek(startDate, currentDate);
}

public static addDays(date: number, days: number): number {
  return date + days * 24 * 60 * 60 * 1000;
}
```

---

### 2.4 数据层类型修复

#### 文件：`CourseEntity.ets` / `TermEntity.ets` / `SchoolEntity.ets`

**问题：** 原先 `fromRow(row)` / `toRow()` 使用 `Record<string, Object>` 或裸 `Object` 作为数据库行类型，与 `@ohos.data.relationalStore` 的实际参数类型不匹配，且 ArkTS 不建议使用 `Object`。

**修复：** 全部改为 `relationalStore.ValuesBucket`，并显式 `as` 类型转换。

当前正确写法（以 `TermEntity` 为例）：

```typescript
import { relationalStore } from '@kit.ArkData';

export class TermEntity {
  public id: string = '';
  public name: string = '';
  public startDate: number = 0;
  public weekCount: number = 0;
  public isCurrent: number = 0;
  public createdAt: number = 0;
  public updatedAt: number = 0;

  public static fromRow(row: relationalStore.ValuesBucket): TermEntity {
    const entity = new TermEntity();
    entity.id = row['id'] as string;
    entity.name = row['name'] as string;
    entity.startDate = row['startDate'] as number;
    entity.weekCount = row['weekCount'] as number;
    entity.isCurrent = row['isCurrent'] as number;
    entity.createdAt = row['createdAt'] as number;
    entity.updatedAt = row['updatedAt'] as number;
    return entity;
  }

  public toRow(): relationalStore.ValuesBucket {
    const row: relationalStore.ValuesBucket = {};
    row['id'] = this.id;
    row['name'] = this.name;
    row['startDate'] = this.startDate;
    row['weekCount'] = this.weekCount;
    row['isCurrent'] = this.isCurrent;
    row['createdAt'] = this.createdAt;
    row['updatedAt'] = this.updatedAt;
    return row;
  }
}
```

#### 文件：`CourseDao.ets` / `TermDao.ets` / `SchoolDao.ets`

**问题：**

1. 原先使用 `Record<string, Object>` 作为 `valuesBucket` 参数类型。
2. 原先 `catch (err)` 后直接 `throw err`，ArkTS 中 `err` 是 `unknown`/`Error` 类型不明确，会报错。

**修复：**

1. 所有 `valuesBucket` 参数改为 `relationalStore.ValuesBucket`。
2. 异常统一 `throw err as Error`。

当前正确写法：

```typescript
import { relationalStore } from '@kit.ArkData';

public async insert(entity: CourseEntity): Promise<Result<void>> {
  try {
    const valuesBucket: relationalStore.ValuesBucket = entity.toRow();
    // ...
  } catch (err) {
    throw err as Error;
  }
}
```

---

### 2.5 解析器 ArkTS 修复

#### 文件：`entry/src/main/ets/utils/TimeTableParser.ets`

**问题：**

1. 原先可能使用了对象字面量作为 `Map` 值，ArkTS 要求显式接口。
2. 静态方法里错误使用了 `this`（静态上下文不可用 `this`）。
3. 静态初始化可能涉及未定义顺序问题。

**修复：**

1. 显式定义 `TimeRange` 接口。
2. 使用 `new Map<number, TimeRange>()` 并通过 `map.set(...)` 初始化。
3. 静态方法内使用 `TimeTableParser.xxx()`，不使用 `this`。

当前正确写法：

```typescript
export interface TimeRange {
  start: string;
  end: string;
}

export class TimeTableParser {
  private static readonly TIME_TABLE: Map<number, TimeRange> = TimeTableParser.initTimeTable();

  private static initTimeTable(): Map<number, TimeRange> {
    const map = new Map<number, TimeRange>();
    map.set(1, TimeTableParser.time('08:30', '09:15'));
    map.set(2, TimeTableParser.time('09:20', '10:05'));
    // ...
    return map;
  }

  private static time(start: string, end: string): TimeRange {
    return { start, end };
  }
}
```

#### 文件：`entry/src/main/ets/utils/CourseParser.ets`

**问题：**

1. 静态方法中错误使用 `this`。
2. 使用数组解构赋值，部分 ArkTS 场景不支持。
3. 使用对象字面量初始化 `CourseImportDTO`，但 ArkTS 要求对象字面量必须对应完整显式类型，且类对象字面量不能只写部分字段。

**修复：**

1. 静态方法内使用 `CourseParser.xxx()`。
2. 避免解构，改为逐字段读取。
3. 用 `new CourseImportDTO()` 后逐字段赋值，而不是对象字面量。

当前正确写法：

```typescript
const dto = new CourseImportDTO();
dto.termId = termId;
dto.courseCode = courseCode;
dto.courseName = courseName;
dto.teachers = teachers;
dto.dayOfWeek = dayOfWeek;
dto.startSection = startSection;
dto.endSection = endSection;
dto.startTime = timeRange.start;
dto.endTime = timeRange.end;
dto.startWeek = startWeek;
dto.endWeek = endWeek;
dto.classroom = classroom;

courses.push(dto);
```

---

### 2.6 UI 组件修复

#### 文件：`entry/src/main/ets/viewmodel/CourseCardItem.ets`

**问题：** 原先错误地 `import { ResourceColor }`。`ResourceColor` 是 ArkUI 全局类型，不需要也不应该显式导入。

**修复：** 删除该 import，直接使用全局 `ResourceColor`。

```typescript
export interface CourseCardItem {
  id: string;
  name: string;
  teacher: string;
  room: string;
  dayOfWeek: number;
  startSection: number;
  endSection: number;
  color: ResourceColor; // 全局类型，不需要 import
  isCurrentWeek: boolean;
}
```

#### 文件：`entry/src/main/ets/components/CourseDetailDialog.ets`

**问题：** 原先把 `@CustomDialog` 的 `detail` 字段写成 `@Param`。`@CustomDialog` 不是 `@ComponentV2`，其内部状态应使用 `@State`。

**修复：** 改为 `@State`。

```typescript
@CustomDialog
export struct CourseDetailDialog {
  controller: CustomDialogController;
  @State detail: CourseDetailItem = {
    courseName: '',
    courseCode: '',
    teachers: '',
    dayOfWeek: '',
    sectionRange: '',
    timeRange: '',
    classrooms: []
  };
}
```

#### 文件：`entry/src/main/ets/components/CourseCard.ets`

**说明：** 这是 `@ComponentV2` 组件，应使用 `@Param` 和 `@Event`，而不是 V1 的 `@Prop`/`@Link`。

```typescript
@ComponentV2
export struct CourseCard {
  @Param course: CourseCardItem = {
    id: '',
    name: '',
    teacher: '',
    room: '',
    dayOfWeek: 1,
    startSection: 1,
    endSection: 1,
    color: Color.Blue,
    isCurrentWeek: true
  };
  @Event onCardClick: (id: string) => void = () => {};
}
```

#### 文件：`entry/src/main/ets/pages/WeekSchedulePage.ets`

**问题：**

1. 原先 `Grid()` 创建后通过 `.layoutOptions(this.layoutOptions)` 设置 `GridLayoutOptions`，但正确 API 是 `Grid` 构造函数第二个参数直接传 `layoutOptions`。
2. `onGetRectByIndex` 返回类型原先为 `number[]`，但 Grid 布局要求返回固定四元组 `[number, number, number, number]`。

**修复：**

```typescript
private layoutOptions: GridLayoutOptions = {
  regularSize: [1, 1],
  onGetRectByIndex: (index: number): [number, number, number, number] => {
    const course = this.courses[index];
    return [
      course.startSection - 1,
      course.dayOfWeek - 1,
      course.endSection - course.startSection + 1,
      1
    ];
  }
};
```

Grid 创建：

```typescript
Grid(undefined, this.layoutOptions) {
  ForEach(this.courses, (course: CourseCardItem) => {
    GridItem() {
      CourseCard({
        course: course,
        onCardClick: (id: string): void => this.handleCourseClick(id)
      })
    }
  }, (course: CourseCardItem) => course.id)
}
.columnsTemplate(this.getColumnsTemplate())
.rowsTemplate(this.getRowsTemplate())
.columnsGap(this.GAP)
.rowsGap(this.GAP)
.width('100%')
.height(this.gridHeight())
.layoutWeight(1)
```

#### 文件：`entry/src/main/ets/pages/ImportPage.ets`

**问题：**

1. `onInterceptRequest` 回调参数原先写成 `WebResourceRequest`，实际类型是 `OnInterceptRequestEvent`。
2. 原先通过 `event.getRequestUrl()` 取 URL，实际应通过 `event.request.getRequestUrl()`。
3. 加载 HTTP 明文页面缺少 `mixedMode`。

**修复：**

```typescript
.onInterceptRequest((event) => {
  if (event) {
    return this.handleInterceptRequest(event);
  }
  return null;
})
```

```typescript
private handleInterceptRequest(event: OnInterceptRequestEvent): WebResourceResponse | null {
  try {
    const url = event.request.getRequestUrl();
    // ...
  } catch (err) {
    Logger.error('ImportPage', 'handleInterceptRequest', JSON.stringify(err));
    return null;
  }
}
```

Web 组件属性：

```typescript
.javaScriptAccess(true)
.domStorageAccess(true)
.mixedMode(MixedMode.All)
```

---

### 2.7 权限与网络

#### 文件：`entry/src/main/module.json5`

**问题：** WebView 加载远程网页，但未声明网络权限。

**修复：** 在 `module` 下新增 `requestPermissions`。

```json5
{
  "module": {
    "name": "entry",
    "type": "entry",
    "pages": "$profile:main_pages",
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ],
    "abilities": [
      // ...
    ]
  }
}
```

---

### 2.8 编译验证结果

经过上述修复后，最终编译结果：

```text
isSuccess: true
compilationErrors: ""
```

应用已可正常进入，并跳转到课表导入页。

---

### 2.9 补充：实体类用对象字面量初始化导致的连锁编译错误（15 个报错）

**触发时间：** 2026-08-13
**涉及文件：** `EntryAbility.ets`、`WeekSchedulePage.ets`
**编译报错类型：**

- `10605038 arkts-no-untyped-obj-literals`（对象字面量必须对应显式声明的类/接口）
- `10605043 arkts-no-noninferrable-arr-literals`（数组字面量必须只包含可推断类型的元素）
- `10505001`（属性缺失/未知属性）

#### 问题一：`TermEntity` 用对象字面量初始化

`EntryAbility.ets` 的 `createTestTerm()` 原写法：

```typescript
const term: TermEntity = {
  id: '',
  name: '2026-2027学年第1学期',
  startDate: new Date('2026-09-01').getTime(),
  weekCount: 20,
  isCurrent: 1,
  createdAt: Date.now(),
  updatedAt: Date.now()
};
```

**根因：**

`TermEntity` 内部有 `fromRow()`、`toRow()` 等方法，ArkTS **禁止用对象字面量初始化带方法的类**，因此同时触发：

- `arkts-no-untyped-obj-literals`
- 「`toRow` 属性缺失」的 `10505001`

**修复：** 改为 `new TermEntity()` 后逐字段赋值。

```typescript
const term = new TermEntity();
term.name = '2026-2027学年第1学期';
term.startDate = new Date('2026-09-01').getTime();
term.weekCount = 20;
term.isCurrent = 1;
term.createdAt = Date.now();
term.updatedAt = Date.now();
```

#### 问题二：`CourseEntity[]` 用对象字面量数组初始化

`WeekSchedulePage.ets` 的 `insertTestData()` 原写法：

```typescript
const testCourses: CourseEntity[] = [
  {
    id: '',
    termId: termId,
    courseCode: 'MATH001',
    courseName: '高等数学Ⅱ',
    teachers: '韩少锋',
    // ...
  },
  // ...
];
```

**根因：**

1. 数组元素是对象字面量，无法被可靠推断为 `CourseEntity`，触发 `arkts-no-noninferrable-arr-literals`。
2. `CourseEntity` 是带方法的类，不能用对象字面量初始化，触发 `arkts-no-untyped-obj-literals`。
3. **字段名与 `CourseEntity` 定义不一致**：代码里使用了 `courseCode`、`courseName`、`teachers`、`classroom`、`building`，但这些都不是 `CourseEntity` 的字段，触发大量 `10505001`。

**修复：** 改为「空数组 + `new CourseEntity()` 后 push」，并将字段映射到实体真实字段。

字段映射关系：

| 原字面量字段 | 实体真实字段 | 处理方式 |
|---|---|---|
| `courseName` | `name` | 直接映射 |
| `teachers` | `teacher` | 直接映射 |
| `classroom` + `building` | `location` | 合并为「楼栋 教室」 |
| `courseCode` | 无 | 移除（`CourseEntity` 不存储课程代码，且 `color` 已单独指定） |
| `id` | `id` | 可省略（有默认值 `''`） |

修复后核心写法：

```typescript
const testCourses: CourseEntity[] = [];

const course1 = new CourseEntity();
course1.termId = termId;
course1.name = '高等数学Ⅱ';
course1.teacher = '韩少锋';
course1.dayOfWeek = 1;
course1.startSection = 3;
course1.endSection = 4;
course1.startTime = '10:25';
course1.endTime = '12:00';
course1.startWeek = 1;
course1.endWeek = 16;
course1.location = '明远楼 WH1102';
course1.color = '#FF6B9D';
course1.weekType = 0;
course1.sourceType = 0;
course1.createdAt = Date.now();
course1.updatedAt = Date.now();
testCourses.push(course1);
```

其余 5 门课程同理逐个 `new CourseEntity()` 后 push。

**编译验证结果：**

```text
isSuccess: true
compilationErrors: ""
```

---

## 3. 后续 Claude 写代码的注意事项

以下规则来自本次实际踩坑，后续务必遵守。

---

### 3.1 工程配置类

#### ✅ 新增页面必须注册

- 新增任何页面 `.ets` 文件后，立即在 `entry/src/main/resources/base/profile/main_pages.json` 的 `src` 数组中注册。
- 注册路径格式：`pages/PageName`，不带 `.ets`。

#### ✅ 使用系统能力必须声明权限

- 网络请求 / WebView 加载远程资源：`ohos.permission.INTERNET`。
- 摄像头、定位、存储、通讯录等按需在 `module.json5` 的 `requestPermissions` 中声明。
- 权限变更后通常需要**重新安装应用**才生效。

#### ✅ 模块结构变更同步到配置

- 新增/删除模块时同步 `build-profile.json5`。
- 页面/Ability/Skill 变更同步 `module.json5`。

---

### 3.2 ArkTS 语言红线

这是本次编译错误最多的区域，务必优先检查。

#### 🚫 禁止无类型对象字面量

ArkTS 要求对象字面量必须对应显式声明的接口或类。

❌ 错误：

```typescript
const data = { name: 'abc', count: 1 };
```

✅ 正确：

```typescript
interface Data {
  name: string;
  count: number;
}
const data: Data = { name: 'abc', count: 1 };
```

#### 🚫 禁止使用 `any` / `unknown`

所有变量、参数、返回值必须显式声明类型。

❌ 错误：

```typescript
function parse(data: any) { return data; }
```

✅ 正确：

```typescript
function parse(data: string): CourseImportDTO[] { ... }
```

#### 🚫 禁止对象展开（spread）

❌ 错误：

```typescript
const newObj = { ...oldObj, extra: 1 };
```

✅ 正确：

```typescript
const newObj = new SomeClass();
newObj.field1 = oldObj.field1;
newObj.extra = 1;
```

#### 🚫 禁止计算属性名 + `Record` 承载枚举键

❌ 错误：

```typescript
const map: Record<ErrorCode, string> = {
  [ErrorCode.UNKNOWN]: '未知错误'
};
```

✅ 正确：

```typescript
const map = new Map<ErrorCode, string>([
  [ErrorCode.UNKNOWN, '未知错误']
]);
```

#### 🚫 类对象字面量不能只写部分字段

给类实例赋值时，不要用对象字面量，尤其是只写一部分字段。

❌ 错误：

```typescript
const dto: CourseImportDTO = {
  termId: termId,
  courseName: name
};
```

✅ 正确：

```typescript
const dto = new CourseImportDTO();
dto.termId = termId;
dto.courseName = name;
```

#### 🚫 带方法的类禁止用对象字面量初始化（尤其数组元素）

ArkTS 中，只要类内部有方法（如 `fromRow()`、`toRow()`），就**不能**用对象字面量初始化。实体类、DAO、Service 等业务类都适用。数组元素同样如此，否则还会触发 `arkts-no-noninferrable-arr-literals`。

❌ 错误：

```typescript
const term: TermEntity = {
  id: '',
  name: '2026-2027学年第1学期',
  // ...
};

const courses: CourseEntity[] = [
  {
    id: '',
    name: '高等数学',
    // ...
  }
];
```

✅ 正确：

```typescript
const term = new TermEntity();
term.name = '2026-2027学年第1学期';

const courses: CourseEntity[] = [];
const course = new CourseEntity();
course.name = '高等数学';
courses.push(course);
```

#### 🚫 对象字面量字段必须与目标类/接口字段完全一致

写测试数据、DTO 转换、实体构造前，先核对真实字段名。不要凭直觉使用 `courseName`、`teachers`、`classroom`、`building` 等字段——本项目中 `CourseEntity` 只有 `name`、`teacher`、`location`。

❌ 错误（字段名对不上）：

```typescript
const course = new CourseEntity();
course.courseName = '高等数学';   // CourseEntity 无此字段
course.teachers = '韩少锋';       // 应为 teacher
course.classroom = 'WH1102';      // 应并入 location
```

✅ 正确：

```typescript
const course = new CourseEntity();
course.name = '高等数学';
course.teacher = '韩少锋';
course.location = '明远楼 WH1102';
```

#### 🚫 静态方法内不要使用 `this`

❌ 错误：

```typescript
private static foo() {
  return this.bar();
}
```

✅ 正确：

```typescript
private static foo() {
  return ClassName.bar();
}
```

#### 🚫 避免数组解构赋值

ArkTS 对解构支持有限，解析数组时尽量用索引读取。

❌ 可能报错：

```typescript
const [a, b] = arr;
```

✅ 正确：

```typescript
const a = arr[0];
const b = arr[1];
```

#### 🚫 数组和元组不要混用

需要固定长度、固定类型顺序时，使用元组，而不是 `number[]`。

✅ 正确：

```typescript
(index: number): [number, number, number, number] => {
  return [0, 0, 1, 1];
}
```

#### 🚫 `catch` 中再抛出要显式转类型

❌ 错误：

```typescript
} catch (err) {
  throw err;
}
```

✅ 正确：

```typescript
} catch (err) {
  throw err as Error;
}
```

---

### 3.3 状态管理（V1 与 V2）

#### ✅ 分清 V1 和 V2 装饰器

| 场景 | V1 | V2 |
|---|---|---|
| 页面入口 | `@Entry` + `@Component` | `@Entry` + `@ComponentV2` |
| 父传子 | `@Prop` | `@Param` |
| 子回调父 | `@Link` 或回调 | `@Event` |
| 组件内状态 | `@State` | `@Local` |
| 深层状态 | `@Provide/@Consume` | `@Provider/@Consumer` 或 `@ObservedV2` |

本次项目里：

- `Index`、`ImportPage`、`WeekSchedulePage` 是 `@Entry` 页面。
- `CourseCard` 是 `@ComponentV2`，使用 `@Param` / `@Event`。
- `CourseDetailDialog` 是 `@CustomDialog`，使用 `@State`，不要用 `@Param`。

#### ✅ 全局 ArkUI 类型不要显式 import

`ResourceColor`、`Color`、`FontWeight`、`TextOverflow`、`MixedMode` 等属于 ArkUI 全局类型/枚举，不需要也不应该 `import`。

❌ 错误：

```typescript
import { ResourceColor } from '@ohos.arkui.node';
```

✅ 正确：

```typescript
// 直接使用
color: ResourceColor
```

---

### 3.4 RDB / DAO 数据层

#### ✅ 数据库行类型统一用 `relationalStore.ValuesBucket`

❌ 错误：

```typescript
public static fromRow(row: Record<string, Object>): TermEntity { ... }
```

✅ 正确：

```typescript
public static fromRow(row: relationalStore.ValuesBucket): TermEntity { ... }
```

#### ✅ 实体转换必须显式赋值

`fromRow` 和 `toRow` 都要逐字段处理，并用 `as` 明确类型。

```typescript
entity.id = row['id'] as string;
row['id'] = this.id;
```

#### ✅ DAO 的错误统一 `throw err as Error`

---

### 3.5 WebView 注意事项

#### ✅ 加载远程网页前先检查权限

- 必须声明 `ohos.permission.INTERNET`。
- 网络权限变更后重新安装。

#### ✅ HTTP 明文页面设置 mixedMode

开发/工具场景可设置：

```typescript
.mixedMode(MixedMode.All)
```

但正式生产项目需评估安全风险，优先使用 HTTPS。

#### ✅ `onInterceptRequest` 的正确类型

- 回调参数类型是 `OnInterceptRequestEvent`，**不是** `WebResourceRequest`。
- 获取 URL 用：

```typescript
event.request.getRequestUrl()
```

#### ✅ `src` 不能通过 `@State` 动态改

Web 组件的 `src` 不能在声明后通过状态变量动态变更，需要切换地址时调用 `controller.loadUrl(url)`。

---

### 3.6 Grid 布局注意事项

#### ✅ `GridLayoutOptions` 通过构造函数第二个参数传入

❌ 错误：

```typescript
Grid()
  .layoutOptions(this.layoutOptions)
```

✅ 正确：

```typescript
Grid(undefined, this.layoutOptions) {
  // GridItem
}
```

#### ✅ `onGetRectByIndex` 返回固定四元组

返回类型必须是：

```typescript
[number, number, number, number]
```

含义通常为 `[rowStart, colStart, rowSpan, colSpan]`（本项目按行列计算）。

---

### 3.7 交付前自检清单

每次写完后，按下面清单逐项自检，再交付给用户：

1. **页面注册**：新增页面是否已写入 `main_pages.json`。
2. **权限声明**：WebView / 网络 / 存储 / 定位等是否已在 `module.json5` 声明。
3. **ArkTS 红线**：
   - 无 `any` / `unknown`
   - 无对象展开
   - 无计算属性名 + `Record`
   - 类对象不用部分字段字面量
   - 带方法的类（Entity/DAO/Service）用 `new` + 逐字段赋值，数组元素同理
   - 对象字面量/赋值字段名必须与目标类或接口完全一致
   - 静态方法不用 `this`
   - 无数组解构
   - 元组类型正确
   - `throw err as Error`
4. **状态管理**：V1/V2 装饰器使用正确；`@CustomDialog` 用 `@State`；全局 ArkUI 类型不 import。
5. **数据层**：RDB 行类型用 `relationalStore.ValuesBucket`。
6. **WebView**：权限、`mixedMode`、`OnInterceptRequestEvent`、`event.request.getRequestUrl()`。
7. **Grid**：`layoutOptions` 用构造函数第二参数，`onGetRectByIndex` 返回元组。
8. **编译验证**：执行编译，确保 `isSuccess: true`、`compilationErrors` 为空。
9. **运行时验证**：进入应用、页面跳转、关键功能是否正常；如有白屏，优先查权限和网络。

---

## 4. 总结

本次问题的本质是：

1. **工程配置遗漏**：页面未注册、权限未声明。
2. **ArkTS 严格语法不熟悉**：把 TypeScript 习惯直接搬到 HarmonyOS，导致大量编译错误。
3. **API 类型/参数使用错误**：WebView 回调、Grid 布局等 API 细节未按官方签名实现。

后续 Claude 写代码时，最核心的一条原则是：

> **先确认 HarmonyOS 官方 API 签名和 ArkTS 语法约束，再写代码；写完后必须编译验证，并检查页面注册和权限声明。**

以上规则如能严格遵守，可显著减少同类问题。
