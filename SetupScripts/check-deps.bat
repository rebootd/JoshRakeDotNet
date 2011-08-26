@echo off
REM --------------------------------------------------------------------------
REM PUREPOSE: Install Ruby 1.9.2 and required Gems if missing
REM 
REM AUTHOR: Josh Coffman
REM --------------------------------------------------------------------------

REM check for ruby
IF EXIST C:\Ruby192 GOTO Gemcheck

ECHO Installing Ruby 1.9.2 installer...
../installers/rubyinstaller-1.9.2-p0.exe /tasks="assocfiles,modpath" /silent

:Gemcheck
REM check for albacore:
for /f "tokens=*" %%A in ( 'gem list ^| find /c "albacore"' ) do set MyVar=%%A

REM ECHO /%MyVar%/
if /i "%MyVar%"=="0" (goto Proceed)
exit /b

:Proceed
REM install albacore gem
ECHO installing required gems....
gem install bundler
REM now install gems using bundler
bundle install

