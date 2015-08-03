;Not meant to be used directly
;Make a class that extends DC - ensure this.dc is a valid dc and call DC.__New() in constructor
;extended classes should implement getWidth, getHeight, getDimensions, and resize
class baseDC
{
  __New()
  {
    this.oldPen := this.select(DllCall("CreateSolidBrush", "uint", 0))
    this.oldBrush := this.select(DllCall("CreatePen", "int", 0, "int", 1, "uint", 0))
    this.oldFont := this.select(DllCall("CreateFont", "int", 0, "int", 0, "int", 0, "int", 0, "int", 400, "uint", false, "uint", false, "uint", false "uint", 1, "uint", 0, "uint", 0, "uint", 4, "uint", 0, "str", ""))
    DllCall("SetBkMode", "ptr", this.dc, "int", 1) ;Transparent
    DllCall("SetStretchBltMode", "ptr", this.dc, "int", 3) ;COLORONCOLOR
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
  
  clear(BBGGRR)
  {
    hBrush := this.select(DllCall("CreateSolidBrush", "uint", BBGGRR))
    hPen := this.select(DllCall("CreatePen", "int", 0, "int", 0, "uint", BBGGRR))
    DllCall("Rectangle", "ptr", this.dc, "int", 0, "int", 0, "int", this.getWidth(), "int", this.getHeight())
    DllCall("DeleteObject", "ptr", this.select(hPen)), DllCall("DeleteObject", "ptr", this.select(hBrush))
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
  
  ;Note: 0 alpha = src is transparent, 255 alpha = src is opaque
  alphablend(srcDC, dx=0, dy=0, dw=0, dh=0, sx=0, sy=0, sw=0, sh=0, alpha=255)
  {
    DllCall("GdiAlphaBlend", "ptr", this.dc, "int", dx, "int", dy, "int", dw ? dw : this.getWidth(), "int", dh ? dh : this.getHeight()
           , "ptr", srcDC.dc, "int", sx, "int", sy, "int", sw ? sw : srcDC.getWidth(), "int", sh ? sh : srcDC.getHeight(), "uint", alpha << 16)
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
  
  enableAdvancedGraphics()
  {
    DllCall("SetGraphicsMode", "ptr", this.dc, "int", 2)
  }
  
  ;https://msdn.microsoft.com/en-us/library/dd145228(v=vs.85).aspx
  setWorldTransform(eM11=1, eM12=0, eM21=0, eM22=1, eDx=0, eDy=0)
  {
    VarSetCapacity(XFORM, 24)
    Numput(eM11, XFORM, 0, "float"), Numput(eM12, XFORM, 4, "float"), Numput(eM21, XFORM, 8, "float")
    , Numput(eM22, XFORM, 12, "float"), Numput(eDx, XFORM, 16, "float"), Numput(eDy, XFORM, 20, "float")
    DllCall("SetWorldTransform", "ptr", this.dc, "ptr", &XFORM)
  }
  
  ;mode values:
  ;MWT_IDENTITY 1
  ;MWT_LEFTMULTIPLY 2
  ;MWT_RIGHTMULTIPLY 3
  modifyWorldTransform(eM11=1, eM12=0, eM21=0, eM22=1, eDx=0, eDy=0, mode=3)
  {
    VarSetCapacity(XFORM, 24)
    Numput(eM11, XFORM, 0, "float"), Numput(eM12, XFORM, 4, "float"), Numput(eM21, XFORM, 8, "float")
    , Numput(eM22, XFORM, 12, "float"), Numput(eDx, XFORM, 16, "float"), Numput(eDy, XFORM, 20, "float")
    DllCall("ModifyWorldTransform", "ptr", this.dc, "ptr", &XFORM, "uint", mode)
  }
  
  ;http://www.functionx.com/visualc/gdi/gdicoord.htm
  setMapMode(mode)
  {
    DllCall("SetMapMode", "ptr", this.dc, "int", mode)
  }
  
  ;MM_ANISOTROPIC 8
  ;MM_ISOTROPIC 7
  ;MM_LOENGLISH 4
  SetViewportExt(w, h)
  {
    DllCall("SetViewportExtEx", "ptr", this.dc, "int", w, "int", h, "ptr", 0)
  }
  
  SetWindowExt(w, h)
  {
    DllCall("SetWindowExtEx", "ptr", this.dc, "int", w, "int", h, "ptr", 0)
  }
  
  SetViewportOrigin(x, y)
  {
    DllCall("SetViewportOrgEx", "ptr", this.dc, "int", x, "int", y, "ptr", 0)
  }
  
  GetViewportOrigin(byref x, byref y)
  {
    DllCall("GetViewportOrgEx", "ptr", this.dc, "int64*", p)
    x := p & 0xFFFFFFFF, y := p >> 32
  }
  
  SetWindowOrigin(x, y)
  {
    DllCall("SetWindowOrgEx", "ptr", this.dc, "int", x, "int", y, "ptr", 0)
  }
  
  GetWindowOrigin(byref x, byref y)
  {
    DllCall("GetWindowOrgEx", "ptr", this.dc, "int64*", p)
    x := p & 0xFFFFFFFF, y := p >> 32
  }

  DPtoLP(byref x, byref y)
  {
    p := x | (y << 32)
    DllCall("DPtoLP", "ptr", this.dc, "int64*", p, "int", 1)
    x := p & 0xFFFFFFFF, y := p >> 32
  }


  LPtoDP(byref x, byref y)
  {
    p := x | (y << 32)
    DllCall("LPtoDP", "ptr", this.dc, "int64*", p, "int", 1)
    x := p & 0xFFFFFFFF, y := p >> 32
  }
  
  measureString(str, byref w, byref h)
  {
    DllCall("GetTextExtentPoint32", "ptr", this.dc, "str", str, "int", StrLen(str), "int64*", p)
    w := p & 0xFFFFFFFF, h := p >> 32
  }
  
  RGBtoBGR(color)
  {
    return ((color & 0xFF0000) >> 16) | (color & 0xFF00) | ((color & 0xFF) << 16)
  }
  
  saveState()
  {
    this.DCSavedState := DllCall("SaveDC", "ptr", this.dc)
  }
  
  restoreState()
  {
    DllCall("RestoreDC", "ptr", this.dc, "int", this.DCSavedState)
  }
}

class memoryDC extends baseDC
{
  __New(initialWidth, initialHeight, compatibleDC = 0, hbm = 0)
  {
    this.needToFreeDC := !compatibleDC
    this.cdc := compatibleDC ? compatibleDC : DllCall("GetDC", "ptr", 0)
    this.dc := DllCall("CreateCompatibleDC", "ptr", this.cdc)
    hbm := hbm ? hbm : DllCall("CreateCompatibleBitmap", "ptr", this.cdc, "int", initialWidth, "int", initialHeight)
    this.oldBM := this.select(hbm)
    this.w := initialWidth, this.h := initialHeight
    base.__New()
  }
  
  __Delete()
  {
    base.__Delete()
    DllCall("DeleteObject", "ptr", this.select(this.oldBM))
    DllCall("DeleteDC", "ptr", this.dc)
    if (this.needToFreeDC)
      DllCall("ReleaseDC", "ptr", 0, "ptr", this.cdc)
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
  
  resize(newWidth, newHeight, stretch=false)
  {
    hbm := DllCall("CreateCompatibleBitmap", "ptr", this.cdc, "int", newWidth, "int", newHeight)
    ;Select new bitmap into a dc
    dctmp := DllCall("CreateCompatibleDC", "ptr", this.cdc)
    defbm := DllCall("SelectObject", "ptr", dctmp, "ptr", hbm)
    ;Copy the old bitmap into a new bitmap
    if (stretch)
      DllCall("StretchBlt", "ptr", dctmp, "int", 0, "int", 0, "int", newWidth, "int", newHeight, "ptr", this.dc, "int", 0, "int", 0, "int", this.w, "int", this.h, "uint", 0xCC0020)
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

;Intended for use with AHK windows or controls
class windowDC extends baseDC
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
    DllCall("SetWindowPos", "ptr", this.hwnd, "ptr", 0, "int", 0, "int", 0, "int", newWidth, "int", newHeight, "uint", 534)
  }
}

;Use if you have an hdc already - in this case, you are responsible for freeing the dc
class shellDC extends baseDC
{
  __New(hdc)
  {
    this.dc := hdc
  }
  
  __Delete()
  {
    if (this.hmodule)
      DllCall("FreeLibrary", "ptr", this.hmodule)
  }
  
  getDimensions(byref w, byref h)
  {
    VarSetCapacity(BITMAP, 32, 0)
    hbm := DllCall("GetCurrentObject", "ptr", this.dc, "uint", 7, "ptr")
    DllCall("GetObject", "ptr", hbm, "int", A_PtrSize = 4 ? 24 : 32, "ptr", &BITMAP)
    w := NumGet(BITMAP, 4, "int"), h := NumGet(BITMAP, 8, "int")
  }
  
  getWidth()
  {
    VarSetCapacity(BITMAP, 32, 0)
    hbm := DllCall("GetCurrentObject", "ptr", this.dc, "uint", 7, "ptr")
    DllCall("GetObject", "ptr", hbm, "int", A_PtrSize = 4 ? 24 : 32, "ptr", &BITMAP)
    return NumGet(BITMAP, 4, "int")
  }
  
  getHeight()
  {
    VarSetCapacity(BITMAP, 32, 0)
    hbm := DllCall("GetCurrentObject", "ptr", this.dc, "uint", 7, "ptr")
    DllCall("GetObject", "ptr", hbm, "int", A_PtrSize = 4 ? 24 : 32, "ptr", &BITMAP)
    return NumGet(BITMAP, 8, "int")
  }
  
  resize(newWidth, newHeight, stretch=true)
  {
    hbm := DllCall("CreateCompatibleBitmap", "ptr", this.dc, "int", newWidth, "int", newHeight)
    ;Select new bitmap into a dc
    dctmp := DllCall("CreateCompatibleDC", "ptr", this.dc)
    defbm := DllCall("SelectObject", "ptr", dctmp, "ptr", hbm)
    ;Copy the old bitmap into a new bitmap
    if (stretch)
      DllCall("StretchBlt", "ptr", dctmp, "int", 0, "int", 0, "int", newWidth, "int", newHeight, "ptr", this.dc, "int", 0, "int", 0, "int", this.getWidth(), "int", this.getHeight(), "uint", 0xCC0020)
    else
      DllCall("BitBlt", "ptr", dctmp, "int", 0, "int", 0, "int", newWidth, "int", newHeight, "ptr", this.dc, "int", 0, "int", 0, "uint", 0xCC0020)
    ;Put default bitmap back and delete temporary dc
    DllCall("SelectObject", "ptr", dctmp, "ptr", defbm)
    DllCall("DeleteDC", "ptr", dctmp)
    ;Install the new bitmap and delete the old one
    DllCall("DeleteObject", "ptr", this.select(hbm))
  }
}