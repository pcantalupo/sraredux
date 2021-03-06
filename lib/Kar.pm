=head1
Kar

=cut

package Kar;
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

  my $mm = {};
  my @opts = qw//;
  my @bools = qw//;
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

  push (@tokens, "-c " . $self->{sraredux}->get("sraunalign") );  
  push (@tokens, "-d " . $self->{sraredux}->get("srasorted") );
  
  my $logfile = $self->{sraredux}->get("logfile");
  if ($logfile) {
    push (@tokens, "2>> " . $logfile);
  }

  $self->{program} = "kar";  
  $self->{exec} = join(" ", $self->{program}, @tokens);
}

sub run {
  my ($self) = @_;

  # remove any existing .unaligned.sra file
  unlink( $self->{sraredux}->get("sraunalign") );

  my $stdout = `$self->{exec}`;
  return ($?, $stdout);
}


1;
