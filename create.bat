@echo off
setlocal

set cacheDir=
set currentDir=%~dp0
set phar=%currentDir%sami.phar
set config=%currentDir%sami-config.php

:: Download sami.phar if not exists.
if not exist "%phar%" (
  call :download
)

:: Create configuration file.
call :createConfig

:: Run sami.phar and wait until the process has finished.
start /wait php sami.phar update %config%

:: Remove the cache directory.
if exist %cacheDir% (
  echo.
  echo Removing cache directory "%cacheDir%"
  rd /s /q "%cacheDir%"
  echo Cache directory removed
)

:: Script ends here. Closing cmd.
echo.
echo Your documentation was successfully created. Press any key to complete...
timeout /t -1 >nul
exit

:: Downloads the PHP Archive "sami.phar".
:download
echo "Downloading sami.phar"

:: PowerShell command.
powershell -Command "Invoke-WebRequest http://get.sensiolabs.org/sami.phar -OutFile sami.phar"
exit /B 0

:: Creates the configuration file for sami.phar.
:createConfig
:: Ask user for necessary information about the configuration file.
set /P title="Title of the documentation: "
set /P projectDir="Full path to the project directory (e.g. C:/projects/code): "
set /P docDir="Directory which should documented (e.g. Lib): "
set /P outDir="Output directory name (e.g. Doc): "
set /P excludeDirs="Exclude directories (e.g. Test Resources): "

set cacheDir=%projectDir%/samiCache

:: Write the file.
echo ^<?php> %config%
echo.>>%config%
echo use Sami\Sami;>> %config%
echo use Symfony\Component\Finder\Finder;>> %config%
echo.>>%config%
echo $iterator = Finder::create()>> %config%
echo     -^>files()>> %config%
echo     -^>name( '*.php' )>> %config%

for %%e in (%excludeDirs%) do (
  echo     -^>exclude( '%%e' ^)>> %config%
)

echo     -^>in( '%projectDir%/%docDir%' );>> %config%
echo.>>%config%
echo $options = [>> %config%
echo     'title' =^> '%title%',>> %config%
echo     'build_dir' =^> '%projectDir%/%outDir%',>> %config%
echo     'cache_dir' =^> '%projectDir%/samiCache',>> %config%
echo     'default_opened_level' =^> 2,>> %config%
echo ];>> %config%
echo.>>%config%
echo return new Sami( $iterator, $options );>> %config%
:: File finished.
exit /B 0