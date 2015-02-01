#include gdi.ahk
#include timer.ahk
SetBatchLines, -1  ;Very important for fps counter, AHK's built in sleeps will make it do weird things
startWidth := 400
startHeight := 400

fpsInterval := 15 ;frames per fps update
frameLimit := 60 ;cap fps

Gui, +Hwndmygui +Resize
winDC := new windowDC(mygui)
memDC := new memoryDC(startWidth, startHeight)
memDC.setFont("Consolas")

;Draw a face
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
  while(t.check() < nextframe)
    sleep, 1

  ;It's best to draw to a memoryDC rather than directly to the window
  ;Once the scene is drawn, it can be pushed to the window
  memDC.setBrush(0xAA00FF) ; 0xBBGGRR
  memDC.rectangle(0, 0, memDC.getWidth(), memDC.getHeight())  ;x = 0, y = 0, w = memDC width, h = memDC height
  ;tile memDC with faces
  Loop, % i := 9
  {
    offset := 10*A_Index
    Loop, % j := memDC.getWidth() // 100
    {
      xpos := 100*A_Index-offset
      Loop, % k := memDC.getHeight() // 100
      {
        ypos := 100*A_Index-offset
        ;copy faceDC into memDC at (xpos, ypos) with width 100 and height 100
        memDC.bitblt(faceDC, xpos, ypos, 100, 100)
      }
    }
  }
  
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
  memDC.write("Tiles: " i*j*k, 15, 30)
  ;This actually puts the contents of memDC onto the window
  winDC.bitblt(memDC)
}
GuiClose:
  ExitApp
return

GuiSize:
  memDC.resize(winDC.getWidth(), winDC.getHeight())
return