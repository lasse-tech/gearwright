@echo off
rem Windows counterpart to the Makefile; usage: Makefile <target>
setlocal EnableDelayedExpansion

set ADDON=Gearwright
for /f "tokens=3" %%v in ('findstr /b /c:"## Version:" %ADDON%.toc') do set VERSION=%%v
set DIRS=Core UI Data Locales Skin Media
set FILES=%ADDON%.toc embeds.xml Bindings.xml CHANGELOG.md LICENSE
set ZIP=dist\%ADDON%-%VERSION%.zip

set ADDONS=%WOW_RETAIL_ADDON_FOLDER%
if "%ADDONS%"=="" if not "%WOW_DIR%"=="" set ADDONS=%WOW_DIR%\_retail_\Interface\AddOns
if "%ADDONS%"=="" if exist "%ProgramFiles(x86)%\World of Warcraft\_retail_" set ADDONS=%ProgramFiles(x86)%\World of Warcraft\_retail_\Interface\AddOns
if "%ADDONS%"=="" if exist "C:\Program Files\World of Warcraft\_retail_" set ADDONS=C:\Program Files\World of Warcraft\_retail_\Interface\AddOns
set TARGET=%ADDONS%\%ADDON%

set GOAL=%1
if "%GOAL%"=="" set GOAL=help
goto %GOAL% 2>nul || (echo unknown target: %GOAL% & exit /b 1)

rem help: list the targets
:help
echo %ADDON% %VERSION%
for /f "tokens=1,*" %%a in ('findstr /b /r /c:"rem [abcdefghijklmnopqrstuvwxyz][abcdefghijklmnopqrstuvwxyz0123456789-]*: " "%~f0"') do echo   %%b
echo.
echo Variables (set NAME=value): WOW_RETAIL_ADDON_FOLDER, WOW_DIR
exit /b 0

:need_addons
if "%ADDONS%"=="" (echo AddOns folder not found. Set WOW_RETAIL_ADDON_FOLDER or WOW_DIR & exit /b 1)
exit /b 0

:need_libs
if not exist Libs\LibStub (echo Libs\ is empty - run "make fetch-libs" on Linux & exit /b 1)
exit /b 0

rem lint: luac, TOC, data, luacheck (BLOCKER; Makefile comments: make lint)
:lint
for /r %%f in (*.lua) do (
    echo %%f | findstr /i "\\Libs\\ \\dist\\ \\tests\\ \\tools\\ \\.cache\\" >nul || (
        luac -p "%%f" || exit /b 1
    )
)
echo luac: all files parse
for /f "usebackq tokens=* delims=" %%l in (`findstr /r "^[A-Za-z].*\.lua$ ^[A-Za-z].*\.xml$" %ADDON%.toc`) do (
    if not exist "%%l" (echo   MISSING %%l & exit /b 1)
)
echo toc: every listed file exists
lua5.1 tools\check-data.lua . || lua tools\check-data.lua . || exit /b 1
luacheck --no-color -q . || exit /b 1
echo luacheck: no warnings
exit /b 0

rem data: rebuild Data\Specs.lua (needs python)
:data
python -u tools\fetch_data.py || exit /b 1
goto lint

rem install: copy the addon into the client
:install
call :lint || exit /b 1
call :need_addons || exit /b 1
call :need_libs || exit /b 1
if exist "%TARGET%" rmdir /s /q "%TARGET%"
mkdir "%TARGET%"
for %%d in (%DIRS% Libs) do xcopy /e /i /q /y "%%d" "%TARGET%\%%d" >nul
for %%f in (%FILES%) do copy /y "%%f" "%TARGET%\" >nul
echo installed %ADDON% %VERSION% -^> %TARGET% - /reload in game
exit /b 0

rem debug: link the working copy into the client (junctions)
:debug
call :need_addons || exit /b 1
call :need_libs || exit /b 1
if exist "%TARGET%" rmdir /s /q "%TARGET%"
mkdir "%TARGET%"
for %%d in (%DIRS%) do mklink /J "%TARGET%\%%d" "%CD%\%%d" >nul
for %%f in (%FILES%) do copy /y "%%f" "%TARGET%\" >nul
xcopy /e /i /q /y Libs "%TARGET%\Libs" >nul
echo linked %ADDON% -^> %TARGET% - /reload after each edit (re-run after editing the TOC)
exit /b 0

rem uninstall: remove the addon, SavedVariables stay
:uninstall
call :need_addons || exit /b 1
if not exist "%TARGET%" (echo not installed: %TARGET% & exit /b 0)
rmdir /s /q "%TARGET%"
echo removed %TARGET%
exit /b 0

rem dist: build dist\Gearwright-<version>.zip
:dist
call :lint || exit /b 1
call :need_libs || exit /b 1
if exist "%ZIP%" del /q "%ZIP%"
mkdir dist\stage\%ADDON% 2>nul
for %%d in (%DIRS% Libs) do xcopy /e /i /q /y "%%d" "dist\stage\%ADDON%\%%d" >nul
for %%f in (%FILES%) do copy /y "%%f" "dist\stage\%ADDON%\" >nul
tar -a -c -f "%ZIP%" -C dist\stage %ADDON%
rmdir /s /q dist\stage
echo built %ZIP%
exit /b 0

rem deploy: none - a v* tag pushed to Forgejo is exported to GitHub and packaged there
:deploy
echo No deploy: git tag v%VERSION% ^&^& git push origin main v%VERSION%
exit /b 0

rem clean: remove dist\ and .cache\
:clean
for %%d in (dist .cache) do if exist "%%d" rmdir /s /q "%%d"
echo clean
exit /b 0

rem distclean: clean and empty Libs\
:distclean
call :clean
if exist Libs rmdir /s /q Libs
echo distclean
exit /b 0
