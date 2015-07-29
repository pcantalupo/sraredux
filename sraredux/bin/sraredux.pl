#!/usr/bin/env perl
use strict;
use warnings;
use File::Path;
use Sraredux;
use Getopt::Long;
use Data::Dumper;

my $o = {};
my @keys = qw(sra=s threads=i folder=s config=s help donotdelete debug);
GetOptions($o, @keys);

die join(' ', @keys),$/ if $o->{help};
die "Need to define sra (--sra)\n" if !$o->{sra};
die "Need to defined config file (--config)\n" if !$o->{config};

my $sra = Sraredux->new($o);
$sra->run;

