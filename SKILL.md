---
name: center-window
description: Center any window on the screen. Use when the user wants to move a window to the center, reposition a game client, center a program window, or asks to "把窗口移到屏幕中间" / "居中窗口" / "center the window". Supports locating windows by process name or title keywords.
---

# Center Window

将指定窗口移动到主屏幕正中央。

## When to use

Trigger when the user asks to:
- Center/move a window to the middle of the screen
- "把XXX移到屏幕中间" / "居中" / "窗口居中"
- Reposition a game client, application, or any visible window

## How it works

Uses a bundled PowerShell script (`scripts/center_window.ps1`) that:
1. Finds the target window by **process name** (most reliable) or **window title keyword**
2. Restores the window if minimized or off-screen
3. Calculates the center position based on the primary screen
4. Moves the window via Win32 `SetWindowPos` / `MoveWindow`

## Parameters

| Parameter | Description |
|-----------|-------------|
| `-ProcessName` | Process name(s) without `.exe`, e.g. `mhtab`, `notepad` |
| `-TitleKeyword` | Keyword to match in window title (UTF-8 aware) |
| `-MonitorIndex` | Target monitor (0 = primary, default) |

## Usage instructions

### Step 1: Identify the window

If the user doesn't know the process name, first run the script in **list mode** to show all visible windows:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-path>/scripts/center_window.ps1" -List
```

Present the relevant windows to the user and let them pick.

### Step 2: Center the window

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-path>/scripts/center_window.ps1" -ProcessName "mhtab"
```

Or by title keyword:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-path>/scripts/center_window.ps1" -TitleKeyword "梦幻"
```

### Step 3: If MoveWindow fails

The script detects failure and reports it. If the window stays off-screen or unmoved, the target process likely runs with **administrator privileges** and blocks external window manipulation. In that case:

```powershell
Start-Process powershell -Verb RunAs -ArgumentList '-ExecutionPolicy Bypass -File "<skill-path>/scripts/center_window.ps1" -ProcessName "xxx"'
```

## Common process names for Chinese games

| Game | Process Name |
|------|-------------|
| 梦幻西游 | `mhtab` (main), `mhmain` (login) |
| 大话西游 | `dh2` |

## Troubleshooting

- **Window not found**: Use `-List` to see all windows, then identify the correct process name or title
- **Position stays at (-21333, -21333)**: Window is deliberately hidden off-screen. Use elevated PowerShell.
- **MoveWindow returns false**: Game likely has anti-manipulation protection. Try `-Verb RunAs`.
- **Encoding issues with Chinese titles**: Pass keywords via `-TitleKeyword` parameter (handles encoding correctly) rather than hardcoding in the script.
