#include globals.ahk

InitRender()
SetViewport(11, 8)  ;11 x 8 tiles
SetCameraPos(10, 10, false)  ;Center camera on tile 10, 10 (false = absolute pos, true = relative to current pos)

;Load resources
;Note: LoadTile is smart - it keeps references to files already loaded and
;      it will give the original reference if called with the same file twice
tile_earth := LoadTile("tiles\dirt.png")
tile_grass := LoadTile("tiles\grass.png")
tile_lava  := LoadTile("tiles\lava.png")

;Generate a sample map
map.width := 20
map.height := 100
Loop, 20
{
  x := A_Index
  Loop, 90
  {
    y := A_Index+10
    random, r, 0, 100
    if (r > 6)  ;mostly dirt with some empty patches
      map[x, y] := tile_earth
    
    if (A_Index = 1)
      map[x, y] := tile_grass  ;a layer of grass
    if (y > 85)
    {  ;some random lava
      Random, r, 0, 100
      if (r < 20)
        map[x, y] := LoadTile("tiles\lava.png")  ;Gives the same reference as tile_lava
    }
    if (y > 95)
    {  ;all lava
      map[x, y] := tile_lava
    }
  }
}

Gui, Show, % "w" g_render.viewport.w*100 " h" g_render.viewport.h*100, Motherload
Loop
{
  ;update(dt) function here - this is where you respond to player input, move entities, change tiles, etc
  render()  ;This draws the game state
  Sleep, 10 ;Later this can be changed to something fancier, to limit fps or such
}

;Quick and dirty camera movement
#If WinActive("ahk_id " g_render.hwnd)
a::SetCameraPos(-0.2, 0)  ;SetCameraPos accepts floating point values
d::SetCameraPos(0.2, 0)
w::SetCameraPos(0, -0.2)
s::SetCameraPos(0, 0.2)