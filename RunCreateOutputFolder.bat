@echo off
REM This is a script to run photo copy and rename
REM

set perlFile=createEpsonOutputFolder.pl
set clientName=%1%
set fileRoot=C:\aberscanInProgress

perl %perlFile% -srcFolder "%fileRoot%\%clientName%\OriginalScans" -outputFolder "%fileRoot%\%clientName%\EnhancedScans"


exit /B 0
