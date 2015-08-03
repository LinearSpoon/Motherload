#Persistent
#NoEnv
#SingleInstance Force

#include gdi.ahk
#include timer.ahk
#include render.ahk

SetBatchLines, -1

global g_render := {}  ;Information needed for render.ahk
global map := {}       ;Game tile map
