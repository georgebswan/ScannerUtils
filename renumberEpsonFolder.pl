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


my $fileNumber;
my %photosFound;

# Global Variables - initialized in parseCommandLine
my %cmdLine;
my $srcFolder;
my $destFolder;
my $fileRootName;
my $fileStartNumber;
my $useOrigFileName;

################################################################
# This script will find all of the directories in $srcFolder and make a complete copy of it, but will re-number the
# photo files
# 
#

MAIN: {
    my %switches = qw (
        -srcFolder optional
	-destFolder required
	-fileRootName optional
	-fileStartNumber optional
	-useOrigFileName optional
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $srcFolder = $cmdLine{ "srcFolder"};
    $destFolder = $cmdLine{ "destFolder"};
    $fileRootName = $cmdLine{ "fileRootName"};
    $fileStartNumber = $cmdLine{ "fileStartNumber"};
    $useOrigFileName = $cmdLine{ "useOrigFileName"};

    ## Check that the src folder exists, and the destination doesn't
    unless(-e $srcFolder) {
	print ("Source folder '$srcFolder' doesn't exist\n");
	exit 1;
    }

    ## create the destination folder
    if(createDestinationFolder( $destFolder ) == 0) {
	exit 2;
    }

    $fileNumber = $fileStartNumber;

    #print( "Processing Source Folder '$srcFolder'\n");

    processTopFolder ($srcFolder);

    ## print out the file count so that it can be used in the next run
    $fileNumber--;
    print("Final photo count is '$fileNumber'\n");

} # MAIN

################################################################
# processTopFolder
#
# This function looks through the top level. If a directory
# is found, then the function 'processFolder' is recursed
# until all photos are found
################################################################
sub processTopFolder {
    my ($path) = @_;
    my @contents = ();
    my $content;
    my $line;
    my $tmpFileName;
    my $tmpKey;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\\$/);

    ## print the directory being searched
    #print("Path is '$path'\n");

    processFolder( $path );

    # list out the summary
    print("\nSummary of Files found in each Folder:\n");
    for $tmpKey (sort keys %photosFound) {
	print("\t$photosFound{$tmpKey}\t$tmpKey\n");
    }

    print("\n");

}

################################################################
# processFolder
################################################################
sub processFolder {
    my ($path) = @_;
    my @contents = ();
    my $content;
    my $fileBaseName;
    my $dirName;
    my $fileExtension;
    my $relativePath;
    my $newFileName;
    my $tmpFileName;
    my $photoCount = 0;
    my $relativePath;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\\$/);

    ## print the directory being searched
    print("\tProcessing folder'$path'\n");


    # find the relative path for the dir we are currently in
    $relativePath = findRelativePath($path, $srcFolder);

    ## Find all the 'FD*' subdirectories 
    @contents = findDirContent($path);

    ## Now deal with all of the files before we start recursing
    ## down the dirs
    foreach $content (@contents) {
	if( -f $content) {
	    ## check to see if the file is a photo, then copy it to destination
	    ($fileBaseName, $dirName, $fileExtension) = fileparse 
                       ($content, ('\.[^.]+$') );
	    #print("\tFile bits are '$dirName', '$fileBaseName', '$fileExtension'\n");

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG" || $fileExtension eq ".tif" || $fileExtension eq ".tiff") {
		$fileExtension = ".tiff" if ($fileExtension eq ".tif");		#use an extension I prefer

		# use the orig file name or create a new one
		if($useOrigFileName == 1) {
		    $newFileName = $fileBaseName . $fileExtension;
		}
		else {
		    # create the new file Name
		    $newFileName = sprintf("%s%04d%s", $fileRootName, $fileNumber++, $fileExtension);
		}

		# do the copy
		$tmpFileName = "$destFolder\\$relativePath\\$newFileName";
		#print("\t'$fileBaseName$fileExtension' -> '$tmpFileName'\n");
		$photoCount++;
		copy($content, "$tmpFileName") or die "File '$content' cannot be copied.";
	    }
	}
    }

    # record the number of photos found in this folder
    $photosFound{$relativePath} = $photoCount;

    # Now recurse through each of the sub Folders
    foreach $content (@contents) {
	if( -d $content) {
	    # make sure the destination directory exists
    	    $relativePath = findRelativePath($content, $srcFolder);
	    $tmpFileName = "$destFolder\\$relativePath";
	    createDestinationFolder( $tmpFileName );
	    processFolder( $content );
	}
    }
}
