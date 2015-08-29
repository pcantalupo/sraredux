=head1
Hisat

=cut

package Hisat;
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromString :config no_ignore_case);
use Data::Dumper;
use Carp;

sub new {
  my $class = shift;
  my $self = {};
  $self->{options} = shift;
  $self->{sraredux} = shift;
  $self->{debug} = $self->{sraredux}->get("debug");
  
  bless $self, $class;  
  $self->build;
  print Dumper ($self),"\n" if ($self->{debug});
  return $self;
}

sub build {
  my ($self) = @_;

  $self->{options} =~ /^(.+?)(\|.*)?$/;
  $self->{options} = $1;
  $self->{pipe} = $2;
  if (!$self->{pipe}) {
    croak "Hisat was not followed by a pipe to samtools to create bam file\n";
  }

  my $mm = {};
  my @opts = qw/x=s 1=s 2=s U=s sra-acc=s S=s s=s skip=s u=s upto=s 5=s trim5=s 3=s trim3=s
              N=s L=s i=s n-ceil=s dpad=s gbar=s
              pen-cansplice=s pen-noncansplice=s pen-intronlen=s min-intronlen=s max-intronlen=s
              known-splicesite-infile=s novel-splicesite-outfile=s novel-splicesite-infile=s rna-strandness=s
              ma=s mp=s np=s rdg=s rfg=s score-min=s k=s D=s R=s I=s minins=s X=s maxins=s
              un=s al=s un-conc=s al-conc=s un-gz=s
              met-file=s met=s rg-id=s rg=s o=s offrate=s p=s threads=s seed=s
              /;
  my @bools = qw/q qseq f r c phred64 int-quals very-fast fast sensitive very-sensitive
                 ignore-quals nofq norc no-temp-splicesite no-spliced-alignment
                 a all fr rf ff no-mixed no-discordant no-dovetail no-contain no-overlap
                 t time quiet met-stderr no-head no-sq omit-sec-seq reorder mm qc-filter non-deterministic
                 /;
  GetOptionsFromString($self->{options}, $mm, @opts, @bools);
  
  my $threads = $self->{sraredux}->get("threads"); 
  if ($threads) {   # give priority to command line 'threads' option
    $mm->{threads} = $threads;
    delete($mm->{p});
  }
  
  # build command line
  my @tokens = ();  
  foreach ( @bools ) {
    if (exists $mm->{$_}) {
      my $dash = "-";
      if (length($_) > 1) {
        $dash = "--";
      }
      push (@tokens, $dash . $_);
    }
  }
  foreach ( @opts ) {
    $_ =~ s/\=.+$//;    # x=s -> x
    if (exists $mm->{$_}) {
      my $dash = "-";
      if (length($_) > 1) {
        $dash = "--";
      }
      push (@tokens, $dash . $_ . " " . $mm->{$_});
    }
  }

  if (!$mm->{'sra-acc'}) {    # get sra-acc from Sraredux if necessary
    my $sra = $self->{sraredux}->get("sra");
    if ($sra) {
      push (@tokens, "--sra-acc $sra");
    }
  }
  
  my $logfile = $self->{sraredux}->get("logfile");
  if ($logfile) {
    push (@tokens, "2>> " . $logfile);
  }
  
  push (@tokens, $self->{pipe});
  push (@tokens, "> " . $self->{sraredux}->get("bam"));
  
  $self->{program} = "hisat";
  $self->{exec} = join(" ", $self->{program}, @tokens);
}

sub run {
  my ($self) = @_;
  my $stdout = `$self->{exec}`;   # stderr is captured into logfile in 'run'
  return ($?, $stdout);
}


1;
