# Example command line to remap SRR181596
sraredux.pl --sra SRR181596 --config /PATH/TO/rnaseq_mapping_hackathon_v002/sraredux/config/config.txt


# Restart sraredux on an SRA to pick up where it left off
same command as above


# See how long each step took
grep done SRR181596/SRR181596.log


# See command lines that were executed
grep starting SRR181596/SRR181596.log
