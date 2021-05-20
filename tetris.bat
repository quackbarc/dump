::
:: tetris.bat
:: - a fork of tetris that i made back in 2018.
:: - runs really slowly -- around 100ms to 400 ms between refreshes.
:: - changes:
::    - commented on some sections, tabbed a couple parts.
::    - removed some lines that really reeked 2018 me

@echo off
setlocal enabledelayedexpansion
chcp 65001>nul

if [%screen2%]==[a] goto begin
if [%screen2%]==[b] goto splitStart

del "%temp%\tetris_*" /q >nul 2>nul
set transmission=%random%
set transmissionloc=%temp%\tetris_%transmission%

set screen2=a
start /high "" "%~nx0"
set screen2=b
start /high "" "%~nx0"
goto :eof

:begin
color 0f
title tetris
mode con cols=46 lines=20
cls
echo.
echo.
echo.    ██████ ██████ ██████ ██████ ██ ██████ 
echo.      ██   ██       ██   ██  ██ ██ ██
echo.      ██   ████     ██   ████   ██ ██████
echo.      ██   ██       ██   ██  ██ ██     ██
echo.      ██   ██████   ██   ██  ██ ██ ██████
echo. ████████████████████████████████████████████
echo.
echo.           TETRIS IN BATCH ^(v1.0.1^)
echo.                 by QuackBarc
echo.
echo.       Press any key within the control
echo.           window to start the game.
echo.
echo.      Position the control window however
echo.                   you want.
echo.

:inputCheck_start
set controlOut=
if exist "%transmissionloc%" (
	for /f %%a in (%transmissionloc%) do set controlOut=%%a
) 2>nul else goto inputCheck_start
if [%controlOut%]==[] goto inputCheck_start

set controlOut=%controlOut:~0,-1%
del %transmissionloc%
:: wonder what happens if i decide to not delete them

if [%controlOut%]==[0] goto init
goto inputCheck_start

:splitStart
:: starting screen, control window.
color 0f
title tetris - controls
mode con cols=35 lines=6

echo.
echo. -+ hi i'm the control window +-
echo.    press any key to continue
echo.
set /p =. ^> <nul
pause>nul

<nul set /p =0.>%transmissionloc%
goto splitControl

:init
:: initialization of game variables and such
mode con lines=30 cols=55
echo.
echo. Initializing game...

set emptycell=░░
set fillcell=██
set ymax=20
set xmax=10
set screen2=
set frames=0
set frames_p=0
set falltick=0
set falltick_p=0
set lines=0
set blockRot=0
set origin_x=5
set origin_y=19

set level=1

set /a falldelay=55-(%level%*5)
set /a blocktype3=%random%*7/32768
set /a blocktype2=%random%*7/32768
set /a blocktype1=%random%*7/32768
set /a blocktype=%random%*7/32768

set /a ymax_z=%ymax%-1
set /a xmax_z=%xmax%-1
for /l %%a in (0,1,%ymax_z%) do for /l %%b in (0,1,%xmax_z%) do set boardF_y%%ax%%b=%emptycell%
for /l %%a in (0,1,%ymax_z%) do for /l %%b in (0,1,%xmax_z%) do set board_y%%ax%%b=%emptycell%
for /l %%a in (0,1,%xmax_z%) do set boardY_B=!boardY_B!%emptycell%
for /l %%a in (0,1,%xmax_z%) do set boardY=!boardY!%fillcell%
for /l %%a in (0,1,5) do set prev_B=!prev_B!%emptycell%

goto upNext

:touchFlag
set swapflag=
for /l %%a in (0,1,3) do set boardF_y!square%%a_y!x!square%%a_x!=%fillcell%
if [%dropFlag%]==[a] goto gameOver
set dropFlag=a
:newBlock
:: reorders the upcoming block list.
if [%swapFlag%]==[a] goto setDisplay
if [%holdFlag%]==[a] (
	if not [%blocktype0%]==[] (
		set swapFlag=a
		set tempblock=!blocktype!
		set blocktype=!blocktype0!
		set blocktype0=!tempblock!
	) else (
		set swapFlag=a
		set blocktype0=!blocktype!
		set blocktype=!blocktype1!
		set blocktype1=!blocktype2!
		set blocktype2=!blocktype3!
		set /a blocktype3=!random!*7/32768
	)
) else (
	set blocktype=!blocktype1!
	set blocktype1=!blocktype2!
	set blocktype2=!blocktype3!
	set /a blocktype3=!random!*7/32768
)
set blockRot=0
set origin_x=5
set origin_y=19
set falltick=
for /f "delims=:. tokens=3,4" %%a in ("%time%") do set msold=%%b&set sold=%%a
if [%dropFlag%]==[] if [%holdFlag%]==[] goto previewDisplay
set holdflag=

:upNext
:: sets up display of the upcoming blocks.
for /f "delims=:. tokens=1-4" %%a in ("!time!") do set /a "t2=((1%%a*60+1%%b)*60+1%%c)*100+1%%d-36610100"
for /l %%a in (0,1,3) do (
	for /l %%b in (0,1,3) do for /l %%c in (0,1,5) do set prev%%a_y%%bx%%c=%emptycell%
	if [!blocktype%%a!]==[0] set fillcells=y2x2, y2x3, y1x2, y1x3
	if [!blocktype%%a!]==[1] set fillcells=y1x1, y1x2, y1x3, y1x4
	if [!blocktype%%a!]==[2] set fillcells=y1x1, y1x2, y2x2, y2x3
	if [!blocktype%%a!]==[3] set fillcells=y1x2, y1x3, y2x1, y2x2
	if [!blocktype%%a!]==[4] set fillcells=y1x1, y2x1, y2x2, y2x3
	if [!blocktype%%a!]==[5] set fillcells=y1x3, y2x1, y2x2, y2x3
	if [!blocktype%%a!]==[6] set fillcells=y1x2, y2x1, y2x2, y2x3
	for %%b in (!fillcells!) do set prev%%a_%%b=%fillcell%
)

:setDisplay
set hardDrop=
set lineClearFlag=
set /a level=%lines%/10
set /a falldelay=55-(%level%*5)
if %level% gtr 10 set falldelay=2
if [%movement%]==[2] set /a origin_x+=1
if [%movement%]==[1] set /a origin_x-=1
if %blockRot% gtr 3 set blockRot=0
if %blockRot% lss 0 set blockRot=3
if %origin_x% lss 0 set origin_x=0
if %origin_x% gtr %xmax_z% set origin_x=%xmax_z%
for /l %%a in (0,1,%ymax_z%) do set board_y%%a=
for /l %%a in (0,1,%ymax_z%) do for /l %%b in (0,1,%xmax_z%) do (
	if not [!boardF_y%%ax%%b!]==[] (
		set board_y%%ax%%b=!boardF_y%%ax%%b!
	) else set board_y%%ax%%b=%emptycell%
)

for /l %%a in (0,1,%ymax_z%) do (
	set boardF_y%%a=
	for /l %%b in (0,1,%xmax_z%) do set boardF_y%%a=!boardF_y%%a!!boardF_y%%ax%%b!
)


if [%dropFlag%]==[] goto blockSet
for /l %%a in (0,1,%ymax_z%) do if [!boardF_y%%a!]==[%boardY%] (
	set lineClearFlag=a
	set boardF_y%%a=
	set /a lines+=1
	for /l %%b in (0,1,%xmax_z%) do set boardF_y%%ax%%b=
)

if [%lineClearFlag%]==[] goto blockSet
set lcsFlag=
for /l %%a in (%ymax_z%,-1,0) do if [!lcsFlag!]==[] (if not [!boardF_y%%a!]==[] set lcsFlag=%%a) else (
	if [!boardF_y%%a!]==[] for /l %%b in (%%a,1,!lcsFlag!) do (
		set /a tempY=%%b+1
		for /l %%c in (0,1,%xmax_z%) do for /f %%d in ("!tempY!") do set boardF_y%%bx%%c=!boardF_y%%dx%%c!
))
goto setDisplay

:blockSet
:: sets up display for the current tetramino.
set flowFlag=
set flowSquare=
for /l %%a in (0,1,3) do ( 
	set square%%a_x=%origin_x%
	set square%%a_y=%origin_y%
)
:: ████
:: ████
if [%blocktype%]==[0] (
	set /a square1_x-=1
	set /a square2_y-=1
	set /a square3_x-=1
	set /a square3_y-=1
)
:: ████████
if [%blocktype%]==[1] (
	if %blockRot% gtr 1 set blockRot=0
	if %blockRot% lss 0 set blockRot=1
	if [!blockRot!]==[0] (
	set /a square1_x+=1
	set /a square2_x-=1
	set /a square3_x-=2
	)
	if [!blockRot!]==[1] (
	set /a square1_y-=1
	set /a square2_y+=1
	set /a square3_y+=2
	)
)
::   ████
:: ████
if [%blocktype%]==[2] (
	if %blockRot% gtr 1 set blockRot=0
	if %blockRot% lss 0 set blockRot=1
	if [!blockRot!]==[0] (
	set /a square1_x+=1
	set /a square2_y-=1
	set /a square3_x-=1
	set /a square3_y-=1
	)
	if [!blockRot!]==[1] (
	set /a square1_y-=1
	set /a square2_x-=1
	set /a square3_x-=1
	set /a square3_y+=1
	)
)
:: ████
::   ████
if [%blocktype%]==[3] (
	if %blockRot% gtr 1 set blockRot=0
	if %blockRot% lss 0 set blockRot=1
	if [!blockRot!]==[0] (
	set /a square1_x-=1
	set /a square2_y-=1
	set /a square3_x+=1
	set /a square3_y-=1
	)
	if [!blockRot!]==[1] (
	set /a square1_y+=1
	set /a square2_x-=1
	set /a square3_x-=1
	set /a square3_y-=1
	)
)
:: ██████
:: ██
if [%blocktype%]==[4] (
	if [!blockRot!]==[0] (
	set /a square1_x+=1
	set /a square2_x-=1
	set /a square3_x-=1
	set /a square3_y-=1
	)
	if [!blockRot!]==[1] (
	set /a square1_y-=1
	set /a square2_y+=1
	set /a square3_x-=1
	set /a square3_y+=1
	)
	if [!blockRot!]==[2] (
	set /a square1_x-=1
	set /a square2_x+=1
	set /a square3_x+=1
	set /a square3_y+=1
	)
	if [!blockRot!]==[3] (
	set /a square1_y+=1
	set /a square2_y-=1
	set /a square3_x+=1
	set /a square3_y-=1
	)
)
:: ██████
::     ██
if [%blocktype%]==[5] (
	if [!blockRot!]==[0] (
	set /a square1_x-=1
	set /a square2_x+=1
	set /a square3_x+=1
	set /a square3_y-=1
	)
	if [!blockRot!]==[1] (
	set /a square1_y+=1
	set /a square2_y-=1
	set /a square3_x-=1
	set /a square3_y-=1
	)
	if [!blockRot!]==[2] (
	set /a square1_x+=1
	set /a square2_x-=1
	set /a square3_x-=1
	set /a square3_y+=1
	)
	if [!blockRot!]==[3] (
	set /a square1_y-=1
	set /a square2_y+=1
	set /a square3_x+=1
	set /a square3_y+=1
	)
)
:: ██████
::   ██
if [%blocktype%]==[6] (
	if [!blockRot!]==[0] (
	set /a square1_x-=1
	set /a square2_x+=1
	set /a square3_y-=1
	)
	if [!blockRot!]==[1] (
	set /a square1_y+=1
	set /a square2_y-=1
	set /a square3_x-=1
	)
	if [!blockRot!]==[2] (
	set /a square1_x+=1
	set /a square2_x-=1
	set /a square3_y+=1
	)
	if [!blockRot!]==[3] (
	set /a square1_y-=1
	set /a square2_y+=1
	set /a square3_x+=1
	)
)
if [%hardDrop%]==[a] goto blockDrop

:::::::::::::::::::::::::::::::::::::

for /l %%a in (0,1,3) do (
	set flowSquare=%%a
	if !square%%a_x! lss 0 (
		set /a origin_x-=!square%%a_x!
		goto blockSet
	)
	if !square%%a_x! gtr %xmax_z% (
		set /a origin_x-=!square%%a_x!-%xmax_z%
		goto blockSet
	)
	for /f %%b in ("!square%%a_y!") do for /f %%c in ("!square%%a_x!") do if [!boardF_y%%bx%%c!]==[%fillcell%] (
		if [%movement%]==[1] (
		set /a origin_x+=1
		set movement=
		goto blockSet
	) else if [%movement%]==[2] (
		set /a origin_x-=1
		set movement=
		goto blockSet
)))
set movement=

:previewDisplay
:: main screen, main window.
for /l %%a in (0,1,3) do for /l %%b in (0,1,3) do (
	set prev%%a_y%%b=
	for /l %%c in (0,1,5) do set prev%%a_y%%b=!prev%%a_y%%b!!prev%%a_y%%bx%%c!
)
for /l %%a in (0,1,3) do set board_y!square%%a_y!x!square%%a_x!=%fillcell%
for /l %%a in (0,1,%ymax_z%) do (
	set board_y%%a=
	for /l %%b in (0,1,%xmax_z%) do set board_y%%a=!board_y%%a!!board_y%%ax%%b!
)
set tempgen=%ymax_z%
set tickRatio=0
set /a tickRatio=%frames_p%*50/%falltick_p%
cls
echo.
echo.                        TETRIS
echo.
echo.       HOLD      !board_y%tempgen%!      NEXT

set /a tempgen-=1
for /l %%a in (1,1,3) do for /l %%b in (3,-1,0) do for /f %%c in ("!tempgen!") do (
	if [%%a]==[1] (
		echo.   !prev0_y%%b!  !board_y%%c!  !prev%%a_y%%b!
	) else (
		echo.                 !board_y%%c!  !prev%%a_y%%b!
	)
	set /a tempgen-=1
)

for /l %%a in (%tempgen%,-1,0) do echo.                 !board_y%%a!
echo.                 0 1 2 3 4 5 6 7 8 9
echo.
echo. LINES: %lines%         LEVEL: %level%

:tickOld
if [%msold%]==[] if [%sold%]==[] for /f "delims=:. tokens=3,4" %%a in ("%time%") do set msold=%%b&set sold=%%a
if [%msold:~0,1%]==[0] set msold=%msold:~1%
if [%sold:~0,1%]==[0] set sold=%sold:~1%
set /a msold_x=%msold%+2
if not [%snew%]==[] if [%sold%]==[] set sold=0
:tickNew
for /f "delims=:. tokens=3,4" %%a in ("%time%") do set msnew=%%b&set snew=%%a
if [%msnew:~0,1%]==[0] set msnew=%msnew:~1%
if [%snew:~0,1%]==[0] set snew=%snew:~1%
set /a frames+=1
if %snew% lss %sold% (set /a snew_h=%snew%+60) else set snew_h=%snew%
set msnew_h=%msnew%
if not [%snew_h%]==[%sold%] if %msnew_h% lss %msold_x% set /a msnew_h+=(%snew_h%-%sold%)*100
if %msnew_h% geq %msold_x% (
	set msold=%msnew%
	set sold=%snew%
	goto tickCheck
) else goto tickNew
:tickCheck
set temptick=
set /a temptick+=%msnew_h%-%msold_x%
set /a temptick*=5
if [!temptick:~-1!]==[5] set /a temptick+=5
set /a temptick/=10
set /a falltick+=%temptick%
set /a falltick+=1
if !falltick! geq %falldelay% (
	set fallTick_p=!falltick!
	set frames_p=!frames!
	set falltick=0
	set frames=0
	goto blockDrop
)
:inputCheck
set controlOut=
if exist "%transmissionloc%" (for /f %%a in (%transmissionloc%) do set controlOut=%%a) 2>nul else goto tickOld
if [%controlOut%]==[] goto tickOld

set controlOut=%controlOut:~0,-1%
del %transmissionloc%
if [%controlOut%]==[8] exit
if [%controlOut%]==[7] set holdFlag=a&goto newBlock
if [%controlOut%]==[6] set hardDrop=a&goto blockDrop
if [%controlOut%]==[5] goto blockDrop
if [%controlOut%]==[4] set /a blockrot+=1
if [%controlOut%]==[3] set movement=2
if [%controlOut%]==[2] set movement=1
if [%controlOut%]==[1] goto pause
goto setDisplay

:blockDrop

set /a origin_y-=1
:touchCheck
set tempsquare=
for /l %%a in (0,1,3) do (
	set /a tempsquare=!square%%a_y!-1
	if [!tempsquare!]==[-1] goto touchFlag
	for /f %%b in ("!tempsquare!") do for /f %%c in ("!square%%a_x!") do (
		if [!boardF_y%%bx%%c!]==[%fillcell%] goto touchFlag
	)
	set dropFlag=
)
if [%hardDrop%]==[a] goto blockSet
goto setDisplay

:splitControl
:: main screen, control window.
title tetris - controls
set inputs=ADWSZCI
color 0f
mode con cols=30 lines=10
echo.
echo. W   rotate right/clockwise
echo. AD  move left/right
echo. SZ  soft/hard drop
echo. C   hold block
echo. P   pause
echo. I   exit
echo.
set /p =. ^> <nul
choice /n /c P%inputs%
set input=%errorlevel%
<nul set /p =%input%.>%transmissionloc%
if [%input%]==[8] exit
if [%input%]==[1] goto splitPause
goto splitControl


:gameOver
:: game over screen, main window.
echo. game over.
echo. Press I in the control window to exit.
echo.
:inputded
set controlOut=
if exist "%transmissionloc%" (for /f %%a in (%transmissionloc%) do set controlOut=%%a) 2>nul else goto inputded
if [%controlOut%]==[] goto inputded
set controlOut=%controlOut:~0,-1%
if [%controlOut%]==[8] exit
goto inputded

:splitPause
:: pause screen, control window.
title tetris - paused
set inputs=PX
color 0f
mode con cols=30 lines=6
echo.
echo. P   continue
echo. X   exit
echo.
set /p =. ^> <nul
choice /n /c %inputs%
set input=%errorlevel%
<nul set /p =%input%.>%transmissionloc%
if [%input%]==[2] exit
if [%input%]==[1] goto splitControl
goto splitPause

:pause
:: pause screen, main window.
set tempGen=%ymax%
cls
echo.
echo.                        TETRIS
echo.
echo.       HOLD      %boardY_B%      NEXT
set /a tempgen-=1
for /l %%a in (1,1,3) do for /l %%b in (3,-1,0) do for /f %%c in ("!tempgen!") do (
	if [%%a]==[1] (echo.   %prev_B%  %boardY_B%  %prev_B%) else echo.                 %boardY_B%  %prev_B%
	set /a tempgen-=1
)
for /l %%a in (%tempgen%,-1,1) do echo.                 %boardY_B%
echo.                 0 1 2 3 4 5 6 7 8 9
echo.
echo. LINES: %lines%         LEVEL: %level%
echo. Press P in the control window to unpause the game.
echo. Press X to exit.
echo.
:inputCheck_pause
set controlOut=
if exist "%transmissionloc%" (for /f %%a in (%transmissionloc%) do set controlOut=%%a) 2>nul else goto inputCheck_pause
if [%controlOut%]==[] goto inputCheck_pause
set controlOut=%controlOut:~0,-1%
del %transmissionloc%
if [%controlOut%]==[2] exit
if [%controlOut%]==[1] goto setDisplay
goto inputCheck_pause

:: i'm dumb with licensing so i'm not sure how to license
:: a copy of Tetris i made for fun.
::
:: please do not sue