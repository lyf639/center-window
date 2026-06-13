param(
    [string[]]$ProcessName,
    [string]$TitleKeyword,
    [switch]$List,
    [int]$MonitorIndex = 0
)

# ============================================================
# Center Window - Move any window to the center of the screen
# ============================================================

$ErrorActionPreference = "Continue"

# ---- Win32 API definitions ----
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;

public class WinAPI {
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);

    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

    [DllImport("user32.dll")]
    public static extern bool GetWindowRect(IntPtr hWnd, out RECT lpRect);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool MoveWindow(IntPtr hWnd, int X, int Y, int nWidth, int nHeight, bool bRepaint);

    public static readonly IntPtr HWND_TOP = new IntPtr(0);
    public const int SW_SHOWNORMAL = 1;
    public const int SW_RESTORE = 9;
    public const uint SWP_SHOWWINDOW = 0x0040;

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    [StructLayout(LayoutKind.Sequential)]
    public struct RECT { public int Left, Top, Right, Bottom; }

    public class WindowEntry {
        public string Title;
        public IntPtr Hwnd;
        public int ProcessId;
        public int Area;
        public int X, Y, W, H;
    }

    public static List<WindowEntry> FindVisibleWindows() {
        var results = new List<WindowEntry>();
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (!IsWindowVisible(hWnd)) return true;
            uint pid = 0;
            GetWindowThreadProcessId(hWnd, out pid);
            int len = GetWindowTextLength(hWnd);
            if (len > 0) {
                var sb = new StringBuilder(len + 1);
                GetWindowText(hWnd, sb, sb.Capacity);
                string title = sb.ToString();
                if (title.Length > 0) {
                    RECT r;
                    if (GetWindowRect(hWnd, out r)) {
                        int w = r.Right - r.Left;
                        int h = r.Bottom - r.Top;
                        results.Add(new WindowEntry {
                            Title = title, Hwnd = hWnd, ProcessId = (int)pid,
                            X = r.Left, Y = r.Top, W = w, H = h, Area = w * h
                        });
                    }
                }
            }
            return true;
        }, IntPtr.Zero);
        return results;
    }

    public static bool CenterWindow(IntPtr hWnd, int sw, int sh) {
        RECT r;
        if (!GetWindowRect(hWnd, out r)) return false;
        int w = r.Right - r.Left;
        int h = r.Bottom - r.Top;
        int nx = Math.Max(0, (sw - w) / 2);
        int ny = Math.Max(0, (sh - h) / 2);

        // Try SetWindowPos first
        if (SetWindowPos(hWnd, HWND_TOP, nx, ny, w, h, SWP_SHOWWINDOW)) return true;

        // Fallback to MoveWindow
        return MoveWindow(hWnd, nx, ny, w, h, true);
    }
}
'@

# ---- Helper: get process name from PID ----
function Get-ProcName($procId) {
    try { return (Get-Process -Id $procId -ErrorAction Stop).ProcessName }
    catch { return "N/A" }
}

# ---- Helper: resolve monitor ----
function Get-MonitorSize($index) {
    Add-Type -AssemblyName System.Windows.Forms
    $screens = [System.Windows.Forms.Screen]::AllScreens
    if ($index -ge 0 -and $index -lt $screens.Count) {
        $b = $screens[$index].Bounds
        return @{ W = $b.Width; H = $b.Height }
    }
    $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    return @{ W = $b.Width; H = $b.Height }
}

# ============================================================
# LIST MODE
# ============================================================
if ($List) {
    Write-Host "`n=== All Visible Windows (sorted by size) ===`n"
    $all = [WinAPI]::FindVisibleWindows() | Where-Object { $_.Area -gt 0 } | Sort-Object Area -Descending
    $i = 0
    foreach ($w in $all) {
        if ($i++ -ge 50) { Write-Host "... (truncated, $($all.Count) total)"; break }
        $pn = Get-ProcName $w.ProcessId
        $posInfo = if ($w.X -lt -1000 -or $w.Y -lt -1000) { "OFFSCREEN" } else { "$($w.X),$($w.Y)" }
        Write-Host ("[{0}:{1}] '{2}' {3}x{4} pos=({5})" -f $w.ProcessId, $pn, $w.Title, $w.W, $w.H, $posInfo)
    }
    exit 0
}

# ============================================================
# FIND TARGET WINDOW
# ============================================================
$allVisible = [WinAPI]::FindVisibleWindows()
$candidates = @()

if ($ProcessName) {
    foreach ($pname in $ProcessName) {
        $procs = Get-Process -Name $pname -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            $matches = $allVisible | Where-Object { $_.ProcessId -eq $p.Id -and $_.Area -gt 10000 }
            $candidates += $matches
        }
    }
}

if ($TitleKeyword -and $candidates.Count -eq 0) {
    $candidates = $allVisible | Where-Object {
        $_.Title -match [regex]::Escape($TitleKeyword) -and $_.Area -gt 10000
    }
}

if ($candidates.Count -eq 0) {
    Write-Host "ERROR: No matching windows found."
    if ($ProcessName) { Write-Host "Process names tried: $($ProcessName -join ', ')" }
    if ($TitleKeyword) { Write-Host "Title keyword: $TitleKeyword" }
    Write-Host "`nTop visible windows:"
    $allVisible | Where-Object { $_.Area -gt 5000 } | Sort-Object Area -Descending | Select-Object -First 15 | ForEach-Object {
        $pn = Get-ProcName $_.ProcessId
        Write-Host ("  [{0}:{1}] '{2}' {3}x{4}" -f $_.ProcessId, $pn, $_.Title, $_.W, $_.H)
    }
    Write-Host "`nTip: Use -List to see all windows, or try -ProcessName with the process name from the list above."
    exit 1
}

# Pick the largest candidate
$target = $candidates | Sort-Object Area -Descending | Select-Object -First 1
$pn = Get-ProcName $target.ProcessId

Write-Host ("Found: [{0}:{1}] '{2}'" -f $target.ProcessId, $pn, $target.Title)
Write-Host ("Current: {0}x{1} at ({2},{3})" -f $target.W, $target.H, $target.X, $target.Y)

# ============================================================
# RESTORE IF MINIMIZED OR OFF-SCREEN
# ============================================================
$isOffscreen = ($target.X -lt -10000 -or $target.Y -lt -10000)
$isMinimized = [WinAPI]::IsIconic($target.Hwnd)

if ($isMinimized -or $isOffscreen) {
    $reason = if ($isMinimized) { "minimized" } else { "off-screen" }
    Write-Host "Window is $reason. Restoring..."
    [WinAPI]::ShowWindow($target.Hwnd, [WinAPI]::SW_RESTORE)
    Start-Sleep -Milliseconds 200
    [WinAPI]::ShowWindow($target.Hwnd, [WinAPI]::SW_SHOWNORMAL)
    Start-Sleep -Milliseconds 500
}

# ============================================================
# CENTER THE WINDOW
# ============================================================
$mon = Get-MonitorSize $MonitorIndex
Write-Host ("Screen: {0}x{1}" -f $mon.W, $mon.H)
Write-Host "Centering..."

$ok = [WinAPI]::CenterWindow($target.Hwnd, $mon.W, $mon.H)
Start-Sleep -Milliseconds 200

# Verify
$verify = $allVisible | Where-Object { $_.Hwnd -eq $target.Hwnd } | Select-Object -First 1
if ($verify) {
    $expectedX = [Math]::Max(0, [int](($mon.W - $verify.W) / 2))
    $expectedY = [Math]::Max(0, [int](($mon.H - $verify.H) / 2))
    $moved = ($verify.X -eq $expectedX -and $verify.Y -eq $expectedY)
    $onScreen = ($verify.X -gt -10000 -and $verify.Y -gt -10000)

    Write-Host ("Result: {0}x{1} at ({2},{3})" -f $verify.W, $verify.H, $verify.X, $verify.Y)

    if ($moved) {
        Write-Host "SUCCESS: Window centered."
    } elseif ($onScreen) {
        Write-Host "PARTIAL: Window moved but not exactly centered. Check visually."
    } else {
        Write-Host "FAILED: Window still off-screen. The process may run with admin privileges."
        Write-Host "Try running this script elevated:"
        Write-Host "  Start-Process powershell -Verb RunAs -ArgumentList '-File `"$PSCommandPath`" -ProcessName `"$($ProcessName[0])`"'"
        exit 1
    }
} else {
    Write-Host "Done (unable to verify). Check the window visually."
}
