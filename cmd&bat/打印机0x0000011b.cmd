@echo off
reg delete HKLM\SYSTEM\CurrentControlSet\Control\Print /v RpcAuthnLevelPrivacyEnabled /f >nul 2>nul
reg add HKLM\SYSTEM\CurrentControlSet\Control\Print /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 >nul 2>nul
echo.
reg query HKLM\SYSTEM\CurrentControlSet\Control\Print /v RpcAuthnLevelPrivacyEnabled >nul 2>nul && goto A || goto B
:A
echo 提示: 错误0x0000011b修复成功，请重启电脑！
timeout /t 5
exit
:B
echo 提示：错误0x0000011b修复失败...
timeout /t 5

