;Not meant to be used directly
;Make a class that extends DC - ensure this.dc is a valid dc and call DC.__New() in constructor
class DC
{
  __New()
  {
    this.oldPen := this.select(DllCall("CreateSolidBrush", "uint", 0))
    this.oldBrush := this.select(DllCall("CreatePen", "int", 0, "int", 1, "uint", 0))
    this.oldFont := this.select(DllCall("CreateFont", "int", 0, "int", 0, "int", 0, "int", 0, "int", 400, "uint", false, "uint", false, "uint", false "uint", 1, "uint", 0, "uint", 0, "uint", 4, "uint", 0, "str", ""))
    DllCall("SetBkMode", "ptr", this.dc, "int", 1) ;Transparent
    DllCall("SetStretchBltMode", "ptr", this.dc, "int", 4) ;Halftone (Antialias)
  }
  
  __Delete()
  {
    ;Select original objects back into the dc
    DllCall("DeleteObject", "ptr", this.select(this.oldPen))
    DllCall("DeleteObject", "ptr", this.select(this.oldBrush))
    DllCall("DeleteObject", "ptr", this.select(this.oldFont))
    if (this.hmodule)
      DllCall("FreeLibrary", "ptr", this.hmodule)
  }
  
  select(gdiObj)
  {
    return DllCall("SelectObject", "ptr", this.dc, "ptr", gdiObj)
  }
  
  setBrush(BBGGRR)
  {
    hBrush := DllCall("CreateSolidBrush", "uint", BBGGRR)
    DllCall("DeleteObject", "ptr", this.select(hBrush))
  }
  
  /*  Pen styles
      0 - PS_SOLID
      1 - PS_DASH
      2 - PS_DOT
      4 - PS_DASHDOTDOT
      5 - PS_NULL (Invisible pen)
      6 - PS_INSIDEFRAME
  */
  setPen(BBGGRR, width=1, style=0)
  {
    hPen := DllCall("CreatePen", "int", style, "int", width, "uint", BBGGRR)
    DllCall("DeleteObject", "ptr", this.select(hPen))
  }
  
  rectangle(x, y, w, h)
  {
    DllCall("Rectangle", "ptr", this.dc, "int", x, "int", y, "int", x+w, "int", y+h)
  }
  
  roundRectangle(x, y, w, h, r)
  {
    DllCall("RoundRect", "ptr", this.dc, "int", x, "int", y, "int", x+w, "int", y+w, "int", r, "int", r)
  }
  
  ellipse(cx, cy, rx, ry)
  {
    DllCall("Ellipse", "ptr", this.dc, "int", cx-rx, "int", cy-ry, "int", cx+rx, "int", cy+ry)
  }
  
  line(x1, y1, x2, y2)
  {
    DllCall("MoveToEx", "ptr", this.dc, "int", x1, "int", y1, "ptr", 0)
    DllCall("LineTo", "ptr", this.dc, "int", x2, "int", y2)
  }
  
  MoveTo(x, y)
  {
    DllCall("MoveToEx", "ptr", this.dc, "int", x, "int", y, "ptr", 0)
  }
  
  LineTo(x, y)
  {
    DllCall("LineTo", "ptr", this.dc, "int", x, "int", y)
    return this  ;allows chaining mydc.LineTo(a, b).LineTo(c, d)...
  }
  
  ;Fills an area with the current brush color, extending in all directions until a different color is found
  ;Similar to paint bucket tool in most image editors
  FloodFill(x, y)
  {
    ;FLOODFILLBORDER = 0
    ;FLOODFILLSURFACE = 1
    color := DllCall("GetPixel", "ptr", this.dc, "int", x, "int", y)
    DllCall("ExtFloodFill", "ptr", this.dc, "int", x, "int", y, "uint", color, "uint", 1)
  }
  
  bitblt(srcDC, dx=0, dy=0, dw=0, dh=0, sx=0, sy=0, raster=0xCC0020)
  {
    DllCall("BitBlt", "ptr", this.dc, "int", dx, "int", dy, "int", dw ? dw : this.getWidth(), "int", dh ? dh : this.getHeight(), "ptr", srcDC.dc, "int", sx, "int", sy, "uint", raster)
  }
  
  stretchblt(srcDC, dx=0, dy=0, dw=0, dh=0, sx=0, sy=0, sw=0, sh=0, raster=0xCC0020)
  {
     ; hBitmap := DllCall("GetCurrentObject", "ptr", srcDC.dc, "uint", 7), VarSetCapacity(bm, 20+A_PtrSize)
     ; DllCall("GetObject", "ptr", hBitmap, "int", 20+A_PtrSize, "ptr", &bm)
     ; sw := NumGet(bm, 4, "int"), sh := NumGet(bm, 8, "int")
    DllCall("StretchBlt", "ptr", this.dc, "int", dx, "int", dy, "int", dw ? dw : this.getWidth(), "int", dh ? dh : this.getHeight()
           , "ptr", srcDC.dc, "int", sx, "int", sy, "int", sw ? sw : srcDC.getWidth(), "int", sh ? sh : srcDC.getHeight(), "uint", raster)
  }
  
  write(text, x, y)
  {
    DllCall("TextOut", "ptr", this.dc, "int", x, "int", y, "str", text, "int", StrLen(text))
  }
  
  ;weight controls line thickness (0-900) 
  ;Some weight values make CreateFont fail entirely
  setFont(font, size=18, weight=400, italic=false, underline=false, strikeout=false)
  {
    hFont := DllCall("CreateFont"
    ,"int", size ;height
    ,"int", 0 ;width
    ,"int", 0 ;angle of string (0.1 degrees)
    ,"int", 0 ;angle of each character (0.1 degrees)
    ,"int", weight ;font weight
    ,"uint", italic ;font italic
    ,"uint", underline ;font underline
    ,"uint", strikeout ;font strikeout
    ,"uint", 1 ;DEFAULT_CHARSET: character set
    ,"uint", 0 ;OUT_DEFAULT_PRECIS: output precision
    ,"uint", 0 ;CLIP_DEFAULT_PRECIS: clipping precision
    ,"uint", 4 ;ANTIALIASED_QUALITY: output quality
    ,"uint", 0 ;DEFAULT_PITCH | (FF_DONTCARE << 16): font pitch and family
    ,"str", font) ;typeface name
    DllCall("DeleteObject", "ptr", this.select(hFont))
  }
  
  setTextColor(BBGGRR)
  {
    DllCall("SetTextColor", "ptr", this.dc, "int", BBGGRR)
  }
  
  /* Text alignment styles
  24 - TA_BASELINE
  8  - TA_BOTTOM
  0  - TA_TOP
  6  - TA_CENTER
  0  - TA_LEFT
  2  - TA_RIGHT
  */
  setAlign(align=24)
  {
    DllCall("SetTextAlign", "ptr", this.dc, "int", align)
  }
  
  ;Warning: Overwrites whatever is currently in the DC
  LoadFile(filepath)
  {
    if (!FileExist(filepath))
      return
    VarSetCapacity(si, 16, 0), si := Chr(1)
    if !DllCall("GetModuleHandle", "str", "gdiplus")
      this.hmodule := DllCall("LoadLibrary", "str", "gdiplus", "ptr")
    DllCall("gdiplus\GdiplusStartup", "ptr*", pToken, "ptr", &si, "ptr", 0)
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", filepath, "ptr*", pBitmap)
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", Width)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", Height)
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", hbm, "uint", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
    this.resize(Width, Height)
    tmpdc := DllCall("CreateCompatibleDC", "ptr", this.dc)
    obm := DllCall("SelectObject", "ptr", tmpdc, "ptr", hbm)
    DllCall("BitBlt", "ptr", this.dc, "int", 0, "int", 0, "int", Width, "int", Height, "ptr", tmpdc, "int", 0, "int", 0, "uint", 0xCC0020)
    DllCall("DeleteObject", "ptr", DllCall("SelectObject", "ptr", tmpdc, "ptr", obm))
    DllCall("DeleteDC", "ptr", tmpdc)
  }
}

class memoryDC extends DC
{
  __New(initialWidth, initialHeight, compatibleDC = 0, hbm = 0)
  {
    needToFreeDC := !compatibleDC
    compatibleDC := compatibleDC ? compatibleDC : DllCall("GetDC", "ptr", 0)
    this.dc := DllCall("CreateCompatibleDC", "ptr", compatibleDC)
    hbm := hbm ? hbm : DllCall("CreateCompatibleBitmap", "ptr", compatibleDC, "int", initialWidth, "int", initialHeight)
    if (needToFreeDC)
      DllCall("ReleaseDC", "ptr", 0, "ptr", compatibleDC)
    this.oldBM := this.select(hbm)
    this.w := initialWidth, this.h := initialHeight
    base.__New()
  }
  
  __Delete()
  {
    base.__Delete()
    DllCall("DeleteObject", "ptr", this.select(this.oldBM))
    DllCall("DeleteDC", "ptr", this.dc)
  }

  getDimensions(byref w, byref h)
  {
    w := this.w, h := this.h
  }
  
  getWidth()
  {
    return this.w
  }
  
  getHeight()
  {
    return this.h
  }
  
  resize(newWidth, newHeight, stretch=true)
  {
    hbm := DllCall("CreateCompatibleBitmap", "ptr", this.dc, "int", newWidth, "int", newHeight)
    ;Select new bitmap into a dc
    dctmp := DllCall("CreateCompatibleDC", "ptr", this.dc)
    defbm := DllCall("SelectObject", "ptr", dctmp, "ptr", hbm)
    ;Copy the old bitmap into a new bitmap
    if (stretch)
      DllCall("StretchBlt", "ptr", dctmp, "int", 0, "int", 0, "int", newWidth, "int", newHeight, "ptr", this.dc, "int", 0, "int", 0, "int", this.w, "int", this.h, "uint", 0xCC0020)
    else
      DllCall("BitBlt", "ptr", dctmp, "int", 0, "int", 0, "int", newWidth, "int", newHeight, "ptr", this.dc, "int", 0, "int", 0, "uint", 0xCC0020)
    ;Put default bitmap back and delete temporary dc
    DllCall("SelectObject", "ptr", dctmp, "ptr", defbm)
    DllCall("DeleteDC", "ptr", dctmp)
    ;Install the new bitmap and delete the old one
    DllCall("DeleteObject", "ptr", this.select(hbm))
    this.w := newWidth, this.h := newHeight
  }
}

;Intended only for loading images from file
;It skips some unnecessary steps compared to creating a memoryDC then using memdc.LoadFile()
class imageDC extends memoryDC
{
  __New(filepath, compatibleDC = 0)
  {
    if (!FileExist(filepath))
      return
    VarSetCapacity(si, 16, 0), si := Chr(1)
    if !DllCall("GetModuleHandle", "str", "gdiplus")
      this.hmodule := DllCall("LoadLibrary", "str", "gdiplus", "ptr")
    DllCall("gdiplus\GdiplusStartup", "ptr*", pToken, "ptr", &si, "ptr", 0)
    DllCall("gdiplus\GdipCreateBitmapFromFile", "wstr", filepath, "ptr*", pBitmap)
    DllCall("gdiplus\GdipGetImageWidth", "ptr", pBitmap, "uint*", Width)
    DllCall("gdiplus\GdipGetImageHeight", "ptr", pBitmap, "uint*", Height)
    DllCall("gdiplus\GdipCreateHBITMAPFromBitmap", "ptr", pBitmap, "ptr*", hbm, "uint", 0)
    DllCall("gdiplus\GdipDisposeImage", "ptr", pBitmap)
    DllCall("gdiplus\GdiplusShutdown", "ptr", pToken)
    base.__New(width, height, compatibleDC, hbm)
  }
}

;Intended for use with AHK windows
class windowDC extends DC
{
  __New(hwnd)
  {
    this.hwnd := hwnd
    this.dc := DllCall("GetDC", "ptr", hwnd)
    base.__New()
  }
  
  __Delete()
  {
    base.__Delete()
    DllCall("ReleaseDC", "ptr", this.hwnd, "ptr", this.dc)
  }
  
  getDimensions(byref w, byref h)
  {
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "ptr", this.hwnd, "ptr", &rc)
    w := NumGet(rc, 8, "int")
    h := NumGet(rc, 12, "int")
  }
  
  getWidth()
  {
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "ptr", this.hwnd, "ptr", &rc)
    return NumGet(rc, 8, "int")
  }
  
  getHeight()
  {
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "ptr", this.hwnd, "ptr", &rc)
    return NumGet(rc, 12, "int")
  }
  
  isActive()
  {
    return WinActive("ahk_id " this.hwnd)
  }
  
  isMinimized()
  {
    return DllCall("IsIconic", "ptr", this.hwnd)
  }
  
  isMaximized()
  {
    return DllCall("IsZoomed", "ptr", this.hwnd)
  }
  
  isVisible()
  {
    return DllCall("IsWindowVisible", "ptr", this.hwnd)
  }
  
  resize(newWidth, newHeight)
  {
    Gui, % this.hwnd ": Show", w%newWidth% h%newHeight%
  }
}