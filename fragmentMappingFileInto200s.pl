#! \strawberry\perl\bin\perl
    eval 'exec perl $0 ${1+"$@"}'
	if 0;

use strict refs;
use strict vars;
use strict subs;
use File::Basename;
use File::Copy;
use lib 'D:\Aberscan\PerlApplications\PerlLibrary';
require "library.pl";

my $mapFile;

# Global Variables - initialized in parseCorecommandLine
my %cmdLine;
my $finalFolder;
my $outputFolder;
my $photoMappingFileName;
my $removeOrigFileName;

################################################################
# This script pulls out file names that are the same 
# (e.g. XYZ and XYZ 1) and have the same size
#

MAIN: {
    my %switches = qw (
	-outputFolder required
	-photoMappingFile optional
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $outputFolder = $cmdLine{ "outputFolder"};
    $photoMappingFileName = $cmdLine{ "photoMappingFile"};

    ## Check that the output folder exists, and the final doesn't
    unless(-e $outputFolder) {
	print ("Output folder '$outputFolder' doesn't exist\n");
	exit 1;
    }

    print( "Processing Output Folder '$outputFolder'\n");

    processOutputFolder ($outputFolder);

} # MAIN

################################################################
# processOutputFolder
#
# This function looks through the top level output folder by
# reading the contents of the mapping file, and copying the files
# the right subFolder in '$finalFolder'
################################################################
sub processOutputFolder {
    my ($path) = @_;
    my $subFolderName;
    my $outputFileName;
    my $tmpOutputFileName;
    my $fromFileBaseName;
    my $dirName;
    my $fileExtension;
    my $line;
    my $tmpLine;
    my $newMappingFile;
    my $inputLines = 0;
    my $photoCount = 1;
    my $fragFolderCount = 100;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\/$/);

    ## print the directory being searched
    print("Path is '$path'\n");

    # open up the mapping file in the output folder
    open(IN, "$path\\$photoMappingFileName") or die "Can't open '$path\\$photoMappingFileName' for read: $!";

    # create the new mapping file in the output folder
    ($fromFileBaseName, $dirName, $fileExtension) = fileparse 
             ($photoMappingFileName, ('\.[^.]+$') );
    $newMappingFile = $fromFileBaseName . "_fragment" . $fileExtension;
    open($mapFile, '>', "$outputFolder\\$newMappingFile") or die "Can't open '$outputFolder\\$newMappingFile' for write: $!";

    while ($line = <IN>) {
	($tmpLine) = split(/ *$/, $line);
	($subFolderName, $outputFileName) = split(/, */,$tmpLine);
	$inputLines++;

	# pull the name parts out of the $outputFileName
	($fromFileBaseName, $dirName, $fileExtension) = fileparse 
             ($outputFileName, ('\.[^.]+$') );
	#print("\tFile bits are '$dirName', '$fromFileBaseName', '$fileExtension'\n")

	#have we found 200 photos? If yes, increment the fragment folder name
	if(($photoCount++ % 200) == 0) {
	    $fragFolderCount++;
	}


	$tmpOutputFileName = "$fragFolderCount\\,$fromFileBaseName$fileExtension\n";
	print $mapFile $tmpOutputFileName;
    }

    close( IN );
    close ($mapFile);

    print("\tDone creating the new mapping file '$newMappingFile'\n");
}


 


