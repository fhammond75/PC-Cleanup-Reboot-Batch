@echo off
setlocal EnableDelayedExpansion
title NUKE IT FROM ORBIT
goto :main

:: ================================================================
::  Subroutine: cleandir  %1=display label  %2=path
::  Placed before :main so the label scanner finds it immediately.
:: ================================================================
:cleandir
set "CD_LABEL=%~1"
set "CD_PATH=%~2"
set "CD_DEL=0"
set "CD_SKIP=0"
<nul set /p "=  %CYN%[-]%RST%  %CD_LABEL%  "
if not exist "%CD_PATH%" (
    echo %DIM%not found, skipped%RST%
    echo !CD_LABEL!: not found >> "%LOGFILE%"
    goto :eof
)
for /r "%CD_PATH%" %%F in (*) do (
    del /f /q "%%F" >nul 2>&1
    if "!errorlevel!"=="0" (set /a CD_DEL+=1) else (set /a CD_SKIP+=1)
)
for /d /r "%CD_PATH%" %%D in (*) do rd "%%D" >nul 2>&1
echo %GRN%!CD_DEL! deleted%RST%  %DIM%!CD_SKIP! skipped%RST%
set /a TOTAL_DEL+=CD_DEL
set /a TOTAL_SKIP+=CD_SKIP
echo !CD_LABEL!: !CD_DEL! deleted, !CD_SKIP! skipped >> "%LOGFILE%"
goto :eof

:: ================================================================
:main
:: ================================================================

:: -- ANSI color setup --------------------------------------------
for /f "usebackq" %%a in (`powershell -NoProfile -Command "[char]27"`) do set "ESC=%%a"
if defined ESC (
    set "RST=!ESC![0m"
    set "BLD=!ESC![1m"
    set "DIM=!ESC![2m"
    set "GRN=!ESC![92m"
    set "YLW=!ESC![93m"
    set "CYN=!ESC![96m"
    set "WHT=!ESC![97m"
)

cls
echo.
echo %BLD%%CYN%  +=============================================+%RST%
echo %BLD%%CYN%  ^|           NUKE IT FROM ORBIT               ^|%RST%
echo %BLD%%CYN%  ^|      it's the only way to be sure.         ^|%RST%
echo %BLD%%CYN%  +=============================================+%RST%
echo.

:: -- Admin check -------------------------------------------------
set "IS_ADMIN=0"
fsutil dirty query %SystemDrive% >nul 2>&1
if not errorlevel 1 set "IS_ADMIN=1"

if "%IS_ADMIN%"=="1" (
    echo %GRN%  [+] Running as Administrator - full cleanup enabled.%RST%
) else (
    echo %YLW%  [!] Not running as Administrator.%RST%
    echo %DIM%      Prefetch cache will be skipped.%RST%
    echo %DIM%      Right-click and select "Run as administrator" for full cleanup.%RST%
)
echo.

:: -- What will be cleaned ----------------------------------------
echo %WHT%  Cleanup targets:%RST%
echo %DIM%    User Temp           ^(%TEMP%^)%RST%
echo %DIM%    Windows Temp        ^(C:\Windows\Temp^)%RST%
echo %DIM%    LocalAppData Temp%RST%
echo %DIM%    Windows Error Reports ^(user + system^)%RST%
if "%IS_ADMIN%"=="1" (
    echo %DIM%    Prefetch cache      ^(C:\Windows\Prefetch^)%RST%
)
echo %DIM%    DNS cache           ^(flushed via ipconfig^)%RST%
echo.
echo %YLW%  Caution: Do not run during Windows Updates, driver installs,%RST%
echo %YLW%  antivirus scans, or active software installations.%RST%
echo %YLW%  Locked files are automatically skipped.%RST%
echo.

:: -- 10-second countdown -----------------------------------------
for /l %%i in (10,-1,1) do (
    <nul set /p "=  %WHT%Starting in %%i seconds...%RST%  [Ctrl+C to cancel]   %ESC%[1G"
    timeout /t 1 /nobreak >nul
)
<nul set /p "=%ESC%[2K%ESC%[1G"
echo.

:: -- Log file setup ----------------------------------------------
set "LOGFILE=%~dp0cleanup.log"
set "TIMESTAMP=%DATE% %TIME%"
for /f "usebackq delims=" %%T in (`powershell -NoProfile -NonInteractive -Command "Get-Date -Format 'yyyy-MM-dd HH:mm:ss'"`) do set "TIMESTAMP=%%T"

(
    echo ================================================
    echo  NUKE IT FROM ORBIT
    echo  Run: %TIMESTAMP%
    echo  Admin: %IS_ADMIN%
    echo ================================================
) > "%LOGFILE%"

:: -- Disk space before cleanup -----------------------------------
set "MB_BEFORE=0"
for /f "usebackq" %%S in (`powershell -NoProfile -NonInteractive -Command "[math]::Round((Get-PSDrive C).Free/1MB)"`) do set "MB_BEFORE=%%S"

set "TOTAL_DEL=0"
set "TOTAL_SKIP=0"

:: ================================================================
::  PHASE 1 - Temp Directories
:: ================================================================
echo %BLD%%CYN%  --- Temp Files -----------------------------------%RST%
echo.
call :cleandir "User Temp           " "%TEMP%"
call :cleandir "Windows Temp        " "C:\Windows\Temp"
call :cleandir "LocalAppData Temp   " "%LOCALAPPDATA%\Temp"
echo.

:: ================================================================
::  PHASE 2 - Windows Error Reports
:: ================================================================
echo %BLD%%CYN%  --- Windows Error Reports ------------------------%RST%
echo.
call :cleandir "WER Archive (User)  " "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive"
call :cleandir "WER Queue   (User)  " "%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue"
call :cleandir "WER Archive (System)" "%PROGRAMDATA%\Microsoft\Windows\WER\ReportArchive"
call :cleandir "WER Queue   (System)" "%PROGRAMDATA%\Microsoft\Windows\WER\ReportQueue"
echo.

:: ================================================================
::  PHASE 3 - System Caches (Administrator only)
:: ================================================================
if "%IS_ADMIN%"=="1" (
    echo %BLD%%CYN%  --- System Caches [Admin] ------------------------%RST%
    echo.
    call :cleandir "Prefetch            " "C:\Windows\Prefetch"
    echo.
)

:: ================================================================
::  PHASE 4 - DNS Cache
:: ================================================================
echo %BLD%%CYN%  --- DNS ------------------------------------------%RST%
echo.
<nul set /p "=  %CYN%[-]%RST%  DNS cache                "
ipconfig /flushdns >nul 2>&1
echo %GRN%flushed%RST%
echo DNS cache: flushed >> "%LOGFILE%"
echo.

:: ================================================================
::  SUMMARY
:: ================================================================
set "MB_AFTER=0"
for /f "usebackq" %%S in (`powershell -NoProfile -NonInteractive -Command "[math]::Round((Get-PSDrive C).Free/1MB)"`) do set "MB_AFTER=%%S"
set /a MB_FREED=MB_AFTER - MB_BEFORE

echo %BLD%%CYN%  --- Summary --------------------------------------%RST%
echo.
echo   %WHT%Files deleted  : %BLD%%GRN%!TOTAL_DEL!%RST%
echo   %WHT%Files skipped  : %DIM%!TOTAL_SKIP! ^(in use / locked^)%RST%
if !MB_FREED! GTR 0 (
    echo   %WHT%Space freed    : %BLD%%GRN%~!MB_FREED! MB%RST%
) else (
    echo   %WHT%Space freed    : %DIM%check disk properties manually%RST%
)
echo   %WHT%Log saved to   : %DIM%%LOGFILE%%RST%
echo.
echo   %DIM%Locked files may be freed after a reboot.%RST%
echo.

(
    echo.
    echo ------------------------------------------------
    echo  TOTAL FILES DELETED: !TOTAL_DEL!
    echo  FILES SKIPPED:       !TOTAL_SKIP!
    echo  APPROX SPACE FREED:  ~!MB_FREED! MB
    echo ------------------------------------------------
) >> "%LOGFILE%"

:: ================================================================
::  REBOOT PROMPT
:: ================================================================
echo %YLW%  Tip: A reboot removes any remaining locked temp files.%RST%
echo.
choice /c YN /m "  Reboot now? (Y=Yes  N=No) "
if errorlevel 2 goto :no_reboot

shutdown /r /f /t 0
echo.
echo %YLW%  Rebooting now...%RST%
goto :done

:no_reboot
echo.
echo %GRN%  All done. No reboot scheduled.%RST%

:done
echo.
echo %DIM%  Press any key to close...%RST%
pause >nul
