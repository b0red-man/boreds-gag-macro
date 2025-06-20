/*
A VERY minimal version of gdip_all.ahk that only has Gdip_BitmapFromScreen and Gdip_SaveBitmapToFile and all its functional dependencies
NONE OF THIS CODE WAS WRITTEN BY ME, PLEASE CHECK OFFICAL GDIP GITHUB REPO FOR CREDITS.
*/
Gdip_CreateHBITMAPFromBitmap(pBitmap, Background:=0xffffffff) {
        hbm := 0
	DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", A_PtrSize ? "UPtr" : "UInt", pBitmap, A_PtrSize ? "UPtr*" : "uint*", hbm, "int", Background)
	return hbm
}
Gdip_Startup(multipleInstances:=0) {
   pToken := 0
   If (multipleInstances=0)
   {
      if !DllCall("GetModuleHandle", "str", "gdiplus", "UPtr")
         DllCall("LoadLibrary", "str", "gdiplus")
   } Else DllCall("LoadLibrary", "str", "gdiplus")

   VarSetCapacity(si, A_PtrSize = 8 ? 24 : 16, 0), si := Chr(1)
   DllCall("gdiplus\GdiplusStartup", "UPtr*", pToken, "UPtr", &si, "UPtr", 0)
   return pToken
}
GetWindowRect(hwnd, ByRef W, ByRef H) {
   ; function by GeekDude: https://gist.github.com/G33kDude/5b7ba418e685e52c3e6507e5c6972959
   ; W10 compatible function to find a window's visible boundaries
   ; modified by Marius Șucanto return an array
   If !hwnd
      Return

   size := VarSetCapacity(rect, 16, 0)
   er := DllCall("dwmapi\DwmGetWindowAttribute"
      , "UPtr", hWnd  ; HWND  hwnd
      , "UInt", 9     ; DWORD dwAttribute (DWMWA_EXTENDED_FRAME_BOUNDS)
      , "UPtr", &rect ; PVOID pvAttribute
      , "UInt", size  ; DWORD cbAttribute
      , "UInt")       ; HRESULT

   If er
      DllCall("GetWindowRect", "UPtr", hwnd, "UPtr", &rect, "UInt")

   r := []
   r.x1 := NumGet(rect, 0, "Int"), r.y1 := NumGet(rect, 4, "Int")
   r.x2 := NumGet(rect, 8, "Int"), r.y2 := NumGet(rect, 12, "Int")
   r.w := Abs(max(r.x1, r.x2) - min(r.x1, r.x2))
   r.h := Abs(max(r.y1, r.y2) - min(r.y1, r.y2))
   W := r.w
   H := r.h
   ; ToolTip, % r.w " --- " r.h , , , 2
   Return r
}
GetDCEx(hwnd, flags:=0, hrgnClip:=0) {
; Device Context extended flags:
; DCX_CACHE = 0x2
; DCX_CLIPCHILDREN = 0x8
; DCX_CLIPSIBLINGS = 0x10
; DCX_EXCLUDERGN = 0x40
; DCX_EXCLUDEUPDATE = 0x100
; DCX_INTERSECTRGN = 0x80
; DCX_INTERSECTUPDATE = 0x200
; DCX_LOCKWINDOWUPDATE = 0x400
; DCX_NORECOMPUTE = 0x100000
; DCX_NORESETATTRS = 0x4
; DCX_PARENTCLIP = 0x20
; DCX_VALIDATE = 0x200000
; DCX_WINDOW = 0x1
   return DllCall("GetDCEx", "UPtr", hwnd, "UPtr", hrgnClip, "int", flags)
}
Gdip_SaveBitmapToFile(pBitmap, sOutput, Quality:=75, toBase64orStream:=0) {
   nCount := nSize := 0
   pStream := hData := ci := 0
   _p := pCodec := 0

   SplitPath sOutput,,, Extension
   If !RegExMatch(Extension, "^(?i:BMP|DIB|RLE|JPG|JPEG|JPE|JFIF|GIF|TIF|TIFF|PNG)$")
      Return -1

   Extension := "." Extension
   r := Gdip_GetImageEncoder(Extension, pCodec, ci)
   If (r=-1)
      Return -2
   
   If (pCodec="" || pCodec=0)
      Return -3

   If (Quality!=75)
   {
      Quality := (Quality < 0) ? 0 : (Quality > 100) ? 100 : Quality
      If (quality>95 && toBase64=1)
         Quality := 95

      If RegExMatch(Extension, "^\.(?i:JPG|JPEG|JPE|JFIF)$")
      {
         Static EncoderParameterValueTypeLongRange := 6
         If !(nCount := Gdip_GetEncoderParameterList(pBitmap, pCodec, EncoderParameters))
            Return -8

         pad := (A_PtrSize = 8) ? 4 : 0
         Loop, % nCount
         {
            elem := (24+A_PtrSize)*(A_Index-1) + 4 + pad
            If (NumGet(EncoderParameters, elem+16, "UInt") = 1) ; number of values = 1
            && (NumGet(EncoderParameters, elem+20, "UInt") = EncoderParameterValueTypeLongRange)
            {
               ; MsgBox, % "nc=" nCount " | " A_Index
               _p := elem + &EncoderParameters - pad - 4
               NumPut(Quality, NumGet(NumPut(4, NumPut(1, _p+0)+20, "UInt")), "UInt")
               Break
            }
         }
      }
   }

   If (toBase64orStream=1 || toBase64orStream=2)
   {
      ; part of the function extracted from ImagePut by iseahound
      ; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=76301&sid=bfb7c648736849c3c53f08ea6b0b1309
      DllCall("ole32\CreateStreamOnHGlobal", "ptr",0, "int",true, "ptr*",pStream)
      gdipLastError := DllCall("gdiplus\GdipSaveImageToStream", "uptr",pBitmap, "ptr",pStream, "ptr",pCodec, "uint", _p ? _p : 0)
      If gdipLastError
         Return -6

      If (toBase64orStream=2)
         Return pStream

      DllCall("ole32\GetHGlobalFromStream", "ptr",pStream, "uint*",hData)
      pData := DllCall("GlobalLock", "ptr",hData, "ptr")
      nSize := DllCall("GlobalSize", "uint",pData)

      VarSetCapacity(bin, nSize, 0)
      DllCall("RtlMoveMemory", "ptr",&bin, "ptr",pData, "uptr",nSize)
      DllCall("GlobalUnlock", "ptr",hData)
      ObjRelease(pStream)
      DllCall("GlobalFree", "ptr",hData)

      ; Using CryptBinaryToStringA saves about 2MB in memory.
      DllCall("Crypt32.dll\CryptBinaryToStringA", "ptr",&bin, "uint",nSize, "uint",0x40000001, "ptr",0, "uint*",base64Length)
      VarSetCapacity(base64, base64Length, 0)
      _E := DllCall("Crypt32.dll\CryptBinaryToStringA", "ptr",&bin, "uint",nSize, "uint",0x40000001, "ptr",&base64, "uint*",base64Length)
      If !_E
         Return -7

      VarSetCapacity(bin, 0)
      Return StrGet(&base64, base64Length, "CP0")
   }

   _E := DllCall("gdiplus\GdipSaveImageToFile", "UPtr", pBitmap, "WStr", sOutput, "UPtr", pCodec, "uint", _p ? _p : 0)
   ; msgbox, % "lol`nr=" r "`npC=" pCodec "`n" extension "`n" sOutput "`nerr=" _E
   gdipLastError := _E
   Return _E ? -5 : 0
}
Gdip_GetImageEncoder(Extension, ByRef pCodec, ByRef ci) {
; The function returns the handle to the GDI+ image encoder for the given file extension, if it is available
; on error, it returns -1
; CI must be a ByRef to not have AHK destroy the struct needed by pCodec.

   Static mimeTypeOffset := 48
        , sizeImageCodecInfo := 76

   nCount := nSize := pCodec := 0
   DllCall("gdiplus\GdipGetImageEncodersSize", "uint*", nCount, "uint*", nSize)
   VarSetCapacity(ci, nSize, 0)
   DllCall("gdiplus\GdipGetImageEncoders", "uint", nCount, "uint", nSize, "UPtr", &ci)

   If !(nCount && nSize)
   {
      ci := ""
      Return -1
   }

   If (A_IsUnicode)
   {
      Loop, % nCount
      {
         idx := (mimeTypeOffset + 7*A_PtrSize) * (A_Index-1)
         sString := StrGet(NumGet(ci, idx + 32 + 3*A_PtrSize), "UTF-16")
         If !InStr(sString, "*" Extension)
            Continue

         pCodec := &ci + idx
         Break
      }
   } Else
   {
      Loop, % nCount
      {
         Location := NumGet(ci, sizeImageCodecInfo*(A_Index-1) + 44)
         nSize := DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "uint", 0, "int",  0, "uint", 0, "uint", 0)
         VarSetCapacity(sString, nSize, 0)
         DllCall("WideCharToMultiByte", "uint", 0, "uint", 0, "uint", Location, "int", -1, "str", sString, "int", nSize, "uint", 0, "uint", 0)
         If !InStr(sString, "*" Extension)
            Continue

         pCodec := &ci + sizeImageCodecInfo*(A_Index-1)
         Break
      }
   }
}
Gdip_GetEncoderParameterList(pBitmap, pCodec, ByRef EncoderParameters) {
   nSize := 0
   DllCall("gdiplus\GdipGetEncoderParameterListSize", "UPtr", pBitmap, "UPtr", pCodec, "uint*", nSize)
   VarSetCapacity(EncoderParameters, nSize, 0) ; struct size
   DllCall("gdiplus\GdipGetEncoderParameterList", "UPtr", pBitmap, "UPtr", pCodec, "uint", nSize, "UPtr", &EncoderParameters)
   Return NumGet(EncoderParameters, "UInt") ; number of parameters possible
}
IsInteger(Var) {
   Static Integer := "Integer"
   If Var Is Integer
      Return 1
   Return 0
}
GetMonitorInfo(MonitorNum) {
   Monitors := MDMF_Enum()
   for k,v in Monitors
   {
      if (v.Num = MonitorNum)
         return v
   }
}
Gdip_BitmapFromScreen(Screen:=0, Raster:="") {
   hhdc := 0
   if (Screen = 0)
   {
      _x := DllCall("GetSystemMetrics", "Int", 76)
      _y := DllCall("GetSystemMetrics", "Int", 77)
      _w := DllCall("GetSystemMetrics", "Int", 78)
      _h := DllCall("GetSystemMetrics", "Int", 79)
   } else if (SubStr(Screen, 1, 5) = "hwnd:")
   {
      hwnd := SubStr(Screen, 6)
      if !WinExist("ahk_id " hwnd)
         return -2

      GetWindowRect(hwnd, _w, _h)
      _x := _y := 0
      hhdc := GetDCEx(hwnd, 3)
   } else if IsInteger(Screen)
   {
      M := GetMonitorInfo(Screen)
      _x := M.Left, _y := M.Top, _w := M.Right-M.Left, _h := M.Bottom-M.Top
   } else
   {
      S := StrSplit(Screen, "|")
      _x := S[1], _y := S[2], _w := S[3], _h := S[4]
   }

   if (_x = "") || (_y = "") || (_w = "") || (_h = "")
      return -1

   chdc := CreateCompatibleDC()
   hbm := CreateDIBSection(_w, _h, chdc)
   obm := SelectObject(chdc, hbm)
   hhdc := hhdc ? hhdc : GetDC()
   BitBlt(chdc, 0, 0, _w, _h, hhdc, _x, _y, Raster)
   ReleaseDC(hhdc)

   pBitmap := Gdip_CreateBitmapFromHBITMAP(hbm)
   SelectObject(chdc, obm), DeleteObject(hbm), DeleteDC(hhdc), DeleteDC(chdc)
   return pBitmap
}
MDMF_Enum(HMON := "") {
   Static CallbackFunc := Func(A_AhkVersion < "2" ? "RegisterCallback" : "CallbackCreate")
   Static EnumProc := CallbackFunc.Call("MDMF_EnumProc")
   Static Obj := (A_AhkVersion < "2") ? "Object" : "Map"
   Static Monitors := {}
   If (HMON = "") ; new enumeration
   {
      Monitors := %Obj%("TotalCount", 0)
      If !DllCall("User32.dll\EnumDisplayMonitors", "Ptr", 0, "Ptr", 0, "Ptr", EnumProc, "Ptr", &Monitors, "Int")
         Return False
   }
   Return (HMON = "") ? Monitors : Monitors.HasKey(HMON) ? Monitors[HMON] : False
}
; ======================================================================================================================
;  Callback function that is called by the MDMF_Enum function.
; ======================================================================================================================
MDMF_EnumProc(HMON, HDC, PRECT, ObjectAddr) {
   Monitors := Object(ObjectAddr)
   Monitors[HMON] := MDMF_GetInfo(HMON)
   Monitors["TotalCount"]++
   If (Monitors[HMON].Primary)
      Monitors["Primary"] := HMON
   Return True
}
CreateDIBSection(w, h, hdc:="", bpp:=32, ByRef ppvBits:=0, Usage:=0, hSection:=0, Offset:=0) {
; A GDI function that creates a new hBitmap,
; a device-independent bitmap [DIB].
; A DIB consists of two distinct parts:
; a BITMAPINFO structure describing the dimensions
; and colors of the bitmap, and an array of bytes
; defining the pixels of the bitmap. 

   hdc2 := hdc ? hdc : GetDC()
   VarSetCapacity(bi, 40, 0)
   NumPut(40, bi, 0, "uint")
   NumPut(w, bi, 4, "uint")
   NumPut(h, bi, 8, "uint")
   NumPut(1, bi, 12, "ushort")
   NumPut(bpp, bi, 14, "ushort")
   NumPut(0, bi, 16, "uInt")

   hbm := DllCall("CreateDIBSection"
               , "UPtr", hdc2
               , "UPtr", &bi    ; BITMAPINFO
               , "UInt", Usage
               , "UPtr*", ppvBits
               , "UPtr", hSection
               , "UInt", OffSet, "UPtr")

   if !hdc
      ReleaseDC(hdc2)
   return hbm
}
GetDC(hwnd:=0) {
   return DllCall("GetDC", "UPtr", hwnd)
}
ReleaseDC(hdc, hwnd:=0) {
   return DllCall("ReleaseDC", "UPtr", hwnd, "UPtr", hdc)
}
Gdip_CreateBitmapFromHBITMAP(hBitmap, hPalette:=0) {
; Creates a Bitmap GDI+ object from a GDI [DIB] bitmap handle.
; hPalette - Handle to a GDI palette used to define the bitmap colors

; Do not pass to this function a GDI bitmap or a GDI palette that is
; currently is selected into a device context [hDC].

   pBitmap := 0
   If !hBitmap
   {
      gdipLastError := 2
      Return
   }

   gdipLastError := DllCall("gdiplus\GdipCreateBitmapFromHBITMAP", "UPtr", hBitmap, "UPtr", hPalette, "UPtr*", pBitmap)
   return pBitmap
}
MDMF_GetInfo(HMON) {
   NumPut(VarSetCapacity(MIEX, 40 + (32 << !!A_IsUnicode)), MIEX, 0, "UInt")
   If DllCall("User32.dll\GetMonitorInfo", "UPtr", HMON, "Ptr", &MIEX, "Int")
      Return {Name:      (Name := StrGet(&MIEX + 40, 32))  ; CCHDEVICENAME = 32
            , Num:       RegExReplace(Name, ".*(\d+)$", "$1")
            , Left:      NumGet(MIEX, 4, "Int")    ; display rectangle
            , Top:       NumGet(MIEX, 8, "Int")    ; "
            , Right:     NumGet(MIEX, 12, "Int")   ; "
            , Bottom:    NumGet(MIEX, 16, "Int")   ; "
            , WALeft:    NumGet(MIEX, 20, "Int")   ; work area
            , WATop:     NumGet(MIEX, 24, "Int")   ; "
            , WARight:   NumGet(MIEX, 28, "Int")   ; "
            , WABottom:  NumGet(MIEX, 32, "Int")   ; "
            , Primary:   NumGet(MIEX, 36, "UInt")} ; contains a non-zero value for the primary monitor.
   Return False
}
DeleteDC(hdc) {
   return DllCall("DeleteDC", "UPtr", hdc)
}
CreateCompatibleDC(hdc:=0) {
   return DllCall("CreateCompatibleDC", "UPtr", hdc)
}
SelectObject(hdc, hgdiobj) {
   return DllCall("SelectObject", "UPtr", hdc, "UPtr", hgdiobj)
}
DeleteObject(hObject) {
   return DllCall("DeleteObject", "UPtr", hObject)
}
BitBlt(ddc, dx, dy, dw, dh, sdc, sx, sy, raster:="") {
; This function works only with GDI hBitmaps that 
; are Device-Dependent Bitmaps [DDB].

   return DllCall("gdi32\BitBlt"
               , "UPtr", dDC
               , "int", dX, "int", dY
               , "int", dW, "int", dH
               , "UPtr", sDC
               , "int", sX, "int", sY
               , "uint", Raster ? Raster : 0x00CC0020)
}