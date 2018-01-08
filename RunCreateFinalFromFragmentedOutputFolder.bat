@echo off
REM 
REM


set perlOutputFile=createEpsonOutputFolder.pl
set perlFinalFile=createEpsonFinalFolder.pl
set perlFragmentFile=fragmentMappingFileInto200s.pl
set clientName=%1%
set fileRoot=C:\aberscanInProgress
REM **** set fileRoot=D:\aberscan\photoArchive
set origOutputFile=EnhancedScansOutOfDate
set fileRootName=negative

REM first, rename the old outputFolder to backup name
echo ""
echo Renaming dir '%fileRoot%\%clientName%\EnhancedScans' to '%origOutputFile%'
echo ""
REN %fileRoot%\%clientName%\EnhancedScans %origOutputFile%

REM copy fragmented output back into an outputfolder
REM perl %perlOutputFile% -srcFolder "%fileRoot%\%clientName%\EnhancedScansFragmented" -outputFolder "%fileRoot%\%clientName%\EnhancedScans" -fileStartNumber 3275 -fileRootName %fileRootName%
perl %perlOutputFile% -srcFolder "%fileRoot%\%clientName%\EnhancedScansFragmented" -outputFolder "%fileRoot%\%clientName%\EnhancedScans" -useOrigFileName 1
REM **** perl %perlOutputFile% -srcFolder "%fileRoot%\%clientName%\EnhancedScansFragmented" -outputFolder "F:\aberscan\EnhancedScans" -useOrigFileName 1

REM copy into the output folder the original final mapping file
echo ""
echo Copying mapping file '%fileRoot%\%clientName%\%origOutputFile%\AberscanPhotoMappings.txt' to '%fileRoot%\%clientName%\EnhancedScans\AberscanPhotoMappings.txt'
echo ""
COPY "%fileRoot%\%clientName%\%origOutputFile%\AberscanPhotoMappings.txt" "%fileRoot%\%clientName%\EnhancedScans\AberscanPhotoMappings.txt"
REM **** COPY "%fileRoot%\%clientName%\%origOutputFile%\AberscanPhotoMappings.txt" "F:\aberscan\EnhancedScans\AberscanPhotoMappings.txt"

REM create the final folder
perl %perlFinalFile% -finalFolder "%fileRoot%\%clientName%\FinalScans" -outputFolder "%fileRoot%\%clientName%\EnhancedScans"
REM **** perl %perlFinalFile% -finalFolder "F:\aberscan\FinalScans" -outputFolder "F:\aberscan\EnhancedScans"


exit /B 0
