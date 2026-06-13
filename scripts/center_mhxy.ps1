param(
    [string[]]$ProcessName = @('mhtab', 'mhmain'),
    [int]$MonitorIndex = 0
)

# ============================================================
#  Game Window Center Tool
#  Default: mhtab/mhmain (MengHuanXiYou client)
#  Usage: powershell -ExecutionPolicy Bypass -File center_mhxy.ps1
#         powershell -ExecutionPolicy Bypass -File center_mhxy.ps1 -ProcessName notepad,calc
# ============================================================

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'Center Game Window'

# ---- Win32 API ----
Add-Type @'
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;
public class W32 {
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWP e, IntPtr l);
    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int m);
    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cw, int ch, uint f);
    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool b);
    public delegate bool EnumWP(IntPtr h, IntPtr l);
    public struct RECT { public int L,T,R,B; }
    public const int SW_RESTORE=9, SW_SHOWNORMAL=1;
    public const uint SWP_SHOWWINDOW=0x0040;
    public static readonly IntPtr HWND_TOP = IntPtr.Zero;
    public class WE { public string T; public IntPtr H; public int P,A,X,Y,W,Ht; }

    public static WE[] FindWindows(int[] pids) {
        var r = new List<WE>();
        var hs = new HashSet<int>(pids);
        EnumWindows(delegate(IntPtr h, IntPtr _) {
            if (!IsWindowVisible(h)) return true;
            uint p=0; GetWindowThreadProcessId(h, out p);
            if (!hs.Contains((int)p)) return true;
            int l = GetWindowTextLength(h);
            if (l > 0) {
                var sb = new StringBuilder(l+1); GetWindowText(h, sb, sb.Capacity);
                RECT rc;
                if (GetWindowRect(h, out rc)) {
                    int w=rc.R-rc.L, ht=rc.B-rc.T;
                    if (w*ht > 5000)
                        r.Add(new WE { T=sb.ToString(), H=h, P=(int)p, X=rc.L, Y=rc.T, W=w, Ht=ht, A=w*ht });
                }
            }
            return true;
        }, IntPtr.Zero);
        return r.ToArray();
    }
}
'@
Add-Type -AssemblyName System.Windows.Forms

# ---- Main ----
Write-Host ''
Write-Host '================================='
Write-Host '  Game Window Center Tool v1.0'
Write-Host '================================='
Write-Host ''

# Collect PIDs
$allPids = New-Object 'System.Collections.Generic.List[int]'
foreach ($pn in $ProcessName) {
    Write-Host "Looking for: $pn"
    $procs = Get-Process -Name $pn -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) { $allPids.Add($p.Id) }
        Write-Host "  Found $($procs.Count) process(es)"
    } else {
        Write-Host '  Not found'
    }
}

if ($allPids.Count -eq 0) {
    Write-Host ''
    Write-Host 'ERROR: Game process not found. Please start the game first.'
    Write-Host "Tried: $($ProcessName -join ', ')"
    Write-Host ''
    Write-Host 'Tip: Right-click this file -> "Run with PowerShell"'
    Write-Host 'Or:  powershell -File center_mhxy.ps1 -ProcessName <name>'
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}

# Find windows
$windows = [W32]::FindWindows($allPids.ToArray()) | Sort-Object A -Descending
if ($windows.Count -eq 0) {
    Write-Host 'ERROR: No visible game window (area > 5000px) found.'
    Read-Host 'Press Enter to exit'
    exit 1
}

# Pick the largest one
$w = $windows[0]
Write-Host ''
Write-Host "Target: $($w.T)"
Write-Host "Size: $($w.W)x$($w.Ht)  Pos: ($($w.X), $($w.Y))"

# Restore if off-screen or minimized
$offScreen = ($w.X -lt -10000 -or $w.Y -lt -10000)
$minimized = [W32]::IsIconic($w.H)
if ($offScreen -or $minimized) {
    $reason = if ($minimized) { 'minimized' } else { 'off-screen' }
    Write-Host "Window is $reason, restoring..."
    [W32]::ShowWindow($w.H, [W32]::SW_RESTORE) | Out-Null
    Start-Sleep -Milliseconds 300
    [W32]::ShowWindow($w.H, [W32]::SW_SHOWNORMAL) | Out-Null
    Start-Sleep -Milliseconds 500
}

# Center
$screen = [System.Windows.Forms.Screen]::AllScreens[$MonitorIndex]
$sw = $screen.Bounds.Width
$sh = $screen.Bounds.Height
$nx = [Math]::Max(0, [int](($sw - $w.W) / 2))
$ny = [Math]::Max(0, [int](($sh - $w.Ht) / 2))

Write-Host "Screen: ${sw}x${sh}"
Write-Host "Target center: ($nx, $ny)"
Write-Host ''

# Move
$null = [W32]::SetWindowPos($w.H, [W32]::HWND_TOP, $nx, $ny, $w.W, $w.Ht, [W32]::SWP_SHOWWINDOW)
Start-Sleep -Milliseconds 200
$null = [W32]::MoveWindow($w.H, $nx, $ny, $w.W, $w.Ht, $true)
Start-Sleep -Milliseconds 200

# Verify
$verify = New-Object W32+RECT
[W32]::GetWindowRect($w.H, [ref]$verify)
$moved = ($verify.L -eq $nx -and $verify.T -eq $ny)
$onScreen = ($verify.L -gt -10000 -and $verify.T -gt -10000)

if ($moved) {
    Write-Host '*** SUCCESS! Window centered. ***'
} elseif ($onScreen) {
    Write-Host "Window moved to ($($verify.L), $($verify.T)). Check screen."
} else {
    Write-Host 'FAILED: Window still off-screen.'
    Write-Host ''
    Write-Host '========================================'
    Write-Host '  Admin rights may be required!'
    Write-Host '========================================'
    Write-Host 'The game likely runs as Administrator, blocking window moves.'
    Write-Host 'Use the .bat launcher (double-click) which auto-elevates.'
    Write-Host ''
}

Write-Host ''
Read-Host 'Press Enter to exit'
