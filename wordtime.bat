::
:: wordtime.bat
:: = shows a visual word clock

@echo off
setlocal enabledelayedexpansion
if defined reboot goto reboot
set reboot=a
start "" "%~dpnx0"
goto :eof

:reboot
mode con: cols=27 lines=15
chcp 65001>nul
title word clock^^^!

:adjustables
:: themes:
::  - red			cf 97 31
::  - matrix		0f 97 32
::  - dark, teal	0f 36 90
::  - dark, yellow	0f 93 90
::  - black/white	0f 97 90
set color=0f
set color_white=[93m
set color_white2=[37m
set color_dark=[90m

call :time
color %color%
cls

:: 12 hour time
:main
set /a hour12=%hour%%%12
if %hour12% equ 0 set hour12=12
if %hour% geq 12 (
	set period=PM
) else set period=AM

:: bottom time display
:pre_layout
for %%a in (minute second period) do (
	set %%a_prev=0!%%a!
	set %%a_prev=!%%a_prev:~-2!
)
set hour12_prev= %hour12%
set hour12_prev=%hour12_prev:~-2%

:coloring
for %%a in (oclock five ten quarter twenty half past to) do set color_%%a=%color_dark%
for /l %%a in (1,1,12) do set color_%%a=%color_dark%

if 0 leq %minute% if %minute% leq 4 set color_oclock=%color_white%

if 5 leq %minute% if %minute% leq 9 set color_five=%color_white%
if 10 leq %minute% if %minute% leq 14 set color_ten=%color_white%
if 15 leq %minute% if %minute% leq 19 set color_quarter=%color_white%
if 20 leq %minute% if %minute% leq 29 set color_twenty=%color_white%
if 24 leq %minute% if %minute% leq 29 set color_five=%color_white%
if 30 leq %minute% if %minute% leq 34 set color_half=%color_white%
if 5 leq %minute% if %minute% leq 34 (
	set /a hour12_to=%hour12%
	set color_past=%color_white%
)

if 35 leq %minute% if %minute% leq 39 set color_five=%color_white%
if 35 leq %minute% if %minute% leq 44 set color_twenty=%color_white%
if 45 leq %minute% if %minute% leq 49 set color_quarter=%color_white%
if 50 leq %minute% if %minute% leq 54 set color_ten=%color_white%
if 54 leq %minute% if %minute% leq 59 set color_five=%color_white%
if 35 leq %minute% if %minute% leq 59 (
	set /a hour12_to=%hour12%+1
	set color_to=%color_white%
)

set color_%hour12_to%=%color_white%


:layout
echo.[0;0f[?25l%color_dark%
echo.
echo.   %color_white%I T %color_dark%D %color_white%I S %color_dark%W C B Y D R
echo.   A E %color_quarter%Q U A R T E R %color_dark%H L
echo.   %color_twenty%T W E N T Y %color_five%F I V E %color_dark%W
echo.   %color_half%H A L F %color_dark%P %color_ten%T E N %color_dark%Y %color_to%T O
echo.   %color_past%P A S T %color_dark%Q L O %color_9%N I N E
echo.   %color_1%O N E %color_6%S I X %color_3%T H R E E
echo.   %color_4%F O U R %color_5%F I V E %color_2%T W O
echo.   %color_8%E I G H T %color_11%E L E V E N
echo.   %color_7%S E V E N %color_12%T W E L V E
echo.   %color_10%T E N %color_dark%M S %color_oclock%O'C L O C K
echo.  %color_white2%───── %color_white%%hour12_prev%:%minute_prev%:%second_prev% %color_white2%%period_prev% ─────

:loop
call :time
if %second% equ %old_second% goto loop
set /a old_second=second
goto main

:: CALL LABELS
:time
for /f "delims=:. tokens=1-4" %%a in ("%time%") do (
	for /f %%A in ("%%a") do set hour=%%A
	set /a minute=1%%b-100
	set /a second=1%%c-100
	set /a centisecond=1%%d-100
)