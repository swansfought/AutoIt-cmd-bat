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

;ȷ������ֻ����һ��
Global Const $MY_UNIQUE_MUTEX_NAME = 'AutoInstall'
If _Singleton($MY_UNIQUE_MUTEX_NAME, 1) = 0 Then
    MsgBox(16, '������ʾ', '��������������...')
    Exit
EndIf


Global $mainGUI, $listView, $btnClear, $btnInstall, $progressBar, $installFlag
Global $iniPath = @ScriptDir & "\config.ini" ; �����ļ�

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
    $mainGUI = GUICreate("����Զ���װ", 300, 300)

    $listView = _GUICtrlListView_Create($mainGUI, "", 10, 10, 280, 220, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $WS_BORDER, $WS_VSCROLL))
    _GUICtrlListView_AddColumn($listView, "�������", -1) ; �п�����Ӧ
    _GUICtrlListView_SetExtendedListViewStyle($listView, BitOR($LVS_EX_CHECKBOXES, $LVS_EX_FULLROWSELECT)) ;����ListView��ʽ
	
	;��������������鴴���б������������ļ��ж��Ƿ�Ĭ�Ϲ�ѡ
	Local $ret
    Local $nameArray = GetSoftwareNames() 
    For $i = 0 To UBound($nameArray) - 1
        _GUICtrlListView_AddItem($listView, $nameArray[$i], $i)
        _GUICtrlListView_SetColumnWidth($listView, 0, $LVSCW_AUTOSIZE_USEHEADER) ; �п�����Ӧ
        _GUICtrlListView_SetItemChecked($listView, $i, False) ; Ĭ�ϲ�ѡ��
		
		;�ж��Ƿ�ѡ
		$ret = IniRead($iniPath, "Checked",  $i + 1, '')
		If $ret = $nameArray[$i] Then _GUICtrlListView_SetItemChecked($listView, $i, True) ; Ĭ��ѡ��
    Next

    $btnClear = GUICtrlCreateButton("���ѡ��", 8, 235, 90, 30)
    $btnInstall = GUICtrlCreateButton("һ����װ", 202, 235, 90, 30)
    $progressBar = GUICtrlCreateProgress(10, 270, 280, 20) 
	
	GUISetState(@SW_SHOW) ;��ʾ����
	WinSetOnTop($mainGUI, "", 1) ; ʼ���ö�
EndFunc

Func OnClearButtonClick()
    ;��װ�в���Ӧ���
    If $installFlag Then Return
    For $i = 0 To _GUICtrlListView_GetItemCount($listView) - 1
        _GUICtrlListView_SetItemChecked($listView, $i, False)
    Next
EndFunc

Func OnInstallButtonClick()
    ;��װ�в���Ӧ���
    If $installFlag Then Return
	
    Local $checkedSoftwares = GetCheckedSoftwares() ;����ȡѡ�е��������
    If UBound($checkedSoftwares) = 0 Then Return ;δѡ�����
	
    $installFlag = True ;��ʼ��װ��־
	Local $tmpIndex = 0
	Local $failedIndex = 0
	Local $tmpArray[0] ;���ִ�гɹ���������������Ѱ�װ
	Local $failedArray[0] ;���ִ��ʧ�ܵ����
	
	;����ѡ�е���ȥִ�а�װ
	Local $ret = ''
    For $i = 0 To UBound($checkedSoftwares) - 1
		;ȥ�����ļ���ȡ�������·��
		$ret = IniRead($iniPath, "Path", $checkedSoftwares[$i] , '')
		If $ret <> '' Then
			Local $retCode = Run($ret) ;ִ�о�Ĭ��װ
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

	;-------------------------------������ʾ-------------------------------
	Local $successIndex = 0
	Local $installSuccessSoftwares[0] ;��װ�ɹ������
	Local $checkedNum = UBound($checkedSoftwares) 
	
	;һ��Ҳû�ɹ�ִ�е����
	If UBound($checkedSoftwares) = UBound($failedArray)  Then 
		LoadChecked($checkedSoftwares) ;�ָ�ѡ��
		Loadtip($installSuccessSoftwares) ;������ʾ
		Return
	EndIf
	
	; ������ʱ��
	Local $timer = TimerInit() ; ��ʼ����ʱ��
	Local $time = Int(IniRead($iniPath, "Time", "time", ''))
	If $time = 0 Then 
		$time = UBound($tmpIndex)
		$time = $time * 15000 + 2000
	Else
		$time = $time * 1000 + 2000
	EndIf
	
	;�ж��Ƿ�װ�ɹ�
	While 1
		If TimerDiff($timer) >= $time Then ExitLoop
	
		For $i = 0 To UBound($tmpArray) - 1
			;ȥ�����ļ���ȡ�����װ·��
			$ret = IniRead($iniPath, "Estimate", $tmpArray[$i] , '')
			If _ArraySearch($installSuccessSoftwares, $tmpArray[$i]) <> -1 And FileExists($ret) Then
				;������
				$successIndex += 1
				ReDim $installSuccessSoftwares[$successIndex]
				$installSuccessSoftwares[$successIndex - 1] = $tmpArray[$i]
				
				GUICtrlSetData($progressBar, Int(($successIndex / $checkedNum) * 100)) ;������ǰ��
				_ArrayDelete($tmpArray, $i) ;�Ƴ�Ԫ��
			EndIf
		Next
	WEnd
	
	; ��ʾ��װ��Ϣ
	LoadChecked($checkedSoftwares) ;�ָ�ѡ��
	Loadtip($installSuccessSoftwares) ;������ʾ

EndFunc

Func GetSoftwareNames()
    Local $nameArray[0] ;�����������
	
    ; ��ȡ�����ļ����������
	Local $key = 0
	Local $ret
	While 1
		$key += 1
		$ret = IniRead($iniPath, "Name", $key ,'')
		If $ret='' Then ExitLoop
		
		;��������
		ReDim $nameArray[$key]
		$nameArray[$key - 1] = $ret
	WEnd

    Return $nameArray
EndFunc

Func GetCheckedSoftwares()
	Local $checkedSoftwareArray[0]
    Local $index = 0
	;�����õ�ѡ����
    For $i = 0 To _GUICtrlListView_GetItemCount($listView) - 1
        If _GUICtrlListView_GetItemChecked($listView, $i) Then
            $index += 1
			;��������
			ReDim $checkedSoftwareArray[$index]
			$checkedSoftwareArray[$index - 1] = _GUICtrlListView_GetItemText($listView, $i)
        EndIf
    Next
	Return $checkedSoftwareArray
EndFunc

Func LoadChecked(ByRef $checkArr)
	For $i = 0 To UBound($checkArr) - 1
		If  $checkArr[$i] = _GUICtrlListView_GetItemText($listView, $i) Then
			_GUICtrlListView_SetItemChecked($listView, $i, True) ; ѡ��
		Else
			_GUICtrlListView_SetItemChecked($listView, $i, False) ; ��ѡ��
		EndIf
	Next
EndFunc 

Func LoadTip(ByRef $installedArr)
	Local $names
    For $i = 0 To UBound($installedArr) - 1
		$names = $names & $installedArr[$i] & @CRLF
    Next
	Local $tip = "�볢���ֶ���װ��" & @CRLF & "ʧ��ԭ�򣺵�ǰѡ�������޷������Զ���װ��" & @CRLF & _
						"������������������ļ���������Ƿ�������..." & @CRLF  & @CRLF & "�Ѱ�װ�ĳ����б�" & @CRLF &  $names
	MsgBox(0, "��װ��ʾ", $tip)
	ResetGUI() ;���ô��ڽ���
EndFunc

Func ResetGUI()
    GUICtrlSetData($progressBar, 0)
    $installFlag = False 
EndFunc