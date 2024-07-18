@echo off
setlocal EnableDelayedExpansion
for /f %%a in ('echo prompt $E^| cmd') do set "\e=%%a"
set version=1
::    __  __             _                    _  _    _        ____          _     _____  _       _____ 
::   |  \/  |           | |                  (_)| |  | |      |  _ \        | |   / ____|| |     |_   _|
::   | \  / |  __ _   __| |  ___   __      __ _ | |_ | |__    | |_) |  __ _ | |_ | |     | |       | |  
::   | |\/| | / _` | / _` | / _ \  \ \ /\ / /| || __|| '_ \   |  _ <  / _` || __|| |     | |       | |  
::   | |  | || (_| || (_| ||  __/   \ V  V / | || |_ | | | |  | |_) || (_| || |_ | |____ | |____  _| |_ 
::   |_|  |_| \__,_| \__,_| \___|    \_/\_/  |_| \__||_| |_|  |____/  \__,_| \__| \_____||______||_____|
::                                                                                                      
::                                                                                                      

:: dotlang, (C) 2024 NEOAPPS
:: This code is licensed under MIT license (see LICENSE.txt for details)

if /i "%1" == "--help" (goto :help)
if /i "%1" == "/?" (goto :help)
if /i "%1" == "-h" (goto :help)
if /i "%1" == "build" (goto :build)
if /i "%1" == "new" (goto :new)
if /i "%1" == "add" (goto :add)
if /i "%1" == "idk" (echo it's alright. idk too hehe && exit /b 0)
echo Invalid Syntax! use `dot --help` for help.
goto :EOF

:help
echo dotCLI - The CLI for dotlang.
echo Current dot Version Installed: dot v%version%.
echo.
echo Usage:
echo %\e%[4mdot%\e%[0m --help, -h, /?		Show help Page
echo %\e%[4mdot%\e%[0m build				Build Project in the current directory
echo %\e%[4mdot%\e%[0m new					Make a project in the current directory
echo %\e%[4mdot%\e%[0m add PACKAGE          Adds PACKAGE to the current project
exit /b

:new
if exist "%cd%\dot.json" (
echo %\e%[1;31mWARNING: PROJECT IN THIS DIRECTORY ALREADY EXIST. IF YOU WANT TO OVERRIDE IT, MAKE A FILE WITH NAME "override.txt".%\e%[0m
if exist override.txt (
echo {"dotv":"%version%", "name":"mydot", "v": "0.1", "packages": []} >dot.json
del override.txt
echo Project with name `mydot` has been made in %cd%.
)
) else (
echo {"dotv":"%version%", "name":"mydot", "v": "0.1", "packages": []} >dot.json
echo Import-Module .\dot.ps1 # Enable dotlang >main.dot
echo Project with name `mydot` has been made in %cd%.
)
goto :EOF

:build
echo [dot.build] Reinitialized build.log file.>build.log
echo [dot] Building project from %cd%...
echo [dot] Building project from %cd%... >>build.log
%SystemRoot%\system32\timeout 1 >nul
type dot.json | %~dp0\jq .dotv >temp
set /p dotv=<temp
del temp
if "%version%" LSS %dotv% (echo [dot] You're using an outdated version of dot. please install dot %dotv% or more && exit /b 1)
echo [dot] Getting the latest packages from %cd%\dot.json...
echo [dot] Getting the latest packages from %cd%\dot.json... >>build.log
for /f "tokens=*" %%i in ('jq -r ".packages[]" dot.json') do (
    set "child=%%i"
    echo [dot] Installing !child!
    echo [dot] Installing !child! >>build.log
    echo [dot] Begin `Install !child!` log.. >>build.log
    powershell -ExecutionPolicy Bypass -Command "Import-Module %SYSTEMROOT%\dot.ps1; Invoke-InContext Admin 'Install-Module !child!'"
    echo [dot] End `Install !child!` log.. >>build.log
    %SystemRoot%\system32\timeout 2 >nul
)
echo [dot] Building project...
echo [dot] Building project... >>build.log
del dist
mkdir dist >>build.log
xcopy /Y *.dot dist >>build.log
xcopy /Y *.exe dist >>build.log
xcopy /Y *.dll dist >>build.log
xcopy /Y %~dp0\dot.ps1 dist >>build.log
cd dist
ren *.dot *.ps1 >>build.log
cd ..
echo [dot.build] End build.log.>>build.log
echo [dot] Build finished, check %cd%\build.log for the full log. (ERRORCODE: !ERRORLEVEL!)
exit /b !ERRORLEVEL!

:add
%~dp0\jq -r -c ".packages" "dot.json" >temp
set /p PACKAGES=<temp
del temp
set PACKAGES=%PACKAGES:[=%
set PACKAGES=%PACKAGES:]=%
echo {"dotv":"%version%", "name":"mydot", "v": "0.1", "packages": [%PACKAGES%, "%2"]} >dot2.json
%~dp0\jq -r -s -c add "dot2.json" "dot.json" >dot.json
del dot2.json
echo [dot] Package has been added to `dot.json` with error code (!ERRORLEVEL!)
exit /b !ERRORLEVEL!