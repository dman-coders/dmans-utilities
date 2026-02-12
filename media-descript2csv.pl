#!/usr/bin/perl
#
print "converting descript.ion file to descript.csv\n";

$oldfile = 'descript.ion';
$newfile = 'descript.csv';

open(OF, $oldfile);
open(NF, ">$newfile");

# read in each line of the file
while ($line = <OF>) {
  $line =~ s/"([^"]*)" ([^\r\n]*)/"$1", "$2"/;
  print $line . "\n";
  print NF $line;
}

close(OF);
close(NF);
