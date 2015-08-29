=head1
Sraredux

=cut

package Sraredux;
use strict;
use warnings;
use Carp;
use Cwd;
use File::Path;
use File::Copy;
use File::Basename;
use Data::Dumper;
use Hisat;
use Bamload;
use Srasort;
use Kar;

our $SRA;
sub new {
  my $class = shift;
  my $self = shift;
  bless $self, $class;  
  
  $self->{home} = getcwd()."/"; 
  $self->{folder} //= $self->{sra};
  #if (-d $self->{folder}) {
  #  rmtree $self->{folder};
  #}
  mkdir $self->{folder} unless (-d $self->{folder});
  copy($self->{config}, $self->{folder});
  chdir $self->{folder};

  $self->{threads} = 1 if !$self->{threads};
  $self->{logfile} = $self->{sra} . ".log";
  open ($self->{logfh}, ">>", $self->{logfile}) or die "Can't open ". $self->{logfile} . ": $!\n";

  $SRA = $self->{sra};
  $self->{bam} = $SRA . ".bam";                  # SRR0123.bam (file)
  $self->{sraraw} = $SRA . ".raw.sra";           # SRR0123.raw.sra (dir)
  $self->{srasorted} = $SRA . ".sorted.sra";     # SRR0123.sorted.sra (dir)
  $self->{sraunalign} = $SRA . ".unaligned.sra"; # SRR0123.unaligned.sra (file)

  $self->parseconfig;
  $self->restart;
  return $self;
}


sub run {
  my ($self) = @_;
  
  my $START = time;
  my $i = $self->{restart};
  for (; $i <= $#{$self->{programs}}; $i++) {
    my $p = $self->{programs}[$i];
    my $step = ref $p;

    my $ss = time;
    $self->logit($step . " starting: " . $p->{exec});
    my ($err, $stdout) = $p->run();    # return val 0 is exit OK

    if ($err) {
      $self->cleanup;
      croak "Error running step $step...exiting\n";
    }
    else {
      $self->restart($i + 1);
      $self->logit($step . " stdout: $stdout") if ($stdout);
      my $se = time;
      my $st = sprintf "%.8f", ($se - $ss)/86400;;
      $self->logit($step . " done\t$st\t$SRA");
    }
  }
  
  my $TT = sprintf "%.8f", (time - $START)/86400;
  $self->logit("Sraredux done\t$TT\t$SRA");
  $self->cleanup;
}

sub parseconfig {
  my ($self) = @_;
  
  $self->{config} = basename $self->{config};
  open IN, $self->{config};
  my @programs;
  while (<IN>) {
    next if /^#|^\s*$/;
    s/#.*$//;
    my @opts = split " ", $_;
    my $program = ucfirst( shift @opts );
    $program =~ s/-//g;
    push @programs, $program->new(join(' ', @opts), $self);
  }
  close IN;
  $self->{programs} = \@programs;
}

sub cleanup {
  my ($self) = @_;
  
  close $self->{logfh};
  rmtree $self->{sraraw} unless ($self->{donotdelete});
  
  chdir($self->{home});
}

sub logit {
  my ($self, $msg) = @_;
  my $date = `date`; chomp $date;
  print {$self->{logfh}} "$date\t$msg\n";
}

sub get {
  my ($self, $name) = @_;
  if ($name && exists $self->{$name}) {
    return $self->{$name};
  }
}

sub restart {
  my ($self, $r) = @_;
  my $rfile = "restart.txt";
  
  my $toReturn;
  if (defined $r && $r >= 0) {            # update restart file with value
    open (my $out, ">", $rfile);
    print $out "$r\n";
    $self->{restart} = $r;
  }
  else {
    if (-e $rfile) {
      open my $in, "<", $rfile;
      my $line = <$in>;
      chomp $line;
      $self->{restart} = $line;
      close $in;
    }
    else {
      $self->{restart} = 0;
    }
  }
  
  return $self->{restart};
}


1;
