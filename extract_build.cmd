@echo off
setlocal enabledelayedexpansion

REM Check if build folder exists, if not create it
if not exist "build" (
    mkdir "build"
) else (
    REM Completely remove the build folder and all its contents
    rmdir /S /Q "build"
    mkdir "build"
)

REM Create necessary directories
mkdir "build\ExeMods" 2>nul
mkdir "build\Scripts\General" 2>nul
mkdir "build\Scripts\Modules" 2>nul
mkdir "build\Scripts\Modules\MMCheat" 2>nul

REM Copy required files maintaining structure
copy "ExeMods\iup.dll" "build\ExeMods\"
copy "Scripts\General\MMCheat.lua" "build\Scripts\General\"
xcopy "Scripts\Modules\MMCheat\*.*" "build\Scripts\Modules\MMCheat\" /E /I /Y
if exist "build\Scripts\Modules\MMCheat\conf.ini" del "build\Scripts\Modules\MMCheat\conf.ini"
if exist "build\Scripts\Modules\MMCheat\coords.txt" del "build\Scripts\Modules\MMCheat\coords.txt"
copy "Scripts\Modules\iup.lua" "build\Scripts\Modules\"

echo Build folder has been prepared successfully!
pause
