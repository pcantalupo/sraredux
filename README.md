Add `bin` to your $PATH and `lib` to $PERL5LIB

### Run on SRR181596
`sraredux.pl --sra SRR181596 --config config/config.txt`

### Restart sraredux on an SRA to pick up where it left off
same command as above

### See how long each step took
`grep done SRR181596/SRR181596.log`

### See command lines that were executed
`grep starting SRR181596/SRR181596.log`

