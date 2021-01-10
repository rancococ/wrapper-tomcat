@echo off

rem setlocal EnableDelayedExpansion
rem setlocal EnableExtensions

cd /d %~dp0
set "CONF_DIR=%CD%/../conf"
set "PATH=.;%CD%/../tool;%PATH%"

rem read config info from wrapper-property.conf
rem echo read config info from wrapper-property.conf
for /f "eol=# delims=" %%i in ('cat "%CONF_DIR%/wrapper-property.conf"^| grep "="') do (
set temp=%%i
set !temp:~4!
rem echo %%i
rem echo !APP_NAME!
)
