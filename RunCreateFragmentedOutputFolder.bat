@echo off
REM 
REM

set perlFinalFile=createEpsonFinalFolder.pl
set perlFragmentFile=fragmentMappingFileInto200s.pl
set clientName=%1%
set fileRoot=C:\aberscanInProgress
REM set fileRoot=D:\aberscan\photoArchive

REM Fragment
perl %perlFragmentFile% -outputFolder "%fileRoot%\%clientName%\EnhancedScans"
perl %perlFinalFile% -finalFolder "%fileRoot%\%clientName%\EnhancedScansFragmented" -outputFolder "%fileRoot%\%clientName%\EnhancedScans" -photoMappingFile "aberscanPhotoMappings_fragment.txt" 


exit /B 0
