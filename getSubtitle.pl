#!/usr/bin/perl

use Cwd 'abs_path';
use File::Basename;
use lib dirname(abs_path($0));
use subtitle;
use strict;

if((scalar @ARGV)!=1)
{
	print("Usage: $0 <videoFileName>\n");
	exit(1);
}
my ($videoFileName)=@ARGV;

subtitle::get_subtitle($videoFileName);