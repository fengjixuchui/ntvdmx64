@echo off
Setlocal EnableDelayedExpansion

if "%1"=="install" goto addappinit
if "%1"=="uninstall" goto delappinit
if "%1"=="instwow" goto instwow
if "%1"=="delwow" goto delwow
if "%1"=="instole" goto instole
if "%1"=="delole" goto delole
if "%1"=="link" goto hardlink

rem Ensure that we are run from 64bit prompt
if "%ProgramFiles(x86)%" == "" goto StartExec
if not exist %SystemRoot%\Sysnative\cmd.exe goto StartExec
%SystemRoot%\Sysnative\cmd.exe /C "%~f0" %*
goto :fini

:StartExec
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
  echo Requesting administrative privileges...
  goto UACPrompt
) else ( goto gotAdmin )
:UACPrompt
echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
"%temp%\getadmin.vbs"
exit /B
:gotAdmin
if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
pushd "%CD%"
CD /D "%~dp0"

echo ---------------------------------------------
echo Checking machine, please wait...
echo ---------------------------------------------
reg query HKLM\Hardware\Description\System\CentralProcessor\0 | Find /i "x86" >nul
if not errorlevel 1 (
  echo You appear to be running this installation on a 32bit machine.
  echo This NTVDMx64 is only meant to be used on an x64 machine, please use 
  echo NTVDM shipped with your windows installation instead.
  echo Installation aborted
  pause
  goto fini
)

for /F "skip=2 tokens=3" %%r in ('reg query HKLM\SYSTEM\CurrentControlSet\Control\SecureBoot\State /v UEFISecureBootEnabled') do if "%%r"=="0x1" (
  echo It seems that your machine has secure boot feature enabled.
  echo This prevents our AppInit_DLL loader from working properly and 
  echo therefore prevents start of NTVDM.
  echo Please disabe secure boot in BIOS, reboot and try again
  start https://msdn.microsoft.com/en-us/windows/hardware/commercialize/manufacture/desktop/disabling-secure-boot
  pause
  goto fini
)

if exist %SYSTEMROOT%\syswow64\ntvdm.exe (
  echo It seems that you have ntvdm.exe already on your system.
  echo I assume that it's NTVDMx64. Before reinstalling ntvdmx64, you should 
  echo uninstall the old version via control panel first.
  pause
  goto fini
)

for /f "tokens=4-5 delims=[.XP " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%"=="5.1" goto ossupp
if "%version%"=="5.2" (
  set VERSION=5.1
  goto ossupp
)
if "%version%"=="6.1" goto ossupp
if "%version%"=="6.2" goto ossupp
if "%version%"=="6.3" goto usew10
if "%version%"=="10.0" goto ossupp
echo Your operating system version %VERSION% is currently not officially supported
echo by the loader code. You can try Windows 7 loader at your own risk by pressing
echo any key to continue. Otherwise please quit now (CTRL+C)
pause
set VERSION=6.1
goto ossupp
:usew10
set VERSION=10.0
:ossupp
copy /y ldntvdm\system32\%VERSION%\ldntvdm.dll ldntvdm\system32\
copy /y ldntvdm\syswow64\%VERSION%\ldntvdm.dll ldntvdm\syswow64\

cls
echo ---------------------------------------------
echo Installing, please wait...
echo ---------------------------------------------
echo Please check for completion-message from installer in taskbar.
if exist haxm\IntelHaxm.sys RUNDLL32 SETUPAPI.DLL,InstallHinfSection DefaultInstall 132 %CD%\ntvdmx64-haxm.inf

echo [*] Trying to download necessary debug symbols
util\symfetch %SYSTEMROOT%\system32\kernel32.dll
util\symfetch %SYSTEMROOT%\syswow64\kernel32.dll
if not "%version%"=="5.1" util\symfetch %SYSTEMROOT%\system32\appinfo.dll
if "%version%"=="6.1" util\symfetch %SYSTEMROOT%\system32\conhost.exe

if "%version%"=="5.1" goto nodefender
echo [*] Adding Loader to Windows Defender exclusion list, as there are always false positives...
set "DefExclusion=%SystemRoot%\system32\ldntvdm.dll"
powershell -noprofile -command Add-MpPreference -Force -ExclusionPath "$env:DefExclusion" >nul
set "DefExclusion=%SystemRoot%\syswow64\ldntvdm.dll"
powershell -noprofile -command Add-MpPreference -Force -ExclusionPath "$env:DefExclusion" >nul

:nodefender
echo [*] Installing components
rundll32.exe advpack.dll,LaunchINFSection %CD%\ntvdmx64.inf
goto fini

:addappinit
set AppInit=
for /F "skip=2 tokens=2*" %%r in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs') do set AppInit=%AppInit%%%s
echo %AppInit% | findstr /I /C:ldntvdm.dll >nul
if errorlevel 1 reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /f /d "%AppInit% ldntvdm.dll"
set AppInit=
for /F "skip=2 tokens=2*" %%r in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs') do set AppInit=%AppInit%%%s
echo %AppInit% | findstr /I /C:ldntvdm.dll >nul
if errorlevel 1 reg add "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /f /d "%AppInit% ldntvdm.dll"
set AppInit=
goto fini

:delappinit
set AppInit=
for /F "skip=2 tokens=2*" %%r in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs') do (
  for %%t in (%%s) do if not "%%t"=="ldntvdm.dll" set AppInit=!AppInit!%%t 
)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /f /d "%AppInit%"
set AppInit=
for /F "skip=2 tokens=2*" %%r in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs') do (
  for %%t in (%%s) do if not "%%t"=="ldntvdm.dll" set AppInit=!AppInit!%%t 
)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows NT\CurrentVersion\Windows" /v AppInit_DLLs /f /d "%AppInit%"
set AppInit=

if exist %windir%\inf\wow32.inf RunDll32 advpack.dll,LaunchINFSection %windir%\inf\wow32.inf,DefaultUninstall
if exist %windir%\inf\ntvdmdbg.inf RunDll32 advpack.dll,LaunchINFSection %windir%\inf\ntvdmdbg.inf,DefaultUninstall
if exist %windir%\inf\ntvdmx64-haxm.inf RUNDLL32 SETUPAPI.DLL,InstallHinfSection DefaultUninstall 132 %windir%\inf\ntvdmx64-haxm.inf
goto fini

:instwow
rem Windows XP SFP 
for %%I in (gdi.exe user.exe wow32.dll wowexec.exe comm.drv keyboard.drv lanman.drv mouse.drv sound.drv system.drv timer.drv vga.drv wfwnet.drv) do util\wfpreplace %2\%%I
md %3
for %%F in (wow32.dll user.exe) do call :replsysfil %%F %2 %3
if exist %CD%\ole2\olethk32.dll (
  for /f "tokens=4-5 delims=[.XP " %%i in ('ver') do (
    if %%i GEQ 6 (
      rem only on Win 8 or above
      if %%i EQU 6 if %%j LSS 3 goto fini
      rundll32.exe advpack.dll,LaunchINFSection %CD%\ole2.inf
    )
  )
)
goto fini

:delwow
for %%F in (wow32.dll user.exe) do if exist %3\%%I move /y %3\%%I %2\
if exist %windir%\inf\ole2.inf RunDll32 advpack.dll,LaunchINFSection %windir%\inf\ole2.inf,DefaultUninstall
goto fini

:instole
for %%F in (olethk32.dll compobj.dll ole2.dll ole2disp.dll ole2nls.dll storage.dll typelib.dll) do call :replsysfil %%F %2 %3
goto fini

:delole
for %%F in (olethk32.dll compobj.dll ole2.dll ole2disp.dll ole2nls.dll storage.dll typelib.dll) do if exist %3\%%I move /y %3\%%I %2\
goto fini

:hardlink
if exist %2\%4 del %2\%4
if exist %2\%4 echo %2\%4 is in use, please delete manually and then install again
fsutil hardlink create %2\%4 %3\%4 
goto fini

:replsysfil
if not exist %3\%1 (
  takeown /f %2\%1
  cacls %2\%1 /e /p %USERNAME%:F
  move %2\%1 %3\
)
exit /B

:fini
exit /b
