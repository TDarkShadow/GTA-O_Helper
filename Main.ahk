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