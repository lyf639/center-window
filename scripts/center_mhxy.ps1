param(
    [string[]]$ProcessName = @('mhtab', 'mhmain'),
    [int]$MonitorIndex = 0
)

$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'Center Game Window'

# ---- Win32 API (minimal) ----
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

# ---- Find game ----
Write-Host "`n=== Center Game Window ==="

$allPids = New-Object 'System.Collections.Generic.List[int]'
foreach ($pn in $ProcessName) {
    $procs = Get-Process -Name $pn -ErrorAction SilentlyContinue
    if ($procs) { foreach ($p in $procs) { $allPids.Add($p.Id) } }
}

if ($allPids.Count -eq 0) {
    Write-Host "Game not running. Tried: $($ProcessName -join ', ')"
    Read-Host 'Press Enter'; exit 1
}

$windows = [W32]::FindWindows($allPids.ToArray()) | Sort-Object A -Descending
if ($windows.Count -eq 0) { Write-Host "No visible game window."; Read-Host 'Press Enter'; exit 1 }

$w = $windows[0]
Write-Host "Found: $($w.W)x$($w.Ht) at ($($w.X),$($w.Y))"

# ---- Restore if needed ----
if ($w.X -lt -10000 -or $w.Y -lt -10000 -or [W32]::IsIconic($w.H)) {
    Write-Host "Restoring..."
    [W32]::ShowWindow($w.H, [W32]::SW_RESTORE) | Out-Null
    Start-Sleep -Milliseconds 300
    [W32]::ShowWindow($w.H, [W32]::SW_SHOWNORMAL) | Out-Null
    Start-Sleep -Milliseconds 500
}

# ---- Center ----
$sw = [System.Windows.Forms.Screen]::AllScreens[$MonitorIndex].Bounds.Width
$sh = [System.Windows.Forms.Screen]::AllScreens[$MonitorIndex].Bounds.Height
$nx = [Math]::Max(0, [int](($sw - $w.W) / 2))
$ny = [Math]::Max(0, [int](($sh - $w.Ht) / 2))

# Key trick: minimize first, then move, then restore.
# The game's anti-move hook is less aggressive when minimized.
[W32]::ShowWindow($w.H, 6) | Out-Null          # SW_MINIMIZE
Start-Sleep -Milliseconds 400
[W32]::MoveWindow($w.H, $nx, $ny, $w.W, $w.Ht, $false) | Out-Null  # move silently, no repaint
Start-Sleep -Milliseconds 300
[W32]::ShowWindow($w.H, [W32]::SW_RESTORE) | Out-Null  # restore at new position
Start-Sleep -Milliseconds 500

# Verify with actual pixel position (not API return value)
$r = New-Object W32+RECT
[W32]::GetWindowRect($w.H, [ref]$r)

if ($r.L -eq $nx -and $r.T -eq $ny) {
    Write-Host "Centered at ($nx,$ny)"
} elseif ($r.L -gt -10000 -and $r.T -gt -10000) {
    Write-Host "Moved to ($($r.L),$($r.T)). Re-run if not centered."
} else {
    Write-Host "Still off-screen. Right-click bat -> Run as administrator."
}

Read-Host 'Press Enter'
