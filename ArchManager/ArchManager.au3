#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=
#AutoIt3Wrapper_Outfile=
#AutoIt3Wrapper_Res_Comment=Version 0.0.1
#AutoIt3Wrapper_Res_Description=Contact/demo management
#AutoIt3Wrapper_Res_Fileversion=0.0.1
#AutoIt3Wrapper_Run_Au3Stripper=y
#Au3Stripper_Parameters=/so
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

#include <GUIConstants.au3>

;==========================================================
;=-----ArchManager----------------------------------------=
;=-----Author: MikahS-------------------------------------=
;=--------------------------------------------------------=
;==========================================================
;Contacts, Demos, customers, marketing, send e-mails

Global $GUI[2], $msg, $main_Buttons[6]

_mainGUI()

While 1
	$msg = GUIGetMsg(1)
	Switch $msg[1]
		Case $GUI[1]
			Switch $msg[0]
				Case $GUI_EVENT_CLOSE
					Exit
				Case $main_Buttons[1]
					;contacts
				Case $main_Buttons[2]
					;demos
				Case $main_Buttons[3]
					;customers
				Case $main_Buttons[4]
					;marketing
				Case $main_Buttons[5]
					;emails
			EndSwitch
	EndSwitch
WEnd


Func _mainGUI()
	$GUI[0] = 1
	$GUI[1] = GUICreate("ArchManager", 490, 250, -1, -1, BitOR($WS_POPUP, $WS_OVERLAPPEDWINDOW))
	GUICtrlCreateLabel("ArchAngel II Contact/Demo/Marketing Management App", 110, 25)
	GUICtrlSetResizing(-1, $GUI_DOCKTOP + $GUI_DOCKSIZE + $GUI_DOCKHCENTER)
	$main_Buttons[1] = GUICtrlCreateButton("Contacts", 60, 80, 70, 50)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$main_Buttons[2] = GUICtrlCreateButton("Demos", 60, 150, 70, 50)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$main_Buttons[3] = GUICtrlCreateButton("Customers", 205, 115, 70, 50)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$main_Buttons[4] = GUICtrlCreateButton("Marketing", 350, 80, 70, 50)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$main_Buttons[5] = GUICtrlCreateButton("E-Mails", 350, 150, 70, 50)
	GUICtrlSetResizing(-1, $GUI_DOCKAUTO)
	$main_Buttons[0] = 5
	GUISetState()
EndFunc

