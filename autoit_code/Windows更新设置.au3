#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         myName

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>

#RequireAdmin

Global $selectedValue, $IblTip

; 创建GUI窗口
Local $hGUI = GUICreate("Windows更新设置", 295, 140)

; 延迟更新天数标签
Local $lblDelay = GUICtrlCreateLabel("Windows暂停更新", 10, 60, 120, 20)
GUICtrlSetFont($lblDelay, 12, 400) ; 设置标签字体大小为

;单位标签
Local $_blDelay = GUICtrlCreateLabel("年", 195, 60, 20, 20)
GUICtrlSetFont($_blDelay, 12, 400) ; 设置标签字体大小为

; 下拉列表
Local $cmbDelay = GUICtrlCreateCombo("", 135, 57, 55, 20)
GUICtrlSetData(-1, "1|5|10|15|20|25|30")
GUICtrlSetData(-1, 20) ; 设置默认值为20
GUICtrlSetFont($cmbDelay, 12, 400) ; 设置下拉列表字体大小为

; 确认按钮
Local $btnConfirm = GUICtrlCreateButton("确认", 220, 54, 65, 30)
GUICtrlSetFont($btnConfirm, 12, 400) ; 设置按钮字体大小为

;提示标签
$IblTip = GUICtrlCreateLabel("当前最大暂停时间：20年", 10, 20, 295, 30)
GUICtrlSetFont($IblTip , 11, 400) ; 设置标签字体大小为 12
Local $regDay = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings", "FlightSettingsMaxPauseDays") ; 查询注册表中的值
; 判断是否添加过延迟天数
If $regDay = "" Then
	GUICtrlSetData($IblTip, "当前最大暂停时间：5周。")
Else
    GUICtrlSetData($IblTip, "当前最大暂停时间：" & Int($regDay/7) & "周，即" & $regDay/365 & "年！")
EndIf

;恢复默认
Local $btnDefault = GUICtrlCreateButton("恢复默认设置", 5, 95, 115, 30)
GUICtrlSetFont($btnDefault, 11, 400) ; 设置按钮字体大小为

;打开更新设置界面
Local $btnSysUpdateGUI = GUICtrlCreateButton("打开Windows更新设置", 125, 95, 165, 30)
GUICtrlSetFont($btnSysUpdateGUI, 11, 400) ; 设置按钮字体大小为

GUISetState(@SW_SHOW)
WinSetOnTop($hGUI, "", 1) ; 将窗口设置为始终在最前面

; GUI消息循环
While 1
		;判断当前值是否合理
		Local $currValue = GUICtrlRead($cmbDelay)
		If $currValue < 1 Then
			GUICtrlSetData($cmbDelay, 1) 
		ElseIf $currValue > 30 Then
			GUICtrlSetData($cmbDelay, 30)
		EndIf
    Switch GUIGetMsg()
        Case $GUI_EVENT_CLOSE
            ExitLoop
        Case $btnDefault
			If RegDelete("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings", "FlightSettingsMaxPauseDays") Then
				GUICtrlSetData($IblTip, "当前最大暂停时间：5周。")
			Else
				MsgBox(0, "提示窗口", "恢复默认操作失败！")
			EndIf
        Case $btnSysUpdateGUI
				ShellExecute("control.exe", " /name Microsoft.WindowsUpdate") ; 打开 Windows 更新设置界面
				
        Case $btnConfirm
            $selectedValue = GUICtrlRead($cmbDelay)* 365
			RegWrite("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings", "FlightSettingsMaxPauseDays", "REG_DWORD", $selectedValue)
			Local $regDay = RegRead("HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings", "FlightSettingsMaxPauseDays") ; 查询注册表中的值
			If $regDay = "" Then
				MsgBox(0, "提示窗口", "延迟更新设置失败！")
			Else
				GUICtrlSetData($IblTip, "当前最大暂停时间：" & Int($regDay/7) & "周，即" & $regDay/365 & "年！")
			EndIf
    EndSwitch
WEnd

GUIDelete($hGUI)




 
 