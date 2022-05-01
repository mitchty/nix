#!/usr/bin/env perl
#-*-mode: Perl; coding: utf-8;-*-
use strict;
use warnings;
use POSIX qw(strftime);
use Getopt::Long;

my $short = 0;
GetOptions('short' => \$short,
     's' => \$short
    );

my $now       = time;
if ($short) {
  print strftime('%Y%m%dT%H%M%SZ', (gmtime $now)) . "\n";
} else {
  print strftime('%Y-%m-%dT%H:%M:%SZ', (gmtime $now)) . "\n";
}
exit 0;
