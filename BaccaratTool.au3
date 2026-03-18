#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ProgressConstants.au3>
#include <ComboConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <Date.au3>
#include <Inet.au3>
#include <WinAPI.au3>
#include <AutoItConstants.au3>
#include <Array.au3>
#include <GuiListView.au3>
#include <Misc.au3>
#include "wd_core.au3"
#include "wd_helper.au3"
#include "Json.au3"
#include "WinHttp.au3"

; <<<< Yêu cầu quyền quản trị để tool hoạt động ổn định >>>>
#RequireAdmin

; ==================================================================================================
; --- PHẦN CẤU HÌNH (BẮT BUỘC) ---
; ==================================================================================================
Global Const $g_sAppsScriptBaseURL = "https://script.google.com/macros/s/AKfycbzYsojeFPtUJNwNKMMclP7zuj9TO6XYyq16O02Pi-ef87OP2kYz3TV3kT02XBw_GXuE/exec"
Global Const $g_sDevPassword = "nmn12nntv21"
Global Const $g_sToolName = "Tool-Baccarat"
; --- CẤU HÌNH AUTO UPDATE GITHUB ---
Global Const $g_sVersion = "1.2" ; Phiên bản hiện tại
Global Const $g_sCopyright = "Thuộc Bản Quyền Telegram @nnduy2086"
Global Const $g_sGithubVersionURL = "https://raw.githubusercontent.com/nnduy86/BaccaratTool/main/version.txt"
Global Const $g_sDownloadURL = "https://github.com/nnduy86/BaccaratTool/raw/main/BaccaratTool.exe"

; --- KHAI BÁO BIẾN TOÀN CỤC ---
; ==================================================================================================
Global Const $g_iTimeOutLimit = 45000
Global $g_bIsRunning = False
Global $g_sIniPath
Global $g_bIsFormatting = False
Global $g_sInstanceIdentifier
Global $g_bConfigUnlocked = False
Global $g_hSessionTimer
Global $g_sCurrentLoadedProfile = ""
Global $g_hCheckbox_ContinuousMode
Global $g_hButton_Help
Global $g_hTargetGameWin = 0
Global $g_sCurrentRuleSignature = "Global"
Global $g_hStreakGUI = 0 ; Biến lưu cửa sổ popup thống kê
Global $g_iPostWinState = 0         ; 0=Bình thường, 1=Đợi gãy để lấy, 2=Đợi gãy để bỏ
Global $g_sLastTrendToWait = ""     ; Lưu lại dây đang theo để chờ nó gãy
Global $g_iHistoryCutoffIndex = 0 ; Biến lưu điểm cắt đuôi lịch sử để tách cầu
Global $g_hCheckbox_Blacklist   ; Checkbox Blacklist
Global $g_hListView_Stats ; Biến quản lý bảng thống kê
Global $g_hInput_CustomRules        ; Hộp nhập liệu lớn (Edit Box)
Global $g_iCustomSeqStep = 0
Global $g_sCurrentTargetSeq = ""    ; Biến lưu chuỗi cần đánh hiện tại (Khi bắt được cầu)
Global $g_hCheckbox_SeparateQLV      ; Checkbox chọn chế độ QLV Riêng
Global $g_aRuleLevels[100]           ; Mảng lưu Level vốn của 100 dòng (Mỗi dòng 1 ô nhớ)
Global $g_iLastActiveRuleIndex = -1  ; Biến nhớ: Ván vừa rồi là do Dòng nào đánh?
Global $g_sMyTableID = ""
Global $g_bStartHidden = False
If $CmdLine[0] > 0 Then
    For $i = 1 To $CmdLine[0]
        Local $sArg = $CmdLine[$i]
        ; 1. Nhận tên bàn (B1, B2...)
        If StringRegExp($sArg, "^B\d+$") Then
            $g_sMyTableID = $sArg
            Global $g_sIniPath = @ScriptDir & "\config.ini" ; <--- ÉP LUÔN VỀ CONFIG.INI
        EndIf
        ; 2. Nhận lệnh CHẠY ẨN (/starthidden)
        If StringInStr($sArg, "/starthidden") Then
            $g_bStartHidden = True
        EndIf
    Next
Else
    Global $g_sIniPath = @ScriptDir & "\config.ini"
EndIf
Global $g_iTempX = 0
Global $g_iTempY = 0
Global $g_iTempColor = 0
Global $g_bNeedAutoSave = False
Global $g_hAutoSaveTimer = 0
Global $g_sWDSession = ""
Global $g_bIsLoginComplete = False ; [MỚI] Cờ báo hiệu đã đăng nhập xong
Global $g_hGUI, $g_hTab
Global $g_hTabItemConfig
Global $g_hInput_InitialCapital, $g_hInput_InitialBet, $g_hInput_TakeProfit, $g_hInput_StopLoss
Global $g_hLabel_CurrentBalance, $g_hLabel_Profit, $g_hLabel_TotalHands, $g_hLabel_ExpiryDate, $g_hLabel_DaysRemaining
Global $g_hLabel_TotalVolume
Global $g_hButton_Start, $g_hButton_Stop
Global $g_aLabel_History[120]
Global $g_hLabel_StrategyWins, $g_hLabel_StrategyLosses, $g_hLabel_StrategyWinRate, $g_hLabel_MaxWinStreak, $g_hLabel_MaxLossStreak
Global $g_hLabel_Time
Global $g_hLabel_TotalB_Val, $g_hLabel_TotalP_Val, $g_hLabel_TotalT_Val
Global $g_hButton_SaveQLV, $g_hButton_DeleteQLV
Global $g_bManualStopped = False ; [MỚI] Đánh dấu người dùng chủ động tắt hoặc tắt trình duyệt
Global $g_hInput_ScanX, $g_hInput_ScanY, $g_hInput_ScanColor, $g_hLabel_ScanColorPreview, $g_hCheckbox_ToggleScan
Global $g_hButton_Unlock, $g_hButton_Lock
Global $g_aConfigControls[0]
Global $g_hInput_WindowClass
Global $g_hInput_BankerX, $g_hInput_BankerY, $g_hInput_PlayerX, $g_hInput_PlayerY
Global $g_hInput_ResultX1, $g_hInput_ResultY1, $g_hInput_ResultX2, $g_hInput_ResultY2
Global $g_hInput_BankerColor, $g_hInput_PlayerColor, $g_hInput_TieColor
Global $g_hInput_BetTimeX1, $g_hInput_BetTimeY1, $g_hInput_BetTimeX2, $g_hInput_BetTimeY2
Global $g_hInput_BetTimeColor
Global $g_hButton_GetBankerPos, $g_hButton_GetPlayerPos
Global $g_hButton_GetResultTL, $g_hButton_GetResultBR
Global $g_hButton_GetBankerColor, $g_hButton_GetPlayerColor, $g_hButton_GetTieColor
Global $g_hButton_GetBetTimeTL, $g_hButton_GetBetTimeBR
Global $g_hButton_GetBetTimeColor
Global $g_hInput_Shade_Result, $g_hInput_Shade_Timer  ; 3 biến dung sai riêng
Global $g_hButton_TestColor_Result, $g_hButton_TestColor_Timer  ; 3 nút test
Global $g_iShade_Result = 10    ; Mặc định dung sai kết quả
Global $g_iShade_Timer = 20     ; Mặc định dung sai giờ cược
Global $g_hRadio_ClickMode_Control, $g_hRadio_ClickMode_Mouse
Global $g_hInput_ClickDelay
Global $g_sAutoStartProfile = ""
Global $g_aCheckbox_ChipEnabled[5], $g_aInput_ChipValue[5], $g_aInput_ChipX[5], $g_aInput_ChipY[5], $g_aButton_GetChipPos[5]
Global $g_iMouseSpeed = 0 ; 0 là tức thì, 10 là mặc định chậm
Global $g_hInput_MouseSpeed ; Biến cho ô nhập liệu
Global $g_hCombo_Profiles, $g_hInput_ProfileName, $g_hButton_SaveProfileToIni, $g_hButton_DeleteProfileFromIni, $g_hButton_DownloadConfig
Global $g_hCombo_Profiles_Main
Global $g_hRadio_ClickMode_Control_Main, $g_hRadio_ClickMode_Mouse_Main
Global $g_hInput_ClickDelay_Main
Global $g_hGroup_QLV_Flexible
Global $g_hInput_CustomQLV_Edit
Global $g_hCombo_QLV_Presets
Global $g_sGameWindowClass
Global $g_aBankerButtonPos[2]
Global $g_aPlayerButtonPos[2]
Global $g_aResultArea[4]
Global $g_iBankerColor
Global $g_iPlayerColor
Global $g_iTieColor
Global $g_aBetTimeIndicatorArea[4]
Global $g_iBetTimeIndicatorColor
Global $g_sClickMode
Global $g_iClickDelay
Global $g_aChipConfig[5][4] ; [IsEnabled, Value, X, Y]
Global $g_fInitialCapital = 0.0, $g_fInitialBet = 0.0, $g_fTakeProfit = 0.0, $g_fStopLoss = 0.0
Global $g_fTotalProfit = 0.0, $g_fCurrentBet = 0.0
Global $g_fLastBetAmount = 0.0
Global $g_sLastBetOn = ""
Global $g_bContinuousBetting = False
Global $g_fTotalVolume = 0.0
Global $g_iSessionCount = 0
Global $g_aDisplayHistory[0]
Global $g_aHighlightIndices[0]
Global Const $g_iHighlightColor = 0xFFFFE0
Global Const $g_iLatestHighlightColor = 0xADD8E6
Global $g_iTotalBanker = 0, $g_iTotalPlayer = 0, $g_iTotalTie = 0
Global Const $g_sQLVMode = "Flexible" ; [CỐ ĐỊNH] Luôn là Flexible
Global $g_aCustomQLVTable[0][4] ; [Lệnh, Vốn, ThắngVề, ThuaVề]
Global $g_iCustomQLV_Index = 0
Global $g_iStrategyWins = 0, $g_iStrategyLosses = 0, $g_iCurrentWinStreak = 0, $g_iCurrentLossStreak = 0, $g_iMaxWinStreak = 0, $g_iMaxLossStreak = 0
Global $g_iMaxWinStreakCount = 0, $g_iMaxLossStreakCount = 0
Global $g_aWinFreq[50], $g_aLossFreq[50]
Global $g_iCapitalLevel = 1 ; Cấp vốn hiện tại (1, 2, 3...)
Global $g_hInput_Blacklist       ; Ô nhập danh sách đen
Global $g_iCycleStep = 1      ; Biến đếm bước trong chu kỳ quan sát
Global $g_hInput_HistoryLimit ; <--- THÊM DÒNG NÀY (Biến ô nhập giới hạn view)
Global Const $HARD_LIMIT_RAM = 500 ; <--- THÊM DÒNG NÀY (Giới hạn cứng bộ nhớ)
Global $g_hCheckbox_Blacklist_IgnoreRunning ; <--- [MỚI] Biến Checkbox bỏ qua Blacklist khi đang chạy

_Main()

Func _Main()
	If _Singleton("ToolCasino_Lock_Main", 1) = 0 Then
		MsgBox(48, "Thông báo", "Tool đang được mở rồi! Vui lòng kiểm tra dưới thanh Taskbar.")
		Exit
	EndIf
	_CheckForUpdates()
	Local $aLicenseInfo = _CheckLicenseOnline()
	Local $sStatus = $aLicenseInfo[0]
	Local $sData = $aLicenseInfo[1]
	If $sStatus = "OK" Then
		$g_sHWID = _GetHardwareID()
		$g_sExpiryDate = $sData
	ElseIf $sStatus = "EXPIRED" Then
		_ShowExpiryDialog($sData)
		Exit
	Else
		_ShowActivationDialog(_GetHardwareID())
		Exit
	EndIf
	_CreateGUI($g_sExpiryDate)
	_MainLoop()
EndFunc   ;==>_Main

Func _RunMainApp($sExpiryDate)
	_CreateGUI($sExpiryDate)
	_MainLoop()
EndFunc

; ==================================================================================================
; --- CÁC HÀM TẠO GIAO DIỆN (GUI) ---
; ==================================================================================================

Func _CreateGUI($sExpiryDate)
    $g_hGUI = GUICreate("Tool-AIO_" & $g_sVersion & $g_sInstanceIdentifier & " | " & $g_sCopyright, 1280, 840, -1, -1, -1, $WS_EX_CLIENTEDGE)
    ; >>> LỆNH LỒNG ẢNH VÀO FILE .EXE <<<
    ; Tham số 1: Tên file ảnh đang nằm cạnh file code lúc bạn lập trình.
    ; Tham số 2: Nơi bức ảnh sẽ được xả nén ra khi khách mở tool (ném vào Temp cho sạch).
    ; Tham số 3: 1 = Ghi đè nếu đã có.
    FileInstall("hinhnen.jpg", @TempDir & "\hinhnen_temp.jpg", 1)

    ; Load ảnh nền từ thư mục Temp
    Local $hBgPic = GUICtrlCreatePic(@TempDir & "\hinhnen_temp.jpg", 0, 30, 1280, 810)
    GUICtrlSetState($hBgPic, $GUI_DISABLE) ; Khóa ảnh

    GUISetFont(10, 400, 0, "Arial")
    GUIRegisterMsg($WM_COMMAND, "WM_COMMAND_Handler")

    ; TẠO TAB (Cho phần thân Tab trong suốt để lộ ảnh nền bên dưới)
    $g_hTab = GUICtrlCreateTab(5, 5, 1270, 830)
    GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
    GUICtrlSetFont(-1, 10, 700)
    ;GUICtrlSetColor(-1, 0x0066CC)
    Local $hTab1 = GUICtrlCreateTabItem("Giao Diện Chính")
    _CreateTab_MainTool()

    $g_hTabItemConfig = GUICtrlCreateTabItem("Phòng Kỹ Thuật")
    _CreateTab_ConfigHelper()

    GUICtrlCreateTabItem("")

    _LoadSettings()
    _UpdateLicenseInfoLabels($sExpiryDate)
    _SetControlsState(True)
    _ToggleConfigControlsState(False)

    AdlibRegister("_UpdateClock", 1000)
    _UpdateClock()

    If $g_bStartHidden Then
        GUISetState(@SW_HIDE, $g_hGUI)
    Else
        GUISetState(@SW_SHOW, $g_hGUI)
    EndIf
EndFunc

Func _CreateTab_MainTool()
	_CreateGroup_Settings()
	_CreateGroup_BettingMethod()
	_CreateGroup_QLV_On_Main()

	_CreateGroup_StrategyStats()
	_CreateGroup_BPT_Totals()
	_CreateGroup_HistoryDisplay()
	_CreateGroup_HistoryLog()

	_CreateGroup_InfoAndTargets()
	_CreateGroup_UserConfig_Main()
	_CreateGroup_LicenseInfo()
EndFunc

Func _MainLoop()
	AdlibRegister("_CheckForUpdates", 60000) ; Cứ 1 phút check update ngầm 1 lần
	AdlibRegister("_KeepWebLocked", 1500)

	While 1
		; 1. TỰ ĐỘNG LƯU CẤU HÌNH (AUTO SAVE)
		If $g_bNeedAutoSave And TimerDiff($g_hAutoSaveTimer) > 1000 Then
			If $g_sCurrentLoadedProfile <> "" Then _MasterSave($g_sCurrentLoadedProfile)
			$g_bNeedAutoSave = False
		EndIf

		; 2. LẮNG NGHE SỰ KIỆN GIAO DIỆN (GUI MESSAGES)
		Local $aMsg = GUIGetMsg(1)

		If $g_hStreakGUI <> 0 And $aMsg[1] = $g_hStreakGUI And $aMsg[0] = $GUI_EVENT_CLOSE Then
			GUIDelete($g_hStreakGUI)
			$g_hStreakGUI = 0
		EndIf

		Switch $aMsg[0]
			Case 0
				ContinueLoop
			Case $GUI_EVENT_CLOSE
				If $aMsg[1] = $g_hGUI Or $aMsg[0] = $GUI_EVENT_CLOSE Then
					_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))

                    ; --- BẤM X LÀ DIỆT LUÔN CHROME VÀ TẮT TOOL ---
                    If $g_sWDSession <> "" Then _WD_DeleteSession($g_sWDSession)
                    ProcessClose("chromedriver.exe")

					Exit
				EndIf
			Case $g_hButton_Start
				If $g_bIsRunning Then
					_StopProcess()
				Else
					$g_bManualStopped = False
					Opt("WinTitleMatchMode", 2)
					Local $hMainCheck = WinGetHandle("MAIN_BACCARAT_TOOL_9999")
					Local $hSecureCheck = WinGetHandle("SECURE_BACCARAT_TOOL_9999")
					Local $bNeedRinhRap = False

					If $hSecureCheck <> 0 And WinExists($hSecureCheck) Then
						_UpdateStatus("✅ Đã kết nối lại sảnh cũ. BẮT ĐẦU SĂN THƯỞNG...")
						$g_hTargetGameWin = $hSecureCheck
						_StartProcess()
					ElseIf $hMainCheck <> 0 And WinExists($hMainCheck) Then
						_UpdateStatus("🚀 Đang dọn dẹp trang chủ cũ và khởi tạo lại...")
						GUICtrlSetState($g_hButton_Start, $GUI_DISABLE)
						GUICtrlSetData($g_hButton_Start, "ĐANG MỞ WEB...")
						If $g_sWDSession <> "" Then _WD_DeleteSession($g_sWDSession)
						ProcessClose("chromedriver.exe")

						While WinExists("MAIN_BACCARAT_TOOL_9999")
							WinClose("MAIN_BACCARAT_TOOL_9999")
							Sleep(200)
						WEnd
						While WinExists("SECURE_BACCARAT_TOOL_9999")
							WinClose("SECURE_BACCARAT_TOOL_9999")
							Sleep(200)
						WEnd

						$g_sWDSession = ""
						$g_hTargetGameWin = 0
						If _RunAutoLoginFlow() Then
							$bNeedRinhRap = True
						Else
							$bNeedRinhRap = False
						EndIf
					Else
						_UpdateStatus("🚀 Đang khởi tạo Trình duyệt mới...")
						GUICtrlSetState($g_hButton_Start, $GUI_DISABLE)
						GUICtrlSetData($g_hButton_Start, "ĐANG MỞ WEB...")
						If $g_sWDSession <> "" Then _WD_DeleteSession($g_sWDSession)
						ProcessClose("chromedriver.exe")
						While WinExists("MAIN_BACCARAT_TOOL_9999")
							WinClose("MAIN_BACCARAT_TOOL_9999")
							Sleep(200)
						WEnd
						While WinExists("SECURE_BACCARAT_TOOL_9999")
							WinClose("SECURE_BACCARAT_TOOL_9999")
							Sleep(200)
						WEnd

						$g_sWDSession = ""
						$g_hTargetGameWin = 0
						If _RunAutoLoginFlow() Then
							$bNeedRinhRap = True
						Else
							$bNeedRinhRap = False
						EndIf
					EndIf

					If $bNeedRinhRap Then
                        _UpdateStatus("⏳ Hãy tự mở sảnh Nhiều Bàn. Tool đang rình rập...")
                        GUICtrlSetData($g_hButton_Start, "ĐANG MỞ SẢNH...")

                        Local $bFoundLobby = False
                        Local $hWaitLobby = TimerInit()
                        Local $sBrowserClass = GUICtrlRead($g_hInput_WindowClass)
                        If $sBrowserClass = "" Then $sBrowserClass = "Chrome_WidgetWin_1"

                        While TimerDiff($hWaitLobby) < 180000
                            Opt("WinTitleMatchMode", 2)
                            Local $hTarget = WinGetHandle("SECURE_BACCARAT_TOOL_9999")
                            If $hTarget = 0 Then $hTarget = WinGetHandle("[TITLE:Baccarat Multiplay; CLASS:" & $sBrowserClass & "]")
                            If $hTarget = 0 Then $hTarget = WinGetHandle("[TITLE:Pragmatic Play | Lobby; CLASS:" & $sBrowserClass & "]")
                            If $hTarget = 0 Then $hTarget = WinGetHandle("[TITLE:Nhiều Bàn; CLASS:" & $sBrowserClass & "]")

                            If $hTarget <> 0 And WinExists($hTarget) Then
                                WinSetTitle($hTarget, "", "SECURE_BACCARAT_TOOL_9999")
                                Sleep(300)
                                $g_hTargetGameWin = WinGetHandle("SECURE_BACCARAT_TOOL_9999")
                                If $g_hTargetGameWin = 0 Then $g_hTargetGameWin = $hTarget
                                $bFoundLobby = True
                                ExitLoop
                            EndIf

                            Local $aMsgWait = GUIGetMsg(1)
                            If $aMsgWait[0] = $GUI_EVENT_CLOSE Then Exit

                            ; ---> FIX LỖI KẸT Ở ĐÂY: CHO PHÉP BẤM NÚT ĐỂ HỦY NGAY LẬP TỨC <---
                            If $aMsgWait[0] = $g_hButton_Start Then
                                _UpdateStatus("🛑 Đã hủy quá trình tìm sảnh!")
                                _StopProcess()
                                ExitLoop
                            EndIf

                            ; ---> CẢM BIẾN: NẾU BẠN BẤM DẤU X TẮT WEB, TOOL TẮT THEO TỨC THÌ <---
                            If Not ProcessExists("chromedriver.exe") Then
                                _UpdateStatus("⚠️ Trình duyệt đã bị đóng! Hủy tìm sảnh.")
                                _StopProcess()
                                ExitLoop
                            EndIf

                            Sleep(500)
                        WEnd

                        If $bFoundLobby Then
                            _UpdateStatus("✅ Đã khóa cứng phần cứng trình duyệt! TỰ ĐỘNG CHẠY!")
                            _StartProcess()
                        Else
                            ; Chỉ báo lỗi nếu không phải do người dùng chủ động bấm Hủy
                            If Not $g_bManualStopped Then
                                _HaltProcess("⛔ Lỗi: Hết thời gian. Bạn chưa mở sảnh Nhiều bàn!")
                            EndIf
                        EndIf
                    EndIf
				EndIf
			Case $g_hButton_Stop
				_StopProcess()
			Case $g_hButton_Unlock
				_HandleUnlock()
			Case $g_hButton_Lock
				_ToggleConfigControlsState(False)
			Case $g_hCheckbox_ToggleScan
				_ToggleScanHotkey()
			Case $g_hButton_GetBankerPos
				_GetCoords_Fast($g_hInput_BankerX, $g_hInput_BankerY)
			Case $g_hButton_GetPlayerPos
				_GetCoords_Fast($g_hInput_PlayerX, $g_hInput_PlayerY)
			Case $g_hButton_GetResultTL
				_GetCoords_Fast($g_hInput_ResultX1, $g_hInput_ResultY1)
			Case $g_hButton_GetResultBR
				_GetCoords_Fast($g_hInput_ResultX2, $g_hInput_ResultY2)
			Case $g_hButton_GetBetTimeTL
				_GetCoords_Fast($g_hInput_BetTimeX1, $g_hInput_BetTimeY1)
			Case $g_hButton_GetBetTimeBR
				_GetCoords_Fast($g_hInput_BetTimeX2, $g_hInput_BetTimeY2)
			Case $g_hButton_GetBankerColor
				_GetColor_Fast($g_hInput_BankerColor)
			Case $g_hButton_GetPlayerColor
				_GetColor_Fast($g_hInput_PlayerColor)
			Case $g_hButton_GetTieColor
				_GetColor_Fast($g_hInput_TieColor)
			Case $g_hButton_GetBetTimeColor
				_GetColor_Fast($g_hInput_BetTimeColor)
			Case $g_hButton_TestColor_Result
				 _HandleTestColorButton("Result")
			Case $g_hButton_TestColor_Timer
				 _HandleTestColorButton("Timer")
			Case $g_hCombo_Profiles, $g_hCombo_Profiles_Main
				 _HandleProfileChange($aMsg[0])
			Case $g_hCombo_QLV_Presets
				 _HandleQLVPresetChange()
			Case $g_hButton_SaveQLV
				 _SaveCustomQLV()
			Case $g_hButton_DeleteQLV
				 _DeleteCustomQLV()
		EndSwitch

		For $i = 0 To 4
			If $aMsg[0] = $g_aButton_GetChipPos[$i] Then
				_GetCoords_Fast($g_aInput_ChipX[$i], $g_aInput_ChipY[$i])
			EndIf
		Next
	WEnd
EndFunc
Func _CreateStyledGroup($sTitle, $iX, $iY, $iW, $iH)
	Local $hGroup = GUICtrlCreateGroup($sTitle, $iX, $iY, $iW, $iH, $WS_GROUP, $WS_EX_CLIENTEDGE)
	GUICtrlSetFont($hGroup, 10, 700)
	GUICtrlSetColor($hGroup, 0x0000FF)
	GUICtrlSetBkColor($hGroup, 0xF5F5F5)
	Return $hGroup
EndFunc

Func _CreateGroup_Settings()
	Local $hGroup = _CreateStyledGroup("Vốn & Cài Đặt Cược", 10, 40, 320, 120)
	GUICtrlSetTip(-1, "Khu vực thiết lập số tiền vốn và mức cược khởi điểm.")

	Local $y = 65
	GUICtrlCreateLabel("Vốn ban đầu (VND):", 20, $y, 160, 20)
	$g_hInput_InitialCapital = GUICtrlCreateInput("0", 180, $y - 4, 130, 24)
	GUICtrlSetBkColor($g_hInput_InitialCapital, 0xE0FFFF)
	GUICtrlSetTip(-1, "Nhập tổng số vốn bạn mang vào bàn." & @CRLF & "Ví dụ: 10.000.000")

	$y += 35
	GUICtrlCreateLabel("Giá trị cược (VND):", 20, $y, 160, 20)
	$g_hInput_InitialBet = GUICtrlCreateInput("0", 180, $y - 4, 130, 24)
	GUICtrlSetBkColor($g_hInput_InitialBet, 0xE0FFFF)
	GUICtrlSetTip(-1, "Số tiền cược cho Lệnh 1 (Base Bet)." & @CRLF & "Các lệnh sau sẽ nhân lên dựa theo QLV." & @CRLF & "Ví dụ: 50.000")
EndFunc

Func _CreateGroup_BettingMethod()
    _CreateStyledGroup("Phương Pháp Cược & Tín Hiệu", 10, 165, 320, 420)

    Local $y_start = 190
    Local $x_label = 20
    Local $y = $y_start

    GUICtrlCreateLabel("Nhập công thức cược (Tín hiệu - Đánh):", $x_label, $y, 300, 20)
    GUICtrlSetFont(-1, 9, 700)
    GUICtrlSetColor(-1, 0x0000FF)
    $y += 25

    $g_hInput_CustomRules = GUICtrlCreateEdit("", $x_label, $y, 280, 100, BitOR(0x00200000, 0x00000040, 0x00001000))
    GUICtrlSetFont(-1, 10)
    GUICtrlSetBkColor(-1, 0xFFFACD)
    Local $sDefaultRules = "BBB-P" & @CRLF & "PPP-B" & @CRLF & "BPBP-B" & @CRLF & "PBPB-P"
    GUICtrlSetData($g_hInput_CustomRules, $sDefaultRules)
    $y += 110

    $g_hCheckbox_SeparateQLV = GUICtrlCreateCheckbox("QLV Riêng biệt (Mỗi dòng 1 qlv)", $x_label, $y, 250, 20)
    GUICtrlSetFont(-1, 8.5, 400)
    $y += 35

    $g_hCheckbox_ContinuousMode = GUICtrlCreateCheckbox("Đánh nối đuôi", $x_label, $y, 280, 20)
EndFunc
Func _CreateGroup_QLV_On_Main()
    _CreateStyledGroup("Cấu Hình Quản Lý Vốn", 10, 590, 320, 240)

    Local $y_inner = 615

    ; --- Nhóm con bên trong ---
    $g_hGroup_QLV_Flexible = GUICtrlCreateGroup("", 15, $y_inner - 10, 305, 210)

    ; --- CỘT TRÁI (DANH SÁCH LỆNH) ---
    GUICtrlCreateLabel("Lệnh-Vốn-Thắng-Thua", 20, $y_inner, 150, 15)
    GUICtrlSetFont(-1, 8.5, 700)
    GUICtrlSetColor(-1, 0x800080)

    $g_hInput_CustomQLV_Edit = GUICtrlCreateEdit("", 20, $y_inner + 20, 135, 180, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL))
    GUICtrlSetBkColor($g_hInput_CustomQLV_Edit, 0xF0FFF0)
    GUICtrlSetFont($g_hInput_CustomQLV_Edit, 9)
    GUICtrlSetTip(-1, "Cấu trúc: [Tên Lệnh]-[Hệ Số Vốn]-[Lệnh Sau Khi Thắng]-[Lệnh Sau Khi Thua]" & @CRLF & _
                      "Ví dụ: 0-1-0-1 (Lệnh 0 đánh 1 đơn vị. Thắng về 0, Thua lên 1)" & @CRLF & _
                      "Ví dụ: 1-2-0-2 (Lệnh 1 đánh 2 đơn vị. Thắng về 0, Thua lên 2)")

    ; --- CỘT PHẢI (NÚT BẤM) ---
    GUICtrlCreateLabel("Chọn QLV mẫu:", 165, $y_inner, 100, 20)
    $g_hCombo_QLV_Presets = GUICtrlCreateCombo("", 165, $y_inner + 20, 145, 25, $CBS_DROPDOWNLIST)
    GUICtrlSetTip(-1, "Chọn các kiểu quản lý vốn mẫu (Gấp thếp, Fibonacci, Đều tiền...).")

    $g_hButton_SaveQLV = GUICtrlCreateButton("Lưu", 165, $y_inner + 55, 70, 25)
    GUICtrlSetBkColor(-1, 0x90EE90)
    GUICtrlSetTip(-1, "Lưu bảng QLV hiện tại thành mẫu mới để dùng lại sau này.")

    $g_hButton_DeleteQLV = GUICtrlCreateButton("Xóa", 240, $y_inner + 55, 70, 25)
    GUICtrlSetBkColor(-1, 0xFFB6C1)
    GUICtrlSetTip(-1, "Xóa mẫu QLV đang chọn khỏi danh sách.")

    GUICtrlCreateGroup("", -99, -99, 1, 1)
EndFunc

Func _CreateGroup_StrategyStats()
    ; [THAY ĐỔI] Giảm chiều cao Group xuống 250 (Cũ là 350) để tiết kiệm 100px
    _CreateStyledGroup("Thống Kê Hiệu Suất (Chi Tiết Từng Dòng)", 340, 40, 500, 250)

    ; [THAY ĐỔI] Giảm chiều cao ListView xuống 220 cho vừa khung mới
    $g_hListView_Stats = GUICtrlCreateListView("Công Thức |Thắng|Thua|% Win|Max Win|Max Loss", 350, 60, 480, 220, BitOR($LVS_REPORT, $LVS_SHOWSELALWAYS, $LVS_SINGLESEL))

    ; Căn chỉnh chiều rộng cột (Giữ nguyên)
    _GUICtrlListView_SetColumnWidth($g_hListView_Stats, 0, 120) ; Cột Công thức
    _GUICtrlListView_SetColumnWidth($g_hListView_Stats, 1, 60)  ; Cột Thắng
    _GUICtrlListView_SetColumnWidth($g_hListView_Stats, 2, 60)  ; Cột Thua
    _GUICtrlListView_SetColumnWidth($g_hListView_Stats, 3, 70)  ; Cột %
    _GUICtrlListView_SetColumnWidth($g_hListView_Stats, 4, 70)  ; Cột Max Win
    _GUICtrlListView_SetColumnWidth($g_hListView_Stats, 5, 70)  ; Cột Max Loss

    ; Thêm menu chuột phải (Giữ nguyên)
    Local $hContext = GUICtrlCreateContextMenu($g_hListView_Stats)
    Local $hMenuResetRow = GUICtrlCreateMenuItem("Reset dòng đang chọn", $hContext)
    ; GUICtrlSetOnEvent($hMenuResetRow, "_ResetSelectedStatRow")
EndFunc

Func _CreateGroup_BPT_Totals()
    ; [THAY ĐỔI] Đẩy Y lên 300 (Cũ là 400)
    _CreateStyledGroup("Tổng", 340, 300, 500, 100)

    Local $y_line1 = 320, $h = 25 ; [THAY ĐỔI] Y nội bộ cũng giảm theo 100px
    Local $x_b = 380, $x_p = 540, $x_t = 700
    Local $w_label = 20, $w_val = 60

    GUICtrlCreateLabel("B:", $x_b, $y_line1, $w_label, $h, $SS_CENTER)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0xF70102)
    $g_hLabel_TotalB_Val = GUICtrlCreateLabel("0", $x_b + $w_label, $y_line1, $w_val, $h)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0xF70102)

    GUICtrlCreateLabel("P:", $x_p, $y_line1, $w_label, $h, $SS_CENTER)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0x0182FA)
    $g_hLabel_TotalP_Val = GUICtrlCreateLabel("0", $x_p + $w_label, $y_line1, $w_val, $h)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0x0182FA)

    GUICtrlCreateLabel("T:", $x_t, $y_line1, $w_label, $h, $SS_CENTER)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0x29BC2F)
    $g_hLabel_TotalT_Val = GUICtrlCreateLabel("0", $x_t + $w_label, $y_line1, $w_val, $h)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0x29BC2F)

    Local $y_line2 = 360 ; [THAY ĐỔI] Y dòng 2 (Cũ là 460)
    Local $w_total_label = 120, $w_total_val = 100
    Local $x_center = 340 + (500 / 2)
    Local $x_total_label = $x_center - (($w_total_label + $w_total_val) / 2)
    Local $x_total_val = $x_total_label + $w_total_label

    GUICtrlCreateLabel("Tổng số ván:", $x_total_label, $y_line2, $w_total_label, 25)
    GUICtrlSetFont(-1, 12, 800)
    GUICtrlSetColor(-1, 0x800080)
    $g_hLabel_TotalHands = GUICtrlCreateLabel("0", $x_total_val, $y_line2, $w_total_val, 25)
    GUICtrlSetFont($g_hLabel_TotalHands, 12, 800)
    GUICtrlSetColor($g_hLabel_TotalHands, 0x800080)
EndFunc

Func _CreateGroup_HistoryDisplay()
    ; [THAY ĐỔI] Đẩy Y lên 410 (Cũ là 510)
    _CreateStyledGroup("Lịch Sử Cầu", 340, 410, 500, 185)

    Local Const $iCols = 20, $iRows = 6
    Local $labelWidth = 15.5, $labelHeight = 14.5
    Local $xSpacing = 9, $ySpacing = 5
    Local $groupX = 340, $groupWidth = 500

    ; [THAY ĐỔI] Y bắt đầu vẽ lưới cũng thay đổi theo (410 + 25 = 435)
    Local $yStart = 435

    Local $totalGridWidth = ($iCols * $labelWidth) + (($iCols - 1) * $xSpacing)
    Local $xStart = $groupX + ($groupWidth - $totalGridWidth) / 2

    For $iRow = 0 To $iRows - 1
        For $iCol = 0 To $iCols - 1
            Local $iIndex = $iCol + ($iRow * $iCols)
            Local $xPos = $xStart + $iCol * ($labelWidth + $xSpacing)
            Local $yPos = $yStart + $iRow * ($labelHeight + $ySpacing)
            $g_aLabel_History[$iIndex] = GUICtrlCreateLabel("-", $xPos, $yPos, $labelWidth, $labelHeight, $SS_CENTER)
            _StyleResultLabel($g_aLabel_History[$iIndex], "-", False, False)
        Next
    Next

    Local $y_input = $yStart + ($iRows * ($labelHeight + $ySpacing)) + 10
    GUICtrlCreateLabel("🚀 Giới hạn lịch sử bảng cầu giọt nước:", $xStart, $y_input + 3, 290, 20)
    GUICtrlSetFont(-1, 9, 600)
    $g_hInput_HistoryLimit = GUICtrlCreateInput("50", $xStart + 295, $y_input, 50, 22, 0x2001)
    GUICtrlSetBkColor(-1, 0xFFFACD)
EndFunc

Func _CreateGroup_HistoryLog()
    _CreateStyledGroup("Bộ Lọc: Blacklist (Né Cầu)", 340, 605, 500, 150) ; Tăng chiều cao lên chút
    Local $x = 350
    Local $y = 630

    ; Checkbox Bật/Tắt chính
    $g_hCheckbox_Blacklist = GUICtrlCreateCheckbox("⛔ Bật tính năng Né Cầu (Blacklist):", $x, $y, 250, 20)
    GUICtrlSetColor(-1, 0xFF0000)
    GUICtrlSetFont(-1, 9, 700)

    $y += 30
    $g_hInput_Blacklist = GUICtrlCreateInput("", $x, $y, 480, 24)
    GUICtrlSetBkColor(-1, 0xF0F0F0)
    GUICtrlSetTip(-1, "Nhập các chuỗi cần né, cách nhau bằng dấu phẩy. Ví dụ: BBBBBB,PPPPPP")

    ; --- [KHÔI PHỤC] CHECKBOX NÀY ---
    $y += 30
    $g_hCheckbox_Blacklist_IgnoreRunning = GUICtrlCreateCheckbox("🚀 Đang theo dây thì bỏ qua check Blacklist (Đánh hết chuỗi mới thôi)", $x, $y, 480, 20)
    GUICtrlSetFont(-1, 8.5, 400)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetTip(-1, "Nếu đang đánh dở chuỗi (Custom/Copy) mà gặp Blacklist: Tích vào đây để đánh tiếp, Bỏ tích để dừng lại.")
EndFunc

Func _CreateGroup_InfoAndTargets()
	_CreateStyledGroup("Thông Tin & Mục Tiêu", 850, 40, 410, 360)
	Local $x = 860, $y = 65, $w = 390
	GUICtrlCreateLabel("Số dư hiện tại:", $x, $y, 150, 20)
	$g_hLabel_CurrentBalance = GUICtrlCreateLabel("0 VND", $x, $y + 20, $w, 30, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_CurrentBalance, 16, 800)
	GUICtrlSetBkColor($g_hLabel_CurrentBalance, 0xFFFACD)
	GUICtrlSetColor($g_hLabel_CurrentBalance, 0x0000FF)
    GUICtrlSetTip(-1, "Tổng số tiền hiện tại (Vốn gốc + Lãi/Lỗ).")

	$y += 60
	GUICtrlCreateLabel("Lợi nhuận hiện tại:", $x, $y, 150, 20)
	$g_hLabel_Profit = GUICtrlCreateLabel("0 VND", $x, $y + 20, $w, 30, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_Profit, 16, 800)
	GUICtrlSetBkColor($g_hLabel_Profit, 0xFFFACD)
    GUICtrlSetTip(-1, "Số tiền lãi hoặc lỗ tính từ lúc bấm Bắt Đầu.")

	$y += 60
	GUICtrlCreateLabel("Tổng volume giao dịch:", $x, $y, 200, 20)
	$g_hLabel_TotalVolume = GUICtrlCreateLabel("0 VND", $x, $y + 20, $w, 30, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_TotalVolume, 16, 800)
	GUICtrlSetBkColor($g_hLabel_TotalVolume, 0xFFE4B5)
	GUICtrlSetColor($g_hLabel_TotalVolume, 0x8A2BE2)
    GUICtrlSetTip(-1, "Tổng số tiền đã đặt cược (Doanh thu cược).")

	$y += 60
	GUICtrlCreateLabel("Chốt lời (VND):", $x, $y, $w, 20)
	$g_hInput_TakeProfit = GUICtrlCreateInput("0", $x, $y + 20, $w, 24)
	GUICtrlSetBkColor($g_hInput_TakeProfit, 0xE0FFFF)
    GUICtrlSetTip(-1, "Nhập mức Lãi mục tiêu. Khi Lợi Nhuận đạt mức này, Tool sẽ tự dừng." & @CRLF & "Nhập 0 để tắt.")

	$y += 50
	GUICtrlCreateLabel("Cắt lỗ (VND):", $x, $y, $w, 20)
	$g_hInput_StopLoss = GUICtrlCreateInput("0", $x, $y + 20, $w, 24)
	GUICtrlSetBkColor($g_hInput_StopLoss, 0xE0FFFF)
    GUICtrlSetTip(-1, "Nhập mức Lỗ tối đa. Khi Lợi Nhuận ÂM đến mức này, Tool sẽ tự dừng." & @CRLF & "Nhập 0 để tắt.")

	$y += 50
	$g_hLabel_Time = GUICtrlCreateLabel("00:00:00", $x, $y, $w, 30, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_Time, 16, 800)
	GUICtrlSetBkColor($g_hLabel_Time, 0xF0F8FF)
	GUICtrlSetColor($g_hLabel_Time, 0x00008B)
EndFunc

Func _CreateGroup_UserConfig_Main()
    _CreateStyledGroup("Điều Khiển & Tùy Chọn Nhanh", 850, 405, 410, 380)
    Local $x = 860, $y = 430
    ; --- DÒNG 1: CHỌN SẢNH ---
    GUICtrlCreateLabel("Cấu hình:", $x, $y, 60, 20)
    $g_hCombo_Profiles_Main = GUICtrlCreateCombo("", $x + 70, $y - 2, 320, 25, $CBS_DROPDOWNLIST)
    GUICtrlSetTip(-1, "Chọn cấu hình (Tọa độ/Màu sắc) tương ứng với bàn cược bạn đang mở.")
    $y += 35

    ; --- DÒNG 2: CHẾ ĐỘ CLICK ---
    GUICtrlCreateLabel("Click:", $x, $y, 60, 20)
    $g_hRadio_ClickMode_Control_Main = GUICtrlCreateRadio("Nhanh", $x + 70, $y, 90, 20)
    GUICtrlSetTip(-1, "Chế độ ControlClick: Click ẩn, chuột không di chuyển.")

    $g_hRadio_ClickMode_Mouse_Main = GUICtrlCreateRadio("Chuột", $x + 170, $y, 140, 20)
    GUICtrlSetTip(-1, "Chế độ MouseClick: Chuột sẽ tự di chuyển đến vị trí cược.")
    GUICtrlCreateGroup("", -99, -99, 1, 1)
    $y += 30

    ; --- DÒNG 3: DELAY ---
    GUICtrlCreateLabel("TĐ Click:", $x, $y, 80, 20)
    $g_hInput_ClickDelay_Main = GUICtrlCreateInput("10", $x + 90, $y - 2, 50, 24)
    GUICtrlSetTip(-1, "Thời gian nghỉ giữa các lần click (ms).")
    $y += 35

    ; --- DÒNG 4: TỐC ĐỘ CHUỘT ---
    GUICtrlCreateLabel("TĐ Di chuyển:", $x, $y, 90, 20)
    $g_hInput_MouseSpeed = GUICtrlCreateInput("0", $x + 90, $y - 2, 50, 24)
    GUICtrlSetTip(-1, "Tốc độ di chuột (0 = Tức thì).")

    ; >>> ĐÃ XÓA SẠCH NÚT ĐỒNG BỘ 12 BÀN Ở ĐÂY <<<
    $y += 60 ; Tăng khoảng cách đẩy nút Bắt đầu xuống cho đẹp

    $g_hButton_Start = GUICtrlCreateButton("ĐĂNG NHẬP", $x + 50, $y, 250, 45)
    GUICtrlSetFont($g_hButton_Start, 12, 700)
    GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
    GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
EndFunc

Func _CreateGroup_LicenseInfo()
    ; Đổi y_start từ 655 thành 745 (đẩy xuống dưới)
    Local $y_start = 745, $x_start = 850, $width = 410, $height = 65
    Local $hGroup = _CreateStyledGroup("Thông Tin Giấy phép", $x_start, $y_start, $width, $height)
    Local $inner_x_start = $x_start + 10, $inner_y_start = $y_start + 25

    GUICtrlCreateLabel("Hạn sử dụng:", $inner_x_start, $inner_y_start, 80, 20)
    $g_hLabel_ExpiryDate = GUICtrlCreateLabel("N/A", $inner_x_start + 90, $inner_y_start, 100, 20, BitOR($SS_CENTER, $SS_SUNKEN))
    GUICtrlSetFont($g_hLabel_ExpiryDate, 10, 700)
    GUICtrlSetBkColor($g_hLabel_ExpiryDate, 0xFFFACD)

    GUICtrlCreateLabel("Còn lại:", $inner_x_start + 200, $inner_y_start, 60, 20)
    $g_hLabel_DaysRemaining = GUICtrlCreateLabel("N/A", $inner_x_start + 260, $inner_y_start, 130, 20, BitOR($SS_CENTER, $SS_SUNKEN))
    GUICtrlSetFont($g_hLabel_DaysRemaining, 10, 700)
    GUICtrlSetBkColor($g_hLabel_DaysRemaining, 0xFFFACD)
EndFunc

Func _CreateTab_ConfigHelper()
    _CreateStyledGroup("Quét Thông Tin Trực Tiếp", 15, 40, 1240, 80)
    GUICtrlCreateLabel("Tọa độ X:", 25, 70, 70, 20)
    $g_hInput_ScanX = GUICtrlCreateInput("", 100, 68, 80, 24, $ES_READONLY)
    GUICtrlCreateLabel("Tọa độ Y:", 200, 70, 70, 20)
    $g_hInput_ScanY = GUICtrlCreateInput("", 275, 68, 80, 24, $ES_READONLY)
    GUICtrlCreateLabel("Mã màu HEX:", 375, 70, 90, 20)
    $g_hInput_ScanColor = GUICtrlCreateInput("", 470, 68, 100, 24, $ES_READONLY)
    $g_hLabel_ScanColorPreview = GUICtrlCreateLabel("", 580, 68, 50, 24, $SS_SUNKEN)

    $g_hCheckbox_ToggleScan = GUICtrlCreateCheckbox("Bật phím '`' để quét", 650, 70, 150, 20)
    GUICtrlSetTip(-1, "Tích vào đây, sau đó di chuột đến điểm cần lấy trên game, bấm phím ` (cạnh số 1) để xem tọa độ/màu.")

    GUICtrlSetData($g_hInput_ScanColor, "0x000000")
    GUICtrlSetBkColor($g_hLabel_ScanColorPreview, 0x000000)
    AdlibRegister("_UpdateColorPreview", 250)

    ; --- CỘT TRÁI: CẤU HÌNH TỌA ĐỘ & MÀU SẮC ---
    _CreateStyledGroup("Thiết Lập Tọa Độ & Màu Sắc", 15, 130, 600, 480)
    Local $x_col1 = 25, $y_start = 155, $y_step = 35
    Local $y1 = $y_start

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Class cửa sổ Game:", $x_col1, $y1, 150, 20))
    $g_hInput_WindowClass = GUICtrlCreateInput("", $x_col1 + 160, $y1 - 2, 280, 24)
    GUICtrlSetTip(-1, "Tên lớp cửa sổ (Window Class) của trình duyệt hoặc app game. Dùng AutoIt Info Tool để lấy.")
    _ArrayAdd($g_aConfigControls, $g_hInput_WindowClass)
    $y1 += $y_step

    ; -- BANKER / PLAYER POS --
    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Nút Banker (X, Y):", $x_col1, $y1, 150, 20))
    $g_hInput_BankerX = GUICtrlCreateInput("", $x_col1 + 160, $y1 - 2, 60, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_BankerX)
    $g_hInput_BankerY = GUICtrlCreateInput("", $x_col1 + 225, $y1 - 2, 60, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_BankerY)
    $g_hButton_GetBankerPos = GUICtrlCreateButton("Lấy", $x_col1 + 295, $y1 - 4, 50, 28)
    GUICtrlSetTip(-1, "Di chuột vào nút BANKER trên bàn chơi -> Bấm phím S -> Bấm nút Lấy này.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetBankerPos)
    $y1 += $y_step

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Nút Player (X, Y):", $x_col1, $y1, 150, 20))
    $g_hInput_PlayerX = GUICtrlCreateInput("", $x_col1 + 160, $y1 - 2, 60, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_PlayerX)
    $g_hInput_PlayerY = GUICtrlCreateInput("", $x_col1 + 225, $y1 - 2, 60, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_PlayerY)
    $g_hButton_GetPlayerPos = GUICtrlCreateButton("Lấy", $x_col1 + 295, $y1 - 4, 50, 28)
    GUICtrlSetTip(-1, "Di chuột vào nút PLAYER trên bàn chơi -> Bấm phím S -> Bấm nút Lấy này.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetPlayerPos)
    $y1 += $y_step + 10

    ; -- KHU VỰC KẾT QUẢ --
    GUICtrlCreateLabel("--- Cấu hình Nhận diện Kết quả ---", $x_col1, $y1, 300, 20)
    GUICtrlSetColor(-1, 0x0000FF)
    $y1 += 25

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Màu B/P:", $x_col1, $y1, 60, 20))
    $g_hInput_BankerColor = GUICtrlCreateInput("", $x_col1 + 65, $y1 - 2, 80, 24)
    GUICtrlSetTip(-1, "Mã màu đặc trưng của BANKER (Thường là màu đỏ).")
    _ArrayAdd($g_aConfigControls, $g_hInput_BankerColor)
    $g_hButton_GetBankerColor = GUICtrlCreateButton("Lấy B", $x_col1 + 150, $y1 - 4, 45, 28)
    GUICtrlSetTip(-1, "Di chuột vào màu Đỏ của Banker -> Bấm S -> Bấm nút này.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetBankerColor)

    $g_hInput_PlayerColor = GUICtrlCreateInput("", $x_col1 + 205, $y1 - 2, 80, 24)
    GUICtrlSetTip(-1, "Mã màu đặc trưng của PLAYER (Thường là màu xanh).")
    _ArrayAdd($g_aConfigControls, $g_hInput_PlayerColor)
    $g_hButton_GetPlayerColor = GUICtrlCreateButton("Lấy P", $x_col1 + 290, $y1 - 4, 45, 28)
    GUICtrlSetTip(-1, "Di chuột vào màu Xanh của Player -> Bấm S -> Bấm nút này.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetPlayerColor)
    $y1 += $y_step

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Màu Tie:", $x_col1, $y1, 60, 20))
    $g_hInput_TieColor = GUICtrlCreateInput("", $x_col1 + 65, $y1 - 2, 80, 24)
    GUICtrlSetTip(-1, "Mã màu đặc trưng của HÒA (Thường là màu xanh lá).")
    _ArrayAdd($g_aConfigControls, $g_hInput_TieColor)
    $g_hButton_GetTieColor = GUICtrlCreateButton("Lấy T", $x_col1 + 150, $y1 - 4, 45, 28)
    GUICtrlSetTip(-1, "Di chuột vào màu Xanh Lá của Tie -> Bấm S -> Bấm nút này.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetTieColor)

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Sai số:", $x_col1 + 205, $y1, 45, 20))
    $g_hInput_Shade_Result = GUICtrlCreateInput("10", $x_col1 + 250, $y1 - 2, 35, 24)
    GUICtrlSetTip(-1, "Độ lệch màu cho phép (0-255). Nên để 10-20.")
    _ArrayAdd($g_aConfigControls, $g_hInput_Shade_Result)
    $g_hButton_TestColor_Result = GUICtrlCreateButton("Test Màu", $x_col1 + 290, $y1 - 4, 80, 28)
    GUICtrlSetTip(-1, "Bấm để kiểm tra xem Tool có nhận diện đúng kết quả hiện tại trên màn hình không.")
    _ArrayAdd($g_aConfigControls, $g_hButton_TestColor_Result)
    $y1 += $y_step

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Vùng quét KQ (X1,Y1 - X2,Y2):", $x_col1, $y1, 350, 20))
    $y1 += 22
    $g_hInput_ResultX1 = GUICtrlCreateInput("", $x_col1, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_ResultX1)
    $g_hInput_ResultY1 = GUICtrlCreateInput("", $x_col1 + 55, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_ResultY1)
    $g_hButton_GetResultTL = GUICtrlCreateButton("Lấy", $x_col1 + 110, $y1 - 4, 40, 28)
    GUICtrlSetTip(-1, "Lấy góc TRÊN-TRÁI của vùng hiện kết quả.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetResultTL)

    $g_hInput_ResultX2 = GUICtrlCreateInput("", $x_col1 + 160, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_ResultX2)
    $g_hInput_ResultY2 = GUICtrlCreateInput("", $x_col1 + 215, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_ResultY2)
    $g_hButton_GetResultBR = GUICtrlCreateButton("Lấy", $x_col1 + 270, $y1 - 4, 40, 28)
    GUICtrlSetTip(-1, "Lấy góc DƯỚI-PHẢI của vùng hiện kết quả.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetResultBR)
    $y1 += $y_step + 10

    ; -- KHU VỰC GIỜ CƯỢC --
    GUICtrlCreateLabel("--- Cấu hình Giờ Cược ---", $x_col1, $y1, 300, 20)
    GUICtrlSetColor(-1, 0x008000)
    $y1 += 25
    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Màu Giờ Cược:", $x_col1, $y1, 100, 20))
    $g_hInput_BetTimeColor = GUICtrlCreateInput("", $x_col1 + 110, $y1 - 2, 80, 24)
    GUICtrlSetTip(-1, "Màu xuất hiện khi bàn cho phép đặt cược (Ví dụ: Màu xanh của đồng hồ đếm ngược).")
    _ArrayAdd($g_aConfigControls, $g_hInput_BetTimeColor)
    $g_hButton_GetBetTimeColor = GUICtrlCreateButton("Lấy", $x_col1 + 200, $y1 - 4, 40, 28)
    _ArrayAdd($g_aConfigControls, $g_hButton_GetBetTimeColor)

    GUICtrlCreateLabel("Dung sai:", $x_col1 + 250, $y1, 60, 20)
    $g_hInput_Shade_Timer = GUICtrlCreateInput("20", $x_col1 + 310, $y1 - 2, 40, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_Shade_Timer)
    $g_hButton_TestColor_Timer = GUICtrlCreateButton("Test", $x_col1 + 360, $y1 - 4, 50, 28)
    GUICtrlSetTip(-1, "Kiểm tra xem Tool có nhìn thấy giờ cược không.")
    _ArrayAdd($g_aConfigControls, $g_hButton_TestColor_Timer)
    $y1 += $y_step

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Vùng Giờ Cược (X1,Y1-X2,Y2):", $x_col1, $y1, 350, 20))
    $y1 += 22
    $g_hInput_BetTimeX1 = GUICtrlCreateInput("", $x_col1, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_BetTimeX1)
    $g_hInput_BetTimeY1 = GUICtrlCreateInput("", $x_col1 + 55, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_BetTimeY1)
    $g_hButton_GetBetTimeTL = GUICtrlCreateButton("Lấy", $x_col1 + 110, $y1 - 4, 40, 28)
    GUICtrlSetTip(-1, "Góc TRÊN-TRÁI vùng đếm ngược.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetBetTimeTL)

    $g_hInput_BetTimeX2 = GUICtrlCreateInput("", $x_col1 + 160, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_BetTimeX2)
    $g_hInput_BetTimeY2 = GUICtrlCreateInput("", $x_col1 + 215, $y1 - 2, 50, 24)
    _ArrayAdd($g_aConfigControls, $g_hInput_BetTimeY2)
    $g_hButton_GetBetTimeBR = GUICtrlCreateButton("Lấy", $x_col1 + 270, $y1 - 4, 40, 28)
    GUICtrlSetTip(-1, "Góc DƯỚI-PHẢI vùng đếm ngược.")
    _ArrayAdd($g_aConfigControls, $g_hButton_GetBetTimeBR)

    ; --- CỘT PHẢI: CHIP ---
    Local $x_adv = 630
    Local $y_chip_group_start = 130
    _CreateStyledGroup("Cấu Hình Các Loại Chip Cược", $x_adv, $y_chip_group_start, 620, 210)

    Local $x_chip = $x_adv + 10
    Local $y_chip = $y_chip_group_start + 25
    Local $y_chip_step = 32

    For $i = 0 To 4
        $g_aCheckbox_ChipEnabled[$i] = GUICtrlCreateCheckbox("Chip " & $i + 1, $x_chip, $y_chip, 60, 20)
        GUICtrlSetTip(-1, "Tích để sử dụng Chip này.")
        _ArrayAdd($g_aConfigControls, $g_aCheckbox_ChipEnabled[$i])

        _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Giá trị:", $x_chip + 70, $y_chip, 50, 20))
        $g_aInput_ChipValue[$i] = GUICtrlCreateInput("", $x_chip + 120, $y_chip - 2, 80, 24)
        GUICtrlSetTip(-1, "Giá trị thực của chip trong game (VD: 5k thì nhập 5000).")
        _ArrayAdd($g_aConfigControls, $g_aInput_ChipValue[$i])

        _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("X, Y:", $x_chip + 210, $y_chip, 35, 20))
        $g_aInput_ChipX[$i] = GUICtrlCreateInput("", $x_chip + 250, $y_chip - 2, 50, 24)
        _ArrayAdd($g_aConfigControls, $g_aInput_ChipX[$i])
        $g_aInput_ChipY[$i] = GUICtrlCreateInput("", $x_chip + 305, $y_chip - 2, 50, 24)
        _ArrayAdd($g_aConfigControls, $g_aInput_ChipY[$i])

        $g_aButton_GetChipPos[$i] = GUICtrlCreateButton("Lấy", $x_chip + 365, $y_chip - 4, 60, 28)
        GUICtrlSetTip(-1, "Di chuột vào hình Chip " & $i+1 & " trong game -> Bấm S -> Bấm nút Lấy.")
        _ArrayAdd($g_aConfigControls, $g_aButton_GetChipPos[$i])
        $y_chip += $y_chip_step
    Next

    ; --- QUẢN LÝ CẤU HÌNH SẢNH ---
    _CreateStyledGroup("Quản Lý Cấu Hình Sảnh", 15, 620, 1240, 80)
    Local $x_prof = 25, $y_prof = 645

    _ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Chọn cấu hình sảnh:", $x_prof, $y_prof, 120, 20))
    $g_hCombo_Profiles = GUICtrlCreateCombo("", $x_prof + 130, $y_prof - 2, 200, 25, $CBS_DROPDOWNLIST)
    GUICtrlSetTip(-1, "Chọn danh sách các bàn đã lưu.")
    _ArrayAdd($g_aConfigControls, $g_hCombo_Profiles)

    $g_hButton_Unlock = GUICtrlCreateButton("Mở Khóa Cấu Hình", $x_prof + 600, $y_prof - 4, 150, 30)
    GUICtrlSetFont(-1, 9, 700)
    GUICtrlSetColor(-1, 0x008000)
    GUICtrlSetTip(-1, "Mở khóa để chỉnh sửa tọa độ và màu sắc.")

    $g_hButton_Lock = GUICtrlCreateButton("Khóa Cấu Hình", $x_prof + 600, $y_prof - 4, 150, 30)
    GUICtrlSetFont(-1, 9, 700)
    GUICtrlSetColor(-1, 0xFF0000)
    GUICtrlSetTip(-1, "Khóa lại để tránh bấm nhầm.")
    GUICtrlSetState($g_hButton_Lock, $GUI_HIDE)
EndFunc

; ==================================================================================================
; --- CÁC HÀM XỬ LÝ SỰ KIỆN & TRẠNG THÁI ---
; ==================================================================================================
Func _HandleUnlock()
	Local $sPass = InputBox("Yêu cầu mật khẩu", "Vui lòng nhập mật khẩu của nhà phát triển:", "", "*")
	If @error Then Return
	If $sPass = $g_sDevPassword Then
		MsgBox(64, "Thành công", "Đã mở khóa Tab Cấu hình.")
		_ToggleConfigControlsState(True)
	Else
		MsgBox(16, "Lỗi", "Mật khẩu không chính xác.")
	EndIf
EndFunc

Func _ToggleConfigControlsState($bEnable)
	Local $iState = $bEnable ? $GUI_ENABLE : $GUI_DISABLE
	$g_bConfigUnlocked = $bEnable
	For $hControl In $g_aConfigControls
		GUICtrlSetState($hControl, $iState)
	Next
	If $bEnable Then
		GUICtrlSetState($g_hButton_Unlock, $GUI_HIDE)
		GUICtrlSetState($g_hButton_Lock, $GUI_SHOW)
	Else
		GUICtrlSetState($g_hButton_Unlock, $GUI_SHOW)
		GUICtrlSetState($g_hButton_Lock, $GUI_HIDE)
	EndIf
EndFunc

Func _ToggleScanHotkey()
	If GUICtrlRead($g_hCheckbox_ToggleScan) = $GUI_CHECKED Then
		HotKeySet("`", "_UpdateScannerInfo")
	Else
		HotKeySet("`")
	EndIf
EndFunc

Func _UpdateScannerInfo()
    Local $aPos = MouseGetPos()
    Local $iColor = PixelGetColor($aPos[0], $aPos[1])

    ; 1. LƯU VÀO BIẾN TẠM (QUAN TRỌNG)
    $g_iTempX = $aPos[0]
    $g_iTempY = $aPos[1]
    $g_iTempColor = $iColor

    ; 2. Hiển thị lên thanh Review (Trên cùng giao diện)
    Local $sHexColor = "0x" & Hex($iColor, 6)
    GUICtrlSetData($g_hInput_ScanX, $aPos[0])
    GUICtrlSetData($g_hInput_ScanY, $aPos[1])
    GUICtrlSetData($g_hInput_ScanColor, $sHexColor)
    GUICtrlSetBkColor($g_hLabel_ScanColorPreview, $iColor)
EndFunc

Func _UpdateColorPreview()
	Local $sColor = GUICtrlRead($g_hInput_ScanColor)
	If StringIsXDigit(StringTrimLeft($sColor, 2)) Then
		GUICtrlSetBkColor($g_hLabel_ScanColorPreview, Number($sColor))
	EndIf
EndFunc

Func _HandleTestColorButton($sArea)
    Local $hWnd = WinGetHandle("[CLASS:" & GUICtrlRead($g_hInput_WindowClass) & "]")
    If @error Then
        ToolTip("⚠️ Lỗi: Không tìm thấy cửa sổ game!", MouseGetPos()[0], MouseGetPos()[1])
        Sleep(2000)
        ToolTip("")
        Return
    EndIf

    Local $iX1, $iY1, $iX2, $iY2, $iTolerance, $iColorTarget
    Local $sMsgSuccess = "OK! Tìm thấy màu."
    Local $bFound = False

    Switch $sArea
        Case "Result"
            $iX1 = Number(GUICtrlRead($g_hInput_ResultX1))
            $iY1 = Number(GUICtrlRead($g_hInput_ResultY1))
            $iX2 = Number(GUICtrlRead($g_hInput_ResultX2))
            $iY2 = Number(GUICtrlRead($g_hInput_ResultY2))
            $iTolerance = Number(GUICtrlRead($g_hInput_Shade_Result))

            Local $iColB = Number(GUICtrlRead($g_hInput_BankerColor))
            Local $iColP = Number(GUICtrlRead($g_hInput_PlayerColor))
            Local $iColT = Number(GUICtrlRead($g_hInput_TieColor))

            If $iX2 = 0 Then $iX2 = $iX1 + 1
            If $iY2 = 0 Then $iY2 = $iY1 + 1

            If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColB, $iTolerance, 1, $hWnd)) Then
                $bFound = True
                $sMsgSuccess = "OK! Tìm thấy: BANKER"
            ElseIf IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColP, $iTolerance, 1, $hWnd)) Then
                $bFound = True
                $sMsgSuccess = "OK! Tìm thấy: PLAYER"
            ElseIf IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColT, $iTolerance, 1, $hWnd)) Then
                $bFound = True
                $sMsgSuccess = "OK! Tìm thấy: HÒA (TIE)"
            EndIf

        Case "Timer"
            $iX1 = Number(GUICtrlRead($g_hInput_BetTimeX1))
            $iY1 = Number(GUICtrlRead($g_hInput_BetTimeY1))
            $iX2 = Number(GUICtrlRead($g_hInput_BetTimeX2))
            $iY2 = Number(GUICtrlRead($g_hInput_BetTimeY2))
            $iColorTarget = Number(GUICtrlRead($g_hInput_BetTimeColor))
            $iTolerance = Number(GUICtrlRead($g_hInput_Shade_Timer))

            If $iX2 = 0 Then $iX2 = $iX1 + 1
            If $iY2 = 0 Then $iY2 = $iY1 + 1

            If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColorTarget, $iTolerance, 1, $hWnd)) Then $bFound = True
    EndSwitch

    Local $aMouse = MouseGetPos()
    If $bFound Then
        ToolTip($sMsgSuccess, $aMouse[0], $aMouse[1] - 30, "Thành Công", 1)
    Else
        ToolTip("KHÔNG THẤY! Kiểm tra lại vùng quét hoặc màu.", $aMouse[0], $aMouse[1] - 30, "Thất Bại", 3)
    EndIf

    Sleep(1500)
    ToolTip("")
EndFunc

; --- CÁC HÀM QUẢN LÝ CẤU HÌNH SẢNH (HỆ THỐNG FILE INI) ---
; ==================================================================================================
Func _PopulateProfileList()
	Local $aSectionNames = IniReadSectionNames($g_sIniPath)
	If @error Or $aSectionNames[0] = 0 Then
		_CreateDefaultIniFile()
		$aSectionNames = IniReadSectionNames($g_sIniPath)
		If @error Or $aSectionNames[0] = 0 Then
			MsgBox(16, "Lỗi nghiêm trọng", "Không thể tạo hoặc đọc file config '" & $g_sIniPath & "'.")
			Exit
		EndIf
	EndIf

	GUICtrlSetData($g_hCombo_Profiles, "")
	GUICtrlSetData($g_hCombo_Profiles_Main, "")
	Local $sProfileList = ""

	For $i = 1 To $aSectionNames[0]
		If StringLeft($aSectionNames[$i], 8) = "Profile_" Then
			Local $sProfileName = StringTrimLeft($aSectionNames[$i], 8)
			$sProfileList &= $sProfileName & "|"
		EndIf
	Next

	If $sProfileList <> "" Then
		$sProfileList = StringTrimRight($sProfileList, 1)
	EndIf

	GUICtrlSetData($g_hCombo_Profiles, $sProfileList)
	GUICtrlSetData($g_hCombo_Profiles_Main, $sProfileList)
EndFunc

Func _HandleProfileChange($hTriggeredCombo)
    Local $sNewProfile = GUICtrlRead($hTriggeredCombo)
    If $sNewProfile = "" Then Return

    If $g_sCurrentLoadedProfile <> "" And $g_sCurrentLoadedProfile <> $sNewProfile Then
        _MasterSave($g_sCurrentLoadedProfile) ; Tự lưu bàn cũ trước khi qua bàn mới
    EndIf

    ; Đồng bộ 2 combo box (Main và Config)
    If $hTriggeredCombo = $g_hCombo_Profiles Then
        GUICtrlSetData($g_hCombo_Profiles_Main, $sNewProfile)
    Else
        GUICtrlSetData($g_hCombo_Profiles, $sNewProfile)
    EndIf

    _LoadSelectedProfile($sNewProfile)
    GUICtrlSetData($g_hInput_ProfileName, $sNewProfile)
    _GetAndValidateInputs()

    ; Cập nhật biến theo dõi để biết đang ở bàn nào
    $g_sCurrentLoadedProfile = $sNewProfile

    ; --- [THÊM ĐOẠN NÀY] ĐỂ HIỆN THÔNG TIN ĐỒNG BỘ ---
    Local $sTP = GUICtrlRead($g_hInput_TakeProfit)
    Local $sSL = GUICtrlRead($g_hInput_StopLoss)

    ; Chọn 1 trong 2 kiểu hiển thị bạn thích:

    ; Kiểu 1: Đơn giản (Tên bàn)
    _UpdateStatus("✅ Đã chuyển sang: [" & $sNewProfile & "] - Sẵn sàng chiến đấu!")

    ; Kiểu 2: Chi tiết (Mục tiêu) - Nếu thích kiểu này thì bỏ dấu ; ở đầu dòng dưới
    ; _UpdateStatus("🔄 Đã nạp [" & $sNewProfile & "] | Mục tiêu: Lãi " & $sTP & " / Lỗ " & $sSL)
EndFunc

Func _LoadSelectedProfile($sProfileName)
    If $sProfileName = "" Then Return

    Local $sSection = "Profile_" & $sProfileName
    Local $sFileToRead = $g_sIniPath ; <--- ÉP LUÔN LUÔN CHỈ ĐỌC TỪ FILE CONFIG.INI GỐC

    ; --- 1. TẢI CÀI ĐẶT CHUNG ---
    GUICtrlSetData($g_hInput_InitialCapital, IniRead($sFileToRead, $sSection, "InitialCapital", "10.000.000"))
    GUICtrlSetData($g_hInput_InitialBet, IniRead($sFileToRead, $sSection, "InitialBet", "100.000"))
    GUICtrlSetData($g_hInput_TakeProfit, IniRead($sFileToRead, $sSection, "TakeProfit", "200.000"))
    GUICtrlSetData($g_hInput_StopLoss, IniRead($sFileToRead, $sSection, "StopLoss", "500.000"))

    GUICtrlSetData($g_hInput_ClickDelay, IniRead($g_sIniPath, "Settings", "ClickDelay", "10"))
    GUICtrlSetData($g_hInput_ClickDelay_Main, IniRead($g_sIniPath, "Settings", "ClickDelay", "10"))
    GUICtrlSetData($g_hInput_MouseSpeed, IniRead($g_sIniPath, "Settings", "MouseSpeed", "10"))
    Local $sClickMode = IniRead($g_sIniPath, "Settings", "ClickMode", "Control")
    If $sClickMode = "Mouse" Then
        GUICtrlSetState($g_hRadio_ClickMode_Mouse, $GUI_CHECKED)
        GUICtrlSetState($g_hRadio_ClickMode_Mouse_Main, $GUI_CHECKED)
    Else
        GUICtrlSetState($g_hRadio_ClickMode_Control, $GUI_CHECKED)
        GUICtrlSetState($g_hRadio_ClickMode_Control_Main, $GUI_CHECKED)
    EndIf
    ; Tải trạng thái Checkbox Blacklist
Local $iBlacklistState = Number(IniRead($sFileToRead, $sSection, "Opt_BlacklistEnabled", "1"))
GUICtrlSetState($g_hCheckbox_Blacklist, ($iBlacklistState = 1) ? $GUI_CHECKED : $GUI_UNCHECKED)
Local $iIgnRun = Number(IniRead($sFileToRead, $sSection, "Opt_BlacklistIgnoreRun", "0"))
GUICtrlSetState($g_hCheckbox_Blacklist_IgnoreRunning, ($iIgnRun = 1) ? $GUI_CHECKED : $GUI_UNCHECKED)
; --- [MỚI] TẢI CẤU HÌNH QUAN SÁT ---
    ; [FIX] Đổi $g_sIniPath thành $sFileToRead và "Settings" thành $sSection
    Local $iObserveMode = Number(IniRead($sFileToRead, $sSection, "ObserveMode", "1"))
    ; --- 2. TẢI CHIẾN THUẬT & TÙY CHỌN ---
    Local $sSavedRules = IniRead($sFileToRead, $sSection, "CustomRulesList", "BBB-P|NL|PPP-B")
    GUICtrlSetData($g_hInput_CustomRules, StringReplace($sSavedRules, "|NL|", @CRLF))

    Local $iSepQLV = Number(IniRead($sFileToRead, $sSection, "Opt_SeparateQLV", "0"))
    GUICtrlSetState($g_hCheckbox_SeparateQLV, ($iSepQLV = 1) ? $GUI_CHECKED : $GUI_UNCHECKED)
    Local $iContMode = Number(IniRead($sFileToRead, $sSection, "Opt_ContinuousMode", "1"))
    GUICtrlSetState($g_hCheckbox_ContinuousMode, ($iContMode = 1) ? $GUI_CHECKED : $GUI_UNCHECKED)

; --- [SỬA LẠI] ĐỌC SỐ -> TỰ CHỌN DÒNG CHỮ TƯƠNG ỨNG ---
    Local $sID = IniRead($sFileToRead, $sSection, "Opt_AfterWinLogic_ID", "1")
    Local $sTextToSet = "1. Lay ngay cum gan nhat (Danh tiep)" ; Mặc định

; --- [SỬA LẠI] LUÔN CỐ ĐỊNH LOGIC SỐ 2 ---
    ; Bỏ qua việc đọc file INI, ép cứng luôn là Option 2
    Local $sTextToSet = "2. Doi cum moi toanh (Reset)"
    Local $sSavedBlacklist = IniRead($sFileToRead, $sSection, "Blacklist", "BBB,PPP,TTT")
    GUICtrlSetData($g_hInput_Blacklist, $sSavedBlacklist)
    GUICtrlSetData($g_hInput_HistoryLimit, IniRead($sFileToRead, $sSection, "HistoryLimit", "50"))

    ; Tải QLV Riêng
    Local $sSavedQLV = IniRead($sFileToRead, $sSection, "CustomQLV", "")
    If $sSavedQLV = "" Then $sSavedQLV = IniRead($g_sIniPath, "QLV_Global", "QLV_Custom", "")
    If $sSavedQLV = "" Then $sSavedQLV = "0-1-0-1|NL|1-2-0-2"
    GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace($sSavedQLV, "|NL|", @CRLF))

    ; --- 3. TẢI TỌA ĐỘ & MÀU ---
    GUICtrlSetData($g_hInput_WindowClass, IniRead($sFileToRead, $sSection, "WindowClass", "Chrome_WidgetWin_1"))
    GUICtrlSetData($g_hInput_BankerX, IniRead($sFileToRead, $sSection, "BankerX", "0"))
    GUICtrlSetData($g_hInput_BankerY, IniRead($sFileToRead, $sSection, "BankerY", "0"))
    GUICtrlSetData($g_hInput_PlayerX, IniRead($sFileToRead, $sSection, "PlayerX", "0"))
    GUICtrlSetData($g_hInput_PlayerY, IniRead($sFileToRead, $sSection, "PlayerY", "0"))
    GUICtrlSetData($g_hInput_ResultX1, IniRead($sFileToRead, $sSection, "ResultX1", "0"))
    GUICtrlSetData($g_hInput_ResultY1, IniRead($sFileToRead, $sSection, "ResultY1", "0"))
    GUICtrlSetData($g_hInput_ResultX2, IniRead($sFileToRead, $sSection, "ResultX2", "0"))
    GUICtrlSetData($g_hInput_ResultY2, IniRead($sFileToRead, $sSection, "ResultY2", "0"))
    GUICtrlSetData($g_hInput_BankerColor, IniRead($sFileToRead, $sSection, "BankerColor", "0xFB0202"))
    GUICtrlSetData($g_hInput_PlayerColor, IniRead($sFileToRead, $sSection, "PlayerColor", "0x0184FE"))
    GUICtrlSetData($g_hInput_TieColor, IniRead($sFileToRead, $sSection, "TieColor", "0x007722"))
    GUICtrlSetData($g_hInput_Shade_Result, IniRead($sFileToRead, $sSection, "Shade_Result", "10"))
    GUICtrlSetData($g_hInput_BetTimeX1, IniRead($sFileToRead, $sSection, "BetTimeX1", "0"))
    GUICtrlSetData($g_hInput_BetTimeY1, IniRead($sFileToRead, $sSection, "BetTimeY1", "0"))
    GUICtrlSetData($g_hInput_BetTimeX2, IniRead($sFileToRead, $sSection, "BetTimeX2", "0"))
    GUICtrlSetData($g_hInput_BetTimeY2, IniRead($sFileToRead, $sSection, "BetTimeY2", "0"))
    GUICtrlSetData($g_hInput_BetTimeColor, IniRead($sFileToRead, $sSection, "BetTimeColor", "0x2CC937"))
    GUICtrlSetData($g_hInput_Shade_Timer, IniRead($sFileToRead, $sSection, "Shade_Timer", "20"))

    ; --- 4. TẢI CHIP ---
    For $i = 0 To 4
        Local $iChipEnabled = IniRead($sFileToRead, $sSection, "ChipEnabled_" & $i, 0)
        GUICtrlSetState($g_aCheckbox_ChipEnabled[$i], ($iChipEnabled = 1) ? $GUI_CHECKED : $GUI_UNCHECKED)
        GUICtrlSetData($g_aInput_ChipValue[$i], IniRead($sFileToRead, $sSection, "ChipValue_" & $i, "0"))
        GUICtrlSetData($g_aInput_ChipX[$i], IniRead($sFileToRead, $sSection, "ChipX_" & $i, "0"))
        GUICtrlSetData($g_aInput_ChipY[$i], IniRead($sFileToRead, $sSection, "ChipY_" & $i, "0"))
    Next
; --- [SỬA ĐOẠN NÀY] NẠP CHẾ ĐỘ CƯỢC (CUSTOM hay COPY) ---
    Local $sMode = IniRead($sFileToRead, $sSection, "Opt_MethodMode", "CUSTOM")
    ; Gọi hàm này ngay lập tức để nó cập nhật giao diện (Mờ/Sáng các ô nhập liệu)
    ; --------------------------------------------------------
   _UpdateStatus("Đã tải cấu hình: " & $sProfileName)

EndFunc

Func _DeleteProfileFromIni()
	Local $sSelectedProfile = GUICtrlRead($g_hCombo_Profiles)
	If $sSelectedProfile = "" Then
		MsgBox(48, "Chưa chọn Cấu hình", "Vui lòng chọn một cấu hình từ danh sách để xóa.")
		Return
	EndIf

	Local $iConfirm = MsgBox(36, "Xác nhận Xóa", "Bạn có chắc chắn muốn xóa vĩnh viễn cấu hình '" & $sSelectedProfile & "' không?")
	If $iConfirm <> 6 Then Return

	Local $sSection = "Profile_" & $sSelectedProfile
	IniDelete($g_sIniPath, $sSection)

	MsgBox(64, "Thành Công", "Đã xóa cấu hình '" & $sSelectedProfile & "' khỏi file " & StringRegExpReplace($g_sIniPath, "^.*\\", "") & ".")
	_PopulateProfileList()
	GUICtrlSetData($g_hCombo_Profiles, "")
	GUICtrlSetData($g_hCombo_Profiles_Main, "")
	GUICtrlSetData($g_hInput_ProfileName, "")
EndFunc

Func _CreateDefaultIniFile()
	_SaveSettings()
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "WindowClass", "Chrome_WidgetWin_1")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BankerX", "1144")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BankerY", "847")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "PlayerX", "751")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "PlayerY", "836")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ResultX1", "773")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ResultY1", "211")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ResultX2", "1140")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ResultY2", "475")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BankerColor", "0xFB0202")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "PlayerColor", "0x0184FE")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "TieColor", "0x007722")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BetTimeX1", "96")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BetTimeY1", "545")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BetTimeX2", "1819")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BetTimeY2", "567")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "BetTimeColor", "0x2CC937")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ClickMode", "Mouse")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ClickDelay", "50")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_0", "1"); Chip 1
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_0", "500.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_0", "988")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_0", "1009")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_1", "1"); Chip 2
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_1", "100.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_1", "933")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_1", "1007")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_2", "1"); Chip 3
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_2", "40.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_2", "865")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_2", "1013")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_3", "1"); Chip 4
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_3", "20.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_3", "807")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_3", "1008")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_4", "1"); Chip 5
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_4", "4.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_4", "747")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_4", "1002")
EndFunc

Func _LoadSettings()
    If Not FileExists($g_sIniPath) Then _CreateDefaultIniFile()
    _EnsureDefaultQLVExists()

    ; --- Tải thông số cơ bản ---
    GUICtrlSetData($g_hInput_InitialCapital, IniRead($g_sIniPath, "Settings", "InitialCapital", "10.000.000"))
    GUICtrlSetData($g_hInput_InitialBet, IniRead($g_sIniPath, "Settings", "InitialBet", "100.000"))
    GUICtrlSetData($g_hInput_TakeProfit, IniRead($g_sIniPath, "Settings", "TakeProfit", "200.000"))
    GUICtrlSetData($g_hInput_StopLoss, IniRead($g_sIniPath, "Settings", "StopLoss", "500.000"))
    GUICtrlSetData($g_hInput_MouseSpeed, IniRead($g_sIniPath, "Settings", "MouseSpeed", "10"))

    ; --- Tải trạng thái Đánh Nối Đuôi ---
    Local $iContMode = IniRead($g_sIniPath, "Settings", "ContinuousMode", 0)
    If $iContMode = 1 Then
        GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_CHECKED)
    Else
        GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_UNCHECKED)
    EndIf

    ; --- Tải thông số AI ---
    GUICtrlSetData($g_hInput_HistoryLimit, IniRead($g_sIniPath, "Settings", "HistoryLimit", "50"))

    ; --- Tải bảng QLV ---
    Local $sSavedTable = IniRead($g_sIniPath, "CapitalManagement", "CustomQLVTable", "0-1-0-1|NL|1-1-0-2|NL|2-2-0-3")
    GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace($sSavedTable, "|NL|", @CRLF))
    _PopulateQLVList()
    _PopulateProfileList()

    ; --- Load Profile Bàn ---
    Local $sProfileToUse = ""
    If $g_sMyTableID <> "" Then
        $sProfileToUse = StringReplace($g_sMyTableID, "B", "Ban ")
    Else
        $sProfileToUse = IniRead($g_sIniPath, "UISettings", "LastProfile", "Ban 1")
    EndIf

    GUICtrlSetData($g_hCombo_Profiles_Main, $sProfileToUse)
    GUICtrlSetData($g_hCombo_Profiles, $sProfileToUse)

    If $sProfileToUse <> "" Then
        _LoadSelectedProfile($sProfileToUse)
        $g_sCurrentLoadedProfile = $sProfileToUse
        _GetAndValidateInputs()
    EndIf

    ; Lấy tên cấu hình đang chọn để hiển thị
    Local $sCurrentProfile = GUICtrlRead($g_hCombo_Profiles_Main)
    If $sCurrentProfile = "" Then $sCurrentProfile = "Mặc định"

    ; Hiển thị thông tin hữu ích hơn
    _UpdateStatus("✅ Đã nạp cấu hình: [" & $sCurrentProfile & "] - Sẵn sàng hoạt động!")

    ; --------------------------------------------------------

    ; --- Các cài đặt hiển thị khác ---
    GUICtrlSetState($g_hCheckbox_ToggleScan, $GUI_UNCHECKED)
    _ToggleScanHotkey()
    _LoadSessionState()

    ; Load Stats Trọn Đời lần đầu tiên
    Local $sInitMethod = _GetActiveMethodName()
    Local $sFileStats = @ScriptDir & "\stats_history.ini"

    $g_iMaxWinStreak = Number(IniRead($sFileStats, $sInitMethod, "MaxWinStreak", "0"))
    $g_iMaxLossStreak = Number(IniRead($sFileStats, $sInitMethod, "MaxLossStreak", "0"))

    Local $iInitWins = Number(IniRead($sFileStats, $sInitMethod, "TotalWins", "0"))
    Local $iInitLosses = Number(IniRead($sFileStats, $sInitMethod, "TotalLosses", "0"))

EndFunc

Func _StartProcess()
    Local $sSelectedProfile = GUICtrlRead($g_hCombo_Profiles_Main)
    If $sSelectedProfile = "" Then
        MsgBox(16, "Lỗi Cấu Hình", "Vui lòng chọn một cấu hình sảnh hợp lệ từ danh sách.")
        _SetControlsState(True) ; <--- TRẢ LẠI TRẠNG THÁI NÚT
        Return
    EndIf

    If Not _GetAndValidateInputs() Then
        _SetControlsState(True) ; <--- TRẢ LẠI TRẠNG THÁI NÚT
        Return
    EndIf

    _ApplyCurrentSettings()
    $g_hSessionTimer = TimerInit()
    _SendActivityLog("Start")
	$g_fTotalProfit = 0.0

    $g_bIsRunning = True
    _SetControlsState(False) ; <--- GỌI ĐỔI MÀU NÚT SANG TRẠNG THÁI RUNNING TẠI ĐÂY

    ; --- BIẾN CỜ: ĐÁNH DẤU LẦN ĐẦU TIÊN CHẠY ---
_UpdateStatus(">>> KHỞI ĐỘNG NGAY: Bắt đầu dò tín hiệu để đánh luôn!")
    ; -------------------------------------------------------------------------
    ; VÒNG LẶP CHÍNH (QUẢN LÝ CÁC XU BÀI)
    ; -------------------------------------------------------------------------
    While $g_bIsRunning

        ; =====================================================================
        ; BƯỚC 1: TÌM BÀN / CHỜ KẾT QUẢ ĐẦU TIÊN (60S)
        ; =====================================================================
        Local $bFoundFirstResult = False
        Local $hInitTimer = TimerInit()
        Local $iLastReported = -1

        _UpdateStatus("⏳ [BƯỚC 1] Đang tìm bàn (Max 60s)...")

        While $g_bIsRunning
            _ProcessGUIMessages()

            Local $sInitResult = _ScanAreaForResult()
            If $sInitResult <> "" Then
                _UpdateStatus("✅ Đã kết nối vào bàn: " & $sInitResult)
                _ProcessObservation($sInitResult) ; Ghi nhớ
                $bFoundFirstResult = True
                ExitLoop
            EndIf

            Local $iRemain = 60 - Round(TimerDiff($hInitTimer)/1000, 0)
            If $iRemain <> $iLastReported Then
                _UpdateStatus("⏳ Đang tìm tín hiệu... Reset sau: " & $iRemain & "s")
                $iLastReported = $iRemain
            EndIf
            Sleep(100)
        WEnd

        While $g_bIsRunning
            _ProcessGUIMessages()

            ; [CHỐT CHẶN 1] Kiểm tra Target NGAY ĐẦU VÒNG LẶP
            ; Nếu hàm này trả về True (đã đạt target) -> Thoát ngay lập tức
            If _CheckProfitLossTargets() Then ExitLoop

            ; --- A. ĐỢI KẾT QUẢ CŨ BIẾN MẤT ---
            ; Chỉ chạy dòng này nếu chưa đạt target
            _WaitUntilResultDisappears()

            ; [CHỐT CHẶN 2] Kiểm tra lại sau khi đợi (đề phòng bấm Stop tay)
            If Not $g_bIsRunning Then ExitLoop
                ; Vẫn có thể gọi hàm soi cầu để xem chơi cho vui, nhưng không đặt tiền
                ; (Bỏ qua đoạn _DecideNextAction và _PerformBet)
                Local $aAction = _DecideNextAction()
                Local $sBetOn = $aAction[1]
                Local $iBetUnits = $aAction[2]

If $aAction[0] = "BET" Then
                    $g_fCurrentBet = $g_fInitialBet * $iBetUnits
                    _UpdateStatus("🔥 Logic báo CƯỢC: " & $sBetOn & " -> Chờ giờ cược...")

                    If _WaitForBettingTime_Safe() Then
                        ; Nếu tìm thấy giờ cược -> Đánh
                        If _PerformBet($sBetOn, $g_fCurrentBet) Then
                             _UpdateStatus("✅ Đã đặt cược! Đang chờ mở bài...")
                        EndIf
                    Else
                        ; ==> [SỬA] NẾU QUÁ 70S KHÔNG THẤY GIỜ CƯỢC -> RESET
                        _UpdateStatus("⛔ Timeout Giờ Cược -> RESET -> CHUẨN BỊ SANG XU MỚI!")
                        _ResetAllStatsAndState()
                        ExitLoop ; Thoát vòng lặp ván để bắt đầu tìm bàn lại
                    EndIf
                Else
                    ; Quan sát...
                    Local $iCount = UBound($g_aDisplayHistory)
                    _UpdateStatus("👁️ Quan sát (" & $iCount & " tay) - Chờ cơ hội...")
                EndIf

            ; --- C. CHỜ KẾT QUẢ MỚI (TIMEOUT 60S) ---
            Local $sNewResult = _WaitForNextHandResult_TimeOut($g_iTimeOutLimit)
; [QUAN TRỌNG] NẾU TIMEOUT -> HẾT BÀI -> CHUYỂN TRẠNG THÁI
            If $sNewResult = "TIMEOUT" Then
                _UpdateStatus("⛔ HẾT BÀI (Time-out) -> Đang chờ Dealer xào bài...")

                ; >>> BẮT ĐẦU ĐOẠN CODE "NGỦ CANH GÁC" (SMART WAIT) <<<
                Local $iWaitTimeSeconds = 15 ; Cài đặt thời gian chờ tối đa (giây)
                Local $hShuffleTimer = TimerInit()
                Local $bWokeUpEarly = False

                While TimerDiff($hShuffleTimer) < ($iWaitTimeSeconds * 1000)
                    ; 1. Kiểm tra nhanh xem có màu Giờ Cược (Timer) hiện lên không
                    ; Sử dụng lại các biến tọa độ và màu đã cài đặt
                    Local $iTol = Number(GUICtrlRead($g_hInput_Shade_Timer))
                    If IsArray(PixelSearch($g_aBetTimeIndicatorArea[0], $g_aBetTimeIndicatorArea[1], $g_aBetTimeIndicatorArea[2], $g_aBetTimeIndicatorArea[3], $g_iBetTimeIndicatorColor, $iTol, 1)) Then
                        _UpdateStatus("⚠️ PHÁT HIỆN GIỜ CƯỢC! -> Hủy chờ xào bài -> Vào việc ngay!")
                        $bWokeUpEarly = True
                        ExitLoop ; Thoát khỏi vòng chờ ngay lập tức
                    EndIf

                    ; 2. Kiểm tra xem có Kết quả mới hiện lên không (phòng hờ)
                    If _ScanAreaForResult() <> "" Then
                         _UpdateStatus("⚠️ PHÁT HIỆN KẾT QUẢ MỚI! -> Hủy chờ xào bài!")
                         $bWokeUpEarly = True
                         ExitLoop
                    EndIf

                    ; Ngủ ngắn 0.5s rồi check tiếp
                    Sleep(500)
                WEnd
                ; >>> KẾT THÚC ĐOẠN SMART WAIT <<<

                If Not $bWokeUpEarly Then
                    _UpdateStatus("♻️ Hết thời gian chờ -> RESET lịch sử để vào xu mới...")
                EndIf

                _ResetAllStatsAndState()

                ; Nếu bị đánh thức sớm thì không cần Sleep thêm nữa, chiến luôn
                If Not $bWokeUpEarly Then Sleep(2000)

                ExitLoop ; Thoát ra để bắt đầu vòng lặp Xu Mới
            EndIf

            If Not $g_bIsRunning Then ExitLoop

            ; --- D. GHI NHỚ ---
; --- D. GHI NHỚ & XỬ LÝ KẾT QUẢ ---
            If $g_sLastBetOn <> "" Then
                ; Gọi hàm xử lý kết quả (Hàm này vừa sửa ở Bước 1)
                _ProcessBetOutcome($sNewResult, $g_sLastBetOn)

                ; [QUAN TRỌNG] Sau khi xử lý xong, kiểm tra ngay xem Tool có bị tắt không
                ; Nếu Bước 1 đã phát hiện đủ Target và tắt tool -> Thoát vòng lặp NGAY LẬP TỨC
                ; Để nó không vòng lên trên và chạy vào lệnh cược mới
                If Not $g_bIsRunning Then ExitLoop

                $g_sLastBetOn = ""
            Else
                _ProcessObservation($sNewResult)
            EndIf

        WEnd
	WEnd
EndFunc

; ==============================================================================
; HÀM HỖ TRỢ MỚI (COPY KÈM THEO)
; ==============================================================================

Func _WaitForNextHandResult_TimeOut($iMaxTimeMS)
    ; Xóa bỏ đồng hồ đếm ngược, ép Tool đợi vĩnh viễn
    _UpdateStatus("⏳ Đang đợi Dealer lật bài (Chờ vĩnh viễn)...")

    While $g_bIsRunning
        _ProcessGUIMessages()

        Local $sRes = _ScanAreaForResult()
        If $sRes <> "" Then Return $sRes ; Chỉ thoát vòng lặp khi có B, P hoặc T

        Sleep(100)
    WEnd

    Return "STOPPED"
EndFunc
; Hàm đợi kết quả biến mất (Để tránh nhận diện trùng lặp)
Func _WaitUntilResultDisappears()
    _UpdateStatus("⏳ Đợi kết quả cũ biến mất...")
    While _ScanAreaForResult() <> "" And $g_bIsRunning
        _ProcessGUIMessages()
        Sleep(200)
    WEnd
EndFunc
Func _StopProcess()
    $g_bIsRunning = False
    $g_bManualStopped = True
    _UpdateStatus("🛑 Đã dừng Tool và chốt Lợi nhuận vào Số dư!")

    If $g_hTargetGameWin <> 0 And WinExists($g_hTargetGameWin) Then WinClose($g_hTargetGameWin)
    $g_hTargetGameWin = 0
    ;If $g_sWDSession <> "" Then
        ;_WD_DeleteSession($g_sWDSession)
        ;$g_sWDSession = ""
    ;EndIf
    ;ProcessClose("chromedriver.exe")

    ; --- 1. CHỐT LỢI NHUẬN VÀO SỐ DƯ (CỘNG DỒN) ---
    If $g_fTotalProfit <> 0 Then
        $g_fInitialCapital += $g_fTotalProfit
        GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))
    EndIf

    ; --- 2. RESET LỢI NHUẬN VÀ CHUỖI VỀ 0 (BẢO LƯU VOLUME) ---
    $g_fTotalProfit = 0
    $g_iCapitalLevel = 0
    $g_iCustomSeqStep = 0
    $g_iLastActiveRuleIndex = -1
    For $i = 0 To UBound($g_aRuleLevels) - 1
        $g_aRuleLevels[$i] = 0
    Next

    _UpdateProfitLabel()
    _UpdateBalanceLabel()
    _UpdateTotalVolumeLabel()

    ; --- 3. LƯU LẠI VỐN MỚI VÀO FILE CONFIG ---
    _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))

    _SetControlsState(True)
    GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
    GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
EndFunc
Func _HaltProcess($sReason)
    _SendActivityLog("Stop", $sReason, Round(TimerDiff($g_hSessionTimer) / 1000, 0))
    $g_bIsRunning = False
    $g_bManualStopped = True
    _UpdateStatus($sReason)

    If $g_hTargetGameWin <> 0 And WinExists($g_hTargetGameWin) Then WinClose($g_hTargetGameWin)
    $g_hTargetGameWin = 0
    ;If $g_sWDSession <> "" Then
        ;_WD_DeleteSession($g_sWDSession)
        ;$g_sWDSession = ""
    ;EndIf
    ;ProcessClose("chromedriver.exe")

    ; --- 1. CHỐT LỢI NHUẬN VÀO SỐ DƯ (CỘNG DỒN) ---
    If $g_fTotalProfit <> 0 Then
        $g_fInitialCapital += $g_fTotalProfit
        GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))
    EndIf

    ; --- 2. RESET LỢI NHUẬN VÀ CHUỖI VỀ 0 (BẢO LƯU VOLUME) ---
    $g_fTotalProfit = 0
    $g_iCapitalLevel = 0
    $g_iCustomSeqStep = 0
    $g_iLastActiveRuleIndex = -1
    For $i = 0 To UBound($g_aRuleLevels) - 1
        $g_aRuleLevels[$i] = 0
    Next

    _UpdateProfitLabel()
    _UpdateBalanceLabel()
    _UpdateTotalVolumeLabel()

    ; --- 3. LƯU LẠI VỐN MỚI VÀO FILE CONFIG ---
    _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))

    _SetControlsState(True)
    GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
    GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)

    If $g_sMyTableID <> "" Then
        Local $sFile = @TempDir & "\status_" & $g_sMyTableID & ".ini"
        IniWrite($sFile, "Status", "State", "MANUAL_STOP")
    EndIf
EndFunc
Func _ResetAllStatsAndState()
    ;$g_fTotalProfit = 0.0

    ; --- [LOGIC 7H SÁNG GIỮ NGUYÊN] ---
    Local $sFileStats = @ScriptDir & "\stats_history.ini"
    Local $sGamingDate = @YEAR & "/" & @MON & "/" & @MDAY
    If Number(@HOUR) < 7 Then
        $sGamingDate = _DateAdd('d', -1, $sGamingDate)
    EndIf
    $sGamingDate = StringReplace($sGamingDate, "/", "")
    Local $sSavedDate = IniRead($sFileStats, "Global_Daily", "Date", "")
    If $sSavedDate = $sGamingDate Then
        $g_fTotalVolume = Number(IniRead($sFileStats, "Global_Daily", "Volume", "0"))
    Else
        $g_fTotalVolume = 0
        IniWrite($sFileStats, "Global_Daily", "Date", $sGamingDate)
        IniWrite($sFileStats, "Global_Daily", "Volume", "0")
    EndIf
    ; ------------------------

    $g_iSessionCount = 0
    $g_iStrategyWins = 0
    $g_iStrategyLosses = 0
    $g_iCurrentWinStreak = 0
    $g_iCurrentLossStreak = 0

    Local $sMethod = _GetActiveMethodName()
    $g_iMaxWinStreak = Number(IniRead($sFileStats, $sMethod, "MaxWinStreak", "0"))
    $g_iMaxLossStreak = Number(IniRead($sFileStats, $sMethod, "MaxLossStreak", "0"))
    Local $sCurrentMethod = _GetActiveMethodName()
    _LoadStreakStats_Permanent($sCurrentMethod)

    $g_iMaxWinStreakCount = 0
    $g_iMaxLossStreakCount = 0
    ReDim $g_aDisplayHistory[0]
	$g_iHistoryCutoffIndex = 0
    $g_iTotalBanker = 0
    $g_iTotalPlayer = 0
    $g_iTotalTie = 0
    $g_fLastBetAmount = 0.0
    $g_sLastBetOn = ""
    _ResetBettingMethodState()

    ; --- [THÊM MỚI] RESET MẢNG VỐN RIÊNG BIỆT ---
    ; Reset toàn bộ các dòng QLV về 0
    For $i = 0 To UBound($g_aRuleLevels) - 1
        $g_aRuleLevels[$i] = 0
    Next
    $g_iLastActiveRuleIndex = -1 ; Hủy khóa dòng
    ; -------------------------------------------------

    _UpdateStatus("♻️ Đã Reset Lịch sử, Memory & Vốn các dòng!")

    _UpdateProfitLabel()
    _UpdateBalanceLabel()
    _UpdateTotalHandsLabel()
    _UpdateBPTTotalsLabels()
    _UpdateTotalVolumeLabel()
    _RedrawHistory()
EndFunc

Func _ResetBettingMethodState()
    $g_iCapitalLevel = 0 ; Bắt đầu từ Lệnh 0
    _UpdateStatus("Đã Reset về Lệnh 0.")
EndFunc

Func _UpdateAllLabels()
    ; [SỬA QUAN TRỌNG] Gọi hàm hiển thị mới (đọc từ Database) thay vì hàm cũ
    _UpdateProfitLabel()
    _UpdateBalanceLabel()
    _UpdateTotalHandsLabel()
    _UpdateBPTTotalsLabels()
    _UpdateTotalVolumeLabel()
	_CheckProfitLossTargets()
EndFunc

Func _DecideNextAction()
    Local $aStop[3] = ["OBSERVE", "", 0]

    ; 1. Kiểm tra Chốt Lãi / Cắt Lỗ NGAY LẬP TỨC
    If _CheckProfitLossTargets() Then Return $aStop

    Local $iTotalHands = UBound($g_aDisplayHistory)

    ; 2. KIỂM TRA BLACKLIST (NÉ CẦU XẤU)
    If BitAND(GUICtrlRead($g_hCheckbox_Blacklist), $GUI_CHECKED) Then
        Local $bIsRunning = ($g_sCurrentTargetSeq <> "") Or ($g_iCustomSeqStep > 0) Or ($g_iLastActiveRuleIndex > -1) Or ($g_iCapitalLevel > 0)
        Local $bIgnore = (GUICtrlRead($g_hCheckbox_Blacklist_IgnoreRunning) = $GUI_CHECKED)

        If Not ($bIsRunning And $bIgnore) Then
            Local $sBlacklistRaw = GUICtrlRead($g_hInput_Blacklist)
            If $sBlacklistRaw <> "" And $iTotalHands > 0 Then
                Local $sCurrentHistory = StringReplace(_ArrayToString($g_aDisplayHistory, ""), "T", "")
                Local $aBlackItems = StringSplit($sBlacklistRaw, ",")
                For $i = 1 To $aBlackItems[0]
                    Local $sItem = StringReplace(StringStripWS($aBlackItems[$i], 8), "T", "")
                    If $sItem <> "" And StringRight($sCurrentHistory, StringLen($sItem)) = $sItem Then
                        _UpdateStatus("⛔ GẶP BLACKLIST (" & $sItem & ") -> TẠM DỪNG!")
                        Return $aStop
                    EndIf
                Next
            EndIf
        EndIf
    EndIf

    ; 3. GỌI LOGIC VÀO LỆNH (ĐÃ LƯỢC BỎ AI)
    Local $aQLV = _GetQLV_Params($g_iCapitalLevel)
    Return _Logic_Custom($iTotalHands, $aQLV[1], False)
EndFunc
Func _ProcessObservation($sActualResult)
    ; HÒA -> Bỏ Qua
    If $sActualResult = "T" Then
        _UpdateStatus("⚠️ Kết quả HÒA (Tie) -> Bỏ qua...")
        _AddNewHistoryEntry($sActualResult)
        _RedrawHistory()
        Return
    EndIf

    ; KẾT QUẢ ĐỎ/XANH
    _AddNewHistoryEntry($sActualResult)
    _UpdateTotalHandsLabel()

    $g_iCycleStep += 1
    Local $iMaxStep = 3
    Local $sMsg = "Kết quả: " & $sActualResult & ". "

    If $g_iCycleStep > $iMaxStep Then
        $g_iCycleStep = 1
        $sMsg &= "--> Quan sát..."
    Else
        $sMsg &= "Quan sát (" & $g_iCycleStep & "/" & $iMaxStep & ")..."
    EndIf

    _UpdateStatus($sMsg)
    _RedrawHistory()
EndFunc

; --- HÀM 2: LẤY THÔNG SỐ QLV AN TOÀN (ĐÃ SỬA LỖI CRASH) ---
Func _GetQLV_Params($iLevel)
    ; 1. Kiểm tra an toàn: Nếu bảng QLV rỗng hoặc index sai -> Về mặc định
    If UBound($g_aCustomQLVTable) = 0 Then
        ; Trả về mảng tạm mặc định để không bị crash
        Local $aDefault[4] = [0, 1, 0, 0]
        Return $aDefault
    EndIf

    ; Nếu cấp vốn vượt quá bảng -> Về dòng đầu tiên (Lệnh 0)
    If $iLevel < 0 Or $iLevel >= UBound($g_aCustomQLVTable) Then
        $iLevel = 0
        $g_iCapitalLevel = 0
    EndIf

    ; 2. [QUAN TRỌNG] TẠO MẢNG CON 1 CHIỀU ĐỂ TRẢ VỀ
    ; (AutoIt không cho phép Return $Arr[$i] đối với mảng 2 chiều)
    Local $aResult[4]
    $aResult[0] = $g_aCustomQLVTable[$iLevel][0] ; Cột Lệnh
    $aResult[1] = $g_aCustomQLVTable[$iLevel][1] ; Cột Vốn (Bet Unit)
    $aResult[2] = $g_aCustomQLVTable[$iLevel][2] ; Cột Thắng về
    $aResult[3] = $g_aCustomQLVTable[$iLevel][3] ; Cột Thua về

    Return $aResult
EndFunc

; --- HÀM 3: CẬP NHẬT VỐN SAU KHI THẮNG (BỊ THIẾU) ---
Func _UpdateCapital_AfterWin()
    Local $aParams = _GetQLV_Params($g_iCapitalLevel)
    Local $iNext = $aParams[2] ; Lấy giá trị cột Thắng về
    $g_iCapitalLevel = $iNext
EndFunc

; --- HÀM 4: CẬP NHẬT VỐN SAU KHI THUA (BỊ THIẾU) ---
Func _UpdateCapital_AfterLoss()
    Local $aParams = _GetQLV_Params($g_iCapitalLevel)
    Local $iNext = $aParams[3] ; Lấy giá trị cột Thua về
    $g_iCapitalLevel = $iNext
EndFunc

Func _GetActiveMethodName()
    Return "Custom" ; Luôn luôn là Custom
EndFunc
; --- HÀM 3: RESET TRẠNG THÁI KHI ĐỔI BÀN/ĐỔI PHƯƠNG PHÁP ---
Func _ResetSignalState()
    $g_iCurrentStreak = 0
    $g_sLastWinner = ""
    $g_iCapitalLevel = 0

    ; Reset biến của Custom
    $g_iCustomSeqStep = 0

    _UpdateStatus("Đã Reset trạng thái cầu.")
EndFunc

Func _ProcessBetOutcome($sActualResult, $sBetOn)
    Local $sStatsFile = @ScriptDir & "\stats_history.ini"
    Local $sCurrentGamingDate = @YEAR & "/" & @MON & "/" & @MDAY
    If Number(@HOUR) < 7 Then $sCurrentGamingDate = _DateAdd('d', -1, $sCurrentGamingDate)
    $sCurrentGamingDate = StringReplace($sCurrentGamingDate, "/", "")

    Local $sSavedGamingDate = IniRead($sStatsFile, "Global_Daily", "Date", "")
    If $sSavedGamingDate <> $sCurrentGamingDate Then
        $g_fTotalVolume = 0
        IniWrite($sStatsFile, "Global_Daily", "Date", $sCurrentGamingDate)
        IniWrite($sStatsFile, "Global_Daily", "Volume", "0")
        _UpdateTotalVolumeLabel()
    EndIf

    _AddNewHistoryEntry($sActualResult)
    _UpdateTotalHandsLabel()

    ; NẾU HÒA
    If $sActualResult = "T" Then
        _UpdateStatus("HÒA -> Giữ nguyên lệnh -> Đánh lại!")
        _RedrawHistory()
        Return
    EndIf
    Local $bSepQLV = (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED)
    Local $iCurrentLvl = ($bSepQLV And $g_iLastActiveRuleIndex > -1 And $g_iLastActiveRuleIndex < UBound($g_aRuleLevels)) ? $g_aRuleLevels[$g_iLastActiveRuleIndex] : $g_iCapitalLevel

    If $sActualResult = $sBetOn Then
        ; ==========================================
        ; [--- KHI THẮNG (WIN) ---]
        ; ==========================================
        $g_fTotalVolume += $g_fCurrentBet
        _UpdateTotalVolumeLabel()
        $g_fTotalProfit += ($sBetOn = "B") ? ($g_fCurrentBet * 0.95) : $g_fCurrentBet
        _UpdateProfitLabel()
        _UpdateBalanceLabel()
        _UpdateStrategyStats(1)

        Local $aQLV = _GetQLV_Params($iCurrentLvl)
        Local $iWinReturnLvl = $aQLV[2]

        If $bSepQLV And $g_iLastActiveRuleIndex > -1 And $g_iLastActiveRuleIndex < UBound($g_aRuleLevels) Then
            $g_aRuleLevels[$g_iLastActiveRuleIndex] = $iWinReturnLvl
        Else
            $g_iCapitalLevel = $iWinReturnLvl
        EndIf

        $g_iLastActiveRuleIndex = -1
        $g_iCustomSeqStep = 0

        If GUICtrlRead($g_hCheckbox_ContinuousMode) <> $GUI_CHECKED Then
            $g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
            _UpdateStatus("WIN! -> Cắt cầu lịch sử -> Chờ chuỗi tín hiệu mới.")
        Else
            $g_iHistoryCutoffIndex = 0
            _UpdateStatus("WIN! -> Về Lv " & $iWinReturnLvl & " -> Tiếp tục nối đuôi.")
        EndIf

    Else
        ; ==========================================
        ; [--- KHI THUA (LOSS) ---]
        ; ==========================================
        $g_fTotalVolume += $g_fCurrentBet
        _UpdateTotalVolumeLabel()
        $g_fTotalProfit -= $g_fCurrentBet
        _UpdateProfitLabel()
        _UpdateBalanceLabel()
        _UpdateStrategyStats(0)

        Local $aQLV = _GetQLV_Params($iCurrentLvl)
        Local $iNextLvl = $aQLV[3]

        If $bSepQLV And $g_iLastActiveRuleIndex > -1 And $g_iLastActiveRuleIndex < UBound($g_aRuleLevels) Then
            $g_aRuleLevels[$g_iLastActiveRuleIndex] = $iNextLvl
        Else
            $g_iCapitalLevel = $iNextLvl
        EndIf

        If $g_iLastActiveRuleIndex > -1 Then
            $g_iCustomSeqStep += 1
            _UpdateStatus("LOSS! (Dòng " & ($g_iLastActiveRuleIndex+1) & ") -> Lên Lv " & $iNextLvl & " -> Sang bước " & $g_iCustomSeqStep)
        Else
            _UpdateStatus("LOSS! -> Lên Lv " & $iNextLvl)
        EndIf

        If GUICtrlRead($g_hCheckbox_ContinuousMode) <> $GUI_CHECKED And $iNextLvl == 0 Then
            $g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
            _UpdateStatus("⛔ Thua hết bảng vốn -> Cắt cầu lịch sử -> Chờ tín hiệu mới.")
        EndIf
    EndIf

    _RedrawHistory()
EndFunc
Func _AddNewHistoryEntry($sResult)
	_ArrayAdd($g_aDisplayHistory, $sResult)
	; --- [THÊM MỚI] CẮT ĐUÔI NẾU QUÁ NẶNG RAM (Giới hạn cứng 10.000) ---
    If UBound($g_aDisplayHistory) > $HARD_LIMIT_RAM Then
        _ArrayDelete($g_aDisplayHistory, 0)
    EndIf
    ; -------------------------------------------------------------------
	_UpdateBPTTotals($sResult)
EndFunc

Func _UpdateBPTTotals($sResult)
	Switch $sResult
		Case "B"
			$g_iTotalBanker += 1
		Case "P"
			$g_iTotalPlayer += 1
		Case "T"
			$g_iTotalTie += 1
	EndSwitch
	_UpdateBPTTotalsLabels()
EndFunc

Func _UpdateBPTTotalsLabels()
	GUICtrlSetData($g_hLabel_TotalB_Val, $g_iTotalBanker)
	GUICtrlSetData($g_hLabel_TotalP_Val, $g_iTotalPlayer)
	GUICtrlSetData($g_hLabel_TotalT_Val, $g_iTotalTie)
EndFunc

Func _PerformBet($sBetOn, $fAmountToBet)
    ; [CHỐT CHẶN] Kiểm tra lần cuối
    If Not $g_bIsRunning Then Return False
    If _CheckProfitLossTargets() Then Return False

    _UpdateStatus(StringFormat("Thực hiện cược %s (%s VND)...", $sBetOn, _FormatNumber($fAmountToBet)))

    ; [ĐÃ SỬA] Ép trỏ vào đúng trình duyệt của Tool
    Local $hGameWin = $g_hTargetGameWin

    ; Nếu khách cố tình bấm X tắt trình duyệt của tool đi -> Dừng Tool
    If $hGameWin = 0 Or Not WinExists($hGameWin) Then
        _HaltProcess("Lỗi: Trình duyệt của Tool đã bị đóng!")
        Return False
    EndIf

    Local $aBetAreaPos = ($sBetOn = "B") ? $g_aBankerButtonPos : $g_aPlayerButtonPos
    Sleep(50)
    ; Thực hiện Click Chip
    _ClickChipsForAmount($hGameWin, $fAmountToBet, $aBetAreaPos)
    $g_fLastBetAmount = $fAmountToBet
    $g_sLastBetOn = $sBetOn
    Return True
EndFunc

Func _ClickChipsForAmount($hGameWin, $fAmount, $aBetAreaPos)
    ; 1. Tính toán danh sách chip cần dùng (Đã gom nhóm)
    Local $aClickQueue = _CalculateOptimalClicks($fAmount)
    If @error Then return False

    Local $iTotalSteps = UBound($aClickQueue)
    If $iTotalSteps = 0 Then Return True

    ; --- LOGIC MỚI: TÍNH TỔNG SỐ LẦN CLICK ĐỂ ĐIỀU CHỈNH TỐC ĐỘ ---
    Local $iTotalClicks = 0
    For $i = 0 To $iTotalSteps - 1
        $iTotalClicks += $aClickQueue[$i][2]
    Next

    _UpdateStatus("Đang cược " & _FormatNumber($fAmount) & "...")

    Local $iBaseDelay = $g_iClickDelay
    ; Đảm bảo cửa sổ game đang active
    WinActivate($hGameWin)

    ; --- LOGIC NGƯỜI THẬT: GIẢ VỜ SUY NGHĨ NẾU CƯỢC NHỎ ---
    ; Nếu tổng số click <= 3 (cược nhỏ), random suy nghĩ từ 1s đến 2.5s
    ; Nếu gấp thếp (click nhiều), sẽ bỏ qua suy nghĩ để đánh nhanh cho kịp giờ
    If $iTotalClicks <= 3 Then
        Local $iThinkTime = Random(1000, 2500, 1)
        _UpdateStatus("Đang suy nghĩ... (" & Round($iThinkTime/1000, 1) & "s)")
        Sleep($iThinkTime)
    EndIf

    ; 2. Duyệt qua từng loại chip cần dùng
    For $i = 0 To $iTotalSteps - 1
        Local $iChipX = $aClickQueue[$i][0]
        Local $iChipY = $aClickQueue[$i][1]
        Local $iCount = $aClickQueue[$i][2]

        ; BƯỚC A: RA KHAY LẤY CHIP (Bán kính random siêu nhỏ 3px để không lem chip khác)
        _SingleClick($hGameWin, $iChipX, $iChipY, 3)

        ; Nghỉ một chút để game kịp nhận diện chip đổi màu, random từ 50ms - 150ms
        Sleep($iBaseDelay + Random(50, 150, 1))

        ; BƯỚC B: RA Ô CƯỢC VÀ CLICK N LẦN
        ; Di chuyển chuột đến ô cược trước (nếu dùng chế độ Mouse)
        If $g_sClickMode = "Mouse" Then
             MouseMove($aBetAreaPos[0] + Random(-10, 10, 1), $aBetAreaPos[1] + Random(-10, 10, 1), $g_iMouseSpeed)
        EndIf

        For $j = 1 To $iCount
            If Not $g_bIsRunning Then Return False

            ; Click tại chỗ với bán kính random 10px (ô cược rộng nên random thoải mái)
            _SingleClick($hGameWin, $aBetAreaPos[0], $aBetAreaPos[1], 10)

            ; Tính toán delay nhả chuột: Click nhiều thì delay ngắn, click ít thì delay dài
            Local $iCurrentDelay = $iBaseDelay
            If $iTotalClicks > 10 Then
                $iCurrentDelay = Random($iBaseDelay * 0.5, $iBaseDelay, 1) ; Nhanh hơn để kịp giờ
            Else
                $iCurrentDelay = Random($iBaseDelay, $iBaseDelay * 1.5, 1) ; Chậm rãi ngẫu nhiên
            EndIf
            Sleep($iCurrentDelay)
        Next
    Next

    Return True
EndFunc

Func _CalculateOptimalClicks($fTargetAmount)
    Local $aActiveChips[1][3] ; [Value, X, Y]
    Local $iActiveCount = 0

    ; 1. Lấy danh sách chip đang bật
    For $i = 0 To 4
        If $g_aChipConfig[$i][0] Then
            ReDim $aActiveChips[$iActiveCount + 1][3]
            $aActiveChips[$iActiveCount][0] = $g_aChipConfig[$i][1] ; Giá trị
            $aActiveChips[$iActiveCount][1] = $g_aChipConfig[$i][2] ; Tọa độ X
            $aActiveChips[$iActiveCount][2] = $g_aChipConfig[$i][3] ; Tọa độ Y
            $iActiveCount += 1
        EndIf
    Next

    If $iActiveCount = 0 Then
        MsgBox(16, "Lỗi Chip", "Bạn chưa bật chip nào trong Cấu Hình.")
        Return SetError(1)
    EndIf

    ; 2. Sắp xếp chip từ Lớn xuống Nhỏ để ưu tiên dùng chip to
    _ArraySort($aActiveChips, 1, 0, 0, 0)

    Local $aClicksQueue[0][3] ; Mảng chứa lệnh click: [X_Chip, Y_Chip, Số_Lần_Click]
    Local $fRemaining = $fTargetAmount

    ; 3. Tính toán số lượng từng loại chip
    For $i = 0 To UBound($aActiveChips) - 1
        Local $fVal = $aActiveChips[$i][0]
        If $fVal <= 0 Then ContinueLoop

        Local $iCount = Floor($fRemaining / $fVal)
        If $iCount > 0 Then
            ; Thêm vào hàng đợi: Chip này cần click bao nhiêu lần
            Local $iIdx = UBound($aClicksQueue)
            ReDim $aClicksQueue[$iIdx + 1][3]
            $aClicksQueue[$iIdx][0] = $aActiveChips[$i][1] ; X Chip
            $aClicksQueue[$iIdx][1] = $aActiveChips[$i][2] ; Y Chip
            $aClicksQueue[$iIdx][2] = $iCount              ; Số lần click

            $fRemaining = Mod($fRemaining, $fVal)
        EndIf
    Next

    If $fRemaining > 0 Then
        _UpdateStatus("Lẻ " & _FormatNumber($fRemaining) & " (Không đủ chip nhỏ hơn).")
    EndIf

    Return $aClicksQueue
EndFunc

Func _SingleClick($hWnd, $iX, $iY, $iRadius = 0)
    ; Random tọa độ trong phạm vi bán kính cho phép
    Local $iRandX = $iX
    Local $iRandY = $iY

    If $iRadius > 0 Then
        $iRandX = $iX + Random(-$iRadius, $iRadius, 1)
        $iRandY = $iY + Random(-$iRadius, $iRadius, 1)
    EndIf

    ; Nếu chọn chế độ Control (Nhanh - ẩn chuột)
    If $g_sClickMode = "Control" Then
        ControlClick($hWnd, "", "", "left", 1, $iRandX, $iRandY)
    Else
        ; Nếu chọn chế độ Mouse (Tương thích - dùng chuột thật)
        WinActivate($hWnd)
        MouseClick("left", $iRandX, $iRandY, 1, $g_iMouseSpeed)
    EndIf
EndFunc


Func _ScanAreaForResult()
    ; [ĐÃ SỬA] Xóa bỏ lệnh tìm CLASS chung chung
    ; Chỉ lấy đúng trình duyệt mà Tool đã mở lúc nãy
    Local $hWnd = $g_hTargetGameWin

    ; Nếu khách cố tình tắt cái trình duyệt của Tool đi -> Nghỉ quét
    If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

    Local $iTolerance = $g_iShade_Result
    Local $iColB = $g_iBankerColor
    Local $iColP = $g_iPlayerColor
    Local $iColT = $g_iTieColor
; --------------------------------------------------------------------
    ; Quét Banker
    If IsArray(PixelSearch($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3], $iColB, $iTolerance, 1, $hWnd)) Then Return "B"
    ; Quét Player
    If IsArray(PixelSearch($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3], $iColP, $iTolerance, 1, $hWnd)) Then Return "P"
    ; Quét Tie
    If IsArray(PixelSearch($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3], $iColT, $iTolerance, 1, $hWnd)) Then Return "T"

    Return ""
EndFunc

Func _GetAndValidateInputs()
	$g_sGameWindowClass = GUICtrlRead($g_hInput_WindowClass)

    ; --- Tọa độ Nút Bấm ---
	$g_aBankerButtonPos[0] = Number(GUICtrlRead($g_hInput_BankerX))
	$g_aBankerButtonPos[1] = Number(GUICtrlRead($g_hInput_BankerY))
	$g_aPlayerButtonPos[0] = Number(GUICtrlRead($g_hInput_PlayerX))
	$g_aPlayerButtonPos[1] = Number(GUICtrlRead($g_hInput_PlayerY))

    ; --- Tọa độ & Màu Kết Quả ---
	$g_aResultArea[0] = Number(GUICtrlRead($g_hInput_ResultX1))
	$g_aResultArea[1] = Number(GUICtrlRead($g_hInput_ResultY1))
	$g_aResultArea[2] = Number(GUICtrlRead($g_hInput_ResultX2))
	$g_aResultArea[3] = Number(GUICtrlRead($g_hInput_ResultY2))
	$g_iBankerColor = Number(GUICtrlRead($g_hInput_BankerColor))
	$g_iPlayerColor = Number(GUICtrlRead($g_hInput_PlayerColor))
	$g_iTieColor = Number(GUICtrlRead($g_hInput_TieColor))
	$g_iShade_Result = Number(GUICtrlRead($g_hInput_Shade_Result))

    ; --- Tọa độ & Màu Giờ Cược ---
	$g_aBetTimeIndicatorArea[0] = Number(GUICtrlRead($g_hInput_BetTimeX1))
	$g_aBetTimeIndicatorArea[1] = Number(GUICtrlRead($g_hInput_BetTimeY1))
	$g_aBetTimeIndicatorArea[2] = Number(GUICtrlRead($g_hInput_BetTimeX2))
	$g_aBetTimeIndicatorArea[3] = Number(GUICtrlRead($g_hInput_BetTimeY2))
	$g_iBetTimeIndicatorColor = Number(GUICtrlRead($g_hInput_BetTimeColor))
    $g_iShade_Timer = Number(GUICtrlRead($g_hInput_Shade_Timer))

    ; --- Chip Cược ---
	Local $iEnabledChipCount = 0
	For $i = 0 To 4
		$g_aChipConfig[$i][0] = (GUICtrlRead($g_aCheckbox_ChipEnabled[$i]) = $GUI_CHECKED)
		$g_aChipConfig[$i][1] = Number(StringReplace(GUICtrlRead($g_aInput_ChipValue[$i]), ".", ""))
		$g_aChipConfig[$i][2] = Number(GUICtrlRead($g_aInput_ChipX[$i]))
		$g_aChipConfig[$i][3] = Number(GUICtrlRead($g_aInput_ChipY[$i]))
		If $g_aChipConfig[$i][0] Then
			$iEnabledChipCount += 1
			If $g_aChipConfig[$i][1] <= 0 Then
				MsgBox(48, "Lỗi Cấu Hình Chip", "Giá trị của Chip " & $i + 1 & " phải là một số dương.")
				Return False
			EndIf
		EndIf
	Next
	If $iEnabledChipCount = 0 Then
		MsgBox(48, "Lỗi Cấu Hình Chip", "Bạn phải bật ít nhất một chip cược trong Phòng Kỹ Thuật.")
		Return False
	EndIf

    ; --- Tiền Vốn ---
	$g_fInitialCapital = Number(StringReplace(GUICtrlRead($g_hInput_InitialCapital), ".", ""))
	$g_fInitialBet = Number(StringReplace(GUICtrlRead($g_hInput_InitialBet), ".", ""))
	$g_fTakeProfit = Number(StringReplace(GUICtrlRead($g_hInput_TakeProfit), ".", ""))
	$g_fStopLoss = Number(StringReplace(GUICtrlRead($g_hInput_StopLoss), ".", ""))

	If $g_fInitialBet <= 0 Then
		MsgBox(48, "Lỗi đầu vào", "Giá trị cược ban đầu phải lớn hơn 0.")
		Return False
	EndIf

	If $g_sQLVMode = "Flexible" And Not _ParseCustomQLVTable() Then Return False

	Return True
EndFunc

Func _UpdateStrategyStats($iBetResult)
    If $iBetResult = 2 Then Return ; Hòa bỏ qua

    Local $sFileStats = @ScriptDir & "\stats_rules_history.ini"

    ; 1. Lấy tên công thức vừa đánh (Biến này đã được set chính xác ở hàm _Logic_Custom mới)
    Local $sSig = $g_sCurrentRuleSignature

    ; 2. Lưu vào file INI (Lưu vào phần PERM_ để hiển thị vĩnh viễn)
    _Core_SaveStat($sFileStats, "PERM_" & $sSig, $iBetResult)

    ; 3. [QUAN TRỌNG] Cập nhật lại giao diện bảng ListView ngay lập tức
    _InstantDBLookup()
EndFunc

Func _Core_SaveStat($sFile, $sSection, $iResult)
    ; 1. Đọc dữ liệu cơ bản
    Local $iWins   = Number(IniRead($sFile, $sSection, "Wins", "0"))
    Local $iLosses = Number(IniRead($sFile, $sSection, "Losses", "0"))
    Local $iMaxWin = Number(IniRead($sFile, $sSection, "MaxWinStreak", "0"))
    Local $iMaxLoss= Number(IniRead($sFile, $sSection, "MaxLossStreak", "0"))
    Local $iCurWin = Number(IniRead($sFile, $sSection, "CurWinStreak", "0"))
    Local $iCurLoss= Number(IniRead($sFile, $sSection, "CurLossStreak", "0"))

    ; 2. Đọc chuỗi tần suất (Mảng) để sửa lỗi nút ?
    Local $sWinArr = IniRead($sFile, $sSection, "WinFreqArray", "")
    Local $sLossArr = IniRead($sFile, $sSection, "LossFreqArray", "")

    ; Tạo mảng tạm nếu chưa có
    Local $aW[50], $aL[50]
    If $sWinArr <> "" Then
        Local $aTmp = StringSplit($sWinArr, ",", 2)
        If UBound($aTmp) >= 50 Then $aW = $aTmp
    EndIf
    If $sLossArr <> "" Then
        Local $aTmp = StringSplit($sLossArr, ",", 2)
        If UBound($aTmp) >= 50 Then $aL = $aTmp
    EndIf

    ; 3. Cập nhật số liệu
    If $iResult = 1 Then ; Thắng
        $iWins += 1
        $iCurWin += 1
        $iCurLoss = 0
        If $iCurWin > $iMaxWin Then $iMaxWin = $iCurWin

        ; Ghi nhận tần suất thắng
        If $iCurWin < 50 Then $aW[$iCurWin] += 1

    Else ; Thua
        $iLosses += 1
        $iCurLoss += 1
        $iCurWin = 0
        If $iCurLoss > $iMaxLoss Then $iMaxLoss = $iCurLoss

        ; Ghi nhận tần suất thua
        If $iCurLoss < 50 Then $aL[$iCurLoss] += 1

    EndIf

    ; 4. Lưu lại toàn bộ vào File
    IniWrite($sFile, $sSection, "Wins", $iWins)
    IniWrite($sFile, $sSection, "Losses", $iLosses)
    IniWrite($sFile, $sSection, "MaxWinStreak", $iMaxWin)
    IniWrite($sFile, $sSection, "MaxLossStreak", $iMaxLoss)
    IniWrite($sFile, $sSection, "CurWinStreak", $iCurWin)
    IniWrite($sFile, $sSection, "CurLossStreak", $iCurLoss)

    ; Lưu mảng tần suất (Sửa lỗi nút ?)
    IniWrite($sFile, $sSection, "WinFreqArray", _ArrayToString($aW, ","))
    IniWrite($sFile, $sSection, "LossFreqArray", _ArrayToString($aL, ","))
EndFunc

Func _CheckProfitLossTargets()
    Local $bStopNow = False
    Local $sReason = ""
    Local $sStatus = ""

    If $g_fTakeProfit > 0 And $g_fTotalProfit >= $g_fTakeProfit Then
        $bStopNow = True
        $sStatus = "DONE_WIN"
        $sReason = "ĐÃ CHẠM MỐC CHỐT LỜI"
    EndIf

    If $g_fStopLoss > 0 And $g_fTotalProfit <= -$g_fStopLoss Then
        $bStopNow = True
        $sStatus = "DONE_LOSS"
        $sReason = "ĐÃ CHẠM MỐC CẮT LỖ"
    EndIf

    If $bStopNow Then
        _UpdateStatus("⏸️ TẠM DỪNG: " & $sReason & " - Đang chờ lệnh...")
        Local $iUserChoice = _ShowTargetPopup_Overlay($sStatus, $sReason)

        ; =====================================================================
        ; CHUYỂN LỢI NHUẬN VÀO SỐ DƯ NGAY LẬP TỨC CHO CẢ 2 TRƯỜNG HỢP
        ; =====================================================================
        If $g_fTotalProfit <> 0 Then
            $g_fInitialCapital += $g_fTotalProfit
            GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))
        EndIf

        $g_fTotalProfit = 0 ; Reset riêng lợi nhuận (Volume tuyệt đối giữ nguyên)
        ; =====================================================================

        If $iUserChoice == 1 Then
            ; --- CHỌN CHỐT NGHỈ ---
            $g_bIsRunning = False

            ; Thêm 2 dòng này để tự động đóng sảnh, trở về trang chủ
            If $g_hTargetGameWin <> 0 And WinExists($g_hTargetGameWin) Then WinClose($g_hTargetGameWin)
            $g_hTargetGameWin = 0

            WinSetTitle($g_hGUI, "", "STOP: " & $sReason)
            GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
            GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
            _SetControlsState(True)

            _UpdateProfitLabel()
            _UpdateBalanceLabel()
            _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main)) ; Lưu số dư mới

            If $g_sMyTableID <> "" Then
                Local $sFile = @TempDir & "\status_" & $g_sMyTableID & ".ini"
                IniWrite($sFile, "Status", "State", $sStatus)
                IniWrite($sFile, "Status", "LaiLo", "0 VND")
            EndIf
            Return True

        Else
            ; --- CHỌN TIẾP TỤC ĐÁNH (VÀO CA MỚI, GIỮ NGUYÊN SẢNH) ---
            $g_iCapitalLevel = 0
            $g_iCustomSeqStep = 0
            $g_iLastActiveRuleIndex = -1
            For $i = 0 To UBound($g_aRuleLevels) - 1
                $g_aRuleLevels[$i] = 0
            Next

            _UpdateProfitLabel()
            _UpdateBalanceLabel()
            _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main)) ; Lưu số dư mới

            _UpdateStatus("▶️ Đã chốt Số dư. Bắt đầu ca đánh mới (Giữ nguyên Volume)...")
            GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
            GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)

            Return False
        EndIf
    EndIf

    Return False
EndFunc
Func _RedrawHistory()
    ; Xóa sạch bảng cũ
    For $hLabel In $g_aLabel_History
        _StyleResultLabel($hLabel, "-", False, False)
    Next

    Local $iTotalCount = UBound($g_aDisplayHistory)
    If $iTotalCount = 0 Then Return

    ; --- [THÊM MỚI] LẤY GIỚI HẠN TỪ Ô INPUT ---
    Local $iViewLimit = Number(GUICtrlRead($g_hInput_HistoryLimit))
    If $iViewLimit < 10 Then $iViewLimit = 50 ; Mặc định nếu nhập sai

    ; Tính toán điểm bắt đầu (Cắt lấy đuôi)
    Local $iStartIndex = 0
    If $iTotalCount > $iViewLimit Then
        $iStartIndex = $iTotalCount - $iViewLimit
    EndIf
    ; ------------------------------------------

    Local $iRows = 6
    Local $iDisplayCols = 20
    Local $iMaxCells = $iRows * $iDisplayCols
    Local $iDataCount = $iTotalCount - $iStartIndex

    ; Tính toán Scroll hiển thị (Nếu số ván muốn xem > số ô trên bảng)
    Local $iScrollOffset = 0
    If $iDataCount > $iMaxCells Then
        Local $iExcessCols = Ceiling(($iDataCount - $iMaxCells) / $iRows)
        $iScrollOffset = $iExcessCols * $iRows
    EndIf

    ; VẼ LẠI
    For $i = $iStartIndex + $iScrollOffset To $iTotalCount - 1
        ; Tính Index tương đối so với điểm bắt đầu hiển thị
        Local $iRelativeIndex = $i - ($iStartIndex + $iScrollOffset)

        If $iRelativeIndex >= $iMaxCells Then ExitLoop

        Local $iRow = Mod($iRelativeIndex, $iRows)
        Local $iCol = Floor($iRelativeIndex / $iRows)
        Local $iLabelIndex = $iCol + ($iRow * $iDisplayCols)

        If $iLabelIndex < UBound($g_aLabel_History) Then
            Local $sResult = $g_aDisplayHistory[$i]
            Local $bIsLatest = ($i == $iTotalCount - 1)
            _StyleResultLabel($g_aLabel_History[$iLabelIndex], $sResult, False, $bIsLatest)
        EndIf
    Next
EndFunc

Func _StyleResultLabel($hLabel, $sResult, $bHighlight, $bIsLatest)
	GUICtrlSetData($hLabel, $sResult)
	GUICtrlSetFont($hLabel, 8, 700)
	If $bIsLatest Then
		GUICtrlSetBkColor($hLabel, $g_iLatestHighlightColor)
		GUICtrlSetColor($hLabel, 0x000000)
	ElseIf $bHighlight Then
		GUICtrlSetBkColor($hLabel, $g_iHighlightColor)
		GUICtrlSetColor($hLabel, 0x000000)
	Else
		Switch $sResult
			Case "B"
				GUICtrlSetBkColor($hLabel, 0xF70102)
				GUICtrlSetColor($hLabel, 0xFFFFFF)
			Case "P"
				GUICtrlSetBkColor($hLabel, 0x0182FA)
				GUICtrlSetColor($hLabel, 0xFFFFFF)
			Case Else
				GUICtrlSetBkColor($hLabel, 0xE0E0E0)
				GUICtrlSetColor($hLabel, 0x000000)
		EndSwitch
	EndIf
EndFunc

Func _SetControlsState($bEnable)
    Local $iState = $bEnable ? $GUI_ENABLE : $GUI_DISABLE
    Local $iInputColor = $bEnable ? 0xE0FFFF : 0xE0E0E0

    GUICtrlSetState($g_hInput_InitialCapital, $iState)
    GUICtrlSetBkColor($g_hInput_InitialCapital, $iInputColor)
    GUICtrlSetState($g_hInput_InitialBet, $iState)
    GUICtrlSetBkColor($g_hInput_InitialBet, $iInputColor)
    GUICtrlSetState($g_hInput_TakeProfit, $iState)
    GUICtrlSetBkColor($g_hInput_TakeProfit, $iInputColor)
    GUICtrlSetState($g_hInput_StopLoss, $iState)
    GUICtrlSetBkColor($g_hInput_StopLoss, $iInputColor)

    GUICtrlSetState($g_hCombo_Profiles_Main, $iState)
    GUICtrlSetState($g_hRadio_ClickMode_Control_Main, $iState)
    GUICtrlSetState($g_hRadio_ClickMode_Mouse_Main, $iState)
    GUICtrlSetState($g_hInput_ClickDelay_Main, $iState)
    GUICtrlSetState($g_hInput_MouseSpeed, $iState)

    GUICtrlSetState($g_hTabItemConfig, $iState)

    ; Mở khóa GUI cho Custom
    GUICtrlSetState($g_hCheckbox_ContinuousMode, $iState)
    GUICtrlSetState($g_hInput_CustomQLV_Edit, $iState)
    If $bEnable Then
        GUICtrlSetBkColor($g_hInput_CustomQLV_Edit, 0xF0FFF0)
    Else
        GUICtrlSetBkColor($g_hInput_CustomQLV_Edit, 0xE0E0E0)
    EndIf

    GUICtrlSetState($g_hCombo_QLV_Presets, $iState)
    GUICtrlSetState($g_hButton_SaveQLV, $iState)
    GUICtrlSetState($g_hButton_DeleteQLV, $iState)

    GUICtrlSetState($g_hCheckbox_Blacklist, $iState)
    GUICtrlSetState($g_hInput_Blacklist, $iState)
    GUICtrlSetState($g_hCheckbox_Blacklist_IgnoreRunning, $iState)
    GUICtrlSetState($g_hInput_HistoryLimit, $iState)

    If $bEnable Then
        GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
        GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
        GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)

        ; Luôn bật ô nhập liệu
        GUICtrlSetState($g_hInput_CustomRules, $GUI_ENABLE)
        GUICtrlSetState($g_hCheckbox_SeparateQLV, $GUI_ENABLE)
        GUICtrlSetBkColor($g_hInput_CustomRules, 0xFFFACD)
    Else
        GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
        GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)
        GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)

        ; Tối màu khi đang chạy
        GUICtrlSetState($g_hInput_CustomRules, $GUI_DISABLE)
        GUICtrlSetBkColor($g_hInput_CustomRules, 0xE0E0E0)
        GUICtrlSetState($g_hCheckbox_SeparateQLV, $GUI_DISABLE)
    EndIf
EndFunc
Func _UpdateProfitLabel()
	GUICtrlSetData($g_hLabel_Profit, _FormatNumber($g_fTotalProfit) & " VND")
	If $g_fTotalProfit > 0 Then
		GUICtrlSetBkColor($g_hLabel_Profit, 0xFFFACD)
		GUICtrlSetColor($g_hLabel_Profit, 0x33CC33)
	ElseIf $g_fTotalProfit < 0 Then
		GUICtrlSetBkColor($g_hLabel_Profit, 0xFFFACD)
		GUICtrlSetColor($g_hLabel_Profit, 0xFF4141)
	Else
		GUICtrlSetBkColor($g_hLabel_Profit, 0xFFFACD)
		GUICtrlSetColor($g_hLabel_Profit, 0x000000)
	EndIf
EndFunc

Func _UpdateBalanceLabel()
	Local $fCurrentBalance = $g_fInitialCapital + $g_fTotalProfit
	GUICtrlSetData($g_hLabel_CurrentBalance, _FormatNumber($fCurrentBalance) & " VND")
	GUICtrlSetColor($g_hLabel_CurrentBalance, 0x0000FF)
EndFunc

Func _UpdateTotalHandsLabel()
	GUICtrlSetData($g_hLabel_TotalHands, UBound($g_aDisplayHistory))
EndFunc

Func _UpdateTotalVolumeLabel()
	GUICtrlSetData($g_hLabel_TotalVolume, _FormatNumber($g_fTotalVolume) & " VND")
EndFunc

Func _UpdateClock()
	If Not IsHWnd($g_hGUI) Then
		AdlibUnRegister("_UpdateClock")
		Return
	EndIf
	Local $sTime = StringFormat("%02d:%02d:%02d", @HOUR, @MIN, @SEC)
	GUICtrlSetData($g_hLabel_Time, $sTime)
EndFunc

Func _UpdateLicenseInfoLabels($sExpiryDate)
    ; --- TRƯỜNG HỢP 1: VĨNH VIỄN (Server gửi về Lifetime hoặc rỗng) ---
    If $sExpiryDate = "Lifetime" Or $sExpiryDate = "" Then
        ; Ô Hạn sử dụng: Hiện chữ Vĩnh Viễn
        GUICtrlSetData($g_hLabel_ExpiryDate, "Vĩnh Viễn")
        GUICtrlSetColor($g_hLabel_ExpiryDate, 0x0000FF) ; Màu Xanh Dương (Blue)

        ; Ô Còn lại: Hiện biểu tượng Vô cực
        GUICtrlSetData($g_hLabel_DaysRemaining, "∞ (Vô thời hạn)")
        GUICtrlSetColor($g_hLabel_DaysRemaining, 0x0000FF) ; Màu Xanh Dương
        Return
    EndIf

    ; --- TRƯỜNG HỢP 2: CÓ HẠN SỬ DỤNG CỤ THỂ ---
    Local $sToday = @YEAR & "/" & @MON & "/" & @MDAY
    Local $sExp = StringReplace($sExpiryDate, "-", "/") ; Đổi 2026-01-31 thành 2026/01/31

    ; Tính số ngày còn lại
    Local $iDaysLeft = _DateDiff("D", $sToday, $sExp)

    ; Hiển thị ngày hết hạn
    GUICtrlSetData($g_hLabel_ExpiryDate, $sExpiryDate)
    GUICtrlSetColor($g_hLabel_ExpiryDate, 0x006400) ; Màu Xanh Lá Đậm

    ; Hiển thị số ngày còn lại & Đổi màu cảnh báo
    If $iDaysLeft < 0 Then
        GUICtrlSetData($g_hLabel_DaysRemaining, "Hết hạn " & Abs($iDaysLeft) & " ngày")
        GUICtrlSetColor($g_hLabel_DaysRemaining, 0xFF0000) ; Đỏ (Đã hết hạn)
        GUICtrlSetColor($g_hLabel_ExpiryDate, 0xFF0000)
    Else
        GUICtrlSetData($g_hLabel_DaysRemaining, $iDaysLeft & " ngày")

        If $iDaysLeft <= 3 Then
            GUICtrlSetColor($g_hLabel_DaysRemaining, 0xFF0000) ; Đỏ (Sắp hết: <= 3 ngày)
        ElseIf $iDaysLeft <= 7 Then
            GUICtrlSetColor($g_hLabel_DaysRemaining, 0xFF8C00) ; Cam (Cảnh báo: <= 7 ngày)
        Else
            GUICtrlSetColor($g_hLabel_DaysRemaining, 0x006400) ; Xanh Lá (Thoải mái)
        EndIf
    EndIf
EndFunc

Func _FormatNumber($fNumber)
	Local $sSign = ""
	If $fNumber < 0 Then
		$sSign = "-"
		$fNumber = Abs($fNumber)
	EndIf
	Local $sNumber = String(Int($fNumber))
	Return $sSign & StringRegExpReplace($sNumber, '(\d)(?=(\d{3})+(?!\d))', '$1.')
EndFunc

Func _ProcessGUIMessages()
    Local $aMsg = GUIGetMsg(1)
    Switch $aMsg[0]
        Case $GUI_EVENT_CLOSE
            _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
            Exit
        Case $g_hButton_Start
            If $g_bIsRunning Then _StopProcess()
    EndSwitch

    ; =========================================================================
    ; [CẢM BIẾN] KIỂM TRA SẢNH GAME BỊ TẮT THỦ CÔNG (ĐỘ TRỄ 0.1s)
    ; =========================================================================
    If $g_sWDSession <> "" Then
        ; Trường hợp 1: Sảnh game đã bị tắt mất
        If $g_hTargetGameWin <> 0 And Not WinExists($g_hTargetGameWin) Then
            _UpdateStatus("⚠️ Sảnh game đã đóng! Đang dừng tool...")
            _StopProcess()
        EndIf

        ; Trường hợp 2: Trình duyệt bị tắt ngang (Chromedriver mất)
        If Not ProcessExists("chromedriver.exe") And $g_hTargetGameWin = 0 Then
            Local $sBtnText = GUICtrlRead($g_hButton_Start)
            If $sBtnText == "ĐANG MỞ SẢNH..." Or $sBtnText == "ĐANG ĐĂNG NHẬP..." Or $sBtnText == "ĐANG MỞ WEB..." Then
                _UpdateStatus("⚠️ Trình duyệt đã bị đóng đột ngột!")
                _StopProcess()
            EndIf
        EndIf
    EndIf
EndFunc

Func WM_COMMAND_Handler($hWnd, $iMsg, $wParam, $lParam)
    #forceref $hWnd, $iMsg, $lParam
    Local $iCmd = BitShift($wParam, 16)
    Local $iCtrlID = BitAND($wParam, 0xFFFF)

    ; ==========================================================
    ; 1. XỬ LÝ KHI GÕ CHỮ (INPUT/EDIT) -> KÍCH HOẠT AUTO-SAVE
    ; ==========================================================
    If $iCmd = $EN_CHANGE Then
        Switch $iCtrlID
            ; --- NHÓM 1: CÁC Ô NHẬP LIỆU CƠ BẢN (TEXT) ---
            Case $g_hInput_CustomRules, _
                 $g_hInput_Blacklist, _
                 $g_hInput_HistoryLimit, _      ; <--- [MỚI] Đã thêm
                 $g_hInput_ClickDelay_Main, _   ; <--- [MỚI] Đã thêm
                 $g_hInput_MouseSpeed           ; <--- [MỚI] Đã thêm

                ; Riêng ô CustomRules thì cần cập nhật lại ListView thống kê ngay
                If $iCtrlID = $g_hInput_CustomRules Then _InstantDBLookup()

                ; Kích hoạt cờ báo hiệu "Cần Lưu"
                $g_bNeedAutoSave = True
                $g_hAutoSaveTimer = TimerInit()

            ; --- NHÓM 2: CHECKBOX CẦN LƯU NGAY (Nếu bấm) ---
            Case $g_hCheckbox_Blacklist_IgnoreRunning
                 IniWrite($g_sIniPath, "Profile_" & $g_sCurrentLoadedProfile, "Opt_BlacklistIgnoreRun", (GUICtrlRead($g_hCheckbox_Blacklist_IgnoreRunning) = $GUI_CHECKED) ? 1 : 0)

            ; --- NHÓM 3: CÁC Ô TIỀN (CÓ FORMAT SỐ 1.000) ---
            Case $g_hInput_InitialCapital, $g_hInput_InitialBet, $g_hInput_TakeProfit, $g_hInput_StopLoss
                If Not $g_bIsFormatting Then ; Tránh vòng lặp vô tận khi format
                    $g_bIsFormatting = True
                    Local $sText = GUICtrlRead($iCtrlID)
                    Local $sRaw = StringRegExpReplace($sText, "[^0-9]", "")
                    If $sRaw = "" Then $sRaw = "0"
                    Local $sNew = _FormatNumber($sRaw)

                    ; Chỉ cập nhật lại nếu số thay đổi (để giữ vị trí con trỏ chuột không bị nhảy loạn)
                    If $sText <> $sNew Then
                        GUICtrlSetData($iCtrlID, $sNew)
                        ; Đưa con trỏ về cuối dòng
                        GUICtrlSendMsg($iCtrlID, $EM_SETSEL, StringLen($sNew), StringLen($sNew))
                    EndIf
                    $g_bIsFormatting = False

                    ; Kích hoạt lưu
                    $g_bNeedAutoSave = True
                    $g_hAutoSaveTimer = TimerInit()
                EndIf

             ; --- NHÓM 4: Ô NHẬP QLV ---
             Case $g_hInput_CustomQLV_Edit
                 Local $sContent = StringReplace(GUICtrlRead($g_hInput_CustomQLV_Edit), @CRLF, "|NL|")
                 IniWrite($g_sIniPath, "QLV_Global", "QLV_Custom", $sContent)

        EndSwitch
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc

Func _ParseCustomQLVTable()
	ReDim $g_aCustomQLVTable[0][4]
	Local $sAllRules = GUICtrlRead($g_hInput_CustomQLV_Edit)
	Local $aLines = StringSplit(StringStripCR($sAllRules), @LF, $STR_NOCOUNT)
	If UBound($aLines) = 0 Or ($aLines[0] = "" And UBound($aLines) = 1) Then
		MsgBox(48, "Lỗi QLV Linh Hoạt", "Bạn phải nhập ít nhất một dòng quy tắc cho QLV.")
		Return False
	EndIf

	For $i = 0 To UBound($aLines) - 1
		Local $sLine = StringStripWS($aLines[$i], 8)
		If $sLine = "" Then ContinueLoop

		Local $aParts = StringSplit($sLine, "-")
		If $aParts[0] <> 4 Then
			MsgBox(48, "Lỗi QLV Linh Hoạt", "Định dạng sai ở dòng " & $i + 1 & ": '" & $sLine & "'" & @CRLF & "Phải có dạng: Lệnh-Vốn-ThắngVề-ThuaVề (ví dụ: 1-1-0-2)")
			Return False
		EndIf

		For $j = 1 To 4
			If Not StringIsInt($aParts[$j]) Or Number($aParts[$j]) < 0 Then
				MsgBox(48, "Lỗi QLV Linh Hoạt", "Dữ liệu không hợp lệ ở dòng " & $i + 1 & "." & @CRLF & "Tất cả các giá trị phải là số nguyên không âm (>= 0).")
				Return False
			EndIf
		Next

		Local $iCurrentSize = UBound($g_aCustomQLVTable)
		ReDim $g_aCustomQLVTable[$iCurrentSize + 1][4]
		$g_aCustomQLVTable[$iCurrentSize][0] = Number($aParts[1])
		$g_aCustomQLVTable[$iCurrentSize][1] = Number($aParts[2])
		$g_aCustomQLVTable[$iCurrentSize][2] = Number($aParts[3])
		$g_aCustomQLVTable[$iCurrentSize][3] = Number($aParts[4])
	Next

	If UBound($g_aCustomQLVTable) = 0 Then
		MsgBox(48, "Lỗi QLV Linh Hoạt", "Không tìm thấy quy tắc hợp lệ nào.")
		Return False
	EndIf

	If _FindQLVCommandInfo(0) = -1 Then
		MsgBox(48, "Lỗi QLV Linh Hoạt", "Bảng QLV phải chứa định nghĩa cho 'Lệnh 0' để làm điểm bắt đầu/reset.")
		Return False
	EndIf

	Return True
EndFunc

Func _FindQLVCommandInfo($iCommandToFind)
	For $i = 0 To UBound($g_aCustomQLVTable) - 1
		If $g_aCustomQLVTable[$i][0] = $iCommandToFind Then
			Return $i
		EndIf
	Next
	Return -1
EndFunc

; ==================================================================================================
; --- CÁC HÀM TIỆN ÍCH & BẢN QUYỀN ---
; ==================================================================================================
Func _GetHardwareID()
	Return DriveGetSerial("C:")
EndFunc

Func _CheckLicenseOnline()
    Local $aResult[2]

    ; ... (Giữ nguyên đoạn kiểm tra URL và HTTP Request ở đầu) ...
    If StringInStr($g_sAppsScriptBaseURL, "script.google.com") = 0 Then
        $aResult[0] = "CONFIG_ERROR"
        $aResult[1] = "URL sai"
        Return $aResult
    EndIf
    Local $sHWID = _GetHardwareID()
    Local $sFinalURL = $g_sAppsScriptBaseURL & "?action=check_init&hwid=" & $sHWID
    Local $sResponseData = _HTTP_Request($sFinalURL)
    If @error Or $sResponseData = "" Then
        $aResult[0] = "CONNECTION_ERROR"
        Return $aResult
    EndIf

    ; --- LẤY NGÀY HẾT HẠN TỪ JSON (DÙNG CHUNG CHO CẢ OK VÀ EXPIRED) ---
    Local $sExpDate = "Lifetime"
    Local $aRegEx = StringRegExp($sResponseData, '"expiry":"(.*?)"', 3)
    If IsArray($aRegEx) And $aRegEx[0] <> "" Then $sExpDate = $aRegEx[0]

    ; --- XỬ LÝ TRẠNG THÁI ---
    If StringInStr($sResponseData, '"status":"OK"') Then
        $aResult[0] = "OK"
        $aResult[1] = $sExpDate ; Trả về ngày còn hạn (hoặc Lifetime)
        Return $aResult
    EndIf

    If StringInStr($sResponseData, '"status":"EXPIRED"') Then
        $aResult[0] = "EXPIRED"
        $aResult[1] = $sExpDate ; Trả về ngày đã hết hạn để thông báo
        Return $aResult
    EndIf

    ; Các trường hợp khác giữ nguyên
    If StringInStr($sResponseData, '"status":"LOCKED"') Then
        $aResult[0] = "LOCKED"
        Return $aResult
    EndIf
    If StringInStr($sResponseData, '"status":"NEW"') Or StringInStr($sResponseData, '"status":"PENDING"') Then
        $aResult[0] = "INVALID_HWID"
        $aResult[1] = $sHWID
        Return $aResult
    EndIf

    $aResult[0] = "SERVER_ERROR"
    $aResult[1] = $sResponseData
    Return $aResult
EndFunc

Func _ShowUpdateDialog($sNewVersion)
	Local $sMsg = "Đã có phiên bản mới!" & @CRLF & @CRLF & _
			"Phiên bản hiện tại của bạn: " & $g_sVersion & @CRLF & _
			"Phiên bản mới nhất có sẵn: " & $sNewVersion & @CRLF & @CRLF & _
			"Bạn phải cập nhật để tiếp tục sử dụng." & @CRLF & _
			"Bạn có muốn tải bản cập nhật ngay bây giờ không?"

	Local $iChoice = MsgBox(4 + 32, "Yêu Cầu Cập Nhật", $sMsg)

	If $iChoice = 6 Then
		ShellExecute($g_sDownloadURL)
		MsgBox(64, "Đang Tải...", "Trình duyệt của bạn sẽ mở để tải bản cập nhật. Tool sẽ thoát ngay sau đây.")
	Else
		MsgBox(48, "Đã Hủy", "Tool sẽ thoát vì bạn đã chọn không cập nhật.")
	EndIf
	Exit
EndFunc

Func _SendActivityLog($sStatus, $sInfo = "", $sDuration = "")
	Local $sHWID = _GetHardwareID()
	Local $sInstanceInfo = ($g_sInstanceIdentifier <> "") ? StringStripWS(StringReplace($g_sInstanceIdentifier, ":", ""), 8) & " " : ""
	Local $sCombinedInfo = $g_sToolName & " " & $sInstanceInfo & "- " & $sInfo
	Local $sEncodedInfo = StringReplace($sCombinedInfo, " ", "+")
	Local $sFinalURL = $g_sAppsScriptBaseURL & "?action=log" & _
			"&hwid=" & $sHWID & _
			"&status=" & $sStatus & _
			"&version=" & $g_sVersion & _
			"&info=" & $sEncodedInfo & _
			"&duration=" & $sDuration
	_INetGetSource($sFinalURL)
EndFunc

Func _ShowActivationDialog($sHWID)
	Local $hActivationGUI = GUICreate("Yêu cầu Kích hoạt", 500, 250, -1, -1, $WS_SYSMENU, $WS_EX_TOPMOST)
	GUISetFont(10, 400, 0, "Arial")
	GUISetBkColor(0xF5F5F5)
	Local $sMsg = "Tool của bạn chưa được kích hoạt hoặc đã hết hạn." & @CRLF & @CRLF & _
			"Vui lòng sao chép 'Mã máy' bên dưới và gửi cho nhà cung cấp để được hỗ trợ."
	GUICtrlCreateLabel($sMsg, 10, 10, 480, 60)
	GUICtrlCreateLabel("Liên hệ nhà cung cấp:", 10, 80, 150, 20)
	Local $hTeleLink = GUICtrlCreateLabel("https://t.me/nnduy2086", 160, 80, 330, 20)
	GUICtrlSetColor($hTeleLink, 0x0000FF)
	GUICtrlSetCursor($hTeleLink, 0)
	GUICtrlCreateLabel("Mã máy của bạn:", 10, 110, 480, 20)
	Local $hHwidInput = GUICtrlCreateInput($sHWID, 10, 130, 480, 30, BitOR($ES_CENTER, $ES_READONLY))
	GUICtrlSetFont(-1, 14, 700)
	GUICtrlSetBkColor(-1, 0xE0E0E0)
	Local $hButton = GUICtrlCreateButton("Sao chép Mã & Mở Telegram", 100, 180, 300, 50)
	GUICtrlSetFont(-1, 12, 700)
	GUICtrlSetBkColor(-1, 0x27A7E7)
	GUICtrlSetColor(-1, 0xFFFFFF)
	GUISetState(@SW_SHOW, $hActivationGUI)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE
				ExitLoop
			Case $hTeleLink
				ShellExecute("https://t.me/nnduy2086")
			Case $hButton
				ClipPut($sHWID)
				ShellExecute("https://t.me/nnduy2086")
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($hActivationGUI)
EndFunc

Func _ShowExpiryDialog($sExpiryDate)
	Local $hExpiryGUI = GUICreate("Thông Báo Hết Hạn", 500, 250, -1, -1, $WS_SYSMENU, $WS_EX_TOPMOST)
	GUISetFont(10, 400, 0, "Arial")
	GUISetBkColor(0xFFF0F5)
	Local $sMsg = "Rất tiếc, giấy phép sử dụng của bạn đã hết hạn vào ngày: " & $sExpiryDate & "." & @CRLF & @CRLF & _
			"Vui lòng liên hệ nhà cung cấp để gia hạn và tiếp tục sử dụng."
	Local $hMsgLabel = GUICtrlCreateLabel($sMsg, 10, 10, 480, 60)
	GUICtrlSetFont($hMsgLabel, 11)
	GUICtrlSetColor($hMsgLabel, 0xFF0000)
	Local $hProviderLabel = GUICtrlCreateLabel("Nhà cung cấp:", 10, 85, 120, 20)
	GUICtrlSetFont($hProviderLabel, 11, 700)
	GUICtrlSetColor($hProviderLabel, 0x0000FF)
	Local $hTeleUserLabel = GUICtrlCreateLabel("@nnduy2086", 130, 85, 200, 20)
	GUICtrlSetFont($hTeleUserLabel, 11, 700)
	GUICtrlSetColor($hTeleUserLabel, 0x32CD32)
	Local $hButtonContact = GUICtrlCreateButton("Liên hệ Gia hạn qua Telegram", 100, 120, 300, 50)
	GUICtrlSetFont(-1, 12, 700)
	GUICtrlSetBkColor($hButtonContact, 0xADD8E6)
	GUICtrlSetColor($hButtonContact, 0xFFFF00)
	Local $hButtonClose = GUICtrlCreateButton("Đóng", 200, 180, 100, 30)
	GUICtrlSetBkColor($hButtonClose, 0xFFA07A)
	GUISetState(@SW_SHOW, $hExpiryGUI)
	While 1
		Switch GUIGetMsg()
			Case $GUI_EVENT_CLOSE, $hButtonClose
				ExitLoop
			Case $hButtonContact
				ShellExecute("https://t.me/nnduy2086")
				ExitLoop
		EndSwitch
	WEnd
	GUIDelete($hExpiryGUI)
EndFunc

; ==============================================================================
; CÁC HÀM QUẢN LÝ MẪU QLV (ĐÃ NÂNG CẤP: THÊM/SỬA/XÓA TOÀN BỘ)
; ==============================================================================

Func _PopulateQLVList()
    Local $aUserPresets = IniReadSection($g_sIniPath, "UserQLV")
    Local $sList = "Tùy chỉnh" ; Luôn có tùy chọn này đầu tiên

    If Not @error Then
        For $i = 1 To $aUserPresets[0][0]
            $sList &= "|" & $aUserPresets[$i][0]
        Next
    EndIf

    ; Cập nhật Combo Box
    Local $sCurrent = GUICtrlRead($g_hCombo_QLV_Presets)
    GUICtrlSetData($g_hCombo_QLV_Presets, "", "") ; Xóa danh sách cũ
    GUICtrlSetData($g_hCombo_QLV_Presets, $sList, $sCurrent)
EndFunc

Func _HandleQLVPresetChange()
    Local $sSelectedPreset = GUICtrlRead($g_hCombo_QLV_Presets)

    If $sSelectedPreset = "Tùy chỉnh" Then Return

    ; Đọc nội dung từ file config.ini
    Local $sQLV_String = IniRead($g_sIniPath, "UserQLV", $sSelectedPreset, "")

    If $sQLV_String <> "" Then
        ; Thay thế ký tự xuống dòng đặc biệt |NL| thành xuống dòng thật để hiển thị đẹp
        GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace($sQLV_String, "|NL|", @CRLF))
    EndIf
EndFunc

Func _SaveCustomQLV()
    Local $sCurrentContent = GUICtrlRead($g_hInput_CustomQLV_Edit)
    If $sCurrentContent = "" Then Return

    ; Hỏi tên muốn lưu
    Local $sName = InputBox("Lưu/Sửa Mẫu QLV", "Đặt tên cho mẫu (nhập tên cũ để ghi đè):", "", "", 250, 130)
    If @error Or $sName = "" Then Return

    ; Chuẩn hóa nội dung để lưu trên 1 dòng
    Local $sContentToSave = StringReplace($sCurrentContent, @CRLF, "|NL|")

    ; Ghi vào file ini
    IniWrite($g_sIniPath, "UserQLV", $sName, $sContentToSave)

    MsgBox(64, "Thành công", "Đã lưu mẫu '" & $sName & "'.")
    _PopulateQLVList
    GUICtrlSetData($g_hCombo_QLV_Presets, $sName) ; Chọn mẫu vừa lưu
EndFunc

Func _DeleteCustomQLV()
    Local $sSelected = GUICtrlRead($g_hCombo_QLV_Presets)

    If $sSelected = "Tùy chỉnh" Or $sSelected = "" Then
        MsgBox(48, "Lỗi", "Vui lòng chọn một mẫu cụ thể để xóa.")
        Return
    EndIf

    Local $iConfirm = MsgBox(36, "Xác nhận Xóa", "Bạn có chắc chắn muốn xóa vĩnh viễn mẫu '" & $sSelected & "' không?" & @CRLF & "(Hành động này không thể hoàn tác)")
    If $iConfirm = 6 Then
        ; Xóa khỏi file cấu hình
        IniDelete($g_sIniPath, "UserQLV", $sSelected)

        MsgBox(64, "Đã xóa", "Đã xóa mẫu '" & $sSelected & "'.")

        ; Cập nhật lại giao diện
        _PopulateQLVList()
        GUICtrlSetData($g_hCombo_QLV_Presets, "Tùy chỉnh")
        GUICtrlSetData($g_hInput_CustomQLV_Edit, "") ; Xóa trắng ô nhập liệu
    EndIf
EndFunc

Func _EnsureDefaultQLVExists()
    ; Đọc thử xem đã có dữ liệu chưa
    Local $aData = IniReadSection($g_sIniPath, "UserQLV")

    ; [NÂNG CẤP] Nếu bị lỗi (@error) HOẶC danh sách đang trống trơn ($aData[0][0] = 0)
    ; Thì tiến hành ghi lại bộ mẫu mặc định ngay lập tức
    If @error Or $aData[0][0] = 0 Then
        IniWrite($g_sIniPath, "UserQLV", "Gấp thếp (Martingale)", "0-1-0-1|NL|1-2-0-2|NL|2-4-0-3|NL|3-8-0-4|NL|4-16-0-5|NL|5-32-0-6|NL|6-64-0-0")
        IniWrite($g_sIniPath, "UserQLV", "Gấp thếp ngược (Thắng)", "0-1-1-0|NL|1-2-2-0|NL|2-4-3-0|NL|3-8-4-0|NL|4-16-5-0|NL|5-32-6-0|NL|6-64-0-0")
        IniWrite($g_sIniPath, "UserQLV", "Fibonacci", "0-1-0-1|NL|1-1-0-2|NL|2-2-1-3|NL|3-3-2-4|NL|4-5-3-5|NL|5-8-4-6|NL|6-13-5-7|NL|7-21-6-8|NL|8-34-7-9|NL|9-55-8-0")
        IniWrite($g_sIniPath, "UserQLV", "D'Alembert", "0-1-0-1|NL|1-2-0-2|NL|2-3-1-3|NL|3-4-2-4|NL|4-5-3-5|NL|5-6-4-6|NL|6-7-5-7|NL|7-8-6-8|NL|8-9-7-9|NL|9-10-8-0")
        IniWrite($g_sIniPath, "UserQLV", "An toàn (Thua 2 nghỉ)", "0-1-0-1|NL|1-1-0-2|NL|2-0-0-0")

        ; Sau khi ghi xong, gọi hàm nạp lại danh sách lên giao diện ngay lập tức
        _PopulateQLVList()
    EndIf
EndFunc

; ==============================================================================
; CÁC HÀM LƯU GIỮ TRẠNG THÁI PHIÊN (SESSION PERSISTENCE)
; ==============================================================================

Func _SaveSessionState()
    Local $sHistoryString = _ArrayToString($g_aDisplayHistory, ",")
    IniWrite($g_sIniPath, "SessionData", "History", $sHistoryString)
    IniWrite($g_sIniPath, "SessionData", "CapitalLevel", $g_iCapitalLevel)
    IniWrite($g_sIniPath, "SessionData", "TotalProfit", $g_fTotalProfit)
    IniWrite($g_sIniPath, "SessionData", "CycleStep", $g_iCycleStep)
    IniWrite($g_sIniPath, "SessionData", "CurrentWinStreak", $g_iCurrentWinStreak)
    IniWrite($g_sIniPath, "SessionData", "CurrentLossStreak", $g_iCurrentLossStreak)
    IniWrite($g_sIniPath, "SessionData", "TotalVolume", $g_fTotalVolume)

    Local $sSaveDate = @YEAR & "/" & @MON & "/" & @MDAY
    If Number(@HOUR) < 7 Then $sSaveDate = _DateAdd('d', -1, $sSaveDate)
    IniWrite($g_sIniPath, "SessionData", "VolumeDate", $sSaveDate)

    ; --- THÊM DÒNG NÀY ĐỂ LƯU MEMORY ---
EndFunc

Func _LoadSessionState()
    ; --- ĐÃ TẮT TÍNH NĂNG LƯU LỊCH SỬ KHI KHỞI ĐỘNG LẠI ---
    ; Local $sHistoryString = IniRead($g_sIniPath, "SessionData", "History", "")
    ; If $sHistoryString <> "" Then
    ;     $g_aDisplayHistory = StringSplit($sHistoryString, ",", 2)
    ;     _RedrawHistory()
    ;     _UpdateTotalHandsLabel()
    ; EndIf

    ; Ép lợi nhuận và chuỗi gấp thếp về 0 khi mới mở tool
    $g_iCapitalLevel = 0
    $g_fTotalProfit = 0

    ; =========================================================================
    ; [LOGIC VOLUME] CỘNG DỒN 24H (7:00 SÁNG NAY -> 7:00 SÁNG MAI)
    ; =========================================================================
    Local $sCurrentGamingDate = @YEAR & "/" & @MON & "/" & @MDAY
    If Number(@HOUR) < 7 Then $sCurrentGamingDate = _DateAdd('d', -1, $sCurrentGamingDate)

    Local $sSavedDate = IniRead($g_sIniPath, "SessionData", "VolumeDate", "")
    If $sSavedDate = $sCurrentGamingDate Then
        $g_fTotalVolume = Number(IniRead($g_sIniPath, "SessionData", "TotalVolume", "0"))
    Else
        $g_fTotalVolume = 0 ; Chỉ qua 7h sáng mới bị reset
    EndIf
    ; =========================================================================

    $g_iCycleStep = 1
    $g_iCurrentWinStreak = 0
    $g_iCurrentLossStreak = 0

    _UpdateProfitLabel()
    _UpdateBalanceLabel()
    _UpdateTotalVolumeLabel()
EndFunc
; ==============================================================================
; CÁC HÀM LẤY TỌA ĐỘ VÀ MÀU SẮC NHANH (SỬA ĐỔI: LẤY TỪ PHÍM S)
; ==============================================================================

; --- HÀM LẤY TỌA ĐỘ TỪ BIẾN TẠM (PHÍM S) ---
Func _GetCoords_Fast($hInputX, $hInputY)
    ; Kiểm tra xem người dùng đã bấm S chưa (Nếu tọa độ là 0,0 thì cảnh báo)
    If $g_iTempX = 0 And $g_iTempY = 0 Then
        ToolTip("⚠️ Chưa có dữ liệu! Hãy di chuột vào điểm cần lấy và bấm phím 'S' trước.", MouseGetPos()[0], MouseGetPos()[1], "Cảnh báo", 2, 1)
        Sleep(1500)
        ToolTip("")
        Return
    EndIf

    ; Dán dữ liệu từ biến tạm vào ô Input
    GUICtrlSetData($hInputX, $g_iTempX)
    GUICtrlSetData($hInputY, $g_iTempY)

    ; Kích hoạt cờ báo hiệu cần lưu ngay
    $g_bNeedAutoSave = True
    $g_hAutoSaveTimer = TimerInit()
EndFunc

; --- HÀM LẤY MÀU TỪ BIẾN TẠM (PHÍM S) ---
Func _GetColor_Fast($hInputControl)
    If $g_iTempColor = 0 Then
        ToolTip("⚠️ Chưa có dữ liệu! Hãy di chuột vào màu cần lấy và bấm phím 'S' trước.", MouseGetPos()[0], MouseGetPos()[1], "Cảnh báo", 2, 1)
        Sleep(1500)
        ToolTip("")
        Return
    EndIf

    ; Dán mã màu Hex vào ô Input
    GUICtrlSetData($hInputControl, "0x" & Hex($g_iTempColor, 6))

    ; Kích hoạt cờ báo hiệu cần lưu ngay
    $g_bNeedAutoSave = True
    $g_hAutoSaveTimer = TimerInit()
EndFunc

Func _WaitForBettingTime_Safe()
    ; [QUAN TRỌNG] Bỏ tìm Class chung chung. Chỉ dùng đúng Handle độc quyền của Tool
    Local $hWnd = $g_hTargetGameWin
    If $hWnd = 0 Or Not WinExists($hWnd) Then Return False

    Local $hTimer = TimerInit()
    Local $iTolerance = Number(GUICtrlRead($g_hInput_Shade_Timer))

    _UpdateStatus("Đang tìm tín hiệu cược (Màu: " & "0x" & Hex($g_iBetTimeIndicatorColor, 6) & ")...")

    While Not IsArray(PixelSearch($g_aBetTimeIndicatorArea[0], $g_aBetTimeIndicatorArea[1], $g_aBetTimeIndicatorArea[2], $g_aBetTimeIndicatorArea[3], $g_iBetTimeIndicatorColor, $iTolerance, 1, $hWnd))
        _ProcessGUIMessages()
        If Not $g_bIsRunning Then
            ToolTip("")
            Return False
        EndIf

        Local $iElapsed = Round(TimerDiff($hTimer) / 1000, 1)
        ToolTip("Đang tìm Giờ Cược: " & $iElapsed & "s", MouseGetPos()[0], MouseGetPos()[1] - 50)

Sleep(100)
    WEnd

    ToolTip("")
    Return True
EndFunc

Func _SaveSettings()
    ; Xác định đường dẫn file config
    Local $sFile = $g_sIniPath

    ; ======================================================
    ; 1. LƯU CẤU HÌNH BÀN (QUAN TRỌNG - GIỮ LẠI TỪ CŨ)
    ; ======================================================
    ; Dòng này giúp lưu Tọa độ, Màu sắc, QLV của bàn hiện tại
    _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))

    ; ======================================================
    ; 2. LƯU CÀI ĐẶT CHUNG CỦA TOOL (PHẦN MỚI)
    ; ======================================================

    ; a) Lưu vị trí cửa sổ (để lần sau mở lên đúng chỗ cũ)
    Local $aPos = WinGetPos($g_hGui)
    If IsArray($aPos) Then
        IniWrite($sFile, "Settings", "WinX", $aPos[0])
        IniWrite($sFile, "Settings", "WinY", $aPos[1])
    EndIf

    ; b) Lưu trạng thái checkbox "Chế độ thống kê"
    If IsDeclared("g_hCheckbox_StatsMode") Then
    EndIf
    ; d) Lưu tên bàn đang dùng cuối cùng
    If IsDeclared("g_sCurrentLoadedProfile") And $g_sCurrentLoadedProfile <> "" Then
        IniWrite($sFile, "Settings", "LastProfile", $g_sCurrentLoadedProfile)
    EndIf

    ; _UpdateStatus("Đã lưu toàn bộ cài đặt.")
EndFunc

; --- HÀM THIẾT LẬP CÀI ĐẶT HIỆN TẠI (BỊ THIẾU) ---
Func _ApplyCurrentSettings()
    ; Cập nhật biến toàn cục từ giao diện để tool chạy
    $g_sClickMode = (GUICtrlRead($g_hRadio_ClickMode_Control_Main) = $GUI_CHECKED) ? "Control" : "Mouse"
    $g_iClickDelay = Number(GUICtrlRead($g_hInput_ClickDelay_Main))
    $g_iMouseSpeed = Number(GUICtrlRead($g_hInput_MouseSpeed))
EndFunc

Func _MasterSave($sProfileName, $bSilent = True)
    If $sProfileName = "" Then Return
    Local $sSection = "Profile_" & $sProfileName

    IniWrite($g_sIniPath, $sSection, "InitialCapital", GUICtrlRead($g_hInput_InitialCapital))
    IniWrite($g_sIniPath, $sSection, "InitialBet", GUICtrlRead($g_hInput_InitialBet))
    IniWrite($g_sIniPath, $sSection, "TakeProfit", GUICtrlRead($g_hInput_TakeProfit))
    IniWrite($g_sIniPath, $sSection, "StopLoss", GUICtrlRead($g_hInput_StopLoss))
    IniWrite($g_sIniPath, $sSection, "HistoryLimit", GUICtrlRead($g_hInput_HistoryLimit))
    IniWrite($g_sIniPath, "Settings", "ClickDelay", GUICtrlRead($g_hInput_ClickDelay_Main))
    IniWrite($g_sIniPath, "Settings", "MouseSpeed", GUICtrlRead($g_hInput_MouseSpeed))
    IniWrite($g_sIniPath, "Settings", "ClickMode", (GUICtrlRead($g_hRadio_ClickMode_Control_Main) = $GUI_CHECKED) ? "Control" : "Mouse")
    Local $sRules = StringReplace(GUICtrlRead($g_hInput_CustomRules), @CRLF, "|NL|")
    IniWrite($g_sIniPath, $sSection, "CustomRulesList", $sRules)
    IniWrite($g_sIniPath, $sSection, "Opt_SeparateQLV", (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED) ? 1 : 0)
    IniWrite($g_sIniPath, $sSection, "Opt_ContinuousMode", (GUICtrlRead($g_hCheckbox_ContinuousMode) = $GUI_CHECKED) ? 1 : 0)

    ; >>> ĐÃ KHÔI PHỤC VÀ SỬA CHUẨN ĐOẠN NÀY <<<
    IniWrite($g_sIniPath, $sSection, "Opt_AfterWinLogic_ID", "2")
    Local $sContentToSave = StringReplace(GUICtrlRead($g_hInput_CustomQLV_Edit), @CRLF, "|NL|")
    IniWrite($g_sIniPath, $sSection, "CustomQLV", $sContentToSave)
    ; >>> ================================== <<<

    ; --- [CẬP NHẬT] LƯU O+M & BLACKLIST ---
    IniWrite($g_sIniPath, $sSection, "Blacklist", GUICtrlRead($g_hInput_Blacklist))

    ; Lưu trạng thái Checkbox Blacklist
    IniWrite($g_sIniPath, $sSection, "Opt_BlacklistEnabled", (GUICtrlRead($g_hCheckbox_Blacklist) = $GUI_CHECKED) ? 1 : 0)
    IniWrite($g_sIniPath, $sSection, "Opt_BlacklistIgnoreRun", (GUICtrlRead($g_hCheckbox_Blacklist_IgnoreRunning) = $GUI_CHECKED) ? 1 : 0)

    IniWrite($g_sIniPath, $sSection, "WindowClass", GUICtrlRead($g_hInput_WindowClass))
    IniWrite($g_sIniPath, $sSection, "BankerX", GUICtrlRead($g_hInput_BankerX))
    IniWrite($g_sIniPath, $sSection, "BankerY", GUICtrlRead($g_hInput_BankerY))
    IniWrite($g_sIniPath, $sSection, "PlayerX", GUICtrlRead($g_hInput_PlayerX))
    IniWrite($g_sIniPath, $sSection, "PlayerY", GUICtrlRead($g_hInput_PlayerY))
    IniWrite($g_sIniPath, $sSection, "ResultX1", GUICtrlRead($g_hInput_ResultX1))
    IniWrite($g_sIniPath, $sSection, "ResultY1", GUICtrlRead($g_hInput_ResultY1))
    IniWrite($g_sIniPath, $sSection, "ResultX2", GUICtrlRead($g_hInput_ResultX2))
    IniWrite($g_sIniPath, $sSection, "ResultY2", GUICtrlRead($g_hInput_ResultY2))
    IniWrite($g_sIniPath, $sSection, "BankerColor", GUICtrlRead($g_hInput_BankerColor))
    IniWrite($g_sIniPath, $sSection, "PlayerColor", GUICtrlRead($g_hInput_PlayerColor))
    IniWrite($g_sIniPath, $sSection, "TieColor", GUICtrlRead($g_hInput_TieColor))
    IniWrite($g_sIniPath, $sSection, "Shade_Result", GUICtrlRead($g_hInput_Shade_Result))
    IniWrite($g_sIniPath, $sSection, "BetTimeX1", GUICtrlRead($g_hInput_BetTimeX1))
    IniWrite($g_sIniPath, $sSection, "BetTimeY1", GUICtrlRead($g_hInput_BetTimeY1))
    IniWrite($g_sIniPath, $sSection, "BetTimeX2", GUICtrlRead($g_hInput_BetTimeX2))
    IniWrite($g_sIniPath, $sSection, "BetTimeY2", GUICtrlRead($g_hInput_BetTimeY2))
    IniWrite($g_sIniPath, $sSection, "BetTimeColor", GUICtrlRead($g_hInput_BetTimeColor))
    IniWrite($g_sIniPath, $sSection, "Shade_Timer", GUICtrlRead($g_hInput_Shade_Timer))

    For $i = 0 To 4
        IniWrite($g_sIniPath, $sSection, "ChipEnabled_" & $i, (GUICtrlRead($g_aCheckbox_ChipEnabled[$i]) = $GUI_CHECKED ? 1 : 0))
        IniWrite($g_sIniPath, $sSection, "ChipValue_" & $i, GUICtrlRead($g_aInput_ChipValue[$i]))
        IniWrite($g_sIniPath, $sSection, "ChipX_" & $i, GUICtrlRead($g_aInput_ChipX[$i]))
        IniWrite($g_sIniPath, $sSection, "ChipY_" & $i, GUICtrlRead($g_aInput_ChipY[$i]))
    Next
    _SaveSessionState()
    IniWrite($g_sIniPath, "UISettings", "LastProfile", $sProfileName)
    If Not $bSilent Then _UpdateStatus("Đã lưu dữ liệu bàn: " & $sProfileName)
EndFunc

Func _GetDefaultQLV_ForMethod($sMethod)
    ; Giữ hàm này để tránh lỗi code (vì các hàm khác vẫn đang gọi nó).
    ; Tuy nhiên, trả về RỖNG ("") để không tự điền bất kỳ gợi ý nào.
    ; Ô nhập liệu sẽ trắng trơn cho bạn tự thao tác.
    Return ""
EndFunc

; --- HÀM TẢI THỐNG KÊ TẦN SUẤT TỪ FILE ---
Func _LoadStreakStats_Permanent($sMethod)
    Local $sFile = @ScriptDir & "\stats_history.ini"

    ; 1. Tải chuỗi Thắng
    Local $sWinStr = IniRead($sFile, $sMethod, "WinFreqArray", "")
    If $sWinStr = "" Then
        Dim $g_aWinFreq[50] ; Nếu chưa có thì tạo mới rỗng
    Else
        Local $aTemp = StringSplit($sWinStr, ",", 2) ; 2 = Flag không trả về count ở [0]
        If UBound($aTemp) < 50 Then ReDim $aTemp[50] ; Đảm bảo mảng đủ lớn
        $g_aWinFreq = $aTemp
    EndIf

    ; 2. Tải chuỗi Thua
    Local $sLossStr = IniRead($sFile, $sMethod, "LossFreqArray", "")
    If $sLossStr = "" Then
        Dim $g_aLossFreq[50]
    Else
        Local $aTemp2 = StringSplit($sLossStr, ",", 2)
        If UBound($aTemp2) < 50 Then ReDim $aTemp2[50]
        $g_aLossFreq = $aTemp2
    EndIf
EndFunc

; --- HÀM MỚI (ĐÃ NÂNG CẤP): TÌM TÊN PRESET DỰA TRÊN NỘI DUNG ---
Func _FindPresetNameByContent($sContent)
    ; 1. Làm sạch dữ liệu đầu vào (Xóa khoảng trắng thừa 2 đầu)
    $sContent = StringStripWS($sContent, 3)

    ; 2. Xóa sạch ký tự xuống dòng thừa ở cuối (|NL|) để so sánh chuẩn
    While StringRight($sContent, 4) = "|NL|"
        $sContent = StringTrimRight($sContent, 4)
    WEnd

    ; Đọc danh sách mẫu
    Local $aUserPresets = IniReadSection($g_sIniPath, "UserQLV")
    If @error Then Return "Tùy chỉnh"

    ; Duyệt qua từng mẫu
    For $i = 1 To $aUserPresets[0][0]
        Local $sPresetRaw = $aUserPresets[$i][1] ; Nội dung mẫu

        ; 3. Cũng làm sạch dữ liệu mẫu y hệt như trên
        $sPresetRaw = StringStripWS($sPresetRaw, 3)
        While StringRight($sPresetRaw, 4) = "|NL|"
            $sPresetRaw = StringTrimRight($sPresetRaw, 4)
        WEnd

        ; 4. So sánh nội dung đã làm sạch
        If $sPresetRaw = $sContent Then
            Return $aUserPresets[$i][0] ; Trả về tên (VD: Martingale)
        EndIf
    Next

    Return "Tùy chỉnh" ; Nếu vẫn không khớp thì chịu
EndFunc

Func _Logic_Custom($iTotalHands, $iBetUnit_Global, $bContinuous_Param)
    Local $aResult[3] = ["OBSERVE", "", 0]

    ; --- LẤY LỊCH SỬ CHUẨN (CÁCH LY HOÀN TOÀN BỆNH CỦA AUTOIT) ---
    Local $sHistoryRaw = ""
    Local $iStart = 0
    ; [ĐÃ SỬA LỖI] Phải dùng dấu <= thay vì <
    If $g_iHistoryCutoffIndex <= UBound($g_aDisplayHistory) Then
        $iStart = $g_iHistoryCutoffIndex
    EndIf

    ; Quét thủ công từng phần tử để đảm bảo không bao giờ bị trượt tín hiệu
    For $i = $iStart To UBound($g_aDisplayHistory) - 1
        $sHistoryRaw &= $g_aDisplayHistory[$i]
    Next
    Local $sHistoryNow = StringReplace($sHistoryRaw, "T", "")

    Local $bSepQLV = (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED)

    ; Xử lý chuỗi nhập liệu
    Local $sRulesRaw = StringStripWS(GUICtrlRead($g_hInput_CustomRules), 3)
    $sRulesRaw = StringReplace($sRulesRaw, @CRLF, @LF)
    Local $aLines = StringSplit($sRulesRaw, @LF)

    ; Mở rộng mảng nhớ vốn nếu cần
    If $bSepQLV And UBound($g_aRuleLevels) < ($aLines[0] + 5) Then
        ReDim $g_aRuleLevels[$aLines[0] + 10]
    EndIf

    ; ========================================================================
    ; TRƯỜNG HỢP 1: ĐANG THEO DÂY (CHASE MODE)
    ; ========================================================================
    If $g_iLastActiveRuleIndex > -1 Then
        Local $iIdx = $g_iLastActiveRuleIndex
        Local $iLevel = 0

        If $iIdx < UBound($g_aRuleLevels) Then $iLevel = $g_aRuleLevels[$iIdx]

        If ($iIdx + 1) <= $aLines[0] Then
            Local $sLine = StringStripWS($aLines[$iIdx + 1], 8)
            Local $aParts = StringSplit($sLine, "-")
            Local $sBetSeq = ""

            If $aParts[0] >= 2 Then
                $sBetSeq = $aParts[2]
            Else
                $sBetSeq = StringRight($sLine, 1)
            EndIf

            ; Nếu bước đánh hiện tại vẫn còn nằm trong chuỗi -> ĐÁNH TIẾP
            If $g_iCustomSeqStep <= StringLen($sBetSeq) And $g_iCustomSeqStep > 0 Then
                Local $sCharToBet = StringMid($sBetSeq, $g_iCustomSeqStep, 1)
                Local $aQLV = _GetQLV_Params($iLevel)

                $aResult[0] = "BET"
                $aResult[1] = $sCharToBet
                $aResult[2] = $aQLV[1]

                _UpdateStatus("🔥 Đang theo dòng " & ($iIdx + 1) & " (Bước " & $g_iCustomSeqStep & "/" & StringLen($sBetSeq) & "): Đánh " & $sCharToBet)
                Return $aResult
            Else
                ; ĐÃ HẾT CHUỖI -> RESET BỘ NHỚ BƯỚC ĐÁNH
                $g_iLastActiveRuleIndex = -1
                $g_iCustomSeqStep = 0

                If Not BitAND(GUICtrlRead($g_hCheckbox_ContinuousMode), $GUI_CHECKED) Then
                    $g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
                    _UpdateStatus("⛔ Thua hết bảng vốn -> Cắt cầu lịch sử -> Chờ tín hiệu mới.")
                EndIf
                ; Dòng tín hiệu đã bị bạn xóa khỏi bảng nhập -> Reset
                $g_iLastActiveRuleIndex = -1
                $g_iCustomSeqStep = 0
            EndIf
        EndIf
    EndIf ; <=== ĐÂY LÀ CHỮ EndIf QUAN TRỌNG MÀ BẠN ĐÃ BỊ THIẾU !!!

    ; ========================================================================
    ; TRƯỜNG HỢP 2: TÌM TÍN HIỆU MỚI (SCAN MODE)
    ; ========================================================================
    For $i = 1 To $aLines[0]
        Local $sLine = StringStripWS($aLines[$i], 8)
        If $sLine = "" Then ContinueLoop

        Local $sWaitSig = ""
        Local $sBetSeq = ""
        Local $aParts = StringSplit($sLine, "-")

        If $aParts[0] >= 2 Then
            $sWaitSig = $aParts[1]
            $sBetSeq = $aParts[2]
        Else
            $sWaitSig = $sLine
            $sBetSeq = StringRight($sLine, 1)
        EndIf

        $sWaitSig = StringReplace($sWaitSig, "T", "")

        ; KHÔNG QUÉT NẾU LỊCH SỬ ĐANG TRỐNG (Do vừa bị cắt cầu)
        If $sHistoryNow = "" Then ContinueLoop

        If _CheckBlacklist($sHistoryNow) Then
             If StringRight($sHistoryNow, StringLen($sWaitSig)) = $sWaitSig Then
                  Local $iMyLevel = 0
                  If $bSepQLV Then
                       If ($i - 1) < UBound($g_aRuleLevels) Then $iMyLevel = $g_aRuleLevels[$i - 1]
                  Else
                      $iMyLevel = $g_iCapitalLevel
                  EndIf

                  Local $aQLV = _GetQLV_Params($iMyLevel)

                  $g_sCurrentRuleSignature = StringUpper($sWaitSig) & "-SEQ"
                  $g_iCustomSeqStep = 1 ; Khởi động bước 1

                  Local $sFirstChar = StringMid($sBetSeq, 1, 1)

                  $aResult[0] = "BET"
                  $aResult[1] = $sFirstChar
                  $aResult[2] = $aQLV[1]

                  ; KHÓA DÒNG BẤT KỂ QLV CHUNG/RIÊNG
                  $g_iLastActiveRuleIndex = $i - 1

                  _UpdateStatus("🎯 Khớp dòng " & $i & ": [" & $sWaitSig & "] -> Bắt đầu dây (Bước 1): " & $sFirstChar)
                  Return $aResult
              EndIf
         EndIf
    Next

    If $g_iHistoryCutoffIndex > 0 Then
        _UpdateStatus("⏳ Đã cắt cầu. Chờ tín hiệu mới (" & StringLen($sHistoryNow) & " tay)...")
    Else
        _UpdateStatus("⏳ Đang dò tín hiệu (Custom)...")
    EndIf

    Return $aResult
EndFunc
; --- HÀM TỰ ĐỘNG ĐỒNG BỘ DỮ LIỆU TỪ DANH SÁCH NHẬP ---
Func _InstantDBLookup()
    _GUICtrlListView_BeginUpdate($g_hListView_Stats) ; Tối ưu tốc độ vẽ
    _GUICtrlListView_DeleteAllItems($g_hListView_Stats)

    Local $sRulesRaw = GUICtrlRead($g_hInput_CustomRules)
    Local $aLines = StringSplit($sRulesRaw, @CRLF, 1)
    Local $sFileStats = @ScriptDir & "\stats_rules_history.ini"
    Local $sPrefix = "PERM_" ; Luôn đọc từ kho vĩnh viễn

    For $i = 1 To $aLines[0]
        Local $sLine = StringStripWS($aLines[$i], 8)
        If $sLine = "" Then ContinueLoop

        Local $aParts = StringSplit($sLine, "-")
        If $aParts[0] >= 2 Then
            Local $sSig = StringUpper($aParts[1]) & "-" & StringUpper($aParts[2])
            Local $sSection = $sPrefix & $sSig

            ; Đọc dữ liệu
            Local $iWins    = Number(IniRead($sFileStats, $sSection, "Wins", "0"))
            Local $iLosses  = Number(IniRead($sFileStats, $sSection, "Losses", "0"))
            Local $iMaxWin  = Number(IniRead($sFileStats, $sSection, "MaxWinStreak", "0"))
            Local $iMaxLoss = Number(IniRead($sFileStats, $sSection, "MaxLossStreak", "0"))

            Local $sWinRate = "0%"
            Local $iTotal = $iWins + $iLosses
            If $iTotal > 0 Then $sWinRate = Round(($iWins / $iTotal) * 100, 1) & "%"

            Local $iIndex = _GUICtrlListView_AddItem($g_hListView_Stats, $sSig)
            _GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $iWins, 1)
            _GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $iLosses, 2)
            _GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $sWinRate, 3)
            _GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $iMaxWin, 4)
            _GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $iMaxLoss, 5)
        EndIf
    Next
    _GUICtrlListView_EndUpdate($g_hListView_Stats)
EndFunc

; Hàm này giúp cộng dồn các chuỗi tần suất lại với nhau
; Ví dụ: Lệnh 1 có 2 lần bệt 5, Lệnh 2 có 1 lần bệt 5 -> Tổng là 3 lần bệt 5
Func _MergeFreqData(ByRef $aGlobalArr, $sDataStr)
    If $sDataStr = "" Then Return

    Local $aTemp = StringSplit($sDataStr, ",", 2) ; Cắt chuỗi thành mảng
    Local $iCount = UBound($aTemp)

    For $i = 0 To $iCount - 1
        If $i < 50 Then ; Đảm bảo không vượt quá kích thước mảng
            $aGlobalArr[$i] += Number($aTemp[$i])
        EndIf
    Next
EndFunc

Func _ShowStreakPopup_NonBlocking($sType)
    ; Đóng cái cũ nếu đang mở
    If $g_hStreakGUI <> 0 Then
        GUIDelete($g_hStreakGUI)
        $g_hStreakGUI = 0
    EndIf

    Local $sTitle, $sContent = "", $aData
    Local $iMaxStreak = 0

    If $sType = "WIN" Then
        $sTitle = "Chi Tiết Chuỗi THẮNG"
        $aData = $g_aWinFreq  ; Đây là mảng toàn cục vừa được _InstantDBLookup nạp đầy
        $iMaxStreak = $g_iMaxWinStreak
    Else
        $sTitle = "Chi Tiết Chuỗi THUA"
        $aData = $g_aLossFreq ; Đây là mảng toàn cục vừa được _InstantDBLookup nạp đầy
        $iMaxStreak = $g_iMaxLossStreak
    EndIf

    ; Tạo nội dung
    $sContent &= "Kỷ lục dài nhất: " & $iMaxStreak & " tay" & @CRLF & "--------------------------------" & @CRLF

    Local $bFound = False
    ; Duyệt từ 2 đến 49 (Bỏ qua chuỗi 1 vì nó nhiều quá, rác)
    For $i = 2 To 49
        If $aData[$i] > 0 Then
            $sContent &= "Chuỗi " & $i & " tay:  " & $aData[$i] & " lần" & @CRLF
            $bFound = True
        EndIf
    Next

    If Not $bFound Then
        $sContent &= "(Chưa có dữ liệu chuỗi bệt nào > 1)"
    EndIf

    ; Tạo cửa sổ con
    $g_hStreakGUI = GUICreate($sTitle, 300, 400, -1, -1, -1, 0x00000008) ; TopMost
    Local $hEdit = GUICtrlCreateEdit($sContent, 10, 10, 280, 380, 0x0800 + 0x0004) ; ReadOnly
    GUICtrlSetFont(-1, 10)
    GUISetState(@SW_SHOW, $g_hStreakGUI)
EndFunc
; ==============================================================================
; --- HÀM KIỂM TRA BLACKLIST (Dùng cho Logic Custom) ---
Func _CheckBlacklist($sHistoryToCheck)
    ; 1. Nếu chưa bật tính năng Blacklist thì cho qua luôn
    If GUICtrlRead($g_hCheckbox_Blacklist) <> $GUI_CHECKED Then Return True

    ; 2. KIỂM TRA: CÓ ĐANG THEO DÂY KHÔNG?
    Local $bIgnoreRunning = (GUICtrlRead($g_hCheckbox_Blacklist_IgnoreRunning) = $GUI_CHECKED)
    Local $bIsBusy = False

    ; - Trường hợp 1: Dùng Vốn Chung (Global) và đang ở lệnh > 0 (Đang gấp)
    If $g_iCapitalLevel > 0 Then $bIsBusy = True

    ; - Trường hợp 2: Dùng Vốn Riêng và ĐANG KHÓA DÒNG (Bất kể Level bao nhiêu)
    ; [SỬA LẠI] Chỉ cần Index > -1 là coi như đang bận (đang theo đuôi chuỗi)
    If $g_iLastActiveRuleIndex > -1 Then $bIsBusy = True

    ; - Trường hợp 3: Đang ở bước thứ 2 trở đi của chuỗi (Step > 0)
    If $g_iCustomSeqStep > 0 Then $bIsBusy = True

    ; => NẾU (Đang bận) VÀ (Có tích Bỏ qua) THÌ => CHO QUA LUÔN (Không soi nữa)
    If $bIsBusy And $bIgnoreRunning Then
        Return True
    EndIf

    ; 3. LOGIC SO SÁNH BLACKLIST
    Local $sBlacklistRaw = GUICtrlRead($g_hInput_Blacklist)
    If $sBlacklistRaw = "" Then Return True

    Local $aItems = StringSplit($sBlacklistRaw, ",")
    For $i = 1 To $aItems[0]
        Local $sBadItem = StringStripWS($aItems[$i], 8)
        If $sBadItem = "" Then ContinueLoop
        $sBadItem = StringReplace($sBadItem, "T", "")

        If StringRight($sHistoryToCheck, StringLen($sBadItem)) = $sBadItem Then
            _UpdateStatus("⛔ Dính Blacklist [" & $sBadItem & "] -> NGƯNG (Chờ cầu đẹp)...")
            Return False ; Chặn
        EndIf
    Next

    Return True ; Cho phép đánh
EndFunc

Func _HTTP_Request($sURL)
    Local $oHTTP = ObjCreate("WinHttp.WinHttpRequest.5.1")
    If Not IsObj($oHTTP) Then Return SetError(1, 0, "")

    $oHTTP.Open("GET", $sURL, False)
    ; THÊM DÒNG NÀY ĐỂ GIẢ LẬP TRÌNH DUYỆT CHROME (QUAN TRỌNG)
    $oHTTP.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    $oHTTP.SetRequestHeader("Cache-Control", "no-cache")
    $oHTTP.SetRequestHeader("Pragma", "no-cache")
    $oHTTP.Send()

    If $oHTTP.Status <> 200 Then Return SetError(2, 0, "")
    Return $oHTTP.ResponseText
EndFunc
; HÀM TỰ ĐỘNG MỞ TRÌNH DUYỆT & ĐĂNG NHẬP (WEBDRIVER)
; ==============================================================================
Func _RunAutoLoginFlow()
    _UpdateStatus("Đang kết nối Server để lấy danh sách tài khoản...")
    Local $sHWID = _GetHardwareID()

    Local $sFinalURL = $g_sAppsScriptBaseURL & "?action=getAccount&hwid=" & $sHWID
    Local $sResponseData = _HTTP_Request($sFinalURL)

    If @error Or $sResponseData = "" Or $sResponseData = "ERROR" Then
        _UpdateStatus("⛔ Lỗi: Không thể lấy dữ liệu từ Server!")
        GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
        GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
        GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
        _SetControlsState(True)
        Return False
    EndIf

    Local $oJson = Json_Decode($sResponseData)
    Local $sStatus = Json_Get($oJson, "[status]")

    If $sStatus = "ERROR" Then
        Local $sApiError = Json_Get($oJson, "[error]")
        _UpdateStatus("⛔ Lỗi từ Server: " & $sApiError)
        If $sApiError = "Chưa cấp User" Then
            MsgBox(48, "Yêu cầu cấp tài khoản", "Máy của bạn hiện chưa được gắn tài khoản game!" & @CRLF & "Vui lòng gửi mã HWID: [" & $sHWID & "] cho Admin (@nnduy2086).")
        Else
            MsgBox(48, "Thông báo hệ thống", "Lỗi: " & $sApiError)
        EndIf
        GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
        GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
        GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
        _SetControlsState(True)
        Return False
    EndIf

    Local $sUsersRaw = Json_Get($oJson, "[users]")
    Local $sPassesRaw = Json_Get($oJson, "[passes]")
    Local $aUsers = StringSplit($sUsersRaw, ",")
    Local $aPasses = StringSplit($sPassesRaw, ",")

    If $aUsers[0] = 0 Or $sUsersRaw = "" Then
        _UpdateStatus("⛔ Lỗi: Không tìm thấy tài khoản nào!")
        GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
        GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
        GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
        _SetControlsState(True)
        Return False
    EndIf

    Local $bForceSelect = True
    Local $iSelectedIndex = 1

    While 1
        If $bForceSelect And $aUsers[0] > 1 Then
            $iSelectedIndex = _ChooseAccountGUI($aUsers)
            If $iSelectedIndex = 0 Then ; Bấm HỦY
                _UpdateStatus("🛑 Đã hủy đăng nhập.")
                GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
                GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
                GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
                _SetControlsState(True)
                Return False
            EndIf
        EndIf

        $bForceSelect = False
        Local $sTargetUser = $aUsers[$iSelectedIndex]
        Local $sTargetPass = $aPasses[$iSelectedIndex]
        Local $bGoBackToSelect = False
        Local $bIsNewPassToSave = False ; ---> Cờ báo hiệu có pass mới cần test

        While 1
            If $sTargetPass = "EMPTY" Then
                $sTargetPass = _PasswordPromptGUI($sTargetUser)

                If $sTargetPass = "BACK" Then
                    $bGoBackToSelect = True
                    $bForceSelect = True
                    ExitLoop
                ElseIf $sTargetPass = "CANCEL" Then
                    _UpdateStatus("🛑 Đã hủy đăng nhập.")
                    GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
                    GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
                    GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
                    _SetControlsState(True)
                    Return False
                EndIf

                ; ---> ĐÃ XÓA LỆNH LƯU SERVER Ở ĐÂY. CHỈ LƯU VÀO RAM ĐỂ TEST <---
                $bIsNewPassToSave = True
                $aPasses[$iSelectedIndex] = $sTargetPass
            EndIf

            ; GỌI HÀM VÀO GAME
            GUICtrlSetData($g_hButton_Start, "ĐANG ĐĂNG NHẬP...")
            _UpdateStatus("✅ Đang vào game với tài khoản: " & $sTargetUser)
            Local $iLoginResult = _AutoLoginTK88_WebDriver($sTargetUser, $sTargetPass)

            ; XỬ LÝ KẾT QUẢ TRẢ VỀ
            If $iLoginResult = 1 Then
                ; THÀNH CÔNG -> BẮT ĐẦU LƯU PASS LÊN SERVER
                If $bIsNewPassToSave Then
                    _UpdateStatus("⏳ Đang đồng bộ mật khẩu lên máy chủ...")

                    ; 1. Mã hóa các ký tự nhạy cảm để không làm gãy link
                    Local $sSafePass = StringReplace($sTargetPass, "%", "%25")
                    $sSafePass = StringReplace($sSafePass, "&", "%26")
                    $sSafePass = StringReplace($sSafePass, "+", "%2B")
                    $sSafePass = StringReplace($sSafePass, "#", "%23")
                    $sSafePass = StringReplace($sSafePass, " ", "%20")
                    $sSafePass = StringReplace($sSafePass, "?", "%3F")
                    $sSafePass = StringReplace($sSafePass, "=", "%3D")

                    Local $sUpdateUrl = $g_sAppsScriptBaseURL & "?action=update_pass&hwid=" & $sHWID & "&user=" & $sTargetUser & "&pass=" & $sSafePass

                    ; 2. Dùng InetRead để đảm bảo gửi lên Google Sheet thành công 100%
                    InetRead($sUpdateUrl, 1)

                    _UpdateStatus("✅ Đã xác thực chuẩn & Lưu mật khẩu lên hệ thống!")
                EndIf

                $sTargetPass = ""
                Return True

            ElseIf $iLoginResult = 2 Then
                ; SAI MẬT KHẨU
                $bIsNewPassToSave = False ; Hủy cờ chờ lưu
                GUICtrlSetData($g_hButton_Start, "SAI MẬT KHẨU")
                Local $iRetry = MsgBox(48 + 4, "Lỗi Đăng Nhập", "Tài khoản hoặc mật khẩu không chính xác!" & @CRLF & "Bấm [YES] để NHẬP LẠI mật khẩu mới cho nick " & $sTargetUser & "." & @CRLF & "Bấm [NO] để QUAY LẠI bảng chọn Nick.")

                If $iRetry = 6 Then ; Bấm YES
                    $sTargetPass = "EMPTY"
                    $aPasses[$iSelectedIndex] = "EMPTY"
                    GUICtrlSetData($g_hButton_Start, "ĐANG ĐĂNG NHẬP...")
                    ContinueLoop
                Else ; Bấm NO
                    $bGoBackToSelect = True
                    $bForceSelect = True
                    GUICtrlSetData($g_hButton_Start, "ĐANG ĐĂNG NHẬP...")
                    ExitLoop
                EndIf

            ElseIf $iLoginResult = 3 Then
                ; TRÌNH DUYỆT BỊ TẮT ĐỘT NGỘT
                _UpdateStatus("🛑 Quá trình đăng nhập bị hủy do Trình duyệt bị đóng!")
                GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
                GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
                GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
                _SetControlsState(True)
                Return False
            EndIf
        WEnd

        If $bGoBackToSelect Then ContinueLoop
    WEnd
EndFunc
; Hàm tạo Popup chọn Tài Khoản (NẾU MÁY ĐÓ CÓ NHIỀU NICK)
Func _ChooseAccountGUI($aUsers)
    Local $hSelectGUI = GUICreate("Chọn Tài Khoản", 300, 150, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
    GUISetBkColor(0xF5F5F5)

    GUICtrlCreateLabel("Máy này có nhiều tài khoản được cấp." & @CRLF & "Vui lòng chọn nick để vào game:", 20, 15, 260, 35)
    GUICtrlSetFont(-1, 9, 600)

    Local $hCombo = GUICtrlCreateCombo("", 20, 55, 260, 25, $CBS_DROPDOWNLIST)
    Local $sComboData = ""
    For $i = 1 To $aUsers[0]
        $sComboData &= $aUsers[$i] & "|"
    Next
    GUICtrlSetData($hCombo, StringTrimRight($sComboData, 1), $aUsers[1])

    Local $hBtnCancel = GUICtrlCreateButton("Hủy (Đóng)", 20, 100, 90, 30)
    GUICtrlSetBkColor($hBtnCancel, 0xCCCCCC)

    Local $hBtnOK = GUICtrlCreateButton("Tiếp Tục ➡", 160, 100, 120, 30)
    GUICtrlSetBkColor($hBtnOK, 0x33CC33)
    GUICtrlSetFont($hBtnOK, 10, 700)

    GUISetState(@SW_SHOW, $hSelectGUI)

    Local $iResultIndex = 0
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE, $hBtnCancel
                $iResultIndex = 0 ; 0 nghĩa là người dùng bấm hủy
                ExitLoop
            Case $hBtnOK
                Local $sSelected = GUICtrlRead($hCombo)
                For $i = 1 To $aUsers[0]
                    If $aUsers[$i] == $sSelected Then
                        $iResultIndex = $i
                        ExitLoop 2
                    EndIf
                Next
        EndSwitch
    WEnd

    GUIDelete($hSelectGUI)
    Return $iResultIndex
EndFunc

Func _AutoLoginTK88_WebDriver($sUser, $sPass)
    $g_bIsLoginComplete = False
    _UpdateStatus("🚀 Đang khởi động Chrome Tàng hình...")

    ProcessClose("chromedriver.exe")
    Sleep(500)
    Run("chromedriver.exe --port=9515 --log-path=""" & @ScriptDir & "\chrome.log"" --silent", "", @SW_HIDE)
    Sleep(1000)

    _WD_Option('Port', 9515)
    Local $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"goog:chromeOptions": {"w3c": true, "args":["--app=https://www.tk88.com/", "--start-maximized", "--disable-infobars"]}}}}'
    $g_sWDSession = _WD_CreateSession($sDesiredCapabilities)

    _WD_Navigate($g_sWDSession, "https://www.tk88.com/")
    GUICtrlSetData($g_hButton_Start, "ĐANG ĐĂNG NHẬP...")
    Sleep(4000)

    ; TRẠM KIỂM TRA 1: Khách có tắt Chrome khi đang tải trang không?
    Local $sHandles = _WD_Window($g_sWDSession, "handles")
    If @error Or $sHandles = "[]" Or $sHandles = "" Then
        $g_sWDSession = ""
        ProcessClose("chromedriver.exe")
        Return 3 ; Trả mã 3 báo hiệu bị tắt ngang
    EndIf

    ; Dọn quảng cáo
    Local $sClearAds = "var popups = document.querySelectorAll('.close-btn, [class*=""close""], .el-dialog__headerbtn, img[src*=""close""]'); popups.forEach(p => p.click());"
    _WD_ExecuteScript($g_sWDSession, $sClearAds)
    Sleep(1000)

    ; Mở khóa Form & Điền User/Pass
    Local $sUnlockJS = "document.querySelectorAll('input').forEach(function(i) { i.disabled = false; i.readOnly = false; i.style.backgroundColor = ''; if(i.value === 'ĐÃ KHÓA BẢO MẬT') i.value = ''; });"
    _WD_ExecuteScript($g_sWDSession, $sUnlockJS)
    Sleep(500)

    Local $sUserXPath = "//input[contains(@placeholder, 'đăng nhập') or contains(@placeholder, 'Tên') or @name='account' or @type='text']"
    Local $sUserElement = _WD_FindElement($g_sWDSession, $_WD_LOCATOR_ByXPath, $sUserXPath)
    If $sUserElement <> "" Then
        _WD_ElementAction($g_sWDSession, $sUserElement, 'clear')
        Sleep(200)
        Local $aCharsUser = StringSplit($sUser, "")
        For $i = 1 To $aCharsUser[0]
            _WD_ElementAction($g_sWDSession, $sUserElement, 'value', $aCharsUser[$i])
            Sleep(Random(30, 60, 1))
        Next
        _WD_ExecuteScript($g_sWDSession, "var el = document.querySelector('input[type=""text""], input[name=""account""]'); if(el) el.dispatchEvent(new Event('input', {bubbles:true}));")
    EndIf
    Sleep(400)

    Local $sPassXPath = "//input[contains(@placeholder, 'mật khẩu') or contains(@placeholder, 'Mật') or @type='password']"
    Local $sPassElement = _WD_FindElement($g_sWDSession, $_WD_LOCATOR_ByXPath, $sPassXPath)
    If $sPassElement <> "" Then
        _WD_ElementAction($g_sWDSession, $sPassElement, 'clear')
        Sleep(200)
        Local $aCharsPass = StringSplit($sPass, "")
        For $i = 1 To $aCharsPass[0]
            _WD_ElementAction($g_sWDSession, $sPassElement, 'value', $aCharsPass[$i])
            Sleep(Random(30, 60, 1))
        Next
        _WD_ExecuteScript($g_sWDSession, "var el = document.querySelector('input[type=""password""]'); if(el) { el.dispatchEvent(new Event('input', {bubbles:true})); el.focus(); }")
    EndIf

    _UpdateStatus("Đã gõ xong, chuẩn bị Enter...")
    Sleep(800)
    Send("{ENTER}")
    Sleep(500)
    Local $sEnterJS = "var passField = document.querySelector('input[type=""password""]'); if(passField){ var ev = new KeyboardEvent('keydown', {bubbles: true, cancelable: true, keyCode: 13, key: 'Enter'}); passField.dispatchEvent(ev); }"
    _WD_ExecuteScript($g_sWDSession, $sEnterJS)

    ; Đợi Server TK88 phản hồi
    _UpdateStatus("Đang kiểm tra trạng thái đăng nhập...")
    Sleep(2500)

    ; TRẠM KIỂM TRA 2: Có tắt Chrome lúc vừa enter xong không?
    $sHandles = _WD_Window($g_sWDSession, "handles")
    If @error Or $sHandles = "[]" Or $sHandles = "" Then
        $g_sWDSession = ""
        ProcessClose("chromedriver.exe")
        Return 3
    EndIf

    Local $sCheckErrorJS = "var err = false; var txt = document.body.innerText.toLowerCase(); if(txt.includes('mật khẩu không') || txt.includes('sai mật khẩu') || txt.includes('không tồn tại') || txt.includes('thất bại')) { err = true; } return err ? 'FAIL' : 'OK';"
    Local $sResult = _WD_ExecuteScript($g_sWDSession, $sCheckErrorJS)

    If StringInStr($sResult, "FAIL") > 0 Then
        _UpdateStatus("⛔ Báo lỗi: Sai mật khẩu hoặc tài khoản!")
        _WD_DeleteSession($g_sWDSession)
        $g_sWDSession = ""
        ProcessClose("chromedriver.exe")
        Return 2 ; Trả mã 2 báo hiệu Sai Mật Khẩu
    EndIf

    ; =========================================================
    ; NẾU THÀNH CÔNG -> VÀO GAME
    ; =========================================================
    _UpdateStatus("✅ Đăng nhập thành công! Đã mở khóa nút Bắt Đầu.")
    _WD_ExecuteScript($g_sWDSession, "document.title = 'MAIN_BACCARAT_TOOL_9999';")
    $g_bIsLoginComplete = True

    Local $sAntiCheatJS = "setInterval(function() { var elements = document.querySelectorAll('a, button, [class*=\""logout\"" i], [class*=\""sign\"" i]'); elements.forEach(function(el) { var txt = el.innerText ? el.innerText.toLowerCase().trim() : ''; if(txt.includes('đăng xuất') || txt.includes('thoát') || txt.includes('đăng ký') || txt.includes('logout')) { el.style.display = 'none !important'; el.style.pointerEvents = 'none !important'; } }); }, 500);"
    _WD_ExecuteScript($g_sWDSession, $sAntiCheatJS)
    Sleep(1000)

    _UpdateStatus("⏳ Đang tải trang chủ và diệt quảng cáo...")
    Sleep(3000)
    Local $sKillAdsJS = "window.adKiller = setInterval(function() { var els = document.querySelectorAll('.close-btn, [class*=""close""], .el-dialog__wrapper, .v-modal, [class*=""overlay""]'); els.forEach(e => { try { e.click(); e.style.display = 'none'; e.style.opacity = '0'; } catch(err){} }); }, 200); setTimeout(function(){ clearInterval(window.adKiller); }, 15000);"
    _WD_ExecuteScript($g_sWDSession, $sKillAdsJS)
    Sleep(1000)
    ; =================================================================
    ; ---> CHÈN ĐOẠN F5 VÀ QUÉT VỐN VÀO ĐÂY (TRƯỚC KHI VÀO SẢNH) <---
    ; =================================================================
    _UpdateStatus("🔄 Đang tải lại trang chủ để lấy số dư chuẩn nhất...")
    _WD_Action($g_sWDSession, "refresh")
    Sleep(4000) ; Chờ load lại trang chủ

    _UpdateStatus("Đang đọc số dư thực tế...")
    Local $fSoDuMoi = _LaySoDuTrangChu()

    If $fSoDuMoi > 0 Then
        $g_fInitialCapital = $fSoDuMoi
        GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))

        $g_fTotalProfit = 0
        _UpdateProfitLabel()
        _UpdateBalanceLabel()

        _UpdateStatus("✅ Đã chốt VỐN CHUẨN: " & _FormatNumber($g_fInitialCapital) & " VND")
        Sleep(1500)
    Else
        _UpdateStatus("⚠️ Không quét được số dư, dùng tạm vốn cũ!")
        Sleep(1500)
    EndIf
    _UpdateStatus("🎰 Đang gọi lệnh vào sảnh PP...")
    Local $sInitHandles = _WD_Window($g_sWDSession, "handles")
    Local $aInitList = StringRegExp($sInitHandles, '"([^"]+)"', 3)
    Local $iInitCount = IsArray($aInitList) ? UBound($aInitList) : 1

    _WD_ExecuteScript($g_sWDSession, "if(typeof goGame === 'function') { goGame('101','101'); }")

    Local $sLobbyHandle = ""
    Local $hWaitPopup = TimerInit()
    While TimerDiff($hWaitPopup) < 5000
        ; TRẠM KIỂM TRA 3: Lỡ ngứa tay tắt luôn lúc đang load mở sảnh
        $sHandles = _WD_Window($g_sWDSession, "handles")
        If @error Or $sHandles = "[]" Or $sHandles = "" Then
            $g_sWDSession = ""
            ProcessClose("chromedriver.exe")
            Return 3
        EndIf

        Local $sCurrHandles = _WD_Window($g_sWDSession, "handles")
        Local $aCurrList = StringRegExp($sCurrHandles, '"([^"]+)"', 3)
        Local $iCurrCount = IsArray($aCurrList) ? UBound($aCurrList) : 1
        If $iCurrCount > $iInitCount Then
            $sLobbyHandle = $aCurrList[$iCurrCount - 1]
            ExitLoop
        EndIf
        Sleep(200)
    WEnd

    If $sLobbyHandle <> "" Then
        _WD_Window($g_sWDSession, "switch", '{"handle":"' & $sLobbyHandle & '"}')
        _WD_Window($g_sWDSession, "maximize")

        ; ---> DÒNG SỬA LỖI Ở ĐÂY: Ép đổi tên trang web để Tool nhận ra ngay lập tức
        _WD_ExecuteScript($g_sWDSession, "document.title = 'SECURE_BACCARAT_TOOL_9999';")

        _UpdateStatus("✅ Đã mở sảnh! Tự động kích hoạt công tắc...")
        Sleep(1000)
    Else
        _UpdateStatus("⚠️ Mạng chậm! Tool nhường lại cho chế độ rình rập tự bắt sảnh...")
    EndIf

    Return 1 ; Trả mã 1 báo hiệu Hoàn Mỹ
EndFunc
Func _UpdateStatus($sText)
    ; 1. Cập nhật tiêu đề cửa sổ (để theo dõi dưới Taskbar)
    Local $sTitleID = ($g_sMyTableID <> "") ? (" - " & $g_sMyTableID) : ""
    WinSetTitle($g_hGUI, "", "Tool-AIO_" & $g_sVersion & $g_sInstanceIdentifier & $sTitleID & " | " & $g_sCopyright & " | " & $sText)

    ; 2. Ghi file trạng thái cho Tool Tổng (Manager)
    If $g_sMyTableID <> "" Then
        Local $sStatusFile = @TempDir & "\status_" & $g_sMyTableID & ".ini"
        If Not FileExists($sStatusFile) Then
            Local $hFile = FileOpen($sStatusFile, 2 + 32)
            FileClose($hFile)
        EndIf
        IniWrite($sStatusFile, "Status", "CurrentAction", $sText)
    EndIf
EndFunc
Func _KeepWebLocked()
    ; Nếu chưa mở Chrome thì không làm gì cả
    If $g_sWDSession = "" Then Return

    ; [LUÔN CHẠY] 1. Chặn F5, chặn click Đăng xuất và ép ẩn Popup
    Local $sHardcoreLockJS = "" & _
        "if (!window.isLockedDown) {" & _
        "   window.isLockedDown = true;" & _
        "   /* CHẶN F5 VÀ CTRL+R */" & _
        "   document.addEventListener('keydown', function(e) {" & _
        "       if (e.key === 'F5' || e.keyCode === 116 || (e.ctrlKey && (e.key === 'r' || e.key === 'R'))) {" & _
        "           e.preventDefault(); e.stopPropagation();" & _
        "       }" & _
        "   }, true);" & _
        "" & _
        "   /* ĐÁNH CHẶN CÚ CLICK ĐĂNG XUẤT VÀ ĐĂNG KÝ */" & _
        "   document.addEventListener('click', function(e) {" & _
        "       var txt = (e.target.innerText || e.target.value || e.target.className || '').toLowerCase();" & _
        "       if (txt.includes('đăng xuất') || txt.includes('thoát') || txt.includes('logout') || txt.includes('đăng ký')) {" & _
        "           e.preventDefault(); e.stopPropagation(); return false;" & _
        "       }" & _
        "   }, true);" & _
        "}" & _
        "" & _
        "/* ÉP ẨN POPUP XÁC NHẬN LIÊN TỤC */" & _
        "var popups = document.querySelectorAll('.el-message-box__wrapper, .el-dialog__wrapper, div[role=\""dialog\""]');" & _
        "popups.forEach(function(p) { p.style.display = 'none !important'; p.style.opacity = '0'; });"

    ; [CÓ ĐIỀU KIỆN] 2. CHỈ KHÓA CHÍNH XÁC Ô ĐĂNG NHẬP (MỞ KHÓA CHO Ô RÚT TIỀN)
    If $g_bIsLoginComplete Then
        $sHardcoreLockJS &= "" & _
        "var inputs = document.querySelectorAll('input');" & _
        "inputs.forEach(function(i) {" & _
        "   var txt = (i.placeholder + ' ' + i.name + ' ' + i.id).toLowerCase();" & _
        "   /* Nhận diện thông minh: Chỉ tìm ô chứa từ khóa tài khoản/đăng nhập */" & _
        "   var isLoginField = txt.includes('account') || txt.includes('user') || txt.includes('đăng nhập') || txt.includes('tài khoản');" & _
        "   if (isLoginField && !i.disabled) {" & _
        "       i.disabled = true; i.readOnly = true; i.value = 'ĐÃ KHÓA BẢO MẬT';" & _
        "       i.style.backgroundColor = '#ffcccc';" & _
        "   }" & _
        "});"
    EndIf

    ; Bơm mã vào Chrome
    _WD_ExecuteScript($g_sWDSession, $sHardcoreLockJS)
EndFunc
Func _PasswordPromptGUI($sUsername)
    Local $hPassGUI = GUICreate("Nhập Mật Khẩu", 350, 160, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
    GUISetBkColor(0xF5F5F5)

    GUICtrlCreateLabel("Tài khoản: " & $sUsername, 20, 15, 310, 20)
    GUICtrlSetFont(-1, 10, 700)
    GUICtrlSetColor(-1, 0x0000FF)

    GUICtrlCreateLabel("Vui lòng nhập mật khẩu game:", 20, 45, 310, 20)
    Local $hInputPass = GUICtrlCreateInput("", 20, 70, 310, 25, BitOR($ES_PASSWORD, $ES_AUTOHSCROLL))
    GUICtrlSetFont(-1, 11, 700)

    Local $hBtnBack = GUICtrlCreateButton("⬅ Quay Lại", 20, 110, 100, 30)
    GUICtrlSetBkColor(-1, 0xFFB6C1)
    GUICtrlSetFont(-1, 9, 700)

    Local $hBtnOK = GUICtrlCreateButton("Xác Nhận ✔", 210, 110, 120, 30)
    GUICtrlSetBkColor(-1, 0x33CC33)
    GUICtrlSetFont(-1, 9, 700)

    GUISetState(@SW_SHOW, $hPassGUI)

    Local $sResult = "CANCEL"
    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                $sResult = "CANCEL"
                ExitLoop
            Case $hBtnBack
                $sResult = "BACK" ; Trả mã BACK để vòng lặp lùi về bảng chọn Nick
                ExitLoop
            Case $hBtnOK
                $sResult = GUICtrlRead($hInputPass)
                If $sResult <> "" Then
                    ExitLoop
                Else
                    MsgBox(48, "Lỗi", "Mật khẩu không được để trống!", 0, $hPassGUI)
                EndIf
        EndSwitch
    WEnd

    GUIDelete($hPassGUI)
    Return $sResult
EndFunc
Func _CheckForUpdates()
    ; Chốt chặn an toàn: Không chạy update khi đang mở file code (.au3) để lập trình
    If @Compiled = 0 Then Return

    _UpdateStatus("⏳ Đang kiểm tra phiên bản mới từ máy chủ...")

    ; 1. Tải nội dung version.txt (1 = ép tải mới, bỏ qua cache)
    Local $bRead = InetRead($g_sGithubVersionURL, 1)

    ; Nếu khách mất mạng, báo lỗi nhẹ rồi cho tool chạy tiếp bình thường
    If @error Then
        _UpdateStatus("⚠️ Bỏ qua kiểm tra cập nhật do lỗi mạng!")
        Return
    EndIf

    ; 2. Đọc bản online và làm sạch ký tự thừa
    Local $sOnlineVersion = StringStripWS(BinaryToString($bRead, 4), 8)

    ; 3. So sánh: Nếu có bản mới thì báo lên trạng thái và gọi hàm tải
    If $sOnlineVersion <> "" And Number($sOnlineVersion) > Number($g_sVersion) Then
        _UpdateStatus("🚀 Có bản mới v" & $sOnlineVersion & "! Hệ thống đang tự động tải...")
        _SilentAutoUpdate($g_sDownloadURL)
    Else
        _UpdateStatus("✅ Phiên bản v" & $g_sVersion & " đang là mới nhất!")
    EndIf
EndFunc

Func _SilentAutoUpdate($sDownloadLink)
    Local $sNewExePath = @ScriptDir & "\Update_Temp.exe"
    Local $sBatPath = @TempDir & "\updater.bat"
    Local $sCurrentExe = @ScriptFullPath ; Đường dẫn file tool đang chạy

    ; XÓA FILE RÁC TỪ CÁC LẦN TRƯỚC (CHỐNG KẸT)
    If FileExists($sNewExePath) Then FileDelete($sNewExePath)
    If FileExists($sBatPath) Then FileDelete($sBatPath)

    ; Bắt đầu tải file
    Local $iSize = InetGet($sDownloadLink, $sNewExePath, 1, 0)

    If $iSize == 0 Then
        _UpdateStatus("⛔ Lỗi: Tải bản cập nhật thất bại. Vui lòng thử lại sau!")
        Return False
    EndIf

    _UpdateStatus("✅ Tải bản mới thành công! Đang khởi động lại Tool...")
    Sleep(1500) ; Dừng 1.5 giây để khách hàng kịp nhìn thấy dòng chữ "Tải thành công"

    ; TẠO MÃ BATCH (.BAT) CHỐNG KẸT: Chờ 3 giây -> Xóa tool cũ -> Đổi tên tool mới -> Bật lại
    Local $sBatContent = "@echo off" & @CRLF & _
                         "ping 127.0.0.1 -n 3 > nul" & @CRLF & _
                         'del "' & $sCurrentExe & '"' & @CRLF & _
                         'move /y "' & $sNewExePath & '" "' & $sCurrentExe & '"' & @CRLF & _
                         'start "" "' & $sCurrentExe & '"' & @CRLF & _
                         'del "%~f0"'

    ; ÉP MỞ FILE CHẾ ĐỘ 2 (OVERWRITE) ĐỂ ĐẢM BẢO MÃ LUÔN SẠCH
    Local $hFile = FileOpen($sBatPath, 2)
    FileWrite($hFile, $sBatContent)
    FileClose($hFile)

    ; Chạy file .bat ngầm và lập tức thoát Tool cũ
    Run(@ComSpec & ' /c "' & $sBatPath & '"', @TempDir, @SW_HIDE)
    Exit
EndFunc
; =====================================================================
; HÀM BẮN THÔNG BÁO TELEGRAM
; =====================================================================
Func _SendTelegram($sMsg)
    Local $sToken = "ĐIỀN_TOKEN_BOT_CỦA_BẠN_VÀO_ĐÂY" ; <--- Ví dụ: 123456789:ABCDefgh...
    Local $sChatID = "ĐIỀN_CHAT_ID_CỦA_BẠN_VÀO_ĐÂY"  ; <--- Ví dụ: 987654321

    If $sToken = "ĐIỀN_TOKEN_BOT_CỦA_BẠN_VÀO_ĐÂY" Or $sToken = "" Then Return ; Nếu chưa cài thì bỏ qua

    ; Chuyển đổi nội dung tin nhắn để không bị lỗi Font khi gửi qua Web
    Local $sEncodedMsg = ""
    Local $aData = StringToASCIIArray($sMsg)
    For $i = 0 To UBound($aData) - 1
        $sEncodedMsg &= StringFormat("%%%02X", $aData[$i])
    Next

    Local $sUrl = "https://api.telegram.org/bot" & $sToken & "/sendMessage?chat_id=" & $sChatID & "&text=" & $sEncodedMsg
    InetRead($sUrl, 1) ; Bắn lệnh đi (Chạy ngầm không làm đơ tool)
EndFunc

; =====================================================================
; HÀM CỬA SỔ THÔNG BÁO TIÊU CHUẨN (SIÊU NHẸ - CHỐNG CRASH 100%)
; =====================================================================
Func _ShowTargetPopup_Overlay($sStatus, $sReason)
    ; 1. Lấy tọa độ Tool chính để canh bảng thông báo ra giữa màn hình
    Local $aMainPos = WinGetPos($g_hGUI)
    Local $iW = 400
    Local $iH = 200
    Local $iX = -1
    Local $iY = -1
    If Not @error Then
        $iX = $aMainPos[0] + ($aMainPos[2] - $iW) / 2
        $iY = $aMainPos[1] + ($aMainPos[3] - $iH) / 2
    EndIf

    ; 2. Chuẩn bị nội dung và màu sắc
    Local $sTitle = ($sStatus = "DONE_WIN") ? "🎉 CHÚC MỪNG: ĐẠT CHỐT LỜI" : "⚠️ CẢNH BÁO: CHẠM MỨC CẮT LỖ"
    Local $sMessage = ($sStatus = "DONE_WIN") ? "Tuyệt vời! Đã đạt mục tiêu Chốt Lời." & @CRLF & "Sếp muốn nghỉ hay đánh tiếp?" : "Báo động! Đã chạm mức Cắt Lỗ." & @CRLF & "Sếp muốn nghỉ hay đánh tiếp?"
    Local $iBgColor = ($sStatus = "DONE_WIN") ? 0xE6FEE6 : 0xFFE6E6 ; Nền xanh nhạt cho Thắng, đỏ nhạt cho Thua

    ; 3. Tạo Bảng Popup tiêu chuẩn (Không dùng Web/GIF)
    Local $hPopup = GUICreate($sTitle, $iW, $iH, $iX, $iY, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST, $g_hGUI)
    GUISetBkColor($iBgColor, $hPopup)

    ; 4. Thêm chữ thông báo
    Local $hLabel = GUICtrlCreateLabel($sMessage, 20, 30, 360, 60, $SS_CENTER)
    GUICtrlSetFont($hLabel, 12, 700)
    If $sStatus = "DONE_WIN" Then
        GUICtrlSetColor($hLabel, 0x008000) ; Chữ xanh lá
    Else
        GUICtrlSetColor($hLabel, 0xFF0000) ; Chữ đỏ
    EndIf

    ; 5. Tạo 2 nút bấm
    Local $hBtnContinue = GUICtrlCreateButton("TIẾP TỤC ĐÁNH", 40, 110, 140, 45)
    GUICtrlSetBkColor($hBtnContinue, 0x33CC33)
    GUICtrlSetFont($hBtnContinue, 11, 700)
    GUICtrlSetColor($hBtnContinue, 0xFFFFFF)

    Local $hBtnStop = GUICtrlCreateButton("CHỐT NGHỈ", 220, 110, 140, 45)
    GUICtrlSetBkColor($hBtnStop, 0xFF4141)
    GUICtrlSetFont($hBtnStop, 11, 700)
    GUICtrlSetColor($hBtnStop, 0xFFFFFF)

    GUISetState(@SW_SHOW, $hPopup)

    ; 6. Bắn Telegram NGAY LẬP TỨC
    If $sStatus = "DONE_WIN" Then
        _SendTelegram("🎉 Sếp ơi! AI Song Kiếm Hợp Bích đã húp đủ mục tiêu Chốt Lời. Đang đợi quyết định!")
    Else
        _SendTelegram("⚠️ Sếp ơi! AI Song Kiếm Hợp Bích chạm mức Cắt Lỗ. Vào kiểm tra sảnh ngay!")
    EndIf

    ; 7. Vòng lặp chờ lệnh (CÓ BẢO VỆ 5 PHÚT)
    Local $iChoice = 1 ; Mặc định là Dừng
    Local $hWaitTimer = TimerInit()

    While 1
        ; Dùng GUIGetMsg(1) để không xung đột với cửa sổ chính
        Local $aMsg = GUIGetMsg(1)
        Switch $aMsg[0]
            Case $GUI_EVENT_CLOSE
                ; Nếu khách bấm dấu X góc phải trên cùng
                If $aMsg[1] = $hPopup Then
                    $iChoice = 1
                    ExitLoop
                EndIf
            Case $hBtnStop
                $iChoice = 1
                ExitLoop
            Case $hBtnContinue
                $iChoice = 0
                ExitLoop
        EndSwitch

        ; Nếu quá 5 phút (300,000 ms) không ai bấm -> Tự động dừng
        If TimerDiff($hWaitTimer) > 300000 Then
            $iChoice = 1
            _SendTelegram("💤 Đã quá 5 phút không thấy phản hồi. Tool tự động CHỐT NGHỈ để bảo toàn vốn an toàn!")
            ExitLoop
        EndIf
        Sleep(50)
    WEnd

    ; 8. Xóa sổ cửa sổ thông báo an toàn
    GUIDelete($hPopup)

    Return $iChoice
EndFunc
Func _LaySoDuTrangChu()
    If $g_sWDSession = "" Then Return 0

    ; ĐOẠN JS NÀY SẼ ĐI TÌM CHỮ SỐ TRÊN WEB
    ; Sếp đang làm cho TK88, thường class của nó là .money hoặc .balance
    Local $sJS = "var el = document.querySelector('.money, .balance, [class*=""balance""], [class*=""money""]'); return el ? el.innerText : '0';"
    Local $sBal = _WD_ExecuteScript($g_sWDSession, $sJS)

    If @error Or $sBal = "" Then Return 0

    ; Lọc bỏ chữ VND, dấu phẩy, dấu chấm... chỉ giữ lại số thuần
    Local $sClean = StringRegExpReplace($sBal, "[^0-9]", "")
    Return Number($sClean)
EndFunc