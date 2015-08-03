#include gdi.ahk
#include timer.ahk
#singleinstance force
SetBatchLines, -1

startWidth := 400
startHeight := 400
fpsInterval := 15 ;frames per fps update
frameLimit := 60 ;cap fps

Gui, +Hwndmygui +Resize
winDC := new windowDC(mygui)
memDC := new memoryDC(startWidth, startHeight)

faceDC := new memoryDC(100, 100)
faceDC.setBrush(0x00FFFF)
faceDC.setPen(0x000000)
faceDC.ellipse(50, 50, 50, 50)  ;x = 100, y = 100, radius_x = 50, radius_y = 50
faceDC.setBrush(0x000000)
faceDC.ellipse(30, 40, 5, 5)
faceDC.ellipse(70, 40, 5, 5)
faceDC.setPen(0x000000)
faceDC.line(20, 70, 30, 80) ;(60, 120) -> (80, 130)
faceDC.lineTo(70, 80)  ;(80, 130) -> (120, 130)
faceDC.lineTo(80, 70)

Gui, Show, w%startWidth% h%startHeight%

;
;eM11=1, eM12=0, eM21=0, eM22=1, eDx=0, eDy=0
;winDC.setWorldTransform(1,,,-1,50,50)
memDC.setFont("Consolas")

winDC.enableAdvancedGraphics()







t := new timer()
delta := 1000 / frameLimit, nextframe := t.check()
Loop
{
  nextframe += delta

  ;If for some reason this frame was entirely skipped...skip ahead
  if (t.check() > nextframe+delta)
      nextframe += delta*ceil((t.check()-nextframe)/delta)

  ;Wait for next frame
  ;Note: can use 'continue' in place of sleep, 1
  ;This lets you reach higher fps but blows up cpu usage (since there is no sleeping)


  memDC.getDimensions(w,h)


  ;It's best to draw to a memoryDC rather than directly to the window
  ;Once the scene is drawn, it can be pushed to the window
  memDC.setBrush(0xAA00FF) ; 0xBBGGRR
  memDC.rectangle(0,0, memDC.getWidth(), memDC.getHeight())  ;x = 0, y = 0, w = memDC width, h = memDC height
  
  memDC.setPen(0xFFFFFF)
  memDC.setTextColor( 0xFFFFFF)
  Loop, % 100
    memDC.line(100*A_Index-5000, -5000, 100*A_Index-5000, 5000), memDC.write(100*A_Index-5000, 100*A_Index-4995, 0)
  Loop, % 100
    memDC.line(-5000, 100*A_Index-5000, 5000, 100*A_Index-5000), memDC.write(100*A_Index-5000, 5, 100*A_Index-5000)
  
  ;tile memDC with faces
  memDC.bitblt(faceDC, 100, 100)

  
  ;Calculate fps if needed
  if (mod(A_Index, fpsInterval) = 0)
  {
    fps := Round(1000 * fpsInterval / (t.check() - fpstime),2)
    fpstime := t.check()
  }
  ;Print fps in the corner
  memDC.setBrush(0x999999)
  memDC.setPen(0xFFFFFF, 3)
  memDC.rectangle(10, 10, 120, 45)
  memDC.write("FPS: " fps, 15, 15)
  ;This actually puts the contents of memDC onto the window

  while(t.check() < nextframe)
    sleep 1
  memDC.GetwindowOrigin(x1, y1)
  memDC.GetviewportOrigin(x2, y2)
  ;tooltip % x ", " y ", " w ", " h
  winDC.bitblt(memDC,,,,,x1-x2,y1-y2)
}

GuiClose:
  ExitApp
return

GuiSize:
  winDC.getDimensions(ww,wh)
  windc.rectangle(0,0,ww, wh)
  wu := ww < wh ? ww : wh
  winDC.setWorldTransform(wu/400,0,0,wu/400)
 ; memDC.resize(winDC.getWidth(), winDC.getHeight())
  ;SetCameraPos(150,150)
return

SetCameraPos(x, y)
{
  global
  winDC.getDimensions(ww,wh)
  memDC.setViewportOrigin(ww//2 - x, wh//2 - y)
}
