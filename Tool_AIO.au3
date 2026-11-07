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

; --- BIẾN TOÀN CỤC CHO WEBDRIVER ---
Global $g_sSession = "" ; Lưu phiên làm việc của Chrome

; --- ÉP CHUẨN MÔI TRƯỜNG ĐỂ CHỐNG LỆCH TỌA ĐỘ TRÊN MÁY KHÁCH ---
Opt("MouseCoordMode", 1)  ; 1 = Chuột dùng Tọa độ tuyệt đối toàn màn hình
Opt("PixelCoordMode", 1)  ; 1 = Quét màu dùng Tọa độ tuyệt đối toàn màn hình
;Opt("ColorMode", 0)       ; 0 = Đọc mã màu chuẩn RGB (Không bị đảo ngược xanh/đỏ)

; <<<< Yêu cầu quyền quản trị để tool hoạt động ổn định >>>>
#RequireAdmin
; ==================================================================================================
; --- PHẦN CẤU HÌNH (BẮT BUỘC) ---
; ==================================================================================================
Global $g_sCustomerLogin = ""
Global $g_sCustomerRole = ""
Global Const $g_sAppsScriptBaseURL = "https://script.google.com/macros/s/AKfycbzYsojeFPtUJNwNKMMclP7zuj9TO6XYyq16O02Pi-ef87OP2kYz3TV3kT02XBw_GXuE/exec"
Global Const $g_sDevPassword = "nmn12nntv21"
Global Const $g_sToolName = "Tool_AIO"
; --- CẤU HÌNH AUTO UPDATE GITHUB ---
Global Const $g_sVersion = "5.3" ; Phiên bản hiện tại
Global Const $g_sCopyright = "Thuộc Bản Quyền Telegram @nnduy2086"
Global Const $g_sGithubVersionURL = "https://raw.githubusercontent.com/nnduy86/BaccaratTool/main/version.txt"
Global Const $g_sDownloadURL = "https://github.com/nnduy86/BaccaratTool/raw/main/Tool_AIO.exe"

; --- KHAI BÁO BIẾN TOÀN CỤC ---
; ==================================================================================================
; 1. ÉP ĐƯỜNG DẪN TUYỆT ĐỐI (Chống mất dữ liệu khi chạy Admin)
Global $g_sIniPath = @ScriptDir & "\Settings_AIO.ini" ; BẮT BUỘC dùng @ScriptDir để luôn trỏ về thư mục chứa Tool
; --- KHAI BÁO BIẾN MA TRẬN XÓC ĐĨA VIP ---
Global $g_hGroup_XocDiaGrid, $g_hLbl_XD_Status, $g_hLbl_XD_Seq
Global $g_hInput_XD_Seq, $g_hInput_XD_MaxRows
Global $g_aXocDiaGrid[11][16]  ; Ma trận 10 Hàng, 15 Cột
Global $g_aXD_Rows[11]
Global $g_aXD_Cols[16]

; [NÂNG CẤP MẢNG 2 CHIỀU]
Global $g_aXocDia_Seq[11][16]  ; Biến lưu bộ nhớ tiền cược độc lập cho 10 Hàng x 15 Cột
Global $g_aXD_MaxStepsPerRow[11] ; Biến lưu sức chịu đựng tối đa của từng hàng
Global $g_hInput_XD_Virtual    ; Ô nhập chuỗi lệnh nháp (Thay cho Combo)

Global $g_aTierStep[11] = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
Global $g_iDynamicMaxSteps = 0 ; Sẽ được tính động

; BIẾN TOÀN CỤC CHO QLV XÓC ĐĨA VIP 5 HÀNG
; =========================================================================
Global $g_bIsXocDiaVIP_Mode = False ; Cờ hiệu bật/tắt chế độ Xóc Đĩa VIP
Global $g_iCurrentTier = 1 ; Hàng hiện tại (Từ 1 đến 5)
; --- BIẾN GIAO DIỆN XÓC ĐĨA VIP ---
Global $g_hCheckbox_XocDiaVIP
Global $g_hInput_SimString, $g_hBtn_RunSim
Global $g_hCombo_SimQLV
Global $g_hInput_LimitBtnX, $g_hInput_LimitBtnY, $g_hButton_GetLimitBtn
Global $g_hInput_Limit10_500X, $g_hInput_Limit10_500Y, $g_hButton_GetLimit10_500
Global $g_hInput_Limit20_50KX, $g_hInput_Limit20_50KY, $g_hButton_GetLimit20_50K
Global $g_hInput_LimitConfirmX, $g_hInput_LimitConfirmY, $g_hButton_GetLimitConfirm
Global $g_hCheckbox_PinTool, $g_hGroup_BettingMethod
Global $g_hGroup_XocDiaGrid

Global $g_hCheckbox_XD_AutoResetDebt, $g_hInput_XD_TargetProfit
Global $g_hCheckbox_XD_LowDebtPriority
Global $g_hCombo_XD_Virtual ; Biến menu chọn số lệnh Nháp
Global $g_fXD_CycleProfit = 0.0 ; Biến đếm lãi/lỗ của chu kỳ hiện tại để chốt

; --- KHAI BÁO BIẾN ÉP ẨN GIAO DIỆN TRÁI (Dán lên đầu file) ---
Global $g_hGroup_BettingMethod, $g_hCheckbox_SeparateQLV, $g_hCheckbox_ReverseLogic
Global $g_hLabel_TieuDeCongThuc, $g_hInput_CustomRules
Global $g_hGroup_QLV_Main, $g_hLbl_QLV1, $g_hInput_CustomQLV_Edit
Global $g_hLbl_QLV2, $g_hCombo_QLV_Presets, $g_hButton_SaveQLV, $g_hButton_DeleteQLV

Global $g_hGroup_QLV_Main, $g_hLbl_QLV1, $g_hLbl_QLV2 ; Biến tóm khung QLV
Global $g_hLbl_XD_Seq, $g_hInput_XD_Seq ; Biến cho ô nhập chuỗi Xóc đĩa tự do

; Biến quản lý Hạn Mức (Limit)
Global $g_sCurrentLimitState = "10-500" ; Mặc định mới vào là 10-500
Global $g_iLimitBtnX = 0, $g_iLimitBtnY = 0       ; Nút mở bảng Cài Đặt Limit
Global $g_iLimit10_500X = 0, $g_iLimit10_500Y = 0 ; Nút chọn 10-500
Global $g_iLimit20_50KX = 0, $g_iLimit20_50KY = 0 ; Nút chọn 20-50K
Global $g_iLimitConfirmX = 0, $g_iLimitConfirmY = 0 ; Nút Xác Nhận
Global Const $g_iTimeOutLimit = 45000
Global $g_hRadio_Action_Stop, $g_hRadio_Action_PauseMin, $g_hRadio_Action_PauseHand
Global $g_hInput_Action_PauseMin, $g_hInput_Action_PauseHand
Global $g_iTargetPauseEndTime = 0
Global $g_iTargetPauseDuration = 0
Global $g_iTargetPauseHands = 0
Global $g_bIsRunning = False
Global $g_sIniPath
Global $g_sMemoryTargetBet = "" ; Biến nhớ: Lệnh sắp tới sẽ đánh gì theo Memory Code
Global $g_iIdleHands = 0 ; Bộ đếm số ván đã đứng nhìn
Global Const $MAX_IDLE_HANDS = 4 ; Giới hạn số ván nghỉ (Sếp có thể sửa thành 3 hoặc 5 tùy sảnh)
Global $g_hInput_TargetProfitPercent ; Ô nhập % Chốt Lời (Mốc Dương)
Global $g_hInput_StopLossPercent     ; Ô nhập % Dừng Lỗ (Mốc Âm)
Global $g_hCheckbox_DuKich
Global $g_bIsFormatting = False
Global $g_sInstanceIdentifier
Global $g_hSessionTimer
Global $g_hCheckbox_AutoAI_BeCau ; Biến nút bật/tắt AI bẻ cầu
Global $g_sCurrentLoadedProfile = ""
Global $g_hCheckbox_ContinuousMode
Global $g_hTargetGameWin = 0
; --- BIẾN CHO TÍNH NĂNG MEMORY CODE (MẬT MÃ GHI NHỚ) & OCR ---
Global $g_hCheckbox_MemoryCode
Global $g_hInput_PointBankerX, $g_hInput_PointBankerY, $g_hButton_GetPointBanker
Global $g_hInput_PointPlayerX, $g_hInput_PointPlayerY, $g_hButton_GetPointPlayer
Global $g_hInput_OCRBoxSize, $g_hButton_TestOCR
Global $g_sMemoryTargetBet = ""
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
; =========================================================================
; KHAI BÁO BIẾN TOÀN CỤC CHO MEMORY CODE
; =========================================================================
; Mảng lưu trí nhớ cho điểm 0, 1, 2, 3, 4. Giá trị lưu sẽ là "B", "P" hoặc "" (chưa có)
Global $g_aMemoryCode[5] = ["", "", "", "", ""]
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
; --- BIẾN CHO THƯ VIỆN CÔNG THỨC ---
Global $g_hList_FormulaLibrary
Global $g_hBtn_LoadFormula
Global $g_hBtn_SaveFormula
Global $g_hBtn_DeleteFormula
Global $g_iUniCols = 12 ; Sửa thành 10 nếu sảnh sếp chơi chỉ hiện 10 cột
Global $g_iUniRows = 6  ; Bảng khối luôn là 6 hàng
Global $g_iGridCols_Max = 18 ; Tổng số cột tối đa của khung bảng (Tùy sếp đếm sảnh PP là bao nhiêu thì sửa lại)
Global $g_iGridRows_Max = 6  ; Bảng khối luôn luôn là 6 hàng
Global $g_sLastAIPredict = "" ; Bộ nhớ tạm của AI khi gấp thếp
Global $g_sLastAILogicInfo = "" ; Lưu lý do AI vào lệnh để hiển thị cho sếp xem
Global $g_iAIWaitCount = 0 ; Bộ đếm số ván AI đã đứng nhìn (Chống văng bàn)
Global $g_fAITargetThreshold = 85.0 ; Tiêu chuẩn mặc định ban đầu của AI
Global $g_iTableProfit_Units = 0 ; Biến đếm số Đơn vị (Lót) Lãi/Lỗ của bàn hiện tại (KHÔNG TÍNH PHẾ)
; --- BIẾN CHO TÍNH NĂNG RADAR SĂN CẦU ---
Global $g_hCheckbox_Radar12
Global $g_hInput_BigRoadX1, $g_hInput_BigRoadY1, $g_hInput_BigRoadX2, $g_hInput_BigRoadY2
Global $g_hButton_GetBigRoadTL, $g_hButton_GetBigRoadBR
Global $g_hInput_BigRoadShade
; ==================================================================================================
; --- BIẾN CHO CHIẾN THUẬT DU KÍCH ĐA BÀN (12 BÀN TUẦN TỰ) ---
; ==================================================================================================
Global $g_hCheckbox_DuKichDaBan
Global $g_aInput_AnchorX[12], $g_aInput_AnchorY[12], $g_aButton_GetAnchor[12]
Global $g_hInput_DuKich_WinTable, $g_hInput_DuKich_LossTable, $g_hInput_DuKich_RestTime
Global $g_iCurrentTableIndex = 0 ; Từ 0 đến 11 (Tương ứng Bàn 1 -> Bàn 12)
Global $g_fCurrentTableProfit = 0 ; Lưu lợi nhuận/lỗ TIỀN MẶT của bàn
Global $g_iTableProfit_Units = 0  ; Lưu lợi nhuận/lỗ ĐƠN VỊ (Lót) của bàn (Chuẩn 100% không tính phế)
Global $g_hButton_TestBigRoad
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
Global $g_iCycleProfit_Units = 0 ; Đếm Lãi/Lỗ chu kỳ (Đơn vị lót)
Global $g_iHK_ValidHands_CycleStart = 0 ; Mốc đánh dấu ván bắt đầu của Chu kỳ Mới
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


Global $g_sLastLLBoard = "" ; Biến nhớ bảng cầu Long Long cũ
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
Global $g_hInput_LaiKepPercent ; Biến lưu ô nhập % Lãi kép
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
Global $g_hLbl_B, $g_hLbl_P, $g_hLbl_T
Global $g_hLbl_Coord_B, $g_hLbl_Coord_P, $g_hLbl_Coord_T, $g_hLbl_Color_B
; --- BIẾN CHO TÍNH NĂNG SĂN BÀN MỚI (DU KÍCH) ---
Global $g_hCheckbox_SanBanMoi
Global $g_hInput_FirstCellX, $g_hInput_FirstCellY, $g_hButton_GetFirstCell
Global $g_hInput_RadarRed, $g_hButton_GetRadarRed, $g_hInput_RadarBlue, $g_hButton_GetRadarBlue
Global $g_fTableProfit_RealUnits = 0.0 ; Đếm Lãi/Lỗ Chu kỳ (Tính phế 0.95 lót)
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
Global $g_hCombo_WinMode ; Biến quản lý tùy chọn hạ cửa sổ
Global $g_hButton_SaveNewProfile, $g_hButton_DeleteProfile
Global $g_hRadio_ClickMode_Control_Main, $g_hRadio_ClickMode_Mouse_Main
Global $g_hInput_ClickDelay_Main
Global $g_hGroup_QLV_Flexible
Global $g_hInput_CustomQLV_Edit
Global $g_hCombo_QLV_Presets
Global $g_sGameWindowClass
Global $g_aBankerButtonPos[2]
Global $g_aPlayerButtonPos[2]
Global $g_aTieButtonPos[2]
Global $g_hInput_TieX, $g_hInput_TieY, $g_hButton_GetTiePos
Global $g_aResultArea[4]
Global $g_iBankerColor
Global $g_iPlayerColor
Global $g_iTieColor
Global $g_hCheckbox_SanBanMoi
Global $g_hInput_FirstCellX, $g_hInput_FirstCellY, $g_hButton_GetFirstCell
Global $g_fTableProfit_RealUnits = 0.0 ; Biến đếm lót thực tế (có số thập phân 0.95)
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
Global $g_fCurrentCycleBaseBet = 0 ; Biến khóa tiền gốc cho cả chu kỳ gấp thếp
Global $g_hCheckbox_VirtualBet
Global $g_iVirtualLosses = 0
Global $g_bIsRealBetting = True
; --- BIẾN MỚI CHO TÍNH NĂNG NHÁP TÌNH BÁO ---
Global $g_hInput_VirtualLossTarget   ; Ô nhập số tay nháp
Global $g_hCombo_VirtualWinAction    ; Menu chọn hành động khi thắng nháp
Global $g_bForceTableSwitch = False  ; Biến cờ hiệu ép nhảy bàn
; --- BIẾN QUẢN LÝ BẢNG ẨN GIAO DIỆN (ADMIN) ---
; --- BIẾN QUẢN LÝ BẢNG ẨN GIAO DIỆN (TỔNG HỢP TOÀN BỘ TOOL) ---
Global $g_hAdminHideList
Global Const $g_iTotalHideItems = 15
Global $g_hLabel_TieuDeCongThuc          ; Biến cho dòng chữ Tiêu đề Công Thức (Nếu bạn đã gán)

Global $g_fUnsyncedVolume = 0 ; Lưu trữ Volume chưa đẩy lên Server

; --- BIẾN CHO TÍNH NĂNG BẢO VỆ TỔNG NGÀY (DAILY SHIELD) ---
Global $g_hLabel_NetDay
Global $g_hCheckbox_DailyShield
Global $g_hInput_DailyTarget, $g_hInput_DailyTrailing, $g_hInput_DailyStopLoss
Global $g_hRadio_DailyAction_Stop
Global $g_fPeakNetDay = 0.0
Global $g_bIsDailyTrailing = False

Global $g_hCheckbox_BaccaratLaser ; Checkbox chọn chế độ quét Laser cho Baccarat

Global $g_hButton_ResetDaily

Global $g_bIsVIP = False
Global $g_iVipDaysLeft = 0
Global $g_hCombo_VIPMethod
Global $g_hBtn_BuyVIP
Global $g_sActiveVIPs = "" ; Lưu danh sách các gói VIP đang được phép dùng

Global $g_aVipPackages[3][4] = [ _
		["NONE", "CÔNG THỨC CUSTOM (Nhập tay)", 0, "Miễn Phí"], _
		["HK5", "MA TRẬN HONG KONG 5 CỘT", 70000, "Ngày"], _
		["HK3", "MA TRẬN HONG KONG 3 CỘT", 50000, "Ngày"] _
		]
Global $g_bIsDevMode = False ; Biến ẩn chỉ dành cho Developer

Global $g_sMachineStatus = "" ; Theo dõi trạng thái máy (Mới/Đã Kích Hoạt)
Global $g_hButton_ActivateNew = 0 ; Nút bấm kích hoạt 100k

Global $g_fServerVolumeToday = 0 ; Biến lưu Volume thực tế từ máy chủ
_Main()

Func _Main()
    ; ---> BỔ SUNG LỆNH NÀY ĐẦU TIÊN: Đảm bảo khi tắt tool sẽ gọi hàm dọn rác RAM
    OnAutoItExitRegister("_ExitCleanup")

    If _Singleton("ToolCasino_Lock_Main", 1) = 0 Then
        MsgBox(48, "Thông báo", "Tool đang được mở rồi!")
        Exit
    EndIf
    Sleep(500)
    _CheckForUpdates()

    ; ---> LẤY HWID TRƯỚC TIÊN <---
    $g_sHWID = _GetHardwareID()

    ; --- BẮT ĐẦU ĐOẠN ĐĂNG NHẬP ---
    Local $bIsLoggedIn = False

    ; [TÍNH NĂNG MỚI] TỰ ĐỘNG ĐĂNG NHẬP NGẦM NẾU ĐÃ LƯU TÊN TỪ TRƯỚC
    Local $sSavedUser = IniRead($g_sIniPath, "Settings", "LastUsername", "")
    If $sSavedUser <> "" Then
        $g_sCustomerLogin = $sSavedUser
        ; Gửi thẳng thông tin lên Server để check ngầm
        $bIsLoggedIn = _CheckLoginOnline($g_sCustomerLogin, $g_sHWID)
    EndIf

    ; Nếu đăng nhập ngầm thành công, vòng lặp While dưới đây sẽ BỊ BỎ QUA hoàn toàn
    ; Nếu thất bại (hoặc mở tool lần đầu chưa có tên), bảng đăng nhập mới hiện ra
    While Not $bIsLoggedIn
        ; 1. Tạo giao diện Đăng Nhập chuyên nghiệp
        Local $hLoginGUI = GUICreate("Đăng Nhập Tool - @nnduy2086", 400, 260, -1, -1, BitOR($WS_CAPTION, $WS_SYSMENU), $WS_EX_TOPMOST)
        GUISetBkColor(0xF0F4F8, $hLoginGUI)

            GUICtrlCreateLabel("MÃ MÁY (HWID) CỦA BẠN LÀ:", 20, 20, 360, 20)
            GUICtrlSetFont(-1, 10, 700, 0, "Segoe UI")
            GUICtrlSetColor(-1, 0x0000FF)

            ; Ô chứa mã HWID (Chữ to, màu đỏ)
            Local $hInput_HWID = GUICtrlCreateInput($g_sHWID, 20, 45, 250, 28, BitOR($ES_READONLY, $ES_CENTER))
            GUICtrlSetFont(-1, 12, 700, 0, "Segoe UI")
            GUICtrlSetColor(-1, 0xFF0000)
            GUICtrlSetBkColor(-1, 0xFFFACD)

            ; NÚT BẤM COPY
            Local $hBtn_Copy = GUICtrlCreateButton("📋 COPY", 280, 44, 100, 30)
            GUICtrlSetBkColor(-1, 0x33CC33)
            GUICtrlSetColor(-1, 0xFFFFFF)
            GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")

           ; Hướng dẫn
            GUICtrlCreateLabel("BƯỚC 1: Bấm COPY gửi mã máy cho Admin." & @CRLF & "BƯỚC 2: Chờ Admin kích hoạt." & @CRLF & "BƯỚC 3: Nhập Tên Đăng Nhập vào ô dưới đây:", 20, 90, 360, 55)
            GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")

            ; Ô nhập Tên đăng nhập (Đọc tên đã lưu từ file config)
            Local $sSavedUser = IniRead($g_sIniPath, "Settings", "LastUsername", "")
            Local $hInput_User = GUICtrlCreateInput($sSavedUser, 20, 155, 360, 30, $ES_CENTER)

            GUICtrlSetFont(-1, 12, 700, 0, "Segoe UI")

            ; Nút Đăng nhập
            Local $hBtn_Login = GUICtrlCreateButton("ĐĂNG NHẬP", 90, 200, 220, 40)
            GUICtrlSetBkColor(-1, 0x0082FA)
            GUICtrlSetColor(-1, 0xFFFFFF)
            GUICtrlSetFont(-1, 12, 800, 0, "Segoe UI")

            GUISetState(@SW_SHOW, $hLoginGUI)

            Local $sInputUser = ""
            Local $bExit = False

            ; 2. Vòng lặp chờ khách bấm nút
            While 1
                Switch GUIGetMsg()
                    Case $GUI_EVENT_CLOSE
                        $bExit = True
                        ExitLoop

                    Case $hBtn_Copy
                        ; Lệnh copy mã máy vào Clipboard
                        ClipPut($g_sHWID)
                        MsgBox(64 + 262144, "Thành Công", "Đã copy Mã Máy: " & $g_sHWID & @CRLF & @CRLF & "Hãy ra Zalo/Telegram bấm Dán (Ctrl + V) để gửi cho Admin nhé!", 0, $hLoginGUI)

                    Case $hBtn_Login
                        $sInputUser = StringStripWS(GUICtrlRead($hInput_User), 3)
                        If $sInputUser <> "" Then
                            ; Ghi nhớ tên đăng nhập vào file cấu hình
                            IniWrite($g_sIniPath, "Settings", "LastUsername", $sInputUser)
                            ExitLoop
                        Else
                            MsgBox(48 + 262144, "Lỗi", "Vui lòng nhập Tên Đăng Nhập Admin đã cấp!", 0, $hLoginGUI)
                        EndIf
                EndSwitch
            WEnd

            GUIDelete($hLoginGUI)

            ; Nếu khách bấm dấu X tắt bảng thì thoát Tool luôn
            If $bExit Then Exit

            ; 3. Gửi lên Server kiểm tra
            $g_sCustomerLogin = $sInputUser
            $bIsLoggedIn = _CheckLoginOnline($g_sCustomerLogin, $g_sHWID)
        WEnd
        ; --- KẾT THÚC ĐOẠN ĐĂNG NHẬP ---
		HotKeySet("{F4}", "_DebugGrid")
    HotKeySet("{F5}", "_TestCurrentTableZones")
    HotKeySet("{F6}", "_TestRadarZones")

    ; Khởi tạo trạng thái thiết bị (gọi check_init cũ)
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
EndFunc
Func _CreateGUI($sExpiryDate)
	Local $iWinX = IniRead($g_sIniPath, "Settings", "WinX", -1)
	Local $iWinY = IniRead($g_sIniPath, "Settings", "WinY", -1)

	; BỘ LỌC CHỐNG LỖI TỌA ĐỘ BÓNG MA (Ép Tool luôn hiện giữa màn hình nếu tọa độ bị sai)
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

	Global $g_hTab1_Main = GUICtrlCreateTabItem("Giao Diện Chính")
	_CreateTab_MainTool()

	$g_hTabItemConfig = GUICtrlCreateTabItem("Phòng Kỹ Thuật")
	_CreateTab_ConfigHelper()
	GUICtrlCreateTabItem("")

	_LoadSettings()
	_SetControlsState(True)
	_ToggleConfigControlsState(False)
	_UpdateClock()

	If $g_bStartHidden Then
		GUISetState(@SW_HIDE, $g_hGUI)
	Else
		GUISetState(@SW_SHOW, $g_hGUI)
	EndIf

	; ---> KÍCH HOẠT GHIM NGAY TỪ LÚC MỞ TOOL <---
	If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
		WinSetOnTop($g_hGUI, "", 1)
	EndIf
EndFunc
Func _CreateTab_MainTool()
    _CreateGroup_Settings()
    _CreateGroup_BettingMethod()

    ; ĐÃ TRẢ LẠI BẢNG QUẢN LÝ VỐN VÀO ĐÂY
    _CreateGroup_QLV_On_Main()
    _CreateGroup_XocDia_Grid()
    _CreateGroup_BPT_Totals()
    _CreateGroup_HistoryDisplay()
    _CreateGroup_HistoryLog()

    _CreateGroup_InfoAndTargets()
    _CreateGroup_UserConfig_Main()
EndFunc
; HÀM VÒNG LẶP CHÍNH
; ==================================================================================================
Func _MainLoop()
	AdlibRegister("_CheckForUpdates", 6000000)

	While 1
		If $g_bNeedAutoSave And TimerDiff($g_hAutoSaveTimer) > 1000 Then
			If $g_sCurrentLoadedProfile <> "" Then _MasterSave($g_sCurrentLoadedProfile)
			$g_bNeedAutoSave = False
		EndIf

		Local $aMsg = GUIGetMsg(1)

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

				; ---> XỬ LÝ CLICK TASKBAR CHUẨN MỰC AN TOÀN <---
Case $GUI_EVENT_RESTORE
				WinActivate($g_hGUI)
				If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
					WinSetOnTop($g_hGUI, "", 1) ; Nếu đang tích thì ép nổi lên
				Else
					WinSetOnTop($g_hGUI, "", 1)
					WinSetOnTop($g_hGUI, "", 0) ; Nếu ko tích thì nhả ra
				EndIf

			Case $g_hCheckbox_PinTool
				If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
					WinSetOnTop($g_hGUI, "", 1)
					_UpdateStatus("📌 Đã ghim Tool nổi lên trên màn hình Game.")
				Else
					WinSetOnTop($g_hGUI, "", 0)
					_UpdateStatus("🔽 Đã gỡ ghim. Tool sẽ ẩn khi click vào Game.")
				EndIf
				Case $g_hCombo_XD_Virtual
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
				_UpdateXocDiaGridUI()
			Case $g_hButton_GetFirstCell
				_GetCoords_Fast($g_hInput_FirstCellX, $g_hInput_FirstCellY)

				Case $g_hButton_GetLimitBtn
				_GetCoords_Fast($g_hInput_LimitBtnX, $g_hInput_LimitBtnY)
			Case $g_hButton_GetLimit10_500
				_GetCoords_Fast($g_hInput_Limit10_500X, $g_hInput_Limit10_500Y)
			Case $g_hButton_GetLimit20_50K
				_GetCoords_Fast($g_hInput_Limit20_50KX, $g_hInput_Limit20_50KY)
			Case $g_hButton_GetLimitConfirm
				_GetCoords_Fast($g_hInput_LimitConfirmX, $g_hInput_LimitConfirmY)

			Case $g_hRadio_ClickMode_Control_Main, $g_hRadio_ClickMode_Mouse_Main
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
			Case $g_hCombo_VolumeFilter, $g_hDate_VolumeFilter
				_RefreshVolumeDisplay()
			Case $g_hCombo_ProfitFilter, $g_hDate_ProfitFilter
				_RefreshProfitDisplay()
				Case $g_hButton_GetRadarRed
				_GetColor_Fast($g_hInput_RadarRed)
			Case $g_hButton_GetRadarBlue
				_GetColor_Fast($g_hInput_RadarBlue)
Case $GUI_EVENT_CLOSE
    If $aMsg[1] = $g_hGUI Then
        Local $aPos = WinGetPos($g_hGUI)
        If IsArray($aPos) And $aPos[0] > -10000 Then
            IniWrite($g_sIniPath, "Settings", "WinX", $aPos[0])
            IniWrite($g_sIniPath, "Settings", "WinY", $aPos[1])
        EndIf
        _MasterSave(GUICtrlRead($g_hCombo_Profiles_Main))

        ; --- THÊM DÒNG NÀY ĐỂ TẮT CHROME DRIVER ---
        If $g_sSession <> "" Then
            _WD_DeleteSession($g_sSession)
            _WD_Shutdown()
        EndIf
        ; ------------------------------------------

        Exit
    EndIf
		Case $g_hButton_SaveNewProfile
			; Code cũ: Local $sNewProfile = InputBox("Tạo Sảnh Mới", "Nhập tên cho sảnh...", "Sảnh Evo - Long Long")

Local $sNewName = InputBox("Cấp Phát Cấu Hình VIP", "Nhập thông tin theo cú pháp 3 phần:" & @CRLF & "[TênKhách]_[TênSảnh]_[TròChơi]" & @CRLF & @CRLF & "Ví dụ 1: thuydung_Sexy_XocDia" & @CRLF & "Ví dụ 2: thuydung_WM_Baccarat", "")

    ; NẾU BẤM CANCEL HOẶC ĐỂ TRỐNG THÌ BỎ QUA, QUAY LẠI VÒNG LẶP
    If @error Or $sNewName == "" Then
        ContinueLoop
    EndIf

    ; Lưu toàn bộ thông số tọa độ, màu sắc, tính năng hiện tại vào sảnh mới này
    _MasterSave($sNewName, False)

    ; Cập nhật lại danh sách xổ xuống và tự động chọn luôn sảnh vừa tạo
    _PopulateProfileList()
    GUICtrlSetData($g_hCombo_Profiles, $sNewName)
    GUICtrlSetData($g_hCombo_Profiles_Main, $sNewName)
    $g_sCurrentLoadedProfile = $sNewName

    ; Báo cáo thành công
    MsgBox(64, "Thành Công", "Tuyệt vời! Đã lưu toàn bộ thiết lập hiện tại vào sảnh: " & $sNewName)

			Case $g_hButton_DeleteProfile
				Local $sSelectedProfile = GUICtrlRead($g_hCombo_Profiles)
				If $sSelectedProfile = "" Then
					MsgBox(48, "Cảnh Báo", "Bạn chưa chọn sảnh nào để xóa!")
					ContinueLoop
				EndIf

				; Bật hộp thoại hỏi xác nhận chống bấm nhầm
				If MsgBox(36, "Xác Nhận Xóa", "Bạn có chắc chắn muốn xóa vĩnh viễn cấu hình của: [" & $sSelectedProfile & "] không?") = 6 Then

					; 1. Xóa sạch sảnh này khỏi file config.ini
					IniDelete($g_sIniPath, "Profile_" & $sSelectedProfile)

					; 2. Xóa trí nhớ của tool để nó KHÔNG kích hoạt Auto-save hồi sinh sảnh cũ
					$g_sCurrentLoadedProfile = ""

					; 3. Đọc lại file INI xem CÓ THỰC SỰ còn sảnh nào khác không
					Local $aSections = IniReadSectionNames($g_sIniPath)
					Local $sNextProfile = ""
					If Not @error Then
                        For $i = 1 To $aSections[0]
                            If StringLeft($aSections[$i], 8) = "Profile_" Then
                                $sNextProfile = StringTrimLeft($aSections[$i], 8)
                                ExitLoop ; Tìm thấy sảnh đầu tiên còn sót lại là thoát vòng lặp ngay
                            EndIf
                        Next
					EndIf

					; 4. Phân luồng chuyển sảnh an toàn
					If $sNextProfile <> "" Then
						_PopulateProfileList()
						GUICtrlSetData($g_hCombo_Profiles_Main, $sNextProfile)
						GUICtrlSetData($g_hCombo_Profiles, $sNextProfile)
						_HandleProfileChange($g_hCombo_Profiles)
					Else
						_CreateDefaultIniFile()
						_PopulateProfileList()

						; ---> ĐỔI THÀNH TIẾNG VIỆT CHUẨN TẠI ĐÂY <---
						GUICtrlSetData($g_hCombo_Profiles_Main, "Sảnh PP Mẫu")
						GUICtrlSetData($g_hCombo_Profiles, "Sảnh PP Mẫu")
						_HandleProfileChange($g_hCombo_Profiles)
					EndIf

					MsgBox(64, "Thành Công", "Đã tiêu diệt vĩnh viễn sảnh [" & $sSelectedProfile & "].")
				EndIf
			Case $g_hCheckbox_LaiKepVIP
				; Đã mở khóa hoàn toàn cho sếp và khách tự do tích chọn sử dụng
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
			Case $g_hBtn_LoadFormula
				_LoadSelectedFormula()
			Case $g_hBtn_SaveFormula
				_SaveCurrentFormula()
			Case $g_hBtn_DeleteFormula
				_DeleteSelectedFormula()
			Case $g_hListView_VIP
Case $g_hButton_Start
				If $g_bIsRunning Then
					; NẾU ĐANG CHẠY MÀ BẤM THÌ DỪNG LẠI
					_StopProcess()
					GUICtrlSetData($g_hButton_Start, "BẮT ĐẦU QUÉT")
					GUICtrlSetBkColor($g_hButton_Start, 0x33CC33) ; Trả về màu Xanh Lá

					; Khôi phục màn hình tool nếu nó đang ẩn
					GUISetState(@SW_RESTORE, $g_hGUI)
				Else
					; ==============================================================
					; QUY TRÌNH 1 CHẠM: MỞ CHROME -> RÌNH POPUP -> CẮM AUTO
					; ==============================================================

					; 1. Đổi giao diện nút bấm thành DỪNG
					$g_bIsRunning = True
					GUICtrlSetState($g_hButton_Start, $GUI_ENABLE)
					GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
					GUICtrlSetBkColor($g_hButton_Start, 0xFF4141) ; Đổi sang màu Đỏ

					; ---> HẠ TOOL XUỐNG TASKBAR LẬP TỨC <---
					GUISetState(@SW_MINIMIZE, $g_hGUI)
					_UpdateStatus("🔽 Đã hạ Tool xuống Taskbar để sếp tiện thao tác trên Game...")

					; 2. Gọi hàm mở Chrome
					Local $iInitChrome = _LaunchChrome_WebDriver()

					If $iInitChrome == 1 Then
						; 3. Chrome mở xong, lập tức chuyển sang trạng thái "Treo Ngầm Rình Popup"
						If _AutoCatchPopup_And_Maximize() Then
							; Nếu hàm trên trả về True (Chộp được Popup) -> Chuyển thẳng sang hàm Quét Kết Quả
							_UpdateStatus("🚀 [CHỐT TỌA ĐỘ] Đã khóa cứng vào bàn Game. Bắt đầu nã đạn!")
							_StartProcess()
						Else
							; Nếu hàm trả về False (Do sếp bấm DỪNG lúc đang chờ)
							_UpdateStatus("🛑 Đã hủy quá trình chờ Game.")
							_StopProcess()
							; Bấm hủy thì móc tool lên lại
							GUISetState(@SW_RESTORE, $g_hGUI)
						EndIf
					Else
						; Lỗi không mở được Chrome (Lỗi WebDriver)
						_UpdateStatus("🛑 Lỗi: Không thể khởi động Chrome WebDriver!")
						_StopProcess()
						; Bị lỗi thì móc tool lên lại để xem thông báo
						GUISetState(@SW_RESTORE, $g_hGUI)
					EndIf
				EndIf
			Case $g_hButton_Unlock
                Local $sCurrentText = GUICtrlRead($g_hButton_Unlock)

                ; 1. NẾU ĐANG KHÓA -> YÊU CẦU MẬT KHẨU ĐỂ MỞ CHO ADMIN
                If StringInStr($sCurrentText, "MỞ KHÓA") Then
                    Local $sPass = InputBox("Yêu cầu mật khẩu", "Vui lòng nhập mật khẩu...", "", "*")
                    If $sPass == $g_sDevPassword Then
                        $g_bIsDevMode = True ; Cấp quyền Admin toàn cục

                        _ToggleTechRoom($GUI_SHOW) ; Hiện các nút lấy tọa độ
                        _ToggleConfigControlsState(True) ; Mở sáng các ô nhập liệu
                        _UpdateVipButtonState() ; Cập nhật nút VIP sang chế độ Admin Test

                        ; Đổi giao diện nút thành nút KHÓA
                        GUICtrlSetData($g_hButton_Unlock, "🔓 KHÓA LẠI")
                        GUICtrlSetBkColor($g_hButton_Unlock, 0x33CC33)
                    ElseIf $sPass <> "" Then
                        MsgBox(16, "Lỗi", "Sai mật khẩu!")
                    EndIf

                ; 2. NẾU ĐANG MỞ -> BẤM ĐỂ KHÓA LẠI CHO KHÁCH HÀNG
                Else
                    $g_bIsDevMode = False ; Tước quyền Admin

                    _ToggleTechRoom($GUI_HIDE) ; Ẩn các nút lấy tọa độ
                    _ToggleConfigControlsState(False) ; Làm xám (khóa) các ô nhập liệu
                    _UpdateVipButtonState() ; Trả nút VIP về chế độ Khách hàng (bắt buộc mua)

                    ; Đổi giao diện nút về mặc định
                    GUICtrlSetData($g_hButton_Unlock, "🔐 MỞ KHÓA")
                    GUICtrlSetBkColor($g_hButton_Unlock, 0xFF4141)

                    ; Báo cáo thành công cho Admin yên tâm bàn giao
                    ;MsgBox(64, "Đã Khóa", "Đã khóa Phòng Kỹ Thuật an toàn." & @CRLF & "Tool hiện đang ở chế độ dành cho Khách Hàng!")
                EndIf
			Case $g_hButton_Lock
				$g_bIsDevMode = False
				_ToggleConfigControlsState(False)
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
Case $g_hCheckbox_XocDiaVIP, $g_hCheckbox_BaccaratLaser
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()
				_ToggleGameModeUI() ; <--- Thêm dòng này để bấm phát đổi chữ ngay
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
		; Xử lý 12 nút lấy tọa độ Neo (Gốc)
		For $i = 0 To 11
			If $aMsg[0] = $g_aButton_GetAnchor[$i] Then
				_GetCoords_Fast($g_aInput_AnchorX[$i], $g_aInput_AnchorY[$i])
			EndIf
		Next
	WEnd
EndFunc   ;==>_MainLoop
; ==================================================================================================
; HÀM VÒNG LẶP PHỤ (KHI TOOL ĐANG QUÉT GAME)
; ==================================================================================================
Func _ProcessGUIMessages()
	Local $aMsg = GUIGetMsg(1)

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
		EndIf
	EndIf

	Switch $aMsg[0]
		; ---> XỬ LÝ CLICK TASKBAR CHUẨN MỰC AN TOÀN <---
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

		Case $g_hCombo_ProfitFilter, $g_hDate_ProfitFilter
			_RefreshProfitDisplay()

		; ---> XỬ LÝ NÚT GHIM TOOL <---
		Case $g_hCheckbox_PinTool
			If GUICtrlRead($g_hCheckbox_PinTool) == $GUI_CHECKED Then
				; Ép Tool nổi lên trên cùng (TopMost)
				WinSetOnTop($g_hGUI, "", 1)
				_UpdateStatus("📌 Đã ghim Tool nổi lên trên màn hình Game.")
			Else
				; Gỡ ghim, Tool sẽ tự động lặn xuống dưới nếu khách click vào trình duyệt Game
				WinSetOnTop($g_hGUI, "", 0)
				_UpdateStatus("🔽 Đã gỡ ghim. Tool sẽ ẩn khi click vào Game.")
			EndIf
	EndSwitch
EndFunc
Func _CreateStyledGroup($sTitle, $iX, $iY, $iW, $iH)
	Local $hGroup = GUICtrlCreateGroup($sTitle, $iX, $iY, $iW, $iH, $WS_GROUP, $WS_EX_CLIENTEDGE)
	GUICtrlSetFont($hGroup, 10, 700)
	GUICtrlSetColor($hGroup, 0x0000FF)
	GUICtrlSetBkColor($hGroup, 0xF5F5F5)
	Return $hGroup
EndFunc   ;==>_CreateStyledGroup

; ================= CỘT 1: BÊN TRÁI (Vốn, PP, QLV) =================
Func _CreateGroup_Settings()
	Local $hGroup = _CreateStyledGroup("Vốn & Cài Đặt Cược", 10, 35, 350, 85) ; Tăng W lên 350
	Local $y = 55
	GUICtrlCreateLabel("Vốn ban đầu:", 20, $y, 100, 20)
	$g_hInput_InitialCapital = GUICtrlCreateInput("0", 130, $y - 3, 210, 22) ; Kéo dài ô nhập tiền
	GUICtrlSetBkColor(-1, 0xE0FFFF)
	$y += 28
	GUICtrlCreateLabel("Giá trị cược:", 20, $y, 100, 20)
	$g_hInput_InitialBet = GUICtrlCreateInput("0", 130, $y - 3, 210, 22)
	GUICtrlSetBkColor(-1, 0xE0FFFF)
EndFunc

Func _CreateGroup_BettingMethod()
	$g_hGroup_BettingMethod = GUICtrlCreateGroup("PHƯƠNG PHÁP CƯỢC", 10, 125, 350, 240)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0x00008B)

	Local $y = 145
	$g_hCheckbox_SeparateQLV = GUICtrlCreateCheckbox("QLV Riêng", 20, $y, 90, 20)
	$g_hCheckbox_ReverseLogic = GUICtrlCreateCheckbox("Bám Chuỗi", 130, $y, 90, 20)

	$y += 25
	$g_hLabel_TieuDeCongThuc = GUICtrlCreateLabel("📝 NHẬP CÔNG THỨC CƯỢC:", 20, $y, 260, 20)
	GUICtrlSetColor(-1, 0x0000FF)

	$y += 20
	$g_hInput_CustomRules = GUICtrlCreateEdit("", 20, $y, 320, 155, BitOR(0x00200000, 0x00000040, 0x00001000))
	GUICtrlSetBkColor(-1, 0xFFFACD)
EndFunc

Func _CreateGroup_QLV_On_Main()
	$g_hGroup_QLV_Main = _CreateStyledGroup("Cấu Hình Quản Lý Vốn", 10, 370, 350, 185)
	Local $y_inner = 390
	$g_hLbl_QLV1 = GUICtrlCreateLabel("Lệnh-Vốn-Thắng-Thua", 20, $y_inner, 150, 15)
	GUICtrlSetFont(-1, 8.5, 700)
	GUICtrlSetColor(-1, 0x800080)

	$g_hInput_CustomQLV_Edit = GUICtrlCreateEdit("", 20, $y_inner + 18, 150, 135, BitOR($ES_AUTOVSCROLL, $WS_VSCROLL, $ES_NOHIDESEL))
	GUICtrlSetBkColor(-1, 0xF0FFF0)

	$g_hLbl_QLV2 = GUICtrlCreateLabel("Chọn QLV mẫu:", 180, $y_inner, 100, 20)
	$g_hCombo_QLV_Presets = GUICtrlCreateCombo("", 180, $y_inner + 18, 155, 25, $CBS_DROPDOWNLIST)
	$g_hButton_SaveQLV = GUICtrlCreateButton("Lưu", 180, $y_inner + 50, 70, 25)
	GUICtrlSetBkColor(-1, 0x90EE90)
	$g_hButton_DeleteQLV = GUICtrlCreateButton("Xóa", 260, $y_inner + 50, 75, 25)
	GUICtrlSetBkColor(-1, 0xFFB6C1)
EndFunc

Func _CreateGroup_XocDia_Grid()
    $g_hGroup_XocDiaGrid = GUICtrlCreateGroup("📊 GẤP THẾP ĐA TẦNG RIÊNG BIỆT", 10, 125, 350, 405)
    GUICtrlSetFont(-1, 9, 800)
    GUICtrlSetColor(-1, 0xFF0000)

    Local $yOffset = 150
    Local $xOffset = 12
    Local $wCell = 17
    Local $hCell = 19
    Local $spacing = 19
    Local $startX = $xOffset + 24

    For $c = 1 To 15
        $g_aXD_Cols[$c] = GUICtrlCreateLabel("B" & $c, $startX + ($c-1)*$spacing, $yOffset, $wCell+2, 15, $SS_CENTER)
        GUICtrlSetFont(-1, 7, 700)
    Next
    $yOffset += 16

    For $r = 1 To 10
        $g_aXD_Rows[$r] = GUICtrlCreateLabel("H" & $r, $xOffset, $yOffset + ($r-1)*($hCell+5) + 2, 22, 20)
        GUICtrlSetFont(-1, 8, 800)
        GUICtrlSetColor(-1, 0x0000FF)

        For $c = 1 To 15
            $g_aXocDiaGrid[$r][$c] = GUICtrlCreateLabel("-", $startX + ($c-1)*$spacing, $yOffset + ($r-1)*($hCell+5), $wCell+2, $hCell, BitOR($SS_CENTER, 0x0200))
            GUICtrlSetFont(-1, 7, 800)
            GUICtrlSetBkColor(-1, 0xE0E0E0)
        Next
    Next

    $yOffset += 10 * ($hCell+5) + 2

    $g_hLbl_XD_Seq = GUICtrlCreateLabel("Hệ số (x Vốn):", $xOffset, $yOffset + 2, 85, 20)
    GUICtrlSetFont(-1, 8.5, 700)
    $g_hInput_XD_Seq = GUICtrlCreateInput("1, 2, 4, 8, 17, 35, 75", $xOffset + 85, $yOffset, 160, 22)
    GUICtrlSetBkColor(-1, 0xFFFACD)

    GUICtrlCreateLabel("Hàng:", $xOffset + 255, $yOffset + 2, 35, 20)
    GUICtrlSetFont(-1, 8.5, 700)
    $g_hInput_XD_MaxRows = GUICtrlCreateInput("5", $xOffset + 295, $yOffset, 30, 22)
    GUICtrlSetBkColor(-1, 0xE0FFFF)

    $yOffset += 25
    $g_hCheckbox_XD_AutoResetDebt = GUICtrlCreateCheckbox("Tự xóa nợ khi Lãi >=", $xOffset, $yOffset, 145, 20)
    GUICtrlSetFont(-1, 8.5, 700)
    GUICtrlSetColor(-1, 0x0000FF)
    $g_hInput_XD_TargetProfit = GUICtrlCreateInput("50.000", $xOffset + 145, $yOffset - 2, 180, 22)
    GUICtrlSetBkColor(-1, 0xE0FFFF)

    $yOffset += 25
    $g_hCheckbox_XD_LowDebtPriority = GUICtrlCreateCheckbox("Ưu tiên gỡ nợ nhỏ", $xOffset, $yOffset, 125, 20)
    GUICtrlSetFont(-1, 8.5, 700)
    GUICtrlSetColor(-1, 0x008000)

    ; [NÂNG CẤP] Thay thế Menu bằng Ô nhập liệu chuỗi Nháp
    GUICtrlCreateLabel("Nháp (H1,H2..):", $xOffset + 130, $yOffset + 2, 90, 20)
    GUICtrlSetFont(-1, 8.5, 700)
    $g_hInput_XD_Virtual = GUICtrlCreateInput("2, 0, 1", $xOffset + 225, $yOffset, 80, 22)
    GUICtrlSetBkColor(-1, 0xFFFACD)
    GUICtrlSetTip(-1, "Nhập số ván nháp cho từng hàng. Ví dụ: 2,0,1 nghĩa là H1 nháp 2 tay, H2 nháp 0 tay, H3 nháp 1 tay.")

    $yOffset += 25
    $g_hLbl_XD_Status = GUICtrlCreateLabel("Trạng thái: Đang chờ tín hiệu...", $xOffset, $yOffset, 320, 40)
    GUICtrlSetFont(-1, 9, 800)
    GUICtrlSetColor(-1, 0x008000)

    _ToggleXocDiaGridState($GUI_HIDE)
EndFunc
Func _ToggleBaccaratLeftColumn($iState)
    ; Ẩn sạch sẽ khung Phương Pháp Cược
    GUICtrlSetState($g_hGroup_BettingMethod, $iState)
    GUICtrlSetState($g_hCheckbox_SeparateQLV, $iState)
    GUICtrlSetState($g_hCheckbox_ReverseLogic, $iState)
    GUICtrlSetState($g_hLabel_TieuDeCongThuc, $iState)
    GUICtrlSetState($g_hInput_CustomRules, $iState)

    ; Ẩn sạch sẽ khung Quản Lý Vốn
    GUICtrlSetState($g_hGroup_QLV_Main, $iState)
    GUICtrlSetState($g_hLbl_QLV1, $iState)
    GUICtrlSetState($g_hInput_CustomQLV_Edit, $iState)
    GUICtrlSetState($g_hLbl_QLV2, $iState)
    GUICtrlSetState($g_hCombo_QLV_Presets, $iState)
    GUICtrlSetState($g_hButton_SaveQLV, $iState)
    GUICtrlSetState($g_hButton_DeleteQLV, $iState)
EndFunc
; ================= CỘT 2: Ở GIỮA (Cầu, Màn hình TV) =================
Func _CreateGroup_BPT_Totals()
    $g_hGroup_BPTTotals = _CreateStyledGroup("Tổng Số Ván", 370, 35, 300, 60) ; X dời thành 370, W bóp thành 300
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
EndFunc

Func _CreateGroup_HistoryDisplay()
    _CreateStyledGroup("Lịch Sử Kết Quả", 370, 100, 300, 130) ; Đổi tên Group
    Local $yStart = 120, $xStart = 376
    For $iRow = 0 To 5
        For $iCol = 0 To 19
            Local $iIndex = $iCol + ($iRow * 20)
            ; Vẽ 20 cột sát nhau để lọt vừa khung 300px
            $g_aLabel_History[$iIndex] = GUICtrlCreateLabel("-", $xStart + $iCol * 14.3, $yStart + $iRow * 17.2, 13, 15, $SS_CENTER)
            GUICtrlSetFont(-1, 7, 700)
        Next
    Next
EndFunc

Func _CreateGroup_HistoryLog()
    $g_hGroup_ActivityLog = _CreateStyledGroup("Màn Hình TV Screen", 370, 235, 300, 290)
    $g_hEdit_ActivityLog = GUICtrlCreateEdit("", 378, 255, 284, 260, BitOR(0x00200000, 0x0040, 0x0800))
    GUICtrlSetBkColor($g_hEdit_ActivityLog, 0x000000)
    GUICtrlSetColor($g_hEdit_ActivityLog, 0x00FF00)
EndFunc
; ================= CỘT 3: BÊN PHẢI (Mục Tiêu & Control) =================
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

	; Ẩn Tra cứu và Volume
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

	; Đã Sắp Xếp So Le Gọn Gàng
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
	; Dịch toàn bộ cụm này sang trái mạnh (x+10 thay vì x+50)
	$g_hRadio_Action_PauseMin = GUICtrlCreateRadio("Nghỉ", $x + 10, $y, 50, 20)
	$g_hInput_Action_PauseMin = GUICtrlCreateInput("15", $x + 65, $y - 2, 35, 22)
	GUICtrlCreateLabel("phút", $x + 105, $y, 35, 20)

	$g_hRadio_Action_PauseHand = GUICtrlCreateRadio("Nghỉ", $x + 150, $y, 50, 20)
	$g_hInput_Action_PauseHand = GUICtrlCreateInput("5", $x + 205, $y - 2, 35, 22)
	GUICtrlCreateLabel("ván", $x + 245, $y, 25, 20)
EndFunc
Func _CreateGroup_UserConfig_Main()
	_CreateStyledGroup("Điều Khiển Nhanh", 680, 315, 290, 210)
	Local $x = 690, $y = 340

	GUICtrlCreateLabel("Cấu hình:", $x, $y, 60, 20)
	$g_hCombo_Profiles_Main = GUICtrlCreateCombo("", $x + 70, $y - 3, 200, 25, $CBS_DROPDOWNLIST)

	$y += 32
	GUICtrlCreateLabel("Trễ thả chip:", $x, $y, 75, 20)
	$g_hInput_ClickDelay_Main = GUICtrlCreateInput("150", $x + 75, $y-2, 40, 22)
	GUICtrlCreateLabel("ms", $x + 120, $y, 20, 20)
	GUICtrlSetTip($g_hInput_ClickDelay_Main, "Tăng số này (vd 150-300) nếu game nhận rớt phỉnh")

	GUICtrlCreateLabel("Tốc độ rê:", $x + 150, $y, 70, 20)
	$g_hInput_MouseSpeed = GUICtrlCreateInput("2", $x + 220, $y-2, 40, 22)
	GUICtrlSetTip($g_hInput_MouseSpeed, "0 là tức thì, 10 là chậm. Khuyên dùng 2")

	; Giấu 2 biến radio cũ đi để không gây lỗi logic code
	$g_hRadio_ClickMode_Control_Main = GUICtrlCreateRadio("Nhanh", -999, -999, 10, 10)
	$g_hRadio_ClickMode_Mouse_Main = GUICtrlCreateRadio("Chuột", -999, -999, 10, 10)

$y += 32
	Global $g_hCheckbox_PinTool = GUICtrlCreateCheckbox("📌 Ghim Tool luôn nổi (Chống đè)", $x + 20, $y, 250, 20)
	GUICtrlSetFont(-1, 9, 800)
	GUICtrlSetColor(-1, 0xFF00FF)
	GUICtrlSetState(-1, $GUI_UNCHECKED) ; <--- SỬA TẠI ĐÂY: Đổi $GUI_CHECKED thành $GUI_UNCHECKED

	$y += 32
	$g_hButton_Start = GUICtrlCreateButton("ĐĂNG NHẬP", $x + 30, $y, 210, 60)
	GUICtrlSetFont(-1, 13, 800)
	GUICtrlSetBkColor(-1, 0x33CC33)
EndFunc
Func _CreateTab_ConfigHelper()
	Global $g_hButton_Unlock = GUICtrlCreateButton("🔐 MỞ KHÓA", 820, 35, 140, 30)
	GUICtrlSetFont(-1, 10, 800)
	GUICtrlSetBkColor(-1, 0xFF4141)
	GUICtrlSetColor(-1, 0xFFFFFF)

	Global $g_iTechTabStart = GUICtrlCreateDummy()

	; ================= THÊM LẠI THANH QUÉT TỌA ĐỘ VÀ NÚT BẬT PHÍM ` =================
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
	; ==============================================================================

	; ================= CỘT TRÁI (Tọa độ Game) =================
	_CreateStyledGroup("Thiết Lập Tọa Độ Baccarat", 10, 70, 480, 275)
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
	Global $g_hButton_SaveNewProfile = GUICtrlCreateButton("💾 Lưu Sảnh Mới", $x_prof + 190, $y_prof - 4, 140, 26)
	GUICtrlSetBkColor(-1, 0x0082FA)
	GUICtrlSetColor(-1, 0xFFFFFF)
	Global $g_hButton_DeleteProfile = GUICtrlCreateButton("❌ Xóa Sảnh", $x_prof + 340, $y_prof - 4, 100, 26)
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

	Global $g_iTechTabEnd = GUICtrlCreateDummy()
EndFunc
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

	; Đã xóa đoạn lệnh Ẩn/Hiện nút cũ ở đây vì bây giờ chúng ta dùng chung 1 nút duy nhất.
	; Nút sẽ luôn hiện thị và tự đổi chữ/đổi màu.
EndFunc

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

            ; KIỂM TRA XEM CÓ ĐANG BẬT XÓC ĐĨA VIP KHÔNG
            Local $bIsXocDia = (GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED)

			If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColB, $iTolerance, 1, $hWnd)) Then
				$bFound = True
				$sMsgSuccess = "OK! Tìm thấy: " & ($bIsXocDia ? "CHẴN (ĐỎ)" : "BANKER")
			ElseIf IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColP, $iTolerance, 1, $hWnd)) Then
				$bFound = True
				$sMsgSuccess = "OK! Tìm thấy: " & ($bIsXocDia ? "LẺ (XANH)" : "PLAYER")
			ElseIf Not $bIsXocDia And IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColT, $iTolerance, 1, $hWnd)) Then
                ; CHỈ QUÉT HÒA NẾU KHÔNG PHẢI XÓC ĐĨA
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

	Local $sProfileList = "|"

	For $i = 1 To $aSectionNames[0]
		If StringLeft($aSectionNames[$i], 8) = "Profile_" Then
			Local $sProfileName = StringTrimLeft($aSectionNames[$i], 8)
			$sProfileList &= $sProfileName & "|"
		EndIf
	Next

	If $sProfileList <> "|" Then
		$sProfileList = StringTrimRight($sProfileList, 1)
	EndIf

	Local $sCurrentMain = GUICtrlRead($g_hCombo_Profiles_Main)
	Local $sCurrentConf = GUICtrlRead($g_hCombo_Profiles)

	GUICtrlSetData($g_hCombo_Profiles_Main, $sProfileList, $sCurrentMain)
	GUICtrlSetData($g_hCombo_Profiles, $sProfileList, $sCurrentConf)
EndFunc   ;==>_PopulateProfileList
Func _HandleProfileChange($hTriggeredCombo)
	Local $sNewProfile = GUICtrlRead($hTriggeredCombo)
	; Chống chạy lặp lại nếu đang ở đúng sảnh đó
	If $sNewProfile = "" Or $sNewProfile = $g_sCurrentLoadedProfile Then Return

	; 1. BẢO VỆ DỮ LIỆU SẢNH CŨ (Bắt buộc dùng tham số True để lưu ngầm an toàn)
	If $g_sCurrentLoadedProfile <> "" Then
		_MasterSave($g_sCurrentLoadedProfile, True)
	EndIf

	; 2. ĐỒNG BỘ HIỂN THỊ 2 MENU XỔ XUỐNG (Từ code cũ của bạn)
	If $hTriggeredCombo = $g_hCombo_Profiles Then
		GUICtrlSetData($g_hCombo_Profiles_Main, $sNewProfile)
	Else
		GUICtrlSetData($g_hCombo_Profiles, $sNewProfile)
	EndIf

	; 3. NẠP DỮ LIỆU SẢNH MỚI
	_LoadSelectedProfile($sNewProfile)

	; 4. KHÔI PHỤC CÁC LỆNH BỔ TRỢ CỦA BẠN
	; Cập nhật tên vào ô Input (nếu trên UI của bạn có ô này)
	GUICtrlSetData($g_hInput_ProfileName, $sNewProfile)

	; Quét lại toàn bộ thông số tiền nong, chốt lời lỗ để tool sẵn sàng
	_GetAndValidateInputs()

	; Cập nhật lại biến nhớ
	$g_sCurrentLoadedProfile = $sNewProfile

	; 5. HIỂN THỊ THÔNG BÁO CHI TIẾT (Từ code cũ của bạn)
	Local $sTP = GUICtrlRead($g_hInput_TakeProfit)
	Local $sSL = GUICtrlRead($g_hInput_StopLoss)
	_UpdateStatus("✅ Đã chuyển: [" & $sNewProfile & "] | Lãi " & $sTP & " / Lỗ " & $sSL)
EndFunc   ;==>_HandleProfileChange
Func _CreateDefaultIniFile()
	; 1. ÉP TẠO FILE INI CHUẨN UNICODE (Mã số 32 = UTF-16 LE) ĐỂ LƯU TIẾNG VIỆT CÓ DẤU
	Local $hFile = FileOpen($g_sIniPath, 2 + 32)
	FileWrite($hFile, "")
	FileClose($hFile)

	; 2. LƯU CẤU HÌNH VỚI TÊN TIẾNG VIỆT CHUẨN: "Sảnh PP Mẫu"
	_SaveSettings()
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "WindowClass", "Chrome_WidgetWin_1")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BankerX", "1144")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BankerY", "847")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "PlayerX", "751")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "PlayerY", "836")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ResultX1", "773")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ResultY1", "211")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ResultX2", "1140")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ResultY2", "475")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BankerColor", "0xFB0202")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "PlayerColor", "0x0184FE")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "TieColor", "0x007722")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BetTimeX1", "96")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BetTimeY1", "545")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BetTimeX2", "1819")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BetTimeY2", "567")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "BetTimeColor", "0x2CC937")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ClickMode", "Mouse")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ClickDelay", "50")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipEnabled_0", "1")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipValue_0", "500.000")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipX_0", "988")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipY_0", "1009")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipEnabled_1", "1")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipValue_1", "100.000")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipX_1", "933")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipY_1", "1007")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipEnabled_2", "1")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipValue_2", "40.000")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipX_2", "865")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipY_2", "1013")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipEnabled_3", "1")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipValue_3", "20.000")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipX_3", "807")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipY_3", "1008")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipEnabled_4", "1")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipValue_4", "4.000")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipX_4", "747")
	IniWrite($g_sIniPath, "Profile_Sảnh PP Mẫu", "ChipY_4", "1002")

	; Cập nhật bộ nhớ UI
	IniWrite($g_sIniPath, "UISettings", "LastProfile", "Sảnh PP Mẫu")
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
; ĐỌC VÀ PHỤC HỒI TRẠNG THÁI CHẠM MỐC NGHỈ/DỪNG
	Local $sCurrentProfile = GUICtrlRead($g_hCombo_Profiles_Main)
	If $sCurrentProfile == "" Then $sCurrentProfile = "Settings"

	GUICtrlSetState($g_hRadio_Action_Stop, IniRead($g_sIniPath, "Profile_" & $sCurrentProfile, "ActionStop", $GUI_CHECKED))
	GUICtrlSetState($g_hRadio_Action_PauseMin, IniRead($g_sIniPath, "Profile_" & $sCurrentProfile, "ActionPauseMin", $GUI_UNCHECKED))
	GUICtrlSetState($g_hRadio_Action_PauseHand, IniRead($g_sIniPath, "Profile_" & $sCurrentProfile, "ActionPauseHand", $GUI_UNCHECKED))
	GUICtrlSetData($g_hInput_Action_PauseMin, IniRead($g_sIniPath, "Profile_" & $sCurrentProfile, "PauseMinVal", "15"))
	GUICtrlSetData($g_hInput_Action_PauseHand, IniRead($g_sIniPath, "Profile_" & $sCurrentProfile, "PauseHandVal", "5"))

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
		; 1. Cố gắng đọc trí nhớ từ chuẩn mới (Settings)
		$sProfileToUse = IniRead($g_sIniPath, "Settings", "LastProfile", "")

		; 2. Nếu chuẩn mới trống trơn, tự động lùi về chuẩn cũ (UISettings) để khôi phục dữ liệu cho sếp
		If $sProfileToUse == "" Then
			$sProfileToUse = IniRead($g_sIniPath, "UISettings", "LastProfile", "")
		EndIf
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
	_PopulateFormulaLibrary()
EndFunc   ;==>_LoadSettings

Func _StartProcess()
	; ---> ÉP ĐỒNG BỘ SỐ DƯ & CÀI ĐẶT TRƯỚC KHI CHẠY <---
	If Not _GetAndValidateInputs() Then
		Return ; Dừng ngay không cho chạy nếu sếp lỡ nhập cược = 0 hoặc lỗi
	EndIf

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
	$g_iTableProfit_Units = 0

	_RedrawHistory()
	_UpdateBPTTotalsLabels()
	_UpdateTotalHandsLabel()

	Local $hGameWin = $g_hTargetGameWin
	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		$hGameWin = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hGameWin
	EndIf

	Local $bIsMultiTable = False
	If IsDeclared("g_hCheckbox_DuKichDaBan") Then
		If GUICtrlRead($g_hCheckbox_DuKichDaBan) == $GUI_CHECKED Then $bIsMultiTable = True
	EndIf

	; =========================================================================
	; [CHẾ ĐỘ 1]: CHẠY TUẦN TỰ 12 BÀN (DÙNG LASER VÀ SĂN BÀN MỚI)
	; =========================================================================
	If $bIsMultiTable Then
		$g_iCurrentTableIndex = 0
		$g_fTableProfit_RealUnits = 0.0

		If IsDeclared("g_hCheckbox_SanBanMoi") And GUICtrlRead($g_hCheckbox_SanBanMoi) == $GUI_CHECKED Then
			_HuntForNewShoeTable()
		Else
			_CalculateAndSetTableCoords(0)
			_UpdateStatus("🚀 BẮT ĐẦU DU KÍCH: Khóa mục tiêu Bàn 1...")
		EndIf

		While $g_bIsRunning
			_ProcessGUIMessages()
			If _CheckProfitLossTargets() Then ExitLoop

			Local $fTargetWinUnits = Number(GUICtrlRead($g_hInput_DuKich_WinTable))
			Local $fTargetLossUnits = -1 * Number(GUICtrlRead($g_hInput_DuKich_LossTable))

			If $g_fTableProfit_RealUnits >= $fTargetWinUnits Or $g_fTableProfit_RealUnits <= $fTargetLossUnits Then
				Local $sReason = ($g_fTableProfit_RealUnits >= $fTargetWinUnits) ? "CHỐT LỜI" : "CẮT LỖ"
				_UpdateStatus("🔄 " & $sReason & " Bàn " & ($g_iCurrentTableIndex + 1) & " (Đạt " & $g_fTableProfit_RealUnits & " Lót thực). Nhảy bàn...")

				If IsDeclared("g_hCheckbox_SanBanMoi") And GUICtrlRead($g_hCheckbox_SanBanMoi) == $GUI_CHECKED Then
					_HuntForNewShoeTable()
				Else
					$g_iCurrentTableIndex += 1
					If $g_iCurrentTableIndex > 11 Then
						Local $iRestMins = Number(GUICtrlRead($g_hInput_DuKich_RestTime))
						_UpdateStatus("💤 Đã hoàn tất 12 bàn! Tool ngủ đông " & $iRestMins & " phút...")
						Sleep($iRestMins * 60000)
						$g_iCurrentTableIndex = 0
						_UpdateStatus("🚀 Hết giờ nghỉ! Tái khởi động vòng 12 bàn mới...")
					EndIf
					_CalculateAndSetTableCoords($g_iCurrentTableIndex)

					ReDim $g_aDisplayHistory[0]
					$g_iHistoryCutoffIndex = 0
					$g_iCapitalLevel = 0
					$g_iLastActiveRuleIndex = -1
					$g_fTableProfit_RealUnits = 0.0
					_RedrawHistory()
				EndIf
				ContinueLoop
			EndIf

			Local $sNewResult = _WaitPopupAppear_Laser()
			If $sNewResult == "" Then ContinueLoop
			_UpdateStatus("⚡ Vừa ra: [" & $sNewResult & "]. Đang tính toán...")

			If $g_sLastBetOn <> "" Then
				_ProcessBetOutcome($sNewResult, $g_sLastBetOn)
				$g_sLastBetOn = ""
			Else
				_ProcessObservation($sNewResult)
			EndIf

			Local $aAction = _DecideNextAction()

			If $aAction[0] == "BET" Then
				Local $sBetOn = $aAction[1]
				$g_fCurrentBet = $g_fInitialBet * $aAction[2]

				_UpdateStatus("🔥 Lệnh " & $g_iCapitalLevel & ": Chuẩn bị đánh " & $sBetOn & ". Đợi đèn xanh...")
				Local $bTimerFound = False
				Local $iWaitTimer = TimerInit()
				While $g_bIsRunning
					If _IsBetTimeOpen() Then
						$bTimerFound = True
						ExitLoop
					EndIf
					_ProcessGUIMessages()
					Sleep(10)
					If TimerDiff($iWaitTimer) > 25000 Then ExitLoop
				WEnd

				If $g_bIsRunning And $bTimerFound Then
					_PerformBet($sBetOn, $g_fCurrentBet)
					_UpdateStatus("✅ Đã đặt cược! Đang chờ kết quả...")
				Else
					_UpdateStatus("⛔ Bỏ lỡ ván: Hết giờ cược.")
				EndIf
			Else
				_WaitPopupDisappear_Laser()
			EndIf
		WEnd
		_StopProcess()
		Return ; Xong chế độ Du kích là thoát luôn, không chạy xuống dưới
	EndIf

; =========================================================================
	; [CHẾ ĐỘ 2]: XÓC ĐĨA VIP - QUÉT POPUP LASER (Đã fix truyền sai tiền & dịch C/L)
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_UpdateStatus("🚀 XÓC ĐĨA VIP: Khóa tia Laser vào giữa màn hình chờ Popup...")
		While $g_bIsRunning
			_ProcessGUIMessages()
			If _CheckProfitLossTargets() Then ExitLoop

			Local $sNewResult = _WaitPopupAppear_Laser()
			If $sNewResult == "" Then ContinueLoop

			; DỊCH TÍN HIỆU TỪ B/P SANG C/L ĐỂ ĐỒNG BỘ GIAO DIỆN XÓC ĐĨA
			If $sNewResult == "B" Then $sNewResult = "C"
			If $sNewResult == "P" Then $sNewResult = "L"
			If $sNewResult == "T" Then ContinueLoop ; Xóc đĩa không lấy hòa

			_UpdateStatus("⚡ Tia Laser chộp được: [" & $sNewResult & "]. Đang phân tích 5 Hàng...")

			If $g_sLastBetOn <> "" Then
				_ProcessBetOutcome($sNewResult, $g_sLastBetOn)
				$g_sLastBetOn = ""
			Else
				_ProcessObservation($sNewResult)
			EndIf

			Local $aAction = _DecideNextAction()
			If $aAction[0] == "BET" Then
				Local $sBetOn = $aAction[1]
				$g_fCurrentBet = $aAction[2] ; CHỈ LẤY ĐÚNG SỐ TIỀN THỰC TẾ TỪ BẢNG NỢ, KHÔNG NHÂN THÊM GÌ NỮA!

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
					_PerformBet($sBetOn, $g_fCurrentBet)
				Else
					_UpdateStatus("⛔ Bỏ lỡ ván: Hết giờ cược.")
				EndIf
			EndIf

			_WaitPopupDisappear_Laser()
		WEnd
		_StopProcess()
		Return ; Xong chế độ Xóc đĩa là thoát, không chạy Baccarat
	EndIf
	; =========================================================================
	; [CHẾ ĐỘ 3]: BACCARAT QUÉT POPUP LASER (BỎ BẢNG KHỐI)
	; =========================================================================
	If IsDeclared("g_hCheckbox_BaccaratLaser") And GUICtrlRead($g_hCheckbox_BaccaratLaser) == $GUI_CHECKED Then
		_UpdateStatus("🚀 BACCARAT: Khóa tia Laser rình Popup KQ...")
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
				$g_fCurrentBet = $g_fInitialBet * $iBetUnits ; Lệnh này là cược Unit (Lót) nên phải nhân tiền
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
		Return ; Xong Baccarat Laser là thoát, không chạy bảng khối
	EndIf

	; =========================================================================
	; [CHẾ ĐỘ 4 - MẶC ĐỊNH CŨ]: CHẠY 1 BÀN (QUÉT BẢNG KHỐI VẠN NĂNG)
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
	$g_fXD_CycleProfit = 0
	For $i = 0 To UBound($g_aRuleLevels) - 1
		$g_aRuleLevels[$i] = 0
	Next

	; --- FIX: RESET BẢNG LED XÓC ĐĨA VIP VỀ MẶC ĐỊNH KHI DỪNG TOOL ---
	For $i = 1 To 10
		$g_aTierStep[$i] = 1 ; Reset nợ của toàn bộ 10 hàng về Bước 1
	Next
	$g_iCurrentTier = 1 ; Đưa vị trí đánh về lại Hàng 1

	; Gọi lại hàm vẽ UI để nó quét lại mảng và tô màu xám toàn bộ
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_UpdateXocDiaGridUI()
	EndIf

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

	; --- FIX: RESET BẢNG LED XÓC ĐĨA VIP VỀ MẶC ĐỊNH KHI DỪNG TOOL ---
	For $i = 1 To 10
		$g_aTierStep[$i] = 1 ; Reset nợ của toàn bộ 10 hàng về Bước 1
	Next
	$g_iCurrentTier = 1 ; Đưa vị trí đánh về lại Hàng 1

	; Gọi lại hàm vẽ UI để nó quét lại mảng và tô màu xám toàn bộ
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_UpdateXocDiaGridUI()
	EndIf

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
	If $g_iSkipSignalsCount_DuKich > 0 Then $g_iSkipSignalsCount_DuKich -= 1

	; Trừ dần số ván giải lao
	If $g_iTargetPauseHands > 0 Then
		$g_iTargetPauseHands -= 1
		If $g_iTargetPauseHands == 0 Then
			_UpdateStatus("✅ Đã trôi đủ ván nghỉ! Bắt đầu dò cầu chiến tiếp.")
		Else
			_UpdateStatus("⏳ Đang nghỉ giải lao... Chờ trôi thêm " & $g_iTargetPauseHands & " ván.")
		EndIf
	EndIf
	$g_iSkipSignalsCount_DuKich -= 1
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
	Local $iLastBetUnits = $aQLV[1]

	; =========================================================================
	; 1. XỬ LÝ KẾT QUẢ CHO XÓC ĐĨA VIP
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_ProcessOutcome_XocDia_VIP($sActualResult, $sBetOn)

		; Tính toán lợi nhuận/thua lỗ cho Xóc Đĩa VIP
		If $sActualResult == $sBetOn Then
			$g_fTotalProfit += ($g_fCurrentBet * 0.95) ; Thay đổi tỷ lệ phế tùy theo sảnh
			$fProfitChange = ($g_fCurrentBet * 0.95)
		Else
			$g_fTotalProfit -= $g_fCurrentBet
			$fProfitChange = -$g_fCurrentBet
		EndIf

		; Cập nhật thống kê và kết thúc luồng xử lý Xóc Đĩa VIP
		_UpdateProfitLabel()
		_UpdateBalanceLabel()
		_RedrawHistory()
		If $g_bIsRealBetting Then _UpdateDailyStats($g_fCurrentBet, $fProfitChange)
		_SyncLiveDashboard($g_fInitialCapital + $g_fTotalProfit, $g_fTotalProfit, Number(IniRead(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), "0")))
		Return ; Bắt buộc phải có Return để thoát khỏi hàm, không chạy xuống logic Baccarat
	EndIf

	; =========================================================================
	; 2. XỬ LÝ KẾT QUẢ CHO BACCARAT (Giữ nguyên logic cũ)
	; =========================================================================
	If $sActualResult = $sBetOn Then
		; --- ĐẾM LÓT THỰC TẾ (CÓ TRỪ PHẾ NHÀ CÁI 5%) ---
		If $sActualResult = "B" Then
			$g_fTableProfit_RealUnits += ($iLastBetUnits * 0.95) ; Thắng Banker ăn 0.95 lót
		Else
			$g_fTableProfit_RealUnits += $iLastBetUnits          ; Thắng Player ăn 1 lót
		EndIf

		$g_iCycleProfit_Units += $iLastBetUnits
		$g_iTableProfit_Units += $iLastBetUnits

		If Not $g_bIsRealBetting Then
			$g_iVirtualLosses = 0
			_UpdateStatus("🛡️ ĐÁNH NHÁP: Thắng ảo! Cầu chưa sập...")
		Else
			If $sActualResult = "B" Then
				$g_fTotalProfit += ($g_fCurrentBet * 0.95)
				$fProfitChange = ($g_fCurrentBet * 0.95)
			Else
				$g_fTotalProfit += $g_fCurrentBet
				$fProfitChange = $g_fCurrentBet
			EndIf

			If $g_fTotalProfit > $g_fPeakProfit Then $g_fPeakProfit = $g_fTotalProfit
			_UpdateStrategyStats(1)
		EndIf

		If $bReverseLogic Then
			If $g_iLastActiveRuleIndex > -1 Then $g_iCustomSeqStep += 1
			$g_iCapitalLevel = $aQLV[2]
			_UpdateStatus("WIN! (Bám Chuỗi) -> Lên Lv " & $aQLV[2])
		Else
			$g_iLastActiveRuleIndex = -1
			$g_iCustomSeqStep = 0
			$g_iCapitalLevel = $aQLV[2]
			If GUICtrlRead($g_hCheckbox_ContinuousMode) <> $GUI_CHECKED Then
				$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
				_UpdateStatus("WIN! -> Cắt cầu -> Chờ tín hiệu mới.")
			EndIf
		EndIf
	Else
		; --- THUA TRỪ ĐỦ 1 LÓT ---
		$g_fTableProfit_RealUnits -= $iLastBetUnits

		$g_iCycleProfit_Units -= $iLastBetUnits
		$g_iTableProfit_Units -= $iLastBetUnits

		If Not $g_bIsRealBetting Then
			$g_iVirtualLosses += 1
			If $g_iVirtualLosses >= 3 Then
				$g_bIsRealBetting = True
				$g_iVirtualLosses = 0
				$g_iCapitalLevel = 0
				If $bSepQLV And $iSavedActiveIndex > -1 Then $g_aRuleLevels[$iSavedActiveIndex] = 0
				_UpdateStatus("🔥 NHÁP GÃY 3 LẦN -> VÀO TIỀN THẬT!")
			EndIf
		Else
			$g_fTotalProfit -= $g_fCurrentBet
			$fProfitChange = -$g_fCurrentBet
			_UpdateStrategyStats(0)
		EndIf

		If $bReverseLogic Then
			$g_iLastActiveRuleIndex = -1
			$g_iCustomSeqStep = 0
			$g_iCapitalLevel = $aQLV[3]
			$g_iHistoryCutoffIndex = UBound($g_aDisplayHistory)
			_UpdateStatus("LOSS! (Bám Chuỗi) -> Cắt cầu -> Về Lv " & $aQLV[3])
		Else
			If $g_iLastActiveRuleIndex > -1 Then $g_iCustomSeqStep += 1
			$g_iCapitalLevel = $aQLV[3]
			If $g_bIsRealBetting Then _UpdateStatus("LOSS! -> Lên Lv " & $aQLV[3])
		EndIf
	EndIf

	If $bSepQLV And $iSavedActiveIndex > -1 Then
		$g_aRuleLevels[$iSavedActiveIndex] = $g_iCapitalLevel
	EndIf

	_UpdateProfitLabel()
	_UpdateBalanceLabel()
	_RedrawHistory()

	If $g_bIsRealBetting Then _UpdateDailyStats($g_fCurrentBet, $fProfitChange)
	_SyncLiveDashboard($g_fInitialCapital + $g_fTotalProfit, $g_fTotalProfit, Number(IniRead(@ScriptDir & "\volume_history.ini", "Daily", _GetGamingDate(), "0")))
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
		Case "B", "D", "C"  ; Nếu kết quả là Banker (B) hoặc Đỏ (D) hoặc Chẵn (C)
			$g_iTotalBanker += 1
		Case "P", "V", "L"  ; Nếu kết quả là Player (P) hoặc Vàng (V) hoặc Lẻ (L)
			$g_iTotalPlayer += 1
		Case "T"            ; Hòa thì giữ nguyên
			$g_iTotalTie += 1
	EndSwitch
	_UpdateBPTTotalsLabels()
EndFunc   ;==>_UpdateBPTTotals
Func _UpdateBPTTotalsLabels()
	GUICtrlSetData($g_hLabel_TotalB_Val, $g_iTotalBanker)
	GUICtrlSetData($g_hLabel_TotalP_Val, $g_iTotalPlayer)
	GUICtrlSetData($g_hLabel_TotalT_Val, $g_iTotalTie)
EndFunc   ;==>_UpdateBPTTotalsLabels

Func _PerformBet($sBetOn, ByRef $fAmountToBet)
	If Not $g_bIsRunning Then Return False
	If _CheckProfitLossTargets() Then Return False

	_UpdateStatus("💸 [AUTO CLICK] Bắt đầu rải chip cược [" & $sBetOn & "] (Mức tiền: " & _FormatNumber($fAmountToBet) & " đ)...")

	Local $hGameWin = $g_hTargetGameWin
	If $hGameWin = 0 Or Not WinExists($hGameWin) Then
		$hGameWin = _GetRealGameWindow(GUICtrlRead($g_hInput_WindowClass))
		$g_hTargetGameWin = $hGameWin ; Lưu lại luôn cho chắc
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

	; CHỜ BÀN MỞ HẲN
	Sleep(800)

	Local $iBaseDelay = Number(GUICtrlRead($g_hInput_ClickDelay_Main))
	If $iBaseDelay < 150 Then $iBaseDelay = 150

	; Dịch tọa độ Vùng Cược sang tọa độ ngầm
	Local $tTarget = DllStructCreate("long X;long Y")
	DllStructSetData($tTarget, "X", $aBetAreaPos[0])
	DllStructSetData($tTarget, "Y", $aBetAreaPos[1])
	_WinAPI_ScreenToClient($hGameWin, $tTarget)
	Local $iTargetClientX = DllStructGetData($tTarget, "X")
	Local $iTargetClientY = DllStructGetData($tTarget, "Y")

	For $i = 0 To $iTotalSteps - 1
		; Dịch tọa độ Chip sang tọa độ ngầm
		Local $tChip = DllStructCreate("long X;long Y")
		DllStructSetData($tChip, "X", $aClickQueue[$i][0])
		DllStructSetData($tChip, "Y", $aClickQueue[$i][1])
		_WinAPI_ScreenToClient($hGameWin, $tChip)
		Local $iChipClientX = DllStructGetData($tChip, "X")
		Local $iChipClientY = DllStructGetData($tChip, "Y")

		Local $iCount = $aClickQueue[$i][2]

		; =========================================================
		; 1. LẤY CHIP BẰNG CHUỘT ẢO (Nhấp đúp ngầm)
		; =========================================================
		ControlClick($hGameWin, "", "", "left", 2, $iChipClientX, $iChipClientY)
		Sleep(300) ; Chờ Web game sáng phỉnh

		; =========================================================
		; 2. VÀO TIỀN BẰNG CHUỘT ẢO (Xả đạn ngầm)
		; =========================================================
		For $j = 1 To $iCount
			If Not $g_bIsRunning Then Return False
			ControlClick($hGameWin, "", "", "left", 1, $iTargetClientX, $iTargetClientY)
			Sleep($iBaseDelay)
		Next
	Next

	Return True
EndFunc
Func _SingleClick($hWnd, $iX, $iY, $iRadius = 0)
    If $iX <= 0 Or $iY <= 0 Then Return False
    If $hWnd = 0 Or Not WinExists($hWnd) Then Return False

    ; Dịch tọa độ sang tọa độ ngầm
    Local $tPoint = DllStructCreate("long X;long Y")
    DllStructSetData($tPoint, "X", $iX)
    DllStructSetData($tPoint, "Y", $iY)
    _WinAPI_ScreenToClient($hWnd, $tPoint)
    Local $iClientX = DllStructGetData($tPoint, "X")
    Local $iClientY = DllStructGetData($tPoint, "Y")

    ; Bơm lệnh JavaScript Click thẳng vào phần tử tại tọa độ (Chuẩn xác tuyệt đối)
    If $g_sSession <> "" Then
        Local $sJS = "var el = document.elementFromPoint(" & $iClientX & ", " & $iClientY & "); if(el) el.click();"
        _WD_ExecuteScript($g_sSession, $sJS)
    Else
        ; Dự phòng nếu WebDriver bị lỗi thì xài lại ControlClick
        ControlClick($hWnd, "", "", "left", 1, $iClientX, $iClientY)
    EndIf

    Sleep(20)
    Return True
EndFunc
Func _CalculateOptimalClicks(ByRef $fTargetAmount)
	Local $aActiveChips[1][3] ; [Value, X, Y]
	Local $iActiveCount = 0

	; BƯỚC 1: Tạo biến để lưu tổng số tiền thực tế đếm được từ các con chip
	Local $fActualCalculated = 0

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

			; BƯỚC 2: CỘNG DỒN SỐ TIỀN THỰC TẾ (Số lượng chip * Mệnh giá)
			$fActualCalculated += ($iCount * $fVal)

			$fRemaining = Mod($fRemaining, $fVal)
		EndIf
	Next

	If $fRemaining > 0 Then
		_UpdateStatus("Lẻ " & _FormatNumber($fRemaining) & " (Không đủ chip nhỏ hơn).")
	EndIf

	; BƯỚC 3: CHỐT SỔ CỰC KỲ QUAN TRỌNG!
	; Ép con số tiền cược ban đầu (có thể bị lẻ) trở thành số tiền thực tế (chẵn phỉnh)
	$fTargetAmount = $fActualCalculated

	Return $aClicksQueue
EndFunc   ;==>_CalculateOptimalClicks
Func _ScanAreaForResult()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

	Local $sBoard = _ScanUniversalBeadPlate()

	If $g_sLastLLBoard == "" Then
		$g_sLastLLBoard = $sBoard
		Return ""
	EndIf

	If $sBoard <> $g_sLastLLBoard Then
		Local $iLenNew = StringLen($sBoard)
		Local $iLenOld = StringLen($g_sLastLLBoard)

		If $iLenNew < ($iLenOld - 5) Then
			$g_sLastLLBoard = $sBoard
			$g_iCapitalLevel = 0
			$g_iCustomSeqStep = 0
			_UpdateStatus("🔄 Dealer đã đổi hộp bài mới! Reset chu kỳ.")
			Return ""
		EndIf

		If $iLenNew < $iLenOld Then Return ""

		Local $sNewChar = StringRight($sBoard, 1)
		$g_sLastLLBoard = $sBoard
		Return $sNewChar
	EndIf

	Return ""
EndFunc   ;==>_ScanAreaForResult
Func _GetAndValidateInputs()
	$g_sGameWindowClass = GUICtrlRead($g_hInput_WindowClass)

	; --- Tọa độ Nút Bấm ---
	$g_aBankerButtonPos[0] = Number(GUICtrlRead($g_hInput_BankerX))
	$g_aBankerButtonPos[1] = Number(GUICtrlRead($g_hInput_BankerY))
	$g_aPlayerButtonPos[0] = Number(GUICtrlRead($g_hInput_PlayerX))
	$g_aPlayerButtonPos[1] = Number(GUICtrlRead($g_hInput_PlayerY))
	$g_aTieButtonPos[0] = Number(GUICtrlRead($g_hInput_TieX)) ; <--- Thêm
	$g_aTieButtonPos[1] = Number(GUICtrlRead($g_hInput_TieY)) ; <--- Thêm
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
	Local $bHitTarget = False
	Local $sReason = ""

	; Chỉ kiểm tra nếu tích bật Mục Tiêu
	If GUICtrlRead($g_hCheckbox_DailyShield) == $GUI_CHECKED Then

		; SỬA LỖI 1: Lấy Lãi/Lỗ của PHIÊN HIỆN TẠI (Thay vì lấy Tổng Lãi Ngày gây lỗi khóa chéo)
		Local $fCurrentProfit = $g_fTotalProfit

		; Cập nhật Đỉnh Lãi Phiên liên tục (Dùng cho Kéo Đuôi)
		If $fCurrentProfit > $g_fPeakProfit Then $g_fPeakProfit = $fCurrentProfit

		Local $fTarget = Number(StringRegExpReplace(GUICtrlRead($g_hInput_DailyTarget), "\D", ""))
		Local $fTrailing = Number(StringRegExpReplace(GUICtrlRead($g_hInput_DailyTrailing), "\D", ""))
		Local $fStopLoss = -1 * Abs(Number(StringRegExpReplace(GUICtrlRead($g_hInput_DailyStopLoss), "\D", "")))

		; A. Kiểm tra Cắt Lỗ (Chạm là cắt ngay)
		If $fStopLoss < 0 And $fCurrentProfit <= $fStopLoss Then
			$bHitTarget = True
			$sReason = "CHẠM MỨC CẮT LỖ PHIÊN (Âm " & _FormatNumber($fCurrentProfit) & ")"
		EndIf

		; B. Kiểm tra Chốt Lời
		If $fTarget > 0 Then
			; TRƯỜNG HỢP 1: CÓ KÉO ĐUÔI (Trailing > 0) -> Gồng lãi
			If $fTrailing > 0 Then
				If $fCurrentProfit >= $fTarget Or $g_bIsTrailingMode Then
					$g_bIsTrailingMode = True
					Local $fDynTrail = $fTrailing

					; Bóp đuôi nếu ăn x2 mục tiêu
					If $g_fPeakProfit >= ($fTarget * 2) Then $fDynTrail = $fTrailing / 2

					; Chốt khi lợi nhuận tụt từ đỉnh xuống bằng đúng khoảng Kéo Đuôi
					If $fCurrentProfit <= ($g_fPeakProfit - $fDynTrail) Then
						$bHitTarget = True
						$sReason = "CHỐT LÃI KÉO ĐUÔI (Đỉnh: " & _FormatNumber($g_fPeakProfit) & " đ, Tụt mất: " & _FormatNumber($fDynTrail) & " đ)"
					EndIf
				EndIf

			; SỬA LỖI 2 - TRƯỜNG HỢP 2: KHÔNG KÉO ĐUÔI -> CHẠM MỐC LÀ CHỐT CỨNG NGAY LẬP TỨC
			Else
				If $fCurrentProfit >= $fTarget Then
					$bHitTarget = True
					$sReason = "ĐẠT MỤC TIÊU CHỐT LÃI PHIÊN (+" & _FormatNumber($fCurrentProfit) & " đ)"
				EndIf
			EndIf
		EndIf

		; Xử lý hành động khi chạm mốc (Dừng / Nghỉ)
		If $bHitTarget Then
			_StopAndSaveSession()

			If GUICtrlRead($g_hRadio_Action_Stop) == $GUI_CHECKED Then
				; Ghi cờ khóa hệ thống
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

	; Đảm bảo hiển thị nhãn "Tổng Lãi Hôm Nay" trên UI luôn được cập nhật ngầm
	Local $sFileProfit = @ScriptDir & "\profit_history.ini"
	Local $fNetDay = Number(IniRead($sFileProfit, "Daily", _GetGamingDate(), "0"))
	Local $sColorNet = ($fNetDay >= 0) ? 0x006400 : 0xFF0000
	GUICtrlSetData($g_hLabel_NetDay, "LỢI NHUẬN TỔNG: " & _FormatNumber($fNetDay) & " đ")
	GUICtrlSetColor($g_hLabel_NetDay, $sColorNet)

	Return False
EndFunc
; Hàm hỗ trợ để rút gọn code
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
	For $i = 0 To UBound($g_aRuleLevels) - 1
		$g_aRuleLevels[$i] = 0
	Next
	; --- FIX: RESET BẢNG LED XÓC ĐĨA VIP VỀ MẶC ĐỊNH KHI DỪNG TOOL ---
	For $i = 1 To 10
		$g_aTierStep[$i] = 1 ; Reset nợ của toàn bộ 10 hàng về Bước 1
	Next
	$g_iCurrentTier = 1 ; Đưa vị trí đánh về lại Hàng 1

	; Gọi lại hàm vẽ UI để nó quét lại mảng và tô màu xám toàn bộ
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		_UpdateXocDiaGridUI()
	EndIf
	_UpdateProfitLabel()
	_UpdateBalanceLabel()
EndFunc
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
EndFunc   ;==>_RedrawHistory
Func _StyleResultLabel($hLabel, $sResult, $bHighlight, $bIsLatest)
	GUICtrlSetData($hLabel, $sResult)
	GUICtrlSetFont($hLabel, 7, 700) ; <--- ÉP FONT 7 Ở ĐÂY ĐỂ VỪA Ô NHỎ
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
EndFunc
Func _SetControlsState($bEnable)
	Local $iState = $bEnable ? $GUI_ENABLE : $GUI_DISABLE
	Local $iInputColor = $bEnable ? 0xE0FFFF : 0xE0E0E0
	Local $iWhite = $bEnable ? 0xFFFFFF : 0xE0E0E0
	Local $iYellow = $bEnable ? 0xFFFACD : 0xE0E0E0

	; Khóa Vốn Cược
	GUICtrlSetState($g_hInput_InitialCapital, $iState)
	GUICtrlSetBkColor($g_hInput_InitialCapital, $iInputColor)
	GUICtrlSetState($g_hInput_InitialBet, $iState)
	GUICtrlSetBkColor($g_hInput_InitialBet, $iInputColor)

	; Khóa Phương Pháp Cược
	GUICtrlSetState($g_hCheckbox_SeparateQLV, $iState)
	GUICtrlSetState($g_hCheckbox_ReverseLogic, $iState)
	GUICtrlSetState($g_hInput_CustomRules, $iState)
	GUICtrlSetBkColor($g_hInput_CustomRules, $iYellow)

	; Khóa Bảng QLV
	GUICtrlSetState($g_hInput_CustomQLV_Edit, $iState)
	GUICtrlSetBkColor($g_hInput_CustomQLV_Edit, $bEnable ? 0xF0FFF0 : 0xE0E0E0)
	GUICtrlSetState($g_hCombo_QLV_Presets, $iState)
	GUICtrlSetState($g_hButton_SaveQLV, $iState)
	GUICtrlSetState($g_hButton_DeleteQLV, $iState)

	; Khóa các ô Cấu hình Xóc Đĩa VIP
	GUICtrlSetState($g_hInput_XD_Seq, $iState)
	GUICtrlSetState($g_hInput_XD_MaxRows, $iState)

	GUICtrlSetState($g_hCheckbox_XD_AutoResetDebt, $iState)
GUICtrlSetState($g_hInput_XD_TargetProfit, $iState)
GUICtrlSetState($g_hCheckbox_XD_LowDebtPriority, $iState)

	; Khóa Mục Tiêu & Dừng Nghỉ
	GUICtrlSetState($g_hCheckbox_DailyShield, $iState)
	GUICtrlSetState($g_hInput_DailyTarget, $iState)
	GUICtrlSetState($g_hInput_DailyStopLoss, $iState)
	GUICtrlSetState($g_hInput_DailyTrailing, $iState)
	GUICtrlSetState($g_hRadio_Action_Stop, $iState)
	GUICtrlSetState($g_hRadio_Action_PauseMin, $iState)
	GUICtrlSetState($g_hInput_Action_PauseMin, $iState)
	GUICtrlSetState($g_hRadio_Action_PauseHand, $iState)
	GUICtrlSetState($g_hInput_Action_PauseHand, $iState)

	; Khóa Tùy Chọn & Tab
	GUICtrlSetState($g_hCombo_Profiles_Main, $iState)
	GUICtrlSetState($g_hRadio_ClickMode_Control_Main, $iState)
	GUICtrlSetState($g_hRadio_ClickMode_Mouse_Main, $iState)
	GUICtrlSetState($g_hTabItemConfig, $iState) ; Khóa cấm khách bấm sang tab cấu hình khi tool đang chạy

	If $bEnable Then
		GUICtrlSetData($g_hButton_Start, "ĐĂNG NHẬP")
		GUICtrlSetBkColor($g_hButton_Start, 0x33CC33)
	Else
		GUICtrlSetData($g_hButton_Start, "DỪNG TOOL")
		GUICtrlSetBkColor($g_hButton_Start, 0xFF4141)
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

	; Dùng WinAPI để tách tín hiệu chuẩn 100% trên mọi bản Windows (Khắc phục lỗi BitShift)
	Local $iCmd = _WinAPI_HiWord($wParam)
	Local $iCtrlID = _WinAPI_LoWord($wParam)

	; 768 chính là tín hiệu EN_CHANGE: Bắt tức thì mỗi khi có 1 thay đổi nhỏ nhất trong ô
	If $iCmd = 768 Then
		Switch $iCtrlID
				 ; 1. NHÓM CÁC Ô NHẬP TIỀN (Nhảy dấu chấm ngay khi gõ)
			Case $g_hInput_InitialCapital, $g_hInput_InitialBet, $g_hInput_TakeProfit, $g_hInput_TrailingStop, $g_hInput_StopLoss, _
			     $g_hInput_DailyTarget, $g_hInput_DailyTrailing, $g_hInput_DailyStopLoss, $g_hInput_XD_TargetProfit
				If Not $g_bIsFormatting Then
					$g_bIsFormatting = True
					Local $sText = GUICtrlRead($iCtrlID)

					If $sText <> "" And $sText <> "-" Then
						Local $bIsNegative = (StringLeft($sText, 1) == "-")
						; Lọc lấy đúng số
						Local $sRaw = StringRegExpReplace($sText, "[^0-9]", "")

						If $sRaw <> "" Then
							; Xóa số 0 thừa ở đầu và chèn dấu chấm phân cách hàng ngàn
							$sRaw = StringRegExpReplace($sRaw, "^0+(?!$)", "")
							Local $sNew = StringRegExpReplace($sRaw, '(\d)(?=(\d{3})+(?!\d))', '$1.')
							If $bIsNegative Then $sNew = "-" & $sNew

							; Cập nhật ngay lập tức nếu có thay đổi
							If $sText <> $sNew Then
								GUICtrlSetData($iCtrlID, $sNew)
								; Ép con trỏ nháy chuột nhảy về cuối cùng để gõ tiếp mượt mà
								Local $iLen = StringLen($sNew)
								GUICtrlSendMsg($iCtrlID, 0x00B1, $iLen, $iLen)
							EndIf
						EndIf
					EndIf

                    ; CHÈN DÒNG NÀY ĐỂ KHI GÕ "GIÁ TRỊ CƯỢC", MA TRẬN LED TỰ NHẢY SỐ TỨC THÌ
; Gộp chung cả 3 ô: Giá trị cược, Số hàng, và Chuỗi cược vào sự kiện Live Update
    If $iCtrlID == $g_hInput_InitialBet Or $iCtrlID == $g_hInput_XD_MaxRows Or $iCtrlID == $g_hInput_XD_Seq Then _UpdateXocDiaGridUI()

					$g_bIsFormatting = False

					; Tự động lưu file cấu hình ngầm
					$g_bNeedAutoSave = True
					$g_hAutoSaveTimer = TimerInit()
				EndIf

			; 2. NHÓM CẤU HÌNH KHÁC (Chỉ cần Auto-save, không cần dấu chấm)
Case $g_hInput_XD_Seq, $g_hInput_XD_MaxRows, $g_hInput_XD_Virtual, $g_hInput_CustomRules, $g_hInput_CustomQLV_Edit, _
					$g_hInput_BankerX, $g_hInput_BankerY, $g_hInput_PlayerX, $g_hInput_PlayerY, $g_hInput_TieX, $g_hInput_TieY, _
					$g_hInput_ResultX1, $g_hInput_ResultY1, $g_hInput_ResultX2, $g_hInput_ResultY2, _
					$g_hInput_BankerColor, $g_hInput_PlayerColor, $g_hInput_TieColor, $g_hInput_Shade_Result, _
					$g_hInput_BetTimeColor, $g_hInput_BetTimeX1, $g_hInput_BetTimeY1, $g_hInput_BetTimeX2, $g_hInput_BetTimeY2, $g_hInput_Shade_Timer, _
					$g_hInput_DuKich_WinTable, $g_hInput_DuKich_LossTable, $g_hInput_DuKich_RestTime, $g_hCheckbox_DuKichDaBan, _
					$g_hInput_LimitBtnX, $g_hInput_LimitBtnY, $g_hInput_Limit10_500X, $g_hInput_Limit10_500Y, $g_hInput_Limit20_50KX, $g_hInput_Limit20_50KY, $g_hInput_LimitConfirmX, $g_hInput_LimitConfirmY
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()


					; TẠO CASE RIÊNG CHO CÁC NÚT NGHỈ/DỪNG ĐỂ KHÔNG BỊ LỖI CÚ PHÁP
			Case $g_hRadio_Action_Stop, $g_hRadio_Action_PauseMin, $g_hRadio_Action_PauseHand, $g_hInput_Action_PauseMin, $g_hInput_Action_PauseHand
				$g_bNeedAutoSave = True
				$g_hAutoSaveTimer = TimerInit()


				; Gọi thẳng cập nhật Ma Trận nếu người dùng đang gõ ở ô cấu hình Xóc Đĩa
If $iCtrlID == $g_hInput_XD_Seq Or $iCtrlID == $g_hInput_XD_MaxRows Then _UpdateXocDiaGridUI()
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

	; Chuẩn hóa nội dung để lưu trên 1 dòng an toàn
	Local $sContentToSave = StringReplace($sCurrentContent, @CRLF, "|NL|")

	; Ghi vào file ini
	IniWrite($g_sIniPath, "UserQLV", $sName, $sContentToSave)

	MsgBox(64, "Thành công", "Đã lưu mẫu QLV: '" & $sName & "'.")

	; ---> ĐÃ SỬA LỖI: THÊM DẤU () ĐỂ TOOL KHÔNG BỊ VĂNG <---
	_PopulateQLVList()

	GUICtrlSetData($g_hCombo_QLV_Presets, $sName) ; Tự động chọn mẫu vừa lưu
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

Func _MasterSave($sProfileName, $bIsAutoSave = False)
	If $sProfileName = "" Then Return False
	Local $sSec = "Profile_" & $sProfileName

	; ==========================================
	; --- LƯU CẤU HÌNH DU KÍCH 12 BÀN ---
	IniWrite($g_sIniPath, $sSec, "ChkDuKichDaBan", GUICtrlRead($g_hCheckbox_DuKichDaBan))
	IniWrite($g_sIniPath, $sSec, "ChkSanBanMoi", GUICtrlRead($g_hCheckbox_SanBanMoi))
	IniWrite($g_sIniPath, $sSec, "FirstCellX", GUICtrlRead($g_hInput_FirstCellX))
	IniWrite($g_sIniPath, $sSec, "FirstCellY", GUICtrlRead($g_hInput_FirstCellY))
	IniWrite($g_sIniPath, $sSec, "DuKichWin", GUICtrlRead($g_hInput_DuKich_WinTable))
	IniWrite($g_sIniPath, $sSec, "DuKichLoss", GUICtrlRead($g_hInput_DuKich_LossTable))
	IniWrite($g_sIniPath, $sSec, "DuKichRest", GUICtrlRead($g_hInput_DuKich_RestTime))
	IniWrite($g_sIniPath, $sSec, "ChkBaccaratLaser", GUICtrlRead($g_hCheckbox_BaccaratLaser))
	IniWrite($g_sIniPath, $sSec, "XD_Virtual", GUICtrlRead($g_hCombo_XD_Virtual))

	IniWrite($g_sIniPath, $sSec, "XD_AutoReset", GUICtrlRead($g_hCheckbox_XD_AutoResetDebt))
IniWrite($g_sIniPath, $sSec, "XD_TargetProf", GUICtrlRead($g_hInput_XD_TargetProfit))
IniWrite($g_sIniPath, $sSec, "XD_LowDebt", GUICtrlRead($g_hCheckbox_XD_LowDebtPriority))
; LƯU TRẠNG THÁI CHẠM MỐC NGHỈ/DỪNG
	IniWrite($g_sIniPath, $sSec, "ActionStop", GUICtrlRead($g_hRadio_Action_Stop))
	IniWrite($g_sIniPath, $sSec, "ActionPauseMin", GUICtrlRead($g_hRadio_Action_PauseMin))
	IniWrite($g_sIniPath, $sSec, "ActionPauseHand", GUICtrlRead($g_hRadio_Action_PauseHand))
	IniWrite($g_sIniPath, $sSec, "PauseMinVal", GUICtrlRead($g_hInput_Action_PauseMin))
	IniWrite($g_sIniPath, $sSec, "PauseHandVal", GUICtrlRead($g_hInput_Action_PauseHand))
	; --- LƯU CẤU HÌNH XÓC ĐĨA VIP ---
	IniWrite($g_sIniPath, $sSec, "ChkXocDiaVIP", GUICtrlRead($g_hCheckbox_XocDiaVIP))
	IniWrite($g_sIniPath, $sSec, "XD_Seq", GUICtrlRead($g_hInput_XD_Seq))
	IniWrite($g_sIniPath, $sSec, "XD_MaxRows", GUICtrlRead($g_hInput_XD_MaxRows))
	IniWrite($g_sIniPath, $sSec, "LimitBtnX", GUICtrlRead($g_hInput_LimitBtnX))
	IniWrite($g_sIniPath, $sSec, "LimitBtnY", GUICtrlRead($g_hInput_LimitBtnY))
	IniWrite($g_sIniPath, $sSec, "Limit10_500X", GUICtrlRead($g_hInput_Limit10_500X))
	IniWrite($g_sIniPath, $sSec, "Limit10_500Y", GUICtrlRead($g_hInput_Limit10_500Y))
	IniWrite($g_sIniPath, $sSec, "Limit20_50KX", GUICtrlRead($g_hInput_Limit20_50KX))
	IniWrite($g_sIniPath, $sSec, "Limit20_50KY", GUICtrlRead($g_hInput_Limit20_50KY))
	IniWrite($g_sIniPath, $sSec, "LimitConfirmX", GUICtrlRead($g_hInput_LimitConfirmX))
	IniWrite($g_sIniPath, $sSec, "LimitConfirmY", GUICtrlRead($g_hInput_LimitConfirmY))
	For $i = 0 To 11
		IniWrite($g_sIniPath, $sSec, "AnchorX_" & $i, GUICtrlRead($g_aInput_AnchorX[$i]))
		IniWrite($g_sIniPath, $sSec, "AnchorY_" & $i, GUICtrlRead($g_aInput_AnchorY[$i]))
	Next
IniWrite($g_sIniPath, $sSec, "RadarRedColor", GUICtrlRead($g_hInput_RadarRed))
	IniWrite($g_sIniPath, $sSec, "RadarBlueColor", GUICtrlRead($g_hInput_RadarBlue))
	; 1. LƯU TỌA ĐỘ, MÀU SẮC & CHIP
	; ==========================================
	IniWrite($g_sIniPath, $sSec, "WindowClass", GUICtrlRead($g_hInput_WindowClass))

	IniWrite($g_sIniPath, $sSec, "BankerX", GUICtrlRead($g_hInput_BankerX))
	IniWrite($g_sIniPath, $sSec, "BankerY", GUICtrlRead($g_hInput_BankerY))
	IniWrite($g_sIniPath, $sSec, "PlayerX", GUICtrlRead($g_hInput_PlayerX))
	IniWrite($g_sIniPath, $sSec, "PlayerY", GUICtrlRead($g_hInput_PlayerY))
	IniWrite($g_sIniPath, $sSec, "TieX", GUICtrlRead($g_hInput_TieX))
	IniWrite($g_sIniPath, $sSec, "TieY", GUICtrlRead($g_hInput_TieY))
	IniWrite($g_sIniPath, $sSec, "ResultX1", GUICtrlRead($g_hInput_ResultX1))
	IniWrite($g_sIniPath, $sSec, "ResultY1", GUICtrlRead($g_hInput_ResultY1))
	IniWrite($g_sIniPath, $sSec, "ResultX2", GUICtrlRead($g_hInput_ResultX2))
	IniWrite($g_sIniPath, $sSec, "ResultY2", GUICtrlRead($g_hInput_ResultY2))
	IniWrite($g_sIniPath, $sSec, "BankerColor", GUICtrlRead($g_hInput_BankerColor))
	IniWrite($g_sIniPath, $sSec, "PlayerColor", GUICtrlRead($g_hInput_PlayerColor))
	IniWrite($g_sIniPath, $sSec, "TieColor", GUICtrlRead($g_hInput_TieColor))
	IniWrite($g_sIniPath, $sSec, "ShadeResult", GUICtrlRead($g_hInput_Shade_Result))

	IniWrite($g_sIniPath, $sSec, "BetTimeColor", GUICtrlRead($g_hInput_BetTimeColor))
	IniWrite($g_sIniPath, $sSec, "BetTimeX1", GUICtrlRead($g_hInput_BetTimeX1))
	IniWrite($g_sIniPath, $sSec, "BetTimeY1", GUICtrlRead($g_hInput_BetTimeY1))
	IniWrite($g_sIniPath, $sSec, "BetTimeX2", GUICtrlRead($g_hInput_BetTimeX2))
	IniWrite($g_sIniPath, $sSec, "BetTimeY2", GUICtrlRead($g_hInput_BetTimeY2))
	IniWrite($g_sIniPath, $sSec, "ShadeTimer", GUICtrlRead($g_hInput_Shade_Timer))
	IniWrite($g_sIniPath, $sSec, "CustomQLVTable", StringReplace(GUICtrlRead($g_hInput_CustomQLV_Edit), @CRLF, "|NL|"))
	IniWrite($g_sIniPath, $sSec, "QLVPreset", GUICtrlRead($g_hCombo_QLV_Presets))
	For $i = 0 To 4
		IniWrite($g_sIniPath, $sSec, "ChipEnabled_" & $i, GUICtrlRead($g_aCheckbox_ChipEnabled[$i]))
		IniWrite($g_sIniPath, $sSec, "ChipValue_" & $i, GUICtrlRead($g_aInput_ChipValue[$i]))
		IniWrite($g_sIniPath, $sSec, "ChipX_" & $i, GUICtrlRead($g_aInput_ChipX[$i]))
		IniWrite($g_sIniPath, $sSec, "ChipY_" & $i, GUICtrlRead($g_aInput_ChipY[$i]))
	Next

	; ==========================================
	; 2. LƯU MỌI LỰA CHỌN (TIỀN NONG & CƯỢC)
	; ==========================================
	IniWrite($g_sIniPath, $sSec, "CustomRules", StringReplace(GUICtrlRead($g_hInput_CustomRules), @CRLF, "|NL|"))
	IniWrite($g_sIniPath, $sSec, "Capital", GUICtrlRead($g_hInput_InitialCapital))
	IniWrite($g_sIniPath, $sSec, "BaseBet", GUICtrlRead($g_hInput_InitialBet))
	IniWrite($g_sIniPath, $sSec, "TakeProfit", GUICtrlRead($g_hInput_TakeProfit))
	IniWrite($g_sIniPath, $sSec, "StopLoss", GUICtrlRead($g_hInput_StopLoss))

	IniWrite($g_sIniPath, $sSec, "ChkDailyShield", GUICtrlRead($g_hCheckbox_DailyShield))
	IniWrite($g_sIniPath, $sSec, "DailyTarget", GUICtrlRead($g_hInput_DailyTarget))
	IniWrite($g_sIniPath, $sSec, "DailyTrailing", GUICtrlRead($g_hInput_DailyTrailing))
	IniWrite($g_sIniPath, $sSec, "DailyStopLoss", GUICtrlRead($g_hInput_DailyStopLoss))

	IniWrite($g_sIniPath, $sSec, "TargetPos", GUICtrlRead($g_hInput_TargetProfitPercent))
	IniWrite($g_sIniPath, $sSec, "TargetNeg", GUICtrlRead($g_hInput_StopLossPercent))
	IniWrite($g_sIniPath, $sSec, "LaiKepPercent", GUICtrlRead($g_hInput_LaiKepPercent))

	IniWrite($g_sIniPath, $sSec, "ChkCompound", GUICtrlRead($g_hCheckbox_LaiKepVIP))
	IniWrite($g_sIniPath, $sSec, "ChkSepQLV", GUICtrlRead($g_hCheckbox_SeparateQLV))

	; --- LƯU CẤU HÌNH TÙY CHỌN CLICK ---
	Local $sMode = "Mouse"
	If GUICtrlRead($g_hRadio_ClickMode_Control_Main) = $GUI_CHECKED Then $sMode = "Control"
	IniWrite($g_sIniPath, $sSec, "ClickMode", $sMode)
	IniWrite($g_sIniPath, $sSec, "ClickDelay", GUICtrlRead($g_hInput_ClickDelay_Main))
	IniWrite($g_sIniPath, $sSec, "MouseSpeed", GUICtrlRead($g_hInput_MouseSpeed))

	; --- LƯU CẤU HÌNH XÓC ĐĨA VIP ---
	IniWrite($g_sIniPath, $sSec, "ChkXocDiaVIP", GUICtrlRead($g_hCheckbox_XocDiaVIP))
	IniWrite($g_sIniPath, $sSec, "LimitBtnX", GUICtrlRead($g_hInput_LimitBtnX))
	IniWrite($g_sIniPath, $sSec, "LimitBtnY", GUICtrlRead($g_hInput_LimitBtnY))
	IniWrite($g_sIniPath, $sSec, "Limit10_500X", GUICtrlRead($g_hInput_Limit10_500X))
	IniWrite($g_sIniPath, $sSec, "Limit10_500Y", GUICtrlRead($g_hInput_Limit10_500Y))
	IniWrite($g_sIniPath, $sSec, "Limit20_50KX", GUICtrlRead($g_hInput_Limit20_50KX))
	IniWrite($g_sIniPath, $sSec, "Limit20_50KY", GUICtrlRead($g_hInput_Limit20_50KY))
	IniWrite($g_sIniPath, $sSec, "LimitConfirmX", GUICtrlRead($g_hInput_LimitConfirmX))
	IniWrite($g_sIniPath, $sSec, "LimitConfirmY", GUICtrlRead($g_hInput_LimitConfirmY))

	If $bIsAutoSave Then
		_UpdateStatus("🔄 Đã tự động lưu lại toàn bộ thay đổi cho sảnh: " & $sProfileName)
	Else
		$g_sCurrentLoadedProfile = $sProfileName
		_UpdateStatus("💾 Đã lưu thành công 100% các thiết lập cho sảnh mới!")
	EndIf

	IniWrite($g_sIniPath, "Settings", "LastProfile", $sProfileName)

	Return True
EndFunc   ;==>_MasterSave
Func _LoadSelectedProfile($sProfileName)
	If $sProfileName = "" Then Return False
	Local $sSec = "Profile_" & $sProfileName

	; 1. NẠP TỌA ĐỘ
	GUICtrlSetData($g_hInput_WindowClass, IniRead($g_sIniPath, $sSec, "WindowClass", "Chrome_WidgetWin_1"))
	GUICtrlSetData($g_hInput_BankerX, IniRead($g_sIniPath, $sSec, "BankerX", ""))
	GUICtrlSetData($g_hInput_BankerY, IniRead($g_sIniPath, $sSec, "BankerY", ""))
	GUICtrlSetData($g_hInput_PlayerX, IniRead($g_sIniPath, $sSec, "PlayerX", ""))
	GUICtrlSetData($g_hInput_PlayerY, IniRead($g_sIniPath, $sSec, "PlayerY", ""))
	GUICtrlSetData($g_hInput_TieX, IniRead($g_sIniPath, $sSec, "TieX", ""))
	GUICtrlSetData($g_hInput_TieY, IniRead($g_sIniPath, $sSec, "TieY", ""))
	GUICtrlSetState($g_hCheckbox_BaccaratLaser, Number(IniRead($g_sIniPath, $sSec, "ChkBaccaratLaser", 4)))
    GUICtrlSetData($g_hCombo_XD_Virtual, IniRead($g_sIniPath, $sSec, "XD_Virtual", "0"))
	; --- NẠP CẤU HÌNH XÓC ĐĨA VIP ---
	GUICtrlSetState($g_hCheckbox_XocDiaVIP, Number(IniRead($g_sIniPath, $sSec, "ChkXocDiaVIP", 4)))
	GUICtrlSetData($g_hInput_XD_Seq, IniRead($g_sIniPath, $sSec, "XD_Seq", "1, 2, 4, 8, 17, 35, 75"))
	GUICtrlSetData($g_hInput_XD_MaxRows, IniRead($g_sIniPath, $sSec, "XD_MaxRows", "5"))
	GUICtrlSetData($g_hInput_LimitBtnX, IniRead($g_sIniPath, $sSec, "LimitBtnX", ""))
	GUICtrlSetData($g_hInput_LimitBtnY, IniRead($g_sIniPath, $sSec, "LimitBtnY", ""))
	GUICtrlSetData($g_hInput_Limit10_500X, IniRead($g_sIniPath, $sSec, "Limit10_500X", ""))
	GUICtrlSetData($g_hInput_Limit10_500Y, IniRead($g_sIniPath, $sSec, "Limit10_500Y", ""))
	GUICtrlSetData($g_hInput_Limit20_50KX, IniRead($g_sIniPath, $sSec, "Limit20_50KX", ""))
	GUICtrlSetData($g_hInput_Limit20_50KY, IniRead($g_sIniPath, $sSec, "Limit20_50KY", ""))
	GUICtrlSetData($g_hInput_LimitConfirmX, IniRead($g_sIniPath, $sSec, "LimitConfirmX", ""))
	GUICtrlSetData($g_hInput_LimitConfirmY, IniRead($g_sIniPath, $sSec, "LimitConfirmY", ""))

	GUICtrlSetData($g_hInput_ResultX1, IniRead($g_sIniPath, $sSec, "ResultX1", ""))
	GUICtrlSetData($g_hInput_ResultY1, IniRead($g_sIniPath, $sSec, "ResultY1", ""))
	GUICtrlSetData($g_hInput_ResultX2, IniRead($g_sIniPath, $sSec, "ResultX2", ""))
	GUICtrlSetData($g_hInput_ResultY2, IniRead($g_sIniPath, $sSec, "ResultY2", ""))
	GUICtrlSetData($g_hInput_BankerColor, IniRead($g_sIniPath, $sSec, "BankerColor", ""))
	GUICtrlSetData($g_hInput_PlayerColor, IniRead($g_sIniPath, $sSec, "PlayerColor", ""))
	GUICtrlSetData($g_hInput_TieColor, IniRead($g_sIniPath, $sSec, "TieColor", ""))
	GUICtrlSetData($g_hInput_Shade_Result, IniRead($g_sIniPath, $sSec, "ShadeResult", "10"))

	GUICtrlSetData($g_hInput_BetTimeColor, IniRead($g_sIniPath, $sSec, "BetTimeColor", ""))
	GUICtrlSetData($g_hInput_BetTimeX1, IniRead($g_sIniPath, $sSec, "BetTimeX1", ""))
	GUICtrlSetData($g_hInput_BetTimeY1, IniRead($g_sIniPath, $sSec, "BetTimeY1", ""))
	GUICtrlSetData($g_hInput_BetTimeX2, IniRead($g_sIniPath, $sSec, "BetTimeX2", ""))
	GUICtrlSetData($g_hInput_BetTimeY2, IniRead($g_sIniPath, $sSec, "BetTimeY2", ""))
	GUICtrlSetData($g_hInput_Shade_Timer, IniRead($g_sIniPath, $sSec, "ShadeTimer", "20"))

	GUICtrlSetData($g_hInput_CustomQLV_Edit, StringReplace(IniRead($g_sIniPath, $sSec, "CustomQLVTable", "0-1-0-1|NL|1-2-0-2"), "|NL|", @CRLF))
	GUICtrlSetData($g_hCombo_QLV_Presets, IniRead($g_sIniPath, $sSec, "QLVPreset", "Tùy chỉnh"))
	For $i = 0 To 4
		GUICtrlSetState($g_aCheckbox_ChipEnabled[$i], Number(IniRead($g_sIniPath, $sSec, "ChipEnabled_" & $i, 1)))
		GUICtrlSetData($g_aInput_ChipValue[$i], IniRead($g_sIniPath, $sSec, "ChipValue_" & $i, ""))
		GUICtrlSetData($g_aInput_ChipX[$i], IniRead($g_sIniPath, $sSec, "ChipX_" & $i, ""))
		GUICtrlSetData($g_aInput_ChipY[$i], IniRead($g_sIniPath, $sSec, "ChipY_" & $i, ""))
	Next

	GUICtrlSetData($g_hInput_RadarRed, IniRead($g_sIniPath, $sSec, "RadarRedColor", ""))
	GUICtrlSetData($g_hInput_RadarBlue, IniRead($g_sIniPath, $sSec, "RadarBlueColor", ""))

	GUICtrlSetState($g_hCheckbox_XD_AutoResetDebt, Number(IniRead($g_sIniPath, $sSec, "XD_AutoReset", 4)))
GUICtrlSetData($g_hInput_XD_TargetProfit, IniRead($g_sIniPath, $sSec, "XD_TargetProf", "50.000"))
GUICtrlSetState($g_hCheckbox_XD_LowDebtPriority, Number(IniRead($g_sIniPath, $sSec, "XD_LowDebt", 4)))

	; --- NẠP CẤU HÌNH DU KÍCH 12 BÀN ---
	GUICtrlSetState($g_hCheckbox_DuKichDaBan, Number(IniRead($g_sIniPath, $sSec, "ChkDuKichDaBan", 4)))
	GUICtrlSetState($g_hCheckbox_SanBanMoi, Number(IniRead($g_sIniPath, $sSec, "ChkSanBanMoi", 4)))
	GUICtrlSetData($g_hInput_FirstCellX, IniRead($g_sIniPath, $sSec, "FirstCellX", ""))
	GUICtrlSetData($g_hInput_FirstCellY, IniRead($g_sIniPath, $sSec, "FirstCellY", ""))
	GUICtrlSetData($g_hInput_DuKich_WinTable, IniRead($g_sIniPath, $sSec, "DuKichWin", "2"))
	GUICtrlSetData($g_hInput_DuKich_LossTable, IniRead($g_sIniPath, $sSec, "DuKichLoss", "3"))
	GUICtrlSetData($g_hInput_DuKich_RestTime, IniRead($g_sIniPath, $sSec, "DuKichRest", "15"))
	For $i = 0 To 11
		GUICtrlSetData($g_aInput_AnchorX[$i], IniRead($g_sIniPath, $sSec, "AnchorX_" & $i, ""))
		GUICtrlSetData($g_aInput_AnchorY[$i], IniRead($g_sIniPath, $sSec, "AnchorY_" & $i, ""))
	Next

	; 2. NẠP TIỀN NONG & CÔNG THỨC
	GUICtrlSetData($g_hInput_CustomRules, StringReplace(IniRead($g_sIniPath, $sSec, "CustomRules", ""), "|NL|", @CRLF))

	GUICtrlSetData($g_hInput_InitialCapital, IniRead($g_sIniPath, $sSec, "Capital", "10.000.000"))
	GUICtrlSetData($g_hInput_InitialBet, IniRead($g_sIniPath, $sSec, "BaseBet", "50.000"))
	GUICtrlSetData($g_hInput_TakeProfit, IniRead($g_sIniPath, $sSec, "TakeProfit", "1000000"))
	GUICtrlSetData($g_hInput_StopLoss, IniRead($g_sIniPath, $sSec, "StopLoss", "-2000000"))

	; --- FIX: NẠP LẠI TRẠNG THÁI NGHỈ/DỪNG THEO TỪNG TÊN KHÁCH/CẤU HÌNH ---
	GUICtrlSetState($g_hRadio_Action_Stop, Number(IniRead($g_sIniPath, $sSec, "ActionStop", $GUI_CHECKED)))
	GUICtrlSetState($g_hRadio_Action_PauseMin, Number(IniRead($g_sIniPath, $sSec, "ActionPauseMin", 4)))
	GUICtrlSetState($g_hRadio_Action_PauseHand, Number(IniRead($g_sIniPath, $sSec, "ActionPauseHand", 4)))
	GUICtrlSetData($g_hInput_Action_PauseMin, IniRead($g_sIniPath, $sSec, "PauseMinVal", "15"))
	GUICtrlSetData($g_hInput_Action_PauseHand, IniRead($g_sIniPath, $sSec, "PauseHandVal", "5"))

	GUICtrlSetState($g_hCheckbox_DailyShield, Number(IniRead($g_sIniPath, $sSec, "ChkDailyShield", 4)))
	GUICtrlSetData($g_hInput_DailyTarget, IniRead($g_sIniPath, $sSec, "DailyTarget", "1.000.000"))
	GUICtrlSetData($g_hInput_DailyTrailing, IniRead($g_sIniPath, $sSec, "DailyTrailing", "200.000"))
	GUICtrlSetData($g_hInput_DailyStopLoss, IniRead($g_sIniPath, $sSec, "DailyStopLoss", "-1.000.000"))

	GUICtrlSetData($g_hInput_TargetProfitPercent, IniRead($g_sIniPath, $sSec, "TargetPos", "10"))
	GUICtrlSetData($g_hInput_StopLossPercent, IniRead($g_sIniPath, $sSec, "TargetNeg", "20"))
	GUICtrlSetData($g_hInput_LaiKepPercent, IniRead($g_sIniPath, $sSec, "LaiKepPercent", "5"))

	GUICtrlSetState($g_hCheckbox_LaiKepVIP, Number(IniRead($g_sIniPath, $sSec, "ChkCompound", 4)))
	GUICtrlSetState($g_hCheckbox_SeparateQLV, Number(IniRead($g_sIniPath, $sSec, "ChkSepQLV", 4)))

	; --- NẠP CẤU HÌNH TÙY CHỌN CLICK ---
	Local $sMode = IniRead($g_sIniPath, $sSec, "ClickMode", "Nhanh")
	If $sMode == "Mouse" Then
		GUICtrlSetState($g_hRadio_ClickMode_Mouse_Main, $GUI_CHECKED)
	Else
		GUICtrlSetState($g_hRadio_ClickMode_Control_Main, $GUI_CHECKED)
	EndIf
	GUICtrlSetData($g_hInput_ClickDelay_Main, IniRead($g_sIniPath, $sSec, "ClickDelay", "10"))
	GUICtrlSetData($g_hInput_MouseSpeed, IniRead($g_sIniPath, $sSec, "MouseSpeed", "0"))

	; --- NẠP CẤU HÌNH XÓC ĐĨA VIP ---
	GUICtrlSetState($g_hCheckbox_XocDiaVIP, Number(IniRead($g_sIniPath, $sSec, "ChkXocDiaVIP", 4)))
	GUICtrlSetData($g_hInput_LimitBtnX, IniRead($g_sIniPath, $sSec, "LimitBtnX", ""))
	GUICtrlSetData($g_hInput_LimitBtnY, IniRead($g_sIniPath, $sSec, "LimitBtnY", ""))
	GUICtrlSetData($g_hInput_Limit10_500X, IniRead($g_sIniPath, $sSec, "Limit10_500X", ""))
	GUICtrlSetData($g_hInput_Limit10_500Y, IniRead($g_sIniPath, $sSec, "Limit10_500Y", ""))
	GUICtrlSetData($g_hInput_Limit20_50KX, IniRead($g_sIniPath, $sSec, "Limit20_50KX", ""))
	GUICtrlSetData($g_hInput_Limit20_50KY, IniRead($g_sIniPath, $sSec, "Limit20_50KY", ""))
	GUICtrlSetData($g_hInput_LimitConfirmX, IniRead($g_sIniPath, $sSec, "LimitConfirmX", ""))
	GUICtrlSetData($g_hInput_LimitConfirmY, IniRead($g_sIniPath, $sSec, "LimitConfirmY", ""))

	$g_sCurrentLoadedProfile = $sProfileName
	_UpdateStatus("✅ Đã nạp thành công 100% dữ liệu của sảnh: " & $sProfileName)
    _ToggleGameModeUI()
	Return True
EndFunc   ;==>_LoadSelectedProfile
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
				$g_iLastActiveRuleIndex = -1
				$g_iCustomSeqStep = 0
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
Func _UpdateStatus($sText)
	; Biến Static để nhớ nội dung đã hiển thị gần nhất, tránh spam
	Local Static $sLastStatusText = ""

	; Nếu nội dung giống hệt lần trước thì bỏ qua không ghi lại
	If $sText == $sLastStatusText Then Return
	$sLastStatusText = $sText

	If $g_hGUI <> "" And $g_hGUI <> 0 Then
		Local $sTitleID = ($g_sMyTableID <> "") ? (" - " & $g_sMyTableID) : ""
		WinSetTitle($g_hGUI, "", "Tool_AIO_" & $g_sVersion & $g_sInstanceIdentifier & $sTitleID & " | " & $g_sCopyright)
	EndIf

	; >>> ĐƯA NỘI DUNG LÊN TV SCREEN VÀ CHỐNG ĐƠ <<<
	If $g_hEdit_ActivityLog <> 0 Then
		Local $sTime = StringFormat("%02d:%02d:%02d", @HOUR, @MIN, @SEC)
		Local $sCurrentText = GUICtrlRead($g_hEdit_ActivityLog)

		; Nếu vượt quá 15,000 ký tự, tự động xóa phần cũ nhất
		If StringLen($sCurrentText) > 15000 Then
			$sCurrentText = StringRight($sCurrentText, 8000)
			GUICtrlSetData($g_hEdit_ActivityLog, $sCurrentText & @CRLF & "[" & $sTime & "] " & $sText & @CRLF)
		Else
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
	Local $sFileProfit = @ScriptDir & "\profit_history.ini"
	Local $fDisplayVol = 0
	Local $fDisplayProf = 0

	Local $sToday = _GetGamingDate()
	Local $aD = StringSplit($sToday, "-")
	Local $sThisWeek = $aD[1] & "-W" & StringFormat("%02d", _WeekNumberISO($aD[1], $aD[2], $aD[3]))
	Local $sThisMonth = StringLeft($sToday, 7)
	Local $sThisYear = StringLeft($sToday, 4)

	If $sFilter = "Chọn Ngày Cụ Thể" Then
		GUICtrlSetState($g_hDate_VolumeFilter, $GUI_SHOW)
		Local $sPickedDate = GUICtrlRead($g_hDate_VolumeFilter)
		$fDisplayVol = Number(IniRead($sFileVolume, "Daily", $sPickedDate, "0"))
		$fDisplayProf = Number(IniRead($sFileProfit, "Daily", $sPickedDate, "0"))
	Else
		GUICtrlSetState($g_hDate_VolumeFilter, $GUI_HIDE)
		Switch $sFilter
			Case "Hôm Nay"
				$fDisplayVol = Number(IniRead($sFileVolume, "Daily", $sToday, "0"))
				$fDisplayProf = Number(IniRead($sFileProfit, "Daily", $sToday, "0"))
			Case "Hôm Qua"
				Local $sYesterday = StringReplace(_DateAdd('D', -1, _NowCalcDate()), "/", "-")
				$fDisplayVol = Number(IniRead($sFileVolume, "Daily", $sYesterday, "0"))
				$fDisplayProf = Number(IniRead($sFileProfit, "Daily", $sYesterday, "0"))
			Case "3 Ngày Qua"
				; Vòng lặp lùi 0, 1, 2 ngày để cộng dồn
				For $i = 0 To 2
					Local $sDay = StringReplace(_DateAdd('D', -$i, _NowCalcDate()), "/", "-")
					$fDisplayVol += Number(IniRead($sFileVolume, "Daily", $sDay, "0"))
					$fDisplayProf += Number(IniRead($sFileProfit, "Daily", $sDay, "0"))
				Next
			Case "Tuần Này"
				$fDisplayVol = Number(IniRead($sFileVolume, "Weekly", $sThisWeek, "0"))
				$fDisplayProf = Number(IniRead($sFileProfit, "Weekly", $sThisWeek, "0"))
			Case "Tháng Này"
				$fDisplayVol = Number(IniRead($sFileVolume, "Monthly", $sThisMonth, "0"))
				$fDisplayProf = Number(IniRead($sFileProfit, "Monthly", $sThisMonth, "0"))
			Case "3 Tháng"
				; Lùi 0, 1, 2 tháng để cộng dồn
				For $i = 0 To 2
					Local $sMonth = StringLeft(StringReplace(_DateAdd('M', -$i, _NowCalcDate()), "/", "-"), 7)
					$fDisplayVol += Number(IniRead($sFileVolume, "Monthly", $sMonth, "0"))
					$fDisplayProf += Number(IniRead($sFileProfit, "Monthly", $sMonth, "0"))
				Next
			Case "6 Tháng"
				For $i = 0 To 5
					Local $sMonth = StringLeft(StringReplace(_DateAdd('M', -$i, _NowCalcDate()), "/", "-"), 7)
					$fDisplayVol += Number(IniRead($sFileVolume, "Monthly", $sMonth, "0"))
					$fDisplayProf += Number(IniRead($sFileProfit, "Monthly", $sMonth, "0"))
				Next
			Case "1 Năm"
				$fDisplayVol = Number(IniRead($sFileVolume, "Yearly", $sThisYear, "0"))
				$fDisplayProf = Number(IniRead($sFileProfit, "Yearly", $sThisYear, "0"))
			Case "TỔNG VĨNH VIỄN"
				$fDisplayVol = Number(IniRead($sFileVolume, "Total", "Lifetime", "0"))
				$fDisplayProf = Number(IniRead($sFileProfit, "Total", "Lifetime", "0"))
		EndSwitch
	EndIf

	; Cập nhật hiển thị (Hoa hồng 0.8%)
	Local $fFee = Round($fDisplayVol * 0.008)
	GUICtrlSetData($g_hLabel_TotalVolume, "Volume: " & _FormatNumber($fDisplayVol) & " đ | Hoa Hồng: " & _FormatNumber($fFee) & " đ")

	Local $fNetTotal = $fDisplayProf + $fFee
	Local $sColorNet = ($fNetTotal >= 0) ? 0x006400 : 0xFF0000
	GUICtrlSetData($g_hLabel_NetDay, "TỔNG LÃI " & StringUpper($sFilter) & ": " & _FormatNumber($fNetTotal) & " đ")
	GUICtrlSetColor($g_hLabel_NetDay, $sColorNet)
EndFunc
Func _SyncLiveDashboard($fLiveBalance, $fLiveProfit, $fLiveVolume)
	GUICtrlSetData($g_hLabel_CurrentBalance, _FormatNumber($fLiveBalance) & " đ")
	GUICtrlSetColor($g_hLabel_CurrentBalance, 0x0000FF)

	If $fLiveProfit >= 0 Then
		GUICtrlSetData($g_hLabel_Profit, "+" & _FormatNumber($fLiveProfit) & " đ")
		GUICtrlSetColor($g_hLabel_Profit, 0x006400)
	Else
		GUICtrlSetData($g_hLabel_Profit, _FormatNumber($fLiveProfit) & " đ")
		GUICtrlSetColor($g_hLabel_Profit, 0xFF0000)
	EndIf

; ========================================================
	; ĐỒNG BỘ VOLUME LÊN GIAO DIỆN (0.8%)
	; ========================================================
	Local $fLiveFee = Round($fLiveVolume * 0.008)
	GUICtrlSetData($g_hLabel_TotalVolume, "Volume: " & _FormatNumber($fLiveVolume) & " đ | Hoa Hồng: " & _FormatNumber($fLiveFee) & " đ")
	GUICtrlSetColor($g_hLabel_TotalVolume, 0x8A2BE2) ; Giữ màu tím VIP
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
	Local Static $hWaitGUI = 0
	If $hWaitGUI <> 0 Then GUIDelete($hWaitGUI)

	; Nới nhẹ chiều cao tổng lên 140 để đủ chỗ chứa 3 dòng text thoải mái
	$hWaitGUI = GUICreate("System Pause", 350, 140, -1, -1, $WS_POPUP, BitOR($WS_EX_TOPMOST, $WS_EX_TOOLWINDOW))
	GUISetBkColor(0x282C34, $hWaitGUI)

	; Đường viền trên cùng
	GUICtrlCreateLabel("", 0, 0, 350, 3)
	GUICtrlSetBkColor(-1, 0x00A2ED)

	; Tiêu đề
	Local $hTitle = GUICtrlCreateLabel("⏳ HỆ THỐNG TẠM DỪNG CẦN THAO TÁC", 10, 12, 300, 20)
	GUICtrlSetFont(-1, 10, 700, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0xE5C07B)

	; Nút X
	Local $hBtnClose = GUICtrlCreateButton("X", 315, 8, 25, 25)
	GUICtrlSetFont(-1, 10, 800, 0, "Segoe UI")
	GUICtrlSetBkColor(-1, 0xE06C75)
	GUICtrlSetColor(-1, 0xFFFFFF)
	GUICtrlSetCursor(-1, 0)

	; Nội dung thông báo - Nới chiều cao lên 55 để hiển thị hết chữ
	Local $hText = GUICtrlCreateLabel($sMessage, 15, 40, 320, 55, $SS_CENTER)
	GUICtrlSetFont(-1, 9, 400, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0xABB2BF)

	; Vùng kéo thả cửa sổ
	Local $hDragArea = GUICtrlCreateLabel("", 0, 0, 300, 90, -1, $GUI_WS_EX_PARENTDRAG)
	GUICtrlSetBkColor(-1, $GUI_BKCOLOR_TRANSPARENT)

	; Nút xác nhận - Đẩy lùi xuống dưới một chút nhường chỗ cho text
	Local $hBtnDone = GUICtrlCreateButton("✓ ĐÃ XONG - TIẾP TỤC CHẠY", 75, 100, 200, 28)
	GUICtrlSetFont(-1, 9, 800, 0, "Segoe UI")
	GUICtrlSetBkColor(-1, 0x98C379)
	GUICtrlSetColor(-1, 0x000000)
	GUICtrlSetCursor(-1, 0)

	WinSetTrans($hWaitGUI, "", 240)
	GUISetState(@SW_SHOW, $hWaitGUI)

	Local $bContinue = False

	While 1
		Switch GUIGetMsg()
			Case $hBtnDone
				$bContinue = True
				ExitLoop
			Case $hBtnClose
				$bContinue = False
				ExitLoop
		EndSwitch
		Sleep(10)
	WEnd

	GUIDelete($hWaitGUI)
	$hWaitGUI = 0
	Return $bContinue
EndFunc
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
	If $g_fUnsyncedVolume > 0 Then
		Local $fVolToSend = $g_fUnsyncedVolume
		$g_fUnsyncedVolume = 0

		Local $sUrl = $g_sAppsScriptBaseURL & "?action=add_volume&hwid=" & $g_sHWID & "&vol=" & $fVolToSend & "&nocache=" & TimerInit()

		; THÊM DẤU CHẤM PHẨY VÀO TRƯỚC DÒNG DƯỚI ĐÂY ĐỂ TẮT ĐẨY VOLUME
		; InetRead($sUrl, 3)
	EndIf
EndFunc
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

	; 2. Bắt theo danh sách cửa sổ (Lấy cửa sổ có kích thước hiển thị lớn nhất)
	Local $aList = WinList("[CLASS:" & $sClass & "]")
	Local $hWndReal = 0
	Local $iMaxArea = 0

	For $i = 1 To $aList[0][0]
		If $aList[$i][0] <> "" And BitAND(WinGetState($aList[$i][1]), 2) Then
			Local $aPos = WinGetPos($aList[$i][1])
			; Cửa sổ phải đủ to (trên 300px) để là trình duyệt
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
Func _CreateGroup_FormulaLibrary()
	Local $hGroup = GUICtrlCreateGroup("📚 THƯ VIỆN CÔNG THỨC YÊU THÍCH", 340, 40, 500, 250, $WS_GROUP, $WS_EX_CLIENTEDGE)
	GUICtrlSetFont($hGroup, 11, 800)
	GUICtrlSetColor($hGroup, 0x0000FF)
	GUICtrlSetBkColor($hGroup, 0xF5F5F5)

	; Danh sách công thức (List Box) - Font mượt hơn
	$g_hList_FormulaLibrary = GUICtrlCreateList("", 350, 65, 300, 215, BitOR(0x00200000, 0x00800000))
	GUICtrlSetFont($g_hList_FormulaLibrary, 10, 400, 0, "Segoe UI")
	GUICtrlSetBkColor($g_hList_FormulaLibrary, 0x1E1E1E)
	GUICtrlSetColor($g_hList_FormulaLibrary, 0x00FF00)

	; =========================================================
	; Các nút bấm điều khiển (Đã bo lại chiều cao 32px, Font Segoe UI mịn màng)
	; =========================================================
	$g_hBtn_LoadFormula = GUICtrlCreateButton("▶ Nạp Vào Tool", 660, 70, 165, 32)
	GUICtrlSetBkColor($g_hBtn_LoadFormula, 0x4CAF50)
	GUICtrlSetColor($g_hBtn_LoadFormula, 0xFFFFFF)
	GUICtrlSetFont($g_hBtn_LoadFormula, 9, 600, 0, "Segoe UI")

	$g_hBtn_SaveFormula = GUICtrlCreateButton("💾 Lưu Thành Mẫu", 660, 120, 165, 32)
	GUICtrlSetBkColor($g_hBtn_SaveFormula, 0x2196F3)
	GUICtrlSetColor($g_hBtn_SaveFormula, 0xFFFFFF)
	GUICtrlSetFont($g_hBtn_SaveFormula, 9, 600, 0, "Segoe UI")

	$g_hBtn_DeleteFormula = GUICtrlCreateButton("❌ Xóa Mẫu Chọn", 660, 170, 165, 32)
	GUICtrlSetBkColor($g_hBtn_DeleteFormula, 0xF44336)
	GUICtrlSetColor($g_hBtn_DeleteFormula, 0xFFFFFF)
	GUICtrlSetFont($g_hBtn_DeleteFormula, 9, 600, 0, "Segoe UI")

	GUICtrlCreateLabel("Mẹo: Chọn một mẫu bên trái rồi bấm NẠP để tự động điền vào ô Công Thức Cược.", 660, 215, 170, 50)
	GUICtrlSetFont(-1, 8.5, 400, 0, "Segoe UI")
	GUICtrlSetColor(-1, 0x555555)

	GUICtrlCreateGroup("", -99, -99, 1, 1)
EndFunc   ;==>_CreateGroup_FormulaLibrary
Func _EnsureDefaultFormulasExist()
	Local $aData = IniReadSection($g_sIniPath, "UserFormulas")
	If @error Or $aData[0][0] = 0 Then
		IniWrite($g_sIniPath, "UserFormulas", "Danh Theo Duoi (Bam Cau)", "B-B|NL|P-P")
		IniWrite($g_sIniPath, "UserFormulas", "Danh Ping Pong", "B-P|NL|P-B")
	EndIf
EndFunc   ;==>_EnsureDefaultFormulasExist
Func _PopulateFormulaLibrary()
	_EnsureDefaultFormulasExist()
	Local $aData = IniReadSection($g_sIniPath, "UserFormulas")

	; Bắt buộc có dấu | để xóa rác cũ trong ListBox
	Local $sList = "|"
	If Not @error Then
		For $i = 1 To $aData[0][0]
			$sList &= $aData[$i][0] & "|"
		Next
	EndIf
	GUICtrlSetData($g_hList_FormulaLibrary, $sList)
EndFunc   ;==>_PopulateFormulaLibrary

Func _LoadSelectedFormula()
	Local $sSelected = GUICtrlRead($g_hList_FormulaLibrary)
	If $sSelected = "" Then
		MsgBox(48, "Lỗi", "Vui lòng chọn một công thức trong thư viện để Nạp!")
		Return
	EndIf

	Local $sFormula = IniRead($g_sIniPath, "UserFormulas", $sSelected, "")
	If $sFormula <> "" Then
		Local $sFormatted = StringReplace($sFormula, "|NL|", @CRLF)
		; Xóa trắng ô nhập liệu trước, sau đó mới nạp công thức mới vào
		GUICtrlSetData($g_hInput_CustomRules, "")
		GUICtrlSetData($g_hInput_CustomRules, $sFormatted)

		_UpdateStatus("✅ Đã nạp thành công công thức: [" & $sSelected & "]")
		$g_bNeedAutoSave = True
		$g_hAutoSaveTimer = TimerInit()
	Else
		MsgBox(48, "Lỗi", "Công thức này đang trống hoặc bị lỗi!")
	EndIf
EndFunc   ;==>_LoadSelectedFormula
Func _SaveCurrentFormula()
	Local $sCurrent = StringStripWS(GUICtrlRead($g_hInput_CustomRules), 3)
	If $sCurrent = "" Then
		MsgBox(48, "Lỗi", "Ô nhập công thức cược đang trống, không có gì để lưu!")
		Return
	EndIf

	Local $sName = InputBox("Lưu Công Thức", "Đặt tên cho công thức (Nếu trùng tên cũ sẽ ghi đè):", "Công thức mới", "", 300, 150)
	If @error Or $sName = "" Then Return

	; Chuẩn hóa xuống dòng để lưu an toàn vào file INI
	Local $sFormatted = StringReplace($sCurrent, @CRLF, "|NL|")
	$sFormatted = StringReplace($sFormatted, @LF, "|NL|")

	IniWrite($g_sIniPath, "UserFormulas", $sName, $sFormatted)
	MsgBox(64, "Thành Công", "Đã lưu công thức vào thư viện: " & $sName)
	_PopulateFormulaLibrary()
EndFunc   ;==>_SaveCurrentFormula

Func _DeleteSelectedFormula()
	Local $sSelected = GUICtrlRead($g_hList_FormulaLibrary)
	If $sSelected = "" Then
		MsgBox(48, "Lỗi", "Vui lòng chọn công thức cần xóa từ danh sách.")
		Return
	EndIf

	If MsgBox(36, "Xác Nhận Xóa", "Bạn có chắc chắn muốn xóa vĩnh viễn công thức: " & $sSelected & "?") = 6 Then
		IniDelete($g_sIniPath, "UserFormulas", $sSelected)
		MsgBox(64, "Thành Công", "Đã xóa công thức.")
		_PopulateFormulaLibrary()
	EndIf
EndFunc   ;==>_DeleteSelectedFormula

Func _CheckColorRange($iColor, $iTarget, $iShade)
	Local $r1 = BitAND(BitShift($iColor, 16), 0xFF), $g1 = BitAND(BitShift($iColor, 8), 0xFF), $b1 = BitAND($iColor, 0xFF)
	Local $r2 = BitAND(BitShift($iTarget, 16), 0xFF), $g2 = BitAND(BitShift($iTarget, 8), 0xFF), $b2 = BitAND($iTarget, 0xFF)
	If Abs($r1 - $r2) <= $iShade And Abs($g1 - $g2) <= $iShade And Abs($b1 - $b2) <= $iShade Then Return True
	Return False
EndFunc   ;==>_CheckColorRange
; =====================================================================
; HÀM DEBUG TỌA ĐỘ MA TRẬN LONG LONG (BẤM F4 ĐỂ VẼ DẤU THẬP ĐỎ)
; =====================================================================
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

	; --- TÍNH TOÁN BƯỚC NHẢY CHUẨN XÁC TUYỆT ĐỐI THEO FULL BẢNG ---
	If $fOffsetX > 60 Then $fOffsetX = $fOffsetX / 17
	If $fOffsetY > 60 Then $fOffsetY = $fOffsetY / 5
	; --------------------------------------------------------------
	If $fOffsetX < 5 Or $fOffsetY < 5 Then
		MsgBox(48, "Lỗi Tọa Độ", "Khoảng cách lấy bị sai!")
		Return
	EndIf

	; Chỉnh lại 0.20 theo ý sếp
	Local $iSampleDist = Round($fOffsetX * 0.20)
	If $iSampleDist < 3 Then $iSampleDist = 3

	Local $hDC = _WinAPI_GetDC(0)

	For $c = 0 To 18
		Local $iMaxRow = 5
		If $c == 18 Then $iMaxRow = 1

		For $r = 0 To $iMaxRow
			Local $iCX = $iStartX + ($c * $fOffsetX)
			Local $iCY = $iStartY + ($r * $fOffsetY)

			_DrawRedCross($hDC, $iCX - $iSampleDist, $iCY - $iSampleDist)
			_DrawRedCross($hDC, $iCX + $iSampleDist, $iCY + $iSampleDist)
		Next
	Next

	_WinAPI_ReleaseDC(0, $hDC)
EndFunc   ;==>_DebugGrid
; Hàm hỗ trợ vẽ dấu thập (dài 5 pixel)
Func _DrawRedCross($hDC, $x, $y)
	For $i = -2 To 2
		_WinAPI_SetPixel($hDC, $x + $i, $y, 0xFF0000) ; Đã sửa thành Đỏ chuẩn
		_WinAPI_SetPixel($hDC, $x, $y + $i, 0xFF0000)
	Next
EndFunc   ;==>_DrawRedCross
Func _AI_AnalyzeBestStrategy($sHistory)
	; Nếu lịch sử quá ngắn, chờ thêm
	If StringLen($sHistory) < 10 Then Return "WAIT"

	Local $iScore_BamCau = 0  ; Bám bệt (B đánh B, P đánh P)
	Local $iScore_BeCau = 0   ; Đánh Ping Pong (B đánh P, P đánh B)

	; Chạy thử nghiệm trên chuỗi lịch sử hiện tại
	For $i = 2 To StringLen($sHistory)
		Local $sPrev = StringMid($sHistory, $i - 1, 1)
		Local $sCurr = StringMid($sHistory, $i, 1)

		If $sPrev == $sCurr Then
			$iScore_BamCau += 1
		Else
			$iScore_BeCau += 1
		EndIf
	Next

	; AI Quyết định
	If $iScore_BamCau > $iScore_BeCau Then
		_UpdateStatus("🤖 AI Phân tích: Bàn này đang BỆT nhiều (" & $iScore_BamCau & " tay). Chốt chiến thuật: BÁM CẦU.")
		Return "BAM_CAU"
	Else
		_UpdateStatus("🤖 AI Phân tích: Bàn này đang CHUYỀN nhiều (" & $iScore_BeCau & " tay). Chốt chiến thuật: PING PONG.")
		Return "PING_PONG"
	EndIf
EndFunc   ;==>_AI_AnalyzeBestStrategy
; ==================================================================================================
; HÀM QUÉT BẢNG KHỐI VẠN NĂNG (TÍCH HỢP QUÉT CHỮ THẬP NÉ CHẤM ĐÔI)
; ==================================================================================================
Func _ScanUniversalBeadPlate()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

	Local $sHistory = ""
	Local $iStartX = Number(GUICtrlRead($g_hInput_ResultX1))
	Local $iStartY = Number(GUICtrlRead($g_hInput_ResultY1))
	Local $iX2 = Number(GUICtrlRead($g_hInput_ResultX2))
	Local $iY2 = Number(GUICtrlRead($g_hInput_ResultY2))

	If $iStartX = 0 Or $iX2 = 0 Then Return ""

	; Tool tự tính khoảng cách giữa các ô dựa trên toàn bộ khung bảng (VD: 18 cột, 6 hàng)
	Local $fOffsetX = ($iX2 - $iStartX) / ($g_iGridCols_Max - 1)
	Local $fOffsetY = ($iY2 - $iStartY) / ($g_iGridRows_Max - 1)

	Local $iColRed = Number(GUICtrlRead($g_hInput_BankerColor))
	Local $iColBlue = Number(GUICtrlRead($g_hInput_PlayerColor))
	Local $iColGreen = Number(GUICtrlRead($g_hInput_TieColor))
	Local $iShade = Number(GUICtrlRead($g_hInput_Shade_Result))
	If $iShade < 40 Then $iShade = 20

	Local $iEmptyCount = 0

	; Quét tuần tự từ Cột 1 -> Cột 18, từ Hàng 1 -> Hàng 6
	For $c = 0 To ($g_iGridCols_Max - 1)
		For $r = 0 To ($g_iGridRows_Max - 1)
			; Tính tọa độ tâm của ô hiện tại
			Local $iCX = $iStartX + ($c * $fOffsetX)
			Local $iCY = $iStartY + ($r * $fOffsetY)

			; =============================================================
			; THUẬT TOÁN QUÉT CHỮ THẬP (Né góc chứa chấm Đôi / Né chữ Trắng)
			; Khai báo mảng 5 điểm: Tâm, Trên, Dưới, Trái, Phải (Cách tâm 4 pixel)
			; =============================================================
			Local $aPoints[5][2] = [[$iCX, $iCY], [$iCX, $iCY - 4], [$iCX, $iCY + 4], [$iCX - 4, $iCY], [$iCX + 4, $iCY]]

			Local $bFoundRed = False, $bFoundBlue = False, $bFoundGreen = False

			; Chích 5 mũi kim để kiểm tra màu
			For $p = 0 To 4
				Local $iColor = PixelGetColor($aPoints[$p][0], $aPoints[$p][1], $hWnd)

				If _CheckColorRange($iColor, $iColRed, $iShade) Then
					$bFoundRed = True
					ExitLoop ; Thấy màu là thoát vòng lặp chích kim ngay để tối ưu tốc độ
				ElseIf _CheckColorRange($iColor, $iColBlue, $iShade) Then
					$bFoundBlue = True
					ExitLoop
				ElseIf _CheckColorRange($iColor, $iColGreen, $iShade) Then
					$bFoundGreen = True
					ExitLoop
				EndIf
			Next

			; =============================================================
			; GHI NHẬN KẾT QUẢ VÀ XỬ LÝ Ô TRỐNG
			; =============================================================
			If $bFoundRed Then
				$sHistory &= "B"
				$iEmptyCount = 0 ; Reset bộ đếm nếu thấy có kết quả
			ElseIf $bFoundBlue Then
				$sHistory &= "P"
				$iEmptyCount = 0
			ElseIf $bFoundGreen Then
				$sHistory &= "T"
				$iEmptyCount = 0
			Else
				; Nếu chích 5 mũi kim đều không ra màu B/P/T -> Ô trống
				$iEmptyCount += 1

				; Chạm 3 ô trống liên tiếp -> Ván bài đã dừng ở đây -> Trả về kết quả ngay
				If $iEmptyCount >= 3 Then Return $sHistory
			EndIf
		Next
	Next
	Return $sHistory
EndFunc   ;==>_ScanUniversalBeadPlate
; =========================================================================
; HÀM TRỢ GIÚP 1: BÓC TÁCH CỤM CHÍNH XÁC 100% (NGĂN BẮT NHẦM BỆT)
; Biến đổi lịch sử thành chuỗi khối. Ví dụ: PPBBBP -> "P2-B3-P1"
; Đảm bảo 2 Đỏ (B2) không bao giờ bị nhầm với Bệt 4 (B4).
; =========================================================================
Func _GetStrictStreakPattern($sStr, $iNumStreaks)
	Local $sResult = ""
	Local $iLen = StringLen($sStr)
	If $iLen == 0 Then Return ""
	Local $iStreaksFound = 0
	Local $sCurrentChar = StringMid($sStr, $iLen, 1)
	Local $iCount = 1

	For $i = $iLen - 1 To 1 Step -1
		Local $sChar = StringMid($sStr, $i, 1)
		If $sChar == $sCurrentChar Then
			$iCount += 1
		Else
			$sResult = $sCurrentChar & $iCount & "-" & $sResult
			$iStreaksFound += 1
			If $iStreaksFound == $iNumStreaks Then Return StringTrimRight($sResult, 1)
			$sCurrentChar = $sChar
			$iCount = 1
		EndIf
	Next
	$sResult = $sCurrentChar & $iCount & "-" & $sResult
	Return StringTrimRight($sResult, 1)
EndFunc   ;==>_GetStrictStreakPattern

; =========================================================================
; HÀM TRỢ GIÚP 2: CẤP ID RIÊNG BIỆT CHO TỪNG CỤM (ĐỂ GẤP THẾP ĐỘC LẬP)
; =========================================================================
Func _GetAIPatternRuleIndex($sPattern)
	Static $aAIPatternList[250]
	Static $iAIPatternCount = 0
	For $i = 0 To $iAIPatternCount - 1
		If $aAIPatternList[$i] == $sPattern Then Return 50 + $i ; Cấp ID từ 50 trở đi
	Next
	If $iAIPatternCount < 250 Then
		$aAIPatternList[$iAIPatternCount] = $sPattern
		$iAIPatternCount += 1
		Return 50 + ($iAIPatternCount - 1)
	EndIf
	Return 50
EndFunc   ;==>_GetAIPatternRuleIndex

; =========================================================================
; LÕI QUYẾT ĐỊNH XUỐNG TIỀN (GẤP THẾP ĐỢI CỤM)
; =========================================================================
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

	; =========================================================================
	; [CHẾ ĐỘ 1]: MẬT MÃ GHI NHỚ 0-4 (ƯU TIÊN TỐI CAO - NGẮT MỌI TÍNH NĂNG KHÁC)
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_MemoryCode) == $GUI_CHECKED Then
		If $g_sMemoryTargetBet == "B" Or $g_sMemoryTargetBet == "P" Then
			Local $aQLV = _GetQLV_Params($g_iCapitalLevel) ; Lấy mức vốn hiện tại
			Local $aResult[3] = ["BET", $g_sMemoryTargetBet, $aQLV[1]]
			Return $aResult
		EndIf

		; Nếu không có tín hiệu bộ nhớ, đứng im quan sát, KHÔNG XUỐNG CODE DƯỚI
		_UpdateStatus("🧠 Mật Mã Ghi Nhớ: Đang quan sát và chờ mốc điểm 0-4...")
		Return $aStop
	EndIf
; =========================================================================
	; [CHẾ ĐỘ XÓC ĐĨA VIP]: KIỂM TRA NẾU BẬT THÌ RẼ NHÁNH VÀO ĐÂY
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
		; Lấy tọa độ nút bấm Limit từ giao diện đẩy vào biến chạy
		$g_iLimitBtnX = Number(GUICtrlRead($g_hInput_LimitBtnX))
		$g_iLimitBtnY = Number(GUICtrlRead($g_hInput_LimitBtnY))
		$g_iLimit10_500X = Number(GUICtrlRead($g_hInput_Limit10_500X))
		$g_iLimit10_500Y = Number(GUICtrlRead($g_hInput_Limit10_500Y))
		$g_iLimit20_50KX = Number(GUICtrlRead($g_hInput_Limit20_50KX))
		$g_iLimit20_50KY = Number(GUICtrlRead($g_hInput_Limit20_50KY))
		$g_iLimitConfirmX = Number(GUICtrlRead($g_hInput_LimitConfirmX))
		$g_iLimitConfirmY = Number(GUICtrlRead($g_hInput_LimitConfirmY))

		; Chuyển lịch sử thành chuỗi văn bản và nạp vào hàm VIP
		Local $sHistoryRaw = _ArrayToString($g_aDisplayHistory, "")
		Return _Logic_XocDia_5Hang_VIP($sHistoryRaw)
	EndIf

	; =========================================================================
	; [CHẾ ĐỘ 2]: CÁC LOGIC CŨ (AI, CÔNG THỨC CUSTOM) SẼ NẰM Ở DƯỚI NÀY
	; =========================================================================
	If GUICtrlRead($g_hCheckbox_AutoAI_BeCau) == $GUI_CHECKED Then
		Local $aAIPredict = _AI_PredictNextBet_Advanced()
		Local $sAIPredict = $aAIPredict[0]
		Local $sPattern = $aAIPredict[1]

		If $sAIPredict <> "" And $sPattern <> "" Then
			$g_sLastAIPredict = $sAIPredict
			$g_iAIWaitCount = 0

			; 1. LẤY ID CỦA CỤM
			$g_iLastActiveRuleIndex = _GetAIPatternRuleIndex($sPattern)

			; 2. ĐỌC VỐN DỰA TRÊN ID (NẾU BẬT QLV RIÊNG BIỆT)
			Local $iTargetLevel = $g_iCapitalLevel
			Local $bSepQLV = (GUICtrlRead($g_hCheckbox_SeparateQLV) == $GUI_CHECKED)

			If UBound($g_aRuleLevels) < 250 Then ReDim $g_aRuleLevels[250]

			If $bSepQLV And $g_iLastActiveRuleIndex > -1 And $g_iLastActiveRuleIndex < UBound($g_aRuleLevels) Then
				$iTargetLevel = $g_aRuleLevels[$g_iLastActiveRuleIndex]
			EndIf

			Local $aAI_QLV = _GetQLV_Params($iTargetLevel)
			Local $aResult[3] = ["BET", $sAIPredict, $aAI_QLV[1]]

			_UpdateStatus("🤖 [AI CHỐT] Cụm [" & $sPattern & "] -> Đánh " & $sAIPredict & " | Lệnh " & $iTargetLevel)
			Return $aResult
		EndIf

		$g_iAIWaitCount += 1
		If Mod($g_iAIWaitCount, 4) == 0 Then
			_UpdateStatus("🛡️ Chống văng: Click an toàn vào bảng lịch sử...")
			Local $iSafeX = Number(GUICtrlRead($g_hInput_ResultX1)) + 15
			Local $iSafeY = Number(GUICtrlRead($g_hInput_ResultY1)) + 15
			_SingleClick($g_hTargetGameWin, $iSafeX, $iSafeY, 0)
		EndIf

		_UpdateStatus("👁️ AI: " & $g_sLastAILogicInfo)
		Return $aStop
	EndIf

	Local $aQLV = _GetQLV_Params($g_iCapitalLevel)
	Local $iTotalHands = UBound($g_aDisplayHistory)
	Return _Logic_Custom($iTotalHands, $aQLV[1], False)
EndFunc   ;==>_DecideNextAction

; =========================================================================
; HÀM AI: TÌM CỤM CHÍNH XÁC VÀ TÍNH TOÁN XÁC SUẤT ĐỂ RA QUYẾT ĐỊNH
; =========================================================================
Func _AI_PredictNextBet_Advanced()
	Local $aResult[2] = ["", ""]
	Local $sHist = _ArrayToString($g_aDisplayHistory, "")
	$sHist = StringReplace($sHist, "T", "")
	Local $iLen = StringLen($sHist)

	If $iLen < 6 Then
		$g_sLastAILogicInfo = "Đang thu thập dữ liệu bàn (" & $iLen & "/6 tay)..."
		Return $aResult
	EndIf

	Local $sTarget = ""
	Local $sBestPattern = ""
	Local $fConfidence = 0.0
	Local $sLogicName = ""

	; Tìm khuôn từ dài tới ngắn (Ưu tiên khuôn 3 khối, rồi 2 khối)
	; Ví dụ 3 khối: P1-B2-P1 (1 Xanh - 2 Đỏ - 1 Xanh)
	Local $iPatternLength = 3
	If $iLen < 15 Then $iPatternLength = 2

	While $iPatternLength >= 2
		Local $sCurrentTailPattern = _GetStrictStreakPattern($sHist, $iPatternLength)
		If $sCurrentTailPattern == "" Then ExitLoop

		Local $iCountB = 0
		Local $iCountP = 0

		; Quét lịch sử để tìm các lần xuất hiện của cụm TÁCH BIỆT này
		For $i = $iPatternLength To $iLen - 1
			Local $sSubHist = StringLeft($sHist, $i)
			Local $sPastPattern = _GetStrictStreakPattern($sSubHist, $iPatternLength)

			If $sPastPattern == $sCurrentTailPattern Then
				; Nếu khớp chính xác 100% cụm (không bị dính vào bệt), xem tay tiếp theo về gì
				Local $sNextChar = StringMid($sHist, $i + 1, 1)
				If $sNextChar == "B" Then $iCountB += 1
				If $sNextChar == "P" Then $iCountP += 1
			EndIf
		Next

		Local $iTotalFound = $iCountB + $iCountP
		If $iTotalFound > 0 Then
			If $iCountB > $iCountP Then
				$sTarget = "B"
				$fConfidence = Round(($iCountB / $iTotalFound) * 100, 1)
			ElseIf $iCountP > $iCountB Then
				$sTarget = "P"
				$fConfidence = Round(($iCountP / $iTotalFound) * 100, 1)
			EndIf

			If $fConfidence > 50.0 Then
				$sBestPattern = $sCurrentTailPattern
				$sLogicName = "Bắt cụm tách biệt [" & $sCurrentTailPattern & "] (Lặp " & $iTotalFound & " lần)"
				ExitLoop
			EndIf
		EndIf

		$iPatternLength -= 1
	WEnd

	; Mốc tỉ lệ động (Đợi lâu thì mốc thấp cũng vào)
	Local $fDynamicThreshold = 75.0
	If $g_iAIWaitCount >= 4 Then $fDynamicThreshold = 55.0

	If $sTarget <> "" And $fConfidence >= $fDynamicThreshold Then
		$g_sLastAILogicInfo = $sLogicName & " | Tỉ lệ: " & $fConfidence & "%"
		$aResult[0] = $sTarget
		$aResult[1] = $sBestPattern
		Return $aResult
	EndIf

	$g_sLastAILogicInfo = "Đang rình cụm rõ ràng hơn... (Tỉ lệ hiện tại: " & $fConfidence & "%)"
	Return $aResult
EndFunc   ;==>_AI_PredictNextBet_Advanced
; Hàm hỗ trợ xác minh mảng màu đặc (Tuyệt đối toàn màn hình)
Func _VerifySolidBlock_Absolute($iX, $iY, $iColor, $iShade)
	Local $iMatch = 0
	; PixelSearch luôn tìm thấy điểm ĐẦU TIÊN là mép TRÊN-TRÁI.
	; Nên ta phải check các điểm lùi vào bên trong (hướng XUỐNG DƯỚI và SANG PHẢI 6px)
	If _CheckColorRange(PixelGetColor($iX + 6, $iY), $iColor, $iShade) Then $iMatch += 1
	If _CheckColorRange(PixelGetColor($iX, $iY + 6), $iColor, $iShade) Then $iMatch += 1
	If _CheckColorRange(PixelGetColor($iX + 6, $iY + 6), $iColor, $iShade) Then $iMatch += 1

	Return ($iMatch >= 2) ; Chỉ cần 2/3 điểm cùng màu là chốt khối đặc 100%
EndFunc

Func _IsBetTimeOpen()
	Local $iX1 = $g_aBetTimeIndicatorArea[0]
	Local $iY1 = $g_aBetTimeIndicatorArea[1]
	Local $iX2 = $g_aBetTimeIndicatorArea[2]
	Local $iY2 = $g_aBetTimeIndicatorArea[3]

	Local $iLeft = $iX1, $iRight = $iX2
	If $iX1 > $iX2 Then
		$iLeft = $iX2
		$iRight = $iX1
	EndIf

	Local $iTop = $iY1, $iBottom = $iY2
	If $iY1 > $iY2 Then
		$iTop = $iY2
		$iBottom = $iY1
	EndIf

	Local $iTolerance = Number(GUICtrlRead($g_hInput_Shade_Timer))
	If $iTolerance < 40 Then $iTolerance = 40

	; Quét tuyệt đối không dùng $hWnd, Step 3 né nhiễu hạt
	Local $aSearch = PixelSearch($iLeft, $iTop, $iRight, $iBottom, $g_iBetTimeIndicatorColor, $iTolerance, 3)
	Return IsArray($aSearch)
EndFunc

Func _ScanPopupResult_PP()
	Local $hWnd = $g_hTargetGameWin
	If $hWnd = 0 Or Not WinExists($hWnd) Then Return ""

	; Lấy tọa độ Khung Kết Quả (Đã được nội suy chuẩn xác cho bàn hiện tại)
	Local $iX1 = $g_aResultArea[0]
	Local $iY1 = $g_aResultArea[1]
	Local $iX2 = $g_aResultArea[2]
	Local $iY2 = $g_aResultArea[3]

	Local $iColRed = Number(GUICtrlRead($g_hInput_BankerColor))
	Local $iColBlue = Number(GUICtrlRead($g_hInput_PlayerColor))
	Local $iColGreen = Number(GUICtrlRead($g_hInput_TieColor))
	Local $iShade = Number(GUICtrlRead($g_hInput_Shade_Result))
	If $iShade < 40 Then $iShade = 40 ; Ép dung sai tối thiểu 40 để bắt chớp nháy dễ hơn

	Local $sFoundResult = ""

	_UpdateStatus("⏳ Bàn " & ($g_iCurrentTableIndex + 1) & ": Đang rình Dealer lật bài...")

	; =========================================================
	; 1. RÌNH BÀI LẬT LÊN (Quét trong khung chữ nhật X1,Y1 - X2,Y2)
	; =========================================================
While $g_bIsRunning
		_ProcessGUIMessages()

		; >>> HIỂN THỊ TOOLTIP THEO DÕI <<<
		ToolTip("ĐANG RÌNH KẾT QUẢ...", 10, 10, "Radar Quét")

		; Dùng PixelSearch để quét toàn bộ vùng chữ nhật
		If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColRed, $iShade, 1, $hWnd)) Then
			$sFoundResult = "B"
			ExitLoop
		ElseIf IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColBlue, $iShade, 1, $hWnd)) Then
			$sFoundResult = "P"
			ExitLoop
		; ---> CHẶN MÀU HÒA (XANH LÁ) KHI CHƠI XÓC ĐĨA <---
		ElseIf (GUICtrlRead($g_hCheckbox_XocDiaVIP) <> $GUI_CHECKED) And IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColGreen, $iShade, 1, $hWnd)) Then
			$sFoundResult = "T"
			ExitLoop
		EndIf

		Sleep(50) ; Quét liên tục không gây lag
	WEnd
	ToolTip("") ; Tắt ToolTip khi thấy kết quả

	If Not $g_bIsRunning Then Return ""
	_UpdateStatus("⚡ Đã thấy kết quả [" & $sFoundResult & "]. Đợi thu dọn bài để cược...")

	; =========================================================
	; 2. ĐỢI BÀI BIẾN MẤT (Chờ màu biến mất hoàn toàn khỏi khung)
	; =========================================================
While $g_bIsRunning
		_ProcessGUIMessages()

		Local $bRedGone = Not IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColRed, $iShade, 1, $hWnd))
		Local $bBlueGone = Not IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColBlue, $iShade, 1, $hWnd))
		Local $bGreenGone = True ; Mặc định là True (không quan tâm màu xanh) khi chơi Xóc đĩa

		; Nếu KHÔNG PHẢI Xóc Đĩa thì mới thèm kiểm tra xem màu Xanh Lá đã biến mất chưa
		If GUICtrlRead($g_hCheckbox_XocDiaVIP) <> $GUI_CHECKED Then
			$bGreenGone = Not IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColGreen, $iShade, 1, $hWnd))
		EndIf

		; Nếu quét cả khung mà không ra 3 màu kia nữa nghĩa là popup đã dọn đi
		If $bRedGone And $bBlueGone And $bGreenGone Then
			ExitLoop
		EndIf

		Sleep(50)
	WEnd
	Return $sFoundResult
EndFunc   ;==>_ScanPopupResult_PP
; Hàm phụ trợ: Xác minh đó là "mảng màu đặc" của ô kết quả, chứ không phải "nét chữ/chấm bài"
Func _ScanForSolidBlock($iX1, $iY1, $iX2, $iY2, $iColor, $iShade)
	; Quét từ dưới lên trên (Step -5), trái qua phải (Step 5)
	For $y = $iY2 To $iY1 Step -5
		For $x = $iX1 To $iX2 Step 5
			Local $c = PixelGetColor($x, $y) ; ĐÃ BỎ $hWnd
			If _CheckColorRange($c, $iColor, $iShade) Then
				; Kiểm tra mảng màu to (Cũng bỏ $hWnd)
				Local $c1 = PixelGetColor($x + 8, $y)
				Local $c2 = PixelGetColor($x, $y - 8)
				Local $c3 = PixelGetColor($x + 8, $y - 8)

				Local $iMatch = 0
				If _CheckColorRange($c1, $iColor, $iShade) Then $iMatch += 1
				If _CheckColorRange($c2, $iColor, $iShade) Then $iMatch += 1
				If _CheckColorRange($c3, $iColor, $iShade) Then $iMatch += 1

				If $iMatch >= 2 Then Return True
			EndIf
		Next
	Next
	Return False
EndFunc   ;==>_ScanForSolidBlock
Func _CalculateAndSetTableCoords($iTableIndex)
    If $iTableIndex == 0 Then
        _GetAndValidateInputs()
        Return True
    EndIf

    Local $iAnchor1X = Number(GUICtrlRead($g_aInput_AnchorX[0]))
    Local $iAnchor1Y = Number(GUICtrlRead($g_aInput_AnchorY[0]))
    Local $iAnchorTargetX = Number(GUICtrlRead($g_aInput_AnchorX[$iTableIndex]))
    Local $iAnchorTargetY = Number(GUICtrlRead($g_aInput_AnchorY[$iTableIndex]))

    If $iAnchor1X = 0 Or $iAnchorTargetX = 0 Then Return False

    Local $iOffsetX = $iAnchorTargetX - $iAnchor1X
    Local $iOffsetY = $iAnchorTargetY - $iAnchor1Y

    $g_aBankerButtonPos[0] = Number(GUICtrlRead($g_hInput_BankerX)) + $iOffsetX
    $g_aBankerButtonPos[1] = Number(GUICtrlRead($g_hInput_BankerY)) + $iOffsetY

    $g_aPlayerButtonPos[0] = Number(GUICtrlRead($g_hInput_PlayerX)) + $iOffsetX
    $g_aPlayerButtonPos[1] = Number(GUICtrlRead($g_hInput_PlayerY)) + $iOffsetY

    $g_aTieButtonPos[0] = Number(GUICtrlRead($g_hInput_TieX)) + $iOffsetX
    $g_aTieButtonPos[1] = Number(GUICtrlRead($g_hInput_TieY)) + $iOffsetY

    $g_aResultArea[0] = Number(GUICtrlRead($g_hInput_ResultX1)) + $iOffsetX
    $g_aResultArea[1] = Number(GUICtrlRead($g_hInput_ResultY1)) + $iOffsetY
    $g_aResultArea[2] = Number(GUICtrlRead($g_hInput_ResultX2)) + $iOffsetX
    $g_aResultArea[3] = Number(GUICtrlRead($g_hInput_ResultY2)) + $iOffsetY

    $g_aBetTimeIndicatorArea[0] = Number(GUICtrlRead($g_hInput_BetTimeX1)) + $iOffsetX
    $g_aBetTimeIndicatorArea[1] = Number(GUICtrlRead($g_hInput_BetTimeY1)) + $iOffsetY
    $g_aBetTimeIndicatorArea[2] = Number(GUICtrlRead($g_hInput_BetTimeX2)) + $iOffsetX
    $g_aBetTimeIndicatorArea[3] = Number(GUICtrlRead($g_hInput_BetTimeY2)) + $iOffsetY

    Return True
EndFunc

Func _HandleSequentialTableSwitching()
    If GUICtrlRead($g_hCheckbox_DuKichDaBan) <> $GUI_CHECKED Then Return False

    Local $iTargetWin = Number(GUICtrlRead($g_hInput_DuKich_WinTable))
    Local $iTargetLoss = -1 * Number(GUICtrlRead($g_hInput_DuKich_LossTable))

    If $g_iTableProfit_Units >= $iTargetWin Or $g_iTableProfit_Units <= $iTargetLoss Then
        Local $sReason = ($g_iTableProfit_Units >= $iTargetWin) ? "CHỐT LỜI BÀN" : "CẮT LỖ BÀN"
        _UpdateStatus("🔄 " & $sReason & " " & ($g_iCurrentTableIndex + 1) & " (" & $g_iTableProfit_Units & " đơn vị). Chuyển Bàn...")

        ReDim $g_aDisplayHistory[0]
        $g_iHistoryCutoffIndex = 0
        $g_iTotalBanker = 0
        $g_iTotalPlayer = 0
        $g_iTotalTie = 0
        $g_iCapitalLevel = 0
        $g_iLastActiveRuleIndex = -1
        $g_iTableProfit_Units = 0
        _RedrawHistory()

        $g_iCurrentTableIndex += 1

        If $g_iCurrentTableIndex > 11 Then
            Local $iRestMins = Number(GUICtrlRead($g_hInput_DuKich_RestTime))
            _UpdateStatus("💤 Đã hoàn tất 12 bàn! Tool ngủ đông " & $iRestMins & " phút...")
            Sleep($iRestMins * 60000)
            $g_iCurrentTableIndex = 0
            _UpdateStatus("🚀 Hết giờ nghỉ! Tái khởi động vòng 12 bàn mới...")
        EndIf

        _CalculateAndSetTableCoords($g_iCurrentTableIndex)
        _UpdateStatus("✅ Đã ngắm trúng Bàn " & ($g_iCurrentTableIndex + 1) & ". Đang rình...")
        Return True
    EndIf
    Return False
EndFunc

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

		; Luôn quét Xanh (P/Lẻ) và Đỏ (B/Chẵn)
		If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColBlue, $iShade, 1, $hWnd)) Then Return "P"
		If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColRed, $iShade, 1, $hWnd)) Then Return "B"

		; CHỈ quét màu Xanh Lá (Hòa) nếu KHÔNG PHẢI đang chơi Xóc Đĩa VIP
		If GUICtrlRead($g_hCheckbox_XocDiaVIP) <> $GUI_CHECKED Then
			If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColGreen, $iShade, 1, $hWnd)) Then Return "T"
		EndIf

		Sleep(20)
	WEnd
	Return ""
EndFunc
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
    If $iShade > 25 Then $iShade = 25 ; Ép dung sai thấp xuống lúc chờ biến mất để tránh quét rác

    _UpdateStatus("🧹 [SYSTEM] Bài đang hiển thị. Đợi thu dọn bàn sạch sẽ để chốt vòng lặp...")

    Local $hDisappearTimer = TimerInit()
    Local $bIsXocDia = (GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED)

    While $g_bIsRunning
        _ProcessGUIMessages()
        Local $bStillThere = False

        ; Luôn quét màu Đỏ (Chẵn) và Xanh (Lẻ)
        If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColBlue, $iShade, 1, $hWnd)) Then $bStillThere = True
        If Not $bStillThere And IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColRed, $iShade, 1, $hWnd)) Then $bStillThere = True

        ; CHỈ quét màu Hòa (Xanh Lá) nếu KHÔNG PHẢI chơi Xóc Đĩa
        If Not $bIsXocDia And Not $bStillThere Then
            If IsArray(PixelSearch($iX1, $iY1, $iX2, $iY2, $iColGreen, $iShade, 1, $hWnd)) Then $bStillThere = True
        EndIf

        If $bStillThere Then
            ; Nếu màu vẫn còn -> Reset đồng hồ
            $hDisappearTimer = TimerInit()
        Else
            ; Nếu ĐÃ SẠCH MÀU -> Đợi 1 giây để dứt điểm popup không bị chớp nháy
            If TimerDiff($hDisappearTimer) > 1000 Then
                Return True
            EndIf
        EndIf

        Sleep(50)
    WEnd
    Return False
EndFunc
Func _IsLargeObject($hWnd, $X, $Y, $iColor, $iShade, $iSize)
	Local $cRight = PixelGetColor($X + $iSize, $Y, $hWnd)
	Local $cDown  = PixelGetColor($X, $Y + $iSize, $hWnd)
	Local $cDiag  = PixelGetColor($X + $iSize, $Y + $iSize, $hWnd)

	Local $bRight = _CheckColorRange($cRight, $iColor, $iShade)
	Local $bDown  = _CheckColorRange($cDown, $iColor, $iShade)
	Local $bDiag  = _CheckColorRange($cDiag, $iColor, $iShade)

	Local $iMatch = 0
	If $bRight Then $iMatch += 1
	If $bDown  Then $iMatch += 1
	If $bDiag  Then $iMatch += 1

	Return ($iMatch >= 1)
EndFunc
; --- HÀM 3: BỘ LỌC KÍCH THƯỚC VẬT THỂ ---
Func _TestCurrentTableZones()
    Local $hDC = _WinAPI_GetDC(0)
    Local $hPenRes = _WinAPI_CreatePen($PS_SOLID, 3, 0x0000FF) ; Khung Đỏ (KQ)
    Local $hPenTime = _WinAPI_CreatePen($PS_SOLID, 3, 0x00FF00) ; Khung Xanh Lá (Giờ Cược)
    Local $hOldPen = _WinAPI_SelectObject($hDC, $hPenRes)
    _WinAPI_SelectObject($hDC, _WinAPI_GetStockObject($NULL_BRUSH)) ; Rỗng ruột

    ; 1. Vẽ Vùng Kết Quả (Đỏ) - Đóng gói vào biến RECT Struct
    Local $tRectRes = _WinAPI_CreateRectEx($g_aResultArea[0], $g_aResultArea[1], $g_aResultArea[2], $g_aResultArea[3])
    _WinAPI_Rectangle($hDC, $tRectRes)

    ; 2. Vẽ Vùng Giờ Cược (Xanh lá) - Đóng gói vào biến RECT Struct
    _WinAPI_SelectObject($hDC, $hPenTime)
    Local $tRectTime = _WinAPI_CreateRectEx($g_aBetTimeIndicatorArea[0], $g_aBetTimeIndicatorArea[1], $g_aBetTimeIndicatorArea[2], $g_aBetTimeIndicatorArea[3])
    _WinAPI_Rectangle($hDC, $tRectTime)

    ; Dọn dẹp
    _WinAPI_SelectObject($hDC, $hOldPen)
    _WinAPI_DeleteObject($hPenRes)
    _WinAPI_DeleteObject($hPenTime)
    _WinAPI_ReleaseDC(0, $hDC)

    _UpdateStatus("🔍 TEST TỌA ĐỘ BÀN " & ($g_iCurrentTableIndex + 1) & ": Khung Đỏ (KQ), Khung Xanh (Giờ cược)")
EndFunc
Func _HuntForNewShoeTable()
	_UpdateStatus("🔍 Đang khởi động Radar tìm BÀN MỚI (Trắng cầu)...")

	; Đọc mã màu RIÊNG BIỆT của Radar (Nếu quên lấy, tự động dự phòng bằng màu KQ cũ)
	Local $iColRadarRed = Number(GUICtrlRead($g_hInput_RadarRed))
	If $iColRadarRed == 0 Then $iColRadarRed = Number(GUICtrlRead($g_hInput_BankerColor))

	Local $iColRadarBlue = Number(GUICtrlRead($g_hInput_RadarBlue))
	If $iColRadarBlue == 0 Then $iColRadarBlue = Number(GUICtrlRead($g_hInput_PlayerColor))

	Local $iColGreen = Number(GUICtrlRead($g_hInput_TieColor))

	Local $iRadarShade = 20 ; Dung sai cực kỳ an toàn vì màu đã được khóa chuẩn

	Local $iBaseCellX = Number(GUICtrlRead($g_hInput_FirstCellX))
	Local $iBaseCellY = Number(GUICtrlRead($g_hInput_FirstCellY))

	If $iBaseCellX = 0 Or $iBaseCellY = 0 Then
		_UpdateStatus("⚠️ Lỗi: Sếp chưa lấy tọa độ Ô Cầu Đầu Tiên (Bàn 1) cho tính năng Săn Bàn Mới!")
		Return -1
	EndIf

	Local $iBoxSize = 15 ; Khung quét 30x30 pixel

	While $g_bIsRunning
		If $g_hTargetGameWin <> 0 And WinExists($g_hTargetGameWin) Then
			WinActivate($g_hTargetGameWin)
			Sleep(300)
		EndIf

		For $i = 0 To 11
			_CalculateAndSetTableCoords($i)

			Local $iAnchor1X = Number(GUICtrlRead($g_aInput_AnchorX[0]))
			Local $iAnchor1Y = Number(GUICtrlRead($g_aInput_AnchorY[0]))
			Local $iAnchorTargetX = Number(GUICtrlRead($g_aInput_AnchorX[$i]))
			Local $iAnchorTargetY = Number(GUICtrlRead($g_aInput_AnchorY[$i]))

			Local $iTargetCellX = $iBaseCellX + ($iAnchorTargetX - $iAnchor1X)
			Local $iTargetCellY = $iBaseCellY + ($iAnchorTargetY - $iAnchor1Y)

			Local $iStartX = $iTargetCellX - $iBoxSize
			Local $iStartY = $iTargetCellY - $iBoxSize
			Local $iEndX = $iTargetCellX + $iBoxSize
			Local $iEndY = $iTargetCellY + $iBoxSize

			Local $bIsEmpty = True
			For $k = 1 To 3
				Local $bHasColor = False

				; Dùng màu Radar riêng biệt để đối chiếu
				If IsArray(PixelSearch($iStartX, $iStartY, $iEndX, $iEndY, $iColRadarRed, $iRadarShade, 1)) Then $bHasColor = True
				If Not $bHasColor And IsArray(PixelSearch($iStartX, $iStartY, $iEndX, $iEndY, $iColRadarBlue, $iRadarShade, 1)) Then $bHasColor = True
				If Not $bHasColor And IsArray(PixelSearch($iStartX, $iStartY, $iEndX, $iEndY, $iColGreen, $iRadarShade, 1)) Then $bHasColor = True

				If $bHasColor Then
					$bIsEmpty = False
					ExitLoop
				EndIf
				Sleep(300)
			Next

			If $bIsEmpty Then
				$g_iCurrentTableIndex = $i
				_UpdateStatus("🎯 Phát hiện Bàn " & ($i + 1) & " là BÀN MỚI! Khóa mục tiêu.")

				ReDim $g_aDisplayHistory[0]
				$g_iHistoryCutoffIndex = 0
				$g_iCapitalLevel = 0
				$g_iLastActiveRuleIndex = -1
				$g_fTableProfit_RealUnits = 0.0
				_RedrawHistory()

				Return $i
			EndIf
		Next

		_UpdateStatus("⏳ 12 bàn đều đang có cầu dở dang. Chờ 15s rồi lùng lại...")
		Sleep(15000)
	WEnd
	Return -1
EndFunc
Func _TestRadarZones()
	Local $hDC = _WinAPI_GetDC(0)
	; Tạo bút vẽ màu Tím (0xFF00FF) độ dày 3 pixel
	Local $hPenRadar = _WinAPI_CreatePen(0, 3, 0xFF00FF)
	Local $hOldPen = _WinAPI_SelectObject($hDC, $hPenRadar)

	Local $iBaseCellX = Number(GUICtrlRead($g_hInput_FirstCellX))
	Local $iBaseCellY = Number(GUICtrlRead($g_hInput_FirstCellY))

	If $iBaseCellX = 0 Or $iBaseCellY = 0 Then
		MsgBox(48, "Lỗi Test", "Sếp chưa lấy tọa độ Ô Cầu Đầu Tiên ở Bàn 1!")
		_WinAPI_SelectObject($hDC, $hOldPen)
		_WinAPI_DeleteObject($hPenRadar)
		_WinAPI_ReleaseDC(0, $hDC)
		Return
	EndIf

	Local $iBoxSize = 15 ; Khung 30x30 (15 pixel mỗi bên)

	; Vẽ 12 ô vuông tương ứng 12 bàn
	For $i = 0 To 11
		_CalculateAndSetTableCoords($i)

		Local $iAnchor1X = Number(GUICtrlRead($g_aInput_AnchorX[0]))
		Local $iAnchor1Y = Number(GUICtrlRead($g_aInput_AnchorY[0]))
		Local $iAnchorTargetX = Number(GUICtrlRead($g_aInput_AnchorX[$i]))
		Local $iAnchorTargetY = Number(GUICtrlRead($g_aInput_AnchorY[$i]))

		Local $iTargetCellX = $iBaseCellX + ($iAnchorTargetX - $iAnchor1X)
		Local $iTargetCellY = $iBaseCellY + ($iAnchorTargetY - $iAnchor1Y)

		; Tính toán 4 góc
		Local $iLeft = $iTargetCellX - $iBoxSize
		Local $iTop = $iTargetCellY - $iBoxSize
		Local $iRight = $iTargetCellX + $iBoxSize
		Local $iBottom = $iTargetCellY + $iBoxSize

		; Vẽ 4 cạnh thủ công (Cách này an toàn tuyệt đối, không bao giờ lỗi Struct)
		_WinAPI_MoveTo($hDC, $iLeft, $iTop)
		_WinAPI_LineTo($hDC, $iRight, $iTop)      ; Cạnh trên
		_WinAPI_LineTo($hDC, $iRight, $iBottom)   ; Cạnh phải
		_WinAPI_LineTo($hDC, $iLeft, $iBottom)    ; Cạnh dưới
		_WinAPI_LineTo($hDC, $iLeft, $iTop)       ; Cạnh trái
	Next

	_WinAPI_SelectObject($hDC, $hOldPen)
	_WinAPI_DeleteObject($hPenRadar)
	_WinAPI_ReleaseDC(0, $hDC)

	_UpdateStatus("🔍 TEST X-QUANG: Đã vẽ 12 ô vuông Tím quanh các điểm Radar săn bàn!")
EndFunc
; =====================================================================
; HÀM DI CHUYỂN CHUỘT MA (MÔ PHỎNG NGƯỜI THẬT)
; =====================================================================
Func _MouseMove_Human($iStartX, $iStartY, $iEndX, $iEndY, $iSteps = 40)
	; Tạo 2 điểm neo ngẫu nhiên (Control Points) để làm cong đường đi
	Local $iCtrl1X = $iStartX + Random(-150, 150, 1) + ($iEndX - $iStartX) / 3
	Local $iCtrl1Y = $iStartY + Random(-150, 150, 1) + ($iEndY - $iStartY) / 3
	Local $iCtrl2X = $iStartX + Random(-150, 150, 1) + ($iEndX - $iStartX) * 2 / 3
	Local $iCtrl2Y = $iStartY + Random(-150, 150, 1) + ($iEndY - $iStartY) * 2 / 3

	; Di chuyển dọc theo đường cong Bezier
	For $i = 1 To $iSteps
		Local $t = $i / $iSteps
		Local $u = 1 - $t
		Local $tt = $t * $t
		Local $uu = $u * $u
		Local $uuu = $uu * $u
		Local $ttt = $tt * $t

		; Tính toán tọa độ x, y từng bước
		Local $pX = $uuu * $iStartX + 3 * $uu * $t * $iCtrl1X + 3 * $u * $tt * $iCtrl2X + $ttt * $iEndX
		Local $pY = $uuu * $iStartY + 3 * $uu * $t * $iCtrl1Y + 3 * $u * $tt * $iCtrl2Y + $ttt * $iEndY

		MouseMove($pX, $pY, 0) ; Di chuyển tức thì đến điểm ảnh kế tiếp

		; Tốc độ biến thiên: Chậm ở 2 đầu, lướt nhanh ở giữa
		Local $iDelay = Random(1, 3, 1)
		If $i < ($iSteps / 5) Or $i > ($iSteps * 4 / 5) Then $iDelay = Random(4, 8, 1)

		Sleep($iDelay)
	Next

	; Đảm bảo điểm đáp cuối cùng chính xác 100% vào tâm phỉnh
	MouseMove($iEndX, $iEndY, 0)
EndFunc
Func _RealTimeCurrencyFormat($hInput)
	Local $sText = GUICtrlRead($hInput)
	If $sText == "" Or $sText == "-" Then Return

	Local $bIsNegative = (StringLeft($sText, 1) == "-")
	Local $sRaw = StringRegExpReplace($sText, "[^0-9]", "")
	If $sRaw == "" Then Return

	Local $sNew = StringRegExpReplace(String(Int($sRaw)), '(\d)(?=(\d{3})+(?!\d))', '$1.')
	If $bIsNegative Then $sNew = "-" & $sNew

	If $sText <> $sNew Then
		GUICtrlSetData($hInput, $sNew)
		; Ép con trỏ chuột (cursor) nhảy về cuối cùng để gõ liên tục không bị ngược
		GUICtrlSendMsg($hInput, 0x00B1, StringLen($sNew), StringLen($sNew))
		$g_bNeedAutoSave = True
		$g_hAutoSaveTimer = TimerInit()
	EndIf
EndFunc
Func _ApplyCustomerFeatures()
    ; 1. NẾU LÀ ADMIN -> HIỆN TẤT CẢ VÀ ĐỔI NÚT THÀNH XANH LÁ
    If StringUpper($g_sCustomerRole) == "ADMIN" Then
        _ToggleTechRoom($GUI_SHOW)
        _ToggleConfigControlsState(True)  ; <--- THÊM DÒNG NÀY CHO ADMIN

        GUICtrlSetData($g_hButton_Unlock, "🔓 KHÓA LẠI")
        GUICtrlSetBkColor($g_hButton_Unlock, 0x33CC33)
        Return
    EndIf

    ; =========================================================
    ; 2. QUÉT TÌM TOÀN BỘ SẢNH CỦA RIÊNG KHÁCH HÀNG NÀY
    ; =========================================================
    Local $sUsername = $g_sCustomerLogin ; Ví dụ: thuydung
    Local $aAllSections = IniReadSectionNames($g_sIniPath) ; Đọc toàn bộ file config
    Local $sUserProfiles = "|" ; Dấu | ở đầu để xóa sạch menu cũ
    Local $sFirstProfileToLoad = ""
    Local $iProfileCount = 0

    If Not @error Then
        ; Chạy vòng lặp kiểm tra từng sảnh trong file config
        For $i = 1 To $aAllSections[0]
            ; Nếu tên sảnh có chứa chữ "Profile_thuydung_"
            If StringInStr($aAllSections[$i], "Profile_" & $sUsername & "_") = 1 Then
                ; Cắt bỏ chữ "Profile_" đi cho đẹp, chỉ lấy "thuydung_EvoVIP"
                Local $sCleanName = StringReplace($aAllSections[$i], "Profile_", "")

                $sUserProfiles &= $sCleanName & "|"
                If $sFirstProfileToLoad == "" Then $sFirstProfileToLoad = $sCleanName
                $iProfileCount += 1
            EndIf
        Next
    EndIf

    ; =========================================================
    ; 3. CẤP PHÁT GIAO DIỆN DỰA TRÊN KẾT QUẢ TÌM ĐƯỢC
    ; =========================================================
If $iProfileCount > 0 Then
        ; Nếu tìm thấy sảnh: Nhét toàn bộ danh sách vào Menu
        GUICtrlSetData($g_hCombo_Profiles_Main, $sUserProfiles, $sFirstProfileToLoad)

        ; MỞ KHÓA MENU CHO KHÁCH TỰ DO CHỌN SẢNH
        GUICtrlSetState($g_hCombo_Profiles_Main, $GUI_ENABLE)

        ; Tự động nạp sảnh đầu tiên trong danh sách lên giao diện
        _LoadSelectedProfile($sFirstProfileToLoad)

        ; Chạy bộ máy Ẩn/Hiện giao diện (đã được vá lỗi né Xóc Đĩa ở bước 1)
        _ExecuteHideShow()

		; ---> ÉP QUÉT LẠI GIAO DIỆN LẦN CUỐI ĐỂ DỌN SẠCH BÓNG MA CHỒNG CHÉO <---
		_ToggleGameModeUI()

        _UpdateStatus("✅ Đã tải thành công " & $iProfileCount & " cấu hình dành riêng cho: " & $sUsername)
Else
        ; Nếu khách mới toanh chưa có sảnh nào
        GUICtrlSetState($g_hCombo_Profiles_Main, $GUI_DISABLE)
        MsgBox(48, "Thông báo", "Tài khoản của bạn hiện chưa có Cấu hình/Sảnh game nào." & @CRLF & "Vui lòng liên hệ Admin để được cấp phát!")
        Exit
    EndIf

; 4. CHỐT CHẶN CUỐI CÙNG CHO KHÁCH HÀNG
    _ToggleTechRoom($GUI_HIDE)
    _ToggleConfigControlsState(False) ; <--- THÊM DÒNG NÀY ĐỂ KHÓA ĐỐI VỚI KHÁCH

    GUICtrlSetData($g_hButton_Unlock, "🔐 MỞ KHÓA")
    GUICtrlSetBkColor($g_hButton_Unlock, 0xFF4141)
EndFunc
Func _CheckLoginOnline($sUsername, $sHWID)
    Local $sUrl = $g_sAppsScriptBaseURL & "?action=check_login&username=" & $sUsername & "&hwid=" & $sHWID & "&nocache=" & TimerInit()
    Local $sData = BinaryToString(InetRead($sUrl, 3), 4)

    Local $oJson = Json_Decode($sData)
    Local $sStatus = Json_Get($oJson, "[status]")

; 1. Bắt lỗi sai tên hoặc bị khóa từ Server trả về
    If $sStatus == "ERROR" Then
        Local $sMsg = Json_Get($oJson, "[msg]")
        ; Báo lỗi và nhắc khách copy HWID
        MsgBox(16, "Lỗi đăng nhập", $sMsg & @CRLF & @CRLF & "Mã máy của bạn: " & $sHWID & @CRLF & "Vui lòng copy mã này gửi cho Admin để được cấp quyền!")
        Return False
    EndIf
    ; 2. Lấy mã quyền (Dữ liệu từ cột NOTE)
    $g_sCustomerRole = StringStripWS(Json_Get($oJson, "[role]"), 3)

    ; 3. CHỈ KIỂM TRA RỖNG (Không khóa cứng tên gói nữa để tool tự do nhận tên sảnh)
    If $g_sCustomerRole == "" Then
        MsgBox(16, "Lỗi hệ thống", "Tài khoản này chưa được điền quyền ở cột NOTE trên Google Sheets!")
        Return False
    EndIf

    Return True
EndFunc
Func _ExecuteHideShow()
    ; Ép hiển thị luôn các ô Chốt Lời / Cắt Lỗ Tổng cho khách hàng thấy
    GUICtrlSetState($g_hInput_DailyTarget, $GUI_SHOW)
    GUICtrlSetState($g_hInput_DailyTrailing, $GUI_SHOW)
    GUICtrlSetState($g_hInput_DailyStopLoss, $GUI_SHOW)
    GUICtrlSetState($g_hCheckbox_DailyShield, $GUI_SHOW)

    ; ---> CHỐT CHẶN BẢO VỆ GIAO DIỆN XÓC ĐĨA <---
    If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
        Return ; Nếu khách đang chạy Xóc Đĩa VIP thì dừng hàm ở đây, để hệ thống Xóc đĩa tự quản lý hiển thị
    EndIf

    ; Giữ lại các lệnh hiển thị cũ (Chỉ chạy khi khách dùng Baccarat)
    If StringStripWS(GUICtrlRead($g_hInput_CustomRules), 8) == "" Then
        GUICtrlSetState($g_hInput_CustomRules, $GUI_HIDE)
    Else
        GUICtrlSetState($g_hInput_CustomRules, $GUI_SHOW)
    EndIf

    GUICtrlSetState($g_hInput_CustomQLV_Edit, $GUI_SHOW)
    GUICtrlSetState($g_hCombo_QLV_Presets, $GUI_SHOW)
    GUICtrlSetState($g_hButton_SaveQLV, $GUI_SHOW)
    GUICtrlSetState($g_hButton_DeleteQLV, $GUI_SHOW)
EndFunc
; Hàm phụ trợ ép lệnh HIDE/SHOW siêu tốc (Nâng cấp tối đa 20 biến)
Func _ToggleHideShow($iIndex, $c1=0, $c2=0, $c3=0, $c4=0, $c5=0, $c6=0, $c7=0, $c8=0, $c9=0, $c10=0, $c11=0, $c12=0, $c13=0, $c14=0, $c15=0, $c16=0, $c17=0, $c18=0, $c19=0, $c20=0)
    Local $iState = $GUI_SHOW
    ; Nếu Admin có đánh dấu tích vào bảng ở dòng thứ $iIndex -> Chuyển trạng thái thành HIDE
    If _GUICtrlListView_GetItemChecked($g_hAdminHideList, $iIndex) Then $iState = $GUI_HIDE

    Local $aControls[20] = [$c1, $c2, $c3, $c4, $c5, $c6, $c7, $c8, $c9, $c10, $c11, $c12, $c13, $c14, $c15, $c16, $c17, $c18, $c19, $c20]

    For $i = 0 To 19
        If $aControls[$i] <> 0 And $aControls[$i] <> "" Then GUICtrlSetState($aControls[$i], $iState)
    Next
EndFunc
Func _ToggleTechRoom($iState)
	For $i = $g_iTechTabStart To $g_iTechTabEnd
		; Không được ẩn chính 2 cái cột mốc Dummy đi (Gây lỗi vòng lặp)
		If $i <> $g_iTechTabStart And $i <> $g_iTechTabEnd Then
			GUICtrlSetState($i, $iState)
		EndIf
	Next
EndFunc

Func _Logic_XocDia_5Hang_VIP($sHistoryRaw)
    Local $aResult[3] = ["OBSERVE", "", 0]
    Local $sHist = StringRegExpReplace($sHistoryRaw, "[^CL]", "")
    Local $iLen = StringLen($sHist)

    If $iLen < 4 Then
        _UpdateStatus("📡 [HỆ THỐNG] Đang lấy mẫu (" & $iLen & "/4 tay). Lịch sử hiện hành: [" & $sHist & "]")
        Return $aResult
    EndIf

    Local $sTarget = StringMid($sHist, $iLen - 3, 1)
	Local $sKhung4Tay = StringRight($sHist, 4)
	_UpdateStatus("🎯 [PHÂN TÍCH] Khuôn 4 tay: [" & $sKhung4Tay & "] -> Luật bảo toàn tỷ lệ: Đánh [" & $sTarget & "]")

    Local $iCurrentStep = $g_aTierStep[$g_iCurrentTier]
    Local $iMaxLimit = $g_aXD_MaxStepsPerRow[$g_iCurrentTier] ; Lấy kịch kim của riêng hàng này

    If $iCurrentStep > $iMaxLimit Then
        _UpdateStatus("⚠️ [CẮT LỖ] Chạm mốc gãy kịch kim " & $iMaxLimit & " tay của Hàng " & $g_iCurrentTier & "! Reset toàn bộ nợ về H1 B1.")
        For $i = 1 To 10
            $g_aTierStep[$i] = 1
        Next
        $g_iCurrentTier = 1
        $iCurrentStep = 1
    EndIf

    Local $iBetAmount = $g_aXocDia_Seq[$g_iCurrentTier][$iCurrentStep] ; Lấy tiền từ mảng 2 chiều

    Local $sDebtLog = ""
    If $g_iCurrentTier > 1 Then
        $sDebtLog = " (Hàng trên H" & ($g_iCurrentTier - 1) & " nợ B" & $g_aTierStep[$g_iCurrentTier - 1] & ")"
    Else
        $sDebtLog = " (Đỉnh Hàng 1, không nợ)"
    EndIf

    _UpdateStatus("💰 [VỐN] HÀNG " & $g_iCurrentTier & " (Lệnh x" & $iCurrentStep & ")" & $sDebtLog)

    $aResult[0] = "BET"
    $aResult[1] = $sTarget
    $aResult[2] = $iBetAmount

    If $iBetAmount > 0 Then
        If $iBetAmount > 500000 Then
            _SwitchLimit_VIP("20-50K")
        Else
            _SwitchLimit_VIP("10-500")
        EndIf
        _UpdateStatus("💸 [VÀO TIỀN] Cược " & _FormatNumber($iBetAmount) & "đ vào [" & $sTarget & "]")
        GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: HÀNG " & $g_iCurrentTier & " - BƯỚC " & $g_aTierStep[$g_iCurrentTier] & @CRLF & "💰 Sẵn sàng ném: " & _FormatNumber($iBetAmount) & "đ VÀO [" & $sTarget & "]")
    Else
        _UpdateStatus("💸 [VÀO TIỀN] ĐÁNH NHÁP TAY " & $iCurrentStep & " (Không ném chip) vào [" & $sTarget & "]")
        GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: HÀNG " & $g_iCurrentTier & " - BƯỚC " & $g_aTierStep[$g_iCurrentTier] & @CRLF & "💰 Sẵn sàng: ĐÁNH NHÁP VÀO [" & $sTarget & "]")
    EndIf

    _UpdateXocDiaGridUI()
    Return $aResult
EndFunc
Func _ProcessOutcome_XocDia_VIP($sActualResult, $sBetOn)
    Local $bIsWin = ($sActualResult == $sBetOn)
    Local $iTargetRows = Number(GUICtrlRead($g_hInput_XD_MaxRows))
    If $iTargetRows < 1 Then $iTargetRows = 1
    If $iTargetRows > 10 Then $iTargetRows = 10

    If $bIsWin Then
        $g_fXD_CycleProfit += ($g_fCurrentBet * 0.95)
    Else
        $g_fXD_CycleProfit -= $g_fCurrentBet
    EndIf

    If $bIsWin Then
        $g_aTierStep[$g_iCurrentTier] = 1

        If GUICtrlRead($g_hCheckbox_XD_LowDebtPriority) == $GUI_CHECKED Then
            Local $iMinStep = 9999
            Local $iBestTier = 1
            For $i = 1 To $iTargetRows
                If $g_aTierStep[$i] < $iMinStep Then
                    $iMinStep = $g_aTierStep[$i]
                    $iBestTier = $i
                EndIf
            Next
            $g_iCurrentTier = $iBestTier
            _UpdateStatus("✅ [KẾT QUẢ] Húp! -> Xóa nợ. [Tìm Nợ Thấp] Chuyển sang Hàng " & $g_iCurrentTier & " đánh tiếp.")
        Else
            $g_iCurrentTier = 1
            _UpdateStatus("✅ [KẾT QUẢ] Húp! -> Xóa nợ hàng vừa đánh. Trở về Hàng 1, Bước 1.")
        EndIf
    Else
        $g_aTierStep[$g_iCurrentTier] += 1

        If GUICtrlRead($g_hCheckbox_XD_LowDebtPriority) == $GUI_CHECKED Then
            Local $iMinStep = 9999
            Local $iBestTier = 1
            For $i = 1 To $iTargetRows
                If $g_aTierStep[$i] < $iMinStep Then
                    $iMinStep = $g_aTierStep[$i]
                    $iBestTier = $i
                EndIf
            Next
            $g_iCurrentTier = $iBestTier
            _UpdateStatus("❌ [KẾT QUẢ] Gãy! -> [Tìm Nợ Thấp] Chuyển sang Hàng " & $g_iCurrentTier & " (Đang nợ Bước " & $g_aTierStep[$g_iCurrentTier] & ").")
        Else
            If $g_iCurrentTier < $iTargetRows Then
                $g_iCurrentTier += 1
                _UpdateStatus("❌ [KẾT QUẢ] Gãy! -> [Tuần Tự] Lùi xuống Hàng " & $g_iCurrentTier & " (Đang nợ Bước " & $g_aTierStep[$g_iCurrentTier] & ").")
            Else
                _UpdateStatus("❌ [KẾT QUẢ] Gãy! -> [Chạm Đáy] Hết hàng lùi. Ở lại Hàng " & $iTargetRows & " gấp thếp lên Bước " & $g_aTierStep[$g_iCurrentTier] & ".")
            EndIf
        EndIf
    EndIf

    ; SỬ DỤNG SỨC CHỊU ĐỰNG RIÊNG CỦA TỪNG HÀNG
    Local $iMaxLimit = $g_aXD_MaxStepsPerRow[$g_iCurrentTier]
    If $g_aTierStep[$g_iCurrentTier] > $iMaxLimit Then
        _UpdateStatus("⚠️ [CẮT LỖ TOÀN CỤC] Hàng " & $g_iCurrentTier & " đã gãy quá giới hạn " & $iMaxLimit & " bước! Reset toàn bộ về H1 B1.")
        For $i = 1 To 10
            $g_aTierStep[$i] = 1
        Next
        $g_iCurrentTier = 1
        $g_fXD_CycleProfit = 0
    EndIf

    Local $bAllClean = False
    If GUICtrlRead($g_hCheckbox_XD_AutoResetDebt) == $GUI_CHECKED Then
        Local $fTarget = Number(StringRegExpReplace(GUICtrlRead($g_hInput_XD_TargetProfit), "\D", ""))
        If $fTarget > 0 And $g_fXD_CycleProfit >= $fTarget Then
            _UpdateStatus("🎉 [CHỐT LỜI VÒNG] Lãi chu kỳ đạt +" & _FormatNumber($g_fXD_CycleProfit) & "đ! XÓA SẠCH NỢ, Về Lại H1 B1.")
            For $i = 1 To 10
                $g_aTierStep[$i] = 1
            Next
            $g_iCurrentTier = 1
            $g_fXD_CycleProfit = 0
            $bAllClean = True
        EndIf
    EndIf

    If Not $bAllClean Then
        If GUICtrlRead($g_hCheckbox_XD_AutoResetDebt) <> $GUI_CHECKED Then
            $bAllClean = True
            For $i = 1 To $iTargetRows
                If $g_aTierStep[$i] > 1 Then
                    $bAllClean = False
                    ExitLoop
                EndIf
            Next
            If $bAllClean Then $g_fXD_CycleProfit = 0
        EndIf
    EndIf

    _UpdateXocDiaGridUI()
EndFunc
Func _SwitchLimit_VIP($sTargetLimit)
    ; 1. NẾU ĐANG ĐÚNG MỐC RỒI -> BỎ QUA LUÔN (Chống kẹt nút, tiết kiệm thời gian)
    If $g_sCurrentLimitState == $sTargetLimit Then Return

    Local $hWnd = $g_hTargetGameWin
    If $hWnd = 0 Or Not WinExists($hWnd) Then Return

    _UpdateStatus("⚙️ Đang bẻ Hạn Mức sang: [" & $sTargetLimit & "] (Chế độ click vật lý chống trượt)...")

    ; Ép game nổi lên trên cùng để chuột thật không bị vướng
    WinActivate($hWnd)
    Sleep(200)

    ; 2. Click Mở bảng Hạn Mức (Dùng chuột thật thay vì JS)
    MouseMove($g_iLimitBtnX, $g_iLimitBtnY, 2) ; Rê chuột vào vị trí (Tốc độ 2 = Nhanh nhưng không giật)
    Sleep(100)
    MouseClick("left", $g_iLimitBtnX, $g_iLimitBtnY, 1, 0)

    ; ĐIỂM MẤU CHỐT: Chờ 600ms để hiệu ứng UI của game xổ bảng hạn mức ra hoàn toàn
    Sleep(600)

    ; 3. Click chọn mốc 10-500 hoặc 20-50K
    If $sTargetLimit == "10-500" Then
        MouseMove($g_iLimit10_500X, $g_iLimit10_500Y, 2)
        Sleep(100)
        MouseClick("left", $g_iLimit10_500X, $g_iLimit10_500Y, 1, 0)
    Else
        MouseMove($g_iLimit20_50KX, $g_iLimit20_50KY, 2)
        Sleep(100)
        MouseClick("left", $g_iLimit20_50KX, $g_iLimit20_50KY, 1, 0)
    EndIf

    ; Nghỉ 400ms chờ UI ghi nhận click chọn mốc
    Sleep(400)

    ; 4. Bấm nút Xác Nhận Vàng (Bấm dứt khoát)
    If $g_iLimitConfirmX > 0 And $g_iLimitConfirmY > 0 Then
        MouseMove($g_iLimitConfirmX, $g_iLimitConfirmY, 2)
        Sleep(100)
        MouseDown("left")
        Sleep(150) ; Giữ phím chuột 150ms để game Sexy nhận diện là "Click" chứ không phải "Vuốt"
        MouseUp("left")
    EndIf

    ; 5. CHỐT CHẶN: Chờ 500ms để bảng hạn mức đóng lại hoàn toàn trước khi vào tiền cược
    Sleep(500)

    $g_sCurrentLimitState = $sTargetLimit
    _UpdateStatus("✅ Đã bẻ xong hạn mức! Chuẩn bị chờ đèn xanh thả chip.")
EndFunc
Func _ToggleGameModeUI()
    If GUICtrlRead($g_hCheckbox_XocDiaVIP) == $GUI_CHECKED Then
        ; 1. Đổi Text màn hình chính thành C/L
        GUICtrlSetData($g_hLbl_B, "C:")
        GUICtrlSetData($g_hLbl_P, "L:")
        GUICtrlSetState($g_hLbl_T, $GUI_HIDE)
        GUICtrlSetState($g_hLabel_TotalT_Val, $GUI_HIDE)

        ; 2. Đổi nhãn trong Phòng Kỹ Thuật thành Chẵn/Lẻ
        GUICtrlSetData($g_hLbl_Coord_B, "Chẵn (X, Y):")
        GUICtrlSetData($g_hLbl_Coord_P, "Lẻ (X, Y):")
        GUICtrlSetData($g_hLbl_Coord_T, "Bỏ Qua (X,Y):")
        GUICtrlSetData($g_hLbl_Color_B, "Màu C/L:")
        GUICtrlSetData($g_hButton_GetBankerColor, "Lấy C")
        GUICtrlSetData($g_hButton_GetPlayerColor, "Lấy L")
        GUICtrlSetData($g_hButton_GetTieColor, "-")

		; Bổ sung: Ép ẩn sạch tọa độ & màu của cửa HÒA
        GUICtrlSetState($g_hLbl_Coord_T, $GUI_HIDE)
        GUICtrlSetState($g_hInput_TieX, $GUI_HIDE)
        GUICtrlSetState($g_hInput_TieY, $GUI_HIDE)
        GUICtrlSetState($g_hButton_GetTiePos, $GUI_HIDE)
        GUICtrlSetState($g_hInput_TieColor, $GUI_HIDE)
        GUICtrlSetState($g_hButton_GetTieColor, $GUI_HIDE)

        ; 3. Ẩn cụm Baccarat, Hiện cụm Xóc đĩa VIP
        _ToggleBaccaratLeftColumn($GUI_HIDE)
        _ToggleXocDiaGridState($GUI_SHOW)
        _UpdateXocDiaGridUI()
    Else
        ; 1. Trả về màn hình chính B/P
        GUICtrlSetData($g_hLbl_B, "B:")
        GUICtrlSetData($g_hLbl_P, "P:")
        GUICtrlSetState($g_hLbl_T, $GUI_SHOW)
        GUICtrlSetState($g_hLabel_TotalT_Val, $GUI_SHOW)

        ; BỔ SUNG: Gọi HIỆN lại các ô nhập tọa độ và màu của cửa HÒA
        GUICtrlSetState($g_hLbl_Coord_T, $GUI_SHOW)
        GUICtrlSetState($g_hInput_TieX, $GUI_SHOW)
        GUICtrlSetState($g_hInput_TieY, $GUI_SHOW)
        GUICtrlSetState($g_hButton_GetTiePos, $GUI_SHOW)
        GUICtrlSetState($g_hInput_TieColor, $GUI_SHOW)
        GUICtrlSetState($g_hButton_GetTieColor, $GUI_SHOW)

        ; 2. Trả về Phòng Kỹ Thuật Banker/Player
        GUICtrlSetData($g_hLbl_Coord_B, "Banker (X, Y):")
        GUICtrlSetData($g_hLbl_Coord_P, "Player (X, Y):")
        GUICtrlSetData($g_hLbl_Coord_T, "Hòa/Tie (X,Y):")
        GUICtrlSetData($g_hLbl_Color_B, "Màu B/P:")
        GUICtrlSetData($g_hButton_GetBankerColor, "Lấy B")
        GUICtrlSetData($g_hButton_GetPlayerColor, "Lấy P")
        GUICtrlSetData($g_hButton_GetTieColor, "Lấy T")

        ; 3. Hiện cụm Baccarat
        _ToggleXocDiaGridState($GUI_HIDE)
        _ToggleBaccaratLeftColumn($GUI_SHOW)
    EndIf
EndFunc

Func _UpdateXocDiaGridUI()
	Local $sCustomSeq = StringStripWS(GUICtrlRead($g_hInput_XD_Seq), 8)
	Local $aParsed = StringSplit($sCustomSeq, ",")

	Local $iTargetRows = Number(GUICtrlRead($g_hInput_XD_MaxRows))
	If $iTargetRows < 1 Then $iTargetRows = 1
	If $iTargetRows > 10 Then $iTargetRows = 10

	Local $fBaseBet = Number(StringRegExpReplace(GUICtrlRead($g_hInput_InitialBet), "\D", ""))
	If $fBaseBet <= 0 Then $fBaseBet = 10000

    ; ĐỌC CHUỖI NHÁP VÀ LỌC RA MẢNG
    Local $sVirtualRaw = StringStripWS(GUICtrlRead($g_hInput_XD_Virtual), 8)
    Local $aVirtualParsed = StringSplit($sVirtualRaw, ",")
    Local $aVirt[11]
    For $r = 1 To 10
        If $r <= $aVirtualParsed[0] Then
            $aVirt[$r] = Number($aVirtualParsed[$r])
        Else
            $aVirt[$r] = 0 ; Nếu khách không ghi gì thì tự hiểu là nháp 0 tay
        EndIf
    Next

    $g_iDynamicMaxSteps = 0

    ; TÍNH TOÁN TIỀN CƯỢC CHO TỪNG HÀNG X CỘT
    For $r = 1 To 10
        Local $iVirtSteps = $aVirt[$r]
        Local $iRowSteps = $aParsed[0] + $iVirtSteps
        If $iRowSteps > 15 Then $iRowSteps = 15
        $g_aXD_MaxStepsPerRow[$r] = $iRowSteps ; Lưu sức chịu đựng của hàng này

        ; Cập nhật số cột kịch kim lớn nhất trên toàn bảng để vẽ viền
        If $iRowSteps > $g_iDynamicMaxSteps And $r <= $iTargetRows Then $g_iDynamicMaxSteps = $iRowSteps

        For $c = 1 To 15
            If $c <= $iVirtSteps Then
                $g_aXocDia_Seq[$r][$c] = 0 ; Các lệnh đầu độn 0đ
            Else
                Local $idx = $c - $iVirtSteps
                If $idx <= $aParsed[0] Then
                    $g_aXocDia_Seq[$r][$c] = Number($aParsed[$idx]) * $fBaseBet
                Else
                    $g_aXocDia_Seq[$r][$c] = -1 ; -1 tượng trưng cho ô rỗng ngoài vùng phủ sóng
                EndIf
            EndIf
        Next
    Next

    ; ẨN/HIỆN CỘT TIÊU ĐỀ
    For $c = 1 To 15
        If $c <= $g_iDynamicMaxSteps Then
            GUICtrlSetState($g_aXD_Cols[$c], $GUI_SHOW)
        Else
            GUICtrlSetState($g_aXD_Cols[$c], $GUI_HIDE)
        EndIf
    Next

    ; VẼ MÀU CHO 10 HÀNG VÀ 15 CỘT
    For $r = 1 To 10
		If $r <= $iTargetRows Then
			GUICtrlSetState($g_aXD_Rows[$r], $GUI_SHOW)
			For $c = 1 To 15
                Local $iVal = $g_aXocDia_Seq[$r][$c]
				If $c <= $g_iDynamicMaxSteps And $iVal <> -1 Then
					GUICtrlSetState($g_aXocDiaGrid[$r][$c], $GUI_SHOW)

					Local $sText = ""
					If $iVal == 0 And $c <= $aVirt[$r] Then
                        $sText = "0đ"
					ElseIf $iVal >= 1000000 Then
						$sText = Round($iVal/1000000, 1) & "M"
					ElseIf $iVal >= 1000 Then
						$sText = Round($iVal/1000, 0) & "k"
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

    If $iBetAmount > 0 Then
        GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: HÀNG " & $g_iCurrentTier & " - BƯỚC " & $g_aTierStep[$g_iCurrentTier] & @CRLF & "💰 Sẵn sàng ném: " & _FormatNumber($iBetAmount) & "đ")
    Else
        GUICtrlSetData($g_hLbl_XD_Status, "Trạng thái: HÀNG " & $g_iCurrentTier & " - BƯỚC " & $g_aTierStep[$g_iCurrentTier] & @CRLF & "💰 Sẵn sàng: ĐÁNH NHÁP (Không thả chip)")
    EndIf
EndFunc

Func _ToggleXocDiaGridState($iState)
    GUICtrlSetState($g_hGroup_XocDiaGrid, $iState)
    GUICtrlSetState($g_hLbl_XD_Status, $iState)
	GUICtrlSetState($g_hLbl_XD_Seq, $iState)
	GUICtrlSetState($g_hInput_XD_Seq, $iState)
	GUICtrlSetState($g_hInput_XD_MaxRows, $iState)
	GUICtrlSetState($g_hCheckbox_XD_AutoResetDebt, $iState)
GUICtrlSetState($g_hInput_XD_TargetProfit, $iState)
GUICtrlSetState($g_hCheckbox_XD_LowDebtPriority, $iState)

    For $c = 1 To 12
        GUICtrlSetState($g_aXD_Cols[$c], $iState)
    Next
    For $r = 1 To 10 ; ---> TĂNG LÊN QUÉT 10 HÀNG <---
        GUICtrlSetState($g_aXD_Rows[$r], $iState)
        For $c = 1 To 12
            GUICtrlSetState($g_aXocDiaGrid[$r][$c], $iState)
        Next
    Next
EndFunc

Func _CheckForUpdates()
	If @Compiled = 0 Then Return
	Local $bRead = InetRead($g_sGithubVersionURL, 1)
	If @error Then Return
	Local $sOnlineVersion = StringStripWS(BinaryToString($bRead, 4), 8)
	If $sOnlineVersion <> "" And Number($sOnlineVersion) > Number($g_sVersion) Then
		_UpdateStatus("🚀 Có bản mới v" & $sOnlineVersion & "! Hệ thống đang tự động tải...")
		_SilentAutoUpdate($g_sDownloadURL)
	EndIf
EndFunc

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

    ; Mở Chrome lên (Không ép Maximize vội, để sếp dễ thao tác)
    Local $sDesiredCapabilities = '{"capabilities": {"alwaysMatch": {"browserName": "chrome", "goog:chromeOptions": {"excludeSwitches": ["enable-automation"], "useAutomationExtension": false, "args": ["--user-data-dir=' & $sDataDir & '"]}}}}'

    $g_sSession = _WD_CreateSession($sDesiredCapabilities)
    If @error Or $g_sSession == "" Then
        _WD_Shutdown()
        Return 0
    EndIf

   ; Vào thẳng trang chủ Game
    _WD_Navigate($g_sSession, "https://8k3071q.top")

    ; ÉP PHÓNG TO (MAXIMIZE) TRÌNH DUYỆT NGAY LẬP TỨC
    _WD_Window($g_sSession, "maximize")
    Sleep(1000) ; Chờ giao diện tải và giãn khung ổn định

; --- THUẬT TOÁN TÌM VÀ CLICK NÚT "ĐÓNG" QUẢNG CÁO BẰNG XPATH ---
    _UpdateStatus("Đang cố gắng tìm và đóng khung quảng cáo bằng XPath...")

    ; Tìm phần tử <span> chứa chữ "Đóng" hoặc có thuộc tính translate='Common_Closed'
    Local $sClickJS = "var btn = document.evaluate(""//span[text()='Đóng' or @translate='Common_Closed']"", document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;" & _
                      "if (btn) { btn.click(); }"

    ; Bắn lệnh 3 lần liên tiếp, mỗi lần cách nhau 1.5 giây để chắc chắn ăn
    For $i = 1 To 3
        _WD_ExecuteScript($g_sSession, $sClickJS)
        Sleep(1500)
    Next

    Return 1 ; Trả về 1 báo hiệu mở Chrome thành công

EndFunc
; --- HÀM TREO NGẦM RÌNH RẬP POPUP GAME XUẤT HIỆN (BẢN V3 - DÙNG WIN API) ---
Func _AutoCatchPopup_And_Maximize()
    _UpdateStatus("⏳ [HỆ THỐNG] Đang rình Popup. Sếp tự tắt quảng cáo và bấm mở sảnh Sexy nhé...")

    ; Vòng lặp treo ngầm (Chỉ thoát khi tìm thấy Popup hoặc sếp bấm DỪNG TOOL)
    While $g_bIsRunning
        _ProcessGUIMessages() ; Giữ cho giao diện Tool không bị đơ

        ; 1. Quét toàn bộ danh sách cửa sổ Chrome đang mở trên máy bằng lệnh Windows
        Local $aChromeList = WinList("[CLASS:Chrome_WidgetWin_1]")
        Local $hPopup = 0

        ; 2. Điều kiện 1: Phải có ít nhất 2 cửa sổ Chrome (1 trang chủ, 1 cái popup vừa đẻ ra)
        If $aChromeList[0][0] >= 2 Then
            For $i = 1 To $aChromeList[0][0]
                Local $hWnd = $aChromeList[$i][1]

                ; Kiểm tra xem cửa sổ có đang hiển thị sáng đèn không
                If BitAND(WinGetState($hWnd), 2) Then
                    Local $aPos = WinGetPos($hWnd)

                    ; Điều kiện 2: Lọc ra cửa sổ "Nhỏ hơn màn hình".
                    ; Trang chủ sếp đang mở Full. Cái Popup đẻ ra (như trong ảnh) bề ngang luôn nhỏ gọn hơn.
                    If IsArray($aPos) And $aPos[2] > 300 And $aPos[2] < @DesktopWidth - 50 Then
                        $hPopup = $hWnd ; Đã tóm trúng ID của Popup Sexy
                        ExitLoop
                    EndIf
                EndIf
            Next
        EndIf

        ; 3. Nếu đã tóm được Popup -> Ra lệnh kích hoạt và ép bung to kịch trần
        If $hPopup <> 0 Then
            _UpdateStatus("⚡ Đã tóm được Popup Sảnh! Đang phóng to...")
            WinActivate($hPopup)
            Sleep(200)
            WinSetState($hPopup, "", @SW_MAXIMIZE)
            Sleep(800) ; Chờ web bung to và load giao diện ổn định

            ; Bàn giao lại ID Window cho Tool AutoIt quét màu
            $g_hTargetGameWin = $hPopup
            Return True
        EndIf

        Sleep(500) ; Nghỉ nửa giây rồi rình tiếp
    WEnd

    Return False ; Trả về False nếu sếp bấm Dừng Tool giữa chừng
EndFunc
; =====================================================================
; HÀM DỌN RÁC RAM TRƯỚC KHI TẮT TOOL HOÀN TOÀN
; =====================================================================
Func _ExitCleanup()
	; 1. Tắt kết nối WebDriver
	If $g_sSession <> "" Then
		_WD_DeleteSession($g_sSession)
		_WD_Shutdown()
	EndIf

	; 2. Giết sạch sẽ các tiến trình chạy ngầm còn sót lại trong Task Manager
	ProcessClose("chromedriver.exe")
EndFunc