' NuomiLauncher - double-click GUI entry with NO console window.
' Runs nuomiw.exe (Windows GUI subsystem), so no black cmd box appears.
' Plain ASCII on purpose: wscript.exe reads .vbs as ANSI on Chinese Windows.
Option Explicit

Dim sh, fso, here, exe, script, cmd
Set fso = CreateObject("Scripting.FileSystemObject")
Set sh  = CreateObject("WScript.Shell")

here   = fso.GetParentFolderName(WScript.ScriptFullName)
exe    = here & "\nuomiw.exe"
script = here & "\gui.nuomi"

If Not fso.FileExists(exe) Then
    MsgBox "nuomiw.exe not found in:" & vbCrLf & here & vbCrLf & vbCrLf & _
           "Please keep all release files in the same folder.", 16, "NuomiLauncher"
    WScript.Quit 1
End If
If Not fso.FileExists(script) Then
    MsgBox "gui.nuomi not found in:" & vbCrLf & here, 16, "NuomiLauncher"
    WScript.Quit 1
End If

sh.CurrentDirectory = here
cmd = """" & exe & """ """ & script & """"
' 1 = normal window (wm.c forces SW_SHOW anyway), False = return immediately
sh.Run cmd, 1, False
