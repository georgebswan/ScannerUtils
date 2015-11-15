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
my $photoCount = 0;
my $relativePath;

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
    my $i;
    my $f1;
    my $f2;
    my $f3;
    my $f4;
    my $f5;
    my $b1;
    my $b2;
    my $b3;
    my $b4;
    my $b5;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\\$/);

    ## print the directory being searched
    print("\tProcessing folder'$path'\n");


    # find the relative path for the dir we are currently in
    $relativePath = findRelativePath($path, $srcFolder);

    ## Find all the 'FD*' subdirectories 
    @contents = findDirContent($path);

    # process each sheet (5 photos)
    for( $i = 0; $i< scalar(@contents); $i = $i+10) {
    
    	#are there still 10 photos remaining?
	if($contents[$i+5] ne "") {
	    #here if yes
	    $f1 = $contents[$i];
    	    $b3 = $contents[$i+1];
    	    $f2 = $contents[$i+2];
    	    $b4 = $contents[$i+3];
    	    $f3 = $contents[$i+4];
	    $b5 = $contents[$i+5];
	    $f4 = $contents[$i+6];
	    $b1 = $contents[$i+7];
	    $f5 = $contents[$i+8];
	    $b2 = $contents[$i+9];
	}
	else {
	    #here if no. the 5 remaining photos are in sequential order
	    $f1 = $contents[$i];
    	    $f2 = $contents[$i+1];
    	    $f3 = $contents[$i+2];
    	    $f4 = $contents[$i+3];
    	    $f5 = $contents[$i+4];
	    $b1 = "";
	    $b2 = "";
	    $b3 = "";
	    $b4 = "";
	    $b5 = "";
	}

        #print("Files are:\n\t$f1,\t$f2,\t$f3\t$f4,\t$f5,\t$b1,\t$b2,\t$b3,\t$b4,\t$b5\n");

	#copy the files into the dest folder
	copyFile($f1);
	copyFile($f2);
	copyFile($f3);
	copyFile($f4);
	copyFile($f5);

	#before doing the back page, check that there are photos for it
	if($b1 ne "") {
	    copyFile($b1);
	    copyFile($b2);
	    copyFile($b3);
	    copyFile($b4);
	    copyFile($b5);
	}

    }

    # record the number of photos found in this folder
    $photosFound{$relativePath} = $photoCount;

}

sub copyFile() {
    my ($content) = @_;
    my $fileBaseName;
    my $dirName;
    my $fileExtension;
    my $newFileName;
    my $tmpFileName;

    ## check to see if the file is a photo, then copy it to destination
	    ($fileBaseName, $dirName, $fileExtension) = fileparse 
                       ($content, ('\.[^.]+$') );
	    #print("\tFile bits are '$dirName', '$fileBaseName', '$fileExtension'\n");

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG" || $fileExtension eq ".tif" || $fileExtension eq ".tiff") {
		$fileExtension = ".tiff" if ($fileExtension eq ".tif");		#use an extension I prefer

		
	    	# create the new file Name
	    	$newFileName = sprintf("%s%04d%s", $fileRootName, $fileNumber++, $fileExtension);

		# do the copy
		$tmpFileName = "$destFolder\\$relativePath\\$newFileName";
		#print("\t'$fileBaseName$fileExtension' -> '$tmpFileName'\n");
		$photoCount++;
		copy($content, "$tmpFileName") or die "File '$content' cannot be copied.";
	    }
}