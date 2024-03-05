@Echo off
setlocal enabledelayedexpansion
if not %ERRORLEVEL%==0 (
    cecho {0C}SOMETHING WENT WRONG...{#}
    CALL :LOG "Initializing error."
    goto :ERROR
)
set "basePath=%~dp0"
set "logFile=Anna-YTD Log.txt"
if exist "%logFile%" (
    for %%F in ("%logFile%") do set fileSize=%%~zF
    if !fileSize! GTR 20971520 (
        del "%logFile%"
        CALL :LOG "The log file was larger than 20MB and has been deleted."
	echo The log file was larger than 20MB and has been deleted.
    )
)
if not exist "%logFile%" (
    echo Log file created on %DATE% at %TIME% > "%logFile%"
)
CALL :LOG "Script started on %DATE% at %TIME%"

:back1
echo Please enter a file name. Do NOT use any spaces or forbidden characters like greater than/less than, : \ " / \ \ | ? or *:
set "name="
set "webm="
set /P "name=>" || goto linkER
set "name=%name:"=%"
if not defined name goto linkER
if not "%name%"=="%name: =%" goto linkER
for %%G in ("%name%") do if /I not "%%~xG" == ".webm" if  "%%~xG" == "" (set "webm=%name%.webm") else goto linkER
goto back2

:linkER
cecho {0C}INVALID ENTRY {#}
CALL :LOG "Invalid entry linkER."
goto back1

:back2
echo Please paste the YouTube link:
set /P "link=>" || goto Invalid
set "link=%link:"=%"
if not defined link goto Invalid
if "%link:youtube=%" == "%link%" goto Youtube
goto start_time

:Invalid
cecho {0C}INVALID ENTRY {#}
CALL :LOG "Invalid entry %link%"
goto back2

:Youtube
cecho {0C}INVALID ENTRY: Must contain "Youtube" {#}
CALL :LOG "Invalid: not Youtube link."
goto back2

:start_time
echo Please enter start time (0 if empty) (0.5 = 30 seconds, 0.75 = 45 seconds)
set /p "start_time=>"
echo %start_time%|findstr /r "^[0-9]*\.*[0-9]*$" >nul && (
    goto end_time
) || (
    echo %start_time% is NOT a valid number
    goto start_time
)
goto end_time


:end_time
echo Please enter the video length (0 for unchanged) (0.5 = 30 seconds, 0.75 = 45 seconds)
set/p "end_time=>"
echo %end_time%|findstr /r "^[0-9]*\.*[0-9]*$" >nul && (
    goto back3
) || (
    echo %end_time% is NOT a valid number
    goto end_time
)
goto back3

:back3
echo Please enter the output file type (example: ".mp3"):
echo Currently supported types: .mp3 ~ .webm ~ .mp4 ~ .wma ~ .wav ~ .gif ~ .mov
echo If you wish to conver to another file type, please contact Anna-Rose.
set /p "output_type=>"
set "output=%name%%output_type%"
if %output_type%==.gif goto back3_gif
echo Please ensure this is correct:
echo Name       = %name%
echo Output     = %output%
echo Link       = %link%
echo Cut Start  = %start_time% seconds
echo Clip length= %end_time% seconds
echo -------------------------------------------
set /p DUMMY=Hit ENTER to continue. If the above is not right, close and re-open this file.
CALL :LOG "User confirmed details: Name=%name%, Output=%output%, Link=%link%, Start=%start_time%, Length=%end_time%"
if %output_type%==.mp3 goto MP3
if %output_type%==.webm goto WEBM
if %output_type%==.mp4 goto mp4
if %output_type%==.wma goto WMA
if %output_type%==.wav goto WAV
if %output_type%==.gif goto GIF
if %output_type%==.mov goto MOV
cecho {0C}ERROR: Unknown File Type{#}
CALL :LOG "Unknown file type entered."
echo.
goto back3

:back3_gif
echo Since GIF files can get large quickly, please select an fps you would like. Enter '0' if you want to leave it unchanged
set /p "FPS=>"
echo %FPS%|findstr /r "^[0-9]*\.*[0-9]*$" >nul && (
    echo Please ensure this is correct:
    echo Name       = %name%
    echo Output     = %output%
    echo Link       = %link%
    echo Frames     = %FPS% fps
    echo Cut Start  = %start_time% seconds
    echo Clip length= %end_time% seconds
    echo -------------------------------------------
    set /p DUMMY=Hit ENTER to continue. If the above is not right, close and re-open this file.
    goto GIF
    CALL :LOG "User confirmed details: Name=%name%, Output=%output%, Link=%link%, FPS=%FPS% fps, Start=%start_time%, Length=%end_time%"
) || (
    echo %FPS% is NOT a valid number
    goto back3_gif
)

:MP3
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %end_time%==0 (ffmpeg -ss %start_time% -i %webm% -y -vn -acodec copy -c:a libmp3lame %output%
) else (
    ffmpeg -ss %start_time% -t %end_time% -i %webm% -y -vn -acodec copy -c:a libmp3lame %output%
)
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "ffmpeg encountered an error."
    goto :ERROR
)
goto END_S

:WEBM
set "output=1%webm%"
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %end_time%==0 (
    if %start_time%==0 (
        goto END_WEBM)
    else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -n %output%)
else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -n %output%)
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "ffmpeg encountered an error."
    goto :ERROR
)
goto END_S

:mp4
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %end_time%==0 (
    if %start_time%==0 (
        ffmpeg -i %webm% -c:a flac -c:v h264 %output%
    ) else (ffmpeg -ss %start_time% -i %webm% -c:a flac -c:v h264 -n %output%)
) else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -c:a flac -c:v h264 -n %output%)
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "ffmpeg encountered an error."
    goto :ERROR
)
goto END_S

:WMA
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %end_time%==0 (
    if %start_time%==0 (
        ffmpeg -i %webm% -c:a wmav2 -vn %output%
    ) else (ffmpeg -ss %start_time% -i %webm% -c:a wmav2 -vn -n %output%)
) else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -c:a wmav2 -vn -n %output%)
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "ffmpeg encountered an error."
    goto :ERROR
)
goto END_S

:WAV
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %end_time%==0 (
    if %start_time%==0 (
        ffmpeg -i %webm% -c:a pcm_s24le -vn %output%
    ) else (ffmpeg -ss %start_time% -i %webm% -c:a pcm_s24le -vn -n %output%)
) else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -c:a pcm_s24le -vn -n %output%)
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "ffmpeg encountered an error."
    goto :ERROR
)
goto END_S

:GIF
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %FPS%==0 (
    if %end_time%==0 (
        if %start_time%==0 (
            ffmpeg -i %webm% -c:v gif -an %output%
        ) else (ffmpeg -ss %start_time% -i %webm% -c:v gif -an -n %output%)
    ) else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -c:v gif -an -n %output%)
) else (
    if %end_time%==0 (
        if %start_time%==0 (
            ffmpeg -i %webm% -c:v gif -an -fpsmax %FPS% %output%
        ) else (ffmpeg -ss %start_time% -i %webm% -c:v gif -an -fpsmax %FPS% -n %output%)
    ) else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -c:v gif -an -fpsmax %FPS% -n %output%))
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "Complex ffmpeg (gif) encountered an error."
    goto :ERROR
)
goto END_S

:MOV
yt-dlp "%link%" -o %webm%
if not %ERRORLEVEL%==0 (
    cecho {0C}yt-dlp encountered an error.{#}
    CALL :LOG "yt-dlp encountered an error."
    goto :ERROR
)
if %end_time%==0 (
    if %start_time%==0 (
        ffmpeg -i %webm% -c:a aac -c:v h264 %output%
    ) else (ffmpeg -ss %start_time% -i %webm% -c:a aac -c:v h264 -n %output%)
) else (ffmpeg -ss %start_time% -t %end_time% -i %webm% -c:a aac -c:v h264 -n %output%)
if not %ERRORLEVEL%==0 (
    cecho {0C}FFMPEG encountered an error.{#}
    CALL :LOG "ffmpeg encountered an error."
    goto :ERROR
)
goto END_S

:END_WEBM
if exist %USERPROFILE%\Downloads\Annas YT Downloader\ (move "%basePath%%webm%" "%USERPROFILE%\Downloads\Annas YT Downloader\%webm%") else (
    cd %USERPROFILE%\Downloads
    mkdir "Annas YT Downloader"
    move "%basePath%%webm%" "%USERPROFILE%\Downloads\Annas YT Downloader\%webm%"
)
goto END
:END_S
del %webm%
if exist %USERPROFILE%\Downloads\Annas YT Downloader\ (move "%basePath%%output%" "%USERPROFILE%\Downloads\Annas YT Downloader\%output%") else (
    cd %USERPROFILE%\Downloads
    mkdir "Annas YT Downloader"
    move "%basePath%%output%" "%USERPROFILE%\Downloads\Annas YT Downloader\%output%"
)
if not %ERRORLEVEL%==0 (
    cecho {0C}Something went wrong at the very end but were not sure what...{#}
    echo.
    echo Try checking if your file is in "Downloads\Annas YT Downloader" If not, try checking %basePath%
    CALL :LOG "End_s error."
    goto :ERROR
)
goto END

:LOG
echo [%DATE% %TIME%] %~1 >> "%logFile%"
echo [%DATE% %TIME%] %~1
GOTO :EOF

:END
CALL :LOG "success"
echo [%DATE% %TIME%] %~1 >> "%logFile%"
echo [%DATE% %TIME%] %~1
echo ----------------------------------------------------------------------------------------------------
for /L %%i in (1, 1, 51) do (
    cecho {00}--{#}
    echo.
)
echo ----------------------------------------------------------------------------------------------------
cecho {0A}Success... You will find your file in "Downloads\Annas YT Downloader"!.{#}
echo.
set /p DUMMY=Press any key if you wish the script to repeat. If you're done, feel free to close me!
goto :back1

:ERROR
CALL :LOG "An error occurred with the last operation."
cecho {0C}An error occurred with the last operation.{#}
echo.
echo Sorry about that, something went wrong. If you want, try debugging it yourself! If you can't, contact Anna on Discord (phederal_phoenix) or in her server (https://discord.gg/FPSmSMzA4j) and send her your log stored in %basePath%%logFile%
echo Its best to make a copy of the log each time you encounter an error as each time you run this script there's a chance it will delete itself to save space.
echo.
cecho {0A}Press any button to CLOSE this session{#}
pause
:EOF
CALL :LOG "%*"