# PC-Cleanup-Reboot-Batch

A Windows batch script that safely removes temporary files, caches, and system junk to free up disk space.

## Usage

**Right-click `PC-Cleanup.bat` → Run as administrator** for full cleanup.  
Running without elevation still cleans user-level targets but skips Prefetch and Windows Update cache.

## What It Cleans

| Target | Path | Requires Admin |
|---|---|---|
| User Temp | `%TEMP%` | No |
| Windows Temp | `C:\Windows\Temp` | No |
| LocalAppData Temp | `%LOCALAPPDATA%\Temp` | No |
| WER Archive (User) | `%LOCALAPPDATA%\Microsoft\Windows\WER\ReportArchive` | No |
| WER Queue (User) | `%LOCALAPPDATA%\Microsoft\Windows\WER\ReportQueue` | No |
| WER Archive (System) | `%PROGRAMDATA%\Microsoft\Windows\WER\ReportArchive` | No |
| WER Queue (System) | `%PROGRAMDATA%\Microsoft\Windows\WER\ReportQueue` | No |
| Recycle Bin | System-wide | No |
| DNS Cache | Flushed via `ipconfig /flushdns` | No |
| Prefetch Cache | `C:\Windows\Prefetch` | Yes |
| Windows Update Cache | `C:\Windows\SoftwareDistribution\Download` | Yes |

## Features

- **Colored output** with per-phase section headers (Windows 10 1607+)
- **Admin detection** — warns and gracefully skips admin-only targets if not elevated
- **Disk space freed** — before/after comparison via PowerShell
- **Log file** — written to `cleanup.log` in the same folder as the script
- **10-second countdown** with Ctrl+C cancel
- **Optional reboot** with 30-second delay and cancellation instructions
- Locked/in-use files are automatically skipped, never force-closed

## Requirements

- Windows 10 or later
- PowerShell (for disk space display and log timestamps — script continues without it)

## Cautions

- Do not run during Windows Updates, driver installs, or antivirus scans
- The Windows Update cache step briefly stops and restarts the `wuauserv` and `bits` services
- Prefetch deletion is safe — Windows rebuilds it automatically on next use
