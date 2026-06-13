# Center Window

将任意窗口移动到屏幕正中央的 PowerShell 工具 / Claude Code Skill。

## 功能

- 按**进程名**或**窗口标题关键词**定位目标窗口
- 自动恢复最小化或离屏窗口
- 支持多显示器（选择目标屏幕）
- 检测提权需求（管理员进程窗口）
- 列出所有可见窗口以辅助定位

## 使用

### 作为 Claude Code Skill

安装后直接对话触发：

- "帮我把梦幻西游移到屏幕中间"
- "把 notepad 窗口居中"
- "列出所有窗口"

### 作为独立 PowerShell 脚本

```powershell
# 列出所有可见窗口
.\center_window.ps1 -List

# 按进程名居中
.\center_window.ps1 -ProcessName "notepad"

# 按标题关键词居中
.\center_window.ps1 -TitleKeyword "记事本"

# 需要管理员权限时
Start-Process powershell -Verb RunAs -ArgumentList '-File "center_window.ps1" -ProcessName "xxx"'
```

## 安装

将 `skills/center-window/` 目录放到 `.claude/skills/` 下即可。

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
