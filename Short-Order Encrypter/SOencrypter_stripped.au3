Global Const $GUI_EVENT_CLOSE = -3
Global Const $FO_OVERWRITE = 2
Global Const $FO_CREATEPATH = 8
Global Const $FO_BINARY = 16
Global Const $PROV_RSA_AES = 24
Global Const $CRYPT_VERIFYCONTEXT = 0xF0000000
Global Const $CRYPT_EXPORTABLE = 0x00000001
Global Const $CRYPT_USERDATA = 1
Global Const $CALG_MD5 = 0x00008003
Global Const $CALG_3DES = 0x00006603
Global Const $CALG_AES_128 = 0x0000660e
Global Const $CALG_AES_192 = 0x0000660f
Global Const $CALG_AES_256 = 0x00006610
Global Const $CALG_DES = 0x00006601
Global Const $CALG_RC2 = 0x00006602
Global Const $CALG_RC4 = 0x00006801
Global Const $CALG_USERKEY = 0
Global $__g_aCryptInternalData[3]
Func _Crypt_Startup()
If __Crypt_RefCount() = 0 Then
Local $hAdvapi32 = DllOpen("Advapi32.dll")
If $hAdvapi32 = -1 Then Return SetError(1, 0, False)
__Crypt_DllHandleSet($hAdvapi32)
Local $iProviderID = $PROV_RSA_AES
Local $aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptAcquireContext", "handle*", 0, "ptr", 0, "ptr", 0, "dword", $iProviderID, "dword", $CRYPT_VERIFYCONTEXT)
If @error Or Not $aRet[0] Then
Local $iError = @error + 10, $iExtended = @extended
DllClose(__Crypt_DllHandle())
Return SetError($iError, $iExtended, False)
Else
__Crypt_ContextSet($aRet[1])
EndIf
EndIf
__Crypt_RefCountInc()
Return True
EndFunc
Func _Crypt_Shutdown()
__Crypt_RefCountDec()
If __Crypt_RefCount() = 0 Then
DllCall(__Crypt_DllHandle(), "bool", "CryptReleaseContext", "handle", __Crypt_Context(), "dword", 0)
DllClose(__Crypt_DllHandle())
EndIf
EndFunc
Func _Crypt_DeriveKey($vPassword, $iALG_ID, $iHash_ALG_ID = $CALG_MD5)
Local $aRet = 0, $hBuff = 0, $hCryptHash = 0, $iError = 0, $iExtended = 0, $vReturn = 0
_Crypt_Startup()
Do
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptCreateHash", "handle", __Crypt_Context(), "uint", $iHash_ALG_ID, "ptr", 0, "dword", 0, "handle*", 0)
If @error Or Not $aRet[0] Then
$iError = @error + 10
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$hCryptHash = $aRet[5]
$hBuff = DllStructCreate("byte[" & BinaryLen($vPassword) & "]")
DllStructSetData($hBuff, 1, $vPassword)
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptHashData", "handle", $hCryptHash, "struct*", $hBuff, "dword", DllStructGetSize($hBuff), "dword", $CRYPT_USERDATA)
If @error Or Not $aRet[0] Then
$iError = @error + 20
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptDeriveKey", "handle", __Crypt_Context(), "uint", $iALG_ID, "handle", $hCryptHash, "dword", $CRYPT_EXPORTABLE, "handle*", 0)
If @error Or Not $aRet[0] Then
$iError = @error + 30
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$vReturn = $aRet[5]
Until True
If $hCryptHash <> 0 Then DllCall(__Crypt_DllHandle(), "bool", "CryptDestroyHash", "handle", $hCryptHash)
Return SetError($iError, $iExtended, $vReturn)
EndFunc
Func _Crypt_DestroyKey($hCryptKey)
Local $aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptDestroyKey", "handle", $hCryptKey)
Local $iError = @error, $iExtended = @extended
_Crypt_Shutdown()
If $iError Or Not $aRet[0] Then
Return SetError($iError + 10, $iExtended, False)
Else
Return True
EndIf
EndFunc
Func _Crypt_EncryptData($vData, $vCryptKey, $iALG_ID, $bFinal = True)
Local $iReqBuffSize = 0, $aRet = 0, $hBuff = 0, $iError = 0, $iExtended = 0, $vReturn = 0
_Crypt_Startup()
Do
If $iALG_ID <> $CALG_USERKEY Then
$vCryptKey = _Crypt_DeriveKey($vCryptKey, $iALG_ID)
If @error Then
$iError = @error + 100
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
EndIf
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptEncrypt", "handle", $vCryptKey, "handle", 0, "bool", $bFinal, "dword", 0, "ptr", 0, "dword*", BinaryLen($vData), "dword", 0)
If @error Or Not $aRet[0] Then
$iError = @error + 20
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$iReqBuffSize = $aRet[6]
$hBuff = DllStructCreate("byte[" & $iReqBuffSize & "]")
DllStructSetData($hBuff, 1, $vData)
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptEncrypt", "handle", $vCryptKey, "handle", 0, "bool", $bFinal, "dword", 0, "struct*", $hBuff, "dword*", BinaryLen($vData), "dword", DllStructGetSize($hBuff))
If @error Or Not $aRet[0] Then
$iError = @error + 30
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$vReturn = DllStructGetData($hBuff, 1)
Until True
If $iALG_ID <> $CALG_USERKEY Then _Crypt_DestroyKey($vCryptKey)
_Crypt_Shutdown()
Return SetError($iError, $iExtended, $vReturn)
EndFunc
Func _Crypt_DecryptData($vData, $vCryptKey, $iALG_ID, $bFinal = True)
Local $aRet = 0, $hBuff = 0, $hTempStruct = 0, $iError = 0, $iExtended = 0, $iPlainTextSize = 0, $vReturn = 0
_Crypt_Startup()
Do
If $iALG_ID <> $CALG_USERKEY Then
$vCryptKey = _Crypt_DeriveKey($vCryptKey, $iALG_ID)
If @error Then
$iError = @error + 100
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
EndIf
$hBuff = DllStructCreate("byte[" & BinaryLen($vData) + 1000 & "]")
DllStructSetData($hBuff, 1, $vData)
$aRet = DllCall(__Crypt_DllHandle(), "bool", "CryptDecrypt", "handle", $vCryptKey, "handle", 0, "bool", $bFinal, "dword", 0, "struct*", $hBuff, "dword*", BinaryLen($vData))
If @error Or Not $aRet[0] Then
$iError = @error + 20
$iExtended = @extended
$vReturn = -1
ExitLoop
EndIf
$iPlainTextSize = $aRet[6]
$hTempStruct = DllStructCreate("byte[" & $iPlainTextSize & "]", DllStructGetPtr($hBuff))
$vReturn = DllStructGetData($hTempStruct, 1)
Until True
If $iALG_ID <> $CALG_USERKEY Then _Crypt_DestroyKey($vCryptKey)
_Crypt_Shutdown()
Return SetError($iError, $iExtended, $vReturn)
EndFunc
Func _Crypt_EncryptFile($sSourceFile, $sDestinationFile, $vCryptKey, $iALG_ID)
Local $bTempData = 0, $hInFile = 0, $hOutFile = 0, $iError = 0, $iExtended = 0, $iFileSize = FileGetSize($sSourceFile), $iRead = 0, $bReturn = True
_Crypt_Startup()
Do
If $iALG_ID <> $CALG_USERKEY Then
$vCryptKey = _Crypt_DeriveKey($vCryptKey, $iALG_ID)
If @error Then
$iError = @error
$iExtended = @extended
$bReturn = False
ExitLoop
EndIf
EndIf
$hInFile = FileOpen($sSourceFile, $FO_BINARY)
If @error Then
$iError = 2
$bReturn = False
ExitLoop
EndIf
$hOutFile = FileOpen($sDestinationFile, $FO_OVERWRITE + $FO_CREATEPATH + $FO_BINARY)
If @error Then
$iError = 3
$bReturn = False
ExitLoop
EndIf
Do
$bTempData = FileRead($hInFile, 1024 * 1024)
$iRead += BinaryLen($bTempData)
If $iRead = $iFileSize Then
$bTempData = _Crypt_EncryptData($bTempData, $vCryptKey, $CALG_USERKEY, True)
If @error Then
$iError = @error + 400
$iExtended = @extended
$bReturn = False
EndIf
FileWrite($hOutFile, $bTempData)
ExitLoop 2
Else
$bTempData = _Crypt_EncryptData($bTempData, $vCryptKey, $CALG_USERKEY, False)
If @error Then
$iError = @error + 500
$iExtended = @extended
$bReturn = False
ExitLoop 2
EndIf
FileWrite($hOutFile, $bTempData)
EndIf
Until False
Until True
If $iALG_ID <> $CALG_USERKEY Then _Crypt_DestroyKey($vCryptKey)
_Crypt_Shutdown()
If $hInFile <> -1 Then FileClose($hInFile)
If $hOutFile <> -1 Then FileClose($hOutFile)
Return SetError($iError, $iExtended, $bReturn)
EndFunc
Func _Crypt_DecryptFile($sSourceFile, $sDestinationFile, $vCryptKey, $iALG_ID)
Local $bTempData = 0, $hInFile = 0, $hOutFile = 0, $iError = 0, $iExtended = 0, $iFileSize = FileGetSize($sSourceFile), $iRead = 0, $bReturn = True
_Crypt_Startup()
Do
If $iALG_ID <> $CALG_USERKEY Then
$vCryptKey = _Crypt_DeriveKey($vCryptKey, $iALG_ID)
If @error Then
$iError = @error
$iExtended = @extended
$bReturn = False
ExitLoop
EndIf
EndIf
$hInFile = FileOpen($sSourceFile, $FO_BINARY)
If @error Then
$iError = 2
$bReturn = False
ExitLoop
EndIf
$hOutFile = FileOpen($sDestinationFile, $FO_OVERWRITE + $FO_CREATEPATH + $FO_BINARY)
If @error Then
$iError = 3
$bReturn = False
ExitLoop
EndIf
Do
$bTempData = FileRead($hInFile, 1024 * 1024)
$iRead += BinaryLen($bTempData)
If $iRead = $iFileSize Then
$bTempData = _Crypt_DecryptData($bTempData, $vCryptKey, $CALG_USERKEY, True)
If @error Then
$iError = @error + 400
$iExtended = @extended
$bReturn = False
EndIf
FileWrite($hOutFile, $bTempData)
ExitLoop 2
Else
$bTempData = _Crypt_DecryptData($bTempData, $vCryptKey, $CALG_USERKEY, False)
If @error Then
$iError = @error + 500
$iExtended = @extended
$bReturn = False
ExitLoop 2
EndIf
FileWrite($hOutFile, $bTempData)
EndIf
Until False
Until True
If $iALG_ID <> $CALG_USERKEY Then _Crypt_DestroyKey($vCryptKey)
_Crypt_Shutdown()
If $hInFile <> -1 Then FileClose($hInFile)
If $hOutFile <> -1 Then FileClose($hOutFile)
Return SetError($iError, $iExtended, $bReturn)
EndFunc
Func __Crypt_RefCount()
Return $__g_aCryptInternalData[0]
EndFunc
Func __Crypt_RefCountInc()
$__g_aCryptInternalData[0] += 1
EndFunc
Func __Crypt_RefCountDec()
If $__g_aCryptInternalData[0] > 0 Then $__g_aCryptInternalData[0] -= 1
EndFunc
Func __Crypt_DllHandle()
Return $__g_aCryptInternalData[1]
EndFunc
Func __Crypt_DllHandleSet($hAdvapi32)
$__g_aCryptInternalData[1] = $hAdvapi32
EndFunc
Func __Crypt_Context()
Return $__g_aCryptInternalData[2]
EndFunc
Func __Crypt_ContextSet($hCryptContext)
$__g_aCryptInternalData[2] = $hCryptContext
EndFunc
Global Const $WS_EX_ACCEPTFILES = 0x00000010
Global Const $WM_DROPFILES = 0x0233
Global Const $tagRECT = "struct;long Left;long Top;long Right;long Bottom;endstruct"
Global Const $tagREBARBANDINFO = "uint cbSize;uint fMask;uint fStyle;dword clrFore;dword clrBack;ptr lpText;uint cch;" & "int iImage;hwnd hwndChild;uint cxMinChild;uint cyMinChild;uint cx;handle hbmBack;uint wID;uint cyChild;uint cyMaxChild;" & "uint cyIntegral;uint cxIdeal;lparam lParam;uint cxHeader" &((@OSVersion = "WIN_XP") ? "" : ";" & $tagRECT & ";uint uChevronState")
Global Const $HGDI_ERROR = Ptr(-1)
Global Const $INVALID_HANDLE_VALUE = Ptr(-1)
Global Const $WH_CBT = 5
Global Const $KF_EXTENDED = 0x0100
Global Const $KF_ALTDOWN = 0x2000
Global Const $KF_UP = 0x8000
Global Const $LLKHF_EXTENDED = BitShift($KF_EXTENDED, 8)
Global Const $LLKHF_ALTDOWN = BitShift($KF_ALTDOWN, 8)
Global Const $LLKHF_UP = BitShift($KF_UP, 8)
Func _WinAPI_CallNextHookEx($hHk, $iCode, $wParam, $lParam)
Local $aResult = DllCall("user32.dll", "lresult", "CallNextHookEx", "handle", $hHk, "int", $iCode, "wparam", $wParam, "lparam", $lParam)
If @error Then Return SetError(@error, @extended, -1)
Return $aResult[0]
EndFunc
Func _WinAPI_GetCurrentThreadId()
Local $aResult = DllCall("kernel32.dll", "dword", "GetCurrentThreadId")
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_SetWindowsHookEx($idHook, $pFn, $hMod, $iThreadId = 0)
Local $aResult = DllCall("user32.dll", "handle", "SetWindowsHookEx", "int", $idHook, "ptr", $pFn, "handle", $hMod, "dword", $iThreadId)
If @error Then Return SetError(@error, @extended, 0)
Return $aResult[0]
EndFunc
Func _WinAPI_UnhookWindowsHookEx($hHk)
Local $aResult = DllCall("user32.dll", "bool", "UnhookWindowsHookEx", "handle", $hHk)
If @error Then Return SetError(@error, @extended, False)
Return $aResult[0]
EndFunc
Local $hGUI, $msg = 0, $hInput, $iButton, $hDecode, $dButton, $aChkBx[8], $cValue, $iChild = 9999, $iMsg, $iPswd, $iMsgBox, $iPswdBox, $iSubmit = 9999, $iChild2 = 9999, $cButton = 9999, $eButton = 9999, $iEdit, $dChild = 9999, $dMsgBox, $dPswdBox, $dSubmit = 9999, $dMsg, $dPswd, $iFileGetB, $dFileGetB, $fChildi = 9999, $iFilePass, $iFilePassBox, $iPassSubmit, $fcPath, $ED = "", $inputBox = -1
GUI()
GUIRegisterMsg($WM_DROPFILES, "WM_DROPFILES")
While 1
$msg = GUIGetMsg(1)
Switch $msg[1]
Case $hGUI
Switch $msg[0]
Case $GUI_EVENT_CLOSE
Quit()
Case $iButton
getCheckbox()
inputChild()
Case $dButton
getCheckbox()
decryptChild()
EndSwitch
Case $iChild
Switch $msg[0]
Case $GUI_EVENT_CLOSE
GUIDelete($iChild)
GUICtrlSetState($aChkBx[$cValue], 4)
$cValue = ""
Case $iSubmit
$iMsg = GUICtrlRead($iMsgBox)
$iPswd = GUICtrlRead($iPswdBox)
Crypt($iMsg, $iPswd, $cValue)
Case $iFileGetB
getFile("E")
EndSwitch
Case $iChild2
Switch $msg[0]
Case $GUI_EVENT_CLOSE
GUICtrlSetState($aChkBx[$cValue], 4)
GUIDelete($iChild2)
$cValue = ""
Case $cButton
cpyToClipboard()
Case $eButton
GUICtrlSetState($aChkBx[$cValue], 4)
GUIDelete($iChild2)
$cValue = ""
EndSwitch
Case $dChild
Switch $msg[0]
Case $GUI_EVENT_CLOSE
GUIDelete($dChild)
GUICtrlSetState($aChkBx[$cValue], 4)
$cValue = ""
Case $dSubmit
$dMsg = GUICtrlRead($dMsgBox)
$dPswd = GUICtrlRead($dPswdBox)
dCrypt($dMsg, $dPswd, $cValue)
Case $dFileGetB
getFile("D")
EndSwitch
Case $fChildi
Switch $msg[0]
Case $GUI_EVENT_CLOSE
GUIDelete($fChildi)
GUICtrlSetState($aChkBx[$cValue], 4)
$cValue = ""
Case $iPassSubmit
$iFilePass = GUICtrlRead($iFilePassBox)
fileCrypt($fcPath, $iFilePass, $cValue, $ED)
EndSwitch
EndSwitch
WEnd
Func GUI()
$hGUI = GUICreate("Short-Order Encrypter", 300, 200, Default, Default, Default, $WS_EX_ACCEPTFILES)
GUICtrlCreateLabel("Encrypt a Message or a File!", 75, 10)
GUICtrlCreateLabel("This is a simple input and output encryption program. You will", 5, 30)
GUICtrlCreateLabel("select which method of encryption, then input your", 32, 43)
GUICtrlCreateLabel("text (file) by pressing the Input button, or", 52, 56)
GUICtrlCreateLabel("you will press the Decode button to", 60, 69)
GUICtrlCreateLabel("decode an encrypted message (file).", 59, 82)
$iButton = GUICtrlCreateButton("Input", 50, 160, 70, 30)
$dButton = GUICtrlCreateButton("Decode", 160, 160, 70, 30)
$aChkBx[0] = GUICtrlCreateCheckbox("Text", 15, 105)
$aChkBx[1] = GUICtrlCreateCheckbox("3DES", 67, 105)
$aChkBx[2] = GUICtrlCreateCheckbox("AES (128bit)", 122, 105)
$aChkBx[3] = GUICtrlCreateCheckbox("AES (192bit)", 208, 105)
$aChkBx[4] = GUICtrlCreateCheckbox("AES (256bit)", 32, 130)
$aChkBx[5] = GUICtrlCreateCheckbox("DES", 121, 130)
$aChkBx[6] = GUICtrlCreateCheckbox("RC2", 172, 130)
$aChkBx[7] = GUICtrlCreateCheckbox("RC4", 224, 130)
GUISetState(@SW_SHOW)
EndFunc
Func getCheckbox()
Local $i, $readArray, $cCounter = 0
For $i = 0 To UBound($aChkBx) - 1 Step 1
$readArray = GUICtrlRead($aChkBx[$i])
If $readArray = 1 Then
$cCounter += 1
$cValue &= $i
EndIf
Next
If $cCounter > 1 Then
MsgBox(0, "Encryption Type", "Could not specify encryption type due to multiple selections. Please make sure you have only selected one type of encryption")
$cValue = ""
Return 1
ElseIf $cCounter = 0 Then
MsgBox(0, "Encryption Type", "You must select an encryption type in the Short-Order Encrypter window")
$cValue = ""
Return 2
EndIf
EndFunc
Func inputChild()
If $cValue = "" Then
Return
EndIf
$iChild = GUICreate("Input Message", 386, 120, -1, -1, -1, -1, $hGUI)
GUICtrlCreateLabel("Message", 5, 10)
GUICtrlCreateLabel("Password", 200, 10)
$iMsgBox = GUICtrlCreateInput("", 5, 25, 180, 60)
$iPswdBox = GUICtrlCreateInput("", 200, 25, 180, 60)
$iSubmit = GUICtrlCreateButton("Encrypt", 170, 90)
$iFileGetB = GUICtrlCreateButton("Get File", 335, 90)
GUISetState()
EndFunc
Func decryptChild()
If $cValue = "" Then
Return
EndIf
$dChild = GUICreate("Input Message", 386, 120, -1, -1, -1, -1, $hGUI)
GUICtrlCreateLabel("Message", 5, 10)
GUICtrlCreateLabel("Password", 200, 10)
$dMsgBox = GUICtrlCreateInput("", 5, 25, 180, 60)
$dPswdBox = GUICtrlCreateInput("", 200, 25, 180, 60)
$dSubmit = GUICtrlCreateButton("Decrypt", 172, 90)
$dFileGetB = GUICtrlCreateButton("Get File", 335, 90)
GUISetState()
EndFunc
Func Crypt($iMess, $iPass, $iflag)
Local $mFlag[8], $eCrypt, $E
$mFlag[0] = "TEXT"
$mFlag[1] = $CALG_3DES
$mFlag[2] = $CALG_AES_128
$mFlag[3] = $CALG_AES_192
$mFlag[4] = $CALG_AES_256
$mFlag[5] = $CALG_DES
$mFlag[6] = $CALG_RC2
$mFlag[7] = $CALG_RC4
If $iMess = "" Then
MsgBox(0, "ERROR", "Did not enter in a message to Encrypt.")
Return
ElseIf $iPass = "" Then
MsgBox(0, "ERROR", "Did not enter in a password or Encryption.")
Return
EndIf
If $iflag <> 0 Then
$eCrypt = _Crypt_EncryptData($iMess, $iPass, $mFlag[$iflag])
Else
showCode($iMess, $mFlag[$iflag], $E)
Return
EndIf
If $eCrypt = -1 Then
MsgBox(0, "ERROR", "Could not Encrypt the data.")
Select
Case @error >= 100
MsgBox(0, "error", "Cannot create key.")
Case @error = 20
MsgBox(0, "error", "Failed to determine buffer.")
Case @error = 30
EndSelect
Return
EndIf
showCode($eCrypt, $mFlag[$iflag], $E)
EndFunc
Func dCrypt($iMess, $iPass, $iflag)
Local $mFlag[8], $dCt, $D = "D", $bts
$mFlag[0] = "TEXT"
$mFlag[1] = $CALG_3DES
$mFlag[2] = $CALG_AES_128
$mFlag[3] = $CALG_AES_192
$mFlag[4] = $CALG_AES_256
$mFlag[5] = $CALG_DES
$mFlag[6] = $CALG_RC2
$mFlag[7] = $CALG_RC4
If $iMess = "" Then
MsgBox(0, "ERROR", "Did not enter in a message to Decrypt.")
Return
ElseIf $iPass = "" Then
MsgBox(0, "ERROR", "Did not enter in a password.")
Return
EndIf
If $iflag <> 0 Then
$dCt = _Crypt_DecryptData($iMess, $iPass, $mFlag[$iflag])
$bts = BinaryToString($dCt)
Else
showCode($iMess, $mFlag[$iflag], $D)
Return
EndIf
If @error Then
MsgBox(0, "ERROR", "Could not Decrypt the data.")
If @error >= 100 Then
MsgBox(0, "error", "Could not create key.")
EndIf
Return
EndIf
showCode($bts, $mFlag[$iflag], $D)
EndFunc
Func showCode($code, $eType, $DorE)
Local $aFlag[8]
$aFlag[0] = "Text"
$aFlag[1] = "3DES"
$aFlag[2] = "AES (128bit)"
$aFlag[3] = "AES (192bit)"
$aFlag[4] = "AES (256bit)"
$aFlag[5] = "DES"
$aFlag[6] = "RC2"
$aFlag[7] = "RC4"
If $DorE <> "D" Then
GUIDelete($iChild)
$iChild2 = GUICreate("Secret Message - shhh!", 400, 200, -1, -1, -1, -1, $hGUI)
Else
GUIDelete($dChild)
$iChild2 = GUICreate("Here is your message - you spy you", 400, 200, -1, -1, -1, -1, $hGUI)
EndIf
$iEdit = GUICtrlCreateEdit($code, 9, 10, 380, 150)
$cButton = GUICtrlCreateButton("Copy to Clipboard", 100, 170)
$eButton = GUICtrlCreateButton("Close Window", 210, 170)
ControlClick($iChild2, $code, $iEdit)
GUISetState()
EndFunc
Func cpyToClipboard()
Local $cInfo, $clip
$cInfo = GUICtrlRead($iEdit)
$clip = ClipPut($cInfo)
If $clip = 0 Then Return MsgBox(0, "ERROR", "Could not copy code to clipboard.")
MsgBox(0, "Clipboard", "Successfully set code to the clipboard.")
EndFunc
Func getFile($erd)
Local $fPath, $fArray, $fName, $i, $mBox
$fPath = FileOpenDialog("Find that File!", @WorkingDir, "All (*.*)", 1, "")
If @error = 1 Then
MsgBox(0, "ERROR", "Bad selection or no selection.")
Return
ElseIf @error = 2 Then
MsgBox(0, "ERROR", "Bad filter.")
Return
EndIf
$fcPath = $fPath
$fArray = StringSplit($fPath, "\")
If @error = 1 Then
MsgBox(0, "ERROR", "No path selected")
Return
EndIf
$i = $fArray[0]
$fName = $fArray[$i]
If $erd = "E" Then
$mBox = MsgBox(4, "Encrypt File", "Would you like to Encrypt: " & $fName & "?")
If $mBox = 7 Then
Return
ElseIf $mBox = 6 Then
iPswdBox($erd)
EndIf
Else
$mBox = MsgBox(4, "Decrypt File", "Would you like to Decrypt: " & $fName & "?")
If $mBox = 7 Then
Return
ElseIf $mBox = 6 Then
iPswdBox($erd)
EndIf
EndIf
EndFunc
Func iPswdBox($eord)
$ED = $eord
If $ED = "E" Then
GUIDelete($iChild)
Else
GUIDelete($dChild)
EndIf
$fChildi = GUICreate("I need a password", 200, 100, -1, -1, -1, -1, $hGUI)
$iFilePassBox = GUICtrlCreateInput("", 5, 5, 190, 60)
$iPassSubmit = GUICtrlCreateButton("Run", 80, 70)
GUISetState()
EndFunc
Func WM_DROPFILES($hWnd, $iMsg, $wParam, $lParam)
#forceref $iMsg, $lParam
If $hWnd = $hGUI Then
$sDroppedFiles = _DragQueryFile($wParam)
If @error Or StringInStr(FileGetAttrib($sDroppedFiles), "D") Then
_MessageBeep(48)
Return 1
EndIf
_DragFinish($wParam)
_getInput($sDroppedFiles)
Return 1
EndIf
_MessageBeep(48)
Return 1
EndFunc
Func _DragQueryFile($hDrop, $iIndex = 0)
Local $aCall = DllCall("shell32.dll", "dword", "DragQueryFileW", "handle", $hDrop, "dword", $iIndex, "wstr", "", "dword", 32767)
If @error Or Not $aCall[0] Then Return MsgBox(0, "", "error")
Return $aCall[3]
EndFunc
Func _DragFinish($hDrop)
DllCall("shell32.dll", "none", "DragFinish", "handle", $hDrop)
If @error Then Return MsgBox(0, "", "error in _DragFinish: " & @error)
EndFunc
Func _MessageBeep($iType)
DllCall("user32.dll", "int", "MessageBeep", "dword", $iType)
If @error Then Return MsgBox(0, "", "error in _MessageBeep: " & @error)
EndFunc
Func _getInput($droppedPath)
Local $i, $iPath, $fName, $getCheckbx
$ifCharSet = FileGetEncoding($droppedPath)
$getCheckbx = getCheckbox()
If $getCheckbx = 1 Then
Return
ElseIf $getCheckbx = 2 Then
Return
EndIf
$msgBox = _MsgBoxEnglish(3, "Drag & Drop", "Would you like to encrypt or decrypt file?")
If $msgBox = 6 Then
$ED = "E"
$inputBox = InputBox("Encryption type", "1.Text 2.3DES 3.AES (128bit) 4.AES (192bit) 5.AES (256bit) 6.DES 7.RC2 8.RC4 ; please enter the number corresponding with the type of encryption you would like to use.")
If @error = 1 Then
GUIDelete($hGUI)
GUI()
Return
EndIf
$cValue = Int(StringStripWS($inputBox, 8))
$fcPath = $droppedPath
iPswdBox($ED)
ElseIf $msgBox = 7 Then
$ED = "D"
$inputBox = InputBox("Decryption type", "1.Text 2.3DES 3.AES (128bit) 4.AES (192bit) 5.AES (256bit) 6.DES 7.RC2 8.RC4 ; please enter the number corresponding with the type of decryption you would like to use.")
If @error = 1 Then
GUIDelete($hGUI)
GUI()
Return
EndIf
$cValue = Int(StringStripWS($inputBox, 8))
$fcPath = $droppedPath
iPswdBox($ED)
Else
GUIDelete($hGUI)
GUI()
Return
EndIf
EndFunc
Func fileCrypt($Path, $Pass, $cFlag, $encORdec)
Local $fFlag[8], $sPath, $fEcrypt, $fDcrypt, $aError, $getNameA, $gotName, $iN, $sis
$fFlag[0] = "TEXT"
$fFlag[1] = $CALG_3DES
$fFlag[2] = $CALG_AES_128
$fFlag[3] = $CALG_AES_192
$fFlag[4] = $CALG_AES_256
$fFlag[5] = $CALG_DES
$fFlag[6] = $CALG_RC2
$fFlag[7] = $CALG_RC4
If $cFlag = 0 Then
MsgBox(0, "Text Selected", "You have selected text, which is not available for file Encryption or Decryption. Exiting...")
Return
EndIf
Switch $encORdec
Case "E"
$sPath = FileSaveDialog("Save Encrypted File", @WorkingDir, "All(*.*)", 2)
$aError = @error
If $aError = 1 Then
MsgBox(0, "ERROR", "No file name to save")
Return
ElseIf $aError = 2 Then
MsgBox(0, "ERROR", "Bad file filter")
Return
EndIf
$getNameA = StringSplit($sPath, "\")
If @error = 1 Then Return MsgBox(0, "ERROR", "No path selected")
$iN = $getNameA[0]
$gotName = $getNameA[$iN]
$sis = StringInStr($gotName, ".")
If $sis = 0 Then Return MsgBox(0, "ERROR", "Bad name; Must use file saving format *.*")
$fEcrypt = _Crypt_EncryptFile($Path, $sPath, $Pass, $fFlag[$cFlag])
If $fEcrypt = False Then
Select
Case @error >= 10 And @error < 400
MsgBox(0, "ERROR", "Failed to create key")
Return
Case @error >= 400
MsgBox(0, "ERROR", "Failed to encrypt final piece")
Return
Case @error >= 500
MsgBox(0, "ERROR", "Failed to encrypt piece")
Return
Case @error = 2
MsgBox(0, "ERROR", "Couldn't get source file")
Return
Case @error = 3
MsgBox(0, "ERROR", "Couldn't save to destination file")
Return
EndSelect
EndIf
GUICtrlSetState($aChkBx[$cValue], 4)
GUIDelete($fChildi)
$cValue = ""
MsgBox(0, "Success!", "Successfully Encrypted")
Case "D"
$sPath = FileSaveDialog("Save Decrypted File", @WorkingDir, "All(*.*)", 2)
$aError = @error
If $aError = 1 Then
MsgBox(0, "ERROR", "No file name to save")
Return
ElseIf $aError = 2 Then
MsgBox(0, "ERROR", "Bad file filter")
Return
EndIf
$getNameA = StringSplit($sPath, "\")
If @error = 1 Then Return MsgBox(0, "ERROR", "No path selected")
$iN = $getNameA[0]
$gotName = $getNameA[$iN]
$sis = StringInStr($gotName, ".")
If $sis = 0 Then Return MsgBox(0, "ERROR", "Bad name; Must use file saving format *.*")
$fDcrypt = _Crypt_DecryptFile($Path, $sPath, $Pass, $fFlag[$cFlag])
If $fDcrypt = False Then
Select
Case @error >= 10 And @error < 400
MsgBox(0, "ERROR", "Failed to create key")
Return
Case @error >= 400
MsgBox(0, "ERROR", "Failed to decrypt final piece")
Return
Case @error >= 500
MsgBox(0, "ERROR", "Failed to encrypt piece")
Return
Case @error = 2
MsgBox(0, "ERROR", "Couldn't get source file")
Return
Case @error = 3
MsgBox(0, "ERROR", "Couldn't save to destination file")
Return
EndSelect
EndIf
GUICtrlSetState($aChkBx[$cValue], 4)
GUIDelete($fChildi)
$cValue = ""
MsgBox(0, "Success!", "Successfully Decrypted")
EndSwitch
EndFunc
Func Quit()
Exit
EndFunc
Func _MsgBoxEnglish($flag, $title, $text, $timeout = 0, $hwnd = 0)
Local $hProcMsgBox = DllCallbackRegister("CbtHookProcMsgBox", "int", "int;int;int")
Local $TIDMsgBox = _WinAPI_GetCurrentThreadId()
$hHookMsgBox = _WinAPI_SetWindowsHookEx($WH_CBT, DllCallbackGetPtr($hProcMsgBox), 0, $TIDMsgBox)
Local $iRet = MsgBox($flag, $title, $text, $timeout, $hwnd)
_WinAPI_UnhookWindowsHookEx($hHookMsgBox)
DllCallbackFree($hProcMsgBox)
Return $iRet
EndFunc
Func CbtHookProcMsgBox($nCode, $wParam, $lParam, $hHookMsgBox)
Local $RET = 0, $hBitmap = 0, $xWnd = 0
If $nCode < 0 Then
$RET = _WinAPI_CallNextHookEx($hHookMsgBox, $nCode, $wParam, $lParam)
Return $RET
EndIf
Switch $nCode
Case 5
_WinAPI_SetDlgItemText($wParam, 1, "Ok")
_WinAPI_SetDlgItemText($wParam, 2, "Cancel")
_WinAPI_SetDlgItemText($wParam, 3, "&Abort")
_WinAPI_SetDlgItemText($wParam, 4, "&Retry")
_WinAPI_SetDlgItemText($wParam, 5, "&Ignore")
_WinAPI_SetDlgItemText($wParam, 6, "&Encrypt")
_WinAPI_SetDlgItemText($wParam, 7, "&Decrypt")
_WinAPI_SetDlgItemText($wParam, 8, "Help")
_WinAPI_SetDlgItemText($wParam, 10, "&Try Again")
_WinAPI_SetDlgItemText($wParam, 11, "&Continue")
EndSwitch
Return
EndFunc
Func _WinAPI_SetDlgItemText($hDlg, $nIDDlgItem, $lpString)
Local $aRet = DllCall('user32.dll', "int", "SetDlgItemText", "hwnd", $hDlg, "int", $nIDDlgItem, "str", $lpString)
Return $aRet[0]
EndFunc
