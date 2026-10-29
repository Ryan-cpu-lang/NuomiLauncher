# NuomiLauncher · 用糯米语言写的 Minecraft 启动器

> 纯 Nuomi（糯米语言）实现的 Minecraft 启动器，离线优先，不打包任何游戏文件，
> 全部走 Mojang 官方 Piston API 下载。

```
E:/workbuddy/2026-10-28-17-17-07/nuomi-launcher/
├── launcher.nuomi     ← 启动器本体（全部逻辑都在这一个文件里）
├── gui.nuomi          ← 图形界面（自绘窗口，鼠标点 + 输入玩家名）
├── nuomi.exe          ← 糯米解释器（含本项目给 Nuomi 加的原生函数）
├── start.bat          ← 双击运行（纯英文 + GBK + CRLF）
└── README.md
```

---

## 一、快速开始

双击 `start.bat`，或者在命令行里：

```bat
start.bat gui        :: 打开图形界面（推荐：鼠标点按钮 + 输入玩家名）
start.bat dry        :: 只规划，打印 java 启动命令，不下载不启动
start.bat download   :: 下载全部资源（client.jar / 依赖库 / 原生库 / 资源包）
start.bat launch     :: 下载全部资源并启动 Minecraft
start.bat            :: 按 launcher.nuomi 里的 CONFIG 默认值走
```

也可以直接跑解释器：

```bat
nuomi.exe launcher.nuomi
nuomi.exe gui.nuomi
```

> 如果按之前步骤把 `C:\Users\RAYN\mc-launcher` 前置到了 PATH，
> 命令行里直接打 `nuomi MC-gui` 也能开图形界面（其它模式：`nuomi MC-start` /
> `nuomi MC-download` / `nuomi MC-dry`）。

---

## 一-A、图形界面（GUI）

不想敲命令的话，用 GUI 最省事：双击 `start.bat` 选 `gui`，或命令行 `nuomi MC-gui`。

界面长这样（自绘窗口，无第三方库）：

- **标题栏**：`Nuomi MC Launcher` + 版本号
- **玩家名输入框**：点一下就能打字，最多 16 字，`Backspace` 删除，空着会用默认 `Tracgiture`
- **启动游戏** 按钮：下载全部资源并启动 Minecraft
- **下载资源** 按钮：只下载，不启动
- **状态文字** + **进度条**：显示后台任务进行到哪（库 N/total、资源 N/total）
- `Esc` 或点窗口右上角 `X` 退出

> 💡 后端其实是 `launcher.nuomi`（CLI）。GUI 用 `cmd /c start /min` 异步拉起它，
> 进度写进 `%USERPROFILE%/.nuomi-mc/gui_progress.txt`，GUI 轮询显示——
> 所以主窗口的消息循环不会卡住。麻烦的是 Java 仍要在 PATH 里（见下方提醒）。

> ⚠️ **需要自备 Java**：`java` 要在 PATH 里（装 JRE/JDK 都行）。
> 想指定路径就改 `launcher.nuomi` 里的 `JAVA_CMD`。

---

## 二、配置项（都在 `launcher.nuomi` 顶部的 CONFIG 区）

| 变量 | 默认值 | 说明 |
|---|---|---|
| `TARGET_VERSION` | `1.21.4` | 要启动的版本（Piston 上真实存在的版本号） |
| `USERNAME` | `Tracgiture` | 离线玩家名 |
| `RAM_MB` | `2048` | 堆内存上限（`-Xmx`） |
| `JAVA_CMD` | `java` | java 可执行文件 |
| `OS` | `windows` | `windows` / `linux` / `osx`，用于规则匹配 |
| `ARCH` | `x86_64` | `x86_64` / `x86` / `arm64` |
| `DOWNLOAD_ASSETS` | `true` | 是否下载资源包（贴图/音效，约 420 MB） |
| `USE_CURL_PARALLEL` | `true` | 资源包是否用 `curl --parallel` 批量下载（提速关键，详见「九、已知限制」） |
| `PARALLEL_MAX` | `24` | curl 并发数；网络好可上 50，慢网降到 8~16 |
| `DRY_RUN` / `LAUNCH?` | `true` / `true` | 兜底模式，一般用 `NUOMI_MODE` 环境变量代替 |

环境变量 `NUOMI_MODE` 可以临时覆盖 `DRY_RUN` / `LAUNCH?`，`start.bat` 就是靠它切换模式的。

---

## 三、文件放哪

| 内容 | 路径 |
|---|---|
| 根目录 | `%USERPROFILE%/.nuomi-mc`（Linux/macOS 是 `~/.nuomi-mc`） |
| client.jar | `.nuomi-mc/versions/<版本>/<版本>.jar` |
| 依赖库 | `.nuomi-mc/libraries/<maven 路径>.jar` |
| 原生库解压 | `.nuomi-mc/instances/<版本>/natives/` |
| 资源包 | `.nuomi-mc/assets/objects/<前2位>/<sha1>` |

> 顶部的 `BASE_DIR` 改成别的路径即可换位置。

---

## 四、它做了什么（管线）

1. **拉版本清单** → `piston-meta.mojang.com/mc/game/version_manifest_v2.json`
2. **拉版本元数据** → 拿到 `client.jar` 的地址/sha1、依赖库列表、资源索引地址
3. **按平台过滤依赖**（见下节，这是最容易踩坑的地方）
4. **拉资源索引** → 统计要下多少个资源对象
5. **下载 + SHA1 校验** → 已有且校验通过就跳过
6. **解压原生库** → `unzip` 到 `natives/`
7. **拼 JVM 参数** → 用元数据里的 `arguments.jvm` / `arguments.game`，
   过滤规则 + 替换 `${...}` 占位符
8. **启动 java**

---

## 五、平台过滤规则（最容易踩坑的地方）

Mojang 的 `rules` 语义，**必须严格按这个来**，否则会把 linux/macOS 的库
塞进 Windows 的 classpath：

- 规则里带 `os` 且和本机不匹配 → 这条规则**不适用**
- 在**适用**的规则里，**最后一条**的 `action` 决定去留
- `rules` 列表非空但一条都不适用 → **排除**
- 完全没有 `rules` → **包含**
- 带 `features` 条件的规则 → 离线模式没有特性开关，**不适用**
  （1.21.4 的 `--demo`、`--quickPlay*` 全挂在 features 上，不处理会把
  `${quickPlayPath}` 这种占位符直接塞进启动命令）

**原生库的判定**（1.19 起变了）：

- 旧写法（1.19 前）：`lib.natives.<os>` → `downloads.classifiers` 的键
- 新写法（1.19+）：`name` 带 classifier，如 `org.lwjgl:lwjgl:3.3.3:natives-windows`
  - 平台靠 classifier 里的 `windows`/`linux`/`macos` 判断
  - 架构靠后缀：`-x86_64` / `-arm64`(`-aarch_64`) / `-x86`
  - 没有架构后缀 = 64 位（`natives-windows` 是 x86_64，
    `natives-windows-x86` 才是 32 位）

> ⚠️ **`rules` 区分不出 x86 / x86_64 / arm64**，必须靠 classifier 后缀。
> 这是 1.21.4 上 25 条 windows 规则里混着 3 种架构的原因。

---

## 六、两个容易踩的坑（都已在代码里处理）

### 1. classpath 分隔符

Windows 是 **`;`**，不是 `/`。用 `/` 会直接
`ClassNotFoundException: net.minecraft.client.main.Main`。

### 2. 原生库 jar 必须在 classpath 上

LWJGL 3.3 的 `SharedLibraryLoader` 是**从 classpath 资源里找**
`windows/x64/org/lwjgl/*.dll` 自己解压的。
所以原生库 jar 不能只解压到 `natives/`，**还得同时进 classpath**。

---

## 七、给 Nuomi 加的原生函数

这个启动器用到了几个 Nuomi 本来没有的原生函数，都加在 Nuomi 仓库里了：

| 函数 | 作用 | 文件 |
|---|---|---|
| `sha1-string` / `sha1-file` | SHA1 校验 | `src/sha1.c` |
| `unzip` | 解压 zip/jar（自带 deflate 解码器，无 zlib 依赖） | `src/zip.c` |
| `str-split` / `str-replace` | 字符串切分/替换 | `src/strutil.c` |
| `getenv` | 读环境变量（用来定位用户主目录） | `src/native.c` |
| `to-number` | 字符串转数字（GUI 进度条用） | `src/native.c` |
| `window-click` | 取鼠标左键点击坐标（队列，返回 `x*100000+y`） | `src/wm.c` |
| `window-char` | 取键盘输入字符（UTF-8，队列） | `src/wm.c` |

Nuomi 重新编译：

```bat
cd ..\nuomi-lang
build.bat
```

> ⚠️ **`(home)` 不是"取主目录"**！它是「光标复位 + 隐藏光标」的终端指令，
> 恒返回 nil。主目录要用 `(getenv "USERPROFILE")`（Windows）
> 或 `(getenv "HOME")`（其它平台）。

---

## 八、离线模式的说明

- UUID 每次随机生成（v4），token 随机 40 位十六进制 → **每次启动都是"新账号"**
- 皮肤是默认的 Steve/Alex，进不去正版服务器
- 单机存档完全正常
- **想做正版登录**的话，需要另外接微软 OAuth（任务 6，还没做）

---

## 九、已知限制

- 只支持 **Java 版**，不支持基岩版
- 不支持 Mod / Fabric / Forge（要加的话得自己解析 profiles JSON）
- **资源包下载（已优化提速）**：4039 个资源对象，早期串行约 1 个/秒 → 全量 ~1 小时；
  也试过 Nuomi 自带并发（`http-download-many`），**实测反而慢 4 倍**（WinINet 全局锁串行化）。
  现在改用 **Windows 自带的 `curl.exe --parallel`** 批量下载（默认并发 24），
  下载完再逐个 SHA1 校验，**失败项自动重新生成清单重试一次**。
  实测：全量（client.jar + 59 库 + 9 原生库 + 4039 资源）一次拉完约 **4 分半钟**、资源零失败；
  而早期串行仅资源就要 ~1 小时，提速接近一个数量级。
  - 嫌慢/网络差：调 `launcher.nuomi` 里的 `PARALLEL_MAX`（网络好可上 50，慢网降到 8~16）
  - 彻底不要资源包：把 `DOWNLOAD_ASSETS` 改成 `false`
    （缺资源只有贴图/音效报错，**游戏照样能进主菜单**）
- 不支持多实例切换
- 离线模式每次启动都是新 UUID（皮肤只有默认 Steve/Alex）
