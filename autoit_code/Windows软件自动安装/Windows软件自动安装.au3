#cs ----------------------------------------------------------------------------

 AutoIt Version: 3.3.16.1
 Author:         swansfought

 Script Function:
	Template AutoIt script.

#ce ----------------------------------------------------------------------------

; Script Start - Add your code below here
#include <Misc.au3>
#include <GUIConstantsEx.au3>
#include <ButtonConstants.au3>
#include <WindowsConstants.au3>
#include <GuiListView.au3>
#include <FileConstants.au3>

#RequireAdmin

;确保程序只存在一个
Global Const $MY_UNIQUE_MUTEX_NAME = 'AutoInstall'
If _Singleton($MY_UNIQUE_MUTEX_NAME, 1) = 0 Then
    MsgBox(16, '程序提示', '程序正在运行中...')
    Exit
EndIf


Global $mainGUI, $listView, $btnClear, $btnInstall, $progressBar, $installFlag
Global $iniPath = @ScriptDir & "\config.ini" ; 配置文件

Main()

Func Main()
    CreateGUI()
    $installFlag = False
	
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                ExitLoop
            Case $btnClear
                OnClearButtonClick()
            Case $btnInstall
                OnInstallButtonClick()
        EndSwitch
    WEnd
    GUIDelete($mainGUI)
EndFunc


Func CreateGUI()
    $mainGUI = GUICreate("软件自动安装", 300, 300)

    $listView = _GUICtrlListView_Create($mainGUI, "", 10, 10, 280, 220, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $WS_BORDER, $WS_VSCROLL))
    _GUICtrlListView_AddColumn($listView, "常用软件", -1) ; 列宽自适应
    _GUICtrlListView_SetExtendedListViewStyle($listView, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT)) ;设置ListView样式
	
	;根据软件名称数组创建列表，并根据配置文件判断是否默认勾选
	Local $ret
    Local $nameArray = GetSoftwareNames() 
    For $i = 0 To UBound($nameArray) - 1
        _GUICtrlListView_AddItem($listView, $nameArray[$i], $i)
        _GUICtrlListView_SetColumnWidth($listView, 0, $LVSCW_AUTOSIZE_USEHEADER) ; 列宽自适应
        _GUICtrlListView_SetItemChecked($listView, $i, False) ; 默认不选中
		
		;判断是否勾选
		$ret = IniRead($iniPath, "Checked",  $i + 1, '')
		If $ret = $nameArray[$i] Then _GUICtrlListView_SetItemChecked($listView, $i, True) ; 默认选中
    Next

    $btnClear = GUICtrlCreateButton("清除选择", 8, 235, 90, 30)
    $btnInstall = GUICtrlCreateButton("一键安装", 202, 235, 90, 30)
    $progressBar = GUICtrlCreateProgress(10, 270, 280, 20) 
	
	GUISetState(@SW_SHOW) ;显示界面
	WinSetOnTop($mainGUI, "", 1) ; 始终置顶
EndFunc

Func OnClearButtonClick()
    ;安装中不响应点击
    If $installFlag Then Return
    For $i = 0 To _GUICtrlListView_GetItemCount($listView) - 1
        _GUICtrlListView_SetItemChecked($listView, $i, False)
    Next
EndFunc

Func OnInstallButtonClick()
    ;安装中不响应点击
    If $installFlag Then Return
	
    Local $checkedSoftwares = GetCheckedSoftwares() ;更获取选中的软件数组
    If UBound($checkedSoftwares) = 0 Then Return ;未选中软件
	
    $installFlag = True ;开始安装标志
	Local $tmpIndex = 0
	Local $failedIndex = 0
	Local $tmpArray[0] ;存放执行成功的软件，不代表已安装
	Local $failedArray[0] ;存放执行失败的软件
	
	;遍历选中的项去执行安装
	Local $ret = ''
    For $i = 0 To UBound($checkedSoftwares) - 1
		;去配置文件获取软件所在路径
		$ret = IniRead($iniPath, "Path", $checkedSoftwares[$i] , '')
		If $ret <> '' Then
			Local $retCode = Run($ret) ;执行静默安装
			If $retCode > 0 Then
				$tmpIndex += 1
				ReDim $tmpArray[$tmpIndex]
				$tmpArray[$tmpIndex - 1] = $checkedSoftwares[$i] 
			Else
				$failedIndex += 1
				ReDim $failedArray[$failedIndex]
				$failedArray[$failedIndex - 1] = $checkedSoftwares[$i] 
			EndIf
		Else
				$failedIndex += 1
				ReDim $failedArray[$failedIndex]
				$failedArray[$failedIndex - 1] = $checkedSoftwares[$i] 
		EndIf
	Next

	;-------------------------------处理提示-------------------------------
	Local $successIndex = 0
	Local $installSuccessSoftwares[0] ;安装成功的软件
	Local $checkedNum = UBound($checkedSoftwares) 
	
	;一个也没成功执行的情况
	If UBound($checkedSoftwares) = UBound($failedArray)  Then 
		LoadChecked($checkedSoftwares) ;恢复选中
		Loadtip($installSuccessSoftwares) ;加载提示
		Return
	EndIf
	
	; 创建定时器
	Local $timer = TimerInit() ; 初始化定时器
	Local $time = Int(IniRead($iniPath, "Time", "time", ''))
	If $time = 0 Then 
		$time = UBound($tmpIndex)
		$time = $time * 15000 + 2000
	Else
		$time = $time * 1000 + 2000
	EndIf
	
	;判断是否安装成功
	While 1
		If TimerDiff($timer) >= $time Then ExitLoop
	
		For $i = 0 To UBound($tmpArray) - 1
			;去配置文件获取软件安装路径
			$ret = IniRead($iniPath, "Estimate", $tmpArray[$i] , '')
			If _ArraySearch($installSuccessSoftwares, $tmpArray[$i]) <> -1 And FileExists($ret) Then
				;存数据
				$successIndex += 1
				ReDim $installSuccessSoftwares[$successIndex]
				$installSuccessSoftwares[$successIndex - 1] = $tmpArray[$i]
				
				GUICtrlSetData($progressBar, Int(($successIndex / $checkedNum) * 100)) ;进度条前进
				_ArrayDelete($tmpArray, $i) ;移除元素
			EndIf
		Next
	WEnd
	
	; 显示安装信息
	LoadChecked($checkedSoftwares) ;恢复选中
	Loadtip($installSuccessSoftwares) ;加载提示

EndFunc

Func GetSoftwareNames()
    Local $nameArray[0] ;软件名称数组
	
    ; 读取配置文件的软件名称
	Local $key = 0
	Local $ret
	While 1
		$key += 1
		$ret = IniRead($iniPath, "Name", $key ,'')
		If $ret='' Then ExitLoop
		
		;保存数据
		ReDim $nameArray[$key]
		$nameArray[$key - 1] = $ret
	WEnd

    Return $nameArray
EndFunc

Func GetCheckedSoftwares()
	Local $checkedSoftwareArray[0]
    Local $index = 0
	;遍历拿到选中项
    For $i = 0 To _GUICtrlListView_GetItemCount($listView) - 1
        If _GUICtrlListView_GetItemChecked($listView, $i) Then
            $index += 1
			;保存数据
			ReDim $checkedSoftwareArray[$index]
			$checkedSoftwareArray[$index - 1] = _GUICtrlListView_GetItemText($listView, $i)
        EndIf
    Next
	Return $checkedSoftwareArray
EndFunc

Func LoadChecked(ByRef $checkArr)
	For $i = 0 To UBound($checkArr) - 1
		If  $checkArr[$i] = _GUICtrlListView_GetItemText($listView, $i) Then
			_GUICtrlListView_SetItemChecked($listView, $i, True) ; 选中
		Else
			_GUICtrlListView_SetItemChecked($listView, $i, False) ; 不选中
		EndIf
	Next
EndFunc 

Func LoadTip(ByRef $installedArr)
	Local $names
    For $i = 0 To UBound($installedArr) - 1
		$names = $names & $installedArr[$i] & @CRLF
    Next
	Local $tip = "请尝试手动安装！" & @CRLF & "失败原因：当前选择的软件无法启用自动安装。" & @CRLF & _
						"解决方法：请检查配置文件或检查软件是否已运行..." & @CRLF  & @CRLF & "已安装的程序列表：" & @CRLF &  $names
	MsgBox(0, "安装提示", $tip)
	ResetGUI() ;重置窗口界面
EndFunc

Func ResetGUI()
    GUICtrlSetData($progressBar, 0)
    $installFlag = False 
EndFunc