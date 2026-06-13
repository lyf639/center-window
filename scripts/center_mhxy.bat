@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

:: ============================================================
::  Game Window Center Tool - double-click to center MHXY
:: ============================================================
title Game Window Center

:: ---- Auto-elevate ----
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting admin rights...
    powershell -Command "Start-Process '%~f0' -Verb RunAs -WorkingDirectory '%~dp0'" 2>nul
    exit /b
)

:: ---- Extract PowerShell script to temp ----
set "TMPPS=%TEMP%\center_game.ps1"
powershell -Command "[System.IO.File]::WriteAllText('%TMPPS%', (Get-Content '%~f0' -Encoding UTF8 | Select-String -Pattern '^::PS::' | ForEach-Object { $_ -replace '^::PS::','' }) -join \"`r`n\", [System.Text.UTF8Encoding]::new(`$true))"

:: ---- Run it ----
powershell -ExecutionPolicy Bypass -File "%TMPPS%" %*

:: ---- Cleanup ----
del "%TMPPS%" 2>nul
exit /b

::PS::param([string[]]$ProcessName=@('mhtab','mhmain'),[int]$MonitorIndex=0)
::PS::$ErrorActionPreference='Continue'
::PS::$Host.UI.RawUI.WindowTitle='Center Game Window'
::PS::Add-Type @'
::PS::using System;
::PS::using System.Runtime.InteropServices;
::PS::using System.Text;
::PS::using System.Collections.Generic;
::PS::public class W32 {
::PS::    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);
::PS::    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWP e, IntPtr l);
::PS::    [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int m);
::PS::    [DllImport("user32.dll")] public static extern int GetWindowTextLength(IntPtr h);
::PS::    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
::PS::    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
::PS::    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
::PS::    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
::PS::    [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr a, int x, int y, int cw, int ch, uint f);
::PS::    [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool b);
::PS::    public delegate bool EnumWP(IntPtr h, IntPtr l);
::PS::    public struct RECT { public int L,T,R,B; }
::PS::    public const int SW_RESTORE=9, SW_SHOWNORMAL=1;
::PS::    public const uint SWP_SHOWWINDOW=0x0040;
::PS::    public static readonly IntPtr HWND_TOP=IntPtr.Zero;
::PS::    public class WE { public string T; public IntPtr H; public int P,A,X,Y,W,Ht; }
::PS::    public static WE[] FindWindows(int[] pids) {
::PS::        var r=new List<WE>();
::PS::        var hs=new HashSet<int>(pids);
::PS::        EnumWindows(delegate(IntPtr h,IntPtr _) {
::PS::            if(!IsWindowVisible(h)) return true;
::PS::            uint p=0;GetWindowThreadProcessId(h,out p);
::PS::            if(!hs.Contains((int)p)) return true;
::PS::            int l=GetWindowTextLength(h);
::PS::            if(l>0){var sb=new StringBuilder(l+1);GetWindowText(h,sb,sb.Capacity);
::PS::                RECT rc;if(GetWindowRect(h,out rc)){
::PS::                    int w=rc.R-rc.L,ht=rc.B-rc.T;
::PS::                    if(w*ht>5000) r.Add(new WE{T=sb.ToString(),H=h,P=(int)p,X=rc.L,Y=rc.T,W=w,Ht=ht,A=w*ht});
::PS::                }
::PS::            }
::PS::            return true;
::PS::        },IntPtr.Zero);
::PS::        return r.ToArray();
::PS::    }
::PS::}
::PS::'@
::PS::Add-Type -AssemblyName System.Windows.Forms
::PS::Write-Host ''
::PS::Write-Host '================================='
::PS::Write-Host '  Game Window Center Tool v2.0'
::PS::Write-Host '================================='
::PS::Write-Host ''
::PS::$allPids=New-Object 'System.Collections.Generic.List[int]'
::PS::foreach($pn in $ProcessName){
::PS::    Write-Host "Looking for: $pn"
::PS::    $procs=Get-Process -Name $pn -ErrorAction SilentlyContinue
::PS::    if($procs){foreach($p in $procs){$allPids.Add($p.Id)};Write-Host "  Found $($procs.Count) process(es)"}
::PS::    else{Write-Host '  Not found'}
::PS::}
::PS::if($allPids.Count -eq 0){
::PS::    Write-Host 'ERROR: Game not running.'
::PS::    Write-Host "Tried: $($ProcessName -join ', ')"
::PS::    Read-Host 'Press Enter to exit';exit 1
::PS::}
::PS::$windows=[W32]::FindWindows($allPids.ToArray())|Sort-Object A -Descending
::PS::if($windows.Count -eq 0){Write-Host 'ERROR: No visible game window.';Read-Host 'Press Enter to exit';exit 1}
::PS::$w=$windows[0]
::PS::Write-Host "Target: $($w.T)"
::PS::Write-Host "Size: $($w.W)x$($w.Ht)  Pos: ($($w.X),$($w.Y))"
::PS::$offScreen=($w.X -lt -10000 -or $w.Y -lt -10000)
::PS::$minimized=[W32]::IsIconic($w.H)
::PS::if($offScreen -or $minimized){
::PS::    $reason=if($minimized){'minimized'}else{'off-screen'}
::PS::    Write-Host "Window is $reason, restoring..."
::PS::    [W32]::ShowWindow($w.H,9)|Out-Null;Start-Sleep -Milliseconds 300
::PS::    [W32]::ShowWindow($w.H,1)|Out-Null;Start-Sleep -Milliseconds 500
::PS::}
::PS::$screen=[System.Windows.Forms.Screen]::AllScreens[$MonitorIndex]
::PS::$sw=$screen.Bounds.Width;$sh=$screen.Bounds.Height
::PS::$nx=[Math]::Max(0,[int](($sw-$w.W)/2))
::PS::$ny=[Math]::Max(0,[int](($sh-$w.Ht)/2))
::PS::Write-Host "Screen: ${sw}x${sh}  ->  Center: ($nx,$ny)"
::PS::$null=[W32]::SetWindowPos($w.H,[W32]::HWND_TOP,$nx,$ny,$w.W,$w.Ht,[W32]::SWP_SHOWWINDOW)
::PS::Start-Sleep -Milliseconds 200
::PS::$null=[W32]::MoveWindow($w.H,$nx,$ny,$w.W,$w.Ht,$true)
::PS::Start-Sleep -Milliseconds 200
::PS::$verify=New-Object W32+RECT;[W32]::GetWindowRect($w.H,[ref]$verify)
::PS::$moved=($verify.L -eq $nx -and $verify.T -eq $ny)
::PS::$onScreen=($verify.L -gt -10000 -and $verify.T -gt -10000)
::PS::if($moved){Write-Host '*** SUCCESS! Window centered. ***'}
::PS::elseif($onScreen){Write-Host "Window moved to ($($verify.L),$($verify.T)). Check screen."}
::PS::else{Write-Host 'FAILED: Game blocks window move (admin vs admin mismatch?).'}
::PS::Write-Host '';Read-Host 'Press Enter to exit'
