# NuomiLauncher v1.0.1

> 修掉「双击启动器总跟着一个 cmd 黑框」的问题。核心思路是 Python `python.exe` / `pythonw.exe`
> 的同款双解释器方案，加上子进程统一静默。

## 快速开始（有变化！）

**双击 `nuomiMC-GUI.vbs`** 打开图形界面 —— 全程零 cmd 黑框。

想看下载/登录日志、跑命令行模式时，仍用 `start.bat <mode>` 或 `nuomi.exe`。
从批处理/控制台程序启动会带一个 cmd 窗口，那是 Windows 分配的控制台，不是报错。

## 为什么以前有黑框

两个来源叠加：

1. **`.bat` 文件本身**：双击 `start.bat`，Windows 用 `cmd.exe` 解释执行，必然先开一个控制台窗口，`start.bat` 里 `echo` 的提示也打在这个窗口里。
2. **`nuomi.exe` 是 CONSOLE 子系统**：链接时没加 `-mwindows` / `-Wl,--subsystem,windows`，所以即使能画出真 GUI 窗口，也会自带一个黑框控制台。

另外 GUI 点「启动游戏 / 登录」时，后台会用 `cmd /c start /min` 拉起下载任务，
curl / java / powershell 这些 console 子进程也各自可能弹黑框。

## 这次改了什么

| 改动 | 说明 |
|---|---|
| 新增 `nuomiw.exe` | GUI 子系统版解释器，启动时 Windows 不分配控制台窗口 |
| 新增 `nuomiMC-GUI.vbs` | 推荐双击入口，由 `wscript.exe`（GUI 宿主）拉起 `nuomiw.exe` |
| `gui.nuomi` 后台任务改用 `nuomiw.exe` | 点按钮启动的下载/登录进程也不再带黑框 |
| `start.bat gui` 分支改用 `nuomiw.exe` | 从这里进 GUI 也少一个黑框（批处理自身的窗口仍在） |
| `proc.c` 加 `CREATE_NO_WINDOW` | curl / java / powershell / cmd 子进程全部静默，输出仍走匿名管道读回 |
| 两个 exe 都换成新编译版 | 旧的 `nuomi.exe` 不含子进程静默修复，已一并替换 |

### 为什么不做成「把 nuomi.exe 改成 GUI 子系统」

那样 `start.bat dry/download/launch` 的 `say` / `println` 日志、REPL、编译模式、
`nuomi nuc` 工具链全都会失去控制台输出。所以保留 CONSOLE 版给 CLI，另出一份 GUI 版。

### 为什么用「改 PE 头」而不是加 `-mwindows` 重新链接

链接器切到 GUI 子系统时会改选 `WinMainCRTStartup` 作为入口，而 Nuomi 用的是标准
`main()`，会直接链接失败。改 PE 头不动入口点，还顺带兼容 clang / gcc / TCC 三种编译器
（`build.bat` 会自动探测）。两个 exe 是同一份二进制，只差 4 字节
（Subsystem 字段 3→2、CheckSum 清零）。

## 验证记录

- PE 头实测：`nuomi.exe` Subsystem=3(CONSOLE)、`nuomiw.exe` Subsystem=2(GUI)，差异 4 字节
- 真·无控制台启动（`DETACHED_PROCESS`）：`nuomiw.exe` 退出码 0，`proc-run` 拉起 cmd 与 curl 均返回 0，脚本跑到底并写出结果文件
- console 版回归：12 个非交互样例 12/12 通过；NUC 流水线 `emit-demo → validate → run` 返回 42；编译模式 `-c` 正常
- TCC 编译零报错、零警告

## 文件清单

```
launcher.nuomi      启动器本体
gui.nuomi           图形界面
nuomi.exe           CONSOLE 版解释器（CLI / 日志 / REPL）
nuomiw.exe          GUI 版解释器（双击无黑框）
nuomiMC-GUI.vbs     ★ 推荐双击入口
start.bat           命令行入口（gui / dry / download / launch）
README.md
```

## 仍需你本人验证

沙箱没有桌面，没法代你双击看真实窗口。请在桌面双击 **`nuomiMC-GUI.vbs`**，
确认图形界面正常出现、且任务栏/屏幕上没有跟着黑色 cmd 框。

> v1.0.0 用户：直接下载本页全部文件覆盖到原目录即可，配置文件
> （`%USERPROFILE%/.nuomi-mc/` 下的账户等）不受影响。
