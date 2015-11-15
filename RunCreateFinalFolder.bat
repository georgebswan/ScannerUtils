@echo off
REM This is a script to run photo copy and rename
REM

set perlFile=createEpsonFinalFolder.pl
set clientName=%1%
set fileRoot=C:\aberscanInProgress

perl %perlFile% -finalFolder "%fileRoot%\%clientName%\FinalScans" -outputFolder "%fileRoot%\%clientName%\EnhancedScans"


exit /B 0
