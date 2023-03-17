@echo off
setlocal

set filename=%1

for /f "delims=" %%a in ('where /f %filename%') do (
    set filepath=%%a
    goto :run
)

set 
echo File not found on PATH: %filename%
exit /b 1

@REM No straighforward way to pop off first arg from %*
@REM So we do it in R
:run
Rscript.exe -e Rapp::run(args=commandArgs(TRUE)[-2L]) %filepath% %*
