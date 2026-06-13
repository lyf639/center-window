# Center Window

双击一键将梦幻西游（或其他程序）窗口移到屏幕正中央。

## 怎么用

1. 把 `center_mhxy.bat` 和 `center_mhxy.ps1` 放到同一个文件夹
2. **双击 `center_mhxy.bat`**
3. 弹出 UAC 点「是」
4. 完成

就这么简单。不需要 Claude，不需要安装任何东西，Windows 自带 PowerShell 就能跑。

## 原理

梦幻西游以管理员身份运行，普通程序无法移动它的窗口。脚本会自动检测权限、不够就提权，然后用 Win32 API 把窗口移到正中央。

窗口如果在"离屏"状态（游戏最小化到托盘时会把窗口藏到屏幕外 `-21333` 的位置），脚本会先恢复再居中。

## 自定义

默认目标是梦幻西游（`mhtab` + `mhmain` 进程）。要居中其他程序，命令行传参：

```powershell
.\center_mhxy.ps1 -ProcessName notepad
.\center_mhxy.ps1 -ProcessName calc,firefox
```

或者修改 `.ps1` 第 1 行 `$ProcessName` 的默认值。

## 常见游戏进程名

| 游戏 | 进程名 |
|------|--------|
| 梦幻西游 | `mhtab`（主窗口）、`mhmain`（登录器） |
| 大话西游 | `dh2` |

## 系统要求

- Windows 10 / 11
- 游戏以管理员身份运行时需要 UAC 授权
- **不兼容 macOS / Linux**（Windows 专属 Win32 API）

## License

MIT
