# 📋 任务：将课表导入改为原生 HTTP 方案

**方案：** 方案 B - 原生 HTTP 全自动登录  
**目标：** 用户只输入账号密码，应用自动完成登录、获取课表、解析、导入  
**参考：** `parse_course_with_cookie.py`（已验证可行）

---

## ⚠️ 开始前必读

1. 阅读 `Claude开发问题复盘与避坑指南.md` 中的 ArkTS 规范
2. 阅读本文件的"ArkTS 注意事项"章节

---

## 📊 新的导入流程

```
用户打开导入页面
    ↓
显示登录界面（账号 + 密码输入框）
    ↓
用户点击"登录并导入"
    ↓
自动：CAS 登录 → 获取 ids → POST 课表接口 → 解析 TaskActivity → 导入数据库
    ↓
成功：跳转到周课表页面
失败：显示错误提示
```

---

## 🔧 需要创建/修改的文件

### 新建文件

| 文件 | 功能 |
|------|------|
| `service/EamsLoginService.ets` | CAS 登录 + 获取课表 HTML |
| `pages/LoginImportPage.ets` | 登录导入页面 UI |

### 修改文件

| 文件 | 修改内容 |
|------|---------|
| `utils/CourseParserFromJS.ets` | 修正正则表达式 |
| `pages/Index.ets` | 跳转目标改为 LoginImportPage |
| `main_pages.json` | 注册新页面 |

---

## 📝 文件 1：EamsLoginService.ets

**位置：** `entry/src/main/ets/service/EamsLoginService.ets`

**功能：** 
1. CAS 统一认证登录（密码 AES 加密）
2. 获取学生 ids
3. 获取 semester.id
4. POST 请求课表数据

**完整实现逻辑（对照 Python 脚本）：**

```
步骤 1：访问 CAS 登录页
- GET https://ids.chd.edu.cn/authserver/login?service=http://bkjw.chd.edu.cn/eams/login.action
- 从 HTML 中提取：execution, _eventId, pwdEncryptSalt
- 用 AES 加密密码

步骤 2：POST 登录
- POST 到同一个 CAS URL
- 参数：username, password(加密后), lt, execution, _eventId, cllt, dllt, rmShown
- 跟随重定向回教务系统，获取 JSESSIONID

步骤 3：获取 ids
- GET http://bkjw.chd.edu.cn/eams/courseTableForStd.action
- 从响应 HTML 中正则提取：bg.form.addInput(form,"ids","206271")

步骤 4：获取 semester.id
- 从 Cookie 中获取 semester.id
- 如果没有，使用默认值

步骤 5：POST 课表数据
- POST http://bkjw.chd.edu.cn/eams/courseTableForStd!courseTable.action
- 参数：ignoreHead=1, setting.kind=std, startWeek=, semester.id=xxx, ids=xxx
- Headers：X-Requested-With=XMLHttpRequest, Content-Type=application/x-www-form-urlencoded
- 返回包含 TaskActivity 的 HTML
```

**AES 加密逻辑：**
```
密钥 = pwdEncryptSalt（16字节字符串）
IV = 密钥本身
模式 = AES-CBC
填充 = PKCS7
明文 = 64位随机字符串 + 密码
结果 = Base64(加密后的字节)
```

**关键正则：**
```typescript
// 提取 execution
/name="execution"\s+value="([^"]*)"/

// 提取 pwdEncryptSalt
/id="pwdEncryptSalt"\s+value="([^"]*)"/

// 提取 ids
/bg\.form\.addInput\(form,\s*"ids"\s*,\s*"(\d+)"\s*\)/

// 提取 semester.id（从 Cookie）
cookie.name === 'semester.id'
```

**HTTP 请求注意事项：**
- 使用 `@ohos.net.http` 模块
- 需要手动管理 Cookie（HarmonyOS 的 http 模块不自动处理 Cookie）
- 需要跟随重定向（302）
- 需要 SSL 支持（CAS 是 https）

---

## 📝 文件 2：LoginImportPage.ets

**位置：** `entry/src/main/ets/pages/LoginImportPage.ets`

**UI 设计：**

```
┌─────────────────────────┐
│                         │
│      📚 课程表          │
│                         │
│  ┌───────────────────┐  │
│  │ 学号              │  │  ← TextInput
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │ 密码              │  │  ← TextInput (password)
│  └───────────────────┘  │
│                         │
│  ┌───────────────────┐  │
│  │   登录并导入课表   │  │  ← Button
│  └───────────────────┘  │
│                         │
│  正在登录...            │  ← 状态提示
│  ████████░░ 60%        │  ← 进度条（可选）
│                         │
└─────────────────────────┘
```

**状态管理：**
```typescript
@State username: string = ''
@State password: string = ''
@State isLoading: boolean = false
@State statusText: string = ''
@State errorText: string = ''
```

**按钮点击逻辑：**
```typescript
async onImportClick() {
  this.isLoading = true
  this.errorText = ''
  
  this.statusText = '正在登录...'
  // 调用 EamsLoginService.login()
  
  this.statusText = '正在获取课表...'
  // 调用 EamsLoginService.getCourseTable()
  
  this.statusText = '正在解析课程...'
  // 调用 CourseParserFromJS.parse()
  
  this.statusText = '正在导入...'
  // 调用 ScheduleService.importCourses()
  
  this.statusText = '导入成功！'
  // 跳转到 WeekSchedulePage
}
```

---

## 📝 文件 3：修正 CourseParserFromJS.ets

**位置：** `entry/src/main/ets/utils/CourseParserFromJS.ets`

**需要修正的核心正则（关键！）：**

旧正则（错误，无法匹配）：
```typescript
// ❌ [^,]+ 会被 join(',') 中的逗号截断
/var\s+courseName\s*=\s*"([^"]+)";\s*activity\s*=\s*new\s+TaskActivity\(([^)]+)\);\s*index\s*=\s*([^;]+);/g
```

新正则（正确）：
```typescript
// ✅ 精确匹配 actTeacherId.join(','),actTeacherName.join(',')
const TA_PATTERN = /new\s+TaskActivity\(actTeacherId\.join\('[^']*'\)\s*,\s*actTeacherName\.join\('[^']*'\)\s*,"([^"]*)",courseName,"([^"]*)","\d*","([^"]*)","([^"]*)"/g
```

**匹配组：**
- group(1): 课程 ID（如 "53677(27XK1103.03)"）
- group(2): 课程代码（如 "27XK1103.03"）
- group(3): 教室（如 "*WM1315☆"）
- group(4): 有效周（如 "01110100101000..."）

**解析策略（按 `var teachers` 分块）：**

```typescript
// 1. 提取 unitCount
const unitMatch = html.match(/var\s+unitCount\s*=\s*(\d+)/)

// 2. 按 "var teachers" 分块
const blocks = html.split(/(?=var\s+teachers\s*=\s*\[)/)

// 3. 对每个块提取：
//    - 教师：name:"xxx"
//    - 课程名：var courseName = "xxx"
//    - TaskActivity 参数
//    - index = day*unitCount+section
```

**index 计算：**
```typescript
// index = 4*unitCount+6 表示：星期五(4+1=5)，第7节(6+1=7)
const dayOfWeek = parseInt(dayStr) + 1    // 0-based → 1-based
const section = parseInt(sectionStr) + 1  // 0-based → 1-based
```

---

## 📝 文件 4：修改 Index.ets

将跳转目标改为新的登录导入页面：

```typescript
router.replaceUrl({
  url: 'pages/LoginImportPage'  // ✅ 改为新页面
})
```

---

## 📝 文件 5：注册页面

**文件：** `entry/src/main/resources/base/profile/main_pages.json`

添加：
```json
{
  "src": [
    "pages/Index",
    "pages/WeekSchedulePage",
    "pages/ImportPage",
    "pages/LoginImportPage"
  ]
}
```

---

## ⚠️ ArkTS 注意事项（关键！）

### 1. HTTP 请求

HarmonyOS 使用 `@ohos.net.http` 模块：

```typescript
import http from '@ohos.net.http'

const request = http.createHttp()
const response = await request.request(url, {
  method: http.RequestMethod.POST,
  header: { 'Content-Type': 'application/x-www-form-urlencoded' },
  extraData: 'key1=value1&key2=value2'
})
// 注意：每次请求后需要 request.destroy()
```

### 2. Cookie 管理

**HarmonyOS 的 http 模块不自动管理 Cookie！需要手动：**

```typescript
// 从响应头提取 Set-Cookie
const setCookieHeader = response.header['set-cookie']

// 在下一次请求中手动带上
request.request(url, {
  header: {
    'Cookie': 'JSESSIONID=xxx; semester.id=262'
  }
})
```

### 3. AES 加密

HarmonyOS 使用 `@ohos.security.cryptoFramework`：

```typescript
import cryptoFramework from '@ohos.security.cryptoFramework'

// 创建 AES-CBC 加密器
const cipher = cryptoFramework.createCipher('AES128|CBC|PKCS7')
// ... 具体 API 需要查阅文档
```

### 4. 重定向处理

`@ohos.net.http` 默认不自动跟随重定向，需要手动检查 302 并重新请求。

### 5. ArkTS 语法红线（避坑指南中的规则）

- ❌ 禁止对象展开 `{ ...obj }`
- ❌ 禁止 `any` 类型
- ❌ 禁止数组解构 `const [a, b] = arr`
- ❌ 静态方法不用 `this`
- ✅ 用 `new ClassName()` + 逐字段赋值
- ✅ 用 `relationalStore.ValuesBucket` 类型
- ✅ `catch (err) { throw err as Error }`

---

## 🎯 验收标准

1. ✅ 输入正确的学号密码后，能自动登录
2. ✅ 自动获取 ids 和 semester.id
3. ✅ 自动获取课表 HTML 并解析出课程
4. ✅ 解析出的课程数量 ≥ 20（对照 Python 脚本结果）
5. ✅ 导入数据库成功
6. ✅ 跳转到周课表页面，能看到课程
7. ✅ 输入错误密码时，显示友好的错误提示
8. ✅ 编译通过，无 ArkTS 语法错误

---

## 📝 完成后汇报

```
✅ 原生 HTTP 导入方案完成

创建文件：
- EamsLoginService.ets
- LoginImportPage.ets

修改文件：
- CourseParserFromJS.ets（正则修正）
- Index.ets（跳转目标）
- main_pages.json（注册页面）

验收结果：
- ✅ 登录成功
- ✅ 获取课表成功
- ✅ 解析 XX 门课程
- ✅ 导入数据库成功
- ✅ 课表显示正常
```
