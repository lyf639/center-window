# Center Window

将任意窗口移动到屏幕正中央的 PowerShell 工具 / Claude Code Skill。

## 功能

- 按**进程名**或**窗口标题关键词**定位目标窗口
- 自动恢复最小化或离屏窗口
- 支持多显示器（选择目标屏幕）
- 检测提权需求（管理员进程窗口）
- 列出所有可见窗口以辅助定位

## 一键使用（无需 Claude）

将 `center_mhxy.bat` 和 `center_mhxy.ps1` 放到同一个文件夹，**双击 .bat** 即可。

脚本会：
1. 自动检测管理员权限
2. 不够则弹出 UAC 提权（和游戏同级权限才能移动窗口）
3. 找到 `mhtab` / `mhmain` 进程的最大窗口
4. 如果窗口离屏（`-21333, -21333`），先恢复
5. 移动到屏幕正中央

## 自定义其他程序

```powershell
.\center_mhxy.ps1 -ProcessName notepad
.\center_mhxy.ps1 -ProcessName calc,notepad
```

## 为什么游戏需要管理员权限才能移动？

梦幻西游等 MMO 游戏以管理员身份运行，并持续在渲染循环中重置窗口位置。同级别的 `MoveWindow` / `SetWindowPos` 调用可以覆盖游戏的位置锁定。

## 窗口"离屏"是什么？

梦幻西游最小化到托盘时，并不真正最小化——而是把窗口移到 `(-21333, -21333)`（屏幕外）。这是一个保持 DirectX 渲染表面不被销毁的老技巧。恢复时窗口回到之前可见的位置。

## 安装为 Claude Code Skill

将 `skills/center-window/` 目录放到 `.claude/skills/` 下。

## 参数

| 参数 | 说明 |
|------|------|
| `-ProcessName` | 进程名（不含 .exe），可多个 |
| `-TitleKeyword` | 窗口标题匹配关键词 |
| `-List` | 列出所有可见窗口 |
| `-MonitorIndex` | 目标显示器编号（默认 0 = 主屏） |

## 常见游戏进程名

| 游戏 | 进程名 |
|------|--------|
| 梦幻西游 | `mhtab` (主窗口), `mhmain` (登录器) |
| 大话西游 | `dh2` |

## License

MIT
