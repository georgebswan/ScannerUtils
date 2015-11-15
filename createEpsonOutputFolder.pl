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
my $mapFile;
my %photosFound;

# Global Variables - initialized in parseCommandLine
my %cmdLine;
my $srcFolder;
my $outputFolder;
my $fileRootName;
my $fileStartNumber;
my $photoMappingFileName;
my $useOrigFileName;

################################################################
# This script will find all of the directories in $srcFolder
# 
# Foreach directory found, we recurse to find all of the jpg files. Each file found is
# written to the output directory '$outputFolder' as a flat directory so that we can run
# Photoshop on the files.
#
# This script also creates a mapping files called "aberscanMapping" that retains information
# about where the photo file came from so that we can re-build the original directory structure from the files
# in the $outputFolder. 
#
# The script 'createFinalFolders' will take the output directory and the mapping file and re-create the set of folders
#

MAIN: {
    my %switches = qw (
        -srcFolder optional
	-outputFolder required
	-fileRootName optional
	-fileStartNumber optional
	-photoMappingFile optional
	-useOrigFileName optional
        -help optional
     );
    my $photoCount = 0;

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $srcFolder = $cmdLine{ "srcFolder"};
    $outputFolder = $cmdLine{ "outputFolder"};
    $fileRootName = $cmdLine{ "fileRootName"};
    $fileStartNumber = $cmdLine{ "fileStartNumber"};
    $photoMappingFileName = $cmdLine{ "photoMappingFile"};
    $useOrigFileName = $cmdLine{ "useOrigFileName"};

    ## Check that the src folder exists, and the destination doesn't
    unless(-e $srcFolder) {
	print ("Source folder '$srcFolder' doesn't exist\n");
	exit 1;
    }

    ## create the destination folder
    if(createDestinationFolder( $outputFolder ) == 0) {
	exit 2;
    }

    # create the photo mapping file in the destination folder
    open($mapFile, '>', "$outputFolder\\$photoMappingFileName") or die "Can't open '$outputFolder\\$photoMappingFileName' for write: $!";

    $fileNumber = $fileStartNumber;

    #print( "Processing Source Folder '$srcFolder'\n");

    processTopFolder ($srcFolder);

    ## print out the file count so that it can be used in the next run
    $fileNumber--;
    print("Last photo number is '$fileNumber'\n");
    $photoCount = $fileNumber - $fileStartNumber + 1;
    print("Total photo count is '$photoCount'\n");


    close( $mapFile );

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

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\\$/);

    ## print the directory being searched
    print("\tProcessing folder'$path'\n");


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

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG" || $fileExtension eq ".tif") {

		# use the orig file name or create a new one
		if($useOrigFileName == 1) {
		    $newFileName = $fileBaseName . $fileExtension;
		}
		elsif($useOrigFileName == 2) {
		    #is this a photo, slide, or negative?
		    $fileRootName = $fileBaseName;
		    $fileRootName =~ s/[0-9]+//g;
		    $newFileName = sprintf("%s%04d%s", $fileRootName, $fileNumber++, $fileExtension);
		}
		else {
		    # create the new file Name
		    $newFileName = sprintf("%s%04d%s", $fileRootName, $fileNumber++, $fileExtension);
		}

		# do the copy
		$tmpFileName = "$outputFolder\\$newFileName";
		#print("\t'$fileBaseName$fileExtension' -> '$tmpFileName'\n");
		$photoCount++;
		copy($content, "$tmpFileName") or die "File '$content' cannot be copied.";

		# record the mapping in the mapping file. First, strip out the srcFolder name
		$relativePath = findRelativePath($path, $srcFolder);
		print $mapFile "$relativePath,$newFileName\n";

	    }
	    else {
	    	# here for non standard file extensions, because Photoshop is going to save them as .jpg. End result is duplicate files
	    	# better to fix problem in SrcFolder before getting too far

		print("WARNING: File '$fileBaseName$fileExtension' ignored: Non-standard extension (.jpg or .JPG or .tif). Need to fix before doing enhancements in PhotoShop\n");
	    }
	}
    }

    # record the number of photos found in this folder
    $photosFound{$relativePath} = $photoCount;

    # Now recurse if needed
    foreach $content (@contents) {
	if( -d $content) {
	    ##check to make sure the directory name doesn't contain a ',' because that will make the createfinalfolder.pl fail
	    if( $content =~ /,/) {
		print("ERROR: Directory name '$content' contains an illegal character ','\n");
		exit 3;
            }

	    ## here if a directory. Recurse
	    processFolder( $content );
	}
    }
}


