# Center Window

> 一键将游戏窗口居中，告别强迫症。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-lightgrey.svg)]()

---

## 快速开始

**只需两个文件**，放在同一目录下：

- `center_mhxy.bat` —— 启动器
- `center_mhxy.ps1` —— 主脚本

**双击 `.bat`，点「是」授权 UAC，窗口自动居中。**

---

## 支持的游戏

| 游戏 | 默认支持 | 进程名 |
|------|:--:|------|
| 梦幻西游 | ✅ | `mhtab`（主窗口）、`mhmain`（登录器） |
| 大话西游 | 改参数 | `dh2` |
| 其他程序 | 改参数 | 例如 `notepad`、`firefox` |

**自定义目标：** 命令行加 `-ProcessName` 参数，或编辑 `.ps1` 第 1 行改默认值。

```powershell
.\center_mhxy.ps1 -ProcessName dh2
.\center_mhxy.ps1 -ProcessName notepad,calc
```

---

## 它做了什么

1. 找到目标进程的窗口
2. 如果窗口被藏在屏幕外（游戏最小化到托盘会使窗口坐标变为 `-21333`），先恢复
3. 计算屏幕中心位置
4. 调用 Windows 标准 API（`MoveWindow`）移动窗口
5. 需要管理员权限时自动弹出 UAC 提权

---

## 安全性

**不会导致封号。** 脚本只做一件事：调用 Windows 系统 API 移动窗口位置。

- 不读写游戏内存
- 不注入任何代码到游戏进程
- 不修改游戏文件
- 不和反作弊系统交互

它做的事情等同于你手动 Alt+Space → 「移动」→ 拖窗口到中间，只是自动化了。Windows 自带的窗口管理、多显示器工具、DisplayFusion 等都在用同样的 API，从未有因此被封号的案例。

---

## 系统要求

- Windows 10 或 Windows 11
- 无需安装任何额外软件（系统自带 PowerShell）
- 游戏若以管理员身份运行，需点一次 UAC 确认

> **macOS / Linux 不适用。** 本工具基于 Windows Win32 API，在其他操作系统上无法运行。

---

## 附：Claude Code Skill

本仓库同时包含一个 [Claude Code](https://claude.ai/code) 技能定义（`SKILL.md`），安装后可直接对话触发。

---

## License

MIT
