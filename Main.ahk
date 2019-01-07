#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#WinActivateForce  ; https://autohotkey.com/docs/commands/_WinActivateForce.htm
#SingleInstance force  ; https://autohotkey.com/docs/commands/_SingleInstance.htm
#Persistent  ; https://autohotkey.com/docs/commands/_Persistent.htm

SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, 2  ; Necessary to match on the name of the window instead of window class in IfWinActive.

; Configurable settings.
; -----------------------------------------------------------------------------

; Set keybindings for macros here.
NewSoloKey := "F9"
SessionTimerKey := "F10"

; How many minutes before the script warns you to start a new session.
intTimerMin := 40

; Should a tooltip show how much time is left before finding a new session?
boolTimerTooltip := true

; End of configurable settings.
; -----------------------------------------------------------------------------

; Assigns the macros to the chosen hotkeys.
Hotkey, %NewSoloKey%, NewSolo
Hotkey, %SessionTimerKey%, SessionTimer

; Changes the desired timer minutes into milliseconds.
intTimerMs := intTimerMin * 60000

; Creates a menu when rightclicking on the icon.
Menu, Tray, Add, New Solo Session, NewSolo
Menu, Tray, Add, Set Session Timer, SessionTimer
Menu, Tray, Add  ; Creates a separator line.
; Rearrenges the menu so custom menu items come on top.
Menu, Tray, NoStandard
Menu, Tray, Standard

; Toast notification to alert that the script is running.
TrayTip, GTA:O Script, Ready to activate macros.,, 17
; Win10 solution to remove the notification staying active.
SetTimer, HideTrayTip, -5000
; Hovering over the icon shows that the script is running.
Menu, Tray, Tip , GTA:O Script is running.

Return
; Every command before this line is runned when the script is started.
; -----------------------------------------------------------------------------

; Win10 workaround to prevent toasts of this script remaining in the action center.
HideTrayTip() {
    TrayTip
    if SubStr(A_OSVersion,1,3) = "10." {
        Menu Tray, NoIcon
        Sleep 200
        Menu Tray, Icon
    }
}
Return

; Suspends a process which has the given pid value.
SuspendProcess(pid) {
  hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
  If (hProcess) {
      DllCall("ntdll.dll\NtSuspendProcess", "Int", hProcess)
      DllCall("CloseHandle", "Int", hProcess)
  }
}
Return

; Resumes a process which has the given pid value.
ResumeProcess(pid) {
  hProcess := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", pid)
  If (hProcess) {
      DllCall("ntdll.dll\NtResumeProcess", "Int", hProcess)
      DllCall("CloseHandle", "Int", hProcess)
  }
}
Return

; Checks wether a process which has the given pid value is suspended (true) or not (false).
IsProcessSuspended(pid) {
  For thread in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Thread WHERE ProcessHandle = " pid)
    If (thread.ThreadWaitReason != 5)
      Return False
    Return True
}
Return

; Suspends GTA5.exe for 8.5 seconds to create a solo session.
NewSolo:
  Process, Exist, GTA5.exe
  pid := ErrorLevel
  If (!IsProcessSuspended(pid)) {
    SuspendProcess(pid)
  }
  Sleep, 8500
  Process, Exist, GTA5.exe
  pid := ErrorLevel
  If (IsProcessSuspended(pid)) {
    ResumeProcess(pid)
  }
Return

; Small toast to let the user know they should find a new session.
GTATimerToast:
TrayTip, GTA:O Script, Find a new session!,, 2
Return

; Changes the tooltip of the icon into the remaining time of the alert.
; Gets called every second by SessionTimer & if boolTimerTooltip = true.
GTATimerTooltipUpdate:
; Every time it is called, substract 1 second of the remaining time.
intTimerSecLeft -= 1
; If the remaining seconds are less than zero,
; check if remaining minutes are still positive.
If (intTimerSecLeft < 0) {
	; If remaining minutes are negative, that mean the remaining time is up.
	; So the tooltip changes content to "Find a new session!"
	; The repeating timer gets deleted and this function stops.
	If (intTimerMinLeft <= 0) {
		Menu, Tray, Tip , Find a new session!
		SetTimer, GTATimerTooltipUpdate, Delete
		return
	}
	; If the remaing minutes are positive, subtract 1 minute of the remaining ones,
	; and reset the remaing seconds to 59.
	intTimerMinLeft--
	intTimerSecLeft = 59
}
; Updates the tooltip to show the remaining minutes and seconds.
Menu, Tray, Tip , %intTimerMinLeft% min and %intTimerSecLeft% sec left before taxes.
Return

; Creates a timer toast to warn you when the chosen minutes treshold has past.
SessionTimer:
SetTimer, GTATimerToast, -%intTimerMs%
; If the treshold is only 1 minute, changes the spelling to singular.
If (intTimerMin = 1) {
	TrayTip, GTA:O Script, Timer started`nTimer is set for %intTimerMin% minute,, 17
} Else {
	TrayTip, GTA:O Script, Timer started`nTimer is set for %intTimerMin% minutes,, 17
}
SetTimer, HideTrayTip, -5000
; Renames "Set Session Timer" to "Reset Session Timer",
; unless it is already renamed.
If !boolMenuSessionTimerSet
{
	Menu, Tray, Rename, Set Session Timer, Reset Session Timer
	boolMenuSessionTimerSet := true
}
; Check if the user wants a tooltip to show the remaining time.
If boolTimerTooltip {
	intTimerMinLeft := intTimerMin
	intTimerSecLeft := 0
	SetTimer, GTATimerTooltipUpdate, 1000
}
Return