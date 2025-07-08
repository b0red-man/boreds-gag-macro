#SingleInstance, force
#Requires autohotkey v1.1
downloadMain() {
    mainDir := SubStr(A_ScriptDir, 1, InStr(A_ScriptDir, "\", 0, 0) - 1)
    try {
        UrlDownloadToFile, % "https://raw.githubusercontent.com/b0red-man/boreds-gag-macro/refs/heads/main/main.ahk", % mainDir . "\main.ahk"
        UrlDownloadToFile, % "https://raw.githubusercontent.com/b0red-man/boreds-gag-macro/refs/heads/main/lib/vers.txt", % A_ScriptDir . "\vers.txt"
    } catch e {
        MsgBox,16,, % "An error occurred while updating the macro, please try again later."
    }
}
downloadMain()
FileRead, curVerFile, % A_ScriptDir . "\vers.txt"
curver := StrSplit(curVerFile, "::")[1]
UrlDownloadToFile, % "https://raw.githubusercontent.com/b0red-man/boreds-gag-macro/refs/heads/main/lib/vers.txt", % A_Temp . "\gitver.txt"
FileRead, newVerFile, % A_Temp . "\gitver.txt"
FileDelete, % A_Temp . "\gitver.txt"
newArr := StrSplit(newVerFile, "::")
if (newArr[1] > curver) {
    MsgBox, 68,, % "An update is avaliable, would you like the macro to automatically install it?`n`nChange Notes:`n" . newArr[2]
    IfMsgBox Yes
        downloadMain()
    ExitApp
}
