#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;

my %h;
while (<>) {

  chomp;
  next if /^#/;
  
  my ($ref, $source, $feat, $s, $e, $score, $str, $frame, $group) = split /\t/, $_;
  my %group = parts($group);   # (transcript_id => xxx, gene=> yyy);
  
  next unless (exists $group{transcript_id});
  my $tid = $group{transcript_id};
    
  if ($feat eq 'transcript') {
    my $gene = $group{gene};
    
    $h{$tid}{ref} = $ref;
    $h{$tid}{gene} = $gene;
    $h{$tid}{start} = $s;
    $h{$tid}{end} = $e;
    $h{$tid}{strand} = $str;
  }
  elsif ($feat eq 'exon' && exists $h{$tid}{gene}) {
    push (@{$h{$tid}{es}}, $s);
    push (@{$h{$tid}{ee}}, $e);  
  }
}


foreach my $t (keys %h) {
  if (exists $h{$t}{gene} && exists $h{$t}{es}) {  # make sure we have transcript and exon info for each Transcript ID
    my $num_exons = @{$h{$t}{es}};
    my $exonstarts = join(",", @{$h{$t}{es}});
    my $exonends = join(",", @{$h{$t}{ee}});
    print join("\t", $t, $h{$t}{gene}, $h{$t}{ref},
                     $h{$t}{strand}, $h{$t}{start}, $h{$t}{end}, $h{$t}{start}, $h{$t}{end},
                     $num_exons, $exonstarts, $exonends), "\n";
  }
}

sub parts {
  my ($s) = @_;
  my @a = split(/;/, $s);
  my %nv = map {/(.+)=(.+)$/; $1 => $2 } @a;
  return %nv;
}
