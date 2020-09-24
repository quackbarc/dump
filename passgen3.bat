::
:: passgen3.bat
:: - opening easter egg didn't work well. now fixed
:: - removed some easter egg notes since god was i immature when i made this

@echo off
setlocal enabledelayedexpansion
if [%reboot%]==[a] goto init
set reboot=a
:: moved the random generator here. command prompt is actually pretty awful at random seeding
set /a ran=%random%*50/32768
start "" "%~f0"
goto :eof

:init
mode con: cols=46 lines=15
call :index
if %ran% equ 49 (
	title quackbarc by password generator
) else if %ran% equ 48 (
	title generator by password generator
) else if %ran% equ 47 (
	title password generator by %username%
) else if %ran% equ 46 (
	title password by generator
) else if %ran% equ 45 (
	title generator password by quackbarc
) else title %ran% -- password generator by quackbarc
set length=16
set allowUpper=X
set allowLower=X
set allowNum=X
set allowSym=X
set allowExSym= 
set avoidSimilar= 
:yeah
set list=
set listNo=0
if "%allowLower%"=="X" (
	set list=%list% low
	set /a listNo+=1
)
if "%allowUpper%"=="X" (
	set list=%list% up
	set /a listNo+=1
)
if "%allowNum%"=="X" (
	set list=%list% num
	set /a listNo+=1
)
if "%allowSym%"=="X" (
	set list=%list% sym
	set /a listNo+=1
)
if "%allowExSym%"=="X" (
	set list=%list% exsym
	set /a listNo+=1
)

set pass=
for /l %%a in (1,1,%length%) do (
	set /a pickAway=!random!*%listNo%/32768+1
	for /f "tokens=1-4" %%1 in ("%list%") do (
		if !pickAway! equ 1 set side=%%1
		if !pickAway! equ 2 set side=%%2
		if !pickAway! equ 3 set side=%%3
		if !pickAway! equ 4 set side=%%4
	)
	for /f %%b in ("!side!") do (
		if "%avoidSimilar%"=="X" (
			set /a select=!random!*!%%bALimit!/32768
		) else set /a select=!random!*!%%bLimit!/32768
		for /f %%c in ("!select!") do (
			if not "!side!"=="sym" (
				if not "!side!"=="exsym" (
					if "%avoidSimilar%"=="X" (
						set pass=!pass!!%%bAIndex:~%%c,1!
					) else set pass=!pass!!%%bIndex:~%%c,1!
				) else if "%avoidSimilar%"=="X" (
					set pass=!pass!!%%bA%%c!
				) else set pass=!pass!!%%b%%c!
			) else set pass=!pass!!%%b%%c!
		)
	)
)
set plus= 
if %length% gtr 40 set plus=[91m+
set passPrev=!pass!                                        
if [%inLength%]==[a] goto :length
:display
set copyText=to copy to clipboard
if [%copy%]==[a] set copyText=copied              
if [%copy%]==[c] set copyText=copied..?           
if [%copy%]==[b] set copyText=but it's blank      
echo.[?25l[0;0f
echo.
echo.
echo.[3;0f   [37m1  [-] [90mlength [37m%length%[0m         
echo.   [37m2  [[91m%allowLower%[37m] [90mlowercase letters[0m
echo.   [37m3  [[91m%allowUpper%[37m] [90muppercase letters[0m
echo.   [37m4  [[91m%allowNum%[37m] [90mnumbers[0m
echo.   [37m5  [[91m%allowSym%[37m] [90msymbols[0m
echo.   [37m6  [[91m%allowExSym%[37m] [90mextra symbols[0m
echo.   [37m7  [[91m%avoidSimilar%[37m] [90mavoid similar characters[0m
echo.
if %length% equ -1 (
	if "%list%"=="" (
		echo.   [97myou make me suffer                       [0m
	) else echo.   [97mwhy would you need it that low?          [0m
) else if %length% equ 0 (
	echo.
) else if "%list%"=="" (
	if "%avoidSimilar%"=="X" (
		echo.   [90mthere are no characters to avoid          [0m
	) else echo.   [90myou need to select at least something    [0m
) else echo.   [97m!passPrev:~0,40!%plus%[0m
echo.   [37m1-7[90m to customize  [37mQ[90m %copyText%[0m
set copy=
set /p=.   [37mR[90m to regenerate a password  [37mX[90m to exit[0m  [?25h<nul
choice /n /c XRQ7654321
if %errorlevel% equ 10 (
	set inLength=a
	goto length
)
if %errorlevel% equ 9 (
	if "%allowLower%"=="X" (
		set allowLower= 
	) else set allowLower=X
	goto yeah
)
if %errorlevel% equ 8 (
	if "%allowUpper%"=="X" (
		set allowUpper= 
	) else set allowUpper=X
	goto yeah
)
if %errorlevel% equ 7 (
	if "%allowNum%"=="X" (
		set allowNum= 
	) else set allowNum=X
	goto yeah
)
if %errorlevel% equ 6 (
	if "%allowSym%"=="X" (
		set allowSym= 
	) else set allowSym=X
	goto yeah
)
if %errorlevel% equ 5 (
	if "%allowExSym%"=="X" (
		set allowExSym= 
	) else set allowExSym=X
	goto yeah
)
if %errorlevel% equ 4 (
	if "%avoidSimilar%"=="X" (
		set avoidSimilar= 
	) else set avoidSimilar=X
	goto yeah
)
if %errorlevel% equ 3 (
	if "!pass!"=="" (
		set copy=b
	) else if "%list%"=="" (
		echo|set /p=it takes half an hour of dedication to write all these easter eggs and you should be proud that you found one just now|clip
		set copy=c
	) else (
		echo|set /p"=!pass!"|clip
		set copy=a
	)
	goto display
)
if %errorlevel% equ 2 goto yeah
if %errorlevel% equ 1 exit
exit

:length
echo.[?25l[0;0f
echo.
echo.   [37m1  [   [90mlength [37m%length%[0m   ]         
echo.   [37m2  [[91m%allowLower%[37m] [90mlowercase letters[0m
echo.   [37m3  [[91m%allowUpper%[37m] [90muppercase letters[0m
echo.   [37m4  [[91m%allowNum%[37m] [90mnumbers[0m
echo.   [37m5  [[91m%allowSym%[37m] [90msymbols[0m
echo.   [37m6  [[91m%allowExSym%[37m] [90mextra symbols[0m
echo.   [37m7  [[91m%avoidSimilar%[37m] [90mavoid similar characters[0m
echo.
if %length% equ -1 (
	echo.   [97m...                                      
) else if "%list%"=="" (
	echo.   [97m                                         
) else echo.   [97m!passPrev:~0,40!%plus%[0m
echo.                                            
echo.                                            
set /p=. [13;1f   [37mWS[90m to increase/decrease  [37mX[90m to go back[0m  [?25h<nul
choice /n /c XWS
if %errorlevel% equ 3 (
	set /a length-=1
	if !length! equ -2 set /a length=-1
	goto yeah
)
if %errorlevel% equ 2 (
	set /a length+=1
	goto yeah
)
if %errorlevel% equ 1 (
	set inLength=
	goto display
)
exit

:index
:: UPPERCASE
set upLimit=26
set upIndex=QWERTYUIOPASDFGHJKLZXCVBNM
set upALimit=24
set upAIndex=QWERTYUPASDFGHJKLZXCVBNM
:: LOWERCASE
set lowLimit=26
set lowIndex=qwertyuiopasdfghjklzxcvbnm
set lowALimit=25
set lowAIndex=qwertyuiopasdfghjkzxcvbnm
:: NUMBERS
set numLimit=10
set numIndex=1234567890
set numALimit=8
set numAIndex=23456789
:: SYMBOLS
set symLimit=13
set symALimit=%symLimit%
set sym0=^^^!
set sym1=^^
set sym2=%%
set sym3=*
set sym4=$
set sym5=#
set sym6=@
set sym7=_
set sym8=+
set sym9=?
set sym10=-
set sym11==
set sym12=^&
:: EXTRA SYMBOLS
:: for the sake of my sanity, " isn't added. it'll break the entire thing
set exSymLimit=18
set exSym0=~
set exSym1=^(
set exSym2=^)
set exSym3={
set exSym4=}
set exSym5=[
set exSym6=]
set exSym7=\
set exSym8=^|
set exSym9=;
set exSym10=:
set exSym11='
set exSym12=,
set exSym13=^<
set exSym14=^>
set exSym15=.
set exSym16=/
set exSym17=`
:: EXTRA SYMBOLS W/P SIMILAR CHARACTERS
set exSymALimit=15
set exSymA0=~
set exSymA1=^(
set exSymA2=^)
set exSymA3={
set exSymA4=}
set exSymA5=[
set exSymA6=]
set exSymA7=\
set exSymA8=;
set exSymA9=:
set exSymA10=,
set exSymA11=^<
set exSymA12=^>
set exSymA13=.
set exSymA14=/
goto :eof

:: there used to be 40 more blank lines in here, following the comment "pee"