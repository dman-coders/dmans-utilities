#!/usr/bin/perl
#
# Read a descript.ion file (filename[whitespace]caption
# and insert the found value into the appropriate jpeg
# using exiftool
#
# dman 2009-12

use strict;
use Image::ExifTool ':Public';
my $exifTool = new Image::ExifTool;

   my ($file) = @ARGV;
   if (! -e "$file") {
   	 $file = 'descript.ion';
   }
   if (! -e $file) {
     die ("Missing input file. Needs a descript.ion file in the current dir");
   }

   my $recordCount = 0;
   my $charCount = 0;
   my $totalCount = 0;
   open(IN, "< $file");
   while (<IN>) {
      $recordCount++;
      my($filename, $description); 
      if ($_ =~ m/^\"([^\"]+)\" (.*)$/ ) {
      	$filename = $1; $description = $2;
      }
      elsif ($_ =~  m/^([^\"]\S+) (.*)$/ ) {
      	$filename = $1; $description = $2;
      }
      else {
		print("NO MATCH $_\n");
      }
      # OK, now insert that tag into that file
      if ( -e $filename ) {
		print("Adding tag to [$filename]  = $description\n");
		#my $info = $exifTool->ImageInfo($filename);
		# dump current data 
		#foreach (keys %$info) {
		#    print "$_ => $$info{$_}\n";
		#}
		$exifTool->SetNewValue(Description => $description);

		my ($title, $discard) = split(/\./, $filename);
		if ("$title") {
			$title =~ s/\d\d\.\d\d\.\d\d //;
			print("Adding tag to [$filename]  Title = $title\n");
			$exifTool->SetNewValue(Title => $title);
		}
		else {
			print("No title\n");
		}
	
		$exifTool->WriteInfo($filename);
		
      }
      else {
		#print("File [$filename] not found, skipping\n");
      }

   }
   close(IN);
   print "Number of records = $recordCount\n";
   exit;