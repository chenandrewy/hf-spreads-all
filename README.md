# Overview
Code high-frequency direct trading costs used in "Zeroing in on the Expected Returns of Anomalies" by Andrew Y. Chen and Mihail Velikov.

Generates permno-month effective bid-ask spreads in csv form using data from 
* Daily TAQ (via WRDS Intraday Indicators)
* Monthly TAQ (via WRDS Intraday Indicators)
* ISSM (from the raw high-frequency ISSM data)
* CRSP (for permnos)

Takes about 1 hour, mostly for the issm data.

# Thank Yous
* Craig Holden and Stacey Jacobsen.  The ISSM code is a minor adaptation of the code for their 2014 JF, which they graciously share.
* Rabih Moussawi.  We use his TAQ-CRSP link macro to merge MTAQ permnos
* WRDS Support for the assistance with understanding the IID data

# Instructions
upload to wrds server, run "qsub main.sh" at the linux prompt.

main.sh makes folders
* ~/temp_output/ - output data (csv format) goes here 
* ~/temp_log/ - sas log files go here	

helful wrds cloud commands:
* qstat: check status of jobs
* qdel [job number]: delete a job.
	
# Other Details
* Previous versions of the paper used Holden and Jacobsen's code to construct spreads directly from TAQ (instead of WRDS IID).  This led to very similar results, and since the WRDS IID code makes everything so much faster and doesn't hog up server capacity (and is probably better for the environment), we just went with WRDS IID in the 2021 revision.
* The code converts permno-day spreads to permno-month spreads two ways
  1. Equal-weight average across days.  This is the data used in the paper.
  2. Using the last observation of the month.  This is arguably more appropriate given that the CRSP gross returns are month end to month end.  But the results look mostly the same and previous papers use averaging so we went with that.  I spent some time arguing with a friend the other day whether scholars should do what's right vs what has been done and he's a real hardliner for doing what's right.  I have a more grey view that there are tradeoffs with replicability and transparency, and in this case the replicability issues won out.  
