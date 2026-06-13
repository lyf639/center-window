param(
    [string[]]$ProcessName = @('mhtab', 'mhmain'),
    [int]$MonitorIndex = 0
)

# ============================================================
#  Game Window Center Tool
#  Default target: mhtab / mhmain (MengHuanXiYou)
# ============================================================

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'Center Game Window'

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

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
    [DllImport("user32.dll")] public static extern bool GetWindowPlacement(IntPtr h, ref WPLACEMENT wp);
    [DllImport("user32.dll")] public static extern bool SetWindowPlacement(IntPtr h, ref WPLACEMENT wp);
    public delegate bool EnumWP(IntPtr h, IntPtr l);
    public struct RECT { public int L,T,R,B; }
    public struct POINT { public int X,Y; }
    public struct WPLACEMENT { public uint length; public uint flags; public uint showCmd; public POINT ptMin; public POINT ptMax; public RECT rcNormal; }
    public const int SW_RESTORE=9, SW_SHOWNORMAL=1, SW_MINIMIZE=6;
    public const uint SWP_SHOWWINDOW=0x0040;
    public static readonly IntPtr HWND_TOP=IntPtr.Zero;
    public class WE { public string T; public IntPtr H; public int P,A,X,Y,W,Ht; }
    public static WE[] FindWindows(int[] pids) {
        var r=new List<WE>();
        var hs=new HashSet<int>(pids);
        EnumWindows(delegate(IntPtr h,IntPtr _) {
            if(!IsWindowVisible(h)) return true;
            uint p=0;GetWindowThreadProcessId(h,out p);
            if(!hs.Contains((int)p)) return true;
            int l=GetWindowTextLength(h);
            if(l>0){var sb=new StringBuilder(l+1);GetWindowText(h,sb,sb.Capacity);
                RECT rc;if(GetWindowRect(h,out rc)){
                    int w=rc.R-rc.L,ht=rc.B-rc.T;
                    if(w*ht>5000) r.Add(new WE{T=sb.ToString(),H=h,P=(int)p,X=rc.L,Y=rc.T,W=w,Ht=ht,A=w*ht});
                }
            }
            return true;
        },IntPtr.Zero);
        return r.ToArray();
    }
}
'@
Add-Type -AssemblyName System.Windows.Forms

# ---- Main ----
Write-Host "`n================================="
Write-Host "  Game Window Center Tool v2.1"
if ($isAdmin) { Write-Host "  [Running as Administrator]" }
Write-Host "=================================`n"

# Collect PIDs
$allPids = New-Object 'System.Collections.Generic.List[int]'
foreach ($pn in $ProcessName) {
    Write-Host "Looking for: $pn"
    $procs = Get-Process -Name $pn -ErrorAction SilentlyContinue
    if ($procs) {
        foreach ($p in $procs) { $allPids.Add($p.Id) }
        Write-Host "  Found $($procs.Count) process(es)"
    } else {
        Write-Host "  Not found"
    }
}

if ($allPids.Count -eq 0) {
    Write-Host "`nERROR: Game not running."
    Write-Host "Tried: $($ProcessName -join ', ')"
    Write-Host "`nTip: Start the game first, then run this tool."
    Write-Host "If the game IS running, try: -ProcessName <other name>"
    Read-Host 'Press Enter to exit'
    exit 1
}

# Find windows
$windows = [W32]::FindWindows($allPids.ToArray()) | Sort-Object A -Descending
if ($windows.Count -eq 0) {
    Write-Host "ERROR: No visible game window (min area=5000px)."
    Read-Host 'Press Enter to exit'
    exit 1
}

# Pick the largest window
$w = $windows[0]
Write-Host "`nTarget: $($w.T)"
Write-Host "Size: $($w.W)x$($w.Ht)  Pos: ($($w.X), $($w.Y))"

# Restore if needed
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
Write-Host "Target center: ($nx, $ny)`n"

# Move - Strategy: SetWindowPlacement + minimize/restore bypasses game hooks
Write-Host "Centering..."
$moved = $false

# Method 1: SetWindowPlacement (sets the "restored" position)
$wp = New-Object W32+WPLACEMENT
$wp.length = [System.Runtime.InteropServices.Marshal]::SizeOf($wp)
$null = [W32]::GetWindowPlacement($w.H, [ref]$wp)
$wp.rcNormal.L = $nx
$wp.rcNormal.T = $ny
$wp.rcNormal.R = $nx + $w.W
$wp.rcNormal.B = $ny + $w.Ht
$null = [W32]::SetWindowPlacement($w.H, [ref]$wp)

# If window is already in restored state, toggle min/restore to apply placement
[W32]::ShowWindow($w.H, [W32]::SW_MINIMIZE) | Out-Null
Start-Sleep -Milliseconds 300
[W32]::ShowWindow($w.H, [W32]::SW_RESTORE) | Out-Null
Start-Sleep -Milliseconds 500

# Verify
$verify = New-Object W32+RECT
[W32]::GetWindowRect($w.H, [ref]$verify)
$moved = ($verify.L -eq $nx -and $verify.T -eq $ny)

# Method 2: If placement didn't work, try raw SetWindowPos + MoveWindow
if (-not $moved) {
    Write-Host "Placement method failed, trying direct move..."
    $null = [W32]::SetWindowPos($w.H, [W32]::HWND_TOP, $nx, $ny, $w.W, $w.Ht, [W32]::SWP_SHOWWINDOW)
    Start-Sleep -Milliseconds 200
    $null = [W32]::MoveWindow($w.H, $nx, $ny, $w.W, $w.Ht, $true)
    Start-Sleep -Milliseconds 200
    [W32]::GetWindowRect($w.H, [ref]$verify)
    $moved = ($verify.L -eq $nx -and $verify.T -eq $ny)
}

# Method 3: If still not moved, try ShowWindow hide/show cycle
if (-not $moved) {
    Write-Host "Direct move failed, trying show/hide cycle..."
    [W32]::ShowWindow($w.H, 0) | Out-Null  # SW_HIDE
    Start-Sleep -Milliseconds 200
    [W32]::MoveWindow($w.H, $nx, $ny, $w.W, $w.Ht, $true) | Out-Null
    [W32]::ShowWindow($w.H, [W32]::SW_SHOWNORMAL) | Out-Null
    Start-Sleep -Milliseconds 500
    [W32]::GetWindowRect($w.H, [ref]$verify)
    $moved = ($verify.L -eq $nx -and $verify.T -eq $ny)
}

$onScreen = ($verify.L -gt -10000 -and $verify.T -gt -10000)

if ($moved) {
    Write-Host '*** SUCCESS! Window centered. ***'
} elseif ($onScreen) {
    Write-Host "Window at ($($verify.L), $($verify.T)). Not centered."
    if (-not $isAdmin) {
        Write-Host "`n========================================"
        Write-Host "  ADMIN RIGHTS REQUIRED"
        Write-Host "========================================"
        Write-Host "The game runs as Administrator and blocks"
        Write-Host "window moves from normal programs."
        Write-Host "`nSOLUTION: Right-click center_mhxy.bat"
        Write-Host "          -> Run as administrator"
        Write-Host "========================================"
    } else {
        Write-Host "Game is actively blocking window moves."
        Write-Host "Try: switch the game to windowed mode first."
    }
} else {
    Write-Host "FAILED: Window still off-screen."
    if (-not $isAdmin) {
        Write-Host "Right-click center_mhxy.bat -> Run as administrator"
    }
}

Write-Host ""
Read-Host 'Press Enter to exit'
