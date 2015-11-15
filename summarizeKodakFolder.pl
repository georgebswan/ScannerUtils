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

my $wantedFolderName;
my $fileNumber;

# Global Variables - initialized in parseCommandLine
my %cmdLine;
my $srcFolder;
my $wantedFolderName;
my $wantedFoldersFileName;


################################################################
# This script will find all of the directories in $srcFolder that match any
# of the names that are stored in file "$wantedFoldersFileName" that exists in the $srcFolder
# 
# Foreach directory found, copy all the contents over to $destFolder, while renumbering the files
#

MAIN: {
    my %switches = qw (
        -srcFolder optional
	-wantedFolderName optional
	-wantedFoldersFileName optional
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $srcFolder = $cmdLine{ "srcFolder"};
    $wantedFoldersFileName = $cmdLine{ "wantedFoldersFileName"};
    $wantedFolderName = $cmdLine{ "wantedFolderName"};

    ## Check that the src folder exists, and the destination doesn't
    unless(-e $srcFolder) {
	print ("Source folder '$srcFolder' doesn't exist\n");
	exit 1;
    }

    $fileNumber = 1;

    print( "Processing Source Folder '$srcFolder'\n");
    processTopFolder ($srcFolder);

    ## print out the file count so that it can be used in the next run
    $fileNumber--;
    print("Final photo count is '$fileNumber'\n");

} # MAIN

################################################################
# processTopFolder
#
# This function looks through the top level folder pulling out
# those folders that match '$dirNameWanted'. If the directory
# is found, then the function 'processWantedFolder' is recursed
# until all photos are found
################################################################
sub processTopFolder {
    my ($path) = @_;
    my @contents = ();
    my $content;
    my $nameMatched;
    my $line;
    my $dirNameWanted;
    my $tmpFileName;
    my $matchCount = 1;
    my $tmpKey;
    my %photosFound;
    my %srcFolderMatched;
    my %wantedNametoSrcFolderMapping;
    my $matchFlag;
    my %dirNamesWanted;
    my $photoCount;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\/$/);

    ## print the directory being searched
    print("Path is '$path'\n");

    ## Find the dirNames wanted
    %dirNamesWanted = createWantedNames( $srcFolder, $wantedFoldersFileName, $wantedFolderName );

    #for $tmpKey (sort keys %dirNamesWanted) {
	#print("\tFound wanted folder string '$dirNamesWanted{$tmpKey}'\n");
    #}

    ## First, find all the src folders and store them. Content in the field means 'not found'
    foreach $content (findDirContent($path)) {
	if (-d $content) { $srcFolderMatched{$content} = $content; }
    }


    ## go in order of the dirNamesWanted, and recurse the directories 
    for $tmpKey (sort keys %dirNamesWanted) {
        print("Processing match word '$dirNamesWanted{$tmpKey}'\n");

        ## Find all the content in the directory
        foreach $content (findDirContent($path)) {
	    if( -d $content) {
	        ## here if I found a directory. Is it one of the one want?
	        $nameMatched = oneDirMatch( $content, $dirNamesWanted{$tmpKey}, $tmpKey );

		# Find all the photos in the src Folder
		$photoCount = processWantedFolder( $content, $nameMatched);

		# Does the src Folder match the name wanted?
	        if($nameMatched ne "none") {
		    # Here if yes. Record the number of photos that matched
		    $photosFound{$nameMatched} = $photosFound{$nameMatched} + $photoCount;

		    $fileNumber = $fileNumber + $photoCount;

		    # Note that the src Folder has been matched (by removing the name stored)
		    $srcFolderMatched{$content} = "";

		    # Start by removing the first word and trailing spaces from the src dirName
		    $content =~ s/^\S+\s*//;

		    # Now record the src folder that matched
		    $wantedNametoSrcFolderMapping{$nameMatched} = $wantedNametoSrcFolderMapping{$nameMatched} . 
		    "\t\t" . $photoCount ."\t" . $content . "\n";
	        }
	    }
	}
    }

    # list out the summary
    print("\nSummary:\n");
    for $tmpKey (sort keys %dirNamesWanted) {
	print("\t$photosFound{$tmpKey}\t$dirNamesWanted{$tmpKey} -> $tmpKey\n");
	print("$wantedNametoSrcFolderMapping{$tmpKey}");
    }

    # list out the src directories that were never matched
    print("\nSource Folders not Matched:\n");
    for $tmpKey (sort keys %srcFolderMatched) {
	if($srcFolderMatched{$tmpKey} ne "") {
	    print("\t$srcFolderMatched{$tmpKey}\n");
	}
    }

    print("\n");

    # Before finishing up, check to see that all matches found at least one photo
    for $tmpKey (sort keys %dirNamesWanted) {
	if( $photosFound{$tmpKey} == 0) {
	    print("WARNING: No directory matches found for the name '$dirNamesWanted{$tmpKey}'\n");
	    $matchFlag = 1;
	}
    }
    if ($matchFlag == 0) {
	print("INFO: All names found at least one match'\n");
    }

}

################################################################
# processWantedFolder
################################################################
sub processWantedFolder {
    my ($topPath, $nameMatched) = @_;
    my @contents = ();
    my $content;
    my $fileBaseName;
    my $dirName;
    my $fileExtension;
    my $path;
    my $origName;
    my $photoCount = 0;

    ## append a trailing / if it's not there
    $topPath .= '\\' if($topPath !~ /\/$/);

    ## print the directory being searched
    ##print("\tProcessing sub folder'$topPath'\n");

    ## Now deal with all of the files before we start recursing
    ## down the dirs
    @contents = findDirContent($topPath);
    foreach $content (findDirContent($topPath)) {
	if( -f $content) {
	    ## check to see if the file is a photo
	    ($fileBaseName, $dirName, $fileExtension) = fileparse 
                       ($content, ('\.[^.]+$') );
	    #print("\tFile bits are '$dirName', '$fileBaseName', '$fileExtension'\n");

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG") {
		# count it

		$photoCount++;
	    }
	}
    }

    foreach $content (@contents) {
	if( -d $content) {
	    ## here if a direcory. Recurse
	    $photoCount = $photoCount + processWantedFolder( $content, $nameMatched );
	}
    }

    return($photoCount);
}



