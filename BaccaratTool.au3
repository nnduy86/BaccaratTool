#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <StaticConstants.au3>
#include <ComboConstants.au3>
#include <ButtonConstants.au3>
#include <EditConstants.au3>
#include <GuiComboBox.au3>
#include <Date.au3>
#include <Inet.au3>
#include <WinAPI.au3>
#include <AutoItConstants.au3>
#include <Array.au3>
#include <GuiListView.au3>
#include <Misc.au3>
#include "Json.au3"
; --- ÉP CHUẨN MÔI TRƯỜNG ĐỂ CHỐNG LỆCH TỌA ĐỘ TRÊN MÁY KHÁCH ---
Opt("MouseCoordMode", 1)  ; 1 = Chuột dùng Tọa độ tuyệt đối toàn màn hình
Opt("PixelCoordMode", 1)  ; 1 = Quét màu dùng Tọa độ tuyệt đối toàn màn hình
;Opt("ColorMode", 0)       ; 0 = Đọc mã màu chuẩn RGB (Không bị đảo ngược xanh/đỏ)

; <<<< Yêu cầu quyền quản trị để tool hoạt động ổn định >>>>
#RequireAdmin
; ==================================================================================================
; --- PHẦN CẤU HÌNH (BẮT BUỘC) ---
; ==================================================================================================
Global Const $g_sAppsScriptBaseURL = "https://script.google.com/macros/s/AKfycbzYsojeFPtUJNwNKMMclP7zuj9TO6XYyq16O02Pi-ef87OP2kYz3TV3kT02XBw_GXuE/exec"
Global Const $g_sDevPassword = "nmn12nntv21"
Global Const $g_sToolName = "Tool-Baccarat"
; --- CẤU HÌNH AUTO UPDATE GITHUB ---
Global Const $g_sVersion = "4.0" ; Phiên bản hiện tại
Global Const $g_sCopyright = "Thuộc Bản Quyền Telegram @nnduy2086"
Global Const $g_sGithubVersionURL = "https://raw.githubusercontent.com/nnduy86/BaccaratTool/main/version.txt"
Global Const $g_sDownloadURL = "https://github.com/nnduy86/BaccaratTool/raw/main/BaccaratTool.exe"
; --- KHAI BÁO BIẾN TOÀN CỤC ---
; ==================================================================================================
Global Const $g_iTimeOutLimit = 45000
Global $g_bIsRunning = False
Global $g_sIniPath
Global $g_hCheckbox_DuKich
Global $g_bIsFormatting = False
Global $g_sInstanceIdentifier
Global $g_hSessionTimer
Global $g_sCurrentLoadedProfile = ""
Global $g_hCheckbox_ContinuousMode
Global $g_hTargetGameWin = 0
Global $g_sCurrentRuleSignature = "Global"
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
Global $g_hMenu_AnalyzeQLV ; Nút menu chuột phải
Global $g_hAnalysisGUI = 0 ; Biến lưu cửa sổ phân tích Pro
Global $g_hCombo_ProfitFilter, $g_hDate_ProfitFilter, $g_hLabel_TotalProfitStats
Global $g_hLabel_VaultTotal
; --- HỆ THỐNG VAULT BẤT TỬ & V8 OMNI-ENGINE ---
Global Const $VAULT_MAX_SIZE = 50000000 ; 50 Triệu ván cược (Kho giãn nở an toàn, ko bao giờ bị reset)
Global Const $VAULT_FILE = @AppDataDir & "\System_WinSrv_Cache.dat"
Global $g_hVolumeGUI = 0
Global $g_hCheckbox_ReverseLogic
; --- BIẾN CHO GIAO DIỆN PHÂN TÍCH SONG SONG (MODELESS) ---
Global $g_hAnalysisGUI = 0
Global $g_hSim_List, $g_hSim_BtnRun
Global $g_hSim_BtnInspect = 0
Global $g_hSim_Edit_Inspector = 0
Global $g_hSim_Chk_Cont, $g_hSim_Chk_Sep, $g_hSim_Chk_Rev
Global $g_sSim_Formula = ""
Global $g_hCombo_DailyData = 0
Global $g_hLabel_VaultTotalNum = 0
Global $g_hInput_ProfileName
Global $g_hCheckbox_LaiKepVIP
Global $g_hSim_Combo_TestMode
Global $g_sLastCheckedVIPList = ""
; === BIẾN QUẢN LÝ CỬA HÀNG VIP ===
Global $g_hListView_VIP
Global $g_hBtn_ActionVIP
Global $g_sAppliedVIPCode = "NONE" ; Lưu mã VIP đang được khách sử dụng (Mặc định là NONE)
Global $g_sAppliedVIPName = "Không dùng"
; =====================================================================
; KHAI BÁO BIẾN TOÀN CỤC CHO HỆ THỐNG
; (Để dưới cùng của phần #include)
; =====================================================================
Global $g_sHWID = ""
; --- BIẾN CHO HỆ THỐNG MÔ PHỎNG CHẠY NGẦM ---
; --- SỬA TỪ [8] THÀNH [10] ---
Global $g_aVirtualQLVs[0][2]
Global $g_aRawStats[0][75]
Global $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter ; Thêm biến Lịch
; --- BIẾN CHO CHIẾN THUẬT DU KÍCH ---
Global $g_iWaitTimeEnd_DuKich = 0
Global $g_iWaitDuration_DuKich = 0
Global $g_iSkipSignalsCount_DuKich = 0

Global $g_hEdit_Checksheet = 0
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
Global $g_hGUI, $g_hTab
Global $g_hTabItemConfig
Global $g_hInput_InitialCapital, $g_hInput_InitialBet, $g_hInput_TakeProfit, $g_hInput_StopLoss
Global $g_hLabel_CurrentBalance, $g_hLabel_Profit, $g_hLabel_TotalHands, $g_hLabel_ExpiryDate, $g_hLabel_DaysRemaining
Global $g_hLabel_TotalVolume
Global $g_hButton_Start, $g_hButton_Stop
Global $g_aLabel_History[120]
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
Global $g_aCheckbox_ChipEnabled[5], $g_aInput_ChipValue[5], $g_aInput_ChipX[5], $g_aInput_ChipY[5], $g_aButton_GetChipPos[5]
Global $g_iMouseSpeed = 0 ; 0 là tức thì, 10 là mặc định chậm
Global $g_hInput_MouseSpeed ; Biến cho ô nhập liệu
Global $g_hCombo_Profiles
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
Global $g_sLastBetOn = ""
Global $g_fTotalVolume = 0.0
Global $g_aDisplayHistory[0]
Global Const $g_iHighlightColor = 0xFFFFE0
Global Const $g_iLatestHighlightColor = 0xADD8E6
Global $g_iTotalBanker = 0, $g_iTotalPlayer = 0, $g_iTotalTie = 0
Global Const $g_sQLVMode = "Flexible" ; [CỐ ĐỊNH] Luôn là Flexible
Global $g_aCustomQLVTable[0][4] ; [Lệnh, Vốn, ThắngVề, ThuaVề]
Global $g_iCapitalLevel = 1 ; Cấp vốn hiện tại (1, 2, 3...)
Global $g_hInput_Blacklist       ; Ô nhập danh sách đen
Global $g_iCycleStep = 1      ; Biến đếm bước trong chu kỳ quan sát
Global Const $HARD_LIMIT_RAM = 500 ; <--- THÊM DÒNG NÀY (Giới hạn cứng bộ nhớ)
Global $g_hEdit_ActivityLog
Global $g_hCheckbox_Blacklist_IgnoreRunning ; <--- [MỚI] Biến Checkbox bỏ qua Blacklist khi đang chạy
Global $g_hSim_Chk_MixMode = 0
Global $g_hInput_TrailingStop
Global $g_fPeakProfit = 0.0
Global $g_bIsTrailingMode = False

Global $g_hCheckbox_VirtualBet
Global $g_iVirtualLosses = 0
Global $g_bIsRealBetting = True

Global $g_fUnsyncedVolume = 0 ; Lưu trữ Volume chưa đẩy lên Server

Global $g_bIsVIP = False
Global $g_iVipDaysLeft = 0
Global $g_hCombo_VIPMethod
Global $g_hBtn_BuyVIP
Global $g_sActiveVIPs = "" ; Lưu danh sách các gói VIP đang được phép dùng

; BẢNG GIÁ ĐA PHƯƠNG PHÁP (Mã Gói | Tên Hiển Thị | Giá Tiền)
; === BẢNG GIÁ VIP (Mã | Tên | Giá | Đơn vị tính) ===
; === BẢNG GIÁ VIP (Mã | Tên | Giá | Đơn vị tính) ===
; === BẢNG GIÁ VIP (Chỉ hiển thị Phương pháp Cược) ===
Global $g_aVipPackages[2][4] = [ _
		["NONE", "CÔNG THỨC CUSTOM (Nhập tay)", 0, "Miễn Phí"], _
		["HK5", "MA TRẬN HONG KONG 5 CỘT", 70000, "Ngày"] _
		]
Global $g_bIsDevMode = False ; Biến ẩn chỉ dành cho Developer

Global $g_sMachineStatus = "" ; Theo dõi trạng thái máy (Mới/Đã Kích Hoạt)
Global $g_hButton_ActivateNew = 0 ; Nút bấm kích hoạt 100k

Global $g_fServerVolumeToday = 0 ; Biến lưu Volume thực tế từ máy chủ
_Main()

Func _Main()
	If _Singleton("ToolCasino_Lock_Main", 1) = 0 Then
		MsgBox(48, "Thông báo", "Tool đang được mở rồi!")
		Exit
	EndIf

	Sleep(500)
	_CheckForUpdates()
	$g_sHWID = _GetHardwareID()

	; Lên Server kiểm tra
	Local $aLicenseInfo = _CheckLicenseOnline($g_sHWID)
	$g_sMachineStatus = $aLicenseInfo[0]

	; ==========================================================
	; ĐỒNG BỘ VOLUME THỰC TẾ TỪ MÁY CHỦ VỀ LƯU VÀO MÁY KHÁCH
	; ==========================================================
	IniWrite(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), $g_fServerVolumeToday)

	; NẾU NỢ HOA HỒNG THÌ ÉP TRẢ NỢ MỚI CHO VÀO
	If $g_sMachineStatus == "DEBT" Then
		Local $iDebt = $aLicenseInfo[1]
		_ShowDebtDialog($iDebt, $g_sHWID)

		; Khách trả nợ xong, kiểm tra lại
		$aLicenseInfo = _CheckLicenseOnline($g_sHWID)
		$g_sMachineStatus = $aLicenseInfo[0]
	EndIf

	; --- CỨ MỞ GIAO DIỆN CHO KHÁCH NGẮM ---
	If $g_sMachineStatus == "OK" Then
		$g_sExpiryDate = "Vĩnh viễn"
	Else
		$g_sExpiryDate = "Chưa kích hoạt"
	EndIf

	_CreateGUI($g_sExpiryDate)
	AdlibRegister("_CheckVIPStateChanges", 200) ; <--- Chèn dòng này vào đây
	_MainLoop()
	_UpdateVIPListUI()
EndFunc   ;==>_Main
Func _CreateGUI($sExpiryDate)
	$g_hGUI = GUICreate("Tool-AIO_" & $g_sVersion & $g_sInstanceIdentifier & " | " & $g_sCopyright, 1280, 840, -1, -1, -1, $WS_EX_CLIENTEDGE)

	FileInstall("hinhnen.jpg", @TempDir & "\hinhnen_temp.jpg", 1)
	Local $hBgPic = GUICtrlCreatePic(@TempDir & "\hinhnen_temp.jpg", 0, 30, 1280, 810)
	GUICtrlSetState($hBgPic, $GUI_DISABLE)

	GUISetFont(10, 400, 0, "Arial")
	GUIRegisterMsg($WM_COMMAND, "WM_COMMAND_Handler")

	$g_hTab = GUICtrlCreateTab(5, 5, 1270, 830)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)
	GUICtrlSetFont(-1, 10, 700)

	Local $hTab1 = GUICtrlCreateTabItem("Giao Diện Chính")
	_CreateTab_MainTool()

	$g_hTabItemConfig = GUICtrlCreateTabItem("Phòng Kỹ Thuật")
	_CreateTab_ConfigHelper()
	GUICtrlCreateTabItem("")

	_LoadSettings()
	_SetControlsState(True)
	_ToggleConfigControlsState(False)

	; ĐÃ TẮT: AdlibRegister("_UpdateClock", 1000)
	_UpdateClock() ; Chỉ in giờ 1 lần duy nhất lúc mở phần mềm cho nhẹ máy

	If $g_bStartHidden Then
		GUISetState(@SW_HIDE, $g_hGUI)
	Else
		GUISetState(@SW_SHOW, $g_hGUI)
	EndIf
EndFunc   ;==>_CreateGUI
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
EndFunc   ;==>_CreateTab_MainTool
; ==================================================================================================
; HÀM VÒNG LẶP CHÍNH
; ==================================================================================================
Func _MainLoop()
	AdlibRegister("_CheckForUpdates", 60000)
	While 1
		If $g_bNeedAutoSave And TimerDiff($g_hAutoSaveTimer) > 1000 Then
			If $g_sCurrentLoadedProfile <> "" Then _MasterSave($g_sCurrentLoadedProfile)
			$g_bNeedAutoSave = False
		EndIf

		Local $aMsg = GUIGetMsg(1)

		Local $aInputs[3] = [$g_hInput_TakeProfit, $g_hInput_TrailingStop, $g_hInput_StopLoss]
		For $i = 0 To 2
			Local $sRawVal = GUICtrlRead($aInputs[$i])
			If $sRawVal <> "" Then
				Local $sFormatted = _FormatMoneyVN($sRawVal)
				If $sRawVal <> $sFormatted Then GUICtrlSetData($aInputs[$i], $sFormatted)
			EndIf
		Next

		If $g_hAnalysisGUI <> 0 Then
			If $aMsg[1] = $g_hAnalysisGUI And $aMsg[0] = $GUI_EVENT_CLOSE Then
				GUIDelete($g_hAnalysisGUI)
				$g_hAnalysisGUI = 0
			ElseIf $aMsg[0] = $g_hSim_BtnRun Then
			EndIf
		EndIf

		Switch $aMsg[0]
			Case 0
				ContinueLoop
			Case $g_hRadio_ClickMode_Control_Main, $g_hRadio_ClickMode_Mouse_Main
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
			Case $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter
				_RefreshVolumeDisplay()
			Case $g_hCombo_ProfitFilter, $g_hDate_ProfitFilter
				_RefreshProfitDisplay()
			Case $GUI_EVENT_CLOSE
				If $aMsg[1] = $g_hGUI Then
					_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
					Exit
				EndIf
			Case $g_hCheckbox_LaiKepVIP
				; Khi user tự tay bấm vào ô Checkbox Lãi Kép
				If GUICtrlRead($g_hCheckbox_LaiKepVIP) = $GUI_CHECKED Then
					Local $bOwned = False
					If $g_bIsDevMode Then $bOwned = True
					If StringInStr("," & $g_sActiveVIPs & ",", ",LAIKEP,") Then $bOwned = True

					If Not $bOwned Then
						; Chặn không cho tick, đá văng cái tick đi
						GUICtrlSetState($g_hCheckbox_LaiKepVIP, $GUI_UNCHECKED)
						; Tự động bật bảng QR đòi tiền đúng 20.000đ/Ngày
						_ShowVIPPaymentDialog("LAIKEP", "TÍNH NĂNG GỒNG LÃI KÉP", 20000, $g_sHWID)
					EndIf
				EndIf
			Case $g_hListView_VIP
				_ProcessVIPListCheckboxes()
			Case $g_hButton_Start
				If $g_bIsRunning Then
					_StopProcess()
				Else
					$g_bManualStopped = False
					Local $sClass = GUICtrlRead($g_hInput_WindowClass)
					If $g_hTargetGameWin = 0 Or Not WinExists($g_hTargetGameWin) Then
						GUICtrlSetState($g_hButton_Start, $GUI_DISABLE)
						GUICtrlSetData($g_hButton_Start, "CHỜ THAO TÁC...")
						_WaitManualAction_Pro("1. Vui lòng TỰ MỞ trình duyệt" & @CRLF & "2. Đăng nhập và vào thẳng sảnh game." & @CRLF & "3. ĐỂ TRÌNH DUYỆT ĐANG HIỂN THỊ, rồi bấm TIẾP TỤC.")
						$g_hTargetGameWin = _GetRealGameWindow($sClass)
					EndIf

					If $g_hTargetGameWin <> 0 And WinExists($g_hTargetGameWin) Then
						_UpdateStatus("✅ Đã móc nối thành công vào trình duyệt thật! Bắt đầu quét...")
						GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
						_StartProcess()
					Else
						_UpdateStatus("🛑 Lỗi: Không tìm thấy cửa sổ game ĐANG HIỂN THỊ!")
						GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
						GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
						$g_hTargetGameWin = 0
					EndIf
				EndIf
			Case $g_hButton_Stop
				_SyncVolumeToServer()
				_StopProcess()
			Case $g_hButton_Unlock
				_HandleUnlock()
			Case $g_hButton_Lock
				$g_bIsDevMode = False
				_UpdateVIPListUI()
				_ToggleConfigControlsState(False)
			Case $g_hButton_ActivateNew
				_ShowActivationDialog_New($g_sHWID)
				Local $aCheck = _CheckLicenseOnline($g_sHWID)
				$g_sMachineStatus = $aCheck[0]
				If $g_sMachineStatus == "OK" Then
					GUICtrlSetState($g_hButton_ActivateNew, $GUI_HIDE)
					GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
					GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
					GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
					_UpdateStatus("✅ Đã kích hoạt vĩnh viễn thành công!")
				EndIf
			Case $g_hCheckbox_ToggleScan
				_ToggleScanHotkey()
			Case $g_hCheckbox_ContinuousMode
				If GUICtrlRead($g_hCheckbox_ContinuousMode) = $GUI_CHECKED Then
					GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_UNCHECKED)
					GUICtrlSetState($g_hCheckbox_DuKich, $GUI_UNCHECKED)
				EndIf
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
			Case $g_hCheckbox_ReverseLogic
				If GUICtrlRead($g_hCheckbox_ReverseLogic) = $GUI_CHECKED Then
					GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_UNCHECKED)
					GUICtrlSetState($g_hCheckbox_DuKich, $GUI_UNCHECKED)
				EndIf
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
			Case $g_hCheckbox_DuKich
				If GUICtrlRead($g_hCheckbox_DuKich) = $GUI_CHECKED Then
					GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_UNCHECKED)
					GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_UNCHECKED)
				EndIf
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
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
; ==================================================================================================
; HÀM VÒNG LẶP PHỤ (KHI TOOL ĐANG QUÉT GAME)
; ==================================================================================================
Func _ProcessGUIMessages()
	;AdlibRegister("_SyncVolumeToServer", 180000)
	Local $aMsg = GUIGetMsg(1)

	Local $aInputs[3] = [$g_hInput_TakeProfit, $g_hInput_TrailingStop, $g_hInput_StopLoss]
	For $i = 0 To 2
		Local $sRawVal = GUICtrlRead($aInputs[$i])
		If $sRawVal <> "" Then
			Local $sFormatted = _FormatMoneyVN($sRawVal)
			If $sRawVal <> $sFormatted Then
				GUICtrlSetData($aInputs[$i], $sFormatted)
			EndIf
		EndIf
	Next

	If $g_hVolumeGUI <> 0 Then
		If $aMsg[1] = $g_hVolumeGUI And $aMsg[0] = $GUI_EVENT_CLOSE Then
			GUIDelete($g_hVolumeGUI)
			$g_hVolumeGUI = 0
		EndIf
	EndIf

	If $g_hAnalysisGUI <> 0 Then
		If $aMsg[1] = $g_hAnalysisGUI And $aMsg[0] = $GUI_EVENT_CLOSE Then
			GUIDelete($g_hAnalysisGUI)
			$g_hAnalysisGUI = 0
		ElseIf $aMsg[0] = $g_hSim_BtnRun Then
		ElseIf $aMsg[0] = $g_hSim_BtnInspect Then
			_RunAI_Inspector()
		EndIf
	EndIf

	Switch $aMsg[0]
		Case $GUI_EVENT_CLOSE
			_SyncVolumeToServer()
			If $aMsg[1] = $g_hGUI Then
				_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
				Exit
			EndIf
		Case $g_hButton_Start
			If $g_bIsRunning Then _StopProcess()
		Case $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter
			_RefreshVolumeDisplay()
		Case $g_hCombo_ProfitFilter, $g_hDate_ProfitFilter
			_RefreshProfitDisplay()
	EndSwitch
EndFunc   ;==>_ProcessGUIMessages
Func _CreateStyledGroup($sTitle, $iX, $iY, $iW, $iH)
	Local $hGroup = GUICtrlCreateGroup($sTitle, $iX, $iY, $iW, $iH, $WS_GROUP, $WS_EX_CLIENTEDGE)
	GUICtrlSetFont($hGroup, 10, 700)
	GUICtrlSetColor($hGroup, 0x0000FF)
	GUICtrlSetBkColor($hGroup, 0xF5F5F5)
	Return $hGroup
EndFunc   ;==>_CreateStyledGroup

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
EndFunc   ;==>_CreateGroup_Settings

Func _CreateGroup_BettingMethod()
	; Đã dọn dẹp sạch sẽ phần VIP ở đây để giao diện thoáng hơn
	_CreateStyledGroup("Phương Pháp Cược & Tín Hiệu", 10, 165, 320, 420)
	Local $x_label = 20, $y = 190

	GUICtrlCreateLabel("Nhập công thức cược tự do:", $x_label, $y, 300, 20)
	GUICtrlSetFont(-1, 9, 700)
	GUICtrlSetColor(-1, 0x0000FF)
	$y += 25

	; Kéo dài ô nhập công thức ra vì đã có nhiều không gian hơn
	$g_hInput_CustomRules = GUICtrlCreateEdit("", $x_label, $y, 280, 160, BitOR(0x00200000, 0x00000040, 0x00001000))
	GUICtrlSetFont(-1, 10)
	GUICtrlSetBkColor(-1, 0xFFFACD)
	$y += 180

	$g_hCheckbox_SeparateQLV = GUICtrlCreateCheckbox("QLV Riêng Biệt (Từng dòng độc lập)", $x_label, $y, 300, 20)
	GUICtrlSetFont(-1, 9, 600)
	$y += 35

	$g_hCheckbox_ContinuousMode = GUICtrlCreateCheckbox("Đánh Nối Đuôi (Theo sát cầu)", $x_label, $y, 300, 20)
	GUICtrlSetFont(-1, 9, 600)
	$y += 35

	$g_hCheckbox_DuKich = GUICtrlCreateCheckbox("Du Kích (Thắng nghỉ 5p, Thua bỏ 10 tay)", $x_label, $y, 300, 20)
	GUICtrlSetFont(-1, 9, 600)
	GUICtrlSetColor(-1, 0x008000)
	$y += 35

	$g_hCheckbox_VirtualBet = GUICtrlCreateCheckbox("Đánh Nháp Tình Báo (Chờ gãy 3 lệnh)", $x_label, $y, 300, 20)
	GUICtrlSetFont(-1, 9, 700)
	GUICtrlSetColor(-1, 0x8A2BE2)
	$y += 35 ; Tăng Y lên để tạo dòng mới

	; === THÊM Ô TÍCH LÃI KÉP VÀO ĐÂY ===
	$g_hCheckbox_LaiKepVIP = GUICtrlCreateCheckbox("💎 Gồng Lãi Kép (Kết hợp mọi công thức)", $x_label, $y, 300, 20)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0xFF00FF) ; Màu hồng VIP cho ngầu
EndFunc   ;==>_CreateGroup_BettingMethod
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
EndFunc   ;==>_CreateGroup_QLV_On_Main

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
EndFunc   ;==>_CreateGroup_BPT_Totals

Func _CreateGroup_HistoryDisplay()
	; Dời Y từ 410 lên 400. (Chiều cao 185 -> Đáy sẽ ở mốc 585, bằng với PP Cược)
	_CreateStyledGroup("Lịch Sử Cầu", 340, 400, 500, 185)

	Local Const $iCols = 20, $iRows = 6
	Local $labelWidth = 15.5, $labelHeight = 14.5
	Local $xSpacing = 9, $ySpacing = 5
	Local $groupX = 340, $groupWidth = 500

	; Kéo yStart lên theo khung (từ 435 lên 425)
	Local $yStart = 425

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
EndFunc   ;==>_CreateGroup_HistoryDisplay
Func _CreateGroup_HistoryLog()
	; Đặt Y = 590 và Chiều cao = 240 (Bằng y chang khung QLV bên trái)
	_CreateStyledGroup("Màn Hình Theo Dõi Trực Tiếp (TV Screen)", 340, 590, 500, 240)
	Local $x = 350
	Local $y = 615 ; Đẩy màn hình lên theo khung

	; Tăng chiều cao của cái màn hình đen lên 205 cho vừa vặn khung mới
	$g_hEdit_ActivityLog = GUICtrlCreateEdit("", $x, $y, 480, 205, BitOR(0x00200000, 0x0040, 0x0800)) ; VScroll + AutoVScroll + ReadOnly
	GUICtrlSetBkColor($g_hEdit_ActivityLog, 0x000000) ; Nền đen
	GUICtrlSetColor($g_hEdit_ActivityLog, 0x00FF00)   ; Chữ xanh lá
	GUICtrlSetFont($g_hEdit_ActivityLog, 9, 600, "Consolas")
EndFunc   ;==>_CreateGroup_HistoryLog
Func _CreateGroup_InfoAndTargets()
	_CreateStyledGroup("Thông Tin & Mục Tiêu", 850, 40, 410, 360)
	Local $x = 860, $w = 390
	Local $y = 65
	GUICtrlCreateLabel("Số dư hiện tại:", $x, $y, 110, 20)
	$g_hLabel_CurrentBalance = GUICtrlCreateLabel("0 VND", $x + 110, $y - 5, 280, 25, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_CurrentBalance, 13, 800)
	GUICtrlSetBkColor($g_hLabel_CurrentBalance, 0xFFFACD)
	GUICtrlSetColor($g_hLabel_CurrentBalance, 0x0000FF)

	$y += 35
	GUICtrlCreateLabel("Lãi/Lỗ phiên này:", $x, $y, 110, 20)
	$g_hLabel_Profit = GUICtrlCreateLabel("0 VND", $x + 110, $y - 5, 280, 25, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_Profit, 13, 800)
	GUICtrlSetBkColor($g_hLabel_Profit, 0xFFFACD)

	$y += 40
	GUICtrlCreateLabel("Tra cứu Volume:", $x, $y, 100, 20)
	$g_hCombo_VolumeFilter = GUICtrlCreateCombo("Hôm Nay", $x + 105, $y - 3, 100, 25, $CBS_DROPDOWNLIST)
	GUICtrlSetData($g_hCombo_VolumeFilter, "Hôm Nay|Tuần Này|Tháng Này|Năm Nay|TỔNG VĨNH VIỄN|Chọn Ngày Cụ Thể", "Hôm Nay")
	$g_hDate_VolumeFilter = GUICtrlCreateDate("", $x + 215, $y - 3, 100, 25, 0)
	GUICtrlSendMsg($g_hDate_VolumeFilter, 0x1032, 0, "yyyy-MM-dd")
	GUICtrlSetState($g_hDate_VolumeFilter, $GUI_HIDE)

	$g_hLabel_TotalVolume = GUICtrlCreateLabel("0 VND", $x, $y + 25, $w, 25, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_TotalVolume, 14, 800)
	GUICtrlSetBkColor($g_hLabel_TotalVolume, 0xFFE4B5)
	GUICtrlSetColor($g_hLabel_TotalVolume, 0x8A2BE2)

	$y += 60
	GUICtrlCreateLabel("Tra cứu Lãi/Lỗ:", $x, $y, 100, 20)
	$g_hCombo_ProfitFilter = GUICtrlCreateCombo("Hôm Nay", $x + 105, $y - 3, 100, 25, $CBS_DROPDOWNLIST)
	GUICtrlSetData($g_hCombo_ProfitFilter, "Hôm Nay|Tuần Này|Tháng Này|Năm Nay|TỔNG VĨNH VIỄN|Chọn Ngày Cụ Thể", "Hôm Nay")
	$g_hDate_ProfitFilter = GUICtrlCreateDate("", $x + 215, $y - 3, 100, 25, 0)
	GUICtrlSendMsg($g_hDate_ProfitFilter, 0x1032, 0, "yyyy-MM-dd")
	GUICtrlSetState($g_hDate_ProfitFilter, $GUI_HIDE)

	$g_hLabel_TotalProfitStats = GUICtrlCreateLabel("0 VND", $x, $y + 25, $w, 25, BitOR($SS_CENTER, $SS_SUNKEN))
	GUICtrlSetFont($g_hLabel_TotalProfitStats, 14, 800)
	GUICtrlSetBkColor($g_hLabel_TotalProfitStats, 0xE8F8F5)
	GUICtrlSetColor($g_hLabel_TotalProfitStats, 0x006400)
	$y += 60
	GUICtrlCreateLabel("Chốt lời (đ):", $x, $y, 80, 20)
	$g_hInput_TakeProfit = GUICtrlCreateInput("100.000", $x + 85, $y - 2, 85, 22)
	GUICtrlSetBkColor($g_hInput_TakeProfit, 0xE0FFFF)

	GUICtrlCreateLabel("Kéo đuôi (đ):", $x + 180, $y, 80, 20)
	GUICtrlSetColor(-1, 0x008000)
	$g_hInput_TrailingStop = GUICtrlCreateInput("50.000", $x + 265, $y - 2, 85, 22)
	GUICtrlSetBkColor($g_hInput_TrailingStop, 0xE0FFFF)
	GUICtrlSetTip(-1, "Khoảng cách Gồng Lãi. Khi đạt chốt lời, tool KHÔNG DỪNG mà tiếp tục đánh. Nếu lãi tụt xuống bằng khoảng cách này so với ĐỈNH LÃI thì mới chốt.")

	$y += 30
	GUICtrlCreateLabel("Cắt lỗ (đ):", $x, $y, 80, 20)
	$g_hInput_StopLoss = GUICtrlCreateInput("200.000", $x + 85, $y - 2, 85, 22)
	GUICtrlSetBkColor($g_hInput_StopLoss, 0xE0FFFF)
EndFunc   ;==>_CreateGroup_InfoAndTargets
Func _CreateGroup_UserConfig_Main()
	_CreateStyledGroup("Điều Khiển & Tùy Chọn Nhanh", 850, 405, 410, 380)
	Local $x = 860, $y = 430

	GUICtrlCreateLabel("Cấu hình:", $x, $y, 60, 20)
	$g_hCombo_Profiles_Main = GUICtrlCreateCombo("", $x + 70, $y - 2, 320, 25, $CBS_DROPDOWNLIST)
	$y += 35

	GUICtrlCreateLabel("Click:", $x, $y, 60, 20)
	$g_hRadio_ClickMode_Control_Main = GUICtrlCreateRadio("Nhanh", $x + 70, $y, 90, 20)
	$g_hRadio_ClickMode_Mouse_Main = GUICtrlCreateRadio("Chuột", $x + 170, $y, 140, 20)
	GUICtrlCreateGroup("", -99, -99, 1, 1)
	$y += 30

	GUICtrlCreateLabel("TĐ Click:", $x, $y, 80, 20)
	$g_hInput_ClickDelay_Main = GUICtrlCreateInput("10", $x + 90, $y - 2, 50, 24)
	$y += 35

	GUICtrlCreateLabel("TĐ Di chuyển:", $x, $y, 90, 20)
	$g_hInput_MouseSpeed = GUICtrlCreateInput("0", $x + 90, $y - 2, 50, 24)

	$y += 45

	; ========================================================
	; NÚT KÍCH HOẠT VÀ NÚT ĐĂNG NHẬP
	; ========================================================
	$g_hButton_ActivateNew = GUICtrlCreateButton("🔒 MỞ KHÓA TOOL (100K)", $x + 50, $y, 250, 35)
	GUICtrlSetFont(-1, 11, 800)
	GUICtrlSetBkColor(-1, 0xCC0000)
	GUICtrlSetColor(-1, 0xFFFFFF)

	$y += 40
	$g_hButton_Start = GUICtrlCreateButton("ĐĂNG NHẬP", $x + 50, $y, 250, 45)
	GUICtrlSetFont($g_hButton_Start, 12, 700)

	; LOGIC: Chưa mua thì giấu nút Đăng nhập, bắt bấm Mở khóa
	If $g_sMachineStatus == "OK" Then
		GUICtrlSetState($g_hButton_ActivateNew, $GUI_HIDE)
		GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
	Else
		GUICtrlSetState($g_hButton_Start, $GUI_DISABLE)
		GUICtrlSetData($g_hButton_Start, "YÊU CẦU MỞ KHÓA TRƯỚC")
		GUICtrlSetBkColor($g_hButton_Start, 0xCCCCCC)
	EndIf
EndFunc   ;==>_CreateGroup_UserConfig_Main
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
		GUICtrlSetTip(-1, "Di chuột vào hình Chip " & $i + 1 & " trong game -> Bấm S -> Bấm nút Lấy.")
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
EndFunc   ;==>_CreateTab_ConfigHelper

; ==================================================================================================
; --- CÁC HÀM XỬ LÝ SỰ KIỆN & TRẠNG THÁI ---
; ==================================================================================================
Func _HandleUnlock()
	Local $sPass = InputBox("Yêu cầu mật khẩu", "Vui lòng nhập mật khẩu của nhà phát triển:", "", "*")
	If @error Then Return

	If $sPass = $g_sDevPassword Then
		MsgBox(64, "Thành công", "Đã mở khóa Tab Cấu hình & KÍCH HOẠT QUYỀN ADMIN TEST VIP.")

		; Bật cờ Admin
		$g_bIsDevMode = True
		_ToggleConfigControlsState(True)

		; Ép Tool kiểm tra lại giao diện VIP ngay lập tức
		_UpdateVipButtonState()
	Else
		MsgBox(16, "Lỗi", "Mật khẩu không chính xác.")
	EndIf
EndFunc   ;==>_HandleUnlock
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
EndFunc   ;==>_ToggleConfigControlsState

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
EndFunc   ;==>_UpdateScannerInfo

Func _UpdateColorPreview()
	Local $sColor = GUICtrlRead($g_hInput_ScanColor)
	If StringIsXDigit(StringTrimLeft($sColor, 2)) Then
		GUICtrlSetBkColor($g_hLabel_ScanColorPreview, Number($sColor))
	EndIf
EndFunc   ;==>_UpdateColorPreview

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
EndFunc   ;==>_HandleTestColorButton

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
EndFunc   ;==>_PopulateProfileList

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
EndFunc   ;==>_HandleProfileChange

Func _LoadSelectedProfile($sProfileName)
	If $sProfileName = "" Then Return

	Local $sSection = "Profile_" & $sProfileName
	Local $sFileToRead = $g_sIniPath ; <--- ÉP LUÔN LUÔN CHỈ ĐỌC TỪ FILE CONFIG.INI GỐC

	; --- 1. TẢI CÀI ĐẶT CHUNG ---
	GUICtrlSetData($g_hInput_InitialCapital, IniRead($sFileToRead, $sSection, "InitialCapital", "10.000.000"))
	GUICtrlSetData($g_hInput_InitialBet, IniRead($sFileToRead, $sSection, "InitialBet", "100.000"))
	GUICtrlSetData($g_hInput_TakeProfit, IniRead($sFileToRead, $sSection, "TakeProfit", "200.000"))
	GUICtrlSetData($g_hInput_StopLoss, IniRead($sFileToRead, $sSection, "StopLoss", "500.000"))
	GUICtrlSetData($g_hInput_TrailingStop, IniRead($sFileToRead, $sSection, "TrailingStop", "50.000"))

	GUICtrlSetData($g_hInput_ClickDelay, IniRead($g_sIniPath, "Settings", "ClickDelay", "10"))
	GUICtrlSetData($g_hInput_ClickDelay_Main, IniRead($g_sIniPath, "Settings", "ClickDelay", "10"))
	GUICtrlSetData($g_hInput_MouseSpeed, IniRead($g_sIniPath, "Settings", "MouseSpeed", "10"))

	; ========================================================
	; ĐỌC VÀ KHÔI PHỤC ĐÚNG TRẠNG THÁI NÚT CLICK
	; ========================================================
	Local $sClickMode = IniRead($g_sIniPath, "Settings", "ClickMode", "Control")
	If $sClickMode == "Mouse" Then
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
	Local $iRevLogic = Number(IniRead($sFileToRead, $sSection, "Opt_ReverseLogic", "0"))
	GUICtrlSetState($g_hCheckbox_ReverseLogic, ($iRevLogic = 1) ? $GUI_CHECKED : $GUI_UNCHECKED)
	; --- [SỬA LẠI] ĐỌC SỐ -> TỰ CHỌN DÒNG CHỮ TƯƠNG ỨNG ---
	Local $sID = IniRead($sFileToRead, $sSection, "Opt_AfterWinLogic_ID", "1")
	Local $sTextToSet = "1. Lay ngay cum gan nhat (Danh tiep)" ; Mặc định

	; --- [SỬA LẠI] LUÔN CỐ ĐỊNH LOGIC SỐ 2 ---
	; Bỏ qua việc đọc file INI, ép cứng luôn là Option 2
	Local $sTextToSet = "2. Doi cum moi toanh (Reset)"
	Local $sSavedBlacklist = IniRead($sFileToRead, $sSection, "Blacklist", "BBB,PPP,TTT")
	GUICtrlSetData($g_hInput_Blacklist, $sSavedBlacklist)

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

EndFunc   ;==>_LoadSelectedProfile
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
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_0", "1") ; Chip 1
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_0", "500.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_0", "988")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_0", "1009")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_1", "1") ; Chip 2
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_1", "100.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_1", "933")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_1", "1007")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_2", "1") ; Chip 3
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_2", "40.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_2", "865")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_2", "1013")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_3", "1") ; Chip 4
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_3", "20.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_3", "807")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_3", "1008")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipEnabled_4", "1") ; Chip 5
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipValue_4", "4.000")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipX_4", "747")
	IniWrite($g_sIniPath, "Profile_Sanh PP Mau", "ChipY_4", "1002")
EndFunc   ;==>_CreateDefaultIniFile

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
	_FullBacktest()
	_UpdateVIPListUI()
EndFunc   ;==>_LoadSettings

Func _StartProcess()
	Local $sSelectedProfile = GUICtrlRead($g_hCombo_Profiles_Main)
	If $sSelectedProfile = "" Then
		MsgBox(16, "Lỗi Cấu Hình", "Vui lòng chọn một cấu hình sảnh hợp lệ từ danh sách.")
		_SetControlsState(True)
		Return
	EndIf

	If Not _GetAndValidateInputs() Then
		_SetControlsState(True)
		Return
	EndIf

	_ApplyCurrentSettings()
	$g_hSessionTimer = TimerInit()
	_SendActivityLog("Start")

	; ========================================================
	; LÀM SẠCH BẢNG LỊCH SỬ CẦU MỖI KHI BẤM START
	; ========================================================
	ReDim $g_aDisplayHistory[0]
	$g_iHistoryCutoffIndex = 0
	$g_iTotalBanker = 0
	$g_iTotalPlayer = 0
	$g_iTotalTie = 0
	_RedrawHistory()
	_UpdateBPTTotalsLabels()
	_UpdateTotalHandsLabel()
	; ========================================================

	$g_fTotalProfit = 0.0
	$g_fPeakProfit = 0.0 ; Reset Đỉnh Lãi
	$g_bIsTrailingMode = False ; Tắt Kéo Đuôi

	; Bật tắt chế độ đánh nháp
	If GUICtrlRead($g_hCheckbox_VirtualBet) = $GUI_CHECKED Then
		$g_bIsRealBetting = False
		$g_iVirtualLosses = 0
		_UpdateStatus("🛡️ ĐÁNH NHÁP BẬT: Tool sẽ giả vờ đánh, đợi thua 3 tay mới vào tiền thật!")
	Else
		$g_bIsRealBetting = True
	EndIf

	$g_bIsRunning = True
	_SetControlsState(False)

	_UpdateStatus(">>> KHỞI ĐỘNG NGAY: Bắt đầu dò tín hiệu để đánh luôn!")

	_UpdateStatus("⏳ [BƯỚC 1] Đang tìm bàn / Chờ tín hiệu mồi đầu tiên...")
	While $g_bIsRunning
		_ProcessGUIMessages()
		Local $sInitResult = _ScanAreaForResult()
		If $sInitResult <> "" Then
			_UpdateStatus("✅ Đã kết nối vào bàn: " & $sInitResult)
			_ProcessObservation($sInitResult)
			ExitLoop
		EndIf
		Sleep(200)
	WEnd

	While $g_bIsRunning
		_ProcessGUIMessages()

		If _CheckProfitLossTargets() Then ExitLoop

		_WaitUntilResultDisappears()
		If Not $g_bIsRunning Then ExitLoop

		Local $aAction = _DecideNextAction()
		Local $sBetOn = $aAction[1]
		Local $iBetUnits = $aAction[2]

		If $aAction[0] = "BET" Then
			$g_fCurrentBet = $g_fInitialBet * $iBetUnits
			_UpdateStatus("🔥 Logic báo CƯỢC: " & $sBetOn & " -> Chờ giờ cược...")

			If _WaitForBettingTime_Safe() Then
				If _PerformBet($sBetOn, $g_fCurrentBet) Then
					_UpdateStatus("✅ Đã đặt cược! Đang chờ mở bài...")
				EndIf
			Else
				_UpdateStatus("⛔ Bỏ lỡ giờ cược -> Hủy lệnh này, quan sát ván sau.")
				$g_sLastBetOn = ""
			EndIf
		Else
			Local $iCount = UBound($g_aDisplayHistory)
			_UpdateStatus("👁️ Quan sát (" & $iCount & " tay) - Chờ cơ hội...")
		EndIf

		Local $sNewResult = _WaitForNextHandResult_TimeOut()
		If $sNewResult == "STOPPED" Then ExitLoop

		If $g_sLastBetOn <> "" Then
			_ProcessBetOutcome($sNewResult, $g_sLastBetOn)
			$g_sLastBetOn = ""
		Else
			_ProcessObservation($sNewResult)
		EndIf
		Sleep(200)
	WEnd
EndFunc   ;==>_StartProcess
; ==============================================================================
; HÀM HỖ TRỢ MỚI (COPY KÈM THEO)
; ==============================================================================

Func _WaitForNextHandResult_TimeOut()
	; Xóa bỏ đồng hồ đếm ngược, ép Tool đợi vĩnh viễn
	_UpdateStatus("⏳ Đang đợi Dealer lật bài (Chờ vĩnh viễn)...")

	While $g_bIsRunning
		_ProcessGUIMessages()

		Local $sRes = _ScanAreaForResult()
		If $sRes <> "" Then Return $sRes ; Chỉ thoát vòng lặp khi có B, P hoặc T

		Sleep(100)
	WEnd

	Return "STOPPED"
EndFunc   ;==>_WaitForNextHandResult_TimeOut
; Hàm đợi kết quả biến mất (Để tránh nhận diện trùng lặp)
Func _WaitUntilResultDisappears()
	_UpdateStatus("⏳ Đợi kết quả cũ biến mất...")
	While _ScanAreaForResult() <> "" And $g_bIsRunning
		_ProcessGUIMessages()
		Sleep(200)
	WEnd
EndFunc   ;==>_WaitUntilResultDisappears
Func _StopProcess()
	$g_bIsRunning = False
	$g_bManualStopped = True
	_UpdateStatus("🛑 Đã dừng Tool và chốt Lợi nhuận vào Số dư!")
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
EndFunc   ;==>_StopProcess
Func _HaltProcess($sReason)
	_SendActivityLog("Stop", $sReason, Round(TimerDiff($g_hSessionTimer) / 1000, 0))
	$g_bIsRunning = False
	$g_bManualStopped = True
	_UpdateStatus($sReason)
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
EndFunc   ;==>_HaltProcess
Func _ResetAllStatsAndState()
	; Reset các thông số cơ bản
	ReDim $g_aDisplayHistory[0]
	$g_iHistoryCutoffIndex = 0
	$g_iTotalBanker = 0
	$g_iTotalPlayer = 0
	$g_iTotalTie = 0
	$g_sLastBetOn = ""
	_ResetBettingMethodState()

	; Reset mảng vốn riêng biệt
	For $i = 0 To UBound($g_aRuleLevels) - 1
		$g_aRuleLevels[$i] = 0
	Next
	$g_iLastActiveRuleIndex = -1

	_UpdateStatus("♻️ Đã Reset Lịch sử, Memory & Vốn các dòng!")

	; Cập nhật lại toàn bộ nhãn hiển thị
	_UpdateProfitLabel()
	_UpdateBalanceLabel()
	_UpdateTotalHandsLabel()
	_UpdateBPTTotalsLabels()
	_RefreshVolumeDisplay() ; Đồng bộ nhãn Volume
	_RedrawHistory()
EndFunc   ;==>_ResetAllStatsAndState
Func _ResetBettingMethodState()
	$g_iCapitalLevel = 0 ; Bắt đầu từ Lệnh 0
	_UpdateStatus("Đã Reset về Lệnh 0.")
EndFunc   ;==>_ResetBettingMethodState

Func _UpdateAllLabels()
	; [SỬA QUAN TRỌNG] Gọi hàm hiển thị mới (đọc từ Database) thay vì hàm cũ
	_UpdateProfitLabel()
	_UpdateBalanceLabel()
	_UpdateTotalHandsLabel()
	_UpdateBPTTotalsLabels()
	_UpdateTotalVolumeLabel()
	_CheckProfitLossTargets()
EndFunc   ;==>_UpdateAllLabels
Func _ProcessObservation($sActualResult)
	; HÒA -> Bỏ Qua
	If $sActualResult = "T" Then
		_UpdateStatus("⚠️ Kết quả HÒA (Tie) -> Bỏ qua...")
		_AddNewHistoryEntry($sActualResult)
		_RedrawHistory()
		Return
	EndIf

	; ---> GIẢM ĐẾM NHỊP BỎ QUA <---
	If $g_iSkipSignalsCount_DuKich > 0 Then
		$g_iSkipSignalsCount_DuKich -= 1
	EndIf
	; ------------------------------

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
EndFunc   ;==>_ProcessObservation

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
EndFunc   ;==>_GetQLV_Params
Func _GetActiveMethodName()
	Return "Custom" ; Luôn luôn là Custom
EndFunc   ;==>_GetActiveMethodName
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

	Local $bSepQLV = (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED)
	Local $iCurrentLvl = ($bSepQLV And $g_iLastActiveRuleIndex > -1 And $g_iLastActiveRuleIndex < UBound($g_aRuleLevels)) ? $g_aRuleLevels[$g_iLastActiveRuleIndex] : $g_iCapitalLevel
	Local $aQLV = _GetQLV_Params($iCurrentLvl)
	Local $bReverseLogic = (GUICtrlRead($g_hCheckbox_ReverseLogic) = $GUI_CHECKED)
	Local $iSavedActiveIndex = $g_iLastActiveRuleIndex
	Local $fProfitChange = 0

	If $sActualResult = $sBetOn Then
		; ==========================================
		; [--- KHI THẮNG (WIN) ---]
		; ==========================================
		If Not $g_bIsRealBetting Then
			$g_iVirtualLosses = 0 ; Reset chuỗi thua ảo
			_UpdateStatus("🛡️ ĐÁNH NHÁP: Thắng ảo! Cầu chưa sập, tiếp tục rình...")
		Else
			$g_fTotalProfit += ($sBetOn = "B") ? ($g_fCurrentBet * 0.95) : $g_fCurrentBet
			$fProfitChange = ($sBetOn == "B") ? ($g_fCurrentBet * 0.95) : $g_fCurrentBet

			; KÉO ĐỈNH (TRAILING STOP)
			If $g_fTotalProfit > $g_fPeakProfit Then $g_fPeakProfit = $g_fTotalProfit
			_UpdateStrategyStats(1)

			If GUICtrlRead($g_hCheckbox_DuKich) = $GUI_CHECKED Then
				$g_iWaitTimeEnd_DuKich = TimerInit()
				$g_iWaitDuration_DuKich = Random(300000, 600000, 1)
			EndIf
		EndIf

		If $bReverseLogic Then
			If $g_iLastActiveRuleIndex > -1 Then $g_iCustomSeqStep += 1
			$g_iCapitalLevel = $aQLV[2]
			_UpdateStatus("WIN! (Bám Chuỗi) -> Lên Lv " & $aQLV[2] & " -> Đi tiếp chuỗi!")
		Else
			$g_iLastActiveRuleIndex = -1
			$g_iCustomSeqStep = 0
			$g_iCapitalLevel = $aQLV[2]
			If GUICtrlRead($g_hCheckbox_ContinuousMode) <> $GUI_CHECKED Then
				$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
				_UpdateStatus("WIN! -> Cắt cầu lịch sử -> Chờ chuỗi tín hiệu mới.")

				; NẾU CÓ BẬT ĐÁNH NHÁP THÌ RESET VỀ NHÁP KHI CẮT CẦU
				If GUICtrlRead($g_hCheckbox_VirtualBet) = $GUI_CHECKED Then
					$g_bIsRealBetting = False
					$g_iVirtualLosses = 0
				EndIf
			EndIf
		EndIf
	Else
		; ==========================================
		; [--- KHI THUA (LOSS) ---]
		; ==========================================
		If Not $g_bIsRealBetting Then
			$g_iVirtualLosses += 1
			If $g_iVirtualLosses >= 3 Then
				$g_bIsRealBetting = True
				$g_iVirtualLosses = 0
				$g_iCapitalLevel = 0 ; Bắt đầu đánh thật từ Lệnh 1
				If $bSepQLV And $iSavedActiveIndex > -1 Then $g_aRuleLevels[$iSavedActiveIndex] = 0
				_UpdateStatus("🔥 NHÁP ĐÃ GÃY 3 LẦN -> VÀO TIỀN THẬT LỆNH 1 TỪ TAY SAU!")
			Else
				_UpdateStatus("🛡️ ĐÁNH NHÁP: Thua ảo (" & $g_iVirtualLosses & "/3) -> Gần chín rồi...")
			EndIf
		Else
			$g_fTotalProfit -= $g_fCurrentBet
			$fProfitChange = -$g_fCurrentBet
			_UpdateStrategyStats(0)

			If GUICtrlRead($g_hCheckbox_DuKich) = $GUI_CHECKED Then $g_iSkipSignalsCount_DuKich = 10
		EndIf

		If $bReverseLogic Then
			$g_iLastActiveRuleIndex = -1
			$g_iCustomSeqStep = 0
			$g_iCapitalLevel = $aQLV[3]
			$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
			_UpdateStatus("LOSS! (Bám Chuỗi) -> Cắt cầu -> Về Lv " & $aQLV[3] & " chờ tín hiệu mới.")

			If GUICtrlRead($g_hCheckbox_VirtualBet) = $GUI_CHECKED Then
				$g_bIsRealBetting = False
				$g_iVirtualLosses = 0
			EndIf
		Else
			If $g_iLastActiveRuleIndex > -1 Then $g_iCustomSeqStep += 1
			$g_iCapitalLevel = $aQLV[3]
			If $g_bIsRealBetting Then _UpdateStatus("LOSS! -> Lên Lv " & $aQLV[3] & " -> Tiếp tục đuổi cầu.")
		EndIf
	EndIf

	If $bSepQLV And $iSavedActiveIndex > -1 Then
		$g_aRuleLevels[$iSavedActiveIndex] = $g_iCapitalLevel
	EndIf

	_UpdateProfitLabel()
	_UpdateBalanceLabel()
	_RedrawHistory()

	If $g_bIsRealBetting Then _UpdateDailyStats($g_fCurrentBet, $fProfitChange)

	Local $fSoDuHienTai = $g_fInitialCapital + $g_fTotalProfit
	Local $fLaiLoHienTai = $g_fTotalProfit
	Local $fTongVolumeTrongNgay = Number(IniRead(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), "0"))
	_SyncLiveDashboard($fSoDuHienTai, $fLaiLoHienTai, $fTongVolumeTrongNgay)
EndFunc   ;==>_ProcessBetOutcome
Func _AddNewHistoryEntry($sResult)
	_Vault_Init()
	_Vault_AddResult($sResult)
	_ArrayAdd($g_aDisplayHistory, $sResult)

	; NẾU MẢNG ĐẦY -> XÓA TAY CŨ NHẤT ĐỂ GIẢI PHÓNG RAM VÀ ĐẨY BẢNG
	If UBound($g_aDisplayHistory) > $HARD_LIMIT_RAM Then
		_ArrayDelete($g_aDisplayHistory, 0)
		; Đồng bộ lại điểm cắt đuôi nếu có
		If $g_iHistoryCutoffIndex > 0 Then
			$g_iHistoryCutoffIndex -= 1
		EndIf
	EndIf

	_UpdateBPTTotals($sResult)
	_FullBacktest()
EndFunc   ;==>_AddNewHistoryEntry
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
EndFunc   ;==>_UpdateBPTTotals

Func _UpdateBPTTotalsLabels()
	GUICtrlSetData($g_hLabel_TotalB_Val, $g_iTotalBanker)
	GUICtrlSetData($g_hLabel_TotalP_Val, $g_iTotalPlayer)
	GUICtrlSetData($g_hLabel_TotalT_Val, $g_iTotalTie)
EndFunc   ;==>_UpdateBPTTotalsLabels

Func _PerformBet($sBetOn, $fAmountToBet)
	If Not $g_bIsRunning Then Return False
	If _CheckProfitLossTargets() Then Return False

	If Not $g_bIsRealBetting Then
		_UpdateStatus("🛡️ ĐÁNH NHÁP (Rình mồi): Thử nghiệm đánh " & $sBetOn & " (" & _FormatNumber($fAmountToBet) & " đ)...")
		$g_fLastBetAmount = $fAmountToBet
		$g_sLastBetOn = $sBetOn
		Return True
	EndIf

	_UpdateStatus(StringFormat("Thực hiện cược %s (%s VND)...", $sBetOn, _FormatNumber($fAmountToBet)))

	Local $hGameWin = $g_hTargetGameWin
	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		$hGameWin = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hGameWin ; Lưu lại luôn cho chắc
	EndIf

	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		_HaltProcess("Lỗi: Không tìm thấy cửa sổ game!")
		Return False
	EndIf

	Local $aBetAreaPos = ($sBetOn = "B") ? $g_aBankerButtonPos : $g_aPlayerButtonPos
	Sleep(50)
	_ClickChipsForAmount($hGameWin, $fAmountToBet, $aBetAreaPos)
	$g_fLastBetAmount = $fAmountToBet
	$g_sLastBetOn = $sBetOn
	Return True
EndFunc   ;==>_PerformBet
Func _ClickChipsForAmount($hGameWin, $fAmount, $aBetAreaPos)
	Local $aClickQueue = _CalculateOptimalClicks($fAmount)
	If @error Then Return False

	Local $iTotalSteps = UBound($aClickQueue)
	If $iTotalSteps = 0 Then Return True

	Local $iTotalClicks = 0
	For $i = 0 To $iTotalSteps - 1
		$iTotalClicks += $aClickQueue[$i][2]
	Next

	_UpdateStatus("Đang cược " & _FormatNumber($fAmount) & "...")
	Local $iBaseDelay = $g_iClickDelay

	; =================================================================
	; BÍ QUYẾT 1: CHỈ KÉO CỬA SỔ LÊN NẾU NÓ ĐANG THỰC SỰ NẰM DƯỚI TASKBAR
	; =================================================================
	If Not WinActive($hGameWin) Then
		; =================================================================
		; BÍ QUYẾT 1 (ĐÃ SỬA LẠI): CHỈ RESTORE NẾU BỊ THU NHỎ XUỐNG TASKBAR
		; =================================================================
		If BitAND(WinGetState($hGameWin), 16) Then
			WinSetState($hGameWin, "", @SW_RESTORE)
			Sleep(100)
		EndIf
		; Sếp lưu ý: Không dùng WinActivate ở đây nữa!
	EndIf


	Sleep($iBaseDelay * 2)

	For $i = 0 To $iTotalSteps - 1
		Local $iChipX = $aClickQueue[$i][0]
		Local $iChipY = $aClickQueue[$i][1]
		Local $iCount = $aClickQueue[$i][2]

		_SingleClick($hGameWin, $iChipX, $iChipY, 3)
		Sleep($iBaseDelay + Random(10, 30, 1))

		If $g_sClickMode = "Mouse" Then
			MouseMove($aBetAreaPos[0] + Random(-10, 10, 1), $aBetAreaPos[1] + Random(-10, 10, 1), $g_iMouseSpeed)
		EndIf

		For $j = 1 To $iCount
			If Not $g_bIsRunning Then Return False
			_SingleClick($hGameWin, $aBetAreaPos[0], $aBetAreaPos[1], 10)

			Local $iCurrentDelay = $iBaseDelay
			If $iTotalClicks >= 10 Then
				$iCurrentDelay = Random($iBaseDelay * 0.3, $iBaseDelay * 0.7, 1)
			ElseIf $iTotalClicks >= 5 Then
				$iCurrentDelay = Random($iBaseDelay * 0.8, $iBaseDelay * 1.2, 1)
			Else
				$iCurrentDelay = Random($iBaseDelay, $iBaseDelay * 1.5, 1)
			EndIf

			If $iCurrentDelay < 10 Then $iCurrentDelay = 10
			Sleep($iCurrentDelay)
		Next
	Next
	Return True
EndFunc   ;==>_ClickChipsForAmount


Func _SingleClick($hWnd, $iX, $iY, $iRadius = 0)
	; 1. Chặn lỗi nếu tọa độ trượt ra ngoài màn hình
	If $iX <= 0 Or $iY <= 0 Then Return False
	If $iX > @DesktopWidth Or $iY > @DesktopHeight Then Return False

	Local $iRandX = $iX
	Local $iRandY = $iY

	If $iRadius > 0 Then
		$iRandX = $iX + Random(-$iRadius, $iRadius, 1)
		$iRandY = $iY + Random(-$iRadius, $iRadius, 1)
	EndIf

	; 2. Đảm bảo cửa sổ không bị thu nhỏ xuống Taskbar
	If BitAND(WinGetState($hWnd), 16) Then WinSetState($hWnd, "", @SW_RESTORE)

	; TUYỆT ĐỐI KHÔNG DÙNG WinActivate ĐỂ CHỐNG GIẬT MÀN HÌNH

	; 3. CLICK BÓNG MA (GHOST CLICK)
	Local $aOldMousePos = MouseGetPos() ; Chụp lại vị trí chuột thật của sếp

	BlockInput(1) ; Khóa tay khách 1/10 giây để chống giằng co chuột với Tool

	; Bay chuột tới tọa độ cược và Click (Speed 0 = Tức thì)
	MouseMove($iRandX, $iRandY, 0)
	MouseDown("left")
	Sleep(Random(20, 30, 1)) ; Nhấp nhả ngẫu nhiên cho giống người thật
	MouseUp("left")

	; Trả chuột về ngay vị trí sếp đang làm việc dở
	MouseMove($aOldMousePos[0], $aOldMousePos[1], 0)

	BlockInput(0) ; Mở khóa chuột lại cho sếp dùng

	Sleep(20)
	Return True
EndFunc   ;==>_SingleClick
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
EndFunc   ;==>_CalculateOptimalClicks

Func _ScanAreaForResult()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then
		$hWnd = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hWnd
	EndIf

	If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

	Local $iTolerance = $g_iShade_Result
	Local $iColB = $g_iBankerColor
	Local $iColP = $g_iPlayerColor
	Local $iColT = $g_iTieColor

	If IsArray(PixelSearch($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3], $iColB, $iTolerance)) Then Return "B"
	If IsArray(PixelSearch($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3], $iColP, $iTolerance)) Then Return "P"
	If IsArray(PixelSearch($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3], $iColT, $iTolerance)) Then Return "T"

	Return ""
EndFunc   ;==>_ScanAreaForResult
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
EndFunc   ;==>_GetAndValidateInputs

Func _UpdateStrategyStats($iBetResult)
	; Đã xóa Ra-đa nên không cần cập nhật số liệu nữa
	Return
EndFunc   ;==>_UpdateStrategyStats
Func _Core_SaveStat($sFile, $sSection, $iResult)
	; 1. Đọc dữ liệu cơ bản
	Local $iWins = Number(IniRead($sFile, $sSection, "Wins", "0"))
	Local $iLosses = Number(IniRead($sFile, $sSection, "Losses", "0"))
	Local $iMaxWin = Number(IniRead($sFile, $sSection, "MaxWinStreak", "0"))
	Local $iMaxLoss = Number(IniRead($sFile, $sSection, "MaxLossStreak", "0"))
	Local $iCurWin = Number(IniRead($sFile, $sSection, "CurWinStreak", "0"))
	Local $iCurLoss = Number(IniRead($sFile, $sSection, "CurLossStreak", "0"))

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
EndFunc   ;==>_Core_SaveStat

Func _CheckProfitLossTargets()
	Local $bStopNow = False
	Local $sReason = ""
	Local $sStatus = ""

	Local $iTakeProfitMoney = Number(StringRegExpReplace(GUICtrlRead($g_hInput_TakeProfit), "\D", ""))
	Local $iTrailingMoney = Number(StringRegExpReplace(GUICtrlRead($g_hInput_TrailingStop), "\D", ""))
	Local $iStopLossMoney = Number(StringRegExpReplace(GUICtrlRead($g_hInput_StopLoss), "\D", ""))

	If $g_fTotalProfit > $g_fPeakProfit Then $g_fPeakProfit = $g_fTotalProfit

	If $iTakeProfitMoney > 0 And $iTrailingMoney > 0 Then
		If $g_fTotalProfit >= $iTakeProfitMoney Then
			If Not $g_bIsTrailingMode Then
				$g_bIsTrailingMode = True
				_UpdateStatus("🚀 ĐÃ KÍCH HOẠT GỒNG LÃI! Kéo đuôi " & _FormatMoneyVN($iTrailingMoney) & "đ dưới Đỉnh.")
				_UpdateStatus("⚠️ Chú ý: Tool sẽ tiếp tục đánh cho đến khi tụt lãi. Nếu muốn dừng ngay, hãy tự bấm Dừng!")
			EndIf
		EndIf
		If $g_bIsTrailingMode Then
			Local $fCutLevel = $g_fPeakProfit - $iTrailingMoney
			If $g_fTotalProfit <= $fCutLevel And $g_fTotalProfit > 0 Then
				$bStopNow = True
				$sStatus = "DONE_WIN"
				$sReason = "CHỐT KÉO ĐUÔI Ở: " & _FormatMoneyVN($g_fTotalProfit) & "đ"
			EndIf
		EndIf
	Else
		If $iTakeProfitMoney > 0 And $g_fTotalProfit >= $iTakeProfitMoney Then
			$bStopNow = True
			$sStatus = "DONE_WIN"
			$sReason = "ĐÃ CHẠM MỐC CHỐT LỜI: " & _FormatMoneyVN($g_fTotalProfit) & "đ"
		EndIf
	EndIf

	If $iStopLossMoney > 0 And $g_fTotalProfit <= -$iStopLossMoney Then
		$bStopNow = True
		$sStatus = "DONE_LOSS"
		$sReason = "ĐÃ CHẠM MỐC CẮT LỖ: " & _FormatMoneyVN($g_fTotalProfit) & "đ"
	EndIf

	If $bStopNow Then
		_UpdateStatus("⏸️ TẠM DỪNG: " & $sReason & " - Đang chờ lệnh...")
		Local $iUserChoice = _ShowTargetPopup_Overlay($sStatus, $sReason)

		If $g_fTotalProfit <> 0 Then
			$g_fInitialCapital += $g_fTotalProfit
			GUICtrlSetData($g_hInput_InitialCapital, _FormatNumber($g_fInitialCapital))
		EndIf

		$g_fTotalProfit = 0

		If $iUserChoice == 1 Then
			$g_bIsRunning = False
			; ĐÃ LOẠI BỎ LỆNH WINCLOSE - BẢO VỆ CHROME 100%
			$g_hTargetGameWin = 0
			WinSetTitle($g_hGUI, "", "STOP: " & $sReason)
			GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
			GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
			_SetControlsState(True)
			_UpdateProfitLabel()
			_UpdateBalanceLabel()
			_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
			Return True
		Else
			$g_iCapitalLevel = 0
			$g_iCustomSeqStep = 0
			$g_iLastActiveRuleIndex = -1
			For $i = 0 To UBound($g_aRuleLevels) - 1
				$g_aRuleLevels[$i] = 0
			Next
			$g_fPeakProfit = 0
			$g_bIsTrailingMode = False
			_UpdateProfitLabel()
			_UpdateBalanceLabel()
			_MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))
			_UpdateStatus("▶️ Đã chốt Số dư. Bắt đầu ca đánh mới...")
			GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
			GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)
			Return False
		EndIf
	EndIf
	Return False
EndFunc   ;==>_CheckProfitLossTargets
Func _RedrawHistory()
	; Xóa sạch bảng cũ
	For $hLabel In $g_aLabel_History
		_StyleResultLabel($hLabel, "-", False, False)
	Next

	Local $iTotalCount = UBound($g_aDisplayHistory)
	If $iTotalCount = 0 Then Return

	; ÉP HIỂN THỊ CỐ ĐỊNH 120 TAY MỚI NHẤT TRÊN GIAO DIỆN
	Local $iViewLimit = 120

	; Tính toán điểm bắt đầu (Cắt lấy đuôi 120 tay nếu mảng quá lớn)
	Local $iStartIndex = 0
	If $iTotalCount > $iViewLimit Then
		$iStartIndex = $iTotalCount - $iViewLimit
	EndIf

	Local $iRows = 6
	Local $iDisplayCols = 20
	Local $iMaxCells = $iRows * $iDisplayCols
	Local $iDataCount = $iTotalCount - $iStartIndex

	; Tính toán Scroll hiển thị
	Local $iScrollOffset = 0
	If $iDataCount > $iMaxCells Then
		Local $iExcessCols = Ceiling(($iDataCount - $iMaxCells) / $iRows)
		$iScrollOffset = $iExcessCols * $iRows
	EndIf

	; VẼ LẠI
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
	_UpdateChecksheet()
EndFunc   ;==>_RedrawHistory
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
EndFunc   ;==>_StyleResultLabel

Func _SetControlsState($bEnable)
	Local $iState = $bEnable ? $GUI_ENABLE : $GUI_DISABLE
	Local $iInputColor = $bEnable ? 0xE0FFFF : 0xE0E0E0
	GUICtrlSetState($g_hCheckbox_VirtualBet, $iState)
	GUICtrlSetState($g_hInput_TrailingStop, $iState)
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

	; Khóa/Mở Khóa GUI cho Custom
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

	If $bEnable Then
		GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
		GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
		GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
		; Luôn bật ô nhập liệu khi tool dừng
		GUICtrlSetState($g_hInput_CustomRules, $GUI_ENABLE)
		GUICtrlSetState($g_hCheckbox_SeparateQLV, $GUI_ENABLE)
		GUICtrlSetBkColor($g_hInput_CustomRules, 0xFFFACD)
		GUICtrlSetState($g_hCheckbox_DuKich, $GUI_ENABLE)

		; Xử lý hiển thị mờ chữ khi dừng (Dựa vào cái nào đang tích)
		If GUICtrlRead($g_hCheckbox_ContinuousMode) = $GUI_CHECKED Then
			GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_ENABLE)
			GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_DISABLE)
		ElseIf GUICtrlRead($g_hCheckbox_ReverseLogic) = $GUI_CHECKED Then
			GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_ENABLE)
			GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_DISABLE)
		Else
			GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_ENABLE)
			GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_ENABLE)
		EndIf
	Else
		GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
		GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)
		GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)

		; KHÓA TOÀN BỘ 100% KHI TOOL ĐANG CHẠY (CHỐNG BẤM TAY)
		GUICtrlSetState($g_hInput_CustomRules, $GUI_DISABLE)
		GUICtrlSetBkColor($g_hInput_CustomRules, 0xE0E0E0)
		GUICtrlSetState($g_hCheckbox_SeparateQLV, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_DuKich, $GUI_DISABLE)
	EndIf
EndFunc   ;==>_SetControlsState
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
Func _UpdateClock()
	If Not IsHWnd($g_hGUI) Then
		AdlibUnRegister("_UpdateClock")
		Return
	EndIf

	; Dịch WDAY thành tiếng Việt
	Local $sDayOfWeek = ""
	Switch @WDAY
		Case 1
			$sDayOfWeek = "Chủ Nhật"
		Case 2
			$sDayOfWeek = "Thứ Hai"
		Case 3
			$sDayOfWeek = "Thứ Ba"
		Case 4
			$sDayOfWeek = "Thứ Tư"
		Case 5
			$sDayOfWeek = "Thứ Năm"
		Case 6
			$sDayOfWeek = "Thứ Sáu"
		Case 7
			$sDayOfWeek = "Thứ Bảy"
	EndSwitch

	; Ghép: Thứ + Ngày Tháng Năm + Giờ Phút Giây
	Local $sDate = StringFormat("%02d/%02d/%04d", @MDAY, @MON, @YEAR)
	Local $sTime = StringFormat("%02d:%02d:%02d", @HOUR, @MIN, @SEC)

	GUICtrlSetData($g_hLabel_Time, $sDayOfWeek & ", " & $sDate & "  -  " & $sTime)
EndFunc   ;==>_UpdateClock
Func _FormatNumber($fNumber)
	Local $sSign = ""
	If $fNumber < 0 Then
		$sSign = "-"
		$fNumber = Abs($fNumber)
	EndIf
	Local $sNumber = String(Int($fNumber))
	Return $sSign & StringRegExpReplace($sNumber, '(\d)(?=(\d{3})+(?!\d))', '$1.')
EndFunc   ;==>_FormatNumber
Func WM_COMMAND_Handler($hWnd, $iMsg, $wParam, $lParam)
	#forceref $hWnd, $iMsg, $lParam
	Local $iCmd = BitShift($wParam, 16)
	Local $iCtrlID = BitAND($wParam, 0xFFFF)

	If $iCmd = $EN_CHANGE Then
		Switch $iCtrlID
			Case $g_hInput_CustomRules, $g_hInput_CustomQLV_Edit, $g_hCheckbox_ContinuousMode, $g_hCheckbox_ReverseLogic, $g_hInput_Blacklist
				; ĐÃ XÓA SẠCH LỆNH _FullBacktest() Ở ĐÂY ĐỂ CHỐNG CHỚP GIẬT
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()

			Case $g_hCheckbox_Blacklist_IgnoreRunning
				IniWrite($g_sIniPath, "Profile_" & $g_sCurrentLoadedProfile, "Opt_BlacklistIgnoreRun", (GUICtrlRead($g_hCheckbox_Blacklist_IgnoreRunning) = $GUI_CHECKED) ? 1 : 0)

			Case $g_hInput_InitialCapital, $g_hInput_InitialBet, $g_hInput_TakeProfit, $g_hInput_StopLoss
				If Not $g_bIsFormatting Then
					$g_bIsFormatting = True
					Local $sText = GUICtrlRead($iCtrlID)
					Local $sRaw = StringRegExpReplace($sText, "[^0-9]", "")
					If $sRaw = "" Then $sRaw = "0"
					Local $sNew = _FormatNumber($sRaw)

					If $sText <> $sNew Then
						GUICtrlSetData($iCtrlID, $sNew)
						GUICtrlSendMsg($iCtrlID, $EM_SETSEL, StringLen($sNew), StringLen($sNew))
					EndIf
					$g_bIsFormatting = False

					$g_bNeedAutoSave = True
					$g_hAutoSaveTimer = TimerInit()
				EndIf
		EndSwitch
	EndIf
	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_COMMAND_Handler
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

; ==================================================================================================
; --- CÁC HÀM TIỆN ÍCH & BẢN QUYỀN ---
; ==================================================================================================
Func _GetHardwareID()
	Return DriveGetSerial("C:")
EndFunc   ;==>_GetHardwareID

Func _CheckLicenseOnline($sHWID)
	Local $sUrl = $g_sAppsScriptBaseURL & "?action=check_init&hwid=" & $sHWID & "&nocache=" & TimerInit() & Random(1000, 9999, 1)
	Local $sData = BinaryToString(InetRead($sUrl, 3), 4)

	Local $oJson = Json_Decode($sData)
	Local $sStatus = Json_Get($oJson, "[status]")

	; --- BẮT LỖI TỪ MÁY CHỦ GOOGLE ---
	If $sStatus == "ERROR" Then
		Local $sMsg = Json_Get($oJson, "[msg]")
		Local $aResult[3] = [$sStatus, $sMsg, 0]
		Return $aResult
	EndIf

	; ---> NẾU MÁY CHỦ BÁO ĐANG NỢ HOA HỒNG (Cột C > 0) <---
	If $sStatus == "DEBT" Then
		Local $iDebtAmount = Number(Json_Get($oJson, "[debt_amount]"))
		Local $aResult[3] = [$sStatus, $iDebtAmount, 0]
		Return $aResult
	EndIf

	Local $sExpiry = Json_Get($oJson, "[expiry]")
	$g_sActiveVIPs = Json_Get($oJson, "[active_vips]")

	; ---> ĐÓN VOLUME TỪ MÁY CHỦ BỎ VÀO BIẾN <---
	$g_fServerVolumeToday = Number(Json_Get($oJson, "[vol_today]"))

	Local $aResult[3] = [$sStatus, $sExpiry, 0]
	Return $aResult
EndFunc   ;==>_CheckLicenseOnline
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
EndFunc   ;==>_ShowUpdateDialog

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

; =====================================================================
; BẢNG 1: GIAO DIỆN KÍCH HOẠT VĨNH VIỄN LẦN ĐẦU (100K)
; =====================================================================
Func _ShowActivationDialog_New($sHWID)
	Local $hPayGUI = GUICreate("KÍCH HOẠT TOOL VĨNH VIỄN", 450, 520, -1, -1, $WS_POPUP, $WS_EX_TOPMOST)
	GUISetBkColor(0x111111, $hPayGUI) ; Nền Đen Nhám sang trọng

	; Nút X dời sang trái và làm to ra để chống lẹm, dễ bấm
	Local $hBtnCloseX = GUICtrlCreateButton("X", 400, 10, 40, 35)
	GUICtrlSetBkColor($hBtnCloseX, 0xCC0000)
	GUICtrlSetColor($hBtnCloseX, 0xFFFFFF)
	GUICtrlSetFont(-1, 14, 800)

	; Thu hẹp chiều ngang chữ (còn 380) và làm trong suốt nền để không đè nút X
	GUICtrlCreateLabel("🤝 PHÍ KÍCH HOẠT 1 LẦN DUY NHẤT 🤝", 10, 15, 380, 30, $SS_CENTER)
	GUICtrlSetFont(-1, 13, 800)
	GUICtrlSetColor(-1, 0x00FFFF)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	Local $oIE = ObjCreate("Shell.Explorer.2")
	Local $hActiveX = GUICtrlCreateObj($oIE, 85, 60, 280, 280)

	GUICtrlCreateLabel("Mức phí: 100.000 VNĐ", 10, 365, 430, 25, $SS_CENTER)
	GUICtrlSetFont(-1, 16, 800)
	GUICtrlSetColor(-1, 0x00FF00)

	Local $sContent = "KICHHOAT " & StringRight($sHWID, 6)
	GUICtrlCreateLabel("Nội dung CK: " & $sContent, 10, 405, 430, 25, $SS_CENTER)
	GUICtrlSetFont(-1, 14, 800)
	GUICtrlSetColor(-1, 0xFFD700)

	Local $hStatusLabel = GUICtrlCreateLabel("⏳ Đang chờ giao dịch... (7s)", 10, 455, 430, 35, BitOR($SS_CENTER, $SS_SUNKEN, 0x0200))
	GUICtrlSetFont(-1, 11, 700)
	GUICtrlSetColor(-1, 0x00FFFF)

	; Vẽ QR tĩnh (100k)
	Local $sQrUrl = "https://qr.sepay.vn/img?bank=MB&acc=0986071012&amount=100000&des=" & StringReplace($sContent, " ", "%20") & "&name=NGUYEN%20NGOC%20DUY"
	$oIE.navigate("about:blank")
	While $oIE.readyState <> 4
		Sleep(10)
	WEnd
	$oIE.document.open()
	$oIE.document.write("<html><body style='margin:0;padding:0;overflow:hidden;background-color:#111111;text-align:center;' scroll='no'><img src='" & $sQrUrl & "' width='280' height='280' style='border: 2px solid #00FFFF;'></body></html>")
	$oIE.document.close()

	GUISetState(@SW_SHOW, $hPayGUI)
	Local $hTimer = TimerInit()

	While 1
		Local $aMsg = GUIGetMsg(1)
		If $aMsg[0] = $hBtnCloseX Or $aMsg[0] = $GUI_EVENT_CLOSE Then Exit

		If TimerDiff($hTimer) > 7000 Then
			GUICtrlSetData($hStatusLabel, "🔄 Đang kiểm tra máy chủ...")
			Local $aCheck = _CheckLicenseOnline($sHWID)
			If $aCheck[0] == "OK" Or $aCheck[0] == "DEBT" Then
				GUICtrlSetData($hStatusLabel, "✅ KÍCH HOẠT THÀNH CÔNG!")
				GUICtrlSetColor($hStatusLabel, 0x00FF00)
				Sleep(1500)
				ExitLoop
			EndIf
			$hTimer = TimerInit()
			GUICtrlSetData($hStatusLabel, "⏳ Đang chờ giao dịch... (7s)")
		EndIf
	WEnd
	GUIDelete($hPayGUI)
EndFunc   ;==>_ShowActivationDialog_New

Func _ShowDebtDialog($iDebtAmount, $sHWID)
	Local $hDebtGUI = GUICreate("PHÍ DUY TRÌ HỆ THỐNG", 420, 530, -1, -1, BitOR($WS_POPUP, $WS_BORDER), $WS_EX_TOPMOST)
	GUISetBkColor(0x111111, $hDebtGUI)

	; Nút X canh lề trái một chút để thoát khỏi vùng chữ
	Local $hBtnExit = GUICtrlCreateButton("X", 370, 10, 40, 35)
	GUICtrlSetBkColor($hBtnExit, 0x555555)
	GUICtrlSetColor($hBtnExit, 0xFFFFFF)
	GUICtrlSetFont(-1, 12, 800)

	; Tiêu đề
	GUICtrlCreateLabel("PHÍ DUY TRÌ HỆ THỐNG", 10, 15, 350, 30, $SS_CENTER)
	GUICtrlSetFont(-1, 14, 800)
	GUICtrlSetColor(-1, 0x00FF00)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	Local $sMessage = "Cảm ơn bạn đã đồng hành!" & @CRLF & _
			"Để duy trì máy chủ tốc độ cao và nâng cấp hệ thống liên tục," & @CRLF & _
			"hệ thống xin thu 0.5% phí duy trì từ Tổng Volume chưa thanh toán." & @CRLF & _
			"Thanh toán xong, Volume trên máy bạn sẽ tự động xóa về 0 đ. 🚀"
	GUICtrlCreateLabel($sMessage, 10, 60, 400, 50, $SS_CENTER)
	GUICtrlSetFont(-1, 11, 400)
	GUICtrlSetColor(-1, 0x00FFFF)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	; =================================================================
	; TÍNH TOÁN NGƯỢC TỔNG VOLUME TỪ SỐ NỢ (ĐỒNG BỘ 100% TOÁN HỌC)
	; =================================================================
	Local $fVolumeDaDat = $iDebtAmount / 0.005

	GUICtrlCreateLabel("TỔNG VOLUME CƯỢC CỦA BẠN:", 10, 120, 400, 20, $SS_CENTER)
	GUICtrlSetFont(-1, 11, 600)
	GUICtrlSetColor(-1, 0xAAAAAA)

	GUICtrlCreateLabel(_FormatNumber($fVolumeDaDat) & " đ", 10, 145, 400, 30, $SS_CENTER)
	GUICtrlSetFont(-1, 18, 800)
	GUICtrlSetColor(-1, 0xFFFFFF) ; Hiển thị chữ trắng to nổi bật

	GUICtrlCreateLabel("CHI PHÍ DUY TRÌ (0.5% VOLUME):", 10, 185, 400, 20, $SS_CENTER)
	GUICtrlSetFont(-1, 11, 600)
	GUICtrlSetColor(-1, 0xAAAAAA)

	GUICtrlCreateLabel(_FormatNumber($iDebtAmount) & " VNĐ", 10, 210, 400, 35, $SS_CENTER)
	GUICtrlSetFont(-1, 24, 800)
	GUICtrlSetColor(-1, 0xFFD700) ; Tiền nợ hiển thị màu vàng Gold

	; =================================================================

	; QR Code
	Local $sBankId = "MB"
	Local $sAccountNo = "0986071012"
	Local $sAccountName = "NGUYEN NGOC DUY"
	Local $sContent = "HOAHONG " & StringRight($sHWID, 6)
	Local $sContentUrl = StringReplace($sContent, " ", "%20")
	Local $sNameUrl = StringReplace($sAccountName, " ", "%20")
	Local $sQrUrl = "https://qr.sepay.vn/img?bank=" & $sBankId & "&acc=" & $sAccountNo & "&amount=" & $iDebtAmount & "&des=" & $sContentUrl & "&name=" & $sNameUrl

	Local $oIE = ObjCreate("Shell.Explorer.2")
	Local $hActiveX = GUICtrlCreateObj($oIE, 110, 255, 200, 200) ; Đẩy QR xích xuống một chút

	$oIE.navigate("about:blank")
	While $oIE.readyState <> 4
		Sleep(10)
	WEnd
	Local $sHtml = "<html><body style='margin:0;padding:0;overflow:hidden;background-color:#111111;text-align:center;' scroll='no'>" & _
			"<img src='" & $sQrUrl & "' width='180' height='180' style='border: 2px solid #00FF00; border-radius: 10px;'></body></html>"
	$oIE.document.open()
	$oIE.document.write($sHtml)
	$oIE.document.close()

	Local $sNote = "Nội dung CK: " & $sContent
	GUICtrlCreateLabel($sNote, 10, 465, 400, 25, $SS_CENTER)
	GUICtrlSetFont(-1, 14, 800)
	GUICtrlSetColor(-1, 0xFFD700)

	Local $hStatusLabel = GUICtrlCreateLabel("⏳ Hệ thống đang quét giao dịch... (7s)", 10, 495, 400, 25, BitOR($SS_CENTER, 0x0200))
	GUICtrlSetFont(-1, 10, 600)
	GUICtrlSetColor(-1, 0x00FF00)

	GUISetState(@SW_SHOW, $hDebtGUI)

	Local $hTimer = TimerInit()
	Local $iLastSecs = -1

	While 1
		Local $aMsg = GUIGetMsg(1)
		If $aMsg[0] = $GUI_EVENT_CLOSE Or $aMsg[0] = $hBtnExit Then
			Exit
		EndIf

		Local $iElapsed = TimerDiff($hTimer)
		Local $iSecsLeft = 7 - Int($iElapsed / 1000)

		If $iSecsLeft >= 0 And $iSecsLeft <= 7 And $iSecsLeft <> $iLastSecs Then
			GUICtrlSetData($hStatusLabel, "⏳ Hệ thống đang quét giao dịch... (" & $iSecsLeft & "s)")
			$iLastSecs = $iSecsLeft
		EndIf

		If $iElapsed > 7000 Then
			GUICtrlSetData($hStatusLabel, "🔄 Đang đồng bộ với máy chủ...")
			Local $sUrlCheck = $g_sAppsScriptBaseURL & "?action=check_init&hwid=" & $sHWID & "&nocache=" & TimerInit() & Random(1000, 9999, 1)
			Local $sData = BinaryToString(InetRead($sUrlCheck, 3), 4)

			If $sData <> "" Then
				Local $oJson = Json_Decode($sData)
				Local $sStatus = Json_Get($oJson, "[status]")

				If $sStatus == "OK" Or $sStatus == "EXPIRED" Then
					GUICtrlSetData($hStatusLabel, "✅ THANH TOÁN THÀNH CÔNG!")
					Sleep(1000)
					MsgBox(64, "Tuyệt vời", "Đã nhận được phí duy trì! Chúc bạn đại thắng!", 0, $hDebtGUI)

					; CẬP NHẬT TỨC THÌ (THỜI GIAN THỰC) LÊN GIAO DIỆN CHÍNH (Về 0đ)
					Local $fServerVol = Number(Json_Get($oJson, "[vol_today]"))
					IniWrite(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), $fServerVol)

					$g_fTotalVolume = $fServerVol
					If IsHWnd($g_hGUI) Then _RefreshVolumeDisplay()

					GUIDelete($hDebtGUI)
					Return True
				EndIf
			EndIf
			$hTimer = TimerInit()
		EndIf
	WEnd
EndFunc   ;==>_ShowDebtDialog
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
EndFunc   ;==>_PopulateQLVList

Func _HandleQLVPresetChange()
	Local $sSelectedPreset = GUICtrlRead($g_hCombo_QLV_Presets)

	If $sSelectedPreset = "Tùy chỉnh" Then Return

	; Đọc nội dung từ file config.ini
	Local $sQLV_String = IniRead($g_sIniPath, "UserQLV", $sSelectedPreset, "")

	If $sQLV_String <> "" Then
		; Thay thế ký tự xuống dòng đặc biệt |NL| thành xuống dòng thật để hiển thị đẹp
		GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace($sQLV_String, "|NL|", @CRLF))
	EndIf
EndFunc   ;==>_HandleQLVPresetChange

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
EndFunc   ;==>_SaveCustomQLV

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
EndFunc   ;==>_DeleteCustomQLV

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
EndFunc   ;==>_EnsureDefaultQLVExists

Func _SaveSessionState()
	IniWrite($g_sIniPath, "SessionData", "CapitalLevel", $g_iCapitalLevel)
	IniWrite($g_sIniPath, "SessionData", "TotalProfit", $g_fTotalProfit)
	IniWrite($g_sIniPath, "SessionData", "CycleStep", $g_iCycleStep)

	; --- ĐÃ TẮT LỆNH LƯU VOLUME VÀO CONFIG.INI TRÁNH ĐỌC NHẦM ---
	; Mọi dữ liệu Volume giờ do volume_history.ini và Server quản lý.
EndFunc   ;==>_SaveSessionState
Func _LoadSessionState()
	ReDim $g_aDisplayHistory[0]
	$g_iHistoryCutoffIndex = 0
	$g_iTotalBanker = 0
	$g_iTotalPlayer = 0
	$g_iTotalTie = 0

	$g_iCapitalLevel = 0
	$g_fTotalProfit = 0

	; ĐỌC CHUẨN VOLUME TỪ FILE LỊCH SỬ ĐÃ ĐỒNG BỘ VỚI MÁY CHỦ
	$g_fTotalVolume = Number(IniRead(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), "0"))

	$g_iCycleStep = 1

	_RedrawHistory()
	_UpdateBPTTotalsLabels()
	_UpdateProfitLabel()
	_UpdateBalanceLabel()

	_RefreshVolumeDisplay()
EndFunc   ;==>_LoadSessionState
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

Func _WaitForBettingTime_Safe()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then
		$hWnd = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hWnd
	EndIf

	If $hWnd = 0 Or Not WinExists($hWnd) Then Return False

	Local $hTimer = TimerInit()
	Local $iTolerance = Number(GUICtrlRead($g_hInput_Shade_Timer))

	_UpdateStatus("Đang tìm tín hiệu cược (Màu: " & "0x" & Hex($g_iBetTimeIndicatorColor, 6) & ")...")

	While Not IsArray(PixelSearch($g_aBetTimeIndicatorArea[0], $g_aBetTimeIndicatorArea[1], $g_aBetTimeIndicatorArea[2], $g_aBetTimeIndicatorArea[3], $g_iBetTimeIndicatorColor, $iTolerance))
		_ProcessGUIMessages()
		If Not $g_bIsRunning Then
			ToolTip("")
			Return False
		EndIf

		Local $iElapsed = Round(TimerDiff($hTimer) / 1000, 1)
		ToolTip("Đang tìm Giờ Cược: " & $iElapsed & "s", MouseGetPos()[0], MouseGetPos()[1] - 50)

		If TimerDiff($hTimer) > 70000 Then
			ToolTip("")
			Return False
		EndIf

		Sleep(100)
	WEnd

	ToolTip("")
	Return True
EndFunc   ;==>_WaitForBettingTime_Safe
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
	Local $aPos = WinGetPos($g_hGUI)
	If IsArray($aPos) Then
		IniWrite($sFile, "Settings", "WinX", $aPos[0])
		IniWrite($sFile, "Settings", "WinY", $aPos[1])
	EndIf

	; d) Lưu tên bàn đang dùng cuối cùng
	If IsDeclared("g_sCurrentLoadedProfile") And $g_sCurrentLoadedProfile <> "" Then
		IniWrite($sFile, "Settings", "LastProfile", $g_sCurrentLoadedProfile)
	EndIf

	; _UpdateStatus("Đã lưu toàn bộ cài đặt.")
EndFunc   ;==>_SaveSettings

; --- HÀM THIẾT LẬP CÀI ĐẶT HIỆN TẠI (BỊ THIẾU) ---
Func _ApplyCurrentSettings()
	; Cập nhật biến toàn cục từ giao diện để tool chạy
	$g_sClickMode = (GUICtrlRead($g_hRadio_ClickMode_Control_Main) = $GUI_CHECKED) ? "Control" : "Mouse"
	$g_iClickDelay = Number(GUICtrlRead($g_hInput_ClickDelay_Main))
	$g_iMouseSpeed = Number(GUICtrlRead($g_hInput_MouseSpeed))
EndFunc   ;==>_ApplyCurrentSettings

Func _MasterSave($sProfileName, $bSilent = True)
	If $sProfileName = "" Then Return
	Local $sSection = "Profile_" & $sProfileName

	IniWrite($g_sIniPath, $sSection, "InitialCapital", GUICtrlRead($g_hInput_InitialCapital))
	IniWrite($g_sIniPath, $sSection, "InitialBet", GUICtrlRead($g_hInput_InitialBet))
	IniWrite($g_sIniPath, $sSection, "TakeProfit", GUICtrlRead($g_hInput_TakeProfit))
	IniWrite($g_sIniPath, $sSection, "StopLoss", GUICtrlRead($g_hInput_StopLoss))
	IniWrite($g_sIniPath, $sSection, "TrailingStop", GUICtrlRead($g_hInput_TrailingStop))
	IniWrite($g_sIniPath, "Settings", "ClickDelay", GUICtrlRead($g_hInput_ClickDelay_Main))
	IniWrite($g_sIniPath, "Settings", "MouseSpeed", GUICtrlRead($g_hInput_MouseSpeed))
	IniWrite($g_sIniPath, "Settings", "ClickMode", (GUICtrlRead($g_hRadio_ClickMode_Control_Main) = $GUI_CHECKED) ? "Control" : "Mouse")
	Local $sRules = StringReplace(GUICtrlRead($g_hInput_CustomRules), @CRLF, "|NL|")
	IniWrite($g_sIniPath, $sSection, "CustomRulesList", $sRules)
	IniWrite($g_sIniPath, $sSection, "Opt_SeparateQLV", (GUICtrlRead($g_hCheckbox_SeparateQLV) = $GUI_CHECKED) ? 1 : 0)
	IniWrite($g_sIniPath, $sSection, "Opt_ContinuousMode", (GUICtrlRead($g_hCheckbox_ContinuousMode) = $GUI_CHECKED) ? 1 : 0)
	IniWrite($g_sIniPath, $sSection, "Opt_ReverseLogic", (GUICtrlRead($g_hCheckbox_ReverseLogic) = $GUI_CHECKED) ? 1 : 0)
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
EndFunc   ;==>_MasterSave
Func _Logic_Custom($iTotalHands, $iBetUnit_Global, $bContinuous_Param)
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

	; ========================================================================
	; TRƯỜNG HỢP 1: ĐANG THEO DÂY (CHASE MODE)
	; ========================================================================
	If $g_iLastActiveRuleIndex > -1 Then
		Local $iIdx = $g_iLastActiveRuleIndex
		Local $iLevel = 0

		; NHẬN DIỆN CHUẨN XÁC VỐN CHUNG / VỐN RIÊNG
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

				If Not BitAND(GUICtrlRead($g_hCheckbox_ContinuousMode), $GUI_CHECKED) Then
					$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
					_UpdateStatus("⛔ Thua hết bảng vốn -> Cắt cầu lịch sử -> Chờ tín hiệu mới.")
				EndIf
				$g_iLastActiveRuleIndex = -1
				$g_iCustomSeqStep = 0
			EndIf
		EndIf
	EndIf

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
				$g_iCustomSeqStep = 1

				Local $sFirstChar = StringMid($sBetSeq, 1, 1)

				$aResult[0] = "BET"
				$aResult[1] = $sFirstChar
				$aResult[2] = $aQLV[1]

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
EndFunc   ;==>_Logic_Custom
Func _FullBacktest()
	; Đã xóa tính năng Phân tích nên chặn luôn hàm này để Tool chạy siêu nhẹ
	Return
EndFunc   ;==>_FullBacktest
Func _UpdateStatsUI()
	_GUICtrlListView_BeginUpdate($g_hListView_Stats)
	_GUICtrlListView_DeleteAllItems($g_hListView_Stats)

	For $r = 0 To UBound($g_aRawStats) - 1
		Local $sFormula = $g_aRawStats[$r][0]
		If $sFormula == "" Then ContinueLoop

		Local $sWinStr = ""
		For $k = 1 To 30
			If $g_aRawStats[$r][4 + $k] > 0 Then $sWinStr &= "[T" & $k & "=" & $g_aRawStats[$r][4 + $k] & "] "
		Next
		If $sWinStr == "" Then $sWinStr = "[Chưa húp]"

		Local $sLossStr = ""
		For $k = 1 To 30
			If $g_aRawStats[$r][34 + $k] > 0 Then $sLossStr &= "[" & $k & "T=" & $g_aRawStats[$r][34 + $k] & "] "
		Next
		If $sLossStr == "" Then $sLossStr = "[Chưa gãy]"

		; ---> TÍNH TOÁN TẦN SUẤT & WINRATE LỆNH 1 <---
		Local $iWins = $g_aRawStats[$r][1]
		Local $iLosses = $g_aRawStats[$r][2]
		Local $iTotal = $iWins + $iLosses

		Local $sFreq = $iTotal & " Lần"
		Local $sWinRate = "0%"
		If $iTotal > 0 Then $sWinRate = Round(($iWins / $iTotal) * 100, 1) & "%"

		; ĐẨY RA GIAO DIỆN CHUẨN 5 CỘT MỚI
		Local $iIndex = _GUICtrlListView_AddItem($g_hListView_Stats, $sFormula)
		_GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $sFreq, 1)
		_GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $sWinRate, 2)
		_GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $sWinStr, 3)
		_GUICtrlListView_AddSubItem($g_hListView_Stats, $iIndex, $sLossStr, 4)
	Next

	_GUICtrlListView_EndUpdate($g_hListView_Stats)
EndFunc   ;==>_UpdateStatsUI
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
EndFunc   ;==>_CheckBlacklist

Func _UpdateStatus($sText)
	If $g_hGUI <> "" And $g_hGUI <> 0 Then
		Local $sTitleID = ($g_sMyTableID <> "") ? (" - " & $g_sMyTableID) : ""
		WinSetTitle($g_hGUI, "", "Tool-AIO_" & $g_sVersion & $g_sInstanceIdentifier & $sTitleID & " | " & $g_sCopyright)
	EndIf

	; >>> ĐƯA NỘI DUNG LÊN TV SCREEN VÀ CHỐNG ĐƠ <<<
	If $g_hEdit_ActivityLog <> 0 Then
		Local $sTime = StringFormat("%02d:%02d:%02d", @HOUR, @MIN, @SEC)
		Local $sCurrentText = GUICtrlRead($g_hEdit_ActivityLog)

		; Nếu vượt quá 15,000 ký tự (khoảng 200 dòng), tự động xóa nửa phần trên (cũ nhất)
		If StringLen($sCurrentText) > 15000 Then
			$sCurrentText = StringRight($sCurrentText, 8000) ; Giữ lại 8000 ký tự đuôi mới nhất
			GUICtrlSetData($g_hEdit_ActivityLog, $sCurrentText & @CRLF & "[" & $sTime & "] " & $sText & @CRLF)
		Else
			; Nếu chưa đầy thì dùng lệnh nối đuôi tốc độ cao
			GUICtrlSetData($g_hEdit_ActivityLog, "[" & $sTime & "] " & $sText & @CRLF, 1)
		EndIf
	EndIf

	If $g_sMyTableID <> "" Then
		Local $sStatusFile = @TempDir & "\status_" & $g_sMyTableID & ".ini"
		If Not FileExists($sStatusFile) Then
			Local $hFile = FileOpen($sStatusFile, 2 + 32)
			FileClose($hFile)
		EndIf
		IniWrite($sStatusFile, "Status", "CurrentAction", $sText)
	EndIf
EndFunc   ;==>_UpdateStatus
Func _CheckForUpdates()
	; Chốt chặn an toàn: Không chạy update khi đang mở file code (.au3) để lập trình
	If @Compiled = 0 Then Return

	; ---> ĐÃ XÓA DÒNG "Đang kiểm tra phiên bản" ĐỂ NÓ KHÔNG LẢI NHẢI NỮA <---

	; 1. Tải nội dung version.txt (1 = ép tải mới, bỏ qua cache)
	Local $bRead = InetRead($g_sGithubVersionURL, 1)

	; Nếu khách mất mạng thì im lặng thoát luôn, không spam lỗi ra màn hình
	If @error Then Return

	; 2. Đọc bản online và làm sạch ký tự thừa
	Local $sOnlineVersion = StringStripWS(BinaryToString($bRead, 4), 8)

	; 3. CHỈ HIỆN LÊN MÀN HÌNH KHI CÓ BẢN MỚI THẬT SỰ
	If $sOnlineVersion <> "" And Number($sOnlineVersion) > Number($g_sVersion) Then
		_UpdateStatus("🚀 Có bản mới v" & $sOnlineVersion & "! Hệ thống đang tự động tải...")
		_SilentAutoUpdate($g_sDownloadURL)
	EndIf

	; ---> ĐÃ XÓA DÒNG BÁO "Đang là bản mới nhất" ĐỂ GIỮ SẠCH MÀN HÌNH TV <---
EndFunc   ;==>_CheckForUpdates
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
EndFunc   ;==>_SilentAutoUpdate
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
EndFunc   ;==>_SendTelegram

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
		_SendTelegram("🎉 Sếp ơi! Hệ thống đã đạt đủ mục tiêu Chốt Lời. Đang đợi quyết định!")
	Else
		_SendTelegram("⚠️ Sếp ơi! Hệ thống đã chạm mức Cắt Lỗ. Vào kiểm tra sảnh ngay!")
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
EndFunc   ;==>_ShowTargetPopup_Overlay
Func _Vault_Init()
	If Not FileExists($VAULT_FILE) Then
		FileWrite($VAULT_FILE, "")
	EndIf
EndFunc   ;==>_Vault_Init

Func _Vault_ForceSyncUI()
	Local $sUI = StringReplace(_ArrayToString($g_aDisplayHistory, ""), "T", "")
	If StringLen($sUI) == 0 Then Return
	Local $sVault = _Vault_GetFilteredHistory()
	If StringRight($sVault, StringLen($sUI)) <> $sUI Then _Vault_AddResult($sUI)
EndFunc   ;==>_Vault_ForceSyncUI

Func _Vault_AddResult($sResult)
	If $sResult == "T" Or $sResult == "" Then Return

	; --- 1. Ghi vào kho tổng (kho vĩnh viễn) ---
	FileSetAttrib($VAULT_FILE, "-RSH")
	Local $sData = FileRead($VAULT_FILE)
	$sData &= $sResult
	If StringLen($sData) > $VAULT_MAX_SIZE Then
		$sData = StringTrimLeft($sData, StringLen($sData) - $VAULT_MAX_SIZE)
	EndIf
	Local $hFile = FileOpen($VAULT_FILE, 2)
	FileWrite($hFile, $sData)
	FileClose($hFile)
	FileSetAttrib($VAULT_FILE, "+H")

	; --- 2. Ghi song song vào kho theo từng ngày hiện tại ---
	Local $sDailyFile = @AppDataDir & "\Baccarat_Data_" & @YEAR & @MON & @MDAY & ".dat"
	Local $hDaily = FileOpen($sDailyFile, 1) ; Mở chế độ ghi tiếp (Append)
	FileWrite($hDaily, $sResult)
	FileClose($hDaily)
EndFunc   ;==>_Vault_AddResult
Func _Vault_GetHistory()
	Return FileRead($VAULT_FILE)
EndFunc   ;==>_Vault_GetHistory

; --- HÀM MỚI: LẤY DỮ LIỆU ĐÃ LỌC THEO NGÀY ---
Func _Vault_GetFilteredHistory()
	If Not IsDeclared("g_hCombo_DailyData") Or $g_hCombo_DailyData = 0 Then Return _Vault_GetHistory()

	Local $sSelectedDate = GUICtrlRead($g_hCombo_DailyData)
	If $sSelectedDate = "Tất cả thời gian (Tổng)" Then
		Return _Vault_GetHistory() ; <--- SỬA CHỖ NÀY: Trả về thẳng kho dữ liệu tổng
	Else
		Local $aDateParts = StringSplit($sSelectedDate, "/")
		If $aDateParts[0] == 3 Then
			Local $sTargetFile = @AppDataDir & "\Baccarat_Data_" & $aDateParts[3] & $aDateParts[2] & $aDateParts[1] & ".dat"
			If FileExists($sTargetFile) Then Return FileRead($sTargetFile)
		EndIf
	EndIf
	Return ""
EndFunc   ;==>_Vault_GetFilteredHistory
Func _CreateGroup_StrategyStats()
	Local $hGroup = GUICtrlCreateGroup("💎 TRUNG TÂM PHƯƠNG PHÁP ĐỘC QUYỀN (VIP STORE)", 340, 40, 500, 250, $WS_GROUP, $WS_EX_CLIENTEDGE)
	GUICtrlSetFont($hGroup, 11, 800)
	GUICtrlSetColor($hGroup, 0xFF00FF)
	GUICtrlSetBkColor($hGroup, 0xF5F5F5)

	; Đã thêm mã 0x00000004 để tạo Checkbox và mở rộng chiều cao xuống 215
	$g_hListView_VIP = GUICtrlCreateListView("Mã|Tên Phương Pháp|Giá Thuê|Trạng Thái", 350, 65, 480, 215, BitOR($LVS_REPORT, $LVS_SINGLESEL, $LVS_SHOWSELALWAYS), BitOR($WS_EX_CLIENTEDGE, $LVS_EX_FULLROWSELECT, $LVS_EX_GRIDLINES, 0x00000004))

	GUICtrlSetBkColor($g_hListView_VIP, 0x1E1E1E)
	GUICtrlSetColor($g_hListView_VIP, 0xFFFFFF)
	GUICtrlSetFont($g_hListView_VIP, 10, 600, "Segoe UI")

	_GUICtrlListView_SetColumnWidth($g_hListView_VIP, 0, 60)
	_GUICtrlListView_SetColumnWidth($g_hListView_VIP, 1, 210)
	_GUICtrlListView_SetColumnWidth($g_hListView_VIP, 2, 100)
	_GUICtrlListView_SetColumnWidth($g_hListView_VIP, 3, 105)

	GUICtrlCreateGroup("", -99, -99, 1, 1)
EndFunc   ;==>_CreateGroup_StrategyStats
Func _GetGamingDate()
	; Chốt sổ 7h sáng: Trả về chuỗi ngày YYYY/MM/DD
	Local $iHour = @HOUR
	If $iHour < 7 Then
		Return StringReplace(_DateAdd('D', -1, _NowCalcDate()), "/", "-")
	Else
		Return StringReplace(_NowCalcDate(), "/", "-")
	EndIf
EndFunc   ;==>_GetGamingDate

Func _ShowVolumeReport()
	If $g_hVolumeGUI <> 0 Then GUIDelete($g_hVolumeGUI)
	$g_hVolumeGUI = GUICreate("💰 TRẠM KÊ KHAI HOA HỒNG (VOLUME)", 650, 450, -1, -1, -1, 0x00000008)
	GUISetBkColor(0x1E1E1E, $g_hVolumeGUI)

	GUICtrlCreateLabel("BẢNG THỐNG KÊ VOLUME GIAO DỊCH (CHỐT SỔ 7H SÁNG)", 20, 15, 600, 25)
	GUICtrlSetFont(-1, 13, 700, "Consolas")
	GUICtrlSetColor(-1, 0x00FF00)

	Local $hTab = GUICtrlCreateTab(20, 50, 610, 380)
	GUICtrlSetFont($hTab, 10, 600)
	; --- TAB 1.5: THEO TUẦN ---
	GUICtrlCreateTabItem("Hằng Tuần")
	Local $hListWeek = GUICtrlCreateListView("Tuần Giao Dịch (Năm-Tuần) | Tổng Cược (Volume)", 30, 85, 590, 335, BitOR($LVS_REPORT, $LVS_SINGLESEL))
	_LoadVolumeDataToView($hListWeek, "Weekly")
	; --- TAB 1: THEO NGÀY ---
	GUICtrlCreateTabItem("Hằng Ngày")
	Local $hListDay = GUICtrlCreateListView("Ngày Giao Dịch | Tổng Cược (Volume)", 30, 85, 590, 335, BitOR($LVS_REPORT, $LVS_SINGLESEL))
	_LoadVolumeDataToView($hListDay, "Daily")

	; --- TAB 2: THEO THÁNG ---
	GUICtrlCreateTabItem("Hằng Tháng")
	Local $hListMonth = GUICtrlCreateListView("Tháng Giao Dịch | Tổng Cược (Volume)", 30, 85, 590, 335, BitOR($LVS_REPORT, $LVS_SINGLESEL))
	_LoadVolumeDataToView($hListMonth, "Monthly")

	; --- TAB 3: THEO NĂM & TỔNG ---
	GUICtrlCreateTabItem("Theo Năm & Tổng Vĩnh Viễn")
	Local $hListYear = GUICtrlCreateListView("Năm / Tổng Vĩnh Viễn | Tổng Cược (Volume)", 30, 85, 590, 335, BitOR($LVS_REPORT, $LVS_SINGLESEL))
	_LoadVolumeDataToView($hListYear, "Yearly")

	; Cộng dòng Tổng vĩnh viễn vào Tab Năm
	Local $fTotal = Number(IniRead(@ScriptDir & "\volume_history.ini", "Total", "Lifetime", "0"))
	Local $iIndex = _GUICtrlListView_AddItem($hListYear, "🔥 TỔNG VĨNH VIỄN")
	_GUICtrlListView_AddSubItem($hListYear, $iIndex, _FormatNumber($fTotal) & " đ", 1)

	GUICtrlCreateTabItem("") ; Đóng Tab
	GUISetState(@SW_SHOW, $g_hVolumeGUI)
EndFunc   ;==>_ShowVolumeReport

Func _LoadVolumeDataToView($hListView, $sSection)
	_GUICtrlListView_SetColumnWidth($hListView, 0, 220)
	_GUICtrlListView_SetColumnWidth($hListView, 1, 350)
	GUICtrlSetBkColor($hListView, 0x2D2D30)
	GUICtrlSetColor($hListView, 0xFFFFFF)
	GUICtrlSetFont($hListView, 11, 400, "Segoe UI")

	Local $aData = IniReadSection(@ScriptDir & "\volume_history.ini", $sSection)
	If @error Then Return

	; Xếp ngược để ngày/tháng mới nhất ngoi lên đầu
	For $i = $aData[0][0] To 1 Step -1
		Local $iItem = _GUICtrlListView_AddItem($hListView, $aData[$i][0])
		_GUICtrlListView_AddSubItem($hListView, $iItem, _FormatNumber(Number($aData[$i][1])) & " đ", 1)
	Next
EndFunc   ;==>_LoadVolumeDataToView
Func _RefreshProfitDisplay()
	Local $sFilter = GUICtrlRead($g_hCombo_ProfitFilter)
	Local $sFileProfit = @ScriptDir & "\profit_history.ini"
	Local $fDisplayProf = 0

	Local $sToday = _GetGamingDate()
	Local $aD = StringSplit($sToday, "-")
	Local $sThisWeek = $aD[1] & "-W" & StringFormat("%02d", _WeekNumberISO($aD[1], $aD[2], $aD[3]))
	Local $sThisMonth = StringLeft($sToday, 7)
	Local $sThisYear = StringLeft($sToday, 4)

	If $sFilter = "Chọn Ngày Cụ Thể" Then
		GUICtrlSetState($g_hDate_ProfitFilter, $GUI_SHOW)
		Local $sPickedDate = GUICtrlRead($g_hDate_ProfitFilter)
		$fDisplayProf = Number(IniRead($sFileProfit, "Daily", $sPickedDate, "0"))
	Else
		GUICtrlSetState($g_hDate_ProfitFilter, $GUI_HIDE)
		Switch $sFilter
			Case "Hôm Nay"
				$fDisplayProf = Number(IniRead($sFileProfit, "Daily", $sToday, "0"))
			Case "Tuần Này"
				$fDisplayProf = Number(IniRead($sFileProfit, "Weekly", $sThisWeek, "0"))
			Case "Tháng Này"
				$fDisplayProf = Number(IniRead($sFileProfit, "Monthly", $sThisMonth, "0"))
			Case "Năm Nay"
				$fDisplayProf = Number(IniRead($sFileProfit, "Yearly", $sThisYear, "0"))
			Case "TỔNG VĨNH VIỄN"
				$fDisplayProf = Number(IniRead($sFileProfit, "Total", "Lifetime", "0"))
		EndSwitch
	EndIf

	; Tự động đổi màu (Xanh nếu Lãi, Đỏ nếu Lỗ)
	Local $sColor = 0x00FF00
	If $fDisplayProf < 0 Then $sColor = 0xFF3333
	GUICtrlSetColor($g_hLabel_TotalProfitStats, $sColor)

	Local $sSign = ($fDisplayProf > 0) ? "+" : ""
	GUICtrlSetData($g_hLabel_TotalProfitStats, $sSign & _FormatNumber($fDisplayProf) & " VND")
EndFunc   ;==>_RefreshProfitDisplay

Func _RefreshVolumeDisplay()
	Local $sFilter = GUICtrlRead($g_hCombo_VolumeFilter)
	Local $sFileVolume = @ScriptDir & "\volume_history.ini"
	Local $fDisplayVol = 0

	Local $sToday = _GetGamingDate()
	Local $aD = StringSplit($sToday, "-")
	Local $sThisWeek = $aD[1] & "-W" & StringFormat("%02d", _WeekNumberISO($aD[1], $aD[2], $aD[3]))
	Local $sThisMonth = StringLeft($sToday, 7)
	Local $sThisYear = StringLeft($sToday, 4)

	If $sFilter = "Chọn Ngày Cụ Thể" Then
		GUICtrlSetState($g_hDate_VolumeFilter, $GUI_SHOW)
		Local $sPickedDate = GUICtrlRead($g_hDate_VolumeFilter)
		$fDisplayVol = Number(IniRead($sFileVolume, "Daily", $sPickedDate, "0"))
	Else
		GUICtrlSetState($g_hDate_VolumeFilter, $GUI_HIDE)
		Switch $sFilter
			Case "Hôm Nay"
				$fDisplayVol = Number(IniRead($sFileVolume, "Daily", $sToday, "0"))
			Case "Tuần Này"
				$fDisplayVol = Number(IniRead($sFileVolume, "Weekly", $sThisWeek, "0"))
			Case "Tháng Này"
				$fDisplayVol = Number(IniRead($sFileVolume, "Monthly", $sThisMonth, "0"))
			Case "Năm Nay"
				$fDisplayVol = Number(IniRead($sFileVolume, "Yearly", $sThisYear, "0"))
			Case "TỔNG VĨNH VIỄN"
				$fDisplayVol = Number(IniRead($sFileVolume, "Total", "Lifetime", "0"))
		EndSwitch
	EndIf

	; ========================================================
	; TỰ ĐỘNG TÍNH VÀ HIỂN THỊ PHÍ HOA HỒNG LÊN GIAO DIỆN
	; ========================================================
	Local $fFee = Round($fDisplayVol * 0.005)
	GUICtrlSetData($g_hLabel_TotalVolume, _FormatNumber($fDisplayVol) & " đ (Phí: " & _FormatNumber($fFee) & " đ)")
EndFunc   ;==>_RefreshVolumeDisplay

Func _SyncLiveDashboard($fLiveBalance, $fLiveProfit, $fLiveVolume)
	GUICtrlSetData($g_hLabel_CurrentBalance, _FormatNumber($fLiveBalance) & " đ")
	GUICtrlSetColor($g_hLabel_CurrentBalance, 0x0000FF)

	If $fLiveProfit >= 0 Then
		GUICtrlSetData($g_hLabel_Profit, "+" & _FormatNumber($fLiveProfit) & " đ")
		GUICtrlSetColor($g_hLabel_Profit, 0x006400)
		GUICtrlSetData($g_hLabel_TotalProfitStats, "+" & _FormatNumber($fLiveProfit) & " đ")
		GUICtrlSetColor($g_hLabel_TotalProfitStats, 0x006400)
	Else
		GUICtrlSetData($g_hLabel_Profit, _FormatNumber($fLiveProfit) & " đ")
		GUICtrlSetColor($g_hLabel_Profit, 0xFF0000)
		GUICtrlSetData($g_hLabel_TotalProfitStats, _FormatNumber($fLiveProfit) & " đ")
		GUICtrlSetColor($g_hLabel_TotalProfitStats, 0xFF0000)
	EndIf

	; ========================================================
	; BƠM SỐ VOLUME KÈM THEO PHÍ HOA HỒNG 0.5% (TỨC THÌ)
	; ========================================================
	Local $fLiveFee = Round($fLiveVolume * 0.005)
	GUICtrlSetData($g_hLabel_TotalVolume, _FormatNumber($fLiveVolume) & " đ (Phí: " & _FormatNumber($fLiveFee) & " đ)")
	GUICtrlSetColor($g_hLabel_TotalVolume, 0x8A2BE2)
EndFunc   ;==>_SyncLiveDashboard
Func _UpdateDailyStats($fBetAmount, $fProfitChange)
	$g_fUnsyncedVolume += $fBetAmount ; <--- Dòng gom tiền vừa cược

	Local $sFileVolume = @ScriptDir & "\volume_history.ini"
	Local $sFileProfit = @ScriptDir & "\profit_history.ini"

	Local $sGamingDate = _GetGamingDate()
	Local $aD = StringSplit($sGamingDate, "-")
	Local $sGamingWeek = $aD[1] & "-W" & StringFormat("%02d", _WeekNumberISO($aD[1], $aD[2], $aD[3]))
	Local $sGamingMonth = StringLeft($sGamingDate, 7)
	Local $sGamingYear = StringLeft($sGamingDate, 4)

	; 1. LƯU BẢNG VOLUME VÀ CẬP NHẬT BIẾN NHỚ
	Local $fNewDailyVol = Number(IniRead($sFileVolume, "Daily", $sGamingDate, "0")) + $fBetAmount
	$g_fTotalVolume = $fNewDailyVol ; CHỐT CHẶN: Ép biến toàn cục đồng bộ với file

	IniWrite($sFileVolume, "Daily", $sGamingDate, $fNewDailyVol)
	IniWrite($sFileVolume, "Weekly", $sGamingWeek, Number(IniRead($sFileVolume, "Weekly", $sGamingWeek, "0")) + $fBetAmount)
	IniWrite($sFileVolume, "Monthly", $sGamingMonth, Number(IniRead($sFileVolume, "Monthly", $sGamingMonth, "0")) + $fBetAmount)
	IniWrite($sFileVolume, "Yearly", $sGamingYear, Number(IniRead($sFileVolume, "Yearly", $sGamingYear, "0")) + $fBetAmount)
	IniWrite($sFileVolume, "Total", "Lifetime", Number(IniRead($sFileVolume, "Total", "Lifetime", "0")) + $fBetAmount)

	; 2. LƯU BẢNG LỢI NHUẬN (PROFIT)
	IniWrite($sFileProfit, "Daily", $sGamingDate, Number(IniRead($sFileProfit, "Daily", $sGamingDate, "0")) + $fProfitChange)
	IniWrite($sFileProfit, "Weekly", $sGamingWeek, Number(IniRead($sFileProfit, "Weekly", $sGamingWeek, "0")) + $fProfitChange)
	IniWrite($sFileProfit, "Monthly", $sGamingMonth, Number(IniRead($sFileProfit, "Monthly", $sGamingMonth, "0")) + $fProfitChange)
	IniWrite($sFileProfit, "Yearly", $sGamingYear, Number(IniRead($sFileProfit, "Yearly", $sGamingYear, "0")) + $fProfitChange)
	IniWrite($sFileProfit, "Total", "Lifetime", Number(IniRead($sFileProfit, "Total", "Lifetime", "0")) + $fProfitChange)

	_RefreshVolumeDisplay()
	_RefreshProfitDisplay()

	_SyncVolumeToServer()
EndFunc   ;==>_UpdateDailyStats
; --- HÚT TOÀN BỘ CẤU HÌNH QLV VÀO TRẠM MÔ PHỎNG ---
; --- HÚT TOÀN BỘ CẤU HÌNH QLV VÀO TRẠM MÔ PHỎNG ---
Func _LoadAllVirtualQLVs()
	Local $iCount = 1
	Local $aUserPresets = IniReadSection($g_sIniPath, "UserQLV")
	If IsArray($aUserPresets) Then $iCount += $aUserPresets[0][0]

	ReDim $g_aVirtualQLVs[$iCount][2]

	; 1. NẠP CHÍNH XÁC NHỮNG GÌ SẾP ĐANG GÕ Ở Ô QLV BÊN NGOÀI
	$g_aVirtualQLVs[0][0] = "⭐ QLV HIỆN TẠI (Đang nhập)"
	Local $sCurrentUI = GUICtrlRead($g_hInput_CustomQLV_Edit)
	If $sCurrentUI = "" Then $sCurrentUI = "0-1-0-1" ; Chống trống
	$g_aVirtualQLVs[0][1] = StringReplace($sCurrentUI, @CRLF, "|NL|")

	; 2. NẠP TOÀN BỘ CÁC MẪU QLV SẾP ĐÃ LƯU TRONG DANH SÁCH
	If IsArray($aUserPresets) Then
		For $i = 1 To $aUserPresets[0][0]
			$g_aVirtualQLVs[$i][0] = $aUserPresets[$i][0]
			$g_aVirtualQLVs[$i][1] = $aUserPresets[$i][1]
		Next
	EndIf
EndFunc   ;==>_LoadAllVirtualQLVs
; =========================================================================
; HÀM AI TỰ ĐỘNG ĐỌC DỮ LIỆU VÀ PHÂN TÍCH RA TIẾNG VIỆT
; =========================================================================
Func _RunAI_Inspector()
	Local $iSelected = _GUICtrlListView_GetSelectedIndices($g_hSim_List)
	If $iSelected = "" Then
		GUICtrlSetData($g_hSim_Edit_Inspector, "⚠️ Sếp chưa chọn dòng nào cả! Bấm vào 1 hàng trong bảng trên rồi mới xem Sao Kê.")
		Return
	EndIf

	Local $sName = _GUICtrlListView_GetItemText($g_hSim_List, Number($iSelected), 0)
	Local $sProfit = _GUICtrlListView_GetItemText($g_hSim_List, Number($iSelected), 1)
	Local $sWinCa = _GUICtrlListView_GetItemText($g_hSim_List, Number($iSelected), 2)
	Local $sLossCa = _GUICtrlListView_GetItemText($g_hSim_List, Number($iSelected), 3)
	Local $sLog = _GUICtrlListView_GetItemText($g_hSim_List, Number($iSelected), 7) ; Lấy cột số 7

	Local $sReport = ">>> BẢNG SAO KÊ CHI TIẾT TỪNG CA: [" & $sName & "] <<<" & @CRLF
	$sReport &= "TỔNG KẾT QUẢ: " & $sProfit & " (Tổng " & $sWinCa & " - " & $sLossCa & ")" & @CRLF
	$sReport &= "--------------------------------------------------" & @CRLF

	If $sLog = "" Then
		$sReport &= "Không có dữ liệu ca đánh nào được ghi nhận."
	Else
		Local $aLogs = StringSplit($sLog, "|")
		For $i = 1 To $aLogs[0]
			Local $sLine = StringStripWS($aLogs[$i], 3)
			If $sLine <> "" Then
				If StringInStr($sLine, "HÚP") Then
					$sReport &= "🟢 " & $sLine & @CRLF
				ElseIf StringInStr($sLine, "GÃY") Then
					$sReport &= "🔴 " & $sLine & @CRLF
				Else
					$sReport &= "🟡 " & $sLine & @CRLF
				EndIf
			EndIf
		Next
	EndIf

	$sReport &= "--------------------------------------------------" & @CRLF
	$sReport &= "💡 Giải thích: Số tiền từng ca không bao giờ chẵn đúng mức cài đặt vì phụ thuộc vào Lệnh cuối cùng đánh bao nhiêu tiền (vượt mốc) và bị trừ 5% tiền phế (nếu ăn Banker). Cứ lấy từng dòng cộng lại sếp sẽ ra đúng y chóc số TỔNG KẾT QUẢ ở trên."

	GUICtrlSetData($g_hSim_Edit_Inspector, $sReport)
EndFunc   ;==>_RunAI_Inspector
; 2. HÀM LẤY GIÁ BÍ MẬT TỪ GOOGLE
Func _GetDynamicPrice()
	Local $sUrl = $g_sAppsScriptBaseURL & "?action=get_price&nocache=" & TimerInit()
	Local $sResponse = BinaryToString(InetRead($sUrl, 3), 4)
	Local $oJson = Json_Decode($sResponse)
	Local $iPrice = Json_Get($oJson, "[price]")
	If $iPrice = "" Or $iPrice = 0 Then Return 50000
	Return Number($iPrice)
EndFunc   ;==>_GetDynamicPrice

Func _WaitManualAction_Pro($sMessage = "Vui lòng thao tác trên web, sau đó bấm TIẾP TỤC")
	; Xóa thông báo cũ nếu đang mở (chống mở 2 bảng trùng nhau)
	Local Static $hWaitGUI = 0
	If $hWaitGUI <> 0 Then GUIDelete($hWaitGUI)

	; Tạo GUI không viền ($WS_POPUP), luôn nổi trên cùng ($WS_EX_TOPMOST), và không hiện dưới taskbar ($WS_EX_TOOLWINDOW)
	$hWaitGUI = GUICreate("Manual Action", 400, 130, -1, -1, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
	GUISetBkColor(0x111111, $hWaitGUI) ; Màu nền đen nhám huyền bí

	; Viền màu trên/dưới trang trí (Neon Xanh lá)
	GUICtrlCreateLabel("", 0, 0, 400, 2)
	GUICtrlSetBkColor(-1, 0x00FF00)
	GUICtrlCreateLabel("", 0, 128, 400, 2)
	GUICtrlSetBkColor(-1, 0x00FF00)

	; Tiêu đề cảnh báo chớp tắt hoặc màu nổi
	Local $hTitle = GUICtrlCreateLabel("⏳ HỆ THỐNG TẠM DỪNG CHỜ THAO TÁC", 10, 15, 380, 25, $SS_CENTER)
	GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0xFFD700) ; Màu vàng Gold cực sang

	; Nội dung thông báo
	Local $hText = GUICtrlCreateLabel($sMessage, 10, 50, 380, 35, $SS_CENTER)
	GUICtrlSetFont(-1, 10, 400, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0x00FF00) ; Xanh Matrix

	; Bức tường vô hình dùng để KÉO THẢ CỬA SỔ
	; Label này đè lên vùng chữ, sử dụng $GUI_WS_EX_PARENTDRAG cho phép nhấp giữ để di chuyển bảng
	Local $hDragArea = GUICtrlCreateLabel("", 0, 0, 400, 90, -1, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	; Nút xác nhận tiếp tục
	Local $hBtnDone = GUICtrlCreateButton("✓ ĐÃ XONG - TIẾP TỤC", 100, 90, 200, 30)
	GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
	GUICtrlSetBkColor(-1, 0x004400) ; Nền xanh lá đậm
	GUICtrlSetColor(-1, 0xFFFFFF)   ; Chữ trắng
	GUICtrlSetCursor(-1, 0)         ; Trỏ chuột hình bàn tay

	; Hiển thị bảng và làm trong suốt 10% (Alpha 230/255) để có thể thấy mờ mờ nội dung phía sau
	WinSetTrans($hWaitGUI, "", 230)
	GUISetState(@SW_SHOW, $hWaitGUI)

	; Vòng lặp khóa tool, chờ sếp bấm nút "ĐÃ XONG"
	While 1
		Switch GUIGetMsg()
			Case $hBtnDone
				ExitLoop
		EndSwitch
		Sleep(10)
	WEnd

	; Dọn dẹp bảng thông báo sau khi bấm
	GUIDelete($hWaitGUI)
	$hWaitGUI = 0
EndFunc   ;==>_WaitManualAction_Pro
Func _FormatMoneyVN($sInput)
	; Xóa sạch mọi thứ không phải là số (bao gồm cả dấu chấm cũ)
	$sInput = StringRegExpReplace($sInput, "\D", "")
	If $sInput = "" Then Return ""

	; Thuật toán chèn dấu chấm từ phải qua trái
	Local $sFormatted = ""
	While StringLen($sInput) > 3
		$sFormatted = "." & StringRight($sInput, 3) & $sFormatted
		$sInput = StringTrimRight($sInput, 3)
	WEnd
	Return $sInput & $sFormatted
EndFunc   ;==>_FormatMoneyVN
Func _SyncVolumeToServer()
	; Chỉ gửi khi có Volume chưa đồng bộ
	If $g_fUnsyncedVolume > 0 Then
		Local $fVolToSend = $g_fUnsyncedVolume
		$g_fUnsyncedVolume = 0 ; Reset ngay để không gửi trùng

		; Tạo đường link kèm Volume để báo cho Server
		Local $sUrl = $g_sAppsScriptBaseURL & "?action=add_volume&hwid=" & $g_sHWID & "&vol=" & $fVolToSend & "&nocache=" & TimerInit()

		; Bắn dữ liệu lên Google và đợi câu trả lời
		Local $sResponse = BinaryToString(InetRead($sUrl, 3), 4)

		; Nếu máy chủ phản hồi nợ vượt mốc -> Báo động khóa tool
		If StringInStr($sResponse, '"status":"DEBT"') Then
			$g_bIsRunning = False
			_UpdateStatus("🛑 BÁO ĐỘNG: Phí duy trì vượt mốc an toàn. Tool bị tạm khóa!")

			$g_hTargetGameWin = 0
			_SetControlsState(True)
			GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
			GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)

			Local $oJson = Json_Decode($sResponse)
			Local $iDebtAmount = Number(Json_Get($oJson, "[debt_amount]"))
			_ShowDebtDialog($iDebtAmount, $g_sHWID)
		EndIf
	EndIf
EndFunc   ;==>_SyncVolumeToServer
; ====================================================================
; ĐỘNG CƠ MA TRẬN HONG KONG 5 CỘT (ĐÃ NÂNG CẤP CHẾ ĐỘ TEST NGẦM)
; ====================================================================
; ====================================================================
; ĐỘNG CƠ MA TRẬN HONG KONG 5 CỘT (ĐÃ MỞ KHÓA QLV TÙY CHỈNH)
; ====================================================================
Func _Logic_VIP_HK5($sHistoryRaw, $bSilent = False)
	Local $aResult[3] = ["OBSERVE", "", 0]
	Local $sHistoryNow = StringReplace($sHistoryRaw, "T", "") ; Dọn sạch Hòa
	Local $iLen = StringLen($sHistoryNow)

	If $iLen < 5 Then
		If Not $bSilent Then _UpdateStatus("💎 VIP HK5: Đang lấy 5 ván mẫu (" & $iLen & "/5)...")
		Return $aResult
	EndIf

	Local $iRow = Floor($iLen / 5) + 1
	Local $iCol = Mod($iLen, 5) + 1

	; Lấy Hàng Mẫu
	Local $sSampleRow = StringMid($sHistoryNow, ($iRow - 2) * 5 + 1, 5)

	If $sSampleRow == "BBBBB" Or $sSampleRow == "PPPPP" Then
		If Not $bSilent Then _UpdateStatus("💎 VIP HK5: Hàng mẫu bị BỆT (" & $sSampleRow & ") -> Bỏ qua Hàng " & $iRow)
		Return $aResult
	EndIf

	Local $sCurrentRow = StringMid($sHistoryNow, ($iRow - 1) * 5 + 1, $iCol - 1)

	; Cột 1 chỉ dùng để xác định Trend (V hay X) ban đầu, không đánh
	If $iCol == 1 Then
		If Not $bSilent Then _UpdateStatus("💎 VIP HK5: Đợi ván " & $iLen + 1 & " (Cột 1 Hàng " & $iRow & ") để bắt V/X...")
		Return $aResult
	EndIf

	; Kiểm tra xem các cột trước đó đã Win chưa (Ăn 1 tay là nghỉ)
	Local $bAlreadyWon = False
	For $c = 2 To $iCol - 1
		; Trend luôn lấy từ kết quả đối chiếu của Cột ngay trước đó
		Local $sPrevTrend = (StringMid($sSampleRow, $c - 1, 1) == StringMid($sCurrentRow, $c - 1, 1)) ? "V" : "X"
		Local $sSampleC = StringMid($sSampleRow, $c, 1)

		; Xác định lệnh đánh của Cột c
		Local $sTarget = ($sPrevTrend == "V") ? $sSampleC : (($sSampleC == "B") ? "P" : "B")
		Local $sActual = StringMid($sCurrentRow, $c, 1)

		If $sActual == $sTarget Then
			$bAlreadyWon = True
			ExitLoop
		EndIf
	Next

	If $bAlreadyWon Then
		If Not $bSilent Then _UpdateStatus("💎 VIP HK5: Đã WIN 1 tay ở Hàng " & $iRow & " -> Chờ Hàng mới.")
		; ĐÃ XÓA LỆNH ÉP VỀ 0 Ở ĐÂY ĐỂ BẢO LƯU BẢNG QLV
		Return $aResult
	EndIf

	; --- LOGIC BÁM V/X CHO TAY HIỆN TẠI (TAY SẮP ĐÁNH) ---
	; Lấy Trend từ Cột ngay sát trước nó
	Local $sPrevTrend = (StringMid($sSampleRow, $iCol - 1, 1) == StringMid($sCurrentRow, $iCol - 1, 1)) ? "V" : "X"
	Local $sSampleNext = StringMid($sSampleRow, $iCol, 1)

	; Nếu V thì đánh Đồng, nếu X thì đánh Nghịch
	Local $sBetChar = ($sPrevTrend == "V") ? $sSampleNext : (($sSampleNext == "B") ? "P" : "B")

	; ĐÃ XÓA LỆNH ÉP VỐN THEO CỘT ($iCol - 2) Ở ĐÂY
	Local $aQLV = _GetQLV_Params($g_iCapitalLevel)

	$aResult[0] = "BET"
	$aResult[1] = $sBetChar
	$aResult[2] = $aQLV[1]

	If Not $bSilent Then _UpdateStatus("💎 VIP HK5 [Hàng " & $iRow & " Cột " & $iCol & "]: Theo Trend [" & $sPrevTrend & "] -> Vã Lệnh " & $g_iCapitalLevel & " vào " & $sBetChar)
	Return $aResult
EndFunc   ;==>_Logic_VIP_HK5
Func _UpdateVipButtonState()
	Local $sSelected = GUICtrlRead($g_hCombo_VIPMethod)
	Local $bIsVIPSelected = ($sSelected <> $g_aVipPackages[0][1])

	; =========================================================
	; 1. CÁCH LY GIAO DIỆN TÍNH NĂNG (ĐỨNG IM KHI CHỌN VIP)
	; =========================================================
	If $bIsVIPSelected Then
		GUICtrlSetState($g_hInput_CustomRules, $GUI_DISABLE)
		GUICtrlSetBkColor($g_hInput_CustomRules, 0xE0E0E0)
		GUICtrlSetState($g_hCheckbox_SeparateQLV, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_DuKich, $GUI_DISABLE)
		GUICtrlSetState($g_hCheckbox_VirtualBet, $GUI_DISABLE)
	Else
		GUICtrlSetState($g_hInput_CustomRules, $GUI_ENABLE)
		GUICtrlSetBkColor($g_hInput_CustomRules, 0xFFFACD)
		GUICtrlSetState($g_hCheckbox_SeparateQLV, $GUI_ENABLE)
		GUICtrlSetState($g_hCheckbox_ContinuousMode, $GUI_ENABLE)
		GUICtrlSetState($g_hCheckbox_ReverseLogic, $GUI_ENABLE)
		GUICtrlSetState($g_hCheckbox_DuKich, $GUI_ENABLE)
		GUICtrlSetState($g_hCheckbox_VirtualBet, $GUI_ENABLE)
	EndIf

	; =========================================================
	; 2. XỬ LÝ NÚT BẤM THANH TOÁN
	; =========================================================
	If Not $bIsVIPSelected Then
		GUICtrlSetData($g_hBtn_BuyVIP, "CHỌN PHƯƠNG PHÁP VIP BÊN TRÊN")
		GUICtrlSetState($g_hBtn_BuyVIP, $GUI_DISABLE)
		GUICtrlSetBkColor($g_hBtn_BuyVIP, 0xCCCCCC)
		Return
	EndIf

	Local $sCode = "", $iPrice = 0
	For $i = 1 To UBound($g_aVipPackages) - 1
		If $g_aVipPackages[$i][1] == $sSelected Then
			$sCode = $g_aVipPackages[$i][0]
			$iPrice = $g_aVipPackages[$i][2]
			ExitLoop
		EndIf
	Next

	; QUYỀN ADMIN TEST
	If $g_bIsDevMode Then
		GUICtrlSetData($g_hBtn_BuyVIP, "🛠️ QUYỀN ADMIN: ĐÃ MỞ KHÓA TEST")
		GUICtrlSetBkColor($g_hBtn_BuyVIP, 0x00FF00)
		GUICtrlSetState($g_hBtn_BuyVIP, $GUI_DISABLE)
		Return
	EndIf

	; KHÁCH HÀNG BÌNH THƯỜNG
	If StringInStr("," & $g_sActiveVIPs & ",", "," & $sCode & ",") Then
		GUICtrlSetData($g_hBtn_BuyVIP, "✅ ĐÃ KÍCH HOẠT THÀNH CÔNG!")
		GUICtrlSetBkColor($g_hBtn_BuyVIP, 0x00FF00)
		GUICtrlSetState($g_hBtn_BuyVIP, $GUI_DISABLE)
	Else
		GUICtrlSetData($g_hBtn_BuyVIP, "💎 MUA GÓI NÀY (" & _FormatNumber($iPrice) & "đ/Tháng)")
		GUICtrlSetBkColor($g_hBtn_BuyVIP, 0xFFD700)
		GUICtrlSetState($g_hBtn_BuyVIP, $GUI_ENABLE)
	EndIf
EndFunc   ;==>_UpdateVipButtonState
Func _HandleBuyVIP()
	Local $sSelected = GUICtrlRead($g_hCombo_VIPMethod)
	Local $sCode = "", $iPrice = 0
	For $i = 1 To UBound($g_aVipPackages) - 1
		If $g_aVipPackages[$i][1] == $sSelected Then
			$sCode = $g_aVipPackages[$i][0]
			$iPrice = $g_aVipPackages[$i][2]
			ExitLoop
		EndIf
	Next
	If $sCode = "" Then Return

	_ShowVIPPaymentDialog($sCode, $sSelected, $iPrice, $g_sHWID)
EndFunc   ;==>_HandleBuyVIP

; =====================================================================
; BẢNG THANH TOÁN QR DÀNH RIÊNG CHO MUA GÓI VIP ĐA MỆNH GIÁ
; =====================================================================
Func _ShowVIPPaymentDialog($sCode, $sName, $iPrice, $sHWID)
	Local $hPayGUI = GUICreate("MUA GÓI VIP ĐỘC QUYỀN", 450, 520, -1, -1, $WS_POPUP, $WS_EX_TOPMOST)
	GUISetBkColor(0x111111, $hPayGUI)

	Local $hBtnCloseX = GUICtrlCreateButton("X", 400, 10, 40, 35)
	GUICtrlSetBkColor($hBtnCloseX, 0xCC0000)
	GUICtrlSetColor($hBtnCloseX, 0xFFFFFF)
	GUICtrlSetFont(-1, 14, 800)

	GUICtrlCreateLabel("💎 MUA GÓI: " & $sName, 10, 15, 380, 40, $SS_CENTER)
	GUICtrlSetFont(-1, 11, 800)
	GUICtrlSetColor(-1, 0xFF00FF)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	Local $oIE = ObjCreate("Shell.Explorer.2")
	Local $hActiveX = GUICtrlCreateObj($oIE, 85, 60, 280, 280)

	GUICtrlCreateLabel("Mức phí: " & _FormatNumber($iPrice) & " VNĐ / Ngày", 10, 365, 430, 25, $SS_CENTER)
	GUICtrlSetFont(-1, 16, 800)
	GUICtrlSetColor(-1, 0x00FF00)

	; Nội dung chuyển khoản chuyên biệt cho từng gói VIP: MUAVIP HK5 XXXXX
	Local $sContent = "MUAVIP " & $sCode & " " & StringRight($sHWID, 6)
	GUICtrlCreateLabel("Nội dung CK: " & $sContent, 10, 405, 430, 25, $SS_CENTER)
	GUICtrlSetFont(-1, 14, 800)
	GUICtrlSetColor(-1, 0xFFD700)

	Local $hStatusLabel = GUICtrlCreateLabel("⏳ Đang chờ giao dịch... (7s)", 10, 455, 430, 35, BitOR($SS_CENTER, $SS_SUNKEN, 0x0200))
	GUICtrlSetFont(-1, 11, 700)
	GUICtrlSetColor(-1, 0x00FFFF)

	Local $sQrUrl = "https://qr.sepay.vn/img?bank=MB&acc=0986071012&amount=" & $iPrice & "&des=" & StringReplace($sContent, " ", "%20") & "&name=NGUYEN%20NGOC%20DUY"
	$oIE.navigate("about:blank")
	While $oIE.readyState <> 4
		Sleep(10)
	WEnd
	$oIE.document.open()
	$oIE.document.write("<html><body style='margin:0;padding:0;overflow:hidden;background-color:#111111;text-align:center;' scroll='no'><img src='" & $sQrUrl & "' width='280' height='280' style='border: 2px solid #00FFFF;'></body></html>")
	$oIE.document.close()

	GUISetState(@SW_SHOW, $hPayGUI)
	Local $hTimer = TimerInit()

	While 1
		Local $aMsg = GUIGetMsg(1)
		If $aMsg[0] = $hBtnCloseX Or $aMsg[0] = $GUI_EVENT_CLOSE Then ExitLoop

		If TimerDiff($hTimer) > 7000 Then
			GUICtrlSetData($hStatusLabel, "🔄 Đang kiểm tra máy chủ...")
			Local $aCheck = _CheckLicenseOnline($sHWID)

			; Nếu mua thành công, máy chủ sẽ quăng mã HK5 vào biến danh sách
			If StringInStr("," & $g_sActiveVIPs & ",", "," & $sCode & ",") Then
				GUICtrlSetData($hStatusLabel, "✅ MUA VIP THÀNH CÔNG! Đã mở khóa.")
				GUICtrlSetColor($hStatusLabel, 0x00FF00)
				_UpdateVipButtonState() ; Reset lại nút bên ngoài
				Sleep(1500)
				ExitLoop
			EndIf
			$hTimer = TimerInit()
			GUICtrlSetData($hStatusLabel, "⏳ Đang chờ giao dịch... (7s)")
		EndIf
	WEnd
	GUIDelete($hPayGUI)
EndFunc   ;==>_ShowVIPPaymentDialog

; ====================================================================
; KIỂM TRA BẢO MẬT TRƯỚC KHI CHẠY TOOL
; ====================================================================
Func _DecideNextAction()
	Local $aStop[3] = ["OBSERVE", "", 0]
	If _CheckProfitLossTargets() Then Return $aStop

	Local $iTotalHands = UBound($g_aDisplayHistory)

	; === KIỂM TRA QUYỀN VIP ===
	Local $bHasVipCode = False
	If StringInStr("," & $g_sActiveVIPs & ",", "," & $g_sAppliedVIPCode & ",") Then $bHasVipCode = True

	; ===============================================================
	; LUỒNG DÀNH CHO VIP (Đánh bằng HK5)
	; ===============================================================
	If $g_sAppliedVIPCode == "HK5" And ($bHasVipCode Or $g_bIsDevMode) Then
		Local $sHistoryRaw = ""
		For $i = 0 To $iTotalHands - 1
			$sHistoryRaw &= $g_aDisplayHistory[$i]
		Next
		Return _Logic_VIP_HK5($sHistoryRaw)
	EndIf

	; ===============================================================
	; LUỒNG DÀNH CHO BẢN THƯỜNG (Có Du Kích, Nối Đuôi, Custom...)
	; ===============================================================
	If GUICtrlRead($g_hCheckbox_DuKich) = $GUI_CHECKED Then
		If $g_iWaitTimeEnd_DuKich <> 0 Then
			Local $iElapsed = TimerDiff($g_iWaitTimeEnd_DuKich)
			If $iElapsed < $g_iWaitDuration_DuKich Then Return $aStop
			$g_iWaitTimeEnd_DuKich = 0
		EndIf
		If $g_iSkipSignalsCount_DuKich > 0 Then Return $aStop
	EndIf

	Local $aQLV = _GetQLV_Params($g_iCapitalLevel)
	Return _Logic_Custom($iTotalHands, $aQLV[1], False)
EndFunc   ;==>_DecideNextAction
Func _GetRealGameWindow($sClass)
	; 1. Bắt theo tọa độ Nút Banker (Ưu tiên 1)
	Local $iBankerX = Number(GUICtrlRead($g_hInput_BankerX))
	Local $iBankerY = Number(GUICtrlRead($g_hInput_BankerY))

	If $iBankerX > 0 And $iBankerY > 0 Then
		Local $tPoint = DllStructCreate("long X;long Y")
		DllStructSetData($tPoint, "X", $iBankerX)
		DllStructSetData($tPoint, "Y", $iBankerY)
		Local $hWndPoint = _WinAPI_WindowFromPoint($tPoint)
		If $hWndPoint <> 0 Then
			Local $hTopLevel = _WinAPI_GetAncestor($hWndPoint, 2) ; Lấy cửa sổ mẹ
			If $hTopLevel <> 0 And BitAND(WinGetState($hTopLevel), 2) Then
				Return $hTopLevel
			EndIf
		EndIf
	EndIf

	; 2. Bắt theo danh sách cửa sổ (Lọc kỹ hơn, chống nhầm qua tab khác)
	Local $aList = WinList("[CLASS:" & $sClass & "]")
	Local $hWndReal = 0

	Local $iResultColor = Number(GUICtrlRead($g_hInput_BankerColor)) ; Lấy màu chuẩn Banker làm mốc

	For $i = 1 To $aList[0][0]
		If $aList[$i][0] <> "" And BitAND(WinGetState($aList[$i][1]), 2) Then
			Local $aPos = WinGetPos($aList[$i][1])
			; Cửa sổ phải đủ to (trên 300px) để là trình duyệt
			If IsArray($aPos) And $aPos[2] > 300 And $aPos[3] > 300 Then
				; Nếu chưa tìm được cửa sổ nào, cứ lấy tạm cửa sổ to nhất
				If $hWndReal = 0 Then $hWndReal = $aList[$i][1]

				; NHƯNG nếu trong cửa sổ này quét thấy mã màu của game, chốt luôn cửa sổ này!
				If IsArray(PixelSearch($aPos[0], $aPos[1], $aPos[0] + $aPos[2], $aPos[1] + $aPos[3], $iResultColor, 10)) Then
					Return $aList[$i][1]
				EndIf
			EndIf
		EndIf
	Next

	If $hWndReal <> 0 Then Return $hWndReal
	Return WinGetHandle("[CLASS:" & $sClass & "]")
EndFunc   ;==>_GetRealGameWindow
Func _UpdateChecksheet()
	If $g_hEdit_Checksheet = 0 Then Return

	Local $sHistoryNow = ""
	For $i = 0 To UBound($g_aDisplayHistory) - 1
		$sHistoryNow &= $g_aDisplayHistory[$i]
	Next
	$sHistoryNow = StringReplace($sHistoryNow, "T", "")
	Local $iLen = StringLen($sHistoryNow)

	Local $sSelectedVIP = GUICtrlRead($g_hCombo_VIPMethod)
	Local $bIsVIPActive = ($sSelectedVIP <> $g_aVipPackages[0][1])

	Local $sOutput = ""

	If $bIsVIPActive And StringInStr($sSelectedVIP, "HK5") Then
		$sOutput &= "💎 MA TRẬN HONG KONG 5 CỘT" & @CRLF
		$sOutput &= "======================================" & @CRLF

		Local $iTotalRows = Floor($iLen / 5)
		If Mod($iLen, 5) > 0 Then $iTotalRows += 1

		For $r = 1 To $iTotalRows
			Local $sRowData = StringMid($sHistoryNow, ($r - 1) * 5 + 1, 5)
			Local $sFormattedRow = ""

			For $c = 1 To 5
				If $c <= StringLen($sRowData) Then
					$sFormattedRow &= StringMid($sRowData, $c, 1) & "   "
				Else
					$sFormattedRow &= "-   "
				EndIf
			Next

			$sOutput &= "[HÀNG " & StringFormat("%02d", $r) & "] KQ :  " & $sFormattedRow & @CRLF

			; Vẽ hàng V/X ngay phía dưới (V: Đồng mẫu, X: Nghịch mẫu)
			If $r > 1 Then
				Local $sSampleRow = StringMid($sHistoryNow, ($r - 2) * 5 + 1, 5)
				If StringLen($sSampleRow) == 5 And $sSampleRow <> "BBBBB" And $sSampleRow <> "PPPPP" Then
					Local $sPredictRow = ""
					For $c = 1 To 5
						If $c <= StringLen($sRowData) Then
							Local $sSC = StringMid($sSampleRow, $c, 1)
							Local $sCC = StringMid($sRowData, $c, 1)
							Local $sVX = ($sSC == $sCC) ? "V" : "X"
							$sPredictRow &= $sVX & "   "
						Else
							$sPredictRow &= "-   "
						EndIf
					Next
					$sOutput &= "        (V/X):  " & $sPredictRow & @CRLF
				ElseIf $sSampleRow == "BBBBB" Or $sSampleRow == "PPPPP" Then
					$sOutput &= "        -> Bão bệt (Dừng hàng này)" & @CRLF
				EndIf
			EndIf
			$sOutput &= "--------------------------------------" & @CRLF
		Next
	Else
		$sOutput &= "🎯 PHƯƠNG PHÁP: CÔNG THỨC CUSTOM" & @CRLF
		$sOutput &= "======================================" & @CRLF
		If $g_iLastActiveRuleIndex > -1 Then
			$sOutput &= "⚡ Đang bám sát cầu (Dòng " & ($g_iLastActiveRuleIndex + 1) & ")" & @CRLF
			$sOutput &= "⚡ Bước tiến trong chuỗi: " & $g_iCustomSeqStep & @CRLF
			$sOutput &= "⚡ Cấp vốn hiện tại (Level): " & $g_iCapitalLevel & @CRLF
		Else
			$sOutput &= "👁️ Trạng thái: Đang dò tín hiệu mồi..." & @CRLF
			$sOutput &= "💰 Cấp vốn hiện tại (Level): " & $g_iCapitalLevel & @CRLF
		EndIf
	EndIf

	GUICtrlSetData($g_hEdit_Checksheet, $sOutput)
	GUICtrlSendMsg($g_hEdit_Checksheet, $EM_LINESCROLL, 0, 9999)
EndFunc   ;==>_UpdateChecksheet
Func _UpdateVIPListUI()
	If $g_hListView_VIP = 0 Then Return
	_GUICtrlListView_DeleteAllItems($g_hListView_VIP)

	Local $iListIndex = 0

	For $i = 1 To UBound($g_aVipPackages) - 1
		Local $sCode = $g_aVipPackages[$i][0]
		Local $sName = $g_aVipPackages[$i][1]
		Local $iPrice = $g_aVipPackages[$i][2]
		Local $sUnit = $g_aVipPackages[$i][3]

		Local $sStatus = "🔒 KHÓA"
		If $g_bIsDevMode Or StringInStr("," & $g_sActiveVIPs & ",", "," & $sCode & ",") Then
			$sStatus = "🔓 ĐÃ THUÊ"
		EndIf

		Local $bIsApplied = False
		If $g_sAppliedVIPCode == $sCode Then $bIsApplied = True
		If $bIsApplied Then $sStatus = "✅ ĐANG CHẠY"

		Local $sPriceTxt = ($iPrice == 0) ? "0 đ" : _FormatNumber($iPrice) & "đ /" & $sUnit
		Local $sItemText = $sCode & "|" & $sName & "|" & $sPriceTxt & "|" & $sStatus
		Local $hItem = GUICtrlCreateListViewItem($sItemText, $g_hListView_VIP)

		; Tự động tick và tô màu
		If $bIsApplied Then
			_GUICtrlListView_SetItemChecked($g_hListView_VIP, $iListIndex, True)
			GUICtrlSetBkColor($hItem, 0x004400)
			GUICtrlSetColor($hItem, 0x00FF00)
			GUICtrlSetFont($hItem, 10, 800)
		ElseIf $sStatus == "🔒 KHÓA" Then
			GUICtrlSetBkColor($hItem, 0x330000)
			GUICtrlSetColor($hItem, 0xFF6666)
		Else
			GUICtrlSetBkColor($hItem, 0x2D2D30)
			GUICtrlSetColor($hItem, 0xFFD700)
			GUICtrlSetFont($hItem, 10, 700)
		EndIf

		$iListIndex += 1
	Next

	; LƯU LẠI BỘ NHỚ CHECKBOX SAU KHI VẼ XONG
	Local $sNewState = ""
	For $k = 0 To _GUICtrlListView_GetItemCount($g_hListView_VIP) - 1
		If _GUICtrlListView_GetItemChecked($g_hListView_VIP, $k) Then $sNewState &= $k & "|"
	Next
	$g_sLastCheckedVIPList = $sNewState
EndFunc   ;==>_UpdateVIPListUI
Func _ProcessVIPListCheckboxes()
	Local $bMethodChecked = False
	Local $bNeedRedraw = False

	For $i = 0 To _GUICtrlListView_GetItemCount($g_hListView_VIP) - 1
		Local $sCode = _GUICtrlListView_GetItemText($g_hListView_VIP, $i, 0)
		Local $sName = _GUICtrlListView_GetItemText($g_hListView_VIP, $i, 1)
		Local $bIsChecked = _GUICtrlListView_GetItemChecked($g_hListView_VIP, $i)
		Local $sRawPrice = StringRegExpReplace(_GUICtrlListView_GetItemText($g_hListView_VIP, $i, 2), "\D", "")
		Local $iPrice = Number($sRawPrice)

		If $bIsChecked Then
			; Nếu người dùng chọn một phương pháp mới
			If $g_sAppliedVIPCode <> $sCode Then
				Local $bOwned = False
				If $g_bIsDevMode Or StringInStr("," & $g_sActiveVIPs & ",", "," & $sCode & ",") Then $bOwned = True

				If Not $bOwned Then
					; XÓA DẤU TICK LẬP TỨC VÌ CHƯA MUA BẢN QUYỀN
					_GUICtrlListView_SetItemChecked($g_hListView_VIP, $i, False)
					$g_sLastCheckedVIPList = StringReplace($g_sLastCheckedVIPList, $i & "|", "")

					; Hiện bảng QR thanh toán
					_ShowVIPPaymentDialog($sCode, $sName, $iPrice, $g_sHWID)
					Return ; Chặn lại, không xử lý tiếp
				Else
					; Đã mua bản quyền -> Cho phép chạy
					$g_sAppliedVIPCode = $sCode
					$g_sAppliedVIPName = $sName
					_UpdateStatus("🚀 Đã kích hoạt Phương pháp: " & $sName)
					$bMethodChecked = True
					$bNeedRedraw = True

					; Tự động xóa tick của tất cả các phương pháp khác (Chỉ cho chạy 1 cái)
					For $j = 0 To _GUICtrlListView_GetItemCount($g_hListView_VIP) - 1
						If $j <> $i Then
							_GUICtrlListView_SetItemChecked($g_hListView_VIP, $j, False)
							$g_sLastCheckedVIPList = StringReplace($g_sLastCheckedVIPList, $j & "|", "")
						EndIf
					Next
				EndIf
			Else
				; Phương pháp này vốn đang chạy sẵn rồi
				$bMethodChecked = True
			EndIf
		EndIf
	Next

	; Nếu không có ô nào được đánh dấu tick -> Quay về CÔNG THỨC MẶC ĐỊNH
	If Not $bMethodChecked And $g_sAppliedVIPCode <> "NONE" Then
		$g_sAppliedVIPCode = "NONE"
		$g_sAppliedVIPName = "Không dùng"
		_UpdateStatus("✅ Đã tắt Phương pháp, Hệ thống sẽ chạy Công thức tùy chỉnh mặc định.")
		$bNeedRedraw = True
	EndIf

	If $bNeedRedraw Then _UpdateVIPListUI()
EndFunc   ;==>_ProcessVIPListCheckboxes
Func _CheckVIPStateChanges()
	If $g_hListView_VIP = 0 Then Return
	Local $sCurrentChecked = ""
	For $i = 0 To _GUICtrlListView_GetItemCount($g_hListView_VIP) - 1
		If _GUICtrlListView_GetItemChecked($g_hListView_VIP, $i) Then
			$sCurrentChecked &= $i & "|"
		EndIf
	Next

	; Nếu trạng thái các ô tick không thay đổi thì không làm gì cả
	If $sCurrentChecked == $g_sLastCheckedVIPList Then Return

	; Nếu có thay đổi (vừa tích vào hoặc bỏ tích), lập tức xử lý
	$g_sLastCheckedVIPList = $sCurrentChecked
	_ProcessVIPListCheckboxes()
EndFunc   ;==>_CheckVIPStateChanges
