@echo off
set COMPILEDIR=%CD%

title "MOD COMPILER @ ZORO"

for %%* in (.) do set modname=%%~n*
:MAKEOPTIONS
cls
:MAKEOPTIONS
echo ________________________________________________________________________
echo.
echo  Please select an option:
echo    1. Build Fast File (.ff)
echo    2. Dedicated Server and Start Game (WAR)
echo    3. Dedicated Server and Start Game (DM)
echo    4. Dedicated Server and Start Game (SD)
echo    5. Dedicated Server
echo    6. Start Game and Connect
echo    7. Start Game 
echo.
echo ________________________________________________________________________
echo.
echo    Mod Name = %modname%
echo.
echo ________________________________________________________________________
echo.
set /p make_option=:
set make_option=%make_option:~0,1%
if "%make_option%"=="1" goto build_ff
if "%make_option%"=="2" goto war
if "%make_option%"=="3" goto dm
if "%make_option%"=="4" goto sd
if "%make_option%"=="5" goto dedicated
if "%make_option%"=="6" goto STARTGAMECON
if "%make_option%"=="7" goto STARTGAME

goto :MAKEOPTIONS
:build_ff
cls
cd
echo ------------------------------------------------------------------------------------------------------------------------
echo  Building mod.ff:
echo    Deleting old mod.ff file...
del mod.ff
echo    Copying rawfiles...
xcopy shock ..\..\raw\shock /SY
xcopy images ..\..\raw\images /SY
xcopy materials ..\..\raw\materials /SY
xcopy material_properties ..\..\raw\material_properties /SY
xcopy sound ..\..\raw\sound /SY
xcopy soundaliases ..\..\raw\soundaliases /SY
xcopy fx ..\..\raw\fx /SY
xcopy mp ..\..\raw\mp /SY
xcopy weapons\mp ..\..\raw\weapons\mp /SY
xcopy xanim ..\..\raw\xanim /SY
xcopy promod ..\..\raw\promod /SY
xcopy xmodel ..\..\raw\xmodel /SY
xcopy techniques ..\..\raw\techniques /SY
xcopy xmodelparts ..\..\raw\xmodelparts /SY
xcopy xmodelsurfs ..\..\raw\xmodelsurfs /SY
xcopy ui ..\..\raw\ui /SY
xcopy ui_mp ..\..\raw\ui_mp /SY
xcopy english ..\..\raw\english /SY
xcopy vision ..\..\raw\vision /SY
xcopy animtrees ..\..\raw\animtrees /SYI > NUL
echo    Copying source code...
xcopy maps ..\..\raw\maps /SY
xcopy promod_ruleset ..\..\raw\promod_ruleset /SY
echo    Copying MOD.CSV...
xcopy mod.csv ..\..\zone_source /SY
echo    Compiling mod...
cd ..\..\bin
linker_pc.exe -language english -compress -cleanup mod
cd %COMPILEDIR%
copy ..\..\zone\english\mod.ff
echo  New mod.ff file successfully built ;D
echo Completed: %time%
echo ------------------------------------------------------------------------------------------------------------------------
pause
goto :MAKEOPTIONS

:dedicated
cd ..\..\ 
START cod4x18_dedrun.exe +set dedicated 2 +exec server.cfg +set gametype sd +set r_xassetnum "material=2560 xmodel=1200" +set developer 1 +set fs_game mods/%modname% +map mp_crash
cd %COMPILEDIR%
goto :MAKEOPTIONS

:STARTGAMECON
cls
cd ..\..\
START iw3mp.exe allowdupe +g_gametype dm +set r_fullscreen 0 +set r_mode 1280x720 +set fs_game mods/%modname% +developer 2 +connect 127.0.0.1:28960
cd %COMPILEDIR%
goto :MAKEOPTIONS

:STARTGAME
cls
cd ..\..\
START iw3mp.exe allowdupe +g_gametype dm +set r_fullscreen 0 +set r_mode 1280x720 +set fs_game mods/%modname% +developer 2
cd %COMPILEDIR%
goto :MAKEOPTIONS

:war
cls
cd ..\..\
echo Dedicated Server Started Successfully.
START cod4x18_dedrun.exe +set dedicated 2 +exec server.cfg +set gametype war +set r_xassetnum "material=2560 xmodel=1200" +set developer 1 +set logsync 2 +set fs_game mods/%modname% +map mp_killhouse
cd %COMPILEDIR%
cd ..\..\
START iw3mp.exe allowdupe +g_gametype war +set r_fullscreen 0 +set r_mode 1280x720 +set fs_game mods/%modname% +developer 2 +connect 127.0.0.1:28960
cd %COMPILEDIR%
echo Started Game with Mod Launch Seccessfully.
goto :MAKEOPTIONS

:dm
cls
cd ..\..\
echo Dedicated Server Started Successfully.
START cod4x18_dedrun.exe +set dedicated 2 +exec server.cfg +set gametype dm +set r_xassetnum "material=2560 xmodel=1200" +set developer 1 +set logsync 2 +set fs_game mods/%modname% +map mp_killhouse
cd %COMPILEDIR%
cd ..\..\
START iw3mp.exe allowdupe +g_gametype dm +set r_fullscreen 0 +set r_mode 1280x720 +set fs_game mods/%modname% +developer 2 +connect 127.0.0.1:28960
cd %COMPILEDIR%
echo Started Game with Mod Launch Seccessfully.
goto :MAKEOPTIONS

:sd
cls
cd ..\..\
echo Dedicated Server Started Successfully.
START cod4x18_dedrun.exe +set dedicated 2 +exec server.cfg +g_gametype sd +set r_xassetnum "material=2560 xmodel=1200" +set developer 1 +set logsync 2 +set fs_game mods/%modname% +map mp_crash
cd %COMPILEDIR%
cd ..\..\
START iw3mp.exe allowdupe +g_gametype dm +set r_fullscreen 0 +set r_mode 1280x720 +set fs_game mods/%modname% +developer 2 +connect 127.0.0.1:28960
cd %COMPILEDIR%
echo Started Game with Mod Launch Seccessfully.
goto :MAKEOPTIONS

:STARTASSET
cls
cd ..\..\bin
START asset_manager.exe
cd %COMPILEDIR%
goto :MAKEOPTIONS

:FINAL