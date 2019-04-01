@echo off
setlocal enabledelayedexpansion
if [%rB%]==[a] goto init
set rB=a
start "" "%~f0"
goto :eof

:init
mode con: lines=9 cols=33
set streak=0
:start
title colorguess
for /l %%a in (0,1,4) do (
	set /a "color%%a=(!random!*5/32768)+1"
)
for /l %%a in (0,1,4) do set /a colorI%%a=1
if %streak% leq 999 (
	set streakP=%streak%
) else set streakP=999[91m+
set tries=12
set noChange=a
set wrong=
set colorPrev=

:disp
set colorIPrev=
for /l %%a in (0,1,4) do (
	if !colorI%%a! equ 1 (
		set colorIPrev=!colorIPrev![10!colorI%%a!;97m - [0m 
	) else if !colorI%%a! equ 4 (
		set colorIPrev=!colorIPrev![10!colorI%%a!;97m - [0m 
	) else if !colorI%%a! equ 5 (
		set colorIPrev=!colorIPrev![10!colorI%%a!;97m - [0m 
	) else set colorIPrev=!colorIPrev![10!colorI%%a!;30m - [0m 
)
set triesP=  %tries%
set es=
echo.[0;0f[?25l
echo.
if not "%wrong%"=="" (
	if not [%wrong%]==[1] set es=es
	echo.   [97m%wrong%[91m switch!es! incorrect [0m
) else echo.                       
echo.   %colorIPrev%  tries	
echo.   [37m 1   2   3   4   5      [97m%triesP:~-2%[0m
echo.
if %streak% equ 0 (
	echo.  [97m 1-5[37m to alter          
) else echo.  [97m 1-5[37m to alter  [90mstreak: [97m%streakP%[0m
set wrong=
set /p =.  [97m P[37m to check   [97m X[37m to exit  [0m [?25h<nul
choice /n /c XP12345
set error=%errorlevel%
if %error% geq 3 (
	set /a yeah=error-3
	for /f %%a in ("!yeah!") do (
		set /a colorI%%a+=1
		if !colorI%%a! gtr 5 set /a colorI%%a=1
	)
	set noChange=
	goto disp
)
if %error% equ 2 goto check
if %error% equ 1 exit
exit

:check
set wrong=0
for /l %%a in (0,1,4) do if !colorI%%a! neq !color%%a! set /a wrong+=1
set /a tries-=1
if %wrong% equ 0 goto end
if %tries% equ 0 goto end
goto disp

:end
set triesP=  %tries%
for /l %%a in (0,1,4) do (
	if !color%%a! equ 1 (
		set colorPrev=!colorPrev![10!color%%a!;97m - [0m 
	) else if !color%%a! equ 4 (
		set colorPrev=!colorPrev![10!color%%a!;97m - [0m 
	) else if !color%%a! equ 5 (
		set colorPrev=!colorPrev![10!color%%a!;97m - [0m 
	) else set colorPrev=!colorPrev![10!color%%a!;30m - [0m 
)
echo.[0;0f
echo.
echo.   %colorPrev%
echo.   %colorIPrev%  tries	
echo.   [37m 1   2   3   4   5      [97m%triesP:~-2%[0m
echo.
if %wrong% equ 0 (
	echo.   you won                     
	set /a streak+=1
) else (
	if [%noChange%]==[a] (
		echo.   you didn't even try         
	) else echo.   you lost                 
	set streak=0
)
set /p =.   press[97m any key[37m to try again [0m<nul
pause >nul
goto start