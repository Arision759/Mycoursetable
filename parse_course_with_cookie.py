#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
长安大学教务系统课程解析脚本

登录流程：
1. 访问教务系统 → 被重定向到 CAS 统一认证
2. 从 CAS 登录页获取隐藏字段（lt, execution, _eventId, 加密 key）
3. AES 加密密码
4. POST 登录 → 获取 ticket → 回调教务系统 → 获取 JSESSIONID
5. GET courseTableForStd.action → 获取 ids
6. POST courseTableForStd!courseTable.action → 获取课表数据
7. 解析 TaskActivity
"""

import re
import json
import base64
import requests
from typing import List, Dict, Any, Optional

# 尝试导入加密库
try:
    from Crypto.Cipher import AES
    from Crypto.Util.Padding import pad
except ImportError:
    try:
        from Cryptodome.Cipher import AES
        from Cryptodome.Util.Padding import pad
    except ImportError:
        AES = None
        pad = None

WEEK_DAYS = ['一', '二', '三', '四', '五', '六', '日']

# ===== URL 配置 =====
EAMS_BASE = "http://bkjw.chd.edu.cn/eams"
CAS_BASE = "https://ids.chd.edu.cn/authserver"
LOGIN_SERVICE = f"{EAMS_BASE}/login.action"
COURSE_TABLE_PAGE = f"{EAMS_BASE}/courseTableForStd.action"
COURSE_TABLE_DATA = f"{EAMS_BASE}/courseTableForStd!courseTable.action"


class Course:
    def __init__(self):
        self.course_name: str = ""
        self.course_code: str = ""
        self.teachers: str = ""
        self.day_of_week: int = 0
        self.start_section: int = 0
        self.end_section: int = 0
        self.start_week: int = 0
        self.end_week: int = 0
        self.classroom: str = ""

    def to_dict(self) -> Dict[str, Any]:
        return {
            'courseName': self.course_name,
            'courseCode': self.course_code,
            'teachers': self.teachers,
            'dayOfWeek': self.day_of_week,
            'dayName': f'星期{WEEK_DAYS[self.day_of_week - 1]}' if 1 <= self.day_of_week <= 7 else '',
            'startSection': self.start_section,
            'endSection': self.end_section,
            'startWeek': self.start_week,
            'endWeek': self.end_week,
            'classroom': self.classroom
        }


def aes_encrypt(password: str, key: str) -> str:
    """CAS 统一认证密码 AES 加密"""
    if AES is None:
        raise RuntimeError("需要安装 pycryptodome: pip install pycryptodome")

    # CAS 使用的 AES 加密方式：CBC 模式，密钥同时作为 IV
    # 明文格式：随机前缀(通常64位) + password
    # 有些学校用 key 做 IV，有些随机生成
    key_bytes = key.encode('utf-8')

    # 随机前缀（64字符）+ 密码
    import random
    import string
    random_prefix = ''.join(random.choices(string.ascii_letters + string.digits, k=64))
    plaintext = random_prefix + password

    cipher = AES.new(key_bytes, AES.MODE_CBC, key_bytes)
    encrypted = cipher.encrypt(pad(plaintext.encode('utf-8'), AES.block_size))
    return base64.b64encode(encrypted).decode('utf-8')


def cas_login(session: requests.Session, username: str, password: str) -> bool:
    """
    CAS 统一认证登录

    流程：
    1. GET CAS 登录页 → 获取 lt, execution, _eventId, pwdEncryptSalt
    2. AES 加密密码
    3. POST 登录 → 跟随重定向回教务系统
    """
    print("1️⃣  访问 CAS 登录页...")

    # 访问教务系统登录页，会重定向到 CAS
    cas_login_url = f"{CAS_BASE}/login?service={requests.utils.quote(LOGIN_SERVICE)}"

    try:
        resp = session.get(cas_login_url, timeout=15, verify=False)
    except Exception as e:
        print(f"   ❌ 访问 CAS 失败: {e}")
        return False

    if resp.status_code != 200:
        print(f"   ❌ CAS 返回 HTTP {resp.status_code}")
        return False

    html = resp.text
    print(f"   ✅ CAS 登录页加载成功 (长度: {len(html)})")

    # 提取隐藏字段
    lt_match = re.search(r'name="lt"\s+value="([^"]*)"', html)
    execution_match = re.search(r'name="execution"\s+value="([^"]*)"', html)
    event_id_match = re.search(r'name="_eventId"\s+value="([^"]*)"', html)
    salt_match = re.search(r'id="pwdEncryptSalt"\s+value="([^"]*)"', html)

    # 备选：有些版本用 pwdDefaultEncryptSalt
    if not salt_match:
        salt_match = re.search(r'id="pwdDefaultEncryptSalt"\s+value="([^"]*)"', html)
    if not salt_match:
        salt_match = re.search(r'var\s+pwdDefaultEncryptSalt\s*=\s*"([^"]*)"', html)

    lt = lt_match.group(1) if lt_match else ""
    execution = execution_match.group(1) if execution_match else ""
    event_id = event_id_match.group(1) if event_id_match else "submit"

    print(f"   lt: {'✅ 找到' if lt else '❌ 未找到'}")
    print(f"   execution: {'✅ 找到' if execution else '❌ 未找到'}")
    print(f"   _eventId: {event_id}")

    # 加密密码
    if salt_match:
        salt = salt_match.group(1)
        print(f"   pwdEncryptSalt: ✅ 找到 ({salt[:8]}...)")
        try:
            encrypted_password = aes_encrypt(password, salt)
            print(f"   密码加密: ✅")
        except Exception as e:
            print(f"   密码加密失败: {e}")
            encrypted_password = password
    else:
        print(f"   pwdEncryptSalt: ❌ 未找到，使用明文密码")
        encrypted_password = password

    # 登录
    print()
    print("2️⃣  提交登录...")

    login_data = {
        'username': username,
        'password': encrypted_password,
        'lt': lt,
        'execution': execution,
        '_eventId': event_id,
        'cllt': 'userNameLogin',
        'dllt': 'generalLogin',
        'rmShown': '1',
    }

    headers = {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'Referer': cas_login_url
    }

    try:
        resp = session.post(cas_login_url, data=login_data, headers=headers,
                           timeout=15, allow_redirects=True, verify=False)
    except Exception as e:
        print(f"   ❌ 登录请求失败: {e}")
        return False

    # 判断是否登录成功
    final_url = resp.url
    print(f"   最终 URL: {final_url}")

    if 'login' in final_url and 'authserver' in final_url:
        # 仍在登录页，登录失败
        error_match = re.search(r'id="showErrorTip"[^>]*>([^<]+)', resp.text)
        if not error_match:
            error_match = re.search(r'class="auth_error"[^>]*>([^<]+)', resp.text)
        if not error_match:
            error_match = re.search(r'id="msg"[^>]*>([^<]+)', resp.text)

        error_msg = error_match.group(1).strip() if error_match else "未知错误"
        print(f"   ❌ 登录失败: {error_msg}")
        return False

    print(f"   ✅ 登录成功！")

    # 打印 cookies
    print(f"   Cookies: {[c.name for c in session.cookies]}")
    return True


def get_ids(session: requests.Session) -> Optional[str]:
    """
    获取学生 ids 参数
    访问 courseTableForStd.action，从响应中提取 ids
    """
    print()
    print("3️⃣  获取学生 ids...")

    try:
        resp = session.get(COURSE_TABLE_PAGE, timeout=10, verify=False)
    except Exception as e:
        print(f"   ❌ 请求失败: {e}")
        return None

    if resp.status_code != 200:
        print(f"   ❌ HTTP {resp.status_code}")
        return None

    # 从页面中提取 ids
    # 格式："ids=206271" 或 "bg.form.addInput(form,"ids","206271")"
    ids_match = re.search(r'bg\.form\.addInput\(form,\s*"ids"\s*,\s*"(\d+)"\s*\)', resp.text)
    if not ids_match:
        ids_match = re.search(r'"ids"\s*,\s*"(\d+)"', resp.text)
    if not ids_match:
        ids_match = re.search(r'ids=(\d+)', resp.text)

    if ids_match:
        ids = ids_match.group(1)
        print(f"   ✅ ids = {ids}")
        return ids
    else:
        print(f"   ❌ 未找到 ids")
        # 保存页面用于调试
        with open('debug_courseTableForStd.html', 'w', encoding='utf-8') as f:
            f.write(resp.text)
        print(f"   已保存到 debug_courseTableForStd.html")
        return None


def get_semester_id(session: requests.Session) -> Optional[str]:
    """获取当前学期 semester.id"""
    # 通常从 cookie 中获取
    for cookie in session.cookies:
        if cookie.name == 'semester.id':
            return cookie.value

    # 或者从页面中提取
    # semester.id 可能在 courseTableForStd.action 的响应中
    return None


def get_course_table(session: requests.Session, semester_id: str, ids: str) -> str:
    """
    POST 请求课表数据
    """
    print()
    print("4️⃣  获取课表数据...")

    headers = {
        'Accept': '*/*',
        'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        'Origin': EAMS_BASE,
        'Referer': COURSE_TABLE_PAGE,
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        'X-Requested-With': 'XMLHttpRequest'
    }

    data = {
        'ignoreHead': '1',
        'setting.kind': 'std',
        'startWeek': '',
        'semester.id': semester_id,
        'ids': ids
    }

    try:
        resp = session.post(COURSE_TABLE_DATA, headers=headers, data=data,
                           timeout=10, verify=False)
    except Exception as e:
        print(f"   ❌ 请求失败: {e}")
        return ""

    if resp.status_code != 200:
        print(f"   ❌ HTTP {resp.status_code}")
        return ""

    html = resp.text
    print(f"   ✅ 获取成功 (长度: {len(html)} 字符)")

    if 'TaskActivity' in html:
        print(f"   ✅ 包含 TaskActivity 数据")
    else:
        print(f"   ⚠️  未检测到 TaskActivity")

    return html


def parse_valid_weeks(weeks_str: str) -> tuple:
    """解析有效周"""
    start = -1
    end = -1
    for i, ch in enumerate(weeks_str):
        if ch == '1':
            if start == -1:
                start = i + 1
            end = i + 1
    return (start, end) if start != -1 else (1, 20)


def parse_courses(html: str) -> List[Course]:
    """解析 TaskActivity 课程数据"""
    print()
    print("=" * 60)
    print("5️⃣  解析课程数据")
    print("=" * 60)

    # 提取 unitCount
    unit_match = re.search(r'var\s+unitCount\s*=\s*(\d+)', html)
    if not unit_match:
        print("   ❌ 未找到 unitCount")
        return []
    unit_count = int(unit_match.group(1))
    print(f"   unitCount = {unit_count}")

    # 按 "var teachers" 分割代码块
    blocks = re.split(r'(?=\bvar\s+teachers\s*=\s*\[)', html)

    courses: List[Course] = []
    seen: set = set()

    for block in blocks:
        # 提取教师名称
        teacher_names = re.findall(r'name:"([^"]+)"', block)
        if not teacher_names:
            continue

        # 提取课程名称
        course_name_match = re.search(r'var\s+courseName\s*=\s*"([^"]+)"', block)
        if not course_name_match:
            continue
        course_name_full = course_name_match.group(1)

        # 提取 TaskActivity 中的字符串参数
        # 实际格式: new TaskActivity(actTeacherId.join(','),actTeacherName.join(','),"53677(27XK1103.03)",courseName,"27XK1103.03","205","*WM1315☆","0111...",null,"",assistantName,"")
        ta_match = re.search(
            r"new\s+TaskActivity\("
            r"actTeacherId\.join\('[^']*'\)\s*,\s*actTeacherName\.join\('[^']*'\)\s*,"
            r'"([^"]*)"'          # [1] 课程ID
            r",courseName,"
            r'"([^"]*)"'          # [2] 课程代码
            r','
            r'"([^"]*)"'          # [3] 教室ID
            r','
            r'"([^"]*)"'          # [4] 教室
            r','
            r'"([^"]*)"',         # [5] 有效周
            block
        )

        if not ta_match:
            continue

        course_code = ta_match.group(2)
        classroom = ta_match.group(4).lstrip('*')
        valid_weeks = ta_match.group(5)

        # 课程名
        name_only = re.match(r'([^(]+)', course_name_full)
        course_name = name_only.group(1).strip() if name_only else course_name_full

        # 有效周
        start_week, end_week = parse_valid_weeks(valid_weeks)

        # 教师去重
        unique_teachers = list(dict.fromkeys(teacher_names))
        teachers_str = ','.join(unique_teachers)

        # 提取 index
        index_matches = re.findall(r'index\s*=\s*(\d+)\s*\*\s*unitCount\s*\+\s*(\d+)', block)
        if not index_matches:
            continue

        day = int(index_matches[0][0]) + 1
        sections = [int(m[1]) + 1 for m in index_matches]
        start_section = min(sections)
        end_section = max(sections)

        # 去重
        key = f"{course_code}_{day}_{start_section}"
        if key in seen:
            continue
        seen.add(key)

        course = Course()
        course.course_name = course_name
        course.course_code = course_code
        course.teachers = teachers_str
        course.day_of_week = day
        course.start_section = start_section
        course.end_section = end_section
        course.start_week = start_week
        course.end_week = end_week
        course.classroom = classroom
        courses.append(course)

        print(f"   ✅ {course_name} | {teachers_str} | 星期{WEEK_DAYS[day-1]} {start_section}-{end_section}节 | {start_week}-{end_week}周 | {classroom}")

    courses.sort(key=lambda c: (c.day_of_week, c.start_section))
    print(f"\n   共解析 {len(courses)} 门课程")
    return courses


def main():
    import urllib3
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

    print("=" * 60)
    print("📋 长安大学教务系统课程解析")
    print("=" * 60)
    print()

    if AES is None:
        print("⚠️  未安装加密库，请运行:")
        print("   pip install pycryptodome")
        print()
        print("如果安装后仍然无法登录，可能需要调整加密方式。")
        print()

    username = input("学号: ").strip()
    password = input("密码: ").strip()
    print()

    session = requests.Session()

    # 1. CAS 登录
    if not cas_login(session, username, password):
        return

    # 2. 获取 ids
    ids = get_ids(session)
    if not ids:
        return

    # 3. 获取 semester.id
    semester_id = get_semester_id(session)
    if not semester_id:
        # 使用你的默认值
        semester_id = "262"
        print(f"   ⚠️  未从 cookie 获取 semester.id，使用默认值: {semester_id}")

    # 4. 获取课表
    html = get_course_table(session, semester_id, ids)
    if not html:
        return

    # 保存响应用于调试
    with open('response_new.html', 'w', encoding='utf-8') as f:
        f.write(html)
    print("   已保存到 response_new.html")

    # 5. 解析课程
    courses = parse_courses(html)

    if not courses:
        print("\n❌ 未解析到课程")
        return

    # 输出 JSON
    print()
    print("=" * 60)
    print("📋 JSON 输出")
    print("=" * 60)
    print()
    print(json.dumps([c.to_dict() for c in courses], ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
