@echo off
reg delete HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /v FlightSettingsMaxPauseDays /f >nul 2>nul
reg add HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /v FlightSettingsMaxPauseDays /t REG_DWORD /d 10950 >nul 2>nul
echo.
reg query HKLM\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings /v FlightSettingsMaxPauseDays>nul 2>nul&&goto A||goto B
:A
echo  tip: delay update successful, max 30 year.
timeout /t 10
exit
:B
echo  tip: delay update failed, default 35 day
timeout /t 10

