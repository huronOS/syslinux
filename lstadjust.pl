#!/usr/bin/perl
#
# Take a NASM list and map file and make the offsets in the list file
# absolute.  This makes debugging a lot easier.
#
# Usage:
#
#  lstadjust.pl listfile mapfile outfile
#

($listfile, $mapfile, $outfile) = @ARGV;

open(LST, "< $listfile\0")
    or die "$0: cannot open: $listfile: $!\n";
open(MAP, "< $mapfile\0")
    or die "$0: cannot open: $mapfile: $!\n";
open(OUT, "> $outfile\0")
    or die "$0: cannot create: $outfile: $!\n";

%vstart = ();
undef $sec;

while (defined($line = <MAP>)) {
    chomp $line;
    if ($line =~ /^\-+\s+Section\s+(\S+)\s+\-/) {
	$sec = $1;
    }
    next unless (defined($sec));
    if ($line =~ /^vstart:\s+([0-9a-f]+)/i) {
	$vstart{$sec} = hex $1;
    }
}
close(MAP);

$offset = 0;
while (defined($line = <LST>)) {
    chomp $line;
    
    $source = substr($line, 40);
    if ($source =~ /^([^;]*);/) {
	$source = $1;
    }

    if ($source =~ /^\S*\s+(\S+)\s+(\S+)/) {
	$op = $1;
	$arg = $2;

	if ($op =~ /^(|\[)section$/i) {
	    $offset = $vstart{$arg};
	} elsif ($op =~ /^(absolute|\[absolute|struc)$/i) {
	    $offset = 0;
	}
    }

    if ($line =~ /^(\s*[0-9]+ )([0-9A-F]{8})(\s.*)$/) {
	$line = sprintf("%s%08X%s", $1, (hex $2)+$offset, $3);
    }

    print OUT $line, "\n";
}
