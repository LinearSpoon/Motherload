#Persistent
#NoEnv
#SingleInstance Force

#include render.ahk
#include gdi.ahk
#include timer.ahk

SetBatchLines, -1

global g_render := {}  ;Information needed for render.ahk
global map := {}       ;Game tile map
