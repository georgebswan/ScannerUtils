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

my %dirNamesWanted;

# Global Variables - initialized in parseCommandLine
my %cmdLine;
my $srcFolder;
my $destFolder;
my $wantedFoldersFileName;
my $wantedFolderName;

########
# BUGS/ENHANCEMENTS
#
# 2. Sometimes it is good to be able to type in the whole 'wantedFoldersFileName'. Current it is only the file name
#    not the whole path. Check for file name by itself before pre-pending the path?

################################################################
# This script will find all of the folders in the 'srcFolder' that reasonably make up the kodak mapping file
# needed. It pulls out just the folders that match 'wantedName'

MAIN: {
    my %switches = qw (
        -srcFolder optional
	-destFolder optional
	-wantedFoldersFileName optional
	-wantedFolderName required
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );
    $srcFolder = $cmdLine{"srcFolder"};
    $destFolder = $cmdLine{"destFolder"};
    if($destFolder eq "") { $destFolder = $srcFolder; }

    $wantedFoldersFileName = $cmdLine{"wantedFoldersFileName"};
    $wantedFolderName = $cmdLine{"wantedFolderName"};


    ## Check that the src folder exists, and the destination doesn't
    unless(-e $srcFolder) {
	print ("Source folder '$srcFolder' doesn't exist\n");
	exit 1;
    }

    ## create the destination folder (if not the same as the src Folder)
    if($srcFolder ne $destFolder && createDestinationFolder( $destFolder ) == 0) {
	exit 2;
    }

    print( "Processing Source Folder '$srcFolder'\n");

    processTopFolder ($srcFolder, $wantedFoldersFileName, $wantedFolderName);

} # MAIN

################################################################
# processTopFolder
#
# This function looks through the top level folder finding all of the folders
# that might be needed in the mapping file
################################################################
sub processTopFolder {
    my ($path, $wantedFoldersFileName, $wantedFolderName) = @_;
    my @contents = ();
    my $content;
    my $mapFile;
    my $prevName = "";
    my $searchName = "";
    my $targetName = "";
    my $tmpPath = "";
    my $matchCount = 0;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\/$/);

    # create the mapping file in the destination folder
    open($mapFile, '>', "$destFolder\\$wantedFoldersFileName") or die "Can't open '$destFolder\\$wantedFoldersFileName' for write: $!";

    # Make a note that the mapping file was created by this script
    print $mapFile "# Created by 'createMappingFile.pl'\n";
    print $mapFile "# \tsrcFolder = '$srcFolder'\n";
    print $mapFile "# \tdestFolder = '$destFolder'\n";
    print $mapFile "# \twantedFolderName = '$wantedFolderName'\n\n";

    ## Find all the content in the directory
    @contents = findDirContent($path);

    foreach $content (@contents) {
	if( -d $content) {
	    # Here if I found a directory. Pull out the lead name
	    $content = findRelativePath($content, $srcFolder);

	    #print("Found directory '$content'\n");
	    # Does it match the name we are looking for? If 'wantedFolderName' is "", then all folders are matched
	    if( $wantedFolderName eq "" || $content =~ /^$wantedFolderName/) {

	    #print("\tMatched directory '$content'\n");
		# If the dirName has a 'Set' in it, then take out the 'Set' from the Kodak created folder name and everything after it. 
	        if($content =~ m/^(.+)Set.*$/) {
		    $searchName = $1;
		    $searchName =~ s/\s*$//; # The prior search doesn't strip out white space before the '#'
	        }
	        # If the dirName has a '_' in it, then take out the '_' from the Kodak created folder name and everything after it. 
	        elsif($content =~ m/^(.+)_.*$/) {
		    $searchName = $1;
	        }

	        # Have we seen this '$searchName' before
	        if( $searchName ne $prevName ) {
		    # Here if no, so write it into the mapping file
		    # Shorten the targetName to just the part that doesn't match 'wantedFolderName'
		    $targetName = $searchName;
	 	    $targetName =~ s/^$wantedFolderName//;
		    $matchCount++;

		    # Write out the mapping line
		    if ($targetName eq "") {
		        print $mapFile "$searchName\n";
		    }
		    else {
		        print $mapFile "$searchName :$targetName\n";
		    }
		    $prevName = $searchName;
		}
	    }
        }
    }

    # Check to see that at least one match was found
    print("ERROR: No matches for name '$wantedFolderName' was found\n") if ($matchCount == 0);


    close( $mapFile );
}
