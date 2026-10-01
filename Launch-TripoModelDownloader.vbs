Option Explicit
Dim shell, fso, env, appDir, guiPath, commandLine
Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
Set env = shell.Environment("Process")
env("TRIPO_HIDE_CONSOLE") = "1"
appDir = fso.GetParentFolderName(WScript.ScriptFullName)
guiPath = appDir & "\TripoGLBToFBX-GUI.ps1"
commandLine = "powershell.exe -NoProfile -STA -ExecutionPolicy Bypass -File """ & guiPath & """"
shell.Run commandLine, 1, True
