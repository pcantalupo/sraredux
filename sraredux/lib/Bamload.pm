=head1
Bamload

=cut

package Bamload;
use strict;
use warnings;
use Getopt::Long qw(GetOptionsFromString :config no_ignore_case);
use Data::Dumper;
use Carp;
use File::Path;

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

  my $mm = {};
  my @opts = qw/o=s output=s i=s input=s k=s config=s header=s t=s tmpfs=s u=s unaligned=s
                nomatch-log=s Q=s qual-quant=s q=s min-mapq=s cache-size=s minimum-match=s
                ref-filter=s edit-aligned-qual=s max-rec-count=s E=s max-rec-count=s
                r=s ref-file=s max-warning-dup-flag=s z=s xml-log=s L=s log-level=s option-file=s
              /;
  my @bools = qw/d accept-dups accept-nomatch no-cs P no-secondary unsorted sorted no-verify
                only-verify use-QUAL ref-config keep-mismatch-qual TI accept-hard-clip
                allow-multi-map v verbose q quiet
                 /;
  GetOptionsFromString($self->{options}, $mm, @opts, @bools);
  
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

  push (@tokens, "-o " . $self->{sraredux}->get("sraraw") );  
  push (@tokens, $self->{sraredux}->get("bam") );
  
  my $logfile = $self->{sraredux}->get("logfile");
  if ($logfile) {
    push (@tokens, "2>> " . $logfile);
  }
  
  #bam-load -o "$SRARAW" -L info "$BAM"
  $self->{program} = "bam-load";
  $self->{exec} = join(" ", $self->{program}, @tokens);
}

sub run {
  my ($self) = @_;

  # remove any left over .raw.sra output folder
  rmtree( $self->{sraredux}->get("sraraw") );

  my $stdout = `$self->{exec}`;    # bam-load sends output to stderr so should be no STDOUT
  return ($?, $stdout);
}


1;
