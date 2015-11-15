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
my $photoCount;
my %dirNamesWanted;

# Global Variables - initialized in parseCommandLine
my %cmdLine;
my $srcFolder;
my $destFolder;
my $rootDestFolder;
my $wantedFoldersFileName;
my $wantedFolderName;
my $fileRootName;
my $fileStartNumber;
my $includeSource = 0;
my $createOutputDir;

##########
# BUGS/ENHANCEMNETS
# 1. If the contents are read from the aberscan* txt file, The order of processing is based on the 
#     target value, which isn't always the order you want (e.g. Dir1 : Newborn) will come after (Dir2 : Aged 1)
#     Need a way to force that the aberscan file is read in order of lines in file so that I can order manually
#     I guess the problem is that whatever I do, the folders will order with Aged 1 first, so the first folder
#     the customer looks at, the photo0001 isn't there - it is in folder Newborn). So this idea may be moot
#

################################################################
# This script will find all of the directories in $srcFolder that match any
# of the names that are stored in file "$wantedFoldersFileName" that exists in the $srcFolder
# 
# Foreach directory found, copy all the contents over to $destFolder, while renumbering the files
#

MAIN: {
    my %switches = qw (
        -srcFolder optional
	-destFolder required
	-fileRootName optional
	-fileStartNumber optional
	-wantedFoldersFileName optional
	-wantedFolderName optional
	-includeSource optional
	-createOutputDir optional
        -help optional
    );

    %cmdLine = parseCommandLine( %switches );

    # For now, map the cmdLine back to variables. I should replace all the unique global variables, but
    # I can't be bothered at the moment
    $srcFolder = $cmdLine{ "srcFolder"};
    $rootDestFolder = $cmdLine{ "rootDestFolder"};
    $destFolder = $rootDestFolder . "\\" . $cmdLine{ "destFolder"};
    $fileRootName = $cmdLine{ "fileRootName"};
    $fileStartNumber = $cmdLine{ "fileStartNumber"};
    $wantedFoldersFileName = $cmdLine{ "wantedFoldersFileName"};
    $wantedFolderName = $cmdLine{ "wantedFolderName"};
    $includeSource = $cmdLine{ "includeSource"};
    $createOutputDir = $cmdLine{ "createOutputDir"};

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

    print( "Processing Source Folder '$srcFolder'\n");

    processTopFolder ($srcFolder);

    ## print out the file count so that it can be used in the next run
    $fileNumber--;
    print("Final photo count is '$fileNumber'\n");

    ## now create the output dir if needed
    if ($createOutputDir == 1) {
	my $status = system(".\\RunCreateOutputFolder.bat $cmdLine{ \"destFolder\"}");
    }

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
    my $matchFlag;

    ## append a trailing / if it's not there
    $path .= '\\' if($path !~ /\/$/);

    ## print the directory being searched
    print("Path is '$path'\n");

    ## open up the file that contains the dirNames wanted
    %dirNamesWanted = createWantedNames( $srcFolder, $wantedFoldersFileName, $wantedFolderName );

    #for $tmpKey (sort keys %dirNamesWanted) {
	#print("Found wanted folder searchkey '$tmpKey' and target '$dirNamesWanted{$tmpKey}'\n");
    #}

    ## go in order of the dirNamesWanted, and recurse the directories 
    for $tmpKey (sort keys %dirNamesWanted) {

        ## Find all the content in the directory
        @contents = findDirContent($path);

        foreach $content (@contents) {
	    if( -d $content) {
	        ## here if I found a directory. Is it one of the one
	        ## we want?
	        $nameMatched = oneDirMatch( $content, $dirNamesWanted{$tmpKey}, $tmpKey );
	        #print("Matched srcDir '$content' to name '$nameMatched'\n");
	        if($nameMatched ne "none") {
		    $photoCount = 0;

		    print("Processing folder '$content'\n");
		    if($wantedFolderName eq "none") {
			# Here if using the mapping file
		        processWantedFolder( $content, "OriginalScans\\" . $nameMatched);
		    }
		    else {
			# Here if just using the wantedFolderName flag - don't need nameMatch cus it creates an extra level of folder
		        processWantedFolder( $content, "OriginalScans");
		    }

    		    # print out the number of photos found in folder
    		    #print("\tCopied '$photoCount' photos\n");

		    #record the number of photos that matched
		    $photosFound{$tmpKey} = $photosFound{$tmpKey} + $photoCount;
	        }
	    }
	}
    }

    # list out the summary
    print("\nSummary:\n");
    for $tmpKey (sort keys %dirNamesWanted) {
	print("\t$photosFound{$tmpKey}\t$dirNamesWanted{$tmpKey}\n");
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
    my $newFileName;
    my $tmpFileName;
    my $origName;
    my $tmpPath;

    ## append a trailing / if it's not there
    $topPath .= '\\' if($topPath !~ /\/$/);

    ## print the directory being searched
    ##print("\tProcessing sub folder'$topPath'\n");

    # make sure the destination Directory exists
    $tmpFileName = "$destFolder\\$nameMatched";
    if(! -d $tmpFileName) { createDestinationFolder( $tmpFileName ); }

    ## Find all the 'FD*' subdirectories 
    @contents = findDirContent($topPath);


    ## Now deal with all of the files before we start recursing
    ## down the dirs
    foreach $content (@contents) {
	if( -f $content) {
	    ## check to see if the file is a photo, then copy it to destination
	    ($fileBaseName, $dirName, $fileExtension) = fileparse 
                       ($content, ('\.[^.]+$') );
	    #print("\tFile bits are '$dirName', '$fileBaseName', '$fileExtension'\n");

	    if($fileExtension eq ".jpg" || $fileExtension eq ".JPG") {
		# create the new file Name
 		if($includeSource == 1) {
		    # here if I want to include the src dir in the output file name - great for finding file
		    # first do some manipulations to pull out just the piece of the kodak dir name I want
		    # Need to check to see if dir was created by hand (e.g. on flatbed) and therefore doesn't
		    # have the underscore in its name
		    $tmpPath = findRelativePath($dirName, $srcFolder);
		    if($tmpPath !~ /_/) {
			# Here for hand created. Take off the trailing '\' if there is one
			$tmpPath =~ s/\\$// if($tmpPath =~ /\\$/);
			$origName = $tmpPath;
		    }
		    else {
			# Here if created by the Kodak scanner
	   	        ($origName) = split( /_/, $tmpPath);
		    }
		    $newFileName = sprintf("photo%04d %s %s", $fileNumber++, $origName, $fileExtension);
		}
		else {
		    $newFileName = sprintf("%s%04d%s", $fileRootName, $fileNumber++, $fileExtension);
		}


		# do the copy
		$tmpFileName = "$destFolder\\$nameMatched\\$newFileName";

		#print out every tenth one to save on i/o
		if(($photoCount % 10) == 0) {
		    print("\t'$fileBaseName$fileExtension' -> '$tmpFileName'\n");
		}
		$photoCount++;
		copy($content, "$tmpFileName") or die "File '$content' cannot be copied."
	    }
	}
    }

    foreach $content (@contents) {
	if( -d $content) {
	    ## here if a direcory. Recurse
	    processWantedFolder( $content, $nameMatched );
	}
    }
}


