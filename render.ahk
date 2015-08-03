LoadTile(image_path)
{
  if (IsObject(g_render.tiles[image_path]))
    return g_render.tiles[image_path]
  else
    return g_render.tiles[image_path] := new imageDC(image_path)
}

SetCameraPos(x, y, relative=true)
{
  c := relative ? g_render.camera : {x:0, y:0}
  g_render.camera := {x:c.x+x, y:c.y+y}
}

SetViewport(width, height)
{
  g_render.viewport := {w:width, h:height}
  g_render.memDC.resize(100*width+100, 100*height+100)
}

InitRender()
{
  Gui, +Hwndhwnd +Resize
  g_render.hwnd := hwnd
  g_render.winDC := new windowDC(hwnd)
  g_render.memDC := new memoryDC(1, 1)
  g_render.camera := {x:0, y:0}
  g_render.tiles := {}
}

Render()
{
  memDC := g_render.memDC
  vp := g_render.viewport
  camx := g_render.camera.x + 0.5
  camy := g_render.camera.y + 0.5
  xstart := Floor(camx - (vp.w // 2))-1
  ystart := Floor(camy - (vp.h // 2))-1
  
  ;Draw a background
  memDC.setBrush(0xbb0052)
  memDC.rectangle(0, 0, memDC.getWidth(), memDC.getHeight())
  
  xpixel := 0
  Loop, % vp.w+1
  {
    ypixel := 0
    x := A_Index + xstart
    Loop, % vp.h+1
    {
      y := A_Index + ystart
      memDC.bitblt(map[x, y], xpixel, ypixel)
      memDC.write(x ", " y, xpixel+10, ypixel+5)
      ypixel += 100
    }
    xpixel += 100
  }
  g_render.winDC.bitblt(memDC,,, 100*vp.w, 100*vp.h,100*(camx-floor(camx)), 100*(camy-floor(camy)))
  ;g_render.winDC.setTextColor(0xFFFFFF)
  ;g_render.winDC.write(camx ", " camy, 10, 10)
  ;g_render.winDC.write(xstart+1 ", " ystart+1, 10, 30)
  
}

GoTo, RenderExit ;Skip over these gui labels...

GuiClose:
  ExitApp
return

GuiSize:
  ;g_render.memDC.resize(100*g_render.viewport.w, 100*g_render.viewport.w)
return

RenderExit:
