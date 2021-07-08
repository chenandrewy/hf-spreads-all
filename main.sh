#!/bin/bash
#$ -cwd
#$ -m abe
#$ -M andrew.y.chen@frb.gov
# run issm spreads code
# to execute: "qsub issm_loop_a.sh"
# full data on wrds is 1983 to 1992
# takes about 5 minutes per year

echo "Starting Job at `date`"

mkdir ~/temp_output/
mkdir ~/temp_log/

echo PART 1/2 CALCULATING ISSM SPREADS

# run spreads code day by day
for year in $(seq 1983 1992)
do
    echo finding spreads for nyse/amex $year.  Today is `date` 
    sas issm_spreads.sas -set yyyy $year -set exchprefix nyam -log ../temp_log/log_nyam_$year.log

    echo finding spreads for nasdaq $year.  Today is `date` 
    sas issm_spreads.sas -set yyyy $year -set exchprefix nasd -log ../temp_log/log_nasd_$year.log
done    
echo "Ending Job at `date`"

echo combining and averaging and outputting to ~/temp_output/
sas combine_and_average.sas

echo PART 2/2 COMPILING WRDS IID SPREADS
sas iid_to_monthly.sas