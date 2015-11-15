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
        -finalFolder required
	-outputFolder required
	-photoMappingFile optional
	-removeOrigFileName optional
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $finalFolder = $cmdLine{ "finalFolder"};
    $outputFolder = $cmdLine{ "outputFolder"};
    $photoMappingFileName = $cmdLine{ "photoMappingFile"};
    $removeOrigFileName = $cmdLine{ "removeOrigFileName"};

    ## Check that the output folder exists, and the final doesn't
    unless(-e $outputFolder) {
	print ("Output folder '$outputFolder' doesn't exist\n");
	exit 1;
    }

    ## create the final folder
    if(createDestinationFolder( $finalFolder ) == 0) {
	 exit 2;
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
    my @mappings = ();
    my $mapping;
    my $subFolderName;
    my $outputFileName;
    my $tmpOutputFileName;
    my $tmpFinalFileName;
    my $tmpDirName;
    my $fromFileBaseName;
    my $toFileBaseName;
    my $dirName;
    my $fileExtension;
    my $line;
    my $tmpLine;
    my $photoCount;
    my %photoCounts;
    my $totalPhotoCount = 0;
    my $editedFolderName = "\ToBeEdited\\";

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\/$/);

    ## print the directory being searched
    #print("Path is '$path'\n");

    # open up the mapping file in the output folder
    open(IN, "$path\\$photoMappingFileName") or die "Can't open '$path\\$photoMappingFileName' for read: $!";

    while ($line = <IN>) {
	($tmpLine) = split(/ *$/, $line);
	($subFolderName, $outputFileName) = split(/, */,$tmpLine);
	#print ("subFolderName is '$subFolderName'\n");
	#print ("outputFileName is '$outputFileName'\n");

	# if the folder is new, then create it
	createSubFolders( $subFolderName, $finalFolder );

	$tmpDirName = "$finalFolder\\$subFolderName";
	if(! -e $tmpDirName ) {
	    if(createDestinationFolder( $tmpDirName ) == 0) {
	        exit 2;
	    }

	    # reset photo count for this folder
	    #$photoCounts{$tmpDirName} = 0;
	}
 
	# pull the name parts out of the $outputFileName
	($fromFileBaseName, $dirName, $fileExtension) = fileparse 
             ($outputFileName, ('\.[^.]+$') );
	#print("\tFile bits are '$dirName', '$fromFileBaseName', '$fileExtension'\n");

	# NOTE::: I can't figure out what this code was supposed to be doing, but I think that it is old and no longer needed. Instead
	# I want the name in the mapping file to be used for the final name


	#get just the substring if we are trying to remove the Orig File Name extension (for Kodak scans)
	#if($removeOrigFileName == 1) {
	#    $tmpLine =~ m/(photo\d+).*/;
	#    $toFileBaseName = $1;
	#}
	#else {
	    $toFileBaseName = $fromFileBaseName;
	#}


	# do the copy
	# first try finding the file in the 'ToBeEdited' subFolder, otherwise just get it from the <outputFolder>

	$tmpFinalFileName = "$tmpDirName\\$toFileBaseName$fileExtension";
	$photoCounts{$subFolderName}++;

	$tmpOutputFileName = "$path$editedFolderName$fromFileBaseName$fileExtension";
        if(-e $tmpOutputFileName) {
	    #here if in the edited folder
	    copy($tmpOutputFileName, $tmpFinalFileName) or die "File '$tmpOutputFileName' cannot be copied.";
	}
	else {
	    # here if in the output folder
	    $tmpOutputFileName = "$path$fromFileBaseName$fileExtension";
	    copy($tmpOutputFileName, $tmpFinalFileName) or die "File '$tmpOutputFileName' cannot be copied.";
	}
	#print("\t'$tmpOutputFileName' -> '$tmpFinalFileName'\n");
    }

    close( IN );

    # now print out the file counts for each sub folder created
    print("\nTotal Photo Counts:\n");
    for $tmpDirName (sort keys %photoCounts) {
	print("\tCopied '$photoCounts{$tmpDirName}' photos into folder '$tmpDirName'\n");
	$totalPhotoCount = $totalPhotoCount + $photoCounts{$tmpDirName};
    }
    print("\tTotal Count is '$totalPhotoCount'\n");
}


 


