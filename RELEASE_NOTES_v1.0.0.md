# NuomiLauncher v1.0.0 首发

用 **糯米语言（Nuomi）** 写的 Minecraft Java 版启动器 —— GUI + CLI 双形态，离线走 Mojang Piston API，**真的能把游戏拉起来**（实测 Minecraft 1.21.4 一次拉起成功）。

## ✨ 它能干啥

- ✅ 离线 Piston API 解析版本 manifest → 下载 `client.jar` + 59 依赖库 + 9 原生库
- ✅ 资源包**并发下载**（`curl --parallel` 默认并发 24）+ 逐个 **SHA-1 校验**，失败项自动重新生成清单重试一次
- ✅ **GUI 窗口**：账户管理 / 启动页，Windows 真 Win32 窗口，中文标题栏不乱码
- ✅ **三种登录**：微软正版（OAuth2 设备码流 + `refresh_token` 静默续期）、LittleSkin（Yggdrasil 外置登录）、离线模式
- ✅ 多账户切换、自动续期；密码含 `"` / `\` 等特殊字符也能正确登录（已修 JSON 转义 + body 走文件传参）
- ✅ 启动后 `spawn java`，正确传参、抓日志

**实测数据**：全量（client.jar + 59 库 + 9 原生库 + 4039 资源）一次拉完约 **4 分半钟**、资源零失败；早期纯串行仅资源就要 ~1 小时，提速接近一个数量级。

## 🚀 怎么用

1. 下载本 Release 的 **5 个文件**，放到**同一个目录**
2. 双击 `start.bat`（GUI 模式），或命令行 `nuomi.exe launcher.nuomi help` 看 CLI 用法
3. 首次用先点 GUI 里的「登录」添加账户；离线模式也能直接进游戏

> 嫌慢 / 网络差：调 `launcher.nuomi` 里的 `PARALLEL_MAX`（网好可上 50，慢网降到 8~16）。
> 彻底不要资源包：把 `DOWNLOAD_ASSETS` 改成 `false`（缺资源只有贴图/音效报错，游戏照样进主菜单）。

## 📦 文件清单

| 文件 | 作用 |
| --- | --- |
| `nuomi.exe` | 糯米语言解释器（已含启动器运行所需全部原语：窗口 / HTTP / 进程 / SHA-1 / unzip / JSON） |
| `launcher.nuomi` | 启动器核心逻辑（CLI + 下载管线） |
| `gui.nuomi` | GUI 窗口逻辑 |
| `start.bat` | 一键启动脚本（GUI 模式） |
| `README.md` | 完整文档（含 Azure 应用注册、LittleSkin 登录图文教程） |

## ⚠️ 已知限制

- 仅 **Java 版**，不支持基岩版
- 不支持 Mod / Fabric / Forge（要加得自己解析 profiles JSON）
- 微软登录需**自备 Azure 应用 client_id**（公共 ID 已被微软下架），且新应用还要过 Mojang 的 AppID **人工审核**才能登录成功（详见 README 8.1）
- 离线模式每次启动都是新 UUID（皮肤只有默认 Steve/Alex）；登录后使用真实账户

## 🔗 相关

- 启动器源码：<https://github.com/Ryan-cpu-lang/NuomiLauncher>
- 语言本体（Nuomi）：<https://github.com/Ryan-cpu-lang/Nuomi>
