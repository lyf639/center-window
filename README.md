# Center Window

> 解决梦幻西游最小化后点不开、窗口消失的问题。顺手居中。

[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%2010%2F11-lightgrey.svg)]()

---

## 它解决什么问题

梦幻西游点「最小化到托盘」后，偶尔再点开的时候**窗口回不来了**——任务栏有图标，但桌面上什么都没有。

这是因为游戏并没有真的"最小化"，而是把窗口移到了屏幕坐标 `(-21333, -21333)`。这个位置远在屏幕外面，你当然看不到。点击托盘图标时，游戏应该把窗口移回来，但有时候这段逻辑没触发，窗口就永远卡在屏幕外了。

**这个工具做的就是：找到那个卡在屏幕外的窗口，把它拉回来，顺便居中。**

---

## 为什么是 `(-21333, -21333)`？

这是网游客户端的一个老技巧。真正的最小化会让 Windows 销毁窗口的渲染表面（DirectX），恢复时需要重建，会有卡顿。所以很多 MMO 选择**不最小化，只是把窗口藏到你看不到的地方**——渲染管线保持运行，切回来瞬间显示。

坐标 `(-21333, -21333)` 就相当于一个"抽屉"，关托盘就是把窗口塞进去，开托盘就是拿出来。只是这个抽屉有时候会卡住。

---

## 快速开始

**只需两个文件**，放在同一目录下：

- `center_mhxy.bat` —— 启动器
- `center_mhxy.ps1` —— 主脚本

**双击 `.bat`，点「是」授权 UAC，窗口拉回屏幕 + 居中。**

---

## 支持的游戏

| 游戏 | 默认支持 | 进程名 |
|------|:--:|------|
| 梦幻西游 | ✅ | `mhtab`（主窗口）、`mhmain`（登录器） |
| 大话西游 | 改参数 | `dh2` |
| 其他程序 | 改参数 | 例如 `notepad`、`firefox` |

**自定义目标：**

```powershell
.\center_mhxy.ps1 -ProcessName dh2
.\center_mhxy.ps1 -ProcessName notepad,calc
```

也可编辑 `.ps1` 第 1 行改默认值。

---

## 安全性

**不会导致封号。** 脚本只做一件事：调用 Windows 系统 API（`MoveWindow`）移动窗口位置。

- 不读写游戏内存
- 不注入任何代码到游戏进程
- 不修改游戏文件
- 不和反作弊系统交互

等同于手动 Alt+Space → 「移动」→ 拖窗口，只是自动化了。Windows 窗口管理工具用的都是同一套 API，从未有因此被封号的先例。

---

## 系统要求

- Windows 10 或 Windows 11
- 无需安装额外软件（系统自带 PowerShell）
- 游戏若以管理员身份运行，需点一次 UAC 确认

> **macOS / Linux 不适用。** 基于 Windows Win32 API。

---

## 附：Claude Code Skill

本仓库同时包含 [Claude Code](https://claude.ai/code) 技能定义（`SKILL.md`），安装后可直接对话触发。

---

## License

MIT
