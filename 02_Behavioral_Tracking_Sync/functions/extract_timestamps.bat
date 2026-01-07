@echo off
REM Extract frame timestamps from video file using FFmpeg
REM This batch file extracts presentation timestamps (PTS) for each frame
REM Output is saved as timestamps.txt in the same directory

REM Find .avi file in current directory
for %%F in (*.avi) do (
    set VIDEO_FILE=%%F
    goto :found
)

echo No .avi file found in current directory
exit /b 1

:found
echo Extracting timestamps from %VIDEO_FILE%...

REM Run ffprobe to extract frame timestamps
REM -select_streams v:0 : Select video stream
REM -show_entries frame=pts_time : Show presentation timestamp
REM -of csv=p=0 : Output as CSV without header
ffprobe -select_streams v:0 -show_entries frame=pts_time -of csv=p=0 "%VIDEO_FILE%" > timestamps.txt 2>&1

if %ERRORLEVEL% EQU 0 (
    echo Timestamps extracted successfully to timestamps.txt
) else (
    echo Error extracting timestamps
    exit /b 1
)

exit /b 0
