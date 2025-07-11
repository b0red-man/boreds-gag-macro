; Free and open source, forever (unlike you, Virage)
#Include, %A_ScriptDir%\lib\gdip.ahk
#Requires Autohotkey v1.1
#SingleInstance, force
CoordMode, Pixel, Client
CoordMode, Mouse, Client
global seeds := ["Carrot","Strawberry","Blueberry","OrangeTulip","Tomato","Daffodil","Watermelon","Pumpkin","Apple","Bamboo","Coconut","Cactus","Dragon","Mango","Grape","Mushroom","Pepper","Cacao","Beanstalk","EmberLily","SugarApple","BurningBud"]
global gears := ["WateringCan","Trowel","RecallWrench","BasicSprinkler","AdvancedSprinkler","GodlySprinkler","MagnifyingGlass","TanningMirror","MasterSprinkler","FavoriteTool","HarvestTool","FriendshipPot"]
global eggs := ["Common","CommonSummerEgg","RareSummerEgg","Mythical","Paradise","Bee","Bug"]
global egg_colors := [0xFFFFFF,0xFFFF00,0xAAFFFF,0xffcc00,0xffcd32,0xffaa00,0xd5ff86]
global configPath := A_ScriptDir "\lib\config.ini"
global ssPath := A_ScriptDir . "\lib\ss.jpg"
global loops_ran := 0
global startTime := getUnixTime()
global started := 0
checkForUpdates() {
    FileRead, oldVer, % A_ScriptDir . "\lib\vers.txt"
    try {
        UrlDownloadToFile, % "https://raw.githubusercontent.com/b0red-man/boreds-gag-macro/refs/heads/main/lib/autoupdater.ahk", % A_ScriptDir . "\lib\autoupdater.ahk"
        RunWait, % A_ScriptDir . "\lib\autoupdater.ahk"
    }
    FileRead, newVer, % A_ScriptDir . "\lib\vers.txt"
    if (oldVer != newVer) {
        Reload
    }
}
gdip_startup()
ui() {
    global
    seperation := 16
    offset := 40
    Gui, new
    Gui Add, Button, x8 y190 w80 h23 -Tabstop gstart, F5 - Start
    Gui Add, Button, x91 y190 w80 h23 -Tabstop gstop, F6 - Stop
    gui font, s9
    Gui Add, Text, x175 y190, % "made by @b0red_man"
    gui font
    Gui Add,Tab3,x5 y5 w280 h185, Seeds|Gears|Eggs|Other|Extra
    Gui, Tab, Seeds
    Gui Add, Checkbox, vSeedEnable gsave x16 y32, % "Enable"
    for i,j in seeds {
        y := (i*seperation) + offset
        switch {
            case i<=8:x:=16
            case i<=16:{
                x:=98
                y-=(seperation*8)
            }
            case i>=17:{
                x:=178
                y-=(seperation*16)
            }
        }
        id := j . "checkbox"
        Gui, Add,Checkbox, y%y% x%x% v%id% gsave, % j
    }
    Gui, Tab, Gears
    Gui Add, Checkbox, x16 y32 vGearEnable gGearEnable gsave, % "Enable"
    for i,j in gears {
        y := (i*seperation) + offset
        switch {
            case i<=8:x:=16
            case i<=16:{
                x:=128
                y-=(seperation*8)
            }
        }
        id := j . "checkbox"
        Gui, Add,Checkbox, y%y% x%x% v%id% gsave, % j
    }
    Gui, Tab, Eggs
    Gui Add, Checkbox, x16 y32 vEggEnable gsave, % "Enable"
    for i,j in eggs {
        y := (i*seperation) + offset
        switch {
            case i<=8:x:=16
            case i<=16:{
                x:=128
                y-=(seperation*8)
            }
        }
        id := j . "checkbox"
        Gui, Add,Checkbox, y%y% x%x% v%id% gsave, % j
    }
    Gui, Tab, Other
        Gui Add, Checkbox, x16 y36 vCosEnable gsave, % "Buy all cosmetics"
        gui font, w600
        Gui Add, Groupbox, x16 y54 w140 h50, % "Inventory Screenshots"
            Gui Font
            Gui add, checkbox,x25 y70 vseedss gsave, % "Seeds"
            Gui add, checkbox,x25 y86 vgearss gsave, % "Gears"
            Gui add, checkbox,x82 y70 veggss gsave, % "Eggs"
        Gui Font, w600
        Gui Add, Groupbox, x16 y110 w140 h70, % "Webhook"
            Gui Font
            Gui Add, Checkbox, x25 y126 vWebhookOn gsave, % "Enable"
            Gui Font, s7
            Gui Add, Text, x25 y145, % "Webhook URL"
            gui font
            Gui Add, Edit, x28 y158 w120 h16 vWebhookURL gsave
        Gui font, w600
        Gui Add, Groupbox, x165 y32 w105 h148, % "Misc"
            gui font
            Gui Add, Groupbox, y45 x171 w93 h75, % "Macro Speed"
                gui add, slider, x177 y60 w85 vspeedslider gslidermove Range1-100 tickinterval50, 50
                Gui Add, text, x180 y95, % "Cur Speed:"
                Gui Add, Edit, w24 h16 x236 y93 vspeededit gslideredit Range1-100
            gui add, checkbox, y125 x174 vautoalign gautoalign, % "Auto-Align"
            gui add, text, x174 y142, % "UI Nav Key:"
            Gui add, Edit, y140 h18 w15 x235 vNavKey gsave
    Gui, Tab, Extra
    Gui Add, Checkbox, x16 y36 vUpdateEnable gsave, % "Enable auto-update"
    gui font, w600
    Gui Add, Groupbox, y52 x16 w130 h80, % "Reconnection"
        gui, Font
        gui add, checkbox, x25 y70 vRecEnable gsave, % "Enable"
        Gui add, text, x25 y90, % "PS Link"
        Gui Add, Edit, x25 y105 h18 w115 vPSLink gsave
    Gui, show
    load()
}
CreateFormData(ByRef retData, ByRef retHeader, objParam) {
	New CreateFormData(retData, retHeader, objParam)
}

; CreateFormData() by tmplinshi, AHK Topic: https://autohotkey.com/boards/viewtopic.php?t=7647
; Thanks to Coco: https://autohotkey.com/boards/viewtopic.php?p=41731#p41731
; Modified version by SKAN, 09/May/2016
; Rewritten by iseahound in September 2022
Class CreateFormData {
    __New(ByRef retData, ByRef retHeader, objParam) {
        Local CRLF := "`r`n", i, k, v, str, pvData
        ; Create a random Boundary
        Local Boundary := this.RandomBoundary()
        Local BoundaryLine := "------------------------------" . Boundary
        ; Create an IStream backed with movable memory.
        hData := DllCall("GlobalAlloc", "uint", 0x2, "uptr", 0, "ptr")
        DllCall("ole32\CreateStreamOnHGlobal", "ptr", hData, "int", False, "ptr*", pStream:=0, "uint")
        this.pStream := pStream
        ; Loop input paramters
        For k, v in objParam
        {
            If IsObject(v) {
                For i, FileName in v
                {
                    str := BoundaryLine . CRLF
                    . "Content-Disposition: form-data; name=""" . k . """; filename=""" . FileName . """" . CRLF
                    . "Content-Type: " . this.MimeType(FileName) . CRLF . CRLF

                    this.StrPutUTF8( str )
                    this.LoadFromFile( Filename )
                    this.StrPutUTF8( CRLF )
                }
            } Else {
                str := BoundaryLine . CRLF
                . "Content-Disposition: form-data; name=""" . k """" . CRLF . CRLF
                . v . CRLF
                this.StrPutUTF8( str )
            }
        }
        this.StrPutUTF8( BoundaryLine . "--" . CRLF )

        this.pStream := ObjRelease(pStream) ; Should be 0.
        pData := DllCall("GlobalLock", "ptr", hData, "ptr")
        size := DllCall("GlobalSize", "ptr", pData, "uptr")

        ; Create a bytearray and copy data in to it.
        retData := ComObjArray( 0x11, size ) ; Create SAFEARRAY = VT_ARRAY|VT_UI1
        pvData  := NumGet( ComObjValue( retData ), 8 + A_PtrSize , "ptr" )
        DllCall( "RtlMoveMemory", "Ptr", pvData, "Ptr", pData, "Ptr", size )

        DllCall("GlobalUnlock", "ptr", hData)
        DllCall("GlobalFree", "Ptr", hData, "Ptr")                   ; free global memory

        retHeader := "multipart/form-data; boundary=----------------------------" . Boundary
    }
    StrPutUTF8( str ) {
        length := StrPut(str, "UTF-8") - 1 ; remove null terminator
        VarSetCapacity(utf8, length)
        StrPut(str, &utf8, length, "UTF-8")
        DllCall("shlwapi\IStream_Write", "ptr", this.pStream, "ptr", &utf8, "uint", length, "uint")
    }
    LoadFromFile( filepath ) {
        DllCall("shlwapi\SHCreateStreamOnFileEx"
                    ,   "wstr", filepath
                    ,   "uint", 0x0             ; STGM_READ
                    ,   "uint", 0x80            ; FILE_ATTRIBUTE_NORMAL
                    ,    "int", False           ; fCreate is ignored when STGM_CREATE is set.
                    ,    "ptr", 0               ; pstmTemplate (reserved)
                    ,   "ptr*", pFileStream:=0
                    ,   "uint")
        DllCall("shlwapi\IStream_Size", "ptr", pFileStream, "uint64*", size:=0, "uint")
        DllCall("shlwapi\IStream_Copy", "ptr", pFileStream , "ptr", this.pStream, "uint", size, "uint")
        ObjRelease(pFileStream)
    }
    RandomBoundary() {
        str := "0|1|2|3|4|5|6|7|8|9|a|b|c|d|e|f|g|h|i|j|k|l|m|n|o|p|q|r|s|t|u|v|w|x|y|z"
        Sort, str, D| Random
        str := StrReplace(str, "|")
        Return SubStr(str, 1, 12)
    }
    MimeType(FileName) {
        n := FileOpen(FileName, "r").ReadUInt()
        Return (n        = 0x474E5089) ? "image/png"
            :  (n        = 0x38464947) ? "image/gif"
            :  (n&0xFFFF = 0x4D42    ) ? "image/bmp"
            :  (n&0xFFFF = 0xD8FF    ) ? "image/jpeg"
            :  (n&0xFFFF = 0x4949    ) ? "image/tiff"
            :  (n&0xFFFF = 0x4D4D    ) ? "image/tiff"
            :  "application/octet-stream"
    }
}
webhookPost(data := 0){ ; from dolphsol
    if(read("WebhookOn")) {
        data := data ? data : {}
        url := read("WebhookUrl")
        if (data.pings){
            data.content := data.content ? data.content " <@" options.DiscordUserID ">" : "<@" options.DiscordUserID ">"
        }
        payload_json := "
            (LTrim Join
            {
                ""content"": """ data.content """,
                ""embeds"": [{
                    " (data.embedAuthor ? """author"": {""name"": """ data.embedAuthor """" (data.embedAuthorImage ? ",""icon_url"": """ data.embedAuthorImage """" : "") "}," : "") "
                    " (data.embedTitle ? """title"": """ data.embedTitle """," : "") "
                    ""description"": """ data.embedContent """,
                    " (data.embedThumbnail ? """thumbnail"": {""url"": """ data.embedThumbnail """}," : "") "
                    " (data.embedImage ? """image"": {""url"": """ data.embedImage """}," : "") "
                    " (data.embedFooter ? """footer"": {""text"": """ data.embedFooter """}," : "") "
                    ""color"": """ (data.embedColor ? data.embedColor : 0) """
                }]
            }
            )"

        if ((!data.embedContent && !data.embedTitle) || data.noEmbed)
            payload_json := RegExReplace(payload_json, ",.*""embeds.*}]", "")
        objParam := {payload_json: payload_json}
        for i,v in (data.files ? data.files : []) {
            objParam["file" i] := [v]
        }
        try {
            CreateFormData(postdata, hdr_ContentType, objParam)
            WebRequest := ComObjCreate("WinHttp.WinHttpRequest.5.1")
            WebRequest.Open("POST", url, true)
            WebRequest.SetRequestHeader("User-Agent", "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko")
            WebRequest.SetRequestHeader("Content-Type", hdr_ContentType)
            WebRequest.SetRequestHeader("Pragma", "no-cache")
            WebRequest.SetRequestHeader("Cache-Control", "no-cache, no-store")
            WebRequest.SetRequestHeader("If-Modified-Since", "Sat, 1 Jan 2000 00:00:00 GMT")
            WebRequest.Send(postdata)
            WebRequest.WaitForResponse()
        }
    }
}
global other_settings := ["SeedEnable","GearEnable","EggEnable","CosEnable","SeedSS","GearSS","EggSS","WebhookOn","WebhookURL","NavKey","autoalign","PSLink","RecEnable"]
save() {
    if(getUnixTime()-starttime>=5) {
        for _,i in seeds {
            cID := i . "checkbox"
            GuiControlGet, val,, %cID%
            IniWrite, %val%, %configPath%, Main, %i%
        }
        for _,i in gears {
            cID := i . "checkbox"
            GuiControlGet, val,, %cID%
            IniWrite, %val%, %configPath%, Main, %i%
        }
        for _,i in eggs {
            cID := i . "checkbox"
            GuiControlGet, val,, %cID%
            IniWrite, %val%, %configPath%, Main, %i%
        }
        for _,i in other_settings {
            GuiControlGet, val,, %i%
            IniWrite, %val%, %configPath%, Main, %i%
        }
        GuiControlGet, sVal,, speededit
        IniWrite, % sVal, % configPath, Main, speed
    }
}
load() {
    for _,i in seeds {
        cID := i . "checkbox"
        GuiControl,, %cID%, % read(i)
    }
    for _,i in gears {
        cID := i . "checkbox"
        GuiControl,, %cID%, % read(i)
    }
    for _,i in eggs {
        cID := i . "checkbox"
        GuiControl,, %cID%, % read(i)
    }
    for _,i in other_settings {
        GuiControl,, %i%, % read(i)
    }
    GuiControl,, speedslider, % read("speed")
    GuiControl,, speededit, % read("speed")
}
goto_gear() {
    WinActivate, Roblox
    WinGetPos,,, w, h, Roblox
    Send, 1
    MouseMove, % ((w*0.7)), % ((h*0.4))
    Loop, 70 {
        Send, {WheelUp}
    }
    Loop, 10 {
        Send, {WheelDown}
        Sleep(50)
    }
    MouseMove, % ((w*0.5)), % ((h*0.4))
    Sleep(20)
    Click
}

nav_reset() {
    Loop, 3 {
        sendraw, % read("NavKey")
        sleep(15)
    }
}
nav_seed() {
    nav_reset()
    Loop, 3 {
        send, d
        Sleep(50)
    }
    send, {Enter}
}
wrench_set() {
    nav_reset()
    Send, ``
    sleep(15)
    Loop, 3 {
        Send, s
        sleep(15)
    }
    send, {Enter}
    sleep(15)
    Loop, 20 {
        Send, {BackSpace}
        sleep(10)
    }
    sleep(15)
    Send, % "Recall"
    sleep(15)
    Send, {Enter}
    sleep(15)
    Loop, 2 {
        Send, a
        sleep(15)
    }
    Loop, 2 {
        Send, d
        sleep(15)
    }
    Send, {Enter}
    sleep(15)
    send, s
    sleep(15)
    send, {Enter}
    sleep(15)
    send, ``
    sleep(15)
    sendraw, % read("NavKey")
}
sleep(t) {
    x := read("speed")
    sleepMult := 0.00009894867*x*x + 0.005157699*x + 0.494743352 ; holy equation
    Sleep, % t/sleepMult
}
drag(x1,y1,x2,y2) {
    MouseMove, % x1, % y1
    sleep(15)
    Click, Down, Right
    sleep(15)
    MouseMove, % x2, % y2
    sleep(15)
    Click, Up, Right
}
nav_send(oldstr) {
    StringLower, str, oldstr
    Loop, % StrLen(str) {
        char := SubStr(str, A_Index, 1)
        if (char == "e") {
            send, {Enter}
        }
        else {
            send % char
        }
        sleep(15)
    }
}
getUnixTime() {
    now := A_NowUTC
    EnvSub, now, 1970, seconds
    return now
}
sTut() {
    global
    gui, tut:new
    gui add, text,x8 y8, % "If you aren't using auto-align, or its broken,`nyou can use the 'Garden' button to help you align like`nin the image below"
    Gui add, pic, x8 h135 w277, % A_ScriptDir . "\lib\example.jpg"
    gui add, text,x8, % "Make sure recall wrench is in SLOT ONE before starting`nthe macro if you are using gear,`ncosmetics, or egg auto-buy"
    gui add, button,w60 gOKPress, % "OK"
    gui add, checkbox, x160 y240 vTutEnable gsave, % "Dont show this again"
    gui show
}
sendScreenshots() {
    if (read("SeedSS")||read("GearSS")||read("EggSS")) {
        Wingetpos,x,y,w,h,Roblox
        send, ``
        sleep(15)
        nav_reset()
        sleep(15)
        nav_send("SSSASEEE")
        if (read("SeedSS")) {
            sleep(1000)
            pB := Gdip_BitmapFromScreen(x+(w*0.3) . "|" . y + (h*0.5) . "|" . w*0.4 . "|" . h*0.45)
            Gdip_SaveBitmapToFile(pB, ssPath)
            webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Seed Inventory"})
        }
        nav_send("SSEEE")
        if (read("GearSS")) {
            sleep(1000)
            pB := Gdip_BitmapFromScreen(x+(w*0.3) . "|" . y + (h*0.5) . "|" . w*0.4 . "|" . h*0.45)
            Gdip_SaveBitmapToFile(pB, ssPath)
            webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Gear Inventory"})
        }
        nav_send("SEEE")
        if (read("EggSS")) {
            sleep(1000)
            pB := Gdip_BitmapFromScreen(x+(w*0.3) . "|" . y + (h*0.5) . "|" . w*0.4 . "|" . h*0.45)
            Gdip_SaveBitmapToFile(pB, ssPath)
            webhookPost({files:[ssPath],embedImage:"attachment://ss.jpg",embedTitle: "Pet/Egg Inventory"})
        }
        sendraw, % read("NavKey")
        sleep(30)
        send, ``
    }
}
buy_plant(plants) {
    Loop, 5 {
        send, s
        Sleep(15)
    }
    loop, 30 {
        Send, w
        Sleep(15)
    } ; makes sure all buying window things are closed
    for i,v in plants {
        amount := i!=1 ? plants[i]-plants[i-1] : plants[i] + 1
        loop, %amount% {
            Send, s
            Sleep(50)
        }
        Sleep(200)
        Send, {Enter}
        Sleep(200)
        send, s
        Sleep(15)
        Loop, 15 { ; buying item
            Send, {Enter}
            Sleep(15)
        }
        send, w ; closing buying dialouge
        Sleep(15)
        send, {Enter}
    }
}
get_plant_val(plant) {
    IniRead, val, %configPath%, Main, %plant%, 0
    return val
}
sendKey(k,t) {
    Send, % "{" . k . (t ? " " . t : "") . "}"
}
walk(key, time) {
    sendKey(key, "Down")
    Sleep, % Time
    sendKey(key, "Up")
}
ui()
if(!read("TutEnable")) {
    sTut()
}
if(read("UpdateEnable")) {
    checkForUpdates()
}
read(key) {
    IniRead, val, % configPath, Main, % key, 0
    return val
}
scan() {
    if(read("SeedEnable")) {
        plants_to_buy := []
        for i,v in seeds {
            if (get_plant_val(v)) {
                plants_to_buy.Push(i)
            }
        }
        nav_seed()
        Sleep(100)
        send, e
        Sleep(2500)
        nav_send("SSESSEEWWWAAA")
        sleep(15)
        buy_plant(plants_to_buy)
        Sleep(15)
        Loop, 30 { ; closing seed window
            send, w
            sleep(15)
        }
        Loop, 2 {
            send, s
            sleep(15)
        }
        send, w
        sleep(15)
        send, {Enter}
        sendraw, % read("NavKey")
    }
}
scan2() { ; scans the whple gear area (eggs, cosmetics, and gear)
    WinGetPos,,, w, h, Roblox
    if(read("GearEnable")||read("EggEnable")||read("CosEnable")) {
        goto_gear()
        sleep(1000)
        if (read("gearEnable")) {
            send, e
            sleep(100)
            Loop, 6 {
                Send, {WheelUp}
                sleep(15)
            }
            Sleep(1750)
            MouseMove, (w*0.75), (h*0.45)
            Sleep(15)
            Click
            sleep(2500)
            plants_to_buy := []
            for i,v in gears {
                if (get_plant_val(v)) {
                    plants_to_buy.Push(i)
                }
            }
            sleep(15)
            nav_reset()
            sleep(15)
            nav_send("SSESSEEWWWAAA")
            sleep(15)
            buy_plant(plants_to_buy)
            sleep(15)
            Loop, 20 { ; closing seed window
                send, w
                sleep(100)
            }
            Loop, 2 {
                send, s
                sleep(15)
            }
            send, w
            sleep(15)
            send, {Enter}
            sendraw, % read("NavKey")
            Loop, 6 {
                send, {WheelDown}
                sleep(15)
            }
        }
        walk("a",500)
        if (read("CosEnable") && (Mod(SubStr(A_NowUTC,9,2),4) == 0))  {
            sleep(15)
            send, e
            sleep(2000)
            nav_reset()
            nav_send("SSSAEEEDDEEEDDEEESEEEEEDEEEEEAAEEEEEAEEEEEAEEEEEAEEEEE") ; decided to add this mid-dev process, hopefully convert all other functions to this format
        }
        if (read("EggEnable")) { ;  && Mod(getUnixTime(), 1800) <= 300
            walk("d",1400)
            eggs_to_buy := {}
            for _,v in eggs {
                if(read(v)) {
                    eggs_to_buy.Push(v)
                }
            }
            Loop, 3 {
                sleep(200)
                send, e
                egg := get_egg_type()
                if (is_in_arr(egg,eggs_to_buy)) {
                    nav_reset()
                    nav_send("DDDDSE")
                    sendraw, % read("NavKey")
                }
                nav_reset()
                nav_send("DDDDDSE")
                sendraw, % read("NavKey")
                sleep(15)
                walk("d",200)
            }
        }
    }
}
is_in_arr(needle,haystack) {
    for _,v in haystack {
        if (v == needle) {
            return True
        }
    }
    return False
}
reset_tilt() {
    WinGetPos, , ,w,h, Roblox
    drag(w*0.3,h*0.3,w*0.3,h*0.7)
    Loop, 30 {
        Send, {WheelUp}
        sleep(20)
    }
    Loop, 12 {
        Send, {WheelDown}
        sleep(20)
    }
}
mainLoop() {
    if (read("RecEnable")) {
        SetTimer, checkDisc, 7500
    }
    Loop, {
        scan()
        scan2()
        if (Mod(loops_ran,6)==0) {
            sendScreenshots()
        }
        Loop, {
            if (Mod(getUnixTime(),300) <= 5) {
                loops_ran += 1
                Break
            }
        }
    }
}
get_egg_type() {
    wingetpos,x,y,w,h,Roblox
    for i,tv in egg_colors {
        v := egg_colors[7-i]
        PixelSearch, oX, oY, % ((w*0.42)), % ((h*0.3)), % ((w*0.42))+(w*0.16), % ((h*0.3))+h*0.08, % v, 2, Fast RGB
        PixelGetColor, vs, 884, 348, RGB
        if (oX || oY) {
            return eggs[7-i]
        }
    }
    return -1
}
checkdisconnect() { ; 0x393b3d, 0xFFFFFF
    WinGetPos, x,y,w,h, Roblox
    PixelSearch, x1,, % w*0.3, % h*0.3, % w*0.7, % h*0.7, 0x393b3d, 0, Fast RGB
    PixelSearch, x2,, % w*0.3, % h*0.3, % w*0.7, % h*0.7, 0xffffff, 0, Fast RGB
    if (x1 && x2) {
        return True
    }
    return False
}
attemptReconnect() {
    WinKill, Roblox
    sleep, 250
    WinKill, Roblox
    Sleep, 3500
    link := read("PSLink")
    if(InStr(link,"share")) {
        Run, % link
    } else {
        psID := SubStr(link, -31)
        Run, % "roblox://placeID=126884695634066&linkCode=" . psID
    }
    sleep, 1000
    Loop {
        if(WinExist("Roblox")) {
            sleep, 1000
            WinMaximize, Roblox
            WinActivate, Roblox
            sleep, 500
            Break
        }
    }
    Sleep, 6000
    WinActivate, Roblox
    WinGetPos, x,y,w,h,Roblox
    sleep, 500
    Loop, 5 {
        MouseMove, % w*0.5, % h*0.5
        sleep, 50
        Click
        sleep, 500
    }
    Sleep, 10000
    reset_tilt()
    send, {Right Down}
    sleep, 300
    send, {Right Up}
    align()
}
align() { ; 089AD1
    wingetpos,x,y,w,h,Roblox
    nav_seed()
    sleep(15)
    reset_tilt()
    sendraw, % read("NavKey")
    threshold := 2
    Loop, 20 {
        Send, {WheelUp}
        sleep(15)
    }
    sleep(200)
    Loop, 18 {
        Send, {WheelDown}
        sleep(30)
    }
    drag(w*0.3,h*0.3,w*0.3,h*0.3-1)
    Loop, {
        Random, sleepTime, 0, 80
        PixelSearch,, leftY, (w*0.19), (h*0.2), (w*0.21), (h*0.5), 0x61ad4c,20, Fast RGB
        PixelSearch,, rightY, (w*0.79), (h*0.2), (w*0.81), (h*0.5), 0x61ad4c,20, Fast RGB
        ToolTip, leftY: %leftY%`nrightY: %rightY%
        if (!leftY || !rightY) {
            Random, n, 1, 2
            if (n == 1) {
                Send, {Left}
            } else {
                Send, {Right}
            }
        }
        else if (Abs(righty-lefty)) <= threshold {
            return 0
        } else if (righty>lefty) {
            Send, {Right Down}
            sleep, % sleepTime
            send, {Right Up}
        } else {
            Send, {Left Down}
            sleep, % sleepTime
            Send, {Left Up}
        }
        sleep(100)
    }
	reset_tilt()
}
start() {
    webhookPost({embedContent: "Macro Started", embedColor: 0x80c4cf})
    global started := 1
    WinActivate, Roblox
    reset_tilt()
    if (read("autoalign")) {
        align()
    }
    mainLoop()
}
f6::
    if (started) {
        Reload
        webhookPost({embedContent: "Macro Stopped", embedColor: 0x80c4cf})
    }
Return
f5::start()
Return
checkDisc:
    if(checkdisconnect()) {
        webhookPost({embedContent: "Roblox Disconnected", embedColor: 0xcc6452})
        attemptReconnect()
    }
Return
slidermove:
    GuiControlGet, val,, speedslider
    GuiControl,, speededit, % val
    goto, save
Return
slideredit:
    GuiControlGet, val,, speededit
    GuiControl,, speedslider, % val
    goto, save
Return
GearEnable:
    ; Msgbox % "Please make sure recall wrench is not in your hotbar to have this work"
    goto, save
return
autoalign:
    Msgbox % "Even with auto-align, the camera still needs to be in the general direct of the seed shop, though can be less precise`nThis feature might not work during certain weather events."
    goto, save
Return
GuiClose:
    save()
    ExitApp
Return
save:
    if (A_GuiControl == "speededit"||A_GuiControl == "speedslider") {
        GuiControlGet, v,, % A_GuiControl
        IniWrite, % v, % configPath, Main, speed
    } else {
        cID := StrReplace(A_GuiControl, "checkbox","")
        GuiControlGet, v,, % A_GuiControl
        IniWrite, % v, % configPath, Main, % cID
    }
Return
okpress:
    Gui, tut:Destroy
Return
start:
    start()
return
stop:
    if (started) {
        Reload
        webhookPost({embedContent: "Macro Stopped", embedColor: 0x80c4cf})
    }
