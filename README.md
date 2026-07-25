# 💕 报备助手

**情侣专属报备 App** — 实时定位共享 · 历史轨迹回放 · 状态同步 · 甜蜜聊天

> 完全免费 · 无需会员 · 永久自用

---

## ✨ 功能一览

| 功能 | 说明 |
|------|------|
| 📍 **实时定位** | 高精度地图显示双方位置，后台持续上报 |
| 🗺️ **历史轨迹** | 查看某天的完整行动路径，支持回放 |
| 💬 **状态报备** | 一键发送"出门了/到家了/在忙…"等状态 |
| 🔋 **电量显示** | 显示对方手机电量状态 |
| 💌 **甜蜜聊天** | 内嵌聊天功能，消息实时推送 |
| 🔐 **配对绑定** | 6 位配对码，一人创建另一人输入即绑定 |
| 🌙 **后台运行** | 手机在口袋也能持续同步位置 |

---

## 🛠️ 技术栈

- **前端**: Flutter 3.19+ (Dart)
- **后端**: Supabase (PostgreSQL + Realtime)
- **地图**: OpenStreetMap (免费，无需 API Key)
- **定位**: geolocator + flutter_background_service
- **CI/CD**: GitHub Actions 自动编译 APK

---

## 📱 部署教程（跟着做就对了）

### 第一步：注册 Supabase 账号（免费）

1. 打开 [supabase.com](https://supabase.com) 点击 **Start your project**
2. 用 GitHub 账号登录
3. 创建一个新项目：
   - **Name**: `baobei-app`（随便填）
   - **Database Password**: 设一个密码并记下来
   - **Region**: 选 **Singapore**（离中国最近，速度快）
   - 点击 **Create new project**（等 1-2 分钟）
4. 创建完成后，进入项目 Dashboard

### 第二步：导入数据库

1. 在 Supabase Dashboard 左侧菜单点击 **SQL Editor**
2. 点击 **New Query** → 或者直接打开 SQL 编辑器
3. 打开本项目中的 `supabase/schema.sql` 文件，复制全部内容
4. 粘贴到 SQL 编辑器中，点击 **Run**（运行）
5. 你会看到 5 张表被创建：`profiles`、`locations`、`statuses`、`messages`、`alerts`

### 第三步：获取 API 密钥

1. 在 Supabase Dashboard 点击 **Project Settings**（齿轮图标）
2. 点击 **API**
3. 你会看到两个关键信息：
   - **Project URL**（类似 `https://xxxxx.supabase.co`）
   - **anon public** 密钥（一串长字符串）
4. 打开本项目中的 `lib/config/constants.dart`
5. 把第 9-10 行的内容替换成你的：

```dart
static const String supabaseUrl = 'https://你的项目ID.supabase.co';
static const String supabaseAnonKey = '你的anon-key';
```

### 第四步：开启 Realtime（实时推送）

1. 在 Supabase Dashboard 点击 **Database** → **Replication**
2. 在 **Source** 选项卡下，找到 `supabase_realtime` 发布
3. 确保 `locations`、`statuses`、`messages`、`alerts` 这四个表都被选中
4. 点击 **Save**

### 第五步：编译 APK

#### 方法 A：用 GitHub Actions（推荐，无需本地环境）

1. 注册 [GitHub](https://github.com) 账号
2. 创建一个新仓库（点右上角 `+` → **New repository**）
3. 仓库名随便填，选 **Public** 或 **Private** 都行
4. 回到你的电脑，打开终端运行：

```bash
# 把代码上传到 GitHub（把 YOUR_USERNAME 换成你的用户名）
cd C:\Users\28204\Desktop\baobei_app
git init
git add .
git commit -m "🎉 初始提交"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/baobei-app.git
git push -u origin main
```

5. 上传完成后，打开 GitHub 仓库页面
6. 点击 **Actions** 选项卡
7. 你会看到一个叫 **编译 APK** 的工作流正在运行
8. 等它跑完（大约 5-8 分钟）
9. 跑完后点击 workflow 进入详情，下面有个 **Artifacts** 区域
10. 点击 **baobei-app-apk** 下载 ZIP 文件
11. 解压后里面就有 `app-armeabi-v7a-release.apk` 等文件
12. 把 APK 传到手机上安装即可

#### 方法 B：自己电脑编译（需要提前装 Flutter）

```bash
# 安装 Flutter 环境（如果还没装）
# 参考: https://flutter.dev/docs/get-started/install

# 进入项目目录
cd C:\Users\28204\Desktop\baobei_app

# 安装依赖
flutter pub get

# 编译 APK
flutter build apk --release --split-per-abi

# 编译好的文件在:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk
```

### 第六步：安装使用

1. 把 APK 传到你和 TA 的手机上
2. 安装时如果提示"未知来源"，允许即可
3. 打开 App → **注册账号**
4. 注册后你会看到一个 **6 位配对码**
5. **你复制配对码发给 TA**
6. **TA 注册后在 App 中输入你的配对码**
7. 绑定成功！🎉 开始报备吧

---

## ❓ 常见问题

### 地图加载慢或显示不出来？
> OpenStreetMap 在国内访问可能较慢。你可以换成高德地图：
> 1. 去 [lbs.amap.com](https://lbs.amap.com) 注册开发者账号
> 2. 创建应用获取 API Key
> 3. 在 `location_map.dart` 中将 TileLayer 换成高德瓦片

### 耗电吗？
> 后台定位会持续使用 GPS，会有一定耗电。
> 建议：不用时可以关闭位置共享

### 数据安全吗？
> 所有数据存储在 Supabase 的 PostgreSQL 数据库中，经过加密传输。
> Supabase 是开源平台，数据属于你自己。

### 最多能存多久的轨迹？
> 免费版 Supabase 有 500MB 存储，足够存好几年的轨迹数据（每条位置记录约 100 字节）

---

## 📁 项目结构

```
baobei_app/
├── lib/
│   ├── main.dart                  # 入口
│   ├── app.dart                   # App 根组件 + 路由
│   ├── config/
│   │   ├── constants.dart         # 全局常量（Supabase 配置在这里改）
│   │   └── theme.dart             # 主题配色
│   ├── models/                    # 数据模型
│   │   ├── user_profile.dart
│   │   ├── location_record.dart
│   │   ├── status_record.dart
│   │   └── chat_message.dart
│   ├── services/                  # 服务层
│   │   ├── supabase_service.dart   # Supabase API 封装
│   │   ├── location_service.dart   # 定位服务
│   │   ├── notification_service.dart
│   │   └── background_service.dart # 后台运行
│   ├── providers/                 # 状态管理
│   ├── screens/                   # 页面
│   ├── widgets/                   # 可复用组件
├── supabase/
│   └── schema.sql                 # 数据库建表脚本
└── .github/workflows/
    └── build.yml                  # 自动编译 APK
```

---

## 💡 想加功能？

代码都是你的，随便改！有任何问题可以问我。

祝你和你对象甜甜蜜蜜 💕
