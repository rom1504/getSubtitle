#!/usr/bin/perl

use Cwd 'abs_path';
use File::Basename;
use lib dirname(abs_path($0));
use subtitle;
use strict;
use Getopt::Long;

sub usage
{
	print("Usage: $0 [options] <videoFileName> [<subtitleFileName>]\n");
	print("Options :"."\n");
	print("--verbose"."\n");
	print("\t"."display more information about what the program does"."\n");
	exit(1);
}

my $verbose;
GetOptions ("verbose"  => \$verbose)
or usage();

if((scalar @ARGV)==0 || (scalar @ARGV)>2) {usage();}


my ($videoFileName,$subtitleFileName)=@ARGV;

subtitle::get_subtitle($videoFileName,$subtitleFileName,$verbose);
