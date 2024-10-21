@echo off
setlocal enabledelayedexpansion
mode con cols=120 lines=30
title CLIPR
chcp 65001 >nul
cls

:: ASCII Art Header
echo        		╔════════════════════════════════════════════════════════════════════════════════╗
echo        		║                                                                                ║
echo        		║                       ██████╗██╗     ██╗██████╗ ██████╗                        ║
echo        		║                       ██╔════╝██║     ██║██╔══██╗██╔══██╗                      ║
echo        		║                       ██║     ██║     ██║██████╔╝██████╔╝                      ║
echo        		║                       ██║     ██║     ██║██╔═══╝ ██╔══██╗                      ║
echo        		║                       ╚██████╗███████╗██║██║     ██║  ██║                      ║
echo        		║                        ╚═════╝╚══════╝╚═╝╚═╝     ╚═╝  ╚═╝                      ║
echo        		║                                                                                ║
echo        		║                                 Clip Compressor                                ║
echo        		║                          Compress your clips for Discord!                       ║
echo        		║                                                                                ║
echo        		╚════════════════════════════════════════════════════════════════════════════════╝

:: Supported file extensions for FFmpeg
set "supported_extensions=.mp4 .mkv .avi .mov .flv .wmv .webm .mpg .mpeg"

:: Check if input files were dragged and dropped
:process_files
if "%~1"=="" (
    echo        	           ║
    echo        		   ╚ Usage: Drag and drop your MP4 or FFmpeg-supported file onto the .bat file.
    echo.
    echo.
    echo.
    echo.
    :: ASCII Art 9x9 Box with Center +
    echo							     ╔═══════════╗
    echo							     ║           ║
    echo							     ║           ║
    echo							     ║     +     ║
    echo							     ║           ║
    echo							     ║           ║
    echo							     ╚═══════════╝
    echo.
    echo.
    echo.
    call :wait_for_key
    exit /b
)

:: Iterate through all dropped files
:process
set "input_file=%~1"
set "output_file=%~dpn1_compressed.mp4"

:: Check if the file extension is supported
set "file_ext=%~x1"
set "is_supported=0"
for %%E in (%supported_extensions%) do (
    if /i "!file_ext!"=="%%E" (
        set "is_supported=1"
        goto process_file
    )
)

:: If the file is not supported, show an error and exit
if "!is_supported!"=="0" (
    echo Error: The file type is not supported. Please drop a valid FFmpeg file.
    goto end
)

:process_file
echo ================================================
echo        Selected File Information
echo ================================================
echo Input File: "%input_file%"
for %%I in ("%input_file%") do (
    set input_size=%%~zI
)
set /a input_size_mb=input_size/1024/1024
echo Input Size: !input_size_mb! MB
echo Output File: "!output_file!"
echo ================================================

:: Check if the input file exists
if not exist "%input_file%" (
    echo Error: The input file does not exist.
    goto end
)

:: Check if the input file size is already under 8 MB
if !input_size_mb! lss 8 (
    echo Video already under 8 MB and ready for Discord!
    goto end
)

:: Start Compression Timer
set start_time=%time%
set "bitrate=2000k"  :: Initial bitrate setting

:compress
:: Use FFmpeg to compress the video
ffmpeg -y -i "%input_file%" -vf "scale=1280:-1" -b:v !bitrate! -preset fast -c:a aac -b:a 128k "!output_file!" >nul 2>&1

:: Check output file size
for %%I in ("%output_file%") do (
    set output_size=%%~zI
)
set /a output_size_mb=output_size/1024/1024
echo Output Size: !output_size_mb! MB

:: If the output size is greater than 8 MB, reduce the bitrate and compress again
if !output_size_mb! gtr 8 (
    echo Output video exceeds the maximum size of 8 MB. Reducing bitrate...
    
    rem Remove the "k" from the bitrate to perform arithmetic
    set /a bitrate_value=!bitrate:~0,-1! - 200
    if !bitrate_value! lss 0 (
        echo Minimum bitrate reached. Unable to compress below 8 MB.
        goto end
    )
    
    set bitrate=!bitrate_value!k
    goto compress
)

:end
:: End Compression Timer
set end_time=%time%
call :timeDiff !start_time! !end_time! elapsed_time
echo Time Taken: !elapsed_time! seconds

echo Compression completed successfully. The file is ready!

:: Wait for user input before closing
call :wait_for_key
exit /b

:timeDiff
setlocal
set start=%1
set end=%2
:: Calculate time difference
for /f "tokens=1-3 delims=:" %%a in ("%start%") do set /a start_seconds=%%a*3600 + %%b*60 + %%c
for /f "tokens=1-3 delims=:" %%a in ("%end%") do set /a end_seconds=%%a*3600 + %%b*60 + %%c
set /a elapsed=end_seconds-start_seconds
if !elapsed! lss 0 set /a elapsed+=86400
endlocal & set %3=%elapsed%
goto :eof

:: Wait for user to press [q] to quit without displaying a message
:wait_for_key
:wait_for_key_loop
set "key="
for /f "delims=" %%K in ('xcopy /W "%temp%\nul" "%temp%\nul" 2^>nul') do set "key=%%K"
if /i "!key!"=="q" (
    exit /b
)
goto wait_for_key_loop

:: Iterate through all dropped files
shift
if "%~1" neq "" (
    goto process_files
)

:: Process any files that are already in the command line arguments
goto process_files
