#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ComboConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GuiComboBox.au3>
#include <Date.au3>
#include <Inet.au3>
#include <GDIPlus.au3>
#include <ScreenCapture.au3>
#include <File.au3>
#include <WinAPI.au3>
#include <AutoItConstants.au3>
#include <Array.au3>
#include <GuiListView.au3>
#include <Misc.au3>
#include "Json.au3"
#include "wd_core.au3"
#include "wd_helper.au3"

; --- ÉP CHUẨN MÔI TRƯỜNG ĐỂ CHỐNG LỆCH TỌA ĐỘ TRÊN MÁY KHÁCH ---
Opt("MouseCoordMode", 1)  ; 1 = Chuột dùng Tọa độ tuyệt đối toàn màn hình
Opt("PixelCoordMode", 1)  ; 1 = Quét màu dùng Tọa độ tuyệt đối toàn màn hình
#RequireAdmin

; ==================================================================================================
#Region 1. CẤU HÌNH HỆ THỐNG & KHAI BÁO BIẾN TOÀN CỤC
; ==================================================================================================
; --- THÔNG TIN BẢN QUYỀN & SERVER ---
Global Const $g_sAppsScriptBaseURL = "https://script.google.com/macros/s/AKfycbzYsojeFPtUJNwNKMMclP7zuj9TO6XYyq16O02Pi-ef87OP2kYz3TV3kT02XBw_GXuE/exec"
Global Const $g_sDevPassword       = "nmn12nntv21"
Global Const $g_sToolName          = "Tool_AIO"
Global Const $g_sVersion           = "6.3"
Global Const $g_sCopyright         = "Thuộc Bản Quyền Telegram @nnduy2086"
Global Const $g_sGithubVersionURL  = "https://raw.githubusercontent.com/nnduy86/BaccaratTool/main/version.txt"
Global Const $g_sDownloadURL       = "https://github.com/nnduy86/BaccaratTool/raw/main/Tool_AIO.exe"

Global $g_sHWID = ""
Global $g_sCustomerLogin = ""
Global $g_sCustomerRole = ""
Global $g_sActiveVIPs = ""
Global $g_sMachineStatus = ""
Global $g_sExpiryDate = ""
Global $g_bIsDevMode = False
Global $g_bConfigUnlocked = False
Global $g_fServerVolumeToday = 0
Global $g_fUnsyncedVolume = 0

; --- ĐƯỜNG DẪN CẤU HÌNH & THAM SỐ DÒNG LỆNH ---
Global $g_sMyTableID = ""
Global $g_bStartHidden = False
Global $g_sInstanceIdentifier = ""
Global $g_sIniPath = @ScriptDir & "\config.ini"

If $CmdLine[0] > 0 Then
	For $i = 1 To $CmdLine[0]
		If StringRegExp($CmdLine[$i], "^B\d+$") Then $g_sMyTableID = $CmdLine[$i]
		If StringInStr($CmdLine[$i], "/starthidden") Then $g_bStartHidden = True
	Next
EndIf

; --- BIẾN WEBDRIVER & CỬA SỔ GAME ---
Global $g_sSession = ""
Global $g_hTargetGameWin = 0
Global $g_sGameWindowClass = ""

; --- BIẾN GIAO DIỆN CHÍNH (GUI CONTROLS) ---
Global $g_hGUI, $g_hTab, $g_hTab1_Main, $g_hTabItemConfig
Global $g_hInput_InitialCapital, $g_hInput_InitialBet
Global $g_hLabel_CurrentBalance, $g_hLabel_Profit, $g_hLabel_TotalHands
Global $g_hLabel_TotalB_Val, $g_hLabel_TotalP_Val, $g_hLabel_TotalT_Val
Global $g_hLbl_B, $g_hLbl_P, $g_hLbl_T, $g_hLbl_TongVan
Global $g_hGroup_BPTTotals, $g_hGroup_ActivityLog, $g_hGroup_InfoTargets
Global $g_aLabel_History[120]
Global $g_hEdit_ActivityLog
Global $g_hButton_Start
Global $g_hCheckbox_PinTool

; --- BIẾN MỤC TIÊU CHỐT LÃI / CẮT LỖ / NGHỈ ---
Global $g_hLabel_NetDay, $g_hLabel_TotalVolume
Global $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter
Global $g_hCheckbox_DailyShield
Global $g_hInput_DailyTarget, $g_hInput_DailyTrailing, $g_hInput_DailyStopLoss
Global $g_hRadio_Action_Stop, $g_hRadio_Action_PauseMin, $g_hRadio_Action_PauseHand
Global $g_hInput_Action_PauseMin, $g_hInput_Action_PauseHand
Global $g_iTargetPauseEndTime = 0
Global $g_iTargetPauseDuration = 0
Global $g_iTargetPauseHands = 0

; --- BIẾN GIAO DIỆN & LOGIC BACCARAT ---
Global $g_hGroup_BettingMethod, $g_hCheckbox_SeparateQLV, $g_hCheckbox_ReverseLogic
Global $g_hLabel_TieuDeCongThuc, $g_hInput_CustomRules
Global $g_hGroup_QLV_Main, $g_hLbl_QLV1, $g_hInput_CustomQLV_Edit
Global $g_hLbl_QLV2, $g_hCombo_QLV_Presets, $g_hButton_SaveQLV, $g_hButton_DeleteQLV
Global $g_hCheckbox_BaccaratLaser
Global Const $g_sQLVMode = "Flexible"
Global $g_aCustomQLVTable[0][4] ; [Lệnh, Vốn, ThắngVề, ThuaVề]
Global $g_iCapitalLevel = 0
Global $g_iCustomSeqStep = 0
Global $g_aRuleLevels[100]
Global $g_iLastActiveRuleIndex = -1
Global $g_iGridCols_Max = 18
Global $g_iGridRows_Max = 6

; --- BIẾN GIAO DIỆN & LOGIC XÓC ĐĨA VIP (MA TRẬN ĐA TẦNG) ---
Global $g_hCheckbox_XocDiaVIP
Global $g_hGroup_XocDiaGrid, $g_hLbl_XD_Status, $g_hLbl_XD_Seq
Global $g_hLbl_XD_MaxRows, $g_hLbl_XD_Virtual, $g_hCheckbox_XD_AntiKick
Global $g_hLbl_XD_JumpLoss, $g_hInput_XD_JumpLoss
Global $g_hLbl_XD_JumpWin, $g_hInput_XD_JumpWin
Global $g_hRadio_XD_MultiRow, $g_hRadio_XD_SingleRow
Global $g_hRadio_XD_RealKeep, $g_hRadio_XD_DemoKeep
Global $g_hLbl_XD_StreakStats, $g_hBtn_XD_StreakDetail
Global $g_hInput_XD_Seq, $g_hInput_XD_MaxRows, $g_hInput_XD_Virtual, $g_hInput_XD_AntiKick
Global $g_hCheckbox_XD_AutoResetDebt, $g_hInput_XD_TargetProfit, $g_hCheckbox_XD_ShareDebt
Global $g_aXocDiaGrid[11][16]        ; Ma trận 10 Hàng x 15 Cột
Global $g_aXD_Rows[11], $g_aXD_Cols[16]
Global $g_aXocDia_Seq[11][16]        ; Bộ nhớ tiền cược độc lập cho 10 Hàng x 15 Cột
Global $g_aXD_MaxStepsPerRow[11]     ; Sức chịu đựng tối đa của từng hàng
Global $g_aTierStep[11] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
Global $g_iCurrentTier = 1
Global $g_iDynamicMaxSteps = 0
Global $g_iXD_NoBetCount = 0         ; Đếm số ván liên tiếp chưa cược tiền thật (Chống văng bàn)
Global $g_iXD_LossStreakInRow = 0    ; Đếm số tay thua thông liên tiếp tại hàng hiện tại để nhảy hàng
Global $g_iXD_WinStreakInRow = 0     ; Đếm số tay ăn thông liên tiếp tại hàng hiện tại để nhảy hàng
Global $g_fXD_CycleProfit = 0.0      ; Đếm lãi/lỗ chu kỳ hiện tại để xóa nợ
Global $g_fXD_AmortizePool = 0.0     ; Quỹ tích lũy lãi phụ để gọt nợ bậc cao
Global $g_fTableClickBet = 0.0       ; Tiền thật thực tế rải phỉnh xuống mặt bàn (Tách với tiền tính số liệu)
Global $g_aXD_RowLoss[11] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0] ; Theo dõi số tiền nợ thực tế của từng hàng
Global $g_bXD_SplitUsed = False                               ; Khóa chống lặp vòng tròn Chẻ đôi đỉnh nợ
Global $g_iXD_CurLossStreak_Cache = 0                         ; Chuỗi thua thông hiện tại để ghi bộ nhớ đệm
Global $g_sStreakCacheFile = @ScriptDir & "\streak_cache.ini" ; File lưu bộ nhớ đệm thua thông từ trước tới giờ

; --- BIẾN ĐỔI HẠN MỨC XÓC ĐĨA VIP (LIMIT) ---
Global $g_sCurrentLimitState = "10-500"
Global $g_hInput_LimitBtnX, $g_hInput_LimitBtnY, $g_hButton_GetLimitBtn
Global $g_hInput_Limit10_500X, $g_hInput_Limit10_500Y, $g_hButton_GetLimit10_500
Global $g_hInput_Limit20_50KX, $g_hInput_Limit20_50KY, $g_hButton_GetLimit20_50K
Global $g_hInput_LimitConfirmX, $g_hInput_LimitConfirmY, $g_hButton_GetLimitConfirm
Global $g_iLimitBtnX = 0, $g_iLimitBtnY = 0
Global $g_iLimit10_500X = 0, $g_iLimit10_500Y = 0
Global $g_iLimit20_50KX = 0, $g_iLimit20_50KY = 0
Global $g_iLimitConfirmX = 0, $g_iLimitConfirmY = 0

; --- BIẾN PHÒNG KỸ THUẬT (TỌA ĐỘ, MÀU SẮC, CHIP & SẢNH) ---
Global $g_hButton_Unlock
Global $g_iTechTabStart, $g_iTechTabEnd
Global $g_aConfigControls[0]
Global $g_hInput_ScanX, $g_hInput_ScanY, $g_hInput_ScanColor, $g_hLabel_ScanColorPreview, $g_hCheckbox_ToggleScan
Global $g_iTempX = 0, $g_iTempY = 0, $g_iTempColor = 0
Global $g_hInput_WindowClass
Global $g_hLbl_Coord_B, $g_hLbl_Coord_P, $g_hLbl_Coord_T, $g_hLbl_Color_B
Global $g_hInput_BankerX, $g_hInput_BankerY, $g_hButton_GetBankerPos
Global $g_hInput_PlayerX, $g_hInput_PlayerY, $g_hButton_GetPlayerPos
Global $g_hInput_TieX, $g_hInput_TieY, $g_hButton_GetTiePos
Global $g_hInput_BankerColor, $g_hButton_GetBankerColor
Global $g_hInput_PlayerColor, $g_hButton_GetPlayerColor
Global $g_hInput_TieColor, $g_hButton_GetTieColor
Global $g_hInput_ResultX1, $g_hInput_ResultY1, $g_hButton_GetResultTL
Global $g_hInput_ResultX2, $g_hInput_ResultY2, $g_hButton_GetResultBR
Global $g_hInput_Shade_Result, $g_hButton_TestColor_Result
Global $g_hInput_BetTimeX1, $g_hInput_BetTimeY1, $g_hButton_GetBetTimeTL
Global $g_hInput_BetTimeX2, $g_hInput_BetTimeY2, $g_hButton_GetBetTimeBR
Global $g_hInput_BetTimeColor, $g_hButton_GetBetTimeColor
Global $g_hInput_Shade_Timer, $g_hButton_TestColor_Timer
Global $g_aCheckbox_ChipEnabled[5], $g_aInput_ChipValue[5], $g_aInput_ChipX[5], $g_aInput_ChipY[5], $g_aButton_GetChipPos[5]
Global $g_hCombo_Profiles, $g_hCombo_Profiles_Main
Global $g_hButton_SaveNewProfile, $g_hButton_DeleteProfile
Global $g_hInput_ClickDelay_Main, $g_hInput_MouseSpeed
Global $g_hRadio_ClickMode_Control_Main, $g_hRadio_ClickMode_Mouse_Main

; --- BIẾN TRẠNG THÁI PHIÊN CHẠY & TÀI CHÍNH ---
Global $g_bIsRunning = False
Global $g_bManualStopped = False
Global $g_bIsFormatting = False
Global $g_bNeedAutoSave = False
Global $g_hAutoSaveTimer = 0
Global $g_hSessionTimer = 0
Global $g_sCurrentLoadedProfile = ""
Global $g_aBankerButtonPos[2], $g_aPlayerButtonPos[2], $g_aTieButtonPos[2]
Global $g_aResultArea[4], $g_aBetTimeIndicatorArea[4]
Global $g_iBankerColor, $g_iPlayerColor, $g_iTieColor, $g_iBetTimeIndicatorColor
Global $g_iShade_Result = 10, $g_iShade_Timer = 20
Global $g_aChipConfig[5][4] ; [IsEnabled, Value, X, Y]
Global $g_sClickMode = "Mouse", $g_iClickDelay = 150, $g_iMouseSpeed = 2
Global $g_fInitialCapital = 0.0, $g_fInitialBet = 0.0
Global $g_fTotalProfit = 0.0, $g_fCurrentBet = 0.0, $g_fLastBetAmount = 0.0
Global $g_fPeakProfit = 0.0, $g_bIsTrailingMode = False
Global $g_fTotalVolume = 0.0
Global $g_sLastBetOn = ""
Global $g_aDisplayHistory[0]
Global $g_iHistoryCutoffIndex = 0
Global $g_iTotalBanker = 0, $g_iTotalPlayer = 0, $g_iTotalTie = 0
Global $g_iCycleStep = 1
Global Const $HARD_LIMIT_RAM = 500
Global Const $g_iHighlightColor = 0xFFFFE0
Global Const $g_iLatestHighlightColor = 0xADD8E6
#EndRegion 1. CẤU HÌNH HỆ THỐNG & KHAI BÁO BIẾN TOÀN CỤC

_Main()

; ==================================================================================================
#Region 2. KHỞI ĐỘNG, BẢN QUYỀN, MÁY CHỦ & AUTO-UPDATE
; ==================================================================================================
Func _Main()
	OnAutoItExitRegister("_ExitCleanup")

	If _Singleton("ToolCasino_Lock_Main", 1) = 0 Then
		MsgBox(48, "Thông báo", "Tool đang được mở rồi!")
		Exit
	EndIf
	Sleep(500)
	_CheckForUpdates()

	$g_sHWID = _GetHardwareID()

	; --- ĐĂNG NHẬP TỰ ĐỘNG HOẶC HIỆN BẢNG ĐĂNG NHẬP ---
	Local $bIsLoggedIn = False
	Local $sSavedUser = IniRead($g_sIniPath, "Settings", "LastUsername", "")
	If $sSavedUser <> "" Then
		$g_sCustomerLogin = $sSavedUser
		$bIsLoggedIn = _CheckLoginOnline($g_sCustomerLogin, $g_sHWID)
	EndIf

	While Not $bIsLoggedIn
		Local $hLoginGUI = GUICreate("Đăng Nhập Tool - @nnduy2086", 400, 260, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
		GUISetBkColor(0xF0F4F8, $hLoginGUI)

		GUICtrlCreateLabel("MÃ MÁY (HWID) CỦA BẠN LÀ:", 20, 20, 360, 20)
		GUICtrlSetFont(-1, 10, 700, 0, "Segoe UI")
		GUICtrlSetColor(-1, 0x0000FF)

		Local $hInput_HWID = GUICtrlCreateInput($g_sHWID, 20, 45, 250, 28, BitOR($ES_READONLY, $ES_CENTER))
		GUICtrlSetFont(-1, 12, 700, 0, "Segoe UI")
		GUICtrlSetColor(-1, 0xFF0000)
		GUICtrlSetBkColor(-1, 0xFFFACD)

		Local $hBtn_Copy = GUICtrlCreateButton("📋 COPY", 280, 44, 100, 30)
		GUICtrlSetBkColor(-1, 0x33CC33)
		GUICtrlSetColor(-1, 0xFFFFFF)
		GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")

		GUICtrlCreateLabel("BƯỚC 1: Bấm COPY gửi mã máy cho Admin." & @CRLF & "BƯỚC 2: Chờ Admin kích hoạt." & @CRLF & "BƯỚC 3: Nhập Tên Đăng Nhập vào ô dưới đây:", 20, 90, 360, 55)
		GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

		$sSavedUser = IniRead($g_sIniPath, "Settings", "LastUsername", "")
		Local $hInput_User = GUICtrlCreateInput($sSavedUser, 20, 155, 360, 30, $ES_CENTER)
		GUICtrlSetFont(-1, 12, 700, 0, "Segoe UI")

		Local $hBtn_Login = GUICtrlCreateButton("ĐĂNG NHẬP", 90, 200, 220, 40)
		GUICtrlSetBkColor(-1, 0x0082FA)
		GUICtrlSetColor(-1, 0xFFFFFF)
		GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")

		GUISetState(@SW_SHOW, $hLoginGUI)

		Local $sInputUser = ""
		Local $bExit = False

		While 1
			Switch GUIGetMsg()
				Case $GUI_EVENT_CLOSE
					$bExit = True
					ExitLoop
				Case $hBtn_Copy
					ClipPut($g_sHWID)
					MsgBox(64 + 262144, "Thành Công", "Đã copy Mã Máy: " & $g_sHWID & @CRLF & @CRLF & "Hãy ra Zalo/Telegram bấm Dán (Ctrl + V) để gửi cho Admin nhé!", 0, $hLoginGUI)
				Case $hBtn_Login
					$sInputUser = StringStripWS(GUICtrlRead($hInput_User), 3)
					If $sInputUser <> "" Then
						IniWrite($g_sIniPath, "Settings", "LastUsername", $sInputUser)
						ExitLoop
					Else
						MsgBox(48 + 262144, "Lỗi", "Vui lòng nhập Tên Đăng Nhập Admin đã cấp!", 0, $hLoginGUI)
					EndIf
			EndSwitch
		WEnd

		GUIDelete($hLoginGUI)
		If $bExit Then Exit

		$g_sCustomerLogin = $sInputUser
		$bIsLoggedIn = _CheckLoginOnline($g_sCustomerLogin, $g_sHWID)
	WEnd

	HotKeySet("{F4}", "_DebugGrid")

	Local $aLicenseInfo = _CheckLicenseOnline($g_sHWID)
	$g_sMachineStatus = $aLicenseInfo[0]

	IniWrite(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), $g_fServerVolumeToday)

	If $g_sMachineStatus == "OK" Then
		$g_sExpiryDate = "Vĩnh viễn"
	Else
		$g_sExpiryDate = "Chưa kích hoạt"
	EndIf

	_CreateGUI($g_sExpiryDate)
	_ApplyCustomerFeatures()
	_MainLoop()
EndFunc   ;==>_Main

Func _GetHardwareID()
	Return DriveGetSerial("C:")
EndFunc   ;==>_GetHardwareID

Func _CheckLoginOnline($sUsername, $sHWID)
	Local $sUrl = $g_sAppsScriptBaseURL & "?action=check_login&username=" & $sUsername & "&hwid=" & $sHWID & "&nocache=" & TimerInit()
	Local $sData = BinaryToString(InetRead($sUrl, 3), 4)

	Local $oJson = Json_Decode($sData)
	Local $sStatus = Json_Get($oJson, "[status]")

	If $sStatus == "ERROR" Then
		Local $sMsg = Json_Get($oJson, "[msg]")
		MsgBox(16, "Lỗi đăng nhập", $sMsg & @CRLF & @CRLF & "Mã máy của bạn: " & $sHWID & @CRLF & "Vui lòng copy mã này gửi cho Admin để được cấp quyền!")
		Return False
	EndIf

	$g_sCustomerRole = StringStripWS(Json_Get($oJson, "[role]"), 3)
	If $g_sCustomerRole == "" Then
		MsgBox(16, "Lỗi hệ thống", "Tài khoản này chưa được điền quyền ở cột NOTE trên Google Sheets!")
		Return False
	EndIf

	Return True
EndFunc   ;==>_CheckLoginOnline

Func _CheckLicenseOnline($sHWID)
	Local $sUrl = $g_sAppsScriptBaseURL & "?action=check_init&hwid=" & $sHWID & "&nocache=" & TimerInit() & Random(1000, 9999, 1)
	Local $sData = BinaryToString(InetRead($sUrl, 3), 4)

	Local $oJson = Json_Decode($sData)
	Local $sStatus = Json_Get($oJson, "[status]")

	If $sStatus == "ERROR" Then
		Local $sMsg = Json_Get($oJson, "[msg]")
		Local $aErr[3] = [$sStatus, $sMsg, 0]
		Return $aErr
	EndIf

	If $sStatus == "DEBT" Then
		Local $iDebtAmount = Number(Json_Get($oJson, "[debt_amount]"))
		Local $aDebt[3] = [$sStatus, $iDebtAmount, 0]
		Return $aDebt
	EndIf

	Local $sExpiry = Json_Get($oJson, "[expiry]")
	$g_sActiveVIPs = Json_Get($oJson, "[active_vips]")
	$g_fServerVolumeToday = Number(Json_Get($oJson, "[vol_today]"))

	Local $aResult[3] = [$sStatus, $sExpiry, 0]
	Return $aResult
EndFunc   ;==>_CheckLicenseOnline

Func _ApplyCustomerFeatures()
	If StringUpper($g_sCustomerRole) == "ADMIN" Then
		_ToggleTechRoom($GUI_SHOW)
		_ToggleConfigControlsState(True)
		GUICtrlSetData($g_hButton_Unlock, "🔓 KHÓA LẠI")
		GUICtrlSetBkColor($g_hButton_Unlock, 0x33CC33)
		Return
	EndIf

	Local $sUsername = $g_sCustomerLogin
	Local $aAllSections = IniReadSectionNames($g_sIniPath)
	Local $sUserProfiles = "|"
	Local $sFirstProfileToLoad = ""
	Local $iProfileCount = 0

	If Not @error Then
		For $i = 1 To $aAllSections[0]
			If StringInStr($aAllSections[$i], "Profile_" & $sUsername & "_") = 1 Then
				Local $sCleanName = StringReplace($aAllSections[$i], "Profile_", "")
				$sUserProfiles &= $sCleanName & "|"
				If $sFirstProfileToLoad == "" Then $sFirstProfileToLoad = $sCleanName
				$iProfileCount += 1
			EndIf
		Next
	EndIf

	If $iProfileCount > 0 Then
		GUICtrlSetData($g_hCombo_Profiles_Main, $sUserProfiles, $sFirstProfileToLoad)
		GUICtrlSetState($g_hCombo_Profiles_Main, $GUI_ENABLE)
		_LoadSelectedProfile($sFirstProfileToLoad)
		_ExecuteHideShow()
		_ToggleGameModeUI()
		_UpdateStatus("✅ Đã tải thành công " & $iProfileCount & " cấu hình dành riêng cho: " & $sUsername)
	Else
		GUICtrlSetState($g_hCombo_Profiles_Main, $GUI_DISABLE)
		MsgBox(48, "Thông báo", "Tài khoản của bạn hiện chưa có Cấu hình/Sảnh game nào." & @CRLF & "Vui lòng liên hệ Admin để được cấp phát!")
		Exit
	EndIf

	_ToggleTechRoom($GUI_HIDE)
	_ToggleConfigControlsState(False)
	GUICtrlSetData($g_hButton_Unlock, "🔐 MỞ KHÓA")
	GUICtrlSetBkColor($g_hButton_Unlock, 0xFF4141)
EndFunc   ;==>_ApplyCustomerFeatures

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
EndFunc   ;==>_SendActivityLog

Func _CheckForUpdates()
	If @Compiled = 0 Then Return
	Local $bRead = InetRead($g_sGithubVersionURL, 1)
	If @error Then Return
	Local $sOnlineVersion = StringStripWS(BinaryToString($bRead, 4), 8)
	If $sOnlineVersion <> "" And Number($sOnlineVersion) > Number($g_sVersion) Then
		_UpdateStatus("🚀 Có bản mới v" & $sOnlineVersion & "! Hệ thống đang tự động tải...")
		_SilentAutoUpdate($g_sDownloadURL)
	EndIf
EndFunc   ;==>_CheckForUpdates

Func _SilentAutoUpdate($sDownloadLink)
	Local $sNewExePath = @ScriptDir & "\Update_Temp.exe"
	Local $sBatPath = @TempDir & "\updater.bat"
	Local $sCurrentExe = @ScriptFullPath

	If FileExists($sNewExePath) Then FileDelete($sNewExePath)
	If FileExists($sBatPath) Then FileDelete($sBatPath)

	Local $iSize = InetGet($sDownloadLink, $sNewExePath, 1, 0)
	If $iSize == 0 Then
		_UpdateStatus("⛔ Lỗi: Tải bản cập nhật thất bại. Vui lòng thử lại sau!")
		Return False
	EndIf

	_UpdateStatus("✅ Tải bản mới thành công! Đang khởi động lại Tool...")
	Sleep(1500)

	Local $sBatContent = "@echo off" & @CRLF & _
			"ping 127.0.0.1 -n 3 > nul" & @CRLF & _
			'del "' & $sCurrentExe & '"' & @CRLF & _
			'move /y "' & $sNewExePath & '" "' & $sCurrentExe & '"' & @CRLF & _
			'start "" "' & $sCurrentExe & '"' & @CRLF & _
			'del "%~f0"'

	Local $hFile = FileOpen($sBatPath, 2)
	FileWrite($hFile, $sBatContent)
	FileClose($hFile)

	Run(@ComSpec & ' /c "' & $sBatPath & '"', @TempDir, @SW_HIDE)
	Exit
EndFunc   ;==>_SilentAutoUpdate
#EndRegion 2. KHỞI ĐỘNG, BẢN QUYỀN, MÁY CHỦ & AUTO-UPDATE

; ==================================================================================================
#Region 3. CHROME WEBDRIVER & TỰ ĐỘNG BẮT POPUP SẢNH GAME
; ==================================================================================================
Func _LaunchChrome_WebDriver()
	_UpdateStatus("🚀 Đang mở Chrome. Sếp chuẩn bị đăng nhập nhé...")
	$_WD_DEBUG = $_WD_DEBUG_None

	_WD_Option('Driver', @ScriptDir & '\chromedriver.exe')
	_WD_Option('Port', 9515)
	_WD_Option('DriverParams', '--port=9515 --silent')
	_WD_Option('Console', 'Hide')

	Local $sDataDir = @ScriptDir & "\ChromeData"
	If Not FileExists($sDataDir) Then DirCreate($sDataDir)
	$sDataDir = StringReplace($sDataDir, "\", "/")

	_WD_Startup()
	If @error Then Return 0

	WinSetState("[TITLE:" & @ScriptDir & "\chromedriver.exe]", "", @SW_HIDE)
	WinSetState("[TITLE:chromedriver.exe]", "", @SW_HIDE)

	Local $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": {"excludeSwitches": ["enable-automation"], "useAutomationExtension": false, "args": ["--user-data-dir=' & $sDataDir & '"]}}}}'

	$g_sSession = _WD_CreateSession($sDesiredCapabilities)
	If @error Or $g_sSession == "" Then
		_WD_Shutdown()
		Return 0
	EndIf

	_WD_Navigate($g_sSession, "https://8k3071q.top")
	_WD_Window($g_sSession, "maximize")
	Sleep(1000)

	_UpdateStatus("Đang cố gắng tìm và đóng khung quảng cáo bằng XPath...")
	Local $sClickJS = "var btn = document.evaluate(""//span[text()='Đóng' or @translate='Common_Closed']"", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;" & _
			"if (btn) { btn.click(); }"

	For $i = 1 To 3
		_WD_ExecuteScript($g_sSession, $sClickJS)
		Sleep(1500)
	Next

	Return 1
EndFunc   ;==>_LaunchChrome_WebDriver

Func _AutoCatchPopup_And_Maximize()
	_UpdateStatus("⏳ [HỆ THỐNG] Đang rình Popup. Sếp tự tắt quảng cáo và bấm mở sảnh nhé...")

	While $g_bIsRunning
		_ProcessGUIMessages()

		Local $aChromeList = WinList("[CLASS:Chrome_WidgetWin_1]")
		Local $hPopup = 0

		If $aChromeList[0][0] >= 2 Then
			For $i = 1 To $aChromeList[0][0]
				Local $hWnd = $aChromeList[$i][1]
				If BitAND(WinGetState($hWnd), 2) Then
					Local $aPos = WinGetPos($hWnd)
					If IsArray($aPos) And $aPos[2] > 300 And $aPos[2] < @DesktopWidth - 50 Then
						$hPopup = $hWnd
						ExitLoop
					EndIf
				EndIf
			Next
		EndIf

		If $hPopup <> 0 Then
			_UpdateStatus("⚡ Đã tóm được Popup Sảnh! Đang phóng to...")
			WinActivate($hPopup)
			Sleep(200)
			WinSetState($hPopup, "", @SW_MAXIMIZE)
			Sleep(800)

			$g_hTargetGameWin = $hPopup
			Return True
		EndIf

		Sleep(500)
	WEnd

	Return False
EndFunc   ;==>_AutoCatchPopup_And_Maximize

Func _GetRealGameWindow($sClass)
	Local $iBankerX = Number(GUICtrlRead($g_hInput_BankerX))
	Local $iBankerY = Number(GUICtrlRead($g_hInput_BankerY))

	If $iBankerX > 0 And $iBankerY > 0 Then
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", $iBankerX)
		DllStructSetData($tPoint, "Y", $iBankerY)
		Local $hWndPoint = _WinAPI_WindowFromPoint($tPoint)
		If $hWndPoint <> 0 Then
			Local $hTopLevel = _WinAPI_GetAncestor($hWndPoint, 2)
			If $hTopLevel <> 0 And BitAND(WinGetState($hTopLevel), 2) Then
				Return $hTopLevel
			EndIf
		EndIf
	EndIf

	Local $aList = WinList("[CLASS:" & $sClass & "]")
	Local $hWndReal = 0
	Local $iMaxArea = 0

	For $i = 1 To $aList[0][0]
		If $aList[$i][0] <> "" And BitAND(WinGetState($aList[$i][1]), 2) Then
			Local $aPos = WinGetPos($aList[$i][1])
			If IsArray($aPos) And $aPos[2] > 300 And $aPos[3] > 300 Then
				Local $iArea = $aPos[2] * $aPos[3]
				If $iArea > $iMaxArea Then
					$iMaxArea = $iArea
					$hWndReal = $aList[$i][1]
				EndIf
			EndIf
		EndIf
	Next

	If $hWndReal <> 0 Then Return $hWndReal
	Return WinGetHandle("[CLASS:" & $sClass & "]")
EndFunc   ;==>_GetRealGameWindow

Func _ExitCleanup()
	If $g_sSession <> "" Then
		_WD_DeleteSession($g_sSession)
		_WD_Shutdown()
	EndIf
	ProcessClose("chromedriver.exe")
EndFunc   ;==>_ExitCleanup
#EndRegion 3. CHROME WEBDRIVER & TỰ ĐỘNG BẮT POPUP SẢNH GAME

; ==================================================================================================
#Region 4. THIẾT KẾ GIAO DIỆN (GUI) & CHUYỂN ĐỔI CHẾ ĐỘ BACCARAT / XÓC ĐĨA
; ==================================================================================================
Func _CreateGUI($sExpiryDate)
	#forceref $sExpiryDate
	Local $iWinX = IniRead($g_sIniPath, "Settings", "WinX", -1)
	Local $iWinY = IniRead($g_sIniPath, "Settings", "WinY", -1)

	If $iWinX < -1000 Or $iWinY < -1000 Then
		$iWinX = -1
		$iWinY = -1
	EndIf

	$g_hGUI = GUICreate("Tool_AIO_" & $g_sVersion & $g_sInstanceIdentifier & " | " & $g_sCopyright, 990, 545, $iWinX, $iWinY, -1, $WS_EX_CLIENTEDGE)
	GUISetBkColor(0xF0F4F8, $g_hGUI)
	GUISetFont(9, 400, 0, "Segoe UI")
	GUIRegisterMsg($WM_COMMAND, "WM_COMMAND_Handler")

	$g_hTab = GUICtrlCreateTab(5, 5, 980, 535)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 10, 700)

	$g_hTab1_Main = GUICtrlCreateTabItem("Giao Diện Chính")
	_CreateTab_MainTool()

	$g_hTabItemConfig = GUICtrlCreateTabItem("Phòng Kỹ Thuật")
	_CreateTab_ConfigHelper()
	GUICtrlCreateTabItem("")

	_LoadSettings()
	_SetControlsState(True)
	_ToggleConfigControlsState(False)

	If $g_bStartHidden Then
		GUISetState(@SW_HIDE, $g_hGUI)
	Else
		GUISetState(@SW_SHOW, $g_hGUI)
	EndIf

	If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
		WinSetOnTop($g_hGUI, "", 1)
	EndIf
EndFunc   ;==>_CreateGUI

Func _CreateTab_MainTool()
	_CreateGroup_Settings()
	_CreateGroup_BettingMethod()
	_CreateGroup_QLV_On_Main()
	_CreateGroup_XocDia_Grid()
	_CreateGroup_BPT_Totals()
	_CreateGroup_HistoryDisplay()
	_CreateGroup_HistoryLog()
	_CreateGroup_InfoAndTargets()
	_CreateGroup_UserConfig_Main()
EndFunc   ;==>_CreateTab_MainTool

Func _CreateStyledGroup($sTitle, $iX, $iY, $iW, $iH)
	Local $hGroup = GUICtrlCreateGroup($sTitle, $iX, $iY, $iW, $iH, $WS_GROUP, $WS_EX_CLIENTEDGE)
	GUICtrlSetFont($hGroup, 10, 700)
	GUICtrlSetColor($hGroup, 0x0000FF)
	GUICtrlSetBkColor($hGroup, 0xF5F5F5)
	Return $hGroup
EndFunc   ;==>_CreateStyledGroup

Func _CreateGroup_Settings()
	_CreateStyledGroup("Vốn & Cài Đặt Cược", 10, 35, 350, 85)
	Local $y = 55
	GUICtrlCreateLabel("Vốn ban đầu:", 20, $y, 100, 20)
	$g_hInput_InitialCapital = GUICtrlCreateInput("0", 130, $y - 3, 210, 22)
	GUICtrlSetBkColor(-1, 0xE0FFFF)
	$y += 28
	GUICtrlCreateLabel("Giá trị cược:", 20, $y, 100, 20)
	$g_hInput_InitialBet = GUICtrlCreateInput("0", 130, $y - 3, 210, 22)
	GUICtrlSetBkColor(-1, 0xE0FFFF)
EndFunc   ;==>_CreateGroup_Settings

Func _CreateGroup_BettingMethod()
	$g_hGroup_BettingMethod = GUICtrlCreateGroup("PHƯƠNG PHÁP CƯỢC (BACCARAT)", 10, 125, 350, 220)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0x00008B)

	Local $y = 145
	$g_hCheckbox_SeparateQLV = GUICtrlCreateCheckbox("QLV Riêng", 20, $y, 90, 20)
	$g_hCheckbox_ReverseLogic = GUICtrlCreateCheckbox("Bám Chuỗi", 130, $y, 90, 20)

	$y += 22
	$g_hLabel_TieuDeCongThuc = GUICtrlCreateLabel("📝 NHẬP CÔNG THỨC CƯỢC:", 20, $y, 260, 20)
	GUICtrlSetColor(-1, 0x0000FF)

	$y += 20
	$g_hInput_CustomRules = GUICtrlCreateEdit("", 20, $y, 320, 148, BitOR(0x00200000, 0x00000040, 0x00001000))
	GUICtrlSetBkColor(-1, 0xFFFACD)
EndFunc   ;==>_CreateGroup_BettingMethod

Func _CreateGroup_QLV_On_Main()
	$g_hGroup_QLV_Main = _CreateStyledGroup("Cấu Hình Quản Lý Vốn (Baccarat)", 10, 350, 350, 175)
	Local $y_inner = 370
	$g_hLbl_QLV1 = GUICtrlCreateLabel("Lệnh-Vốn-Thắng-Thua", 20, $y_inner, 150, 15)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0x800080)

	$g_hInput_CustomQLV_Edit = GUICtrlCreateEdit("", 20, $y_inner + 18, 150, 128, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL, $ES_NOHIDESEL))
	GUICtrlSetBkColor(-1, 0xF0FFF0)

	$g_hLbl_QLV2 = GUICtrlCreateLabel("Chọn QLV mẫu:", 180, $y_inner, 100, 20)
	$g_hCombo_QLV_Presets = GUICtrlCreateCombo("", 180, $y_inner + 18, 155, 25, $CBS_DROPDOWNLIST)
	$g_hButton_SaveQLV = GUICtrlCreateButton("Lưu", 180, $y_inner + 50, 70, 25)
	GUICtrlSetBkColor(-1, 0x90EE90)
	$g_hButton_DeleteQLV = GUICtrlCreateButton("Xóa", 260, $y_inner + 50, 75, 25)
	GUICtrlSetBkColor(-1, 0xFFB6C1)
EndFunc   ;==>_CreateGroup_QLV_On_Main

Func _CreateGroup_XocDia_Grid()
	$g_hGroup_XocDiaGrid = GUICtrlCreateGroup("📊 GẤP THẾP ĐA TẦNG RIÊNG BIỆT (XÓC ĐĨA)", 10, 125, 350, 405)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0xFF0000)

	Local $yOffset = 141
	Local $xOffset = 14
	Local $wCell = 17
	Local $hCell = 15
	Local $spacing = 19
	Local $startX = $xOffset + 24

	For $c = 1 To 15
		$g_aXD_Cols[$c] = GUICtrlCreateLabel("B" & $c, $startX + ($c - 1) * $spacing, $yOffset, $wCell + 2, 13, $SS_CENTER)
		GUICtrlSetFont(-1, 7, 700)
	Next
	$yOffset += 14

	For $r = 1 To 10
		$g_aXD_Rows[$r] = GUICtrlCreateLabel("H" & $r, $xOffset, $yOffset + ($r - 1) * ($hCell + 3) + 1, 22, 15)
		GUICtrlSetFont(-1, 8, 800)
		GUICtrlSetColor(-1, 0x0000FF)

		For $c = 1 To 15
			$g_aXocDiaGrid[$r][$c] = GUICtrlCreateLabel("-", $startX + ($c - 1) * $spacing, $yOffset + ($r - 1) * ($hCell + 3), $wCell + 2, $hCell, BitOR($SS_CENTER, 0x0200))
			GUICtrlSetFont(-1, 7, 800)
			GUICtrlSetBkColor(-1, 0xE0E0E0)
		Next
	Next

	$yOffset += 10 * ($hCell + 3) + 3

	; DÒNG 1: Hệ số & Số Hàng
	$g_hLbl_XD_Seq = GUICtrlCreateLabel("Hệ số (x Vốn):", $xOffset, $yOffset + 2, 82, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	$g_hInput_XD_Seq = GUICtrlCreateInput("1, 2, 4, 8, 17, 35, 73, 152, 316, 655", $xOffset + 82, $yOffset, 155, 20)
	GUICtrlSetBkColor(-1, 0xFFFACD)

	$g_hLbl_XD_MaxRows = GUICtrlCreateLabel("Hàng:", $xOffset + 245, $yOffset + 2, 35, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	$g_hInput_XD_MaxRows = GUICtrlCreateInput("5", $xOffset + 282, $yOffset, 48, 20)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	; DÒNG 2: Tự xóa nợ khi đạt lãi vòng & Công tắc San sẻ nợ
	$yOffset += 21
	$g_hCheckbox_XD_AutoResetDebt = GUICtrlCreateCheckbox("Xóa nợ Lãi >=", $xOffset, $yOffset, 105, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0x0000FF)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetTip(-1, "Tự động xóa sạch nợ toàn bảng về B1 khi lãi chu kỳ đạt mốc")

	$g_hInput_XD_TargetProfit = GUICtrlCreateInput("20.000", $xOffset + 108, $yOffset - 1, 118, 20)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	$g_hCheckbox_XD_ShareDebt = GUICtrlCreateCheckbox("San sẻ nợ", $xOffset + 235, $yOffset, 95, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0xFF00FF)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetTip(-1, "Bật/Tắt chế độ Chẻ đôi đỉnh nợ (B5->B4) và Gọt nợ bằng quỹ lãi phụ giữa các hàng")

	; DÒNG 3: Nháp từng hàng & Công tắc Bật/Tắt Giữ bàn chống văng
	$yOffset += 21
	$g_hLbl_XD_Virtual = GUICtrlCreateLabel("Nháp (H1..):", $xOffset, $yOffset + 2, 72, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0x008000)
	$g_hInput_XD_Virtual = GUICtrlCreateInput("1, 1, 1, 1, 1", $xOffset + 72, $yOffset, 100, 20)
	GUICtrlSetBkColor(-1, 0xFFFACD)
	GUICtrlSetTip(-1, "Số tay nháp (0đ) đầu mỗi hàng. Chuẩn: 1, 1, 1, 1, 1")

	$g_hCheckbox_XD_AntiKick = GUICtrlCreateCheckbox("Giữ bàn (ván):", $xOffset + 180, $yOffset, 105, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0xFF0000)
	GUICtrlSetState(-1, $GUI_CHECKED)
	GUICtrlSetTip(-1, "Tích chọn để bật tự động ném 1 lệnh nhỏ nhất chống văng khỏi bàn")
	$g_hInput_XD_AntiKick = GUICtrlCreateInput("4", $xOffset + 288, $yOffset - 1, 42, 20)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	; DÒNG 4: Thua thông nhảy hàng & Ăn thông nhảy hàng (Đối xứng)
	$yOffset += 21
	$g_hLbl_XD_JumpLoss = GUICtrlCreateLabel("Thua thông nhảy:", $xOffset, $yOffset + 2, 102, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0x800080)
	$g_hInput_XD_JumpLoss = GUICtrlCreateInput("1", $xOffset + 102, $yOffset, 50, 20)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	$g_hLbl_XD_JumpWin = GUICtrlCreateLabel("Ăn thông nhảy:", $xOffset + 165, $yOffset + 2, 95, 18)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0x008000)
	$g_hInput_XD_JumpWin = GUICtrlCreateInput("0", $xOffset + 262, $yOffset, 68, 20)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	; DÒNG 5: Công tắc Gấp theo hàng luân phiên / Đi theo 1 hàng duy nhất
	$yOffset += 21
	GUIStartGroup()
	$g_hRadio_XD_MultiRow = GUICtrlCreateRadio("🔄 Gấp hàng luân phiên", $xOffset, $yOffset, 158, 19)
	GUICtrlSetFont(-1, 8.5, 800)
	GUICtrlSetColor(-1, 0x00008B)
	GUICtrlSetState(-1, $GUI_CHECKED)

	$g_hRadio_XD_SingleRow = GUICtrlCreateRadio("➡️ Đi 1 hàng duy nhất", $xOffset + 165, $yOffset, 165, 19)
	GUICtrlSetFont(-1, 8.5, 800)
	GUICtrlSetColor(-1, 0x800080)

	; DÒNG 6: Công tắc Chế độ Đánh Thật / Chế độ Đánh Demo
	$yOffset += 20
	GUIStartGroup()
	$g_hRadio_XD_RealKeep = GUICtrlCreateRadio("🔥 Chế độ Đánh Thật", $xOffset, $yOffset, 158, 19)
	GUICtrlSetFont(-1, 8.5, 800)
	GUICtrlSetColor(-1, 0xFF0000)
	GUICtrlSetState(-1, $GUI_CHECKED)

	$g_hRadio_XD_DemoKeep = GUICtrlCreateRadio("🧪 Chế độ Đánh Demo", $xOffset + 165, $yOffset, 165, 19)
	GUICtrlSetFont(-1, 8.5, 800)
	GUICtrlSetColor(-1, 0x008000)
	GUIStartGroup()

	; DÒNG 7: Bộ nhớ đệm Thống kê Thua Thông cao nhất từ trước tới giờ
	$yOffset += 20
	$g_hLbl_XD_StreakStats = GUICtrlCreateLabel(" thống kê thua thông...", $xOffset, $yOffset, 272, 28, $SS_SUNKEN)
	GUICtrlSetFont(-1, 7.5, 700)
	GUICtrlSetBkColor(-1, 0xFFFACD)
	GUICtrlSetColor(-1, 0x8B0000)

	$g_hBtn_XD_StreakDetail = GUICtrlCreateButton("📊 TK/Xóa", $xOffset + 276, $yOffset, 60, 28)
	GUICtrlSetFont(-1, 7.5, 800)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	; DÒNG 8: Trạng thái
	$yOffset += 30
	$g_hLbl_XD_Status = GUICtrlCreateLabel("Trạng thái: Đang chờ tín hiệu...", $xOffset, $yOffset, 335, 30)
	GUICtrlSetFont(-1, 8, 800)
	GUICtrlSetColor(-1, 0x008000)

	_UpdateStreakCacheUI()
	_ToggleXocDiaGridState($GUI_HIDE)
EndFunc   ;==>_CreateGroup_XocDia_Grid

Func _ToggleXocDiaGridState($iState)
	GUICtrlSetState($g_hGroup_XocDiaGrid, $iState)
	GUICtrlSetState($g_hLbl_XD_Status, $iState)
	GUICtrlSetState($g_hLbl_XD_Seq, $iState)
	GUICtrlSetState($g_hInput_XD_Seq, $iState)
	GUICtrlSetState($g_hLbl_XD_MaxRows, $iState)
	GUICtrlSetState($g_hInput_XD_MaxRows, $iState)
	GUICtrlSetState($g_hCheckbox_XD_AutoResetDebt, $iState)
	GUICtrlSetState($g_hInput_XD_TargetProfit, $iState)
	GUICtrlSetState($g_hCheckbox_XD_ShareDebt, $iState)
	GUICtrlSetState($g_hLbl_XD_Virtual, $iState)
	GUICtrlSetState($g_hInput_XD_Virtual, $iState)
	GUICtrlSetState($g_hCheckbox_XD_AntiKick, $iState)
	GUICtrlSetState($g_hInput_XD_AntiKick, $iState)
	GUICtrlSetState($g_hLbl_XD_JumpLoss, $iState)
	GUICtrlSetState($g_hInput_XD_JumpLoss, $iState)
	GUICtrlSetState($g_hLbl_XD_JumpWin, $iState)
	GUICtrlSetState($g_hInput_XD_JumpWin, $iState)
	GUICtrlSetState($g_hRadio_XD_MultiRow, $iState)
	GUICtrlSetState($g_hRadio_XD_SingleRow, $iState)
	GUICtrlSetState($g_hRadio_XD_RealKeep, $iState)
	GUICtrlSetState($g_hRadio_XD_DemoKeep, $iState)
	GUICtrlSetState($g_hLbl_XD_StreakStats, $iState)
	GUICtrlSetState($g_hBtn_XD_StreakDetail, $iState)

	For $c = 1 To 15
		GUICtrlSetState($g_aXD_Cols[$c], $iState)
	Next
	For $r = 1 To 10
		GUICtrlSetState($g_aXD_Rows[$r], $iState)
		For $c = 1 To 15
			GUICtrlSetState($g_aXocDiaGrid[$r][$c], $iState)
		Next
	Next
EndFunc   ;==>_ToggleXocDiaGridState

Func _SetControlsState($bEnable)
	Local $iState = $bEnable ? $GUI_ENABLE : $GUI_DISABLE
	Local $iInputColor = $bEnable ? 0xE0FFFF : 0xE0E0E0
	Local $iYellow = $bEnable ? 0xFFFACD : 0xE0E0E0

	GUICtrlSetState($g_hInput_InitialCapital, $iState)
	GUICtrlSetBkColor($g_hInput_InitialCapital, $iInputColor)
	GUICtrlSetState($g_hInput_InitialBet, $iState)
	GUICtrlSetBkColor($g_hInput_InitialBet, $iInputColor)

	GUICtrlSetState($g_hCheckbox_SeparateQLV, $iState)
	GUICtrlSetState($g_hCheckbox_ReverseLogic, $iState)
	GUICtrlSetState($g_hInput_CustomRules, $iState)
	GUICtrlSetBkColor($g_hInput_CustomRules, $iYellow)

	GUICtrlSetState($g_hInput_CustomQLV_Edit, $iState)
	GUICtrlSetBkColor($g_hInput_CustomQLV_Edit, $bEnable ? 0xF0FFF0 : 0xE0E0E0)
	GUICtrlSetState($g_hCombo_QLV_Presets, $iState)
	GUICtrlSetState($g_hButton_SaveQLV, $iState)
	GUICtrlSetState($g_hButton_DeleteQLV, $iState)

	GUICtrlSetState($g_hInput_XD_Seq, $iState)
	GUICtrlSetState($g_hInput_XD_MaxRows, $iState)
	GUICtrlSetState($g_hCheckbox_XD_AutoResetDebt, $iState)
	GUICtrlSetState($g_hInput_XD_TargetProfit, $iState)
	GUICtrlSetState($g_hInput_XD_Virtual, $iState)
	GUICtrlSetState($g_hInput_XD_AntiKick, $iState)
	GUICtrlSetState($g_hInput_XD_JumpLoss, $iState)
	GUICtrlSetState($g_hInput_XD_JumpWin, $iState)
	; Cho phép bật/tắt các công tắc chế độ và xem thống kê ngay cả khi Tool đang chạy
	GUICtrlSetState($g_hCheckbox_XD_ShareDebt, $GUI_ENABLE)
	GUICtrlSetState($g_hCheckbox_XD_AntiKick, $GUI_ENABLE)
	GUICtrlSetState($g_hRadio_XD_MultiRow, $GUI_ENABLE)
	GUICtrlSetState($g_hRadio_XD_SingleRow, $GUI_ENABLE)
	GUICtrlSetState($g_hRadio_XD_RealKeep, $GUI_ENABLE)
	GUICtrlSetState($g_hRadio_XD_DemoKeep, $GUI_ENABLE)
	GUICtrlSetState($g_hBtn_XD_StreakDetail, $GUI_ENABLE)

	GUICtrlSetState($g_hCheckbox_DailyShield, $iState)
	GUICtrlSetState($g_hInput_DailyTarget, $iState)
	GUICtrlSetState($g_hInput_DailyStopLoss, $iState)
	GUICtrlSetState($g_hInput_DailyTrailing, $iState)
	GUICtrlSetState($g_hRadio_Action_Stop, $iState)
	GUICtrlSetState($g_hRadio_Action_PauseMin, $iState)
	GUICtrlSetState($g_hInput_Action_PauseMin, $iState)
	GUICtrlSetState($g_hRadio_Action_PauseHand, $iState)
	GUICtrlSetState($g_hInput_Action_PauseHand, $iState)

	GUICtrlSetState($g_hCombo_Profiles_Main, $iState)
	GUICtrlSetState($g_hRadio_ClickMode_Control_Main, $iState)
	GUICtrlSetState($g_hRadio_ClickMode_Mouse_Main, $iState)
	GUICtrlSetState($g_hTabItemConfig, $iState)

	If $bEnable Then
		GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
		GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
	Else
		GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
		GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)
	EndIf
EndFunc   ;==>_SetControlsState

Func _CreateGroup_BPT_Totals()
	$g_hGroup_BPTTotals = _CreateStyledGroup("Tổng Số Ván", 370, 35, 300, 60)
	Local $y_line1 = 60

	$g_hLbl_B = GUICtrlCreateLabel("B:", 375, $y_line1, 15, 20)
	GUICtrlSetColor(-1, 0xF70102)
	$g_hLabel_TotalB_Val = GUICtrlCreateLabel("0", 390, $y_line1, 35, 20)

	$g_hLbl_P = GUICtrlCreateLabel("P:", 430, $y_line1, 15, 20)
	GUICtrlSetColor(-1, 0x0182FA)
	$g_hLabel_TotalP_Val = GUICtrlCreateLabel("0", 445, $y_line1, 35, 20)

	$g_hLbl_T = GUICtrlCreateLabel("T:", 485, $y_line1, 15, 20)
	GUICtrlSetColor(-1, 0x29BC2F)
	$g_hLabel_TotalT_Val = GUICtrlCreateLabel("0", 500, $y_line1, 35, 20)

	$g_hLbl_TongVan = GUICtrlCreateLabel("Tổng:", 545, $y_line1, 40, 20)
	$g_hLabel_TotalHands = GUICtrlCreateLabel("0", 585, $y_line1 - 2, 60, 22)
	GUICtrlSetFont($g_hLabel_TotalHands, 11, 800)
	GUICtrlSetColor($g_hLabel_TotalHands, 0x0000FF)
EndFunc   ;==>_CreateGroup_BPT_Totals

Func _CreateGroup_HistoryDisplay()
	_CreateStyledGroup("Lịch Sử Kết Quả", 370, 100, 300, 130)
	Local $yStart = 120, $xStart = 376
	For $iRow = 0 To 5
		For $iCol = 0 To 19
			Local $iIndex = $iCol + ($iRow * 20)
			$g_aLabel_History[$iIndex] = GUICtrlCreateLabel("-", $xStart + $iCol * 14.3, $yStart + $iRow * 17.2, 13, 15, $SS_CENTER)
			GUICtrlSetFont(-1, 7, 700)
		Next
	Next
EndFunc   ;==>_CreateGroup_HistoryDisplay

Func _CreateGroup_HistoryLog()
	$g_hGroup_ActivityLog = _CreateStyledGroup("Màn Hình TV Screen", 370, 235, 300, 290)
	$g_hEdit_ActivityLog = GUICtrlCreateEdit("", 378, 255, 284, 260, BitOR(0x00200000, 0x0040, 0x0800))
	GUICtrlSetBkColor($g_hEdit_ActivityLog, 0x000000)
	GUICtrlSetColor($g_hEdit_ActivityLog, 0x00FF00)
EndFunc   ;==>_CreateGroup_HistoryLog

Func _CreateGroup_InfoAndTargets()
	$g_hGroup_InfoTargets = _CreateStyledGroup("Thông Tin & Mục Tiêu", 680, 35, 290, 275)
	Local $x = 690, $w = 270, $y = 55

	GUICtrlCreateLabel("Số dư hiện tại:", $x, $y, 100, 20)
	$g_hLabel_CurrentBalance = GUICtrlCreateLabel("0 đ", $x + 100, $y - 3, 170, 22, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetBkColor(-1, 0xFFFACD)
	GUICtrlSetColor(-1, 0x0000FF)

	$y += 28
	GUICtrlCreateLabel("Lãi/Lỗ phiên này:", $x, $y, 100, 20)
	$g_hLabel_Profit = GUICtrlCreateLabel("0 đ", $x + 100, $y - 3, 170, 22, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetBkColor(-1, 0xFFFACD)

	$g_hCombo_VolumeFilter = GUICtrlCreateCombo("Hôm Nay", -999, -999, 10, 10)
	$g_hDate_VolumeFilter = GUICtrlCreateDate("", -999, -999, 10, 10)
	$g_hLabel_TotalVolume = GUICtrlCreateLabel("", -999, -999, 10, 10)

	$y += 35
	$g_hLabel_NetDay = GUICtrlCreateLabel("LỢI NHUẬN TỔNG: 0 đ", $x, $y, $w, 23, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetBkColor(-1, 0xE0FFFF)
	GUICtrlSetColor(-1, 0x006400)

	$y += 35
	$g_hCheckbox_DailyShield = GUICtrlCreateCheckbox("🎯 MỤC TIÊU CHỐT LÃI / CẮT LỖ", $x, $y, 250, 20)
	GUICtrlSetColor(-1, 0xFF00FF)

	$y += 25
	GUICtrlCreateLabel("Chốt lời:", $x, $y, 55, 20)
	$g_hInput_DailyTarget = GUICtrlCreateInput("1.000.000", $x + 55, $y - 2, 75, 22)
	GUICtrlCreateLabel("Cắt lỗ:", $x + 135, $y, 50, 20)
	GUICtrlSetColor(-1, 0xFF0000)
	$g_hInput_DailyStopLoss = GUICtrlCreateInput("-1.000.000", $x + 185, $y - 2, 80, 22)

	$y += 28
	GUICtrlCreateLabel("Kéo đuôi:", $x, $y, 55, 20)
	GUICtrlSetColor(-1, 0x008000)
	$g_hInput_DailyTrailing = GUICtrlCreateInput("200.000", $x + 55, $y - 2, 75, 22)

	$y += 28
	GUICtrlCreateLabel("Chạm mốc:", $x, $y, 70, 20)
	GUICtrlSetColor(-1, 0x0000FF)
	$g_hRadio_Action_Stop = GUICtrlCreateRadio("Dừng", $x + 70, $y, 55, 20)

	$y += 24
	$g_hRadio_Action_PauseMin = GUICtrlCreateRadio("Nghỉ", $x + 10, $y, 50, 20)
	$g_hInput_Action_PauseMin = GUICtrlCreateInput("15", $x + 65, $y - 2, 35, 22)
	GUICtrlCreateLabel("phút", $x + 105, $y, 35, 20)

	$g_hRadio_Action_PauseHand = GUICtrlCreateRadio("Nghỉ", $x + 150, $y, 50, 20)
	$g_hInput_Action_PauseHand = GUICtrlCreateInput("5", $x + 205, $y - 2, 35, 22)
	GUICtrlCreateLabel("ván", $x + 245, $y, 25, 20)
EndFunc   ;==>_CreateGroup_InfoAndTargets

Func _CreateGroup_UserConfig_Main()
	_CreateStyledGroup("Điều Khiển Nhanh", 680, 315, 290, 210)
	Local $x = 690, $y = 340

	GUICtrlCreateLabel("Cấu hình:", $x, $y, 60, 20)
	$g_hCombo_Profiles_Main = GUICtrlCreateCombo("", $x + 70, $y - 3, 200, 25, $CBS_DROPDOWNLIST)

	$y += 32
	GUICtrlCreateLabel("Trễ thả chip:", $x, $y, 75, 20)
	$g_hInput_ClickDelay_Main = GUICtrlCreateInput("150", $x + 75, $y - 2, 40, 22)
	GUICtrlCreateLabel("ms", $x + 120, $y, 20, 20)
	GUICtrlSetTip($g_hInput_ClickDelay_Main, "Tăng số này (vd 150-300) nếu game nhận rớt phỉnh")

	GUICtrlCreateLabel("Tốc độ rê:", $x + 150, $y, 70, 20)
	$g_hInput_MouseSpeed = GUICtrlCreateInput("2", $x + 220, $y - 2, 40, 22)
	GUICtrlSetTip($g_hInput_MouseSpeed, "0 là tức thì, 10 là chậm. Khuyên dùng 2")

	$g_hRadio_ClickMode_Control_Main = GUICtrlCreateRadio("Nhanh", -999, -999, 10, 10)
	$g_hRadio_ClickMode_Mouse_Main = GUICtrlCreateRadio("Chuột", -999, -999, 10, 10)

	$y += 32
	$g_hCheckbox_PinTool = GUICtrlCreateCheckbox("📌 Ghim Tool luôn nổi (Chống đè)", $x + 20, $y, 250, 20)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0xFF00FF)
	GUICtrlSetState(-1, $GUI_UNCHECKED)

	$y += 32
	$g_hButton_Start = GUICtrlCreateButton("ĐĂNG NHẬP", $x + 30, $y, 210, 60)
	GUICtrlSetFont(-1, 13, 800)
	GUICtrlSetBkColor(-1, 0x33CC33)
EndFunc   ;==>_CreateGroup_UserConfig_Main

Func _CreateTab_ConfigHelper()
	$g_hButton_Unlock = GUICtrlCreateButton("🔐 MỞ KHÓA", 820, 35, 140, 30)
	GUICtrlSetFont(-1, 10, 800)
	GUICtrlSetBkColor(-1, 0xFF4141)
	GUICtrlSetColor(-1, 0xFFFFFF)

	$g_iTechTabStart = GUICtrlCreateDummy()

	GUICtrlCreateLabel("Tọa độ X:", 20, 42, 60, 20)
	$g_hInput_ScanX = GUICtrlCreateInput("", 80, 40, 50, 22)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	GUICtrlCreateLabel("Y:", 140, 42, 20, 20)
	$g_hInput_ScanY = GUICtrlCreateInput("", 160, 40, 50, 22)
	GUICtrlSetBkColor(-1, 0xE0FFFF)

	GUICtrlCreateLabel("Mã Màu:", 220, 42, 60, 20)
	$g_hInput_ScanColor = GUICtrlCreateInput("", 280, 40, 70, 22)
	GUICtrlSetBkColor(-1, 0xE0FFFF)
	$g_hLabel_ScanColorPreview = GUICtrlCreateLabel("", 360, 40, 30, 22)

	$g_hCheckbox_ToggleScan = GUICtrlCreateCheckbox("Bật phím ` (Góc trái số 1) lấy Tọa độ/Màu", 410, 40, 300, 20)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0xFF0000)

	; ================= CỘT TRÁI (Tọa độ Game) =================
	_CreateStyledGroup("Thiết Lập Tọa Độ Baccarat / Xóc Đĩa", 10, 70, 480, 275)
	Local $x1 = 20, $y1 = 95

	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Class cửa sổ Game:", $x1, $y1, 130, 20))
	$g_hInput_WindowClass = GUICtrlCreateInput("", $x1 + 130, $y1 - 2, 330, 22)
	_ArrayAdd($g_aConfigControls, $g_hInput_WindowClass)

	$y1 += 30
	$g_hLbl_Coord_B = GUICtrlCreateLabel("Banker (X, Y):", $x1, $y1, 90, 20)
	_ArrayAdd($g_aConfigControls, $g_hLbl_Coord_B)
	$g_hInput_BankerX = GUICtrlCreateInput("", $x1 + 90, $y1 - 2, 50, 22)
	$g_hInput_BankerY = GUICtrlCreateInput("", $x1 + 145, $y1 - 2, 50, 22)
	$g_hButton_GetBankerPos = GUICtrlCreateButton("Lấy", $x1 + 200, $y1 - 3, 40, 24)

	$g_hLbl_Coord_P = GUICtrlCreateLabel("Player (X, Y):", $x1 + 250, $y1, 90, 20)
	_ArrayAdd($g_aConfigControls, $g_hLbl_Coord_P)
	$g_hInput_PlayerX = GUICtrlCreateInput("", $x1 + 330, $y1 - 2, 50, 22)
	$g_hInput_PlayerY = GUICtrlCreateInput("", $x1 + 385, $y1 - 2, 50, 22)
	$g_hButton_GetPlayerPos = GUICtrlCreateButton("Lấy", $x1 + 440, $y1 - 3, 40, 24)

	$y1 += 30
	$g_hLbl_Coord_T = GUICtrlCreateLabel("Hòa/Tie (X, Y):", $x1, $y1, 90, 20)
	_ArrayAdd($g_aConfigControls, $g_hLbl_Coord_T)
	$g_hInput_TieX = GUICtrlCreateInput("", $x1 + 90, $y1 - 2, 50, 22)
	$g_hInput_TieY = GUICtrlCreateInput("", $x1 + 145, $y1 - 2, 50, 22)
	$g_hButton_GetTiePos = GUICtrlCreateButton("Lấy", $x1 + 200, $y1 - 3, 40, 24)

	$y1 += 30
	$g_hLbl_Color_B = GUICtrlCreateLabel("Màu B/P:", $x1, $y1, 60, 20)
	_ArrayAdd($g_aConfigControls, $g_hLbl_Color_B)
	$g_hInput_BankerColor = GUICtrlCreateInput("", $x1 + 65, $y1 - 2, 70, 22)
	$g_hButton_GetBankerColor = GUICtrlCreateButton("Lấy B", $x1 + 140, $y1 - 3, 45, 24)
	$g_hInput_PlayerColor = GUICtrlCreateInput("", $x1 + 195, $y1 - 2, 70, 22)
	$g_hButton_GetPlayerColor = GUICtrlCreateButton("Lấy P", $x1 + 270, $y1 - 3, 45, 24)
	$g_hInput_TieColor = GUICtrlCreateInput("", $x1 + 325, $y1 - 2, 70, 22)
	$g_hButton_GetTieColor = GUICtrlCreateButton("Lấy T", $x1 + 400, $y1 - 3, 45, 24)

	$y1 += 30
	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Vùng quét KQ (X1,Y1 - X2,Y2):", $x1, $y1, 200, 20))
	$g_hInput_Shade_Result = GUICtrlCreateInput("10", $x1 + 210, $y1 - 2, 30, 22)
	$g_hButton_TestColor_Result = GUICtrlCreateButton("Test Màu KQ", $x1 + 250, $y1 - 3, 90, 24)

	$y1 += 25
	$g_hInput_ResultX1 = GUICtrlCreateInput("", $x1, $y1, 50, 22)
	$g_hInput_ResultY1 = GUICtrlCreateInput("", $x1 + 55, $y1, 50, 22)
	$g_hButton_GetResultTL = GUICtrlCreateButton("Lấy", $x1 + 110, $y1 - 1, 40, 24)
	$g_hInput_ResultX2 = GUICtrlCreateInput("", $x1 + 160, $y1, 50, 22)
	$g_hInput_ResultY2 = GUICtrlCreateInput("", $x1 + 215, $y1, 50, 22)
	$g_hButton_GetResultBR = GUICtrlCreateButton("Lấy", $x1 + 270, $y1 - 1, 40, 24)
	$g_hCheckbox_BaccaratLaser = GUICtrlCreateCheckbox("Quét Vùng KQ", $x1 + 320, $y1, 130, 20)

	$y1 += 30
	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Giờ Cược (X1,Y1 - X2,Y2):", $x1, $y1, 180, 20))
	$g_hInput_BetTimeColor = GUICtrlCreateInput("", $x1 + 180, $y1 - 2, 70, 22)
	$g_hButton_GetBetTimeColor = GUICtrlCreateButton("Màu", $x1 + 260, $y1 - 3, 40, 24)
	$g_hInput_Shade_Timer = GUICtrlCreateInput("20", $x1 + 310, $y1 - 2, 30, 22)
	$g_hButton_TestColor_Timer = GUICtrlCreateButton("Test GC", $x1 + 350, $y1 - 3, 70, 24)

	$y1 += 25
	$g_hInput_BetTimeX1 = GUICtrlCreateInput("", $x1, $y1, 50, 22)
	$g_hInput_BetTimeY1 = GUICtrlCreateInput("", $x1 + 55, $y1, 50, 22)
	$g_hButton_GetBetTimeTL = GUICtrlCreateButton("Lấy", $x1 + 110, $y1 - 1, 40, 24)
	$g_hInput_BetTimeX2 = GUICtrlCreateInput("", $x1 + 160, $y1, 50, 22)
	$g_hInput_BetTimeY2 = GUICtrlCreateInput("", $x1 + 215, $y1, 50, 22)
	$g_hButton_GetBetTimeBR = GUICtrlCreateButton("Lấy", $x1 + 270, $y1 - 1, 40, 24)

	; ================= CỘT TRÁI DƯỚI (Quản Lý Sảnh) =================
	_CreateStyledGroup("Quản Lý Sảnh", 10, 355, 480, 60)
	Local $x_prof = 20, $y_prof = 380
	$g_hCombo_Profiles = GUICtrlCreateCombo("", $x_prof, $y_prof - 2, 180, 25, $CBS_DROPDOWNLIST)
	$g_hButton_SaveNewProfile = GUICtrlCreateButton("💾 Lưu Sảnh Mới", $x_prof + 190, $y_prof - 4, 140, 26)
	GUICtrlSetBkColor(-1, 0x0082FA)
	GUICtrlSetColor(-1, 0xFFFFFF)
	$g_hButton_DeleteProfile = GUICtrlCreateButton("❌ Xóa Sảnh", $x_prof + 340, $y_prof - 4, 100, 26)
	GUICtrlSetBkColor(-1, 0xFF4141)
	GUICtrlSetColor(-1, 0xFFFFFF)

	; ================= CỘT PHẢI (Chip & Xóc Đĩa VIP) =================
	_CreateStyledGroup("Cấu Hình Chip Cược", 500, 70, 460, 185)
	Local $x_chip = 510, $y_chip = 95
	For $i = 0 To 4
		$g_aCheckbox_ChipEnabled[$i] = GUICtrlCreateCheckbox("Chip " & ($i + 1), $x_chip, $y_chip, 60, 20)
		_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("Giá trị:", $x_chip + 70, $y_chip, 50, 20))
		$g_aInput_ChipValue[$i] = GUICtrlCreateInput("", $x_chip + 120, $y_chip - 2, 80, 22)
		_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("X, Y:", $x_chip + 210, $y_chip, 35, 20))
		$g_aInput_ChipX[$i] = GUICtrlCreateInput("", $x_chip + 245, $y_chip - 2, 50, 22)
		$g_aInput_ChipY[$i] = GUICtrlCreateInput("", $x_chip + 300, $y_chip - 2, 50, 22)
		$g_aButton_GetChipPos[$i] = GUICtrlCreateButton("Lấy", $x_chip + 360, $y_chip - 3, 60, 24)
		$y_chip += 28
	Next

	_CreateStyledGroup("Xóc Đĩa VIP (5 Hàng - Đổi Hạn Mức)", 500, 265, 460, 150)
	Local $x_xd = 510, $y_xd = 285

	$g_hCheckbox_XocDiaVIP = GUICtrlCreateCheckbox("🔥 BẬT XÓC ĐĨA VIP", $x_xd, $y_xd, 200, 20)
	GUICtrlSetColor(-1, 0xFF0000)

	$y_xd += 28
	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("1. Nút Mở:", $x_xd, $y_xd, 60, 20))
	$g_hInput_LimitBtnX = GUICtrlCreateInput("", $x_xd + 60, $y_xd - 2, 35, 22)
	$g_hInput_LimitBtnY = GUICtrlCreateInput("", $x_xd + 95, $y_xd - 2, 35, 22)
	$g_hButton_GetLimitBtn = GUICtrlCreateButton("Lấy", $x_xd + 130, $y_xd - 3, 35, 24)

	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("2. Ô 10-500:", $x_xd + 175, $y_xd, 70, 20))
	$g_hInput_Limit10_500X = GUICtrlCreateInput("", $x_xd + 245, $y_xd - 2, 35, 22)
	$g_hInput_Limit10_500Y = GUICtrlCreateInput("", $x_xd + 280, $y_xd - 2, 35, 22)
	$g_hButton_GetLimit10_500 = GUICtrlCreateButton("Lấy", $x_xd + 315, $y_xd - 3, 35, 24)

	$y_xd += 28
	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("3. Ô 20-50K:", $x_xd, $y_xd, 70, 20))
	$g_hInput_Limit20_50KX = GUICtrlCreateInput("", $x_xd + 60, $y_xd - 2, 35, 22)
	$g_hInput_Limit20_50KY = GUICtrlCreateInput("", $x_xd + 95, $y_xd - 2, 35, 22)
	$g_hButton_GetLimit20_50K = GUICtrlCreateButton("Lấy", $x_xd + 130, $y_xd - 3, 35, 24)

	_ArrayAdd($g_aConfigControls, GUICtrlCreateLabel("4. Xác nhận:", $x_xd + 175, $y_xd, 70, 20))
	$g_hInput_LimitConfirmX = GUICtrlCreateInput("", $x_xd + 245, $y_xd - 2, 35, 22)
	$g_hInput_LimitConfirmY = GUICtrlCreateInput("", $x_xd + 280, $y_xd - 2, 35, 22)
	$g_hButton_GetLimitConfirm = GUICtrlCreateButton("Lấy", $x_xd + 315, $y_xd - 3, 35, 24)

	$g_iTechTabEnd = GUICtrlCreateDummy()
EndFunc   ;==>_CreateTab_ConfigHelper

; --- CÁC HÀM TÁCH BIỆT GIAO DIỆN BACCARAT VS XÓC ĐĨA ---
Func _ToggleGameModeUI()
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		GUICtrlSetData($g_hLbl_B, "C:")
		GUICtrlSetData($g_hLbl_P, "L:")
		GUICtrlSetState($g_hLbl_T, $GUI_HIDE)
		GUICtrlSetState($g_hLabel_TotalT_Val, $GUI_HIDE)

		GUICtrlSetData($g_hLbl_Coord_B, "Chẵn (X, Y):")
		GUICtrlSetData($g_hLbl_Coord_P, "Lẻ (X, Y):")
		GUICtrlSetData($g_hLbl_Coord_T, "Bỏ Qua (X,Y):")
		GUICtrlSetData($g_hLbl_Color_B, "Màu C/L:")
		GUICtrlSetData($g_hButton_GetBankerColor, "Lấy C")
		GUICtrlSetData($g_hButton_GetPlayerColor, "Lấy L")
		GUICtrlSetData($g_hButton_GetTieColor, "-")

		GUICtrlSetState($g_hLbl_Coord_T, $GUI_HIDE)
		GUICtrlSetState($g_hInput_TieX, $GUI_HIDE)
		GUICtrlSetState($g_hInput_TieY, $GUI_HIDE)
		GUICtrlSetState($g_hButton_GetTiePos, $GUI_HIDE)
		GUICtrlSetState($g_hInput_TieColor, $GUI_HIDE)
		GUICtrlSetState($g_hButton_GetTieColor, $GUI_HIDE)

		_ToggleBaccaratLeftColumn($GUI_HIDE)
		_ToggleXocDiaGridState($GUI_SHOW)
		_UpdateXocDiaGridUI()
	Else
		GUICtrlSetData($g_hLbl_B, "B:")
		GUICtrlSetData($g_hLbl_P, "P:")
		GUICtrlSetState($g_hLbl_T, $GUI_SHOW)
		GUICtrlSetState($g_hLabel_TotalT_Val, $GUI_SHOW)

		GUICtrlSetState($g_hLbl_Coord_T, $GUI_SHOW)
		GUICtrlSetState($g_hInput_TieX, $GUI_SHOW)
		GUICtrlSetState($g_hInput_TieY, $GUI_SHOW)
		GUICtrlSetState($g_hButton_GetTiePos, $GUI_SHOW)
		GUICtrlSetState($g_hInput_TieColor, $GUI_SHOW)
		GUICtrlSetState($g_hButton_GetTieColor, $GUI_SHOW)

		GUICtrlSetData($g_hLbl_Coord_B, "Banker (X, Y):")
		GUICtrlSetData($g_hLbl_Coord_P, "Player (X, Y):")
		GUICtrlSetData($g_hLbl_Coord_T, "Hòa/Tie (X,Y):")
		GUICtrlSetData($g_hLbl_Color_B, "Màu B/P:")
		GUICtrlSetData($g_hButton_GetBankerColor, "Lấy B")
		GUICtrlSetData($g_hButton_GetPlayerColor, "Lấy P")
		GUICtrlSetData($g_hButton_GetTieColor, "Lấy T")

		_ToggleXocDiaGridState($GUI_HIDE)
		_ToggleBaccaratLeftColumn($GUI_SHOW)
	EndIf
EndFunc   ;==>_ToggleGameModeUI

Func _ToggleBaccaratLeftColumn($iState)
	GUICtrlSetState($g_hGroup_BettingMethod, $iState)
	GUICtrlSetState($g_hCheckbox_SeparateQLV, $iState)
	GUICtrlSetState($g_hCheckbox_ReverseLogic, $iState)
	GUICtrlSetState($g_hLabel_TieuDeCongThuc, $iState)
	GUICtrlSetState($g_hInput_CustomRules, $iState)

	GUICtrlSetState($g_hGroup_QLV_Main, $iState)
	GUICtrlSetState($g_hLbl_QLV1, $iState)
	GUICtrlSetState($g_hInput_CustomQLV_Edit, $iState)
	GUICtrlSetState($g_hLbl_QLV2, $iState)
	GUICtrlSetState($g_hCombo_QLV_Presets, $iState)
	GUICtrlSetState($g_hButton_SaveQLV, $iState)
	GUICtrlSetState($g_hButton_DeleteQLV, $iState)
EndFunc   ;==>_ToggleBaccaratLeftColumn

Func _ExecuteHideShow()
	GUICtrlSetState($g_hInput_DailyTarget, $GUI_SHOW)
	GUICtrlSetState($g_hInput_DailyTrailing, $GUI_SHOW)
	GUICtrlSetState($g_hInput_DailyStopLoss, $GUI_SHOW)
	GUICtrlSetState($g_hCheckbox_DailyShield, $GUI_SHOW)

	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then Return

	If StringStripWS(GUICtrlRead($g_hInput_CustomRules), 8) == "" Then
		GUICtrlSetState($g_hInput_CustomRules, $GUI_HIDE)
	Else
		GUICtrlSetState($g_hInput_CustomRules, $GUI_SHOW)
	EndIf

	GUICtrlSetState($g_hInput_CustomQLV_Edit, $GUI_SHOW)
	GUICtrlSetState($g_hCombo_QLV_Presets, $GUI_SHOW)
	GUICtrlSetState($g_hButton_SaveQLV, $GUI_SHOW)
	GUICtrlSetState($g_hButton_DeleteQLV, $GUI_SHOW)
EndFunc   ;==>_ExecuteHideShow

Func _ToggleTechRoom($iState)
	For $i = $g_iTechTabStart To $g_iTechTabEnd
		If $i <> $g_iTechTabStart And $i <> $g_iTechTabEnd Then
			GUICtrlSetState($i, $iState)
		EndIf
	Next
EndFunc   ;==>_ToggleTechRoom

Func _ToggleConfigControlsState($bEnable)
	Local $iState = $bEnable ? $GUI_ENABLE : $GUI_DISABLE
	$g_bConfigUnlocked = $bEnable
	For $hControl In $g_aConfigControls
		GUICtrlSetState($hControl, $iState)
	Next
EndFunc   ;==>_ToggleConfigControlsState
#EndRegion 4. THIẾT KẾ GIAO DIỆN (GUI) & CHUYỂN ĐỔI CHẾ ĐỘ BACCARAT / XÓC ĐĨA

; ==================================================================================================
#Region 5. VÒNG LẶP SỰ KIỆN & ĐIỀU PHỐI TIẾN TRÌNH CHẠY
; ==================================================================================================
Func _MainLoop()
	AdlibRegister("_CheckForUpdates", 6000000)

	While 1
		If $g_bNeedAutoSave And TimerDiff($g_hAutoSaveTimer) > 1000 Then
			If $g_sCurrentLoadedProfile <> "" Then _MasterSave($g_sCurrentLoadedProfile, True)
			$g_bNeedAutoSave = False
		EndIf

		Local $aMsg = GUIGetMsg(1)

		Switch $aMsg[0]
			Case 0
				ContinueLoop

			Case $GUI_EVENT_RESTORE
				WinActivate($g_hGUI)
				If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
					WinSetOnTop($g_hGUI, "", 1)
				Else
					WinSetOnTop($g_hGUI, "", 1)
					WinSetOnTop($g_hGUI, "", 0)
				EndIf

			Case $g_hCheckbox_PinTool
				If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
					WinSetOnTop($g_hGUI, "", 1)
					_UpdateStatus("📌 Đã ghim Tool nổi lên trên màn hình Game.")
				Else
					WinSetOnTop($g_hGUI, "", 0)
					_UpdateStatus("🔽 Đã gỡ ghim. Tool sẽ ẩn khi click vào Game.")
				EndIf

			Case $g_hButton_GetLimitBtn
				_GetCoords_Fast($g_hInput_LimitBtnX, $g_hInput_LimitBtnY)
			Case $g_hButton_GetLimit10_500
				_GetCoords_Fast($g_hInput_Limit10_500X, $g_hInput_Limit10_500Y)
			Case $g_hButton_GetLimit20_50K
				_GetCoords_Fast($g_hInput_Limit20_50KX, $g_hInput_Limit20_50KY)
			Case $g_hButton_GetLimitConfirm
				_GetCoords_Fast($g_hInput_LimitConfirmX, $g_hInput_LimitConfirmY)

			Case $g_hRadio_ClickMode_Control_Main, $g_hRadio_ClickMode_Mouse_Main, $g_hCheckbox_ReverseLogic, $g_hCheckbox_SeparateQLV
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()

			Case $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter
				_RefreshVolumeDisplay()

			Case $GUI_EVENT_CLOSE
				If $aMsg[1] = $g_hGUI Then
					Local $aPos = WinGetPos($g_hGUI)
					If IsArray($aPos) And $aPos[0] > -10000 Then
						IniWrite($g_sIniPath, "Settings", "WinX", $aPos[0])
						IniWrite($g_sIniPath, "Settings", "WinY", $aPos[1])
					EndIf
					_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
					If $g_sSession <> "" Then
						_WD_DeleteSession($g_sSession)
						_WD_Shutdown()
					EndIf
					Exit
				EndIf

			Case $g_hButton_SaveNewProfile
				Local $sNewName = InputBox("Cấp Phát Cấu Hình VIP", "Nhập thông tin theo cú pháp 3 phần:" & @CRLF & "[TênKhách]_[TênSảnh]_[TròChơi]" & @CRLF & @CRLF & "Ví dụ 1: thuydung_Sexy_XocDia" & @CRLF & "Ví dụ 2: thuydung_WM_Baccarat", "")
				If @error Or $sNewName == "" Then ContinueLoop

				_MasterSave($sNewName, False)
				_PopulateProfileList()
				GUICtrlSetData($g_hCombo_Profiles, $sNewName)
				GUICtrlSetData($g_hCombo_Profiles_Main, $sNewName)
				$g_sCurrentLoadedProfile = $sNewName
				MsgBox(64, "Thành Công", "Tuyệt vời! Đã lưu toàn bộ thiết lập hiện tại vào sảnh: " & $sNewName)

			Case $g_hButton_DeleteProfile
				Local $sSelectedProfile = GUICtrlRead($g_hCombo_Profiles)
				If $sSelectedProfile = "" Then
					MsgBox(48, "Cảnh Báo", "Bạn chưa chọn sảnh nào để xóa!")
					ContinueLoop
				EndIf

				If MsgBox(36, "Xác Nhận Xóa", "Bạn có chắc chắn muốn xóa vĩnh viễn cấu hình của: [" & $sSelectedProfile & "] không?") = 6 Then
					IniDelete($g_sIniPath, "Profile_" & $sSelectedProfile)
					$g_sCurrentLoadedProfile = ""

					Local $aSections = IniReadSectionNames($g_sIniPath)
					Local $sNextProfile = ""
					If Not @error Then
						For $i = 1 To $aSections[0]
							If StringLeft($aSections[$i], 8) = "Profile_" Then
								$sNextProfile = StringTrimLeft($aSections[$i], 8)
								ExitLoop
							EndIf
						Next
					EndIf

					If $sNextProfile <> "" Then
						_PopulateProfileList()
						GUICtrlSetData($g_hCombo_Profiles_Main, $sNextProfile)
						GUICtrlSetData($g_hCombo_Profiles, $sNextProfile)
						_HandleProfileChange($g_hCombo_Profiles)
					Else
						_CreateDefaultIniFile()
						_PopulateProfileList()
						GUICtrlSetData($g_hCombo_Profiles_Main, "Sảnh PP Mẫu")
						GUICtrlSetData($g_hCombo_Profiles, "Sảnh PP Mẫu")
						_HandleProfileChange($g_hCombo_Profiles)
					EndIf

					MsgBox(64, "Thành Công", "Đã tiêu diệt vĩnh viễn sảnh [" & $sSelectedProfile & "].")
				EndIf

			Case $g_hButton_Start
				If $g_bIsRunning Then
					_StopProcess()
					GUICtrlSetData($g_hButton_Start, "BẮT ĐẦU QUÉT")
					GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
					GUISetState(@SW_RESTORE, $g_hGUI)
				Else
					$g_bIsRunning = True
					GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
					GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
					GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)

					GUISetState(@SW_MINIMIZE, $g_hGUI)
					_UpdateStatus("🔽 Đã hạ Tool xuống Taskbar để sếp tiện thao tác trên Game...")

					Local $iInitChrome = _LaunchChrome_WebDriver()
					If $iInitChrome == 1 Then
						If _AutoCatchPopup_And_Maximize() Then
							_UpdateStatus("🚀 [CHỐT TỌA ĐỘ] Đã khóa cứng vào bàn Game. Bắt đầu nã đạn!")
							_StartProcess()
						Else
							_UpdateStatus("🛑 Đã hủy quá trình chờ Game.")
							_StopProcess()
							GUISetState(@SW_RESTORE, $g_hGUI)
						EndIf
					Else
						_UpdateStatus("🛑 Lỗi: Không thể khởi động Chrome WebDriver!")
						_StopProcess()
						GUISetState(@SW_RESTORE, $g_hGUI)
					EndIf
				EndIf

			Case $g_hButton_Unlock
				Local $sCurrentText = GUICtrlRead($g_hButton_Unlock)
				If StringInStr($sCurrentText, "MỞ KHÓA") Then
					Local $sPass = InputBox("Yêu cầu mật khẩu", "Vui lòng nhập mật khẩu...", "", "*")
					If $sPass == $g_sDevPassword Then
						$g_bIsDevMode = True
						_ToggleTechRoom($GUI_SHOW)
						_ToggleConfigControlsState(True)
						GUICtrlSetData($g_hButton_Unlock, "🔓 KHÓA LẠI")
						GUICtrlSetBkColor($g_hButton_Unlock, 0x33CC33)
					ElseIf $sPass <> "" Then
						MsgBox(16, "Lỗi", "Sai mật khẩu!")
					EndIf
				Else
					$g_bIsDevMode = False
					_ToggleTechRoom($GUI_HIDE)
					_ToggleConfigControlsState(False)
					GUICtrlSetData($g_hButton_Unlock, "🔐 MỞ KHÓA")
					GUICtrlSetBkColor($g_hButton_Unlock, 0xFF4141)
				EndIf

			Case $g_hCheckbox_ToggleScan
				_ToggleScanHotkey()

			Case $g_hCheckbox_XocDiaVIP, $g_hCheckbox_BaccaratLaser
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
				_ToggleGameModeUI()

			Case $g_hButton_GetBankerPos
				_GetCoords_Fast($g_hInput_BankerX, $g_hInput_BankerY)
			Case $g_hButton_GetPlayerPos
				_GetCoords_Fast($g_hInput_PlayerX, $g_hInput_PlayerY)
			Case $g_hButton_GetTiePos
				_GetCoords_Fast($g_hInput_TieX, $g_hInput_TieY)
			Case $g_hButton_GetResultTL
				_GetCoords_Fast($g_hInput_ResultX1, $g_hInput_ResultY1)
			Case $g_hButton_GetResultBR
				_GetCoords_Fast($g_hInput_ResultX2, $g_hInput_ResultY2)
			Case $g_hButton_GetBetTimeTL
				_GetCoords_Fast($g_hInput_BetTimeX1, $g_hInput_BetTimeY1)
			Case $g_hButton_GetBetTimeBR
				_GetCoords_Fast($g_hInput_BetTimeX2, $g_hInput_BetTimeY2)
			Case $g_hCombo_Profiles, $g_hCombo_Profiles_Main
				_HandleProfileChange($aMsg[0])
			Case $g_hCombo_QLV_Presets
				_HandleQLVPresetChange()
			Case $g_hButton_SaveQLV
				_SaveCustomQLV()
			Case $g_hButton_DeleteQLV
				_DeleteCustomQLV()
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
		EndSwitch

		For $i = 0 To 4
			If $aMsg[0] = $g_aButton_GetChipPos[$i] Then
				_GetCoords_Fast($g_aInput_ChipX[$i], $g_aInput_ChipY[$i])
			EndIf
		Next
	WEnd
EndFunc   ;==>_MainLoop

Func _ProcessGUIMessages()
	Local $aMsg = GUIGetMsg(1)

	Switch $aMsg[0]
		Case $GUI_EVENT_RESTORE
			WinActivate($g_hGUI)
			If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
				WinSetOnTop($g_hGUI, "", 1)
			Else
				WinSetOnTop($g_hGUI, "", 1)
				WinSetOnTop($g_hGUI, "", 0)
			EndIf

		Case $g_hCheckbox_PinTool
			If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
				WinSetOnTop($g_hGUI, "", 1)
				_UpdateStatus("📌 Đã ghim Tool nổi lên trên màn hình Game.")
			Else
				WinSetOnTop($g_hGUI, "", 0)
				_UpdateStatus("🔽 Đã gỡ ghim. Tool sẽ ẩn khi click vào Game.")
			EndIf

		Case $GUI_EVENT_CLOSE
			If $aMsg[1] = $g_hGUI Then
				Local $aPos = WinGetPos($g_hGUI)
				If IsArray($aPos) And $aPos[0] > -10000 Then
					IniWrite($g_sIniPath, "Settings", "WinX", $aPos[0])
					IniWrite($g_sIniPath, "Settings", "WinY", $aPos[1])
				EndIf
				_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
				Exit
			EndIf

		Case $g_hButton_Start
			If $g_bIsRunning Then _StopProcess()

		Case $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter
			_RefreshVolumeDisplay()
	EndSwitch
EndFunc   ;==>_ProcessGUIMessages

Func WM_COMMAND_Handler($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $lParam
	Local $iCmd = _WinAPI_HiWord($wParam)
	Local $iCtrlID = _WinAPI_LoWord($wParam)

	If $iCmd = 768 Then
		Switch $iCtrlID
			; 1. NHÓM Ô NHẬP TIỀN (Tự thêm dấu chấm phân cách hàng ngàn)
			Case $g_hInput_InitialCapital, $g_hInput_InitialBet, _
					$g_hInput_DailyTarget, $g_hInput_DailyTrailing, $g_hInput_DailyStopLoss, $g_hInput_XD_TargetProfit
				If Not $g_bIsFormatting Then
					$g_bIsFormatting = True
					Local $sText = GUICtrlRead($iCtrlID)

					If $sText <> "" And $sText <> "-" Then
						Local $bIsNegative = (StringLeft($sText, 1) == "-")
						Local $sRaw = StringRegExpReplace($sText, "[^0-9]", "")

						If $sRaw <> "" Then
							$sRaw = StringRegExpReplace($sRaw, "^0+(?!$)", "")
							Local $sNew = StringRegExpReplace($sRaw, '(\d)(?=(\d{3})+(?!\d))', '$1.')
							If $bIsNegative Then $sNew = "-" & $sNew

							If $sText <> $sNew Then
								GUICtrlSetData($iCtrlID, $sNew)
								Local $iLen = StringLen($sNew)
								GUICtrlSendMsg($iCtrlID, 0x00B1, $iLen, $iLen)
							EndIf
						EndIf
					EndIf

					If $iCtrlID == $g_hInput_InitialBet Then _UpdateXocDiaGridUI()
					$g_bIsFormatting = False
					$g_bNeedAutoSave = True
					$g_hAutoSaveTimer = TimerInit()
				EndIf

			; 2. NHÓM CẤU HÌNH TỌA ĐỘ, CÔNG THỨC & MA TRẬN XÓC ĐĨA
			Case $g_hInput_XD_Seq, $g_hInput_XD_MaxRows, $g_hInput_XD_Virtual, $g_hInput_XD_AntiKick, _
					$g_hInput_XD_JumpLoss, $g_hInput_XD_JumpWin, $g_hInput_CustomRules, $g_hInput_CustomQLV_Edit, _
					$g_hInput_BankerX, $g_hInput_BankerY, $g_hInput_PlayerX, $g_hInput_PlayerY, $g_hInput_TieX, $g_hInput_TieY, _
					$g_hInput_ResultX1, $g_hInput_ResultY1, $g_hInput_ResultX2, $g_hInput_ResultY2, _
					$g_hInput_BankerColor, $g_hInput_PlayerColor, $g_hInput_TieColor, $g_hInput_Shade_Result, _
					$g_hInput_BetTimeColor, $g_hInput_BetTimeX1, $g_hInput_BetTimeY1, $g_hInput_BetTimeX2, $g_hInput_BetTimeY2, $g_hInput_Shade_Timer, _
					$g_hInput_LimitBtnX, $g_hInput_LimitBtnY, $g_hInput_Limit10_500X, $g_hInput_Limit10_500Y, $g_hInput_Limit20_50KX, $g_hInput_Limit20_50KY, $g_hInput_LimitConfirmX, $g_hInput_LimitConfirmY
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
				If $iCtrlID == $g_hInput_XD_Seq Or $iCtrlID == $g_hInput_XD_MaxRows Or $iCtrlID == $g_hInput_XD_Virtual Then _UpdateXocDiaGridUI()

			; 3. NHÓM NÚT DỪNG / NGHỈ
			Case $g_hRadio_Action_Stop, $g_hRadio_Action_PauseMin, $g_hRadio_Action_PauseHand, $g_hInput_Action_PauseMin, $g_hInput_Action_PauseHand
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
		EndSwitch
	ElseIf $iCmd = 0 Then
		If $iCtrlID == $g_hRadio_XD_RealKeep Or $iCtrlID == $g_hRadio_XD_DemoKeep Or _
				$iCtrlID == $g_hRadio_XD_MultiRow Or $iCtrlID == $g_hRadio_XD_SingleRow Or _
				$iCtrlID == $g_hCheckbox_XD_AntiKick Or $iCtrlID == $g_hCheckbox_XD_ShareDebt Or $iCtrlID == $g_hCheckbox_XD_AutoResetDebt Then
			If $iCtrlID == $g_hRadio_XD_SingleRow And GUICtrlRead($g_hRadio_XD_SingleRow) == $GUI_CHECKED Then
				$g_iCurrentTier = 1
			EndIf
			$g_bNeedAutoSave = True
			$g_hAutoSaveTimer = TimerInit()
			_UpdateXocDiaGridUI()
		ElseIf $iCtrlID == $g_hBtn_XD_StreakDetail Then
			AdlibRegister("_ShowStreakCacheDetail_Deferred", 50)
		EndIf
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND_Handler

Func _StartProcess()
	If Not _GetAndValidateInputs() Then Return

	_ApplyCurrentSettings()
	$g_hSessionTimer = TimerInit()
	_SendActivityLog("Start")

	$g_bIsRunning = True
	_SetControlsState(False)

	ReDim $g_aDisplayHistory[0]
	$g_iHistoryCutoffIndex = 0
	$g_iTotalBanker = 0
	$g_iTotalPlayer = 0
	$g_iTotalTie = 0
	$g_fTotalProfit = 0
	$g_iCapitalLevel = 0
	$g_iCustomSeqStep = 0
	$g_iLastActiveRuleIndex = -1
	$g_iXD_NoBetCount = 0
	$g_fXD_CycleProfit = 0
	$g_fXD_AmortizePool = 0

	_RedrawHistory()
	_UpdateBPTTotalsLabels()
	_UpdateTotalHandsLabel()

	Local $hGameWin = $g_hTargetGameWin
	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		$hGameWin = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hGameWin
	EndIf

; =========================================================================
	; [LUỒNG 1]: XÓC ĐĨA VIP - QUÉT POPUP LASER & MA TRẬN ĐA TẦNG
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		For $i = 1 To 10
			$g_aTierStep[$i] = 1
			$g_aXD_RowLoss[$i] = 0
		Next
		$g_iCurrentTier = 1
		$g_iXD_LossStreakInRow = 0
		$g_iXD_WinStreakInRow = 0
		$g_bXD_SplitUsed = False
		$g_iXD_CurLossStreak_Cache = 0
		_UpdateXocDiaGridUI()

		_UpdateStatus("🚀 XÓC ĐĨA VIP: Khóa tia Laser chờ Popup kết quả...")
		While $g_bIsRunning
			_ProcessGUIMessages()
			If _CheckProfitLossTargets() Then ExitLoop

			Local $sNewResult = _WaitPopupAppear_Laser()
			If $sNewResult == "" Then ContinueLoop

			If $sNewResult == "B" Then $sNewResult = "C"
			If $sNewResult == "P" Then $sNewResult = "L"
			If $sNewResult == "T" Then ContinueLoop

			_UpdateStatus("⚡ Tia Laser chộp được: [" & $sNewResult & "]. Đang phân tích Ma Trận...")

			If $g_sLastBetOn <> "" Then
				_ProcessBetOutcome($sNewResult, $g_sLastBetOn)
				$g_sLastBetOn = ""
			Else
				_ProcessObservation($sNewResult)
			EndIf

			Local $aAction = _DecideNextAction()
			If $aAction[0] == "BET" Then
				Local $sBetOn = $aAction[1]
				$g_fCurrentBet = $aAction[2] ; Tiền tính số liệu chuẩn theo Ma Trận
				Local $bIsDemoNow = (GUICtrlRead($g_hRadio_XD_DemoKeep) == $GUI_CHECKED)

				; Nếu không cần rải phỉnh thật xuống mặt bàn
				If $g_fTableClickBet <= 0 Then
					$g_sLastBetOn = $sBetOn
				Else
					; Ở chế độ Demo, luôn khóa cửa cược trước để không bao giờ bị kẹt/bỏ lỡ nhịp Ma Trận
					If $bIsDemoNow Then $g_sLastBetOn = $sBetOn

					Local $bTimerFound = False
					Local $iWaitTimer = TimerInit()
					While $g_bIsRunning
						If _IsBetTimeOpen() Then
							$bTimerFound = True
							ExitLoop
						EndIf
						_ProcessGUIMessages()
						Sleep(20)
						If TimerDiff($iWaitTimer) > 25000 Then ExitLoop
					WEnd

					If $g_bIsRunning And $bTimerFound Then
						Local $fChipToClick = $g_fTableClickBet
						_PerformBet($sBetOn, $fChipToClick)
						$g_fTableClickBet = $fChipToClick
						If Not $bIsDemoNow And $g_fCurrentBet > 0 Then
							$g_fCurrentBet = $fChipToClick
						EndIf
					Else
						If $bIsDemoNow Then
							$g_fTableClickBet = 0
							$g_iXD_NoBetCount = 0
							_UpdateStatus("⚠️ [DEMO] Không thấy đèn Giờ Cược để rải mồi giữ ghế, vẫn tính nhịp Ma Trận bình thường.")
						Else
							; Nếu đang ở bước Nháp 0đ mà chỉ lỡ nhịp giữ ghế thì vẫn chấm kết quả bước Nháp
							If $g_fCurrentBet <= 0 Then $g_sLastBetOn = $sBetOn
							$g_fTableClickBet = 0
							_UpdateStatus("⛔ Bỏ lỡ ván: Hết giờ cược.")
						EndIf
					EndIf
				EndIf
			EndIf

			_WaitPopupDisappear_Laser()
		WEnd
		_StopProcess()
		Return
	EndIf

	; =========================================================================
	; [LUỒNG 2]: BACCARAT - QUÉT VÙNG KẾT QUẢ POPUP LASER
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_BaccaratLaser) == $GUI_CHECKED Then
		_UpdateStatus("🚀 BACCARAT LASER: Khóa tia Laser rình Popup KQ...")
		While $g_bIsRunning
			_ProcessGUIMessages()
			If _CheckProfitLossTargets() Then ExitLoop

			Local $sNewResult = _WaitPopupAppear_Laser()
			If $sNewResult == "" Then ContinueLoop

			_UpdateStatus("⚡ Tia Laser chộp được: [" & $sNewResult & "]. Phân tích...")

			If $g_sLastBetOn <> "" Then
				_ProcessBetOutcome($sNewResult, $g_sLastBetOn)
				$g_sLastBetOn = ""
			Else
				_ProcessObservation($sNewResult)
			EndIf

			Local $aAction = _DecideNextAction()
			If $aAction[0] == "BET" Then
				Local $sBetOn = $aAction[1]
				Local $iBetUnits = $aAction[2]
				$g_fCurrentBet = $g_fInitialBet * $iBetUnits
				_UpdateStatus("🔥 Lệnh " & $g_iCapitalLevel & ": Đánh " & $sBetOn & ". Chờ Giờ Cược...")

				Local $bTimerFound = False
				Local $iWaitTimer = TimerInit()
				While $g_bIsRunning
					If _IsBetTimeOpen() Then
						$bTimerFound = True
						ExitLoop
					EndIf
					_ProcessGUIMessages()
					Sleep(20)
					If TimerDiff($iWaitTimer) > 40000 Then ExitLoop
				WEnd

				If $g_bIsRunning And $bTimerFound Then
					_PerformBet($sBetOn, $g_fCurrentBet)
				Else
					_UpdateStatus("⛔ Bỏ lỡ ván: Hết giờ cược.")
				EndIf
			EndIf

			_WaitPopupDisappear_Laser()
		WEnd
		_StopProcess()
		Return
	EndIf

	; =========================================================================
	; [LUỒNG 3]: BACCARAT - QUÉT BẢNG CẦU KHỐI VẠN NĂNG (18x6)
	; =========================================================================
	_UpdateStatus("⏳ Đang chụp nguyên khối bảng cầu để làm mốc...")
	Local $sLastStableBoard = _ScanUniversalBeadPlate()

	If StringLen($sLastStableBoard) > 0 Then
		Local $aChars = StringSplit($sLastStableBoard, "")
		For $i = 1 To $aChars[0]
			_ArrayAdd($g_aDisplayHistory, $aChars[$i])
			_UpdateBPTTotals($aChars[$i])
		Next
		_UpdateTotalHandsLabel()
		_RedrawHistory()
		_UpdateStatus("✅ Đã nạp " & StringLen($sLastStableBoard) & " ván! Bắt đầu rình...")
	EndIf

	While $g_bIsRunning
		_ProcessGUIMessages()
		If _CheckProfitLossTargets() Then ExitLoop

		Local $sCurrentBoard = _ScanUniversalBeadPlate()
		If $sCurrentBoard == "" Then
			Sleep(50)
			ContinueLoop
		EndIf

		If $sCurrentBoard <> $sLastStableBoard Then
			Local $iLenCur = StringLen($sCurrentBoard)
			Local $iLenLast = StringLen($sLastStableBoard)

			If $iLenCur < ($iLenLast - 5) Then
				$sLastStableBoard = $sCurrentBoard
				ReDim $g_aDisplayHistory[0]
				$g_iHistoryCutoffIndex = 0
				$g_iTotalBanker = 0
				$g_iTotalPlayer = 0
				$g_iTotalTie = 0
				$g_iCapitalLevel = 0
				$g_iCustomSeqStep = 0
				$g_iLastActiveRuleIndex = -1
				_RedrawHistory()
				_UpdateBPTTotalsLabels()
				_UpdateTotalHandsLabel()
				_UpdateStatus("🔄 Dealer đổi hộp bài mới! Đã dọn sạch bảng.")
				Sleep(2000)
				ContinueLoop
			EndIf

			If $iLenCur < $iLenLast Then
				Sleep(50)
				ContinueLoop
			EndIf

			Local $sNewResult = StringRight($sCurrentBoard, 1)
			$sLastStableBoard = $sCurrentBoard

			If $g_sLastBetOn <> "" Then
				_ProcessBetOutcome($sNewResult, $g_sLastBetOn)
				$g_sLastBetOn = ""
			Else
				_ProcessObservation($sNewResult)
			EndIf

			_ProcessGUIMessages()
			_UpdateStatus("⚡ Vừa ra: [" & $sNewResult & "]. Phân tích...")

			Local $aAction = _DecideNextAction()
			If $aAction[0] == "BET" Then
				Local $sBetOn = $aAction[1]
				Local $iBetUnits = $aAction[2]
				$g_fCurrentBet = $g_fInitialBet * $iBetUnits
				_UpdateStatus("🔥 Lệnh " & $g_iCapitalLevel & ": Đánh " & $sBetOn & ". Chờ Giờ Cược...")

				Local $bTimerFound = False
				Local $iWaitTimer = TimerInit()
				While $g_bIsRunning
					If _IsBetTimeOpen() Then
						$bTimerFound = True
						ExitLoop
					EndIf
					_ProcessGUIMessages()
					Sleep(20)
					If TimerDiff($iWaitTimer) > 40000 Then ExitLoop
				WEnd

				If $g_bIsRunning And $bTimerFound Then
					_PerformBet($sBetOn, $g_fCurrentBet)
				Else
					_UpdateStatus("⛔ Bỏ lỡ ván: Hết giờ cược.")
				EndIf
			EndIf
		EndIf
		Sleep(50)
	WEnd
	_StopProcess()
EndFunc   ;==>_StartProcess

Func _StopProcess()
	$g_bIsRunning = False
	$g_bManualStopped = True
	_UpdateStatus("🛑 Đã dừng Tool và chốt Lợi nhuận vào Số dư!")

	If $g_fTotalProfit <> 0 Then
		$g_fInitialCapital += $g_fTotalProfit
		GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))
	EndIf

	$g_fTotalProfit = 0
	$g_iCapitalLevel = 0
	$g_iCustomSeqStep = 0
	$g_iLastActiveRuleIndex = -1
	$g_fXD_CycleProfit = 0
	$g_iXD_NoBetCount = 0
	$g_fXD_AmortizePool = 0
	For $i = 0 To UBound($g_aRuleLevels) - 1
		$g_aRuleLevels[$i] = 0
	Next

	For $i = 1 To 10
		$g_aTierStep[$i] = 1
	Next
	$g_iCurrentTier = 1

	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_UpdateXocDiaGridUI()
	EndIf

	_UpdateProfitLabel()
	_UpdateBalanceLabel()
	_UpdateTotalVolumeLabel()

	_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))

	_SetControlsState(True)
	GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
	GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
EndFunc   ;==>_StopProcess

Func _HaltProcess($sReason)
	_SendActivityLog("Stop", $sReason, Round(TimerDiff($g_hSessionTimer) / 1000, 0))
	_UpdateStatus($sReason)
	_StopProcess()

	If $g_sMyTableID <> "" Then
		Local $sFile = @TempDir & "\status_" & $g_sMyTableID & ".ini"
		IniWrite($sFile, "Status", "State", "MANUAL_STOP")
	EndIf
EndFunc   ;==>_HaltProcess

Func _StopAndSaveSession()
	If $g_fTotalProfit <> 0 Then
		$g_fInitialCapital += $g_fTotalProfit
		GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))
	EndIf
	$g_fTotalProfit = 0
	$g_iCapitalLevel = 0
	$g_iCustomSeqStep = 0
	$g_iLastActiveRuleIndex = -1
	$g_fPeakProfit = 0
	$g_bIsTrailingMode = False
	$g_fXD_CycleProfit = 0
	$g_fXD_AmortizePool = 0
	For $i = 0 To UBound($g_aRuleLevels) - 1
		$g_aRuleLevels[$i] = 0
	Next
	For $i = 1 To 10
		$g_aTierStep[$i] = 1
	Next
	$g_iCurrentTier = 1

	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_UpdateXocDiaGridUI()
	EndIf
	_UpdateProfitLabel()
	_UpdateBalanceLabel()
EndFunc   ;==>_StopAndSaveSession

Func _DecideNextAction()
	Local $aStop[3] = ["OBSERVE", "", 0]

	If $g_iTargetPauseEndTime <> 0 Then
		If TimerDiff($g_iTargetPauseEndTime) < $g_iTargetPauseDuration Then Return $aStop
		$g_iTargetPauseEndTime = 0
	EndIf
	If $g_iTargetPauseHands > 0 Then Return $aStop

	If $g_iCapitalLevel == 0 Then
		If _CheckProfitLossTargets() Then Return $aStop
	EndIf

	; 1. NẾU BẬT XÓC ĐĨA VIP -> RẼ NHÁNH VÀO BỘ MÁY XÓC ĐĨA VIP
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		$g_iLimitBtnX = Number(GUICtrlRead($g_hInput_LimitBtnX))
		$g_iLimitBtnY = Number(GUICtrlRead($g_hInput_LimitBtnY))
		$g_iLimit10_500X = Number(GUICtrlRead($g_hInput_Limit10_500X))
		$g_iLimit10_500Y = Number(GUICtrlRead($g_hInput_Limit10_500Y))
		$g_iLimit20_50KX = Number(GUICtrlRead($g_hInput_Limit20_50KX))
		$g_iLimit20_50KY = Number(GUICtrlRead($g_hInput_Limit20_50KY))
		$g_iLimitConfirmX = Number(GUICtrlRead($g_hInput_LimitConfirmX))
		$g_iLimitConfirmY = Number(GUICtrlRead($g_hInput_LimitConfirmY))

		Local $sHistoryRaw = _ArrayToString($g_aDisplayHistory, "")
		Return _Logic_XocDia_5Hang_VIP($sHistoryRaw)
	EndIf

	; 2. MẶC ĐỊNH: CHẠY BỘ MÁY CÔNG THỨC CUSTOM BACCARAT
	Local $aQLV = _GetQLV_Params($g_iCapitalLevel)
	Local $iTotalHands = UBound($g_aDisplayHistory)
	Return _Logic_Custom($iTotalHands, $aQLV[1], False)
EndFunc   ;==>_DecideNextAction

Func _ProcessObservation($sActualResult)
	If $sActualResult = "T" Then
		_UpdateStatus("⚠️ Kết quả HÒA (Tie) -> Bỏ qua...")
		_AddNewHistoryEntry($sActualResult)
		_RedrawHistory()
		Return
	EndIf

	$g_iXD_NoBetCount += 1 ; Đếm ván đứng nhìn lúc mới vào bàn để chống văng

	If $g_iTargetPauseHands > 0 Then
		$g_iTargetPauseHands -= 1
		If $g_iTargetPauseHands == 0 Then
			_UpdateStatus("✅ Đã trôi đủ ván nghỉ! Bắt đầu dò cầu chiến tiếp.")
		Else
			_UpdateStatus("⏳ Đang nghỉ giải lao... Chờ trôi thêm " & $g_iTargetPauseHands & " ván.")
		EndIf
	EndIf

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
EndFunc   ;==>_ProcessObservation

Func _ProcessBetOutcome($sActualResult, $sBetOn)
	Local $sStatsFile = @ScriptDir & "\stats_history.ini"
	Local $sCurrentGamingDate = _GetGamingDate()

	Local $sSavedGamingDate = IniRead($sStatsFile, "Global_Daily", "Date", "")
	If $sSavedGamingDate <> $sCurrentGamingDate Then
		$g_fTotalVolume = 0
		IniWrite($sStatsFile, "Global_Daily", "Date", $sCurrentGamingDate)
		IniWrite($sStatsFile, "Global_Daily", "Volume", "0")
		_UpdateTotalVolumeLabel()
	EndIf

	_AddNewHistoryEntry($sActualResult)
	_UpdateTotalHandsLabel()

	If $sActualResult = "T" Then
		_UpdateStatus("HÒA -> Giữ nguyên lệnh -> Đánh lại!")
		_RedrawHistory()
		Return
	EndIf

	Local $fProfitChange = 0

	; =========================================================================
	; 1. XỬ LÝ KẾT QUẢ CHO XÓC ĐĨA VIP
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_ProcessOutcome_XocDia_VIP($sActualResult, $sBetOn)

		If $sActualResult == $sBetOn Then
			$g_fTotalProfit += ($g_fCurrentBet * 0.95)
			$fProfitChange = ($g_fCurrentBet * 0.95)
		Else
			$g_fTotalProfit -= $g_fCurrentBet
			$fProfitChange = -$g_fCurrentBet
		EndIf

		If $g_fTotalProfit > $g_fPeakProfit Then $g_fPeakProfit = $g_fTotalProfit

		_UpdateProfitLabel()
		_UpdateBalanceLabel()
		_RedrawHistory()
		If $g_fCurrentBet > 0 Then _UpdateDailyStats($g_fCurrentBet, $fProfitChange)
		_SyncLiveDashboard($g_fInitialCapital + $g_fTotalProfit, $g_fTotalProfit, Number(IniRead(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), "0")))
		Return
	EndIf

	; =========================================================================
	; 2. XỬ LÝ KẾT QUẢ CHO BACCARAT
	; =========================================================================
	Local $bSepQLV = (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED)
	Local $iCurrentLvl = ($bSepQLV And $g_iLastActiveRuleIndex > -1 And $g_iLastActiveRuleIndex < UBound($g_aRuleLevels)) ? $g_aRuleLevels[$g_iLastActiveRuleIndex] : $g_iCapitalLevel
	Local $aQLV = _GetQLV_Params($iCurrentLvl)
	Local $bReverseLogic = (GUICtrlRead($g_hCheckbox_ReverseLogic) = $GUI_CHECKED)
	Local $iSavedActiveIndex = $g_iLastActiveRuleIndex

	If $sActualResult = $sBetOn Then
		If $sActualResult = "B" Then
			$g_fTotalProfit += ($g_fCurrentBet * 0.95)
			$fProfitChange = ($g_fCurrentBet * 0.95)
		Else
			$g_fTotalProfit += $g_fCurrentBet
			$fProfitChange = $g_fCurrentBet
		EndIf

		If $g_fTotalProfit > $g_fPeakProfit Then $g_fPeakProfit = $g_fTotalProfit

		If $bReverseLogic Then
			If $g_iLastActiveRuleIndex > -1 Then $g_iCustomSeqStep += 1
			$g_iCapitalLevel = $aQLV[2]
			_UpdateStatus("WIN! (Bám Chuỗi) -> Lên Lv " & $aQLV[2])
		Else
			$g_iLastActiveRuleIndex = -1
			$g_iCustomSeqStep = 0
			$g_iCapitalLevel = $aQLV[2]
			$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
			_UpdateStatus("WIN! -> Cắt cầu -> Chờ tín hiệu mới.")
		EndIf
	Else
		$g_fTotalProfit -= $g_fCurrentBet
		$fProfitChange = -$g_fCurrentBet

		If $bReverseLogic Then
			$g_iLastActiveRuleIndex = -1
			$g_iCustomSeqStep = 0
			$g_iCapitalLevel = $aQLV[3]
			$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
			_UpdateStatus("LOSS! (Bám Chuỗi) -> Cắt cầu -> Về Lv " & $aQLV[3])
		Else
			If $g_iLastActiveRuleIndex > -1 Then $g_iCustomSeqStep += 1
			$g_iCapitalLevel = $aQLV[3]
			_UpdateStatus("LOSS! -> Lên Lv " & $aQLV[3])
		EndIf
	EndIf

	If $bSepQLV And $iSavedActiveIndex > -1 Then
		$g_aRuleLevels[$iSavedActiveIndex] = $g_iCapitalLevel
	EndIf

	_UpdateProfitLabel()
	_UpdateBalanceLabel()
	_RedrawHistory()

	_UpdateDailyStats($g_fCurrentBet, $fProfitChange)
	_SyncLiveDashboard($g_fInitialCapital + $g_fTotalProfit, $g_fTotalProfit, Number(IniRead(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), "0")))
EndFunc   ;==>_ProcessBetOutcome
#EndRegion 5. VÒNG LẶP SỰ KIỆN & ĐIỀU PHỐI TIẾN TRÌNH CHẠY

; ==================================================================================================
#Region 6. BỘ MÁY BACCARAT (CÔNG THỨC CUSTOM, QLV LINH HOẠT, QUÉT BẢNG KHỐI & LASER)
; ==================================================================================================
Func _Logic_Custom($iTotalHands, $iBetUnit_Global, $bContinuous_Param)
	#forceref $iTotalHands, $iBetUnit_Global, $bContinuous_Param
	Local $aResult[3] = ["OBSERVE", "", 0]

	Local $sHistoryRaw = ""
	Local $iStart = 0
	If $g_iHistoryCutoffIndex <= UBound($g_aDisplayHistory) Then
		$iStart = $g_iHistoryCutoffIndex
	EndIf

	For $i = $iStart To UBound($g_aDisplayHistory) - 1
		$sHistoryRaw &= $g_aDisplayHistory[$i]
	Next
	Local $sHistoryNow = StringReplace($sHistoryRaw, "T", "")

	Local $bSepQLV = (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED)

	Local $sRulesRaw = StringStripWS(GUICtrlRead($g_hInput_CustomRules), 3)
	$sRulesRaw = StringReplace($sRulesRaw, @CRLF, @LF)
	Local $aLines = StringSplit($sRulesRaw, @LF)

	If $bSepQLV And UBound($g_aRuleLevels) < ($aLines[0] + 5) Then
		ReDim $g_aRuleLevels[$aLines[0] + 10]
	EndIf

	If $g_iLastActiveRuleIndex > -1 Then
		Local $iIdx = $g_iLastActiveRuleIndex
		Local $iLevel = 0

		If $bSepQLV Then
			If $iIdx < UBound($g_aRuleLevels) Then $iLevel = $g_aRuleLevels[$iIdx]
		Else
			$iLevel = $g_iCapitalLevel
		EndIf

		If ($iIdx + 1) <= $aLines[0] Then
			Local $sLine = StringStripWS($aLines[$iIdx + 1], 8)
			Local $aParts = StringSplit($sLine, "-")
			Local $sBetSeq = ""

			If $aParts[0] >= 2 Then
				$sBetSeq = $aParts[2]
			Else
				$sBetSeq = StringRight($sLine, 1)
			EndIf

			If $g_iCustomSeqStep <= StringLen($sBetSeq) And $g_iCustomSeqStep > 0 Then
				Local $sCharToBet = StringMid($sBetSeq, $g_iCustomSeqStep, 1)
				Local $aQLV = _GetQLV_Params($iLevel)

				$aResult[0] = "BET"
				$aResult[1] = $sCharToBet
				$aResult[2] = $aQLV[1]

				_UpdateStatus("🔥 Đang theo dòng " & ($iIdx + 1) & " (Bước " & $g_iCustomSeqStep & "/" & StringLen($sBetSeq) & "): Đánh " & $sCharToBet)
				Return $aResult
			Else
				$g_iLastActiveRuleIndex = -1
				$g_iCustomSeqStep = 0
				$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
				_UpdateStatus("⛔ Hết chuỗi lệnh -> Cắt cầu lịch sử -> Chờ tín hiệu mới.")
			EndIf
		EndIf
	EndIf

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
		If $sHistoryNow = "" Then ContinueLoop

		If StringRight($sHistoryNow, StringLen($sWaitSig)) = $sWaitSig Then
			Local $iMyLevel = 0
			If $bSepQLV Then
				If ($i - 1) < UBound($g_aRuleLevels) Then $iMyLevel = $g_aRuleLevels[$i - 1]
			Else
				$iMyLevel = $g_iCapitalLevel
			EndIf

			Local $aQLV = _GetQLV_Params($iMyLevel)

			$g_iCustomSeqStep = 1
			Local $sFirstChar = StringMid($sBetSeq, 1, 1)

			$aResult[0] = "BET"
			$aResult[1] = $sFirstChar
			$aResult[2] = $aQLV[1]

			$g_iLastActiveRuleIndex = $i - 1

			_UpdateStatus("🎯 Khớp dòng " & $i & ": [" & $sWaitSig & "] -> Bắt đầu dây (Bước 1): " & $sFirstChar)
			Return $aResult
		EndIf
	Next

	If $g_iHistoryCutoffIndex > 0 Then
		_UpdateStatus("⏳ Đã cắt cầu. Chờ tín hiệu mới (" & StringLen($sHistoryNow) & " tay)...")
	Else
		_UpdateStatus("⏳ Đang dò tín hiệu (Custom)...")
	EndIf

	Return $aResult
EndFunc   ;==>_Logic_Custom

Func _GetQLV_Params($iLevel)
	If UBound($g_aCustomQLVTable) = 0 Then
		Local $aDefault[4] = [0, 1, 0, 0]
		Return $aDefault
	EndIf

	If $iLevel < 0 Or $iLevel >= UBound($g_aCustomQLVTable) Then
		$iLevel = 0
		$g_iCapitalLevel = 0
	EndIf

	Local $aResult[4]
	$aResult[0] = $g_aCustomQLVTable[$iLevel][0]
	$aResult[1] = $g_aCustomQLVTable[$iLevel][1]
	$aResult[2] = $g_aCustomQLVTable[$iLevel][2]
	$aResult[3] = $g_aCustomQLVTable[$iLevel][3]

	Return $aResult
EndFunc   ;==>_GetQLV_Params

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
EndFunc   ;==>_ParseCustomQLVTable

Func _FindQLVCommandInfo($iCommandToFind)
	For $i = 0 To UBound($g_aCustomQLVTable) - 1
		If $g_aCustomQLVTable[$i][0] = $iCommandToFind Then
			Return $i
		EndIf
	Next
	Return -1
EndFunc   ;==>_FindQLVCommandInfo

Func _PopulateQLVList()
	Local $aUserPresets = IniReadSection($g_sIniPath, "UserQLV")
	Local $sList = "Tùy chỉnh"

	If Not @error Then
		For $i = 1 To $aUserPresets[0][0]
			$sList &= "|" & $aUserPresets[$i][0]
		Next
	EndIf

	Local $sCurrent = GUICtrlRead($g_hCombo_QLV_Presets)
	GUICtrlSetData($g_hCombo_QLV_Presets, "", "")
	GUICtrlSetData($g_hCombo_QLV_Presets, $sList, $sCurrent)
EndFunc   ;==>_PopulateQLVList

Func _HandleQLVPresetChange()
	Local $sSelectedPreset = GUICtrlRead($g_hCombo_QLV_Presets)
	If $sSelectedPreset = "Tùy chỉnh" Then Return

	Local $sQLV_String = IniRead($g_sIniPath, "UserQLV", $sSelectedPreset, "")
	If $sQLV_String <> "" Then
		GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace($sQLV_String, "|NL|", @CRLF))
	EndIf
EndFunc   ;==>_HandleQLVPresetChange

Func _SaveCustomQLV()
	Local $sCurrentContent = GUICtrlRead($g_hInput_CustomQLV_Edit)
	If $sCurrentContent = "" Then Return

	Local $sName = InputBox("Lưu/Sửa Mẫu QLV", "Đặt tên cho mẫu (nhập tên cũ để ghi đè):", "", "", 250, 130)
	If @error Or $sName = "" Then Return

	Local $sContentToSave = StringReplace($sCurrentContent, @CRLF, "|NL|")
	IniWrite($g_sIniPath, "UserQLV", $sName, $sContentToSave)

	MsgBox(64, "Thành công", "Đã lưu mẫu QLV: '" & $sName & "'.")
	_PopulateQLVList()
	GUICtrlSetData($g_hCombo_QLV_Presets, $sName)
EndFunc   ;==>_SaveCustomQLV

Func _DeleteCustomQLV()
	Local $sSelected = GUICtrlRead($g_hCombo_QLV_Presets)
	If $sSelected = "Tùy chỉnh" Or $sSelected = "" Then
		MsgBox(48, "Lỗi", "Vui lòng chọn một mẫu cụ thể để xóa.")
		Return
	EndIf

	If MsgBox(36, "Xác nhận Xóa", "Bạn có chắc chắn muốn xóa vĩnh viễn mẫu '" & $sSelected & "' không?") = 6 Then
		IniDelete($g_sIniPath, "UserQLV", $sSelected)
		MsgBox(64, "Đã xóa", "Đã xóa mẫu '" & $sSelected & "'.")
		_PopulateQLVList()
		GUICtrlSetData($g_hCombo_QLV_Presets, "Tùy chỉnh")
		GUICtrlSetData($g_hInput_CustomQLV_Edit, "")
	EndIf
EndFunc   ;==>_DeleteCustomQLV

Func _EnsureDefaultQLVExists()
	Local $aData = IniReadSection($g_sIniPath, "UserQLV")
	If @error Or $aData[0][0] = 0 Then
		IniWrite($g_sIniPath, "UserQLV", "Gấp thếp (Martingale)", "0-1-0-1|NL|1-2-0-2|NL|2-4-0-3|NL|3-8-0-4|NL|4-16-0-5|NL|5-32-0-6|NL|6-64-0-0")
		IniWrite($g_sIniPath, "UserQLV", "Gấp thếp ngược (Thắng)", "0-1-1-0|NL|1-2-2-0|NL|2-4-3-0|NL|3-8-4-0|NL|4-16-5-0|NL|5-32-6-0|NL|6-64-0-0")
		IniWrite($g_sIniPath, "UserQLV", "Fibonacci", "0-1-0-1|NL|1-1-0-2|NL|2-2-1-3|NL|3-3-2-4|NL|4-5-3-5|NL|5-8-4-6|NL|6-13-5-7|NL|7-21-6-8|NL|8-34-7-9|NL|9-55-8-0")
		IniWrite($g_sIniPath, "UserQLV", "D'Alembert", "0-1-0-1|NL|1-2-0-2|NL|2-3-1-3|NL|3-4-2-4|NL|4-5-3-5|NL|5-6-4-6|NL|6-7-5-7|NL|7-8-6-8|NL|8-9-7-9|NL|9-10-8-0")
		IniWrite($g_sIniPath, "UserQLV", "An toàn (Thua 2 nghỉ)", "0-1-0-1|NL|1-1-0-2|NL|2-0-0-0")
		_PopulateQLVList()
	EndIf
EndFunc   ;==>_EnsureDefaultQLVExists

; --- QUÉT BẢNG KHỐI VẠN NĂNG (18x6) & LASER POPUP ---
Func _ScanUniversalBeadPlate()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

	Local $sHistory = ""
	Local $iStartX = Number(GUICtrlRead($g_hInput_ResultX1))
	Local $iStartY = Number(GUICtrlRead($g_hInput_ResultY1))
	Local $iX2 = Number(GUICtrlRead($g_hInput_ResultX2))
	Local $iY2 = Number(GUICtrlRead($g_hInput_ResultY2))

	If $iStartX = 0 Or $iX2 = 0 Then Return ""

	Local $fOffsetX = ($iX2 - $iStartX) / ($g_iGridCols_Max - 1)
	Local $fOffsetY = ($iY2 - $iStartY) / ($g_iGridRows_Max - 1)

	Local $iColRed = Number(GUICtrlRead($g_hInput_BankerColor))
	Local $iColBlue = Number(GUICtrlRead($g_hInput_PlayerColor))
	Local $iColGreen = Number(GUICtrlRead($g_hInput_TieColor))
	Local $iShade = Number(GUICtrlRead($g_hInput_Shade_Result))
	If $iShade < 40 Then $iShade = 20

	Local $iEmptyCount = 0

	For $c = 0 To ($g_iGridCols_Max - 1)
		For $r = 0 To ($g_iGridRows_Max - 1)
			Local $iCX = $iStartX + ($c * $fOffsetX)
			Local $iCY = $iStartY + ($r * $fOffsetY)

			Local $aPoints[5][2] = [[$iCX, $iCY], [$iCX, $iCY - 4], [$iCX, $iCY + 4], [$iCX - 4, $iCY], [$iCX + 4, $iCY]]
			Local $bFoundRed = False, $bFoundBlue = False, $bFoundGreen = False

			For $p = 0 To 4
				Local $iColor = PixelGetColor($aPoints[$p][0], $aPoints[$p][1], $hWnd)
				If _CheckColorRange($iColor, $iColRed, $iShade) Then
					$bFoundRed = True
					ExitLoop
				ElseIf _CheckColorRange($iColor, $iColBlue, $iShade) Then
					$bFoundBlue = True
					ExitLoop
				ElseIf _CheckColorRange($iColor, $iColGreen, $iShade) Then
					$bFoundGreen = True
					ExitLoop
				EndIf
			Next

			If $bFoundRed Then
				$sHistory &= "B"
				$iEmptyCount = 0
			ElseIf $bFoundBlue Then
				$sHistory &= "P"
				$iEmptyCount = 0
			ElseIf $bFoundGreen Then
				$sHistory &= "T"
				$iEmptyCount = 0
			Else
				$iEmptyCount += 1
				If $iEmptyCount >= 3 Then Return $sHistory
			EndIf
		Next
	Next
	Return $sHistory
EndFunc   ;==>_ScanUniversalBeadPlate

Func _WaitPopupAppear_Laser()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

	Local $iX1 = $g_aResultArea[0]
	Local $iY1 = $g_aResultArea[1]
	Local $iX2 = $g_aResultArea[2]
	Local $iY2 = $g_aResultArea[3]

	Local $iColRed = Number(GUICtrlRead($g_hInput_BankerColor))
	Local $iColBlue = Number(GUICtrlRead($g_hInput_PlayerColor))
	Local $iColGreen = Number(GUICtrlRead($g_hInput_TieColor))
	Local $iShade = Number(GUICtrlRead($g_hInput_Shade_Result))

	_UpdateStatus("📡 [HỆ THỐNG] Đang giám sát vùng kết quả. Chờ tín hiệu ván mới...")

	While $g_bIsRunning
		_ProcessGUIMessages()

		If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColBlue, $iShade, 1, $hWnd)) Then Return "P"
		If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColRed, $iShade, 1, $hWnd)) Then Return "B"

		If GUICtrlRead($g_hCheckbox_XocDiaVIP) <> $GUI_CHECKED Then
			If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColGreen, $iShade, 1, $hWnd)) Then Return "T"
		EndIf

		Sleep(20)
	WEnd
	Return ""
EndFunc   ;==>_WaitPopupAppear_Laser

Func _WaitPopupDisappear_Laser()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return False

	Local $iX1 = $g_aResultArea[0]
	Local $iY1 = $g_aResultArea[1]
	Local $iX2 = $g_aResultArea[2]
	Local $iY2 = $g_aResultArea[3]

	Local $iColRed = Number(GUICtrlRead($g_hInput_BankerColor))
	Local $iColBlue = Number(GUICtrlRead($g_hInput_PlayerColor))
	Local $iColGreen = Number(GUICtrlRead($g_hInput_TieColor))

	Local $iShade = Number(GUICtrlRead($g_hInput_Shade_Result))
	If $iShade > 25 Then $iShade = 25

	_UpdateStatus("🧹 [SYSTEM] Bài đang hiển thị. Đợi thu dọn bàn sạch sẽ để chốt vòng lặp...")

	Local $hDisappearTimer = TimerInit()
	Local $bIsXocDia = (GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED)

	While $g_bIsRunning
		_ProcessGUIMessages()
		Local $bStillThere = False

		If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColBlue, $iShade, 1, $hWnd)) Then $bStillThere = True
		If Not $bStillThere And IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColRed, $iShade, 1, $hWnd)) Then $bStillThere = True

		If Not $bIsXocDia And Not $bStillThere Then
			If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColGreen, $iShade, 1, $hWnd)) Then $bStillThere = True
		EndIf

		If $bStillThere Then
			$hDisappearTimer = TimerInit()
		Else
			If TimerDiff($hDisappearTimer) > 1000 Then Return True
		EndIf

		Sleep(50)
	WEnd
	Return False
EndFunc   ;==>_WaitPopupDisappear_Laser

Func _IsBetTimeOpen()
	Local $iX1 = $g_aBetTimeIndicatorArea[0]
	Local $iY1 = $g_aBetTimeIndicatorArea[1]
	Local $iX2 = $g_aBetTimeIndicatorArea[2]
	Local $iY2 = $g_aBetTimeIndicatorArea[3]

	Local $iLeft = ($iX1 > $iX2) ? $iX2 : $iX1
	Local $iRight = ($iX1 > $iX2) ? $iX1 : $iX2
	Local $iTop = ($iY1 > $iY2) ? $iY2 : $iY1
	Local $iBottom = ($iY1 > $iY2) ? $iY1 : $iY2

	Local $iTolerance = Number(GUICtrlRead($g_hInput_Shade_Timer))
	If $iTolerance < 40 Then $iTolerance = 40

	Local $aSearch = PixelSearch($iLeft, $iTop, $iRight, $iBottom, $g_iBetTimeIndicatorColor, $iTolerance, 3)
	Return IsArray($aSearch)
EndFunc   ;==>_IsBetTimeOpen

Func _CheckColorRange($iColor, $iTarget, $iShade)
	Local $r1 = BitAND(BitShift($iColor, 16), 0xFF), $g1 = BitAND(BitShift($iColor, 8), 0xFF), $b1 = BitAND($iColor, 0xFF)
	Local $r2 = BitAND(BitShift($iTarget, 16), 0xFF), $g2 = BitAND(BitShift($iTarget, 8), 0xFF), $b2 = BitAND($iTarget, 0xFF)
	If Abs($r1 - $r2) <= $iShade And Abs($g1 - $g2) <= $iShade And Abs($b1 - $b2) <= $iShade Then Return True
	Return False
EndFunc   ;==>_CheckColorRange

Func _DebugGrid()
	Local $iStartX = Number(GUICtrlRead($g_hInput_ResultX1))
	Local $iStartY = Number(GUICtrlRead($g_hInput_ResultY1))
	Local $iX2 = Number(GUICtrlRead($g_hInput_ResultX2))
	Local $iY2 = Number(GUICtrlRead($g_hInput_ResultY2))

	If $iStartX = 0 Or $iX2 = 0 Then
		MsgBox(48, "Lỗi Debug", "Sếp chưa lấy tọa độ X1, Y1 và X2, Y2 của vùng kết quả!")
		Return
	EndIf

	Local $fOffsetX = $iX2 - $iStartX
	Local $fOffsetY = $iY2 - $iStartY

	If $fOffsetX > 60 Then $fOffsetX = $fOffsetX / 17
	If $fOffsetY > 60 Then $fOffsetY = $fOffsetY / 5

	If $fOffsetX < 5 Or $fOffsetY < 5 Then
		MsgBox(48, "Lỗi Tọa Độ", "Khoảng cách lấy bị sai!")
		Return
	EndIf

	Local $iSampleDist = Round($fOffsetX * 0.20)
	If $iSampleDist < 3 Then $iSampleDist = 3

	Local $hDC = _WinAPI_GetDC(0)
	For $c = 0 To 18
		Local $iMaxRow = ($c == 18) ? 1 : 5
		For $r = 0 To $iMaxRow
			Local $iCX = $iStartX + ($c * $fOffsetX)
			Local $iCY = $iStartY + ($r * $fOffsetY)
			_DrawRedCross($hDC, $iCX - $iSampleDist, $iCY - $iSampleDist)
			_DrawRedCross($hDC, $iCX + $iSampleDist, $iCY + $iSampleDist)
		Next
	Next
	_WinAPI_ReleaseDC(0, $hDC)
EndFunc   ;==>_DebugGrid

Func _DrawRedCross($hDC, $x, $y)
	For $i = -2 To 2
		_WinAPI_SetPixel($hDC, $x + $i, $y, 0xFF0000)
		_WinAPI_SetPixel($hDC, $x, $y + $i, 0xFF0000)
	Next
EndFunc   ;==>_DrawRedCross
#EndRegion 6. BỘ MÁY BACCARAT (CÔNG THỨC CUSTOM, QLV LINH HOẠT, QUÉT BẢNG KHỐI & LASER)

; ==================================================================================================
#Region 7. BỘ MÁY XÓC ĐĨA VIP (MA TRẬN 3 TRONG 1, GIỮ BÀN & ĐỔI HẠN MỨC)
; ==================================================================================================
Func _Logic_XocDia_5Hang_VIP($sHistoryRaw)
	Local $aResult[3] = ["OBSERVE", "", 0]
	$g_fTableClickBet = 0
	Local $sHist = StringRegExpReplace($sHistoryRaw, "[^CL]", "")
	Local $iLen = StringLen($sHist)

	If $iLen < 4 Then
		_UpdateStatus("📡 [HỆ THỐNG] Đang lấy mẫu (" & $iLen & "/4 tay). Đã đứng nhìn: " & $g_iXD_NoBetCount & " ván.")
		Return $aResult
	EndIf

	Local $sTarget = StringMid($sHist, $iLen - 3, 1)
	Local $sKhung4Tay = StringRight($sHist, 4)
	_UpdateStatus("🎯 [PHÂN TÍCH] Khuôn 4 tay: [" & $sKhung4Tay & "] -> Đánh [" & $sTarget & "]")

	; Nếu chọn Đi 1 hàng duy nhất -> Luôn khóa chặt ở Hàng 1 (H1)
	Local $bIsSingleRow = (GUICtrlRead($g_hRadio_XD_SingleRow) == $GUI_CHECKED)
	If $bIsSingleRow Then $g_iCurrentTier = 1

	Local $iCurrentStep = $g_aTierStep[$g_iCurrentTier]
	Local $iMaxLimit = $g_aXD_MaxStepsPerRow[$g_iCurrentTier]

	If $iCurrentStep > $iMaxLimit Then
		_UpdateStatus("⚠️ [CẮT LỖ] Chạm mốc kịch kim " & $iMaxLimit & " bước của Hàng " & $g_iCurrentTier & "! Reset toàn bộ về H1 B1.")
		For $i = 1 To 10
			$g_aTierStep[$i] = 1
			$g_aXD_RowLoss[$i] = 0
		Next
		$g_iCurrentTier = 1
		$iCurrentStep = 1
		$g_iXD_LossStreakInRow = 0
		$g_iXD_WinStreakInRow = 0
		$g_fXD_CycleProfit = 0
		$g_fXD_AmortizePool = 0
		$g_bXD_SplitUsed = False
	EndIf

	Local $bIsDemoMode = (GUICtrlRead($g_hRadio_XD_DemoKeep) == $GUI_CHECKED)
	Local $bIsKeepTable = (GUICtrlRead($g_hCheckbox_XD_AntiKick) == $GUI_CHECKED)
	Local $iMatrixBet = $g_aXocDia_Seq[$g_iCurrentTier][$iCurrentStep]

	; 1. Tiền tính số liệu ($iStatsBet) luôn lấy 100% theo Ma Trận (cả Thật & Demo), tách rời hoàn toàn với tiền Giữ bàn
	Local $iStatsBet = $iMatrixBet
	$g_fTableClickBet = $bIsDemoMode ? 0 : $iMatrixBet
	Local $bIsAntiKickBet = False

	; 2. Kiểm tra ném phỉnh Giữ Bàn (Chỉ click phỉnh lên bàn để giữ ghế, KHÔNG cộng vào $iStatsBet)
	If $g_fTableClickBet == 0 And $bIsKeepTable Then
		Local $iAntiKickMax = Number(GUICtrlRead($g_hInput_XD_AntiKick))
		If $iAntiKickMax > 0 And ($g_iXD_NoBetCount + 1) >= $iAntiKickMax Then
			Local $fMinBet = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialBet), "\D", ""))
			If $fMinBet <= 0 Then $fMinBet = 10000
			$g_fTableClickBet = $fMinBet
			$bIsAntiKickBet = True
		EndIf
	EndIf

	$aResult[0] = "BET"
	$aResult[1] = $sTarget
	$aResult[2] = $iStatsBet

	; 3. Chỉ đổi hạn mức bàn khi thực sự có rải phỉnh xuống mặt bàn
	If $g_fTableClickBet > 0 Then
		If $g_fTableClickBet > 500000 Then
			_SwitchLimit_VIP("20-50K")
		Else
			_SwitchLimit_VIP("10-500")
		EndIf
	EndIf

	Local $sKeepStatus = $bIsKeepTable ? ("Nghỉ: " & ($g_iXD_NoBetCount + 1) & "/" & Number(GUICtrlRead($g_hInput_XD_AntiKick)) & " ván") : "Tắt giữ bàn"
	Local $sRowModeTag = $bIsSingleRow ? "1 HÀNG H1" : ("HÀNG " & $g_iCurrentTier)

	If $bIsDemoMode Then
		If $bIsAntiKickBet Then
			_UpdateStatus("🛡️ [DEMO - GIỮ BÀN] Rải mồi " & _FormatNumber($g_fTableClickBet) & "đ giữ ghế (Không tính số liệu) | Số liệu Demo: " & _FormatNumber($iStatsBet) & "đ vào [" & $sTarget & "]")
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $iCurrentStep & " [DEMO - GIỮ BÀN]" & @CRLF & "🛡️ Rải giữ ghế: " & _FormatNumber($g_fTableClickBet) & "đ | Số liệu: " & _FormatNumber($iStatsBet) & "đ [" & $sTarget & "]")
		Else
			_UpdateStatus("🧪 [ĐÁNH DEMO] " & $sRowModeTag & " (B" & $iCurrentStep & ") -> Số liệu tính: " & _FormatNumber($iStatsBet) & "đ vào [" & $sTarget & "] (" & $sKeepStatus & ")")
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $iCurrentStep & " [ĐÁNH DEMO]" & @CRLF & "🧪 Số liệu tính: " & _FormatNumber($iStatsBet) & "đ VÀO [" & $sTarget & "] (" & $sKeepStatus & ")")
		EndIf
	Else
		If $bIsAntiKickBet Then
			_UpdateStatus("🛡️ [THẬT - GIỮ BÀN] Đã nghỉ " & $g_iXD_NoBetCount & " ván -> Rải mồi " & _FormatNumber($g_fTableClickBet) & "đ giữ ghế vào [" & $sTarget & "] (Không tính vào số liệu)!")
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $iCurrentStep & " [THẬT - GIỮ BÀN]" & @CRLF & "🛡️ Rải giữ ghế: " & _FormatNumber($g_fTableClickBet) & "đ VÀO [" & $sTarget & "] (Số liệu: 0đ)")
		ElseIf $g_fTableClickBet > 0 Then
			_UpdateStatus("💸 [ĐÁNH THẬT] " & $sRowModeTag & " (B" & $iCurrentStep & ") -> Cược " & _FormatNumber($g_fTableClickBet) & "đ vào [" & $sTarget & "]")
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $iCurrentStep & " [ĐÁNH THẬT]" & @CRLF & "💰 Sẵn sàng ném: " & _FormatNumber($g_fTableClickBet) & "đ VÀO [" & $sTarget & "]")
		Else
			_UpdateStatus("💸 [ĐÁNH NHÁP] " & $sRowModeTag & " - B" & $iCurrentStep & " (0đ) vào [" & $sTarget & "] (" & $sKeepStatus & ")")
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $iCurrentStep & " [BƯỚC NHÁP]" & @CRLF & "💰 Đánh nháp 0đ VÀO [" & $sTarget & "] (" & $sKeepStatus & ")")
		EndIf
	EndIf

	_UpdateXocDiaGridUI()
	Return $aResult
EndFunc   ;==>_Logic_XocDia_5Hang_VIP

Func _ProcessOutcome_XocDia_VIP($sActualResult, $sBetOn)
	Local $bIsWin = ($sActualResult == $sBetOn)
	Local $bIsSingleRow = (GUICtrlRead($g_hRadio_XD_SingleRow) == $GUI_CHECKED)

	; 0. GHI NHẬN THỐNG KÊ BỘ NHỚ ĐỆM CHUỖI THUA THÔNG TỪ TRƯỚC TỚI GIỜ
	_RecordLossStreakCache($bIsWin)

	Local $iTargetRows = $bIsSingleRow ? 1 : Number(GUICtrlRead($g_hInput_XD_MaxRows))
	If $iTargetRows < 1 Then $iTargetRows = 1
	If $iTargetRows > 10 Then $iTargetRows = 10
	If $bIsSingleRow Then $g_iCurrentTier = 1

	Local $iJumpLoss = Number(GUICtrlRead($g_hInput_XD_JumpLoss))
	If $iJumpLoss < 1 Then $iJumpLoss = 1
	Local $iJumpWin = Number(GUICtrlRead($g_hInput_XD_JumpWin))
	If $iJumpWin < 0 Then $iJumpWin = 0
	Local $bShareDebt = (Not $bIsSingleRow) And (GUICtrlRead($g_hCheckbox_XD_ShareDebt) == $GUI_CHECKED)

	; 1. Bộ đếm chống văng bàn: Chỉ reset về 0 khi ván vừa rồi CÓ RẢI PHỈNH THẬT xuống mặt bàn
	If $g_fTableClickBet > 0 Then
		$g_iXD_NoBetCount = 0
	Else
		$g_iXD_NoBetCount += 1
	EndIf

	; Đọc số bước nháp của từng hàng
	Local $sVirtualRaw = StringStripWS(GUICtrlRead($g_hInput_XD_Virtual), 8)
	Local $aVirtualParsed = StringSplit($sVirtualRaw, ",")
	Local $aVirt[11]
	For $r = 1 To 10
		$aVirt[$r] = ($r <= $aVirtualParsed[0]) ? Number($aVirtualParsed[$r]) : 0
	Next

	Local $iJustWonRow = 0 ; Khóa bảo vệ Hàng vừa thắng không bị gán đè nợ trong cùng ván

	; 2. TÍNH NỢ THỰC TẾ TỪNG HÀNG & QUỸ GỌT NỢ CHUẨN TOÁN HỌC
	If $bIsWin Then
		$iJustWonRow = $g_iCurrentTier
		Local $fWinAmount = ($g_fCurrentBet * 0.95)
		$g_fXD_CycleProfit += $fWinAmount

		Local $fNetRowProfit = $fWinAmount - $g_aXD_RowLoss[$g_iCurrentTier]
		$g_aXD_RowLoss[$g_iCurrentTier] = 0

		If $bShareDebt And $fNetRowProfit > 0 Then
			Local $bHasOtherDebt = False
			For $r = 1 To $iTargetRows
				If $r <> $g_iCurrentTier And $g_aXD_RowLoss[$r] > 0 Then
					$bHasOtherDebt = True
					ExitLoop
				EndIf
			Next
			If $bHasOtherDebt Then
				$g_fXD_AmortizePool += $fNetRowProfit
			EndIf
		EndIf
	Else
		$g_fXD_CycleProfit -= $g_fCurrentBet
		$g_aXD_RowLoss[$g_iCurrentTier] += $g_fCurrentBet
	EndIf

	If Not $bShareDebt Then $g_fXD_AmortizePool = 0

	; 3. TẦNG 1: XỬ LÝ THẮNG / THUA (ĐI 1 HÀNG DUY NHẤT HOẶC GẤP HÀNG LUÂN PHIÊN)
	If $bIsSingleRow Then
		; CHẾ ĐỘ ĐI 1 HÀNG DUY NHẤT (H1): Thắng reset về B1 ngay lập tức, Thua gấp lên bước tiếp theo trên H1
		$g_iCurrentTier = 1
		If $bIsWin Then
			$g_aTierStep[1] = 1
			$g_aXD_RowLoss[1] = 0
			$g_iXD_WinStreakInRow += 1
			$g_iXD_LossStreakInRow = 0
			$g_fXD_CycleProfit = 0
			_UpdateStatus("🎉 [1 HÀNG DUY NHẤT] Húp! -> Reset Hàng 1 về lại B1 ngay lập tức!")
		Else
			$g_aTierStep[1] += 1
			$g_iXD_LossStreakInRow += 1
			$g_iXD_WinStreakInRow = 0
			_UpdateStatus("⏳ [1 HÀNG DUY NHẤT] Gãy (Thua thông " & $g_iXD_CurLossStreak_Cache & " tay)! -> Hàng 1 gấp lên Bước " & $g_aTierStep[1] & ".")
		EndIf
	Else
		; CHẾ ĐỘ GẤP THEO HÀNG LUÂN PHIÊN
		If $bIsWin Then
			$g_aTierStep[$g_iCurrentTier] = 1
			$g_aXD_RowLoss[$g_iCurrentTier] = 0
			$g_iXD_WinStreakInRow += 1
			$g_iXD_LossStreakInRow = 0

			If $iJumpWin > 0 And $g_iXD_WinStreakInRow >= $iJumpWin Then
				$g_iCurrentTier = Mod($g_iCurrentTier, $iTargetRows) + 1
				$g_iXD_WinStreakInRow = 0
				$g_iXD_LossStreakInRow = 0
				_UpdateStatus("🎉 [KẾT QUẢ] Ăn thông đủ " & $iJumpWin & " tay! -> [Nhảy Hàng] Chuyển sang Hàng " & $g_iCurrentTier & " (B" & $g_aTierStep[$g_iCurrentTier] & ").")
			Else
				_UpdateStatus("🛡️ [KẾT QUẢ] Húp! -> Hàng " & $g_iCurrentTier & " đã RESET về B1 đứng yên làm khiên!")
			EndIf
		Else
			$g_aTierStep[$g_iCurrentTier] += 1
			$g_iXD_LossStreakInRow += 1
			$g_iXD_WinStreakInRow = 0

			If $g_iXD_LossStreakInRow >= $iJumpLoss Then
				$g_iCurrentTier = Mod($g_iCurrentTier, $iTargetRows) + 1
				$g_iXD_LossStreakInRow = 0
				$g_iXD_WinStreakInRow = 0
				_UpdateStatus("🔄 [KẾT QUẢ] Thua thông đủ " & $iJumpLoss & " tay! -> [Nhảy Hàng] Chuyển sang Hàng " & $g_iCurrentTier & " (Đang ở Bước " & $g_aTierStep[$g_iCurrentTier] & ").")
			Else
				_UpdateStatus("⏳ [KẾT QUẢ] Gãy (Thua thông " & $g_iXD_LossStreakInRow & "/" & $iJumpLoss & " tay)! -> Trụ lại Hàng " & $g_iCurrentTier & " lên Bước " & $g_aTierStep[$g_iCurrentTier] & ".")
			EndIf
		EndIf
	EndIf

	; 4. TẦNG 2 & 3: CHẺ ĐÔI ĐỈNH NỢ & GỌT NỢ (CHỈ CHẠY Ở CHẾ ĐỘ LUÂN PHIÊN KHI BẬT SAN SẺ NỢ)
	If $bShareDebt And $iTargetRows >= 2 Then
		; TẦNG 2: CHẺ ĐÔI ĐỈNH NỢ (Bảo vệ tuyệt đối hàng vừa thắng $iJustWonRow không bị gán nợ lại ngay)
		If Not $g_bXD_SplitUsed Then
			For $rHigh = 1 To $iTargetRows
				Local $iRealStepHigh = $g_aTierStep[$rHigh] - $aVirt[$rHigh]
				If $iRealStepHigh == 5 Then
					For $rLow = 1 To $iTargetRows
						If $rLow == $rHigh Or $rLow == $iJustWonRow Then ContinueLoop
						Local $iRealStepLow = $g_aTierStep[$rLow] - $aVirt[$rLow]
						If $iRealStepLow <= 1 And $g_aXD_RowLoss[$rLow] == 0 Then
							Local $iNewRealStep = 4 ; Lùi về Bước 4 tiền thật (8x)
							$g_aTierStep[$rHigh] = $aVirt[$rHigh] + $iNewRealStep
							$g_aTierStep[$rLow] = $aVirt[$rLow] + $iNewRealStep

							Local $fHalfDebt = $g_aXD_RowLoss[$rHigh] / 2
							$g_aXD_RowLoss[$rHigh] = $fHalfDebt
							$g_aXD_RowLoss[$rLow] = $fHalfDebt
							$g_bXD_SplitUsed = True

							_UpdateStatus("⚡ [SAN SẺ NỢ - CHẺ ĐÔI] Chia nợ Hàng " & $rHigh & " sang Hàng " & $rLow & " (Mỗi hàng gánh " & _FormatNumber($fHalfDebt) & "đ ở Bước tiền thật " & $iNewRealStep & ")!")
							ExitLoop 2
						EndIf
					Next
				EndIf
			Next
		EndIf

		; TẦNG 3: GỌT NỢ TỪNG BẬC BẰNG QUỸ LÃI RÒNG THỰC TẾ
		While $g_fXD_AmortizePool > 0
			Local $iMaxDebtRow = 0
			Local $iMaxRealStep = 0
			For $i = 1 To $iTargetRows
				Local $iRealSt = $g_aTierStep[$i] - $aVirt[$i]
				If $iRealSt > $iMaxRealStep And $g_aXD_RowLoss[$i] > 0 Then
					$iMaxRealStep = $iRealSt
					$iMaxDebtRow = $i
				EndIf
			Next

			If $iMaxDebtRow > 0 And $iMaxRealStep >= 2 Then
				Local $iHighStep = $g_aTierStep[$iMaxDebtRow]
				Local $fLastLostBet = $g_aXocDia_Seq[$iMaxDebtRow][$iHighStep - 1]
				If $fLastLostBet > 0 And $g_fXD_AmortizePool >= $fLastLostBet Then
					$g_fXD_AmortizePool -= $fLastLostBet
					$g_aXD_RowLoss[$iMaxDebtRow] -= $fLastLostBet
					If $g_aXD_RowLoss[$iMaxDebtRow] < 0 Then $g_aXD_RowLoss[$iMaxDebtRow] = 0
					$g_aTierStep[$iMaxDebtRow] -= 1
					_UpdateStatus("🛡️ [GỌT NỢ THỰC TẾ] Dùng " & _FormatNumber($fLastLostBet) & "đ lãi ròng -> Hạ nợ Hàng " & $iMaxDebtRow & " từ B" & $iHighStep & " xuống B" & $g_aTierStep[$iMaxDebtRow] & "!")
				Else
					ExitLoop
				EndIf
			Else
				ExitLoop
			EndIf
		WEnd
	EndIf

	; 5. Kiểm tra kịch kim từng hàng
	Local $iMaxLimit = $g_aXD_MaxStepsPerRow[$g_iCurrentTier]
	If $g_aTierStep[$g_iCurrentTier] > $iMaxLimit Then
		_UpdateStatus("⚠️ [CẮT LỖ TOÀN CỤC] Hàng " & $g_iCurrentTier & " chạm kịch kim " & $iMaxLimit & " bước! Reset toàn bộ về B1.")
		For $i = 1 To 10
			$g_aTierStep[$i] = 1
			$g_aXD_RowLoss[$i] = 0
		Next
		$g_iCurrentTier = 1
		$g_iXD_LossStreakInRow = 0
		$g_iXD_WinStreakInRow = 0
		$g_fXD_CycleProfit = 0
		$g_fXD_AmortizePool = 0
		$g_bXD_SplitUsed = False
	EndIf

	; 6. Khóa Chốt Lãi Chu Kỳ (Tự xóa sạch nợ toàn bảng khi đạt mục tiêu lãi vòng)
	Local $bAllClean = False
	If Not $bIsSingleRow And GUICtrlRead($g_hCheckbox_XD_AutoResetDebt) == $GUI_CHECKED Then
		Local $fTarget = Number(StringRegExpReplace(GUICtrlRead($g_hInput_XD_TargetProfit), "\D", ""))
		If $fTarget > 0 And $g_fXD_CycleProfit >= $fTarget Then
			_UpdateStatus("🎉 [CHỐT LỜI VÒNG] Lãi chu kỳ đạt +" & _FormatNumber($g_fXD_CycleProfit) & "đ! XÓA SẠCH NỢ VỀ B1!")
			For $i = 1 To 10
				$g_aTierStep[$i] = 1
				$g_aXD_RowLoss[$i] = 0
			Next
			$g_iCurrentTier = 1
			$g_iXD_LossStreakInRow = 0
			$g_iXD_WinStreakInRow = 0
			$g_fXD_CycleProfit = 0
			$g_fXD_AmortizePool = 0
			$g_bXD_SplitUsed = False
			$bAllClean = True
		EndIf
	EndIf

	; 7. Khi tất cả các hàng đã tự về B1 và không còn âm chu kỳ -> Mở khóa cho chu kỳ mới
	If Not $bAllClean Then
		$bAllClean = True
		For $i = 1 To $iTargetRows
			If $g_aTierStep[$i] > ($aVirt[$i] + 1) Or $g_aXD_RowLoss[$i] > 0 Then
				$bAllClean = False
				ExitLoop
			EndIf
		Next
		If $bAllClean Then
			$g_bXD_SplitUsed = False
			If $g_fXD_CycleProfit >= 0 Then
				$g_fXD_CycleProfit = 0
				$g_fXD_AmortizePool = 0
			EndIf
		EndIf
	EndIf

	_UpdateXocDiaGridUI()
EndFunc   ;==>_ProcessOutcome_XocDia_VIP

Func _UpdateXocDiaGridUI()
	If Not $g_bIsRunning Then
		$g_iXD_LossStreakInRow = 0
		$g_iXD_WinStreakInRow = 0
		$g_bXD_SplitUsed = False
		For $i = 1 To 10
			$g_aXD_RowLoss[$i] = 0
		Next
	EndIf

	Local $sCustomSeq = StringStripWS(GUICtrlRead($g_hInput_XD_Seq), 8)
	Local $aParsed = StringSplit($sCustomSeq, ",")

	Local $bIsSingleRow = (GUICtrlRead($g_hRadio_XD_SingleRow) == $GUI_CHECKED)
	Local $iTargetRows = $bIsSingleRow ? 1 : Number(GUICtrlRead($g_hInput_XD_MaxRows))
	If $iTargetRows < 1 Then $iTargetRows = 1
	If $iTargetRows > 10 Then $iTargetRows = 10
	If $bIsSingleRow Then $g_iCurrentTier = 1

	Local $fBaseBet = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialBet), "\D", ""))
	If $fBaseBet <= 0 Then $fBaseBet = 10000

	Local $sVirtualRaw = StringStripWS(GUICtrlRead($g_hInput_XD_Virtual), 8)
	Local $aVirtualParsed = StringSplit($sVirtualRaw, ",")
	Local $aVirt[11]
	For $r = 1 To 10
		$aVirt[$r] = ($r <= $aVirtualParsed[0]) ? Number($aVirtualParsed[$r]) : 0
	Next

	$g_iDynamicMaxSteps = 0

	For $r = 1 To 10
		Local $iVirtSteps = $aVirt[$r]
		Local $iRowSteps = $aParsed[0] + $iVirtSteps
		If $iRowSteps > 15 Then $iRowSteps = 15
		$g_aXD_MaxStepsPerRow[$r] = $iRowSteps

		If $iRowSteps > $g_iDynamicMaxSteps And $r <= $iTargetRows Then $g_iDynamicMaxSteps = $iRowSteps

		For $c = 1 To 15
			If $c <= $iVirtSteps Then
				$g_aXocDia_Seq[$r][$c] = 0
			Else
				Local $idx = $c - $iVirtSteps
				If $idx <= $aParsed[0] Then
					$g_aXocDia_Seq[$r][$c] = Number($aParsed[$idx]) * $fBaseBet
				Else
					$g_aXocDia_Seq[$r][$c] = -1
				EndIf
			EndIf
		Next
	Next

	Local $bIsXocDia = (GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED)

	For $c = 1 To 15
		If $bIsXocDia And $c <= $g_iDynamicMaxSteps Then
			GUICtrlSetState($g_aXD_Cols[$c], $GUI_SHOW)
		Else
			GUICtrlSetState($g_aXD_Cols[$c], $GUI_HIDE)
		EndIf
	Next

	For $r = 1 To 10
		If $bIsXocDia And $r <= $iTargetRows Then
			GUICtrlSetState($g_aXD_Rows[$r], $GUI_SHOW)
			For $c = 1 To 15
				Local $iVal = $g_aXocDia_Seq[$r][$c]
				If $c <= $g_iDynamicMaxSteps And $iVal <> -1 Then
					GUICtrlSetState($g_aXocDiaGrid[$r][$c], $GUI_SHOW)

					Local $sText = ""
					If $iVal == 0 And $c <= $aVirt[$r] Then
						$sText = "0đ"
					ElseIf $iVal >= 1000000 Then
						$sText = Round($iVal / 1000000, 1) & "M"
					ElseIf $iVal >= 1000 Then
						$sText = Round($iVal / 1000, 0) & "k"
					Else
						$sText = $iVal
					EndIf
					GUICtrlSetData($g_aXocDiaGrid[$r][$c], $sText)

					Local $iStep = $g_aTierStep[$r]
					If $r == $g_iCurrentTier And $c == $iStep Then
						GUICtrlSetBkColor($g_aXocDiaGrid[$r][$c], 0xFF0000)
						GUICtrlSetColor($g_aXocDiaGrid[$r][$c], 0xFFFFFF)
					ElseIf $c == $iStep And $iStep > 1 Then
						GUICtrlSetBkColor($g_aXocDiaGrid[$r][$c], 0xFFFF00)
						GUICtrlSetColor($g_aXocDiaGrid[$r][$c], 0xFF0000)
					ElseIf $c < $iStep Then
						GUICtrlSetBkColor($g_aXocDiaGrid[$r][$c], 0xAAAAAA)
						GUICtrlSetColor($g_aXocDiaGrid[$r][$c], 0x555555)
					Else
						GUICtrlSetBkColor($g_aXocDiaGrid[$r][$c], 0xE0E0E0)
						GUICtrlSetColor($g_aXocDiaGrid[$r][$c], 0x555555)
					EndIf
				Else
					GUICtrlSetState($g_aXocDiaGrid[$r][$c], $GUI_HIDE)
				EndIf
			Next
		Else
			GUICtrlSetState($g_aXD_Rows[$r], $GUI_HIDE)
			For $c = 1 To 15
				GUICtrlSetState($g_aXocDiaGrid[$r][$c], $GUI_HIDE)
			Next
		EndIf
	Next

	Local $iSafeStep = $g_aTierStep[$g_iCurrentTier]
	Local $iMaxLimitRow = $g_aXD_MaxStepsPerRow[$g_iCurrentTier]
	If $iSafeStep > $iMaxLimitRow Then $iSafeStep = $iMaxLimitRow

	Local $iBetAmount = $g_aXocDia_Seq[$g_iCurrentTier][$iSafeStep]
	Local $bIsDemoMode = (GUICtrlRead($g_hRadio_XD_DemoKeep) == $GUI_CHECKED)
	Local $bIsKeepTable = (GUICtrlRead($g_hCheckbox_XD_AntiKick) == $GUI_CHECKED)
	Local $sKeepTag = $bIsKeepTable ? "CÓ GIỮ BÀN" : "TẮT GIỮ BÀN"
	Local $sRowModeTag = $bIsSingleRow ? "1 HÀNG H1" : ("HÀNG " & $g_iCurrentTier)

	If $bIsDemoMode Then
		GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $g_aTierStep[$g_iCurrentTier] & " [DEMO - " & $sKeepTag & "]" & @CRLF & "🧪 Mô phỏng: " & _FormatNumber($iBetAmount) & "đ | Lãi vòng: " & _FormatNumber($g_fXD_CycleProfit) & "đ")
	Else
		If $iBetAmount > 0 Then
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $g_aTierStep[$g_iCurrentTier] & " [THẬT - " & $sKeepTag & "]" & @CRLF & "💰 Sẵn sàng ném: " & _FormatNumber($iBetAmount) & "đ | Lãi vòng: " & _FormatNumber($g_fXD_CycleProfit) & "đ")
		Else
			GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: " & $sRowModeTag & " - B" & $g_aTierStep[$g_iCurrentTier] & " [THẬT - " & $sKeepTag & "]" & @CRLF & "💰 Đánh nháp 0đ | Lãi vòng: " & _FormatNumber($g_fXD_CycleProfit) & "đ")
		EndIf
	EndIf

	_UpdateStreakCacheUI()
EndFunc   ;==>_UpdateXocDiaGridUI

; --- HỆ THỐNG THỐNG KÊ BỘ NHỚ ĐỆM CHUỖI THUA THÔNG TỪ TRƯỚC TỚI GIỜ ---
Func _RecordLossStreakCache($bIsWin)
	If $bIsWin Then
		$g_iXD_CurLossStreak_Cache = 0
	Else
		$g_iXD_CurLossStreak_Cache += 1
		Local $k = $g_iXD_CurLossStreak_Cache

		; Khi chuỗi thua tăng từ (k-1) lên k: Chuyển 1 lượt từ mốc x(k-1) lên mốc x(k) để mỗi dây thua chỉ tính ở đỉnh cao nhất
		If $k > 1 Then
			Local $iPrevCount = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "x" & ($k - 1), "0"))
			If $iPrevCount > 0 Then
				IniWrite($g_sStreakCacheFile, "LossStreakCache", "x" & ($k - 1), $iPrevCount - 1)
			EndIf
		EndIf

		Local $iCurCount = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "x" & $k, "0"))
		IniWrite($g_sStreakCacheFile, "LossStreakCache", "x" & $k, $iCurCount + 1)

		Local $iMaxEver = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "MaxStreak", "0"))
		If $k > $iMaxEver Then
			IniWrite($g_sStreakCacheFile, "LossStreakCache", "MaxStreak", $k)
		EndIf
	EndIf
	_UpdateStreakCacheUI()
EndFunc   ;==>_RecordLossStreakCache

Func _UpdateStreakCacheUI()
	Local $iMaxEver = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "MaxStreak", "0"))
	Local $sTopList = ""

	; Ưu tiên hiển thị từ mức thua thông cao nhất trở xuống (ví dụ x10, x9, x8, x7...)
	For $i = 25 To 1 Step -1
		Local $iCnt = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "x" & $i, "0"))
		If $iCnt > 0 Then
			$sTopList &= "x" & $i & ":" & $iCnt & " | "
		EndIf
	Next

	If $sTopList == "" Then
		$sTopList = "Chưa có dữ liệu thua thông"
	Else
		$sTopList = StringTrimRight($sTopList, 3)
	EndIf

	GUICtrlSetData($g_hLbl_XD_StreakStats, "🔥 Thua thông hiện tại: x" & $g_iXD_CurLossStreak_Cache & " | Kỷ lục: x" & $iMaxEver & @CRLF & "📊 Bộ nhớ: " & $sTopList)
EndFunc   ;==>_UpdateStreakCacheUI

Func _ShowStreakCacheDetail_Deferred()
	AdlibUnRegister("_ShowStreakCacheDetail_Deferred")
	Local $iMaxEver = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "MaxStreak", "0"))
	Local $sDetail = "📊 THỐNG KÊ BỘ NHỚ ĐỆM THUA THÔNG (TỪ TRƯỚC TỚI GIỜ)" & @CRLF
	$sDetail &= "==========================================" & @CRLF
	$sDetail &= "🔥 Chuỗi thua thông hiện tại: x" & $g_iXD_CurLossStreak_Cache & @CRLF
	$sDetail &= "🏆 Đỉnh thua thông cao nhất kỷ lục: x" & $iMaxEver & @CRLF
	$sDetail &= "------------------------------------------" & @CRLF

	Local $bHasData = False
	For $i = 25 To 1 Step -1
		Local $iCnt = Number(IniRead($g_sStreakCacheFile, "LossStreakCache", "x" & $i, "0"))
		If $iCnt > 0 Then
			$sDetail &= "• Thua thông x" & $i & " :  " & $iCnt & " lần" & @CRLF
			$bHasData = True
		EndIf
	Next

	If Not $bHasData Then
		$sDetail &= "(Hiện chưa có dữ liệu chuỗi thua nào được ghi nhận)" & @CRLF
	EndIf

	$sDetail &= "==========================================" & @CRLF
	$sDetail &= "👉 Bấm [NO] để Đóng và Giữ nguyên bộ nhớ đệm." & @CRLF
	$sDetail &= "👉 Bấm [YES] nếu bạn muốn XÓA LÀM MỚI toàn bộ thống kê về 0."

	Local $iAns = MsgBox(36 + 262144, "Bộ Nhớ Đệm Thua Thông", $sDetail, 0, $g_hGUI)
	If $iAns == 6 Then
		FileDelete($g_sStreakCacheFile)
		$g_iXD_CurLossStreak_Cache = 0
		_UpdateStreakCacheUI()
		MsgBox(64 + 262144, "Đã Xóa", "Đã làm mới toàn bộ bộ nhớ đệm thống kê thua thông về 0!", 0, $g_hGUI)
	EndIf
EndFunc   ;==>_ShowStreakCacheDetail_Deferred

Func _SwitchLimit_VIP($sTargetLimit)
	If $g_sCurrentLimitState == $sTargetLimit Then Return

	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return

	_UpdateStatus("⚙️ Đang bẻ Hạn Mức sang: [" & $sTargetLimit & "]...")

	WinActivate($hWnd)
	Sleep(200)

	MouseMove($g_iLimitBtnX, $g_iLimitBtnY, 2)
	Sleep(100)
	MouseClick("left", $g_iLimitBtnX, $g_iLimitBtnY, 1, 0)
	Sleep(600)

	If $sTargetLimit == "10-500" Then
		MouseMove($g_iLimit10_500X, $g_iLimit10_500Y, 2)
		Sleep(100)
		MouseClick("left", $g_iLimit10_500X, $g_iLimit10_500Y, 1, 0)
	Else
		MouseMove($g_iLimit20_50KX, $g_iLimit20_50KY, 2)
		Sleep(100)
		MouseClick("left", $g_iLimit20_50KX, $g_iLimit20_50KY, 1, 0)
	EndIf

	Sleep(400)

	If $g_iLimitConfirmX > 0 And $g_iLimitConfirmY > 0 Then
		MouseMove($g_iLimitConfirmX, $g_iLimitConfirmY, 2)
		Sleep(100)
		MouseDown("left")
		Sleep(150)
		MouseUp("left")
	EndIf

	Sleep(500)
	$g_sCurrentLimitState = $sTargetLimit
	_UpdateStatus("✅ Đã bẻ xong hạn mức! Chuẩn bị chờ đèn xanh thả chip.")
EndFunc   ;==>_SwitchLimit_VIP
#EndRegion 7. BỘ MÁY XÓC ĐĨA VIP (MA TRẬN 3 TRONG 1, GIỮ BÀN & ĐỔI HẠN MỨC)

; ==================================================================================================
#Region 8. RẢI CHIP CƯỢC, CÔNG CỤ PHÒNG KỸ THUẬT, THỐNG KÊ & LƯU CẤU HÌNH
; ==================================================================================================
Func _PerformBet($sBetOn, ByRef $fAmountToBet)
	If Not $g_bIsRunning Then Return False
	If _CheckProfitLossTargets() Then Return False

	_UpdateStatus("💸 [AUTO CLICK] Bắt đầu rải chip cược [" & $sBetOn & "] (Mức tiền: " & _FormatNumber($fAmountToBet) & " đ)...")

	Local $hGameWin = $g_hTargetGameWin
	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		$hGameWin = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hGameWin
	EndIf

	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		_HaltProcess("Lỗi: Không tìm thấy cửa sổ game!")
		Return False
	EndIf

	Local $aBetAreaPos
	If $sBetOn == "B" Or $sBetOn == "D" Or $sBetOn == "C" Then
		$aBetAreaPos = $g_aBankerButtonPos
	ElseIf $sBetOn == "P" Or $sBetOn == "V" Or $sBetOn == "M" Or $sBetOn == "L" Then
		$aBetAreaPos = $g_aPlayerButtonPos
	Else
		Return False
	EndIf
	Sleep(50)

	_ClickChipsForAmount($hGameWin, $fAmountToBet, $aBetAreaPos)

	$g_fLastBetAmount = $fAmountToBet
	$g_sLastBetOn = $sBetOn
	Return True
EndFunc   ;==>_PerformBet

Func _ClickChipsForAmount($hGameWin, ByRef $fAmount, $aBetAreaPos)
	Local $aClickQueue = _CalculateOptimalClicks($fAmount)
	If @error Then Return False
	Local $iTotalSteps = UBound($aClickQueue)
	If $iTotalSteps = 0 Then
		$fAmount = 0
		Return True
	EndIf

	Sleep(800)

	Local $iBaseDelay = Number(GUICtrlRead($g_hInput_ClickDelay_Main))
	If $iBaseDelay < 150 Then $iBaseDelay = 150

	Local $tTarget = DllStructCreate("long X;long Y")
	DllStructSetData($tTarget, "X", $aBetAreaPos[0])
	DllStructSetData($tTarget, "Y", $aBetAreaPos[1])
	_WinAPI_ScreenToClient($hGameWin, $tTarget)
	Local $iTargetClientX = DllStructGetData($tTarget, "X")
	Local $iTargetClientY = DllStructGetData($tTarget, "Y")

	For $i = 0 To $iTotalSteps - 1
		Local $tChip = DllStructCreate("long X;long Y")
		DllStructSetData($tChip, "X", $aClickQueue[$i][0])
		DllStructSetData($tChip, "Y", $aClickQueue[$i][1])
		_WinAPI_ScreenToClient($hGameWin, $tChip)
		Local $iChipClientX = DllStructGetData($tChip, "X")
		Local $iChipClientY = DllStructGetData($tChip, "Y")

		Local $iCount = $aClickQueue[$i][2]

		ControlClick($hGameWin, "", "", "left", 2, $iChipClientX, $iChipClientY)
		Sleep(300)

		For $j = 1 To $iCount
			If Not $g_bIsRunning Then Return False
			ControlClick($hGameWin, "", "", "left", 1, $iTargetClientX, $iTargetClientY)
			Sleep($iBaseDelay)
		Next
	Next

	Return True
EndFunc   ;==>_ClickChipsForAmount

Func _CalculateOptimalClicks(ByRef $fTargetAmount)
	Local $aActiveChips[1][3]
	Local $iActiveCount = 0
	Local $fActualCalculated = 0

	For $i = 0 To 4
		If $g_aChipConfig[$i][0] Then
			ReDim $aActiveChips[$iActiveCount + 1][3]
			$aActiveChips[$iActiveCount][0] = $g_aChipConfig[$i][1]
			$aActiveChips[$iActiveCount][1] = $g_aChipConfig[$i][2]
			$aActiveChips[$iActiveCount][2] = $g_aChipConfig[$i][3]
			$iActiveCount += 1
		EndIf
	Next

	If $iActiveCount = 0 Then
		MsgBox(16, "Lỗi Chip", "Bạn chưa bật chip nào trong Cấu Hình.")
		Return SetError(1)
	EndIf

	_ArraySort($aActiveChips, 1, 0, 0, 0)

	Local $aClicksQueue[0][3]
	Local $fRemaining = $fTargetAmount

	For $i = 0 To UBound($aActiveChips) - 1
		Local $fVal = $aActiveChips[$i][0]
		If $fVal <= 0 Then ContinueLoop

		Local $iCount = Floor($fRemaining / $fVal)
		If $iCount > 0 Then
			Local $iIdx = UBound($aClicksQueue)
			ReDim $aClicksQueue[$iIdx + 1][3]
			$aClicksQueue[$iIdx][0] = $aActiveChips[$i][1]
			$aClicksQueue[$iIdx][1] = $aActiveChips[$i][2]
			$aClicksQueue[$iIdx][2] = $iCount

			$fActualCalculated += ($iCount * $fVal)
			$fRemaining = Mod($fRemaining, $fVal)
		EndIf
	Next

	If $fRemaining > 0 Then
		_UpdateStatus("Lẻ " & _FormatNumber($fRemaining) & " (Không đủ chip nhỏ hơn).")
	EndIf

	$fTargetAmount = $fActualCalculated
	Return $aClicksQueue
EndFunc   ;==>_CalculateOptimalClicks

Func _SingleClick($hWnd, $iX, $iY, $iRadius = 0)
	#forceref $iRadius
	If $iX <= 0 Or $iY <= 0 Then Return False
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return False

	Local $tPoint = DllStructCreate("long X;long Y")
	DllStructSetData($tPoint, "X", $iX)
	DllStructSetData($tPoint, "Y", $iY)
	_WinAPI_ScreenToClient($hWnd, $tPoint)
	Local $iClientX = DllStructGetData($tPoint, "X")
	Local $iClientY = DllStructGetData($tPoint, "Y")

	If $g_sSession <> "" Then
		Local $sJS = "var el = document.elementFromPoint(" & $iClientX & ", " & $iClientY & "); if(el) el.click();"
		_WD_ExecuteScript($g_sSession, $sJS)
	Else
		ControlClick($hWnd, "", "", "left", 1, $iClientX, $iClientY)
	EndIf

	Sleep(20)
	Return True
EndFunc   ;==>_SingleClick

; --- CÔNG CỤ QUÉT TỌA ĐỘ & MÀU PHÒNG KỸ THUẬT ---
Func _ToggleScanHotkey()
	If GUICtrlRead($g_hCheckbox_ToggleScan) = $GUI_CHECKED Then
		HotKeySet("`", "_UpdateScannerInfo")
	Else
		HotKeySet("`")
	EndIf
EndFunc   ;==>_ToggleScanHotkey

Func _UpdateScannerInfo()
	Local $aPos = MouseGetPos()
	Local $iColor = PixelGetColor($aPos[0], $aPos[1])

	$g_iTempX = $aPos[0]
	$g_iTempY = $aPos[1]
	$g_iTempColor = $iColor

	Local $sHexColor = "0x" & Hex($iColor, 6)
	GUICtrlSetData($g_hInput_ScanX, $aPos[0])
	GUICtrlSetData($g_hInput_ScanY, $aPos[1])
	GUICtrlSetData($g_hInput_ScanColor, $sHexColor)
	GUICtrlSetBkColor($g_hLabel_ScanColorPreview, $iColor)
EndFunc   ;==>_UpdateScannerInfo

Func _GetCoords_Fast($hInputX, $hInputY)
	If $g_iTempX = 0 And $g_iTempY = 0 Then
		MsgBox(48, "Cảnh báo", "Sếp chưa di chuột vào điểm cần lấy và bấm phím ` (gần số 1) !")
		Return
	EndIf

	GUICtrlSetData($hInputX, $g_iTempX)
	GUICtrlSetData($hInputY, $g_iTempY)

	$g_bNeedAutoSave = True
	$g_hAutoSaveTimer = TimerInit()
EndFunc   ;==>_GetCoords_Fast

Func _GetColor_Fast($hInputControl)
	If $g_iTempX = 0 And $g_iTempY = 0 Then
		MsgBox(48, "Cảnh báo", "Sếp chưa di chuột vào màu cần lấy và bấm phím ` (gần số 1) !")
		Return
	EndIf

	GUICtrlSetData($hInputControl, "0x" & Hex($g_iTempColor, 6))

	$g_bNeedAutoSave = True
	$g_hAutoSaveTimer = TimerInit()
EndFunc   ;==>_GetColor_Fast

Func _HandleTestColorButton($sArea)
	Local $hWnd = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
	If $hWnd = 0 Then
		ToolTip("⚠️ Lỗi: Không tìm thấy cửa sổ game đang hiển thị!", MouseGetPos()[0], MouseGetPos()[1])
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

			Local $bIsXocDia = (GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED)

			If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColB, $iTolerance, 1, $hWnd)) Then
				$bFound = True
				$sMsgSuccess = "OK! Tìm thấy: " & ($bIsXocDia ? "CHẴN (ĐỎ)" : "BANKER")
			ElseIf IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColP, $iTolerance, 1, $hWnd)) Then
				$bFound = True
				$sMsgSuccess = "OK! Tìm thấy: " & ($bIsXocDia ? "LẺ (XANH)" : "PLAYER")
			ElseIf Not $bIsXocDia And IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColT, $iTolerance, 1, $hWnd)) Then
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
EndFunc   ;==>_HandleTestColorButton

; --- KIỂM TRA MỤC TIÊU CHỐT LÃI / CẮT LỖ / KÉO ĐUÔI ---
Func _CheckProfitLossTargets()
	Local $bHitTarget = False
	Local $sReason = ""

	If GUICtrlRead($g_hCheckbox_DailyShield) == $GUI_CHECKED Then
		Local $fCurrentProfit = $g_fTotalProfit
		If $fCurrentProfit > $g_fPeakProfit Then $g_fPeakProfit = $fCurrentProfit

		Local $fTarget = Number(StringRegExpReplace(GUICtrlRead($g_hInput_DailyTarget), "\D", ""))
		Local $fTrailing = Number(StringRegExpReplace(GUICtrlRead($g_hInput_DailyTrailing), "\D", ""))
		Local $fStopLoss = -1 * Abs(Number(StringRegExpReplace(GUICtrlRead($g_hInput_DailyStopLoss), "\D", "")))

		If $fStopLoss < 0 And $fCurrentProfit <= $fStopLoss Then
			$bHitTarget = True
			$sReason = "CHẠM MỨC CẮT LỖ PHIÊN (Âm " & _FormatNumber($fCurrentProfit) & ")"
		EndIf

		If $fTarget > 0 Then
			If $fTrailing > 0 Then
				If $fCurrentProfit >= $fTarget Or $g_bIsTrailingMode Then
					$g_bIsTrailingMode = True
					Local $fDynTrail = $fTrailing
					If $g_fPeakProfit >= ($fTarget * 2) Then $fDynTrail = $fTrailing / 2

					If $fCurrentProfit <= ($g_fPeakProfit - $fDynTrail) Then
						$bHitTarget = True
						$sReason = "CHỐT LÃI KÉO ĐUÔI (Đỉnh: " & _FormatNumber($g_fPeakProfit) & " đ, Tụt mất: " & _FormatNumber($fDynTrail) & " đ)"
					EndIf
				EndIf
			Else
				If $fCurrentProfit >= $fTarget Then
					$bHitTarget = True
					$sReason = "ĐẠT MỤC TIÊU CHỐT LÃI PHIÊN (+" & _FormatNumber($fCurrentProfit) & " đ)"
				EndIf
			EndIf
		EndIf

		If $bHitTarget Then
			_StopAndSaveSession()

			If GUICtrlRead($g_hRadio_Action_Stop) == $GUI_CHECKED Then
				IniWrite($g_sIniPath, "SessionData", "LockedDate", _GetGamingDate())
				_UpdateStatus("🛑 " & $sReason & " -> DỪNG TOOL THEO YÊU CẦU!")
				_StopProcess()
				Return True
			ElseIf GUICtrlRead($g_hRadio_Action_PauseMin) == $GUI_CHECKED Then
				Local $iMins = Number(GUICtrlRead($g_hInput_Action_PauseMin))
				$g_iTargetPauseEndTime = TimerInit()
				$g_iTargetPauseDuration = $iMins * 60000
				_UpdateStatus("⏳ " & $sReason & " -> Nghỉ " & $iMins & " phút.")
				Return False
			Else
				Local $iHands = Number(GUICtrlRead($g_hInput_Action_PauseHand))
				$g_iTargetPauseHands = $iHands
				_UpdateStatus("⏳ " & $sReason & " -> Chờ trôi " & $iHands & " ván.")
				Return False
			EndIf
		EndIf
	EndIf

	Local $sFileProfit = @ScriptDir & "\profit_history.ini"
	Local $fNetDay = Number(IniRead($sFileProfit, "Daily", _GetGamingDate(), "0"))
	Local $sColorNet = ($fNetDay >= 0) ? 0x006400 : 0xFF0000
	GUICtrlSetData($g_hLabel_NetDay, "LỢI NHUẬN TỔNG: " & _FormatNumber($fNetDay) & " đ")
	GUICtrlSetColor($g_hLabel_NetDay, $sColorNet)

	Return False
EndFunc   ;==>_CheckProfitLossTargets

; --- HIỂN THỊ LỊCH SỬ, SỐ DƯ, LÃI LỖ & THỐNG KÊ NGÀY ---
Func _AddNewHistoryEntry($sResult)
	_ArrayAdd($g_aDisplayHistory, $sResult)

	If UBound($g_aDisplayHistory) > $HARD_LIMIT_RAM Then
		_ArrayDelete($g_aDisplayHistory, 0)
		If $g_iHistoryCutoffIndex > 0 Then
			$g_iHistoryCutoffIndex -= 1
		EndIf
	EndIf

	_UpdateBPTTotals($sResult)
EndFunc   ;==>_AddNewHistoryEntry

Func _UpdateBPTTotals($sResult)
	Switch $sResult
		Case "B", "D", "C"
			$g_iTotalBanker += 1
		Case "P", "V", "L"
			$g_iTotalPlayer += 1
		Case "T"
			$g_iTotalTie += 1
	EndSwitch
	_UpdateBPTTotalsLabels()
EndFunc   ;==>_UpdateBPTTotals

Func _UpdateBPTTotalsLabels()
	GUICtrlSetData($g_hLabel_TotalB_Val, $g_iTotalBanker)
	GUICtrlSetData($g_hLabel_TotalP_Val, $g_iTotalPlayer)
	GUICtrlSetData($g_hLabel_TotalT_Val, $g_iTotalTie)
EndFunc   ;==>_UpdateBPTTotalsLabels

Func _RedrawHistory()
	For $hLabel In $g_aLabel_History
		_StyleResultLabel($hLabel, "-", False, False)
	Next

	Local $iTotalCount = UBound($g_aDisplayHistory)
	If $iTotalCount = 0 Then Return

	Local $iViewLimit = 120
	Local $iStartIndex = ($iTotalCount > $iViewLimit) ? ($iTotalCount - $iViewLimit) : 0

	Local $iRows = 6
	Local $iDisplayCols = 20
	Local $iMaxCells = $iRows * $iDisplayCols
	Local $iDataCount = $iTotalCount - $iStartIndex

	Local $iScrollOffset = 0
	If $iDataCount > $iMaxCells Then
		Local $iExcessCols = Ceiling(($iDataCount - $iMaxCells) / $iRows)
		$iScrollOffset = $iExcessCols * $iRows
	EndIf

	For $i = $iStartIndex + $iScrollOffset To $iTotalCount - 1
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
EndFunc   ;==>_RedrawHistory

Func _StyleResultLabel($hLabel, $sResult, $bHighlight, $bIsLatest)
	GUICtrlSetData($hLabel, $sResult)
	GUICtrlSetFont($hLabel, 7, 700)
	If $bIsLatest Then
		GUICtrlSetBkColor($hLabel, $g_iLatestHighlightColor)
		GUICtrlSetColor($hLabel, 0x000000)
	ElseIf $bHighlight Then
		GUICtrlSetBkColor($hLabel, $g_iHighlightColor)
		GUICtrlSetColor($hLabel, 0x000000)
	Else
		Switch $sResult
			Case "B", "D", "C"
				GUICtrlSetBkColor($hLabel, 0xF70102)
				GUICtrlSetColor($hLabel, 0xFFFFFF)
			Case "P", "V", "L"
				GUICtrlSetBkColor($hLabel, 0x0182FA)
				GUICtrlSetColor($hLabel, 0xFFFFFF)
			Case "T"
				GUICtrlSetBkColor($hLabel, 0x29BC2F)
				GUICtrlSetColor($hLabel, 0xFFFFFF)
			Case Else
				GUICtrlSetBkColor($hLabel, 0xE0E0E0)
				GUICtrlSetColor($hLabel, 0x000000)
		EndSwitch
	EndIf
EndFunc   ;==>_StyleResultLabel

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
EndFunc   ;==>_UpdateProfitLabel

Func _UpdateBalanceLabel()
	Local $fCurrentBalance = $g_fInitialCapital + $g_fTotalProfit
	GUICtrlSetData($g_hLabel_CurrentBalance, _FormatNumber($fCurrentBalance) & " VND")
	GUICtrlSetColor($g_hLabel_CurrentBalance, 0x0000FF)
EndFunc   ;==>_UpdateBalanceLabel

Func _UpdateTotalHandsLabel()
	GUICtrlSetData($g_hLabel_TotalHands, UBound($g_aDisplayHistory))
EndFunc   ;==>_UpdateTotalHandsLabel

Func _UpdateTotalVolumeLabel()
	_RefreshVolumeDisplay()
EndFunc   ;==>_UpdateTotalVolumeLabel

Func _GetGamingDate()
	Local $iHour = @HOUR
	If $iHour < 7 Then
		Return StringReplace(_DateAdd('D', -1, _NowCalcDate()), "/", "-")
	Else
		Return StringReplace(_NowCalcDate(), "/", "-")
	EndIf
EndFunc   ;==>_GetGamingDate

Func _RefreshVolumeDisplay()
	Local $sToday = _GetGamingDate()
	Local $sFileVolume = @ScriptDir & "\volume_history.ini"
	Local $sFileProfit = @ScriptDir & "\profit_history.ini"

	Local $fDisplayVol = Number(IniRead($sFileVolume, "Daily", $sToday, "0"))
	Local $fDisplayProf = Number(IniRead($sFileProfit, "Daily", $sToday, "0"))

	GUICtrlSetData($g_hLabel_TotalVolume, _FormatNumber($fDisplayVol) & " đ")

	Local $sColorNet = ($fDisplayProf >= 0) ? 0x006400 : 0xFF0000
	GUICtrlSetData($g_hLabel_NetDay, "LỢI NHUẬN TỔNG: " & _FormatNumber($fDisplayProf) & " đ")
	GUICtrlSetColor($g_hLabel_NetDay, $sColorNet)
EndFunc   ;==>_RefreshVolumeDisplay

Func _UpdateDailyStats($fBetAmount, $fProfitChange)
	Local $sToday = _GetGamingDate()
	Local $sFileVolume = @ScriptDir & "\volume_history.ini"
	Local $sFileProfit = @ScriptDir & "\profit_history.ini"
	Local $sStatsFile = @ScriptDir & "\stats_history.ini"

	; 1. Cộng dồn Volume trong ngày
	Local $fCurrentVol = Number(IniRead($sFileVolume, "Daily", $sToday, "0"))
	$fCurrentVol += $fBetAmount
	IniWrite($sFileVolume, "Daily", $sToday, Round($fCurrentVol, 0))

	$g_fTotalVolume = $fCurrentVol
	IniWrite($sStatsFile, "Global_Daily", "Date", $sToday)
	IniWrite($sStatsFile, "Global_Daily", "Volume", Round($g_fTotalVolume, 0))

	; 2. Cộng dồn Lợi nhuận tổng trong ngày
	Local $fCurrentProf = Number(IniRead($sFileProfit, "Daily", $sToday, "0"))
	$fCurrentProf += $fProfitChange
	IniWrite($sFileProfit, "Daily", $sToday, Round($fCurrentProf, 0))

	_RefreshVolumeDisplay()
EndFunc   ;==>_UpdateDailyStats

Func _SyncLiveDashboard($fBalance, $fProfit, $fVolume)
	; 1. Ghi trạng thái ra file tạm nếu chạy chế độ quản lý nhiều bàn
	If $g_sMyTableID <> "" Then
		Local $sFile = @TempDir & "\status_" & $g_sMyTableID & ".ini"
		IniWrite($sFile, "Status", "State", $g_bIsRunning ? "RUNNING" : "STOPPED")
		IniWrite($sFile, "Status", "Balance", Round($fBalance, 0))
		IniWrite($sFile, "Status", "Profit", Round($fProfit, 0))
		IniWrite($sFile, "Status", "Volume", Round($fVolume, 0))
	EndIf

	; 2. Đồng bộ Volume & Lợi nhuận lên Google Sheets Server
	If $g_sHWID <> "" Then
		Local $sUrl = $g_sAppsScriptBaseURL & "?action=sync_vol" & _
				"&hwid=" & $g_sHWID & _
				"&vol=" & Round($fVolume, 0) & _
				"&profit=" & Round($fProfit, 0) & _
				"&balance=" & Round($fBalance, 0) & _
				"&nocache=" & TimerInit()
		InetRead($sUrl, 1 + 16) ; Chạy nền nhanh, bỏ qua bộ nhớ đệm
	EndIf
EndFunc   ;==>_SyncLiveDashboard

; ==================================================================================================
; #Region 9. KIỂM TRA ĐẦU VÀO, NẠP & LƯU CẤU HÌNH (INI PROFILES) & TIỆN ÍCH HỆ THỐNG
; ==================================================================================================
Func _GetAndValidateInputs()
	$g_fInitialCapital = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialCapital), "[^0-9]", ""))
	$g_fInitialBet = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialBet), "[^0-9]", ""))

	If $g_fInitialBet <= 0 Then
		MsgBox(48, "Thiếu thông tin", "Vui lòng nhập 'Giá trị cược' lớn hơn 0!")
		Return False
	EndIf

	; Kiểm tra riêng cho chế độ Baccarat
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) <> $GUI_CHECKED Then
		If Not _ParseCustomQLVTable() Then Return False

		Local $sRules = StringStripWS(GUICtrlRead($g_hInput_CustomRules), 8)
		If $sRules == "" Then
			MsgBox(48, "Thiếu Công Thức", "Vui lòng nhập ít nhất 1 dòng công thức cược Baccarat!")
			Return False
		EndIf
	Else
		; Cập nhật lại Ma trận Xóc Đĩa VIP trước khi chạy
		_UpdateXocDiaGridUI()
	EndIf

	; Kiểm tra cấu hình Chip cược
	Local $bHasActiveChip = False
	For $i = 0 To 4
		If GUICtrlRead($g_aCheckbox_ChipEnabled[$i]) == $GUI_CHECKED Then
			Local $iChipVal = Number(StringRegExpReplace(GUICtrlRead($g_aInput_ChipValue[$i]), "[^0-9]", ""))
			Local $iChipX = Number(GUICtrlRead($g_aInput_ChipX[$i]))
			Local $iChipY = Number(GUICtrlRead($g_aInput_ChipY[$i]))
			If $iChipVal > 0 And $iChipX > 0 And $iChipY > 0 Then
				$bHasActiveChip = True
				ExitLoop
			EndIf
		EndIf
	Next

	If Not $bHasActiveChip Then
		MsgBox(48, "Lỗi Cấu Hình Chip", "Chưa có Chip cược nào hợp lệ được bật trong Phòng Kỹ Thuật!")
		Return False
	EndIf

	Return True
EndFunc   ;==>_GetAndValidateInputs

Func _ApplyCurrentSettings()
	$g_fInitialCapital = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialCapital), "[^0-9]", ""))
	$g_fInitialBet = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialBet), "[^0-9]", ""))

	$g_sGameWindowClass = GUICtrlRead($g_hInput_WindowClass)

	$g_aBankerButtonPos[0] = Number(GUICtrlRead($g_hInput_BankerX))
	$g_aBankerButtonPos[1] = Number(GUICtrlRead($g_hInput_BankerY))

	$g_aPlayerButtonPos[0] = Number(GUICtrlRead($g_hInput_PlayerX))
	$g_aPlayerButtonPos[1] = Number(GUICtrlRead($g_hInput_PlayerY))

	$g_aTieButtonPos[0] = Number(GUICtrlRead($g_hInput_TieX))
	$g_aTieButtonPos[1] = Number(GUICtrlRead($g_hInput_TieY))

	$g_iBankerColor = Number(GUICtrlRead($g_hInput_BankerColor))
	$g_iPlayerColor = Number(GUICtrlRead($g_hInput_PlayerColor))
	$g_iTieColor = Number(GUICtrlRead($g_hInput_TieColor))

	$g_aResultArea[0] = Number(GUICtrlRead($g_hInput_ResultX1))
	$g_aResultArea[1] = Number(GUICtrlRead($g_hInput_ResultY1))
	$g_aResultArea[2] = Number(GUICtrlRead($g_hInput_ResultX2))
	$g_aResultArea[3] = Number(GUICtrlRead($g_hInput_ResultY2))
	$g_iShade_Result = Number(GUICtrlRead($g_hInput_Shade_Result))

	$g_aBetTimeIndicatorArea[0] = Number(GUICtrlRead($g_hInput_BetTimeX1))
	$g_aBetTimeIndicatorArea[1] = Number(GUICtrlRead($g_hInput_BetTimeY1))
	$g_aBetTimeIndicatorArea[2] = Number(GUICtrlRead($g_hInput_BetTimeX2))
	$g_aBetTimeIndicatorArea[3] = Number(GUICtrlRead($g_hInput_BetTimeY2))
	$g_iBetTimeIndicatorColor = Number(GUICtrlRead($g_hInput_BetTimeColor))
	$g_iShade_Timer = Number(GUICtrlRead($g_hInput_Shade_Timer))

	For $i = 0 To 4
		$g_aChipConfig[$i][0] = (GUICtrlRead($g_aCheckbox_ChipEnabled[$i]) == $GUI_CHECKED)
		$g_aChipConfig[$i][1] = Number(StringRegExpReplace(GUICtrlRead($g_aInput_ChipValue[$i]), "[^0-9]", ""))
		$g_aChipConfig[$i][2] = Number(GUICtrlRead($g_aInput_ChipX[$i]))
		$g_aChipConfig[$i][3] = Number(GUICtrlRead($g_aInput_ChipY[$i]))
	Next

	$g_iClickDelay = Number(GUICtrlRead($g_hInput_ClickDelay_Main))
	$g_iMouseSpeed = Number(GUICtrlRead($g_hInput_MouseSpeed))

	$g_iLimitBtnX = Number(GUICtrlRead($g_hInput_LimitBtnX))
	$g_iLimitBtnY = Number(GUICtrlRead($g_hInput_LimitBtnY))
	$g_iLimit10_500X = Number(GUICtrlRead($g_hInput_Limit10_500X))
	$g_iLimit10_500Y = Number(GUICtrlRead($g_hInput_Limit10_500Y))
	$g_iLimit20_50KX = Number(GUICtrlRead($g_hInput_Limit20_50KX))
	$g_iLimit20_50KY = Number(GUICtrlRead($g_hInput_Limit20_50KY))
	$g_iLimitConfirmX = Number(GUICtrlRead($g_hInput_LimitConfirmX))
	$g_iLimitConfirmY = Number(GUICtrlRead($g_hInput_LimitConfirmY))

	_UpdateBalanceLabel()
	_UpdateProfitLabel()
EndFunc   ;==>_ApplyCurrentSettings

Func _LoadSettings()
	If Not FileExists($g_sIniPath) Then
		_CreateDefaultIniFile()
	EndIf

	_EnsureDefaultQLVExists()
	_PopulateQLVList()
	_PopulateProfileList()

	Local $sLastProfile = IniRead($g_sIniPath, "Settings", "LastProfile", "")
	If $sLastProfile == "" Then
		Local $aSections = IniReadSectionNames($g_sIniPath)
		If Not @error Then
			For $i = 1 To $aSections[0]
				If StringLeft($aSections[$i], 8) == "Profile_" Then
					$sLastProfile = StringTrimLeft($aSections[$i], 8)
					ExitLoop
				EndIf
			Next
		EndIf
	EndIf

	If $sLastProfile <> "" Then
		GUICtrlSetData($g_hCombo_Profiles, $sLastProfile)
		GUICtrlSetData($g_hCombo_Profiles_Main, $sLastProfile)
		_LoadSelectedProfile($sLastProfile)
	EndIf

	_ToggleGameModeUI()
	_RefreshVolumeDisplay()
EndFunc   ;==>_LoadSettings

Func _PopulateProfileList()
	Local $aSections = IniReadSectionNames($g_sIniPath)
	Local $sProfileList = "|"

	If Not @error Then
		For $i = 1 To $aSections[0]
			If StringLeft($aSections[$i], 8) == "Profile_" Then
				$sProfileList &= StringTrimLeft($aSections[$i], 8) & "|"
			EndIf
		Next
	EndIf

	GUICtrlSetData($g_hCombo_Profiles, $sProfileList)
	GUICtrlSetData($g_hCombo_Profiles_Main, $sProfileList)
EndFunc   ;==>_PopulateProfileList

Func _HandleProfileChange($hCombo)
	Local $sSelected = GUICtrlRead($hCombo)
	If $sSelected == "" Then Return

	If $hCombo == $g_hCombo_Profiles Then
		GUICtrlSetData($g_hCombo_Profiles_Main, $sSelected)
	Else
		GUICtrlSetData($g_hCombo_Profiles, $sSelected)
	EndIf

	_LoadSelectedProfile($sSelected)
	_ExecuteHideShow()
	_ToggleGameModeUI()
	IniWrite($g_sIniPath, "Settings", "LastProfile", $sSelected)
EndFunc   ;==>_HandleProfileChange

Func _LoadSelectedProfile($sProfileName)
	If $sProfileName == "" Then Return
	Local $sSection = "Profile_" & $sProfileName
	$g_sCurrentLoadedProfile = $sProfileName

	$g_bIsFormatting = True

	; 1. Vốn & Mục tiêu
	Local $sCap = IniRead($g_sIniPath, $sSection, "InitialCapital", "1.000.000")
	Local $sBet = IniRead($g_sIniPath, $sSection, "InitialBet", "10.000")
	GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber(Number(StringRegExpReplace($sCap, "[^0-9]", ""))))
	GUICtrlSetData($g_hInput_InitialBet, _FormatNumber(Number(StringRegExpReplace($sBet, "[^0-9]", ""))))

	GUICtrlSetState($g_hCheckbox_DailyShield, (IniRead($g_sIniPath, $sSection, "DailyShield", "1") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($g_hInput_DailyTarget, _FormatNumber(Number(StringRegExpReplace(IniRead($g_sIniPath, $sSection, "DailyTarget", "1.000.000"), "[^0-9]", ""))))
	GUICtrlSetData($g_hInput_DailyTrailing, _FormatNumber(Number(StringRegExpReplace(IniRead($g_sIniPath, $sSection, "DailyTrailing", "200.000"), "[^0-9]", ""))))
	Local $nStopLoss = Number(StringRegExpReplace(IniRead($g_sIniPath, $sSection, "DailyStopLoss", "-1.000.000"), "[^0-9]", ""))
	GUICtrlSetData($g_hInput_DailyStopLoss, "-" & _FormatNumber($nStopLoss))

	Local $sTargetAction = IniRead($g_sIniPath, $sSection, "TargetAction", "Stop")
	GUICtrlSetState($g_hRadio_Action_Stop, ($sTargetAction == "Stop") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($g_hRadio_Action_PauseMin, ($sTargetAction == "PauseMin") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($g_hRadio_Action_PauseHand, ($sTargetAction == "PauseHand") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($g_hInput_Action_PauseMin, IniRead($g_sIniPath, $sSection, "PauseMin", "15"))
	GUICtrlSetData($g_hInput_Action_PauseHand, IniRead($g_sIniPath, $sSection, "PauseHand", "5"))

	; 2. Công thức & QLV Baccarat
	GUICtrlSetState($g_hCheckbox_SeparateQLV, (IniRead($g_sIniPath, $sSection, "SeparateQLV", "0") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($g_hCheckbox_ReverseLogic, (IniRead($g_sIniPath, $sSection, "ReverseLogic", "0") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)

	Local $sCustomRules = IniRead($g_sIniPath, $sSection, "CustomRules", "BBB-B|NL|PPP-P")
	GUICtrlSetData($g_hInput_CustomRules, StringReplace($sCustomRules, "|NL|", @CRLF))

	Local $sQLVPreset = IniRead($g_sIniPath, $sSection, "QLVPreset", "Tùy chỉnh")
	GUICtrlSetData($g_hCombo_QLV_Presets, $sQLVPreset)
	Local $sCustomQLV = IniRead($g_sIniPath, $sSection, "CustomQLV", "0-1-0-1|NL|1-2-0-2|NL|2-4-0-3|NL|3-8-0-0")
	GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace($sCustomQLV, "|NL|", @CRLF))

	; 3. Cấu hình Xóc Đĩa VIP
	GUICtrlSetState($g_hCheckbox_XocDiaVIP, (IniRead($g_sIniPath, $sSection, "XocDiaVIP", "0") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($g_hCheckbox_BaccaratLaser, (IniRead($g_sIniPath, $sSection, "BaccaratLaser", "0") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($g_hInput_XD_Seq, IniRead($g_sIniPath, $sSection, "XD_Seq", "1, 2, 4, 8, 17, 35, 73, 152, 316, 655"))
	GUICtrlSetData($g_hInput_XD_MaxRows, IniRead($g_sIniPath, $sSection, "XD_MaxRows", "5"))
	GUICtrlSetData($g_hInput_XD_Virtual, IniRead($g_sIniPath, $sSection, "XD_Virtual", "1, 1, 1, 1, 1"))
	GUICtrlSetState($g_hCheckbox_XD_AntiKick, (IniRead($g_sIniPath, $sSection, "XD_AntiKickEnabled", "1") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($g_hInput_XD_AntiKick, IniRead($g_sIniPath, $sSection, "XD_AntiKick", "4"))
	GUICtrlSetData($g_hInput_XD_JumpLoss, IniRead($g_sIniPath, $sSection, "XD_JumpLoss", "1"))
	GUICtrlSetData($g_hInput_XD_JumpWin, IniRead($g_sIniPath, $sSection, "XD_JumpWin", "0"))

	Local $bIsSingleRow = (IniRead($g_sIniPath, $sSection, "XD_SingleRow", "0") == "1")
	GUICtrlSetState($g_hRadio_XD_SingleRow, $bIsSingleRow ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($g_hRadio_XD_MultiRow, $bIsSingleRow ? $GUI_UNCHECKED : $GUI_CHECKED)

	Local $bIsDemoKeep = (IniRead($g_sIniPath, $sSection, "XD_DemoKeep", "0") == "1")
	GUICtrlSetState($g_hRadio_XD_DemoKeep, $bIsDemoKeep ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetState($g_hRadio_XD_RealKeep, $bIsDemoKeep ? $GUI_UNCHECKED : $GUI_CHECKED)

	GUICtrlSetState($g_hCheckbox_XD_AutoResetDebt, (IniRead($g_sIniPath, $sSection, "XD_AutoResetDebt", "1") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
	GUICtrlSetData($g_hInput_XD_TargetProfit, _FormatNumber(Number(StringRegExpReplace(IniRead($g_sIniPath, $sSection, "XD_TargetProfit", "20.000"), "[^0-9]", ""))))
	GUICtrlSetState($g_hCheckbox_XD_ShareDebt, (IniRead($g_sIniPath, $sSection, "XD_ShareDebt", "1") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)

	GUICtrlSetData($g_hInput_LimitBtnX, IniRead($g_sIniPath, $sSection, "LimitBtnX", "0"))
	GUICtrlSetData($g_hInput_LimitBtnY, IniRead($g_sIniPath, $sSection, "LimitBtnY", "0"))
	GUICtrlSetData($g_hInput_Limit10_500X, IniRead($g_sIniPath, $sSection, "Limit10_500X", "0"))
	GUICtrlSetData($g_hInput_Limit10_500Y, IniRead($g_sIniPath, $sSection, "Limit10_500Y", "0"))
	GUICtrlSetData($g_hInput_Limit20_50KX, IniRead($g_sIniPath, $sSection, "Limit20_50KX", "0"))
	GUICtrlSetData($g_hInput_Limit20_50KY, IniRead($g_sIniPath, $sSection, "Limit20_50KY", "0"))
	GUICtrlSetData($g_hInput_LimitConfirmX, IniRead($g_sIniPath, $sSection, "LimitConfirmX", "0"))
	GUICtrlSetData($g_hInput_LimitConfirmY, IniRead($g_sIniPath, $sSection, "LimitConfirmY", "0"))

	; 4. Tọa độ & Màu sắc Phòng Kỹ Thuật
	GUICtrlSetData($g_hInput_WindowClass, IniRead($g_sIniPath, $sSection, "WindowClass", "Chrome_WidgetWin_1"))
	GUICtrlSetData($g_hInput_BankerX, IniRead($g_sIniPath, $sSection, "BankerX", "0"))
	GUICtrlSetData($g_hInput_BankerY, IniRead($g_sIniPath, $sSection, "BankerY", "0"))
	GUICtrlSetData($g_hInput_PlayerX, IniRead($g_sIniPath, $sSection, "PlayerX", "0"))
	GUICtrlSetData($g_hInput_PlayerY, IniRead($g_sIniPath, $sSection, "PlayerY", "0"))
	GUICtrlSetData($g_hInput_TieX, IniRead($g_sIniPath, $sSection, "TieX", "0"))
	GUICtrlSetData($g_hInput_TieY, IniRead($g_sIniPath, $sSection, "TieY", "0"))

	GUICtrlSetData($g_hInput_BankerColor, IniRead($g_sIniPath, $sSection, "BankerColor", "0xFF0000"))
	GUICtrlSetData($g_hInput_PlayerColor, IniRead($g_sIniPath, $sSection, "PlayerColor", "0x0000FF"))
	GUICtrlSetData($g_hInput_TieColor, IniRead($g_sIniPath, $sSection, "TieColor", "0x00FF00"))

	GUICtrlSetData($g_hInput_ResultX1, IniRead($g_sIniPath, $sSection, "ResultX1", "0"))
	GUICtrlSetData($g_hInput_ResultY1, IniRead($g_sIniPath, $sSection, "ResultY1", "0"))
	GUICtrlSetData($g_hInput_ResultX2, IniRead($g_sIniPath, $sSection, "ResultX2", "0"))
	GUICtrlSetData($g_hInput_ResultY2, IniRead($g_sIniPath, $sSection, "ResultY2", "0"))
	GUICtrlSetData($g_hInput_Shade_Result, IniRead($g_sIniPath, $sSection, "Shade_Result", "10"))

	GUICtrlSetData($g_hInput_BetTimeX1, IniRead($g_sIniPath, $sSection, "BetTimeX1", "0"))
	GUICtrlSetData($g_hInput_BetTimeY1, IniRead($g_sIniPath, $sSection, "BetTimeY1", "0"))
	GUICtrlSetData($g_hInput_BetTimeX2, IniRead($g_sIniPath, $sSection, "BetTimeX2", "0"))
	GUICtrlSetData($g_hInput_BetTimeY2, IniRead($g_sIniPath, $sSection, "BetTimeY2", "0"))
	GUICtrlSetData($g_hInput_BetTimeColor, IniRead($g_sIniPath, $sSection, "BetTimeColor", "0x00FF00"))
	GUICtrlSetData($g_hInput_Shade_Timer, IniRead($g_sIniPath, $sSection, "Shade_Timer", "20"))

	; 5. Chip Cược & Tốc độ Click
	For $i = 0 To 4
		Local $iIdx = $i + 1
		GUICtrlSetState($g_aCheckbox_ChipEnabled[$i], (IniRead($g_sIniPath, $sSection, "Chip" & $iIdx & "_Enabled", "0") == "1") ? $GUI_CHECKED : $GUI_UNCHECKED)
		GUICtrlSetData($g_aInput_ChipValue[$i], IniRead($g_sIniPath, $sSection, "Chip" & $iIdx & "_Value", "0"))
		GUICtrlSetData($g_aInput_ChipX[$i], IniRead($g_sIniPath, $sSection, "Chip" & $iIdx & "_X", "0"))
		GUICtrlSetData($g_aInput_ChipY[$i], IniRead($g_sIniPath, $sSection, "Chip" & $iIdx & "_Y", "0"))
	Next

	GUICtrlSetData($g_hInput_ClickDelay_Main, IniRead($g_sIniPath, $sSection, "ClickDelay", "150"))
	GUICtrlSetData($g_hInput_MouseSpeed, IniRead($g_sIniPath, $sSection, "MouseSpeed", "2"))

	$g_bIsFormatting = False

	_ApplyCurrentSettings()
	_UpdateXocDiaGridUI()
EndFunc   ;==>_LoadSelectedProfile

Func _MasterSave($sProfileName, $bSilent = False)
	#forceref $bSilent
	If $sProfileName == "" Then $sProfileName = $g_sCurrentLoadedProfile
	If $sProfileName == "" Then Return

	Local $sSection = "Profile_" & $sProfileName
	IniWrite($g_sIniPath, "Settings", "LastProfile", $sProfileName)

	; 1. Vốn & Mục tiêu
	IniWrite($g_sIniPath, $sSection, "InitialCapital", GUICtrlRead($g_hInput_InitialCapital))
	IniWrite($g_sIniPath, $sSection, "InitialBet", GUICtrlRead($g_hInput_InitialBet))
	IniWrite($g_sIniPath, $sSection, "DailyShield", (GUICtrlRead($g_hCheckbox_DailyShield) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "DailyTarget", GUICtrlRead($g_hInput_DailyTarget))
	IniWrite($g_sIniPath, $sSection, "DailyTrailing", GUICtrlRead($g_hInput_DailyTrailing))
	IniWrite($g_sIniPath, $sSection, "DailyStopLoss", GUICtrlRead($g_hInput_DailyStopLoss))

	Local $sTargetAction = "Stop"
	If GUICtrlRead($g_hRadio_Action_PauseMin) == $GUI_CHECKED Then $sTargetAction = "PauseMin"
	If GUICtrlRead($g_hRadio_Action_PauseHand) == $GUI_CHECKED Then $sTargetAction = "PauseHand"
	IniWrite($g_sIniPath, $sSection, "TargetAction", $sTargetAction)
	IniWrite($g_sIniPath, $sSection, "PauseMin", GUICtrlRead($g_hInput_Action_PauseMin))
	IniWrite($g_sIniPath, $sSection, "PauseHand", GUICtrlRead($g_hInput_Action_PauseHand))

	; 2. Công thức & QLV Baccarat
	IniWrite($g_sIniPath, $sSection, "SeparateQLV", (GUICtrlRead($g_hCheckbox_SeparateQLV) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "ReverseLogic", (GUICtrlRead($g_hCheckbox_ReverseLogic) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "CustomRules", StringReplace(GUICtrlRead($g_hInput_CustomRules), @CRLF, "|NL|"))
	IniWrite($g_sIniPath, $sSection, "QLVPreset", GUICtrlRead($g_hCombo_QLV_Presets))
	IniWrite($g_sIniPath, $sSection, "CustomQLV", StringReplace(GUICtrlRead($g_hInput_CustomQLV_Edit), @CRLF, "|NL|"))

	; 3. Cấu hình Xóc Đĩa VIP
	IniWrite($g_sIniPath, $sSection, "XocDiaVIP", (GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "BaccaratLaser", (GUICtrlRead($g_hCheckbox_BaccaratLaser) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "XD_Seq", GUICtrlRead($g_hInput_XD_Seq))
	IniWrite($g_sIniPath, $sSection, "XD_MaxRows", GUICtrlRead($g_hInput_XD_MaxRows))
	IniWrite($g_sIniPath, $sSection, "XD_Virtual", GUICtrlRead($g_hInput_XD_Virtual))
	IniWrite($g_sIniPath, $sSection, "XD_AntiKickEnabled", (GUICtrlRead($g_hCheckbox_XD_AntiKick) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "XD_AntiKick", GUICtrlRead($g_hInput_XD_AntiKick))
	IniWrite($g_sIniPath, $sSection, "XD_JumpLoss", GUICtrlRead($g_hInput_XD_JumpLoss))
	IniWrite($g_sIniPath, $sSection, "XD_JumpWin", GUICtrlRead($g_hInput_XD_JumpWin))
	IniWrite($g_sIniPath, $sSection, "XD_SingleRow", (GUICtrlRead($g_hRadio_XD_SingleRow) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "XD_DemoKeep", (GUICtrlRead($g_hRadio_XD_DemoKeep) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "XD_AutoResetDebt", (GUICtrlRead($g_hCheckbox_XD_AutoResetDebt) == $GUI_CHECKED) ? "1" : "0")
	IniWrite($g_sIniPath, $sSection, "XD_TargetProfit", GUICtrlRead($g_hInput_XD_TargetProfit))
	IniWrite($g_sIniPath, $sSection, "XD_ShareDebt", (GUICtrlRead($g_hCheckbox_XD_ShareDebt) == $GUI_CHECKED) ? "1" : "0")

	IniWrite($g_sIniPath, $sSection, "LimitBtnX", GUICtrlRead($g_hInput_LimitBtnX))
	IniWrite($g_sIniPath, $sSection, "LimitBtnY", GUICtrlRead($g_hInput_LimitBtnY))
	IniWrite($g_sIniPath, $sSection, "Limit10_500X", GUICtrlRead($g_hInput_Limit10_500X))
	IniWrite($g_sIniPath, $sSection, "Limit10_500Y", GUICtrlRead($g_hInput_Limit10_500Y))
	IniWrite($g_sIniPath, $sSection, "Limit20_50KX", GUICtrlRead($g_hInput_Limit20_50KX))
	IniWrite($g_sIniPath, $sSection, "Limit20_50KY", GUICtrlRead($g_hInput_Limit20_50KY))
	IniWrite($g_sIniPath, $sSection, "LimitConfirmX", GUICtrlRead($g_hInput_LimitConfirmX))
	IniWrite($g_sIniPath, $sSection, "LimitConfirmY", GUICtrlRead($g_hInput_LimitConfirmY))

	; 4. Tọa độ & Màu sắc Phòng Kỹ Thuật
	IniWrite($g_sIniPath, $sSection, "WindowClass", GUICtrlRead($g_hInput_WindowClass))
	IniWrite($g_sIniPath, $sSection, "BankerX", GUICtrlRead($g_hInput_BankerX))
	IniWrite($g_sIniPath, $sSection, "BankerY", GUICtrlRead($g_hInput_BankerY))
	IniWrite($g_sIniPath, $sSection, "PlayerX", GUICtrlRead($g_hInput_PlayerX))
	IniWrite($g_sIniPath, $sSection, "PlayerY", GUICtrlRead($g_hInput_PlayerY))
	IniWrite($g_sIniPath, $sSection, "TieX", GUICtrlRead($g_hInput_TieX))
	IniWrite($g_sIniPath, $sSection, "TieY", GUICtrlRead($g_hInput_TieY))

	IniWrite($g_sIniPath, $sSection, "BankerColor", GUICtrlRead($g_hInput_BankerColor))
	IniWrite($g_sIniPath, $sSection, "PlayerColor", GUICtrlRead($g_hInput_PlayerColor))
	IniWrite($g_sIniPath, $sSection, "TieColor", GUICtrlRead($g_hInput_TieColor))

	IniWrite($g_sIniPath, $sSection, "ResultX1", GUICtrlRead($g_hInput_ResultX1))
	IniWrite($g_sIniPath, $sSection, "ResultY1", GUICtrlRead($g_hInput_ResultY1))
	IniWrite($g_sIniPath, $sSection, "ResultX2", GUICtrlRead($g_hInput_ResultX2))
	IniWrite($g_sIniPath, $sSection, "ResultY2", GUICtrlRead($g_hInput_ResultY2))
	IniWrite($g_sIniPath, $sSection, "Shade_Result", GUICtrlRead($g_hInput_Shade_Result))

	IniWrite($g_sIniPath, $sSection, "BetTimeX1", GUICtrlRead($g_hInput_BetTimeX1))
	IniWrite($g_sIniPath, $sSection, "BetTimeY1", GUICtrlRead($g_hInput_BetTimeY1))
	IniWrite($g_sIniPath, $sSection, "BetTimeX2", GUICtrlRead($g_hInput_BetTimeX2))
	IniWrite($g_sIniPath, $sSection, "BetTimeY2", GUICtrlRead($g_hInput_BetTimeY2))
	IniWrite($g_sIniPath, $sSection, "BetTimeColor", GUICtrlRead($g_hInput_BetTimeColor))
	IniWrite($g_sIniPath, $sSection, "Shade_Timer", GUICtrlRead($g_hInput_Shade_Timer))

	; 5. Chip Cược & Tốc độ Click
	For $i = 0 To 4
		Local $iIdx = $i + 1
		IniWrite($g_sIniPath, $sSection, "Chip" & $iIdx & "_Enabled", (GUICtrlRead($g_aCheckbox_ChipEnabled[$i]) == $GUI_CHECKED) ? "1" : "0")
		IniWrite($g_sIniPath, $sSection, "Chip" & $iIdx & "_Value", GUICtrlRead($g_aInput_ChipValue[$i]))
		IniWrite($g_sIniPath, $sSection, "Chip" & $iIdx & "_X", GUICtrlRead($g_aInput_ChipX[$i]))
		IniWrite($g_sIniPath, $sSection, "Chip" & $iIdx & "_Y", GUICtrlRead($g_aInput_ChipY[$i]))
	Next

	IniWrite($g_sIniPath, $sSection, "ClickDelay", GUICtrlRead($g_hInput_ClickDelay_Main))
	IniWrite($g_sIniPath, $sSection, "MouseSpeed", GUICtrlRead($g_hInput_MouseSpeed))
EndFunc   ;==>_MasterSave

Func _CreateDefaultIniFile()
	Local $sDefSection = "Profile_Sảnh PP Mẫu"
	IniWrite($g_sIniPath, "Settings", "LastProfile", "Sảnh PP Mẫu")
	IniWrite($g_sIniPath, $sDefSection, "InitialCapital", "1.000.000")
	IniWrite($g_sIniPath, $sDefSection, "InitialBet", "10.000")
	IniWrite($g_sIniPath, $sDefSection, "WindowClass", "Chrome_WidgetWin_1")
	IniWrite($g_sIniPath, $sDefSection, "CustomRules", "BBB-B|NL|PPP-P")
	IniWrite($g_sIniPath, $sDefSection, "CustomQLV", "0-1-0-1|NL|1-2-0-2|NL|2-4-0-3|NL|3-8-0-0")
	IniWrite($g_sIniPath, $sDefSection, "Chip1_Enabled", "1")
	IniWrite($g_sIniPath, $sDefSection, "Chip1_Value", "10000")
EndFunc   ;==>_CreateDefaultIniFile

Func _UpdateStatus($sMessage)
	Local $sTime = StringFormat("[%02d:%02d:%02d] ", @HOUR, @MIN, @SEC)
	Local $sCurrentLog = GUICtrlRead($g_hEdit_ActivityLog)

	; Giới hạn độ dài Log tối đa ~4000 ký tự để tránh tràn RAM khi treo 24/7
	If StringLen($sCurrentLog) > 4000 Then
		$sCurrentLog = StringLeft($sCurrentLog, 3000)
	EndIf

	GUICtrlSetData($g_hEdit_ActivityLog, $sTime & $sMessage & @CRLF & $sCurrentLog)
EndFunc   ;==>_UpdateStatus

Func _FormatNumber($nNumber)
	Local $bIsNegative = ($nNumber < 0)
	Local $sNum = String(Round(Abs($nNumber), 0))
	Local $sFormatted = StringRegExpReplace($sNum, '(\d)(?=(\d{3})+(?!\d))', '$1.')
	If $bIsNegative Then Return "-" & $sFormatted
	Return $sFormatted
EndFunc   ;==>_FormatNumber
#EndRegion 8. RẢI CHIP CƯỢC, CÔNG CỤ PHÒNG KỸ THUẬT, THỐNG KÊ & LƯU CẤU HÌNH
