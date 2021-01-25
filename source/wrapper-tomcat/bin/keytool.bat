@echo off

rem ======================================================================================
rem set window properties
rem buffer size : 9999*150=0x270f0096
rem window size : 40*150=0x00280096
set CONSOLE_CURR="HKCU\Console\%%SystemRoot%%_system32_cmd.exe"
reg add %CONSOLE_CURR% /t REG_SZ    /v "FaceName"         /d "Lucida Console" /f 2>nul>nul
reg add %CONSOLE_CURR% /t REG_DWORD /v "FontSize"         /d 0x00100008 /f 2>nul>nul
reg add %CONSOLE_CURR% /t REG_DWORD /v "ScreenBufferSize" /d 0x270f0096 /f 2>nul>nul
reg add %CONSOLE_CURR% /t REG_DWORD /v "ScreenColors"     /d 0x0000000a /f 2>nul>nul
reg add %CONSOLE_CURR% /t REG_DWORD /v "WindowSize"       /d 0x00280096 /f 2>nul>nul
rem ======================================================================================

cd /d %~dp0
set "WORK_DIR=%CD%"
rem echo %WORK_DIR%

rem restart console
rem if not defined x (set x=0&start cmd /c %0&exit)

setlocal EnableDelayedExpansion
setlocal EnableExtensions

rem 版权信息
set "PROG_NAME=keytool"
set "COPY_RIGHT=www.cdjdgm.com"

rem 命令工具
set "keytoolcmd=jre\bin\keytool"
set "step=1"

rem 当前日期和时间
set "DATE=%DATE: =0%"
set "YYYY=%DATE:~,4%"
set "MM=%DATE:~5,2%"
set "DD=%DATE:~8,2%"
set "YYYYMMDD=%YYYY%%MM%%DD%"
set "TIME=%TIME: =0%"
set "HH=%TIME:~0,2%"
set "MI=%TIME:~3,2%"
set "SS=%TIME:~6,2%"
set "HHMISS=%HH%%MI%%SS%"
set "YYYYMMDDHHMISS=%YYYY%-%MM%-%DD% %HH%:%MI%:%SS%"

rem 命令行参数
set arg_subcmd=
set arg_alias=
set arg_file=

rem 设置标题
title %PROG_NAME% ^| %COPY_RIGHT%

rem 程序开始
rem ======================================================================================

rem 打印基本信息
echo.
echo start...
rem echo CopyRight %COPY_RIGHT%
rem echo current time : %YYYYMMDDHHMISS%
echo.

rem 读取命令行参数
call :read_parameters %*
rem 读取配置信息
call :read_config
rem 执行命令
call :execute_command

echo end...
echo.
pause>nul
goto :eof

rem 程序结束
rem ======================================================================================


rem init,list,import,export,delete,alias,file
rem 读取命令行参数
:read_parameters
rem echo [Step %step%]: read command line parameters
rem set /a step+=1
:loop_read_param
if "%1x" == "x" goto :end_read_param
rem echo [%1]
if "%1x" == "--helpx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=help" )
    shift
    goto :loop_read_param
)
if "%1x" == "-helpx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=help" )
    shift
    goto :loop_read_param
)
if "%1x" == "-hx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=help" )
    shift
    goto :loop_read_param
)
if "%1x" == "--initx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=init" )
    shift
    goto :loop_read_param
)
if "%1x" == "-initx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=init" )
    shift
    goto :loop_read_param
)
if "%1x" == "--listx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=list" )
    shift
    goto :loop_read_param
)
if "%1x" == "-listx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=list" )
    shift
    goto :loop_read_param
)
if "%1x" == "--importx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=import" )
    shift
    goto :loop_read_param
)
if "%1x" == "-importx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=import" )
    shift
    goto :loop_read_param
)
if "%1x" == "--exportx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=export" )
    shift
    goto :loop_read_param
)
if "%1x" == "-exportx" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=export" )
    shift
    goto :loop_read_param
)
if "%1x" == "--deletex" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=delete" )
    shift
    goto :loop_read_param
)
if "%1x" == "-deletex" (
    if "!arg_subcmd!x" == "x" ( set "arg_subcmd=delete" )
    shift
    goto :loop_read_param
)
if "%1x" == "--aliasx" (
    if "!arg_alias!x" == "x" ( set "arg_alias=%~2" )
    shift
    shift
    goto :loop_read_param
)
if "%1x" == "-aliasx" (
    if "!arg_alias!x" == "x" ( set "arg_alias=%~2" )
    shift
    shift
    goto :loop_read_param
)
if "%1x" == "--filex" (
    if "!arg_file!x" == "x" ( set "arg_file=%~2" )
    shift
    shift
    goto :loop_read_param
)
if "%1x" == "-filex" (
    if "!arg_file!x" == "x" ( set "arg_file=%~2" )
    shift
    shift
    goto :loop_read_param
)
echo [unsupport command : %1]
shift
goto :loop_read_param
:end_read_param

rem echo arg_subcmd=%arg_subcmd%
rem echo arg_alias=%arg_alias%
rem echo arg_file=%arg_file%
rem echo.
goto :eof

rem read config info from keytool.env
:read_config
rem echo [Step %step%]: read config info from keytool.env
rem set /a step+=1
if exist "%WORK_DIR%\keytool.env" (
    for /f "eol=# delims=" %%i in ('type "%WORK_DIR%\keytool.env"^| find /i "="') do (
        set _temp=%%i
        rem set !_temp!
        rem echo !_temp!
        for /f "tokens=1,* delims==" %%a in ("!_temp!") do (
            set "key=%%~a"
            set "value=%%~b"
            rem echo key=!key!,value=!value!
            set "!key!=!value:/=\!"
            rem echo !key!=!value:/=\!
        )
    )
) else (
    echo %WORK_DIR%\keytool.env does not exist.
    echo please make sure keytool.env exists.
    goto :eof
)
rem echo.
goto :eof

rem call command
:execute_command
if [%arg_subcmd%]==[] (
    call :show_help
) else if [%arg_subcmd%]==[help] (
    call :show_help
) else if [%arg_subcmd%]==[init] (
    call :execute_init_command
) else if [%arg_subcmd%]==[list] (
    call :execute_list_command
) else if [%arg_subcmd%]==[import] (
    call :execute_import_command
) else if [%arg_subcmd%]==[export] (
    call :execute_export_command
) else if [%arg_subcmd%]==[delete] (
    call :execute_delete_command
)
if not errorlevel 1 goto :eof
echo.
goto :eof

rem show help
:show_help
echo [Step %step%]: show help info
set /a step+=1

echo keytool.bat [--init] ^| [--list] ^| [--import] ^| [--export] ^| [--delete] ^| [--alias test] ^| [--file xxx.crt]
echo --init    execute init command.
echo.
echo --list    execute list command.
echo   --alias test
echo.
echo --import  execute import command.
echo   --alias test
echo   --file  xxx.crt
echo.
echo --export  execute export command.
echo   --alias test
echo   --file  xxx.crt
echo.
echo --delete  execute delete command.
echo   --alias test

echo.
goto :eof

rem execute init command
:execute_init_command
echo [Step %step%]: execute init command
set /a step+=1

echo copy %WORK_DIR%\..\jre\lib\security\cacerts to %WORK_DIR%\..\%trustfile%
echo f | xcopy "%WORK_DIR%\..\jre\lib\security\cacerts" "%WORK_DIR%\..\%trustfile%" /s/e/i/y
echo change storepasswd to %newstorepass%
"%WORK_DIR%\..\%keytoolcmd%" -storepasswd -v -keystore "%WORK_DIR%\..\%trustfile%" -storepass "%oldstorepass%" -new "%newstorepass%"
echo successfully executed init command.

echo.
goto :eof

rem execute list command
:execute_list_command
echo [Step %step%]: execute list command
set /a step+=1

if "%arg_alias%x" == "x" (
    echo list all entries in the keystore
    "%WORK_DIR%\..\%keytoolcmd%" -list -keystore "%WORK_DIR%\..\%trustfile%" -storepass "%newstorepass%"
    echo successfully executed list command.
) else (
    echo list the specified entries in the keystore : [%arg_alias%]
    "%WORK_DIR%\..\%keytoolcmd%" -list -v -keystore "%WORK_DIR%\..\%trustfile%" -alias "%arg_alias%" -storepass "%newstorepass%"
    echo successfully executed list command.
)

echo.
goto :eof

rem execute import command
:execute_import_command
echo [Step %step%]: execute import command
set /a step+=1

if "%arg_alias%x" == "x" (
    if "%arg_file%x" == "x" (
        rem import certificate from %WORK_DIR%\..\%certspath%
        echo import certificate from %WORK_DIR%\..\%certspath%\*.crt
        for /f "delims=" %%a in ('dir /b "%WORK_DIR%\..\%certspath%" ^| findstr .crt') do (
            rem echo %%a
            set file=%%a
            set alias=!file:~0,-4!
            rem echo !alias!
            rem echo !file!
            rem echo check if alias [!alias!] exists
            rem "%WORK_DIR%\..\%keytoolcmd%" -list -keystore "%WORK_DIR%\..\%trustfile%" -alias "!alias!" -storepass "%newstorepass%"
            echo delete alias [!alias!]...
            "%WORK_DIR%\..\%keytoolcmd%" -delete -keystore "%WORK_DIR%\..\%trustfile%" -alias "!alias!" -storepass "%newstorepass%"
            echo import certificate, alias : [!alias!], file : [!file!]
            "%WORK_DIR%\..\%keytoolcmd%" -importcert -noprompt -keystore "%WORK_DIR%\..\%trustfile%" -alias "!alias!" -file "%WORK_DIR%\..\%certspath%\!file!" -storepass "%newstorepass%"
        )
        echo import certificate from %WORK_DIR%\..\%certspath%\*.cer
        for /f "delims=" %%a in ('dir /b "%WORK_DIR%\..\%certspath%" ^| findstr .cer') do (
            rem echo %%a
            set file=%%a
            set alias=!file:~0,-4!
            rem echo !alias!
            rem echo !file!
            rem echo check if alias [!alias!] exists
            rem "%WORK_DIR%\..\%keytoolcmd%" -list -keystore "%WORK_DIR%\..\%trustfile%" -alias "!alias!" -storepass "%newstorepass%"
            echo delete alias [!alias!]...
            "%WORK_DIR%\..\%keytoolcmd%" -delete -keystore "%WORK_DIR%\..\%trustfile%" -alias "!alias!" -storepass "%newstorepass%"
            echo import certificate, alias : [!alias!], file : [!file!]
            "%WORK_DIR%\..\%keytoolcmd%" -importcert -noprompt -keystore "%WORK_DIR%\..\%trustfile%" -alias "!alias!" -file "%WORK_DIR%\..\%certspath%\!file!" -storepass "%newstorepass%"
        )
        echo successfully executed import command.
    ) else (
        echo alias cannot be empty
    )
) else (
    if "%arg_file%x" == "x" (
        echo file cannot be empty
    ) else (
        if not exist "%arg_file%" (
            echo the file [%arg_file%] does not exist
        ) else (
            echo import certificate, alias : [%arg_alias%], file : [%arg_file%]
            "%WORK_DIR%\..\%keytoolcmd%" -importcert -noprompt -keystore "%WORK_DIR%\..\%trustfile%" -alias "%arg_alias%" -file "%arg_file%" -storepass "%newstorepass%"
            echo successfully executed import command.
        )
    )
)

echo.
goto :eof

rem execute export command
:execute_export_command
echo [Step %step%]: execute export command
set /a step+=1

if "%arg_alias%x" == "x" (
    echo alias cannot be empty
    goto :eof
)
if "%arg_file%x" == "x" (
    echo file cannot be empty
    goto :eof
)
if exist "%arg_file%" (
    echo the file [%arg_file%] already exists
    goto :eof
)
echo export certificate, alias : [%arg_alias%], file : [%arg_file%]
"%WORK_DIR%\..\%keytoolcmd%" -exportcert -rfc -keystore "%WORK_DIR%\..\%trustfile%" -alias "%arg_alias%" -file "%arg_file%" -storepass "%newstorepass%"
echo successfully executed export command.

echo.
goto :eof

rem execute delete command
:execute_delete_command
echo [Step %step%]: execute delete command
set /a step+=1

if "%arg_alias%x" == "x" (
    echo alias cannot be empty
    goto :eof
)
echo delete certificate, alias : [%arg_alias%]
"%WORK_DIR%\..\%keytoolcmd%" -delete -v -keystore "%WORK_DIR%\..\%trustfile%" -alias "%arg_alias%" -storepass "%newstorepass%"
echo successfully executed delete command.

echo.
goto :eof
