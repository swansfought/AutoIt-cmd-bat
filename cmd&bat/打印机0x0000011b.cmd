@echo off
reg delete HKLM\SYSTEM\CurrentControlSet\Control\Print /v RpcAuthnLevelPrivacyEnabled /f >nul 2>nul
reg add HKLM\SYSTEM\CurrentControlSet\Control\Print /v RpcAuthnLevelPrivacyEnabled /t REG_DWORD /d 0 >nul 2>nul
echo.
reg query HKLM\SYSTEM\CurrentControlSet\Control\Print /v RpcAuthnLevelPrivacyEnabled >nul 2>nul && goto A || goto B
:A
echo ��ʾ: ����0x0000011b�޸��ɹ������������ԣ�
timeout /t 5
exit
:B
echo ��ʾ������0x0000011b�޸�ʧ��...
timeout /t 5

