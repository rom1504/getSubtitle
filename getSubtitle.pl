#!/usr/bin/perl

use Cwd 'abs_path';
use File::Basename;
use lib dirname(abs_path($0));
use subtitle;
use strict;

if((scalar @ARGV)==0 || (scalar @ARGV)>2)
{
	print("Usage: $0 <videoFileName> [<subtitleFileName>]\n");
	exit(1);
}
my ($videoFileName,$subtitleFileName)=@ARGV;

subtitle::get_subtitle($videoFileName,$subtitleFileName);