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
set versions=
set github=false
set ghUser=
set ghRepo=

:: Ask user for necessary information about the configuration file.
set /P title="Title of the documentation: "
set /P projectDir="Full path to the project directory (e.g. C:/projects/code): "
set /P docDir="Directory which should documented (e.g. Lib): "
set /P outDir="Output directory name (e.g. Doc): "
set /P excludeDirs="Exclude directories (e.g. Test Resources): "

call :choice "Include github repository?" yes no github
if "%github%" == "true" (
  call :setGhUser
  call :setGhRepo
)

set cacheDir=%projectDir%/samiCache

:: Write the file.
echo ^<?php> %config%
echo.>>%config%
echo use Sami\Sami;>> %config%
echo use Symfony\Component\Finder\Finder;>> %config%

if "%github%" == "true" (
  echo use Sami\RemoteRepository\GitHubRemoteRepository;>> %config%
  echo use Sami\Version\GitVersionCollection;>> %config%
)

echo.>>%config%
echo $dir = '%projectDir%';>> %config%
echo.>>%config%

if "%github%" == "true" (
  echo $versions = GitVersionCollection::create( $dir ^)>> %config%

  For /f "tokens=1,2 delims=:, " %%U in ('curl "https://api.github.com/repos/%ghUser%/%ghRepo%/tags" 2^>Nul ^| findstr /i "\"name\""') do (
    echo     -^>add( '%%~V', '%%~V' ^)>> %config%
  )

  echo     -^>add( 'master', 'master' ^);>> %config%
  echo.>>%config%
)

echo $iterator = Finder::create()>> %config%
echo     -^>files()>> %config%
echo     -^>name( '*.php' )>> %config%

for %%e in (%excludeDirs%) do (
  echo     -^>exclude( '%%e' ^)>> %config%
)

echo     -^>in( $dir . '/%docDir%' );>> %config%

echo.>>%config%
echo $options = [>> %config%
echo     'title' =^> '%title%',>> %config%

if "%github%" == "true" (
  echo     'build_dir' =^> $dir . '/%outDir%/%%version%%',>> %config%
  echo     'cache_dir' =^> $dir . '/samiCache/%%version%%',>> %config%
) else (
  echo     'build_dir' =^> $dir . '/%outDir%',>> %config%
  echo     'cache_dir' =^> $dir . '/samiCache',>> %config%
)

echo     'default_opened_level' =^> 2,>> %config%

if "%github%" == "true" (
  echo     'versions' =^> $versions,>> %config%
  echo     'remote_repository' =^> new GitHubRemoteRepository( '%ghUser%/%ghRepo%', $dir ^),>> %config%
)

echo ];>> %config%
echo.>>%config%
echo return new Sami( $iterator, $options );>> %config%
:: File finished.
exit /B 0

:choice
set /P answer=%1
if /I "%answer%" equ "Y" goto :%2 %4
if /I "%answer%" equ "Yes" goto :%2 %4
if /I "%answer%" equ "N" goto :%3 %4
if /I "%answer%" equ "No" goto :%3 %4
echo "Please answer with yes or no" & goto :choice %1 %2 %3 %4
exit /B 0

:yes
set %4=true
exit /B 0

:no
set %4=false
exit /B 0

:setGhUser
set /P ghUser="Github username: "

if [%ghUser%] == [] goto :setGhUser
exit /B 0

:setGhRepo
set /P ghRepo="Github repository name: "

if [%ghRepo%] == [] goto :setGhRepo
exit /B 0