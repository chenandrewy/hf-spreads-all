/* 
  reads in wrds iid data and exports csv to ~/temp_output/ 
  andrew chen 2021 04	
  
  even though wrds labels these spreads as "pct" or "percent," it's clear these spreads are straight ratios, hence the 100*
  
  We follow Abdi and Ranaldo for aggregation and additional screens
  	dollar weighted ave of intraday proporational effective spreads to obtain average daily spreads, then average 
  	days to get monthly spread.  They also use a screen like this one:
  	where spread_iid < 4*spreadq_iid
		and spread_iid < 40
		and spreadq_iid < 40;  	
  
  We follow Lou and Shu for quote delays (modified to use DTAQ and iid):
  	before 1999: 1 sec (2 sec is unavailable)
  	1999-2003: 0 sec
  	2003-present: DTAQ 

  We found that the interpolated spreads are pretty badly behaved, so don't use them.
  
  wrds documentation
	https://wrds-www.wharton.upenn.edu/pages/get-data/intraday-indicators-wrds/
	https://wrds-www.wharton.upenn.edu/pages/support/manuals-and-overviews/wrds-intraday-indicators/
	https://wrds-www.wharton.upenn.edu/documents/1038/WRDS_DTAQ_IID_Manual_1.0.pdf
	
  updated 2021 08 to add sym_root and sym_suffix
	
*/

proc datasets library=WORK kill; run; quit;
dm "out;clear;log;clear;"; /*clears output and log windows*/

libname s_iid "/wrds/nyse/sasdata/wrds_taqs_iid_v1/";
libname ms_iid "/wrds/nyse/sasdata/wrds_taqms_iid/";
*%let subsamp = month(date) = 4;
%let subsamp = not missing(date);

* ==== IMPORT DATA AND MERGE ====;

* NOTE THE TYPE OF SPREADS ARE CHOSEN HERE;

* MTAQ; 
* see https://wrds-www.wharton.upenn.edu/pages/get-data/nyse-trade-and-quote/trade-and-quote-monthly-product-1993-2014/taq-tools/intraday-indicators-by-wrds/;
data daily_mtaq; set s_iid.wrds_iid:;
	where &subsamp;

	if year(date) < 1999 then espread_pct = 100*ESpreadPct_VW1;
	else espread_pct = 100*ESpreadPct_VW0;	
	qspread_pct = 100*QSpreadPct_TW_m; 	* time weighted, market hours;

  	keep date symbol espread_pct qspread_pct;  	
run;

* DTAQ;
* see https://wrds-www.wharton.upenn.edu/pages/get-data/nyse-trade-and-quote/millisecond-trade-and-quote-daily-product-2003-present-updated-daily/taq-millisecond-tools/millisecond-intraday-indicators-by-wrds/;
data daily_dtaq; set ms_iid.wrds_iid_:;
	where &subsamp;

	espread_pct = 100*EffectiveSpread_Percent_DW;
	qspread_pct = 100*QuotedSpread_Percent_tw; 	* time weighted, market hours (only one available);
	
  	keep date symbol sym_root sym_suffix espread_pct qspread_pct year yearm;  	
run;

* merge dtaq and mtaq;
proc sql; create table daily_iid as select
	coalesce(a.symbol, b.symbol) as symbol
	, a.sym_root, a.sym_suffix
	, coalesce(a.date, b.date) as date
	, coalesce(a.espread_pct, b.espread_pct) as espread_pct
	, coalesce(a.qspread_pct, b.qspread_pct) as qspread_pct
	, a.espread_pct as espread_pct_dtaq
	from daily_dtaq as a full join daily_mtaq as b
	on a.symbol = b.symbol and a.date = b.date;
quit;	

data daily_iid; set daily_iid;
	format date yymmdd10.;
	yearm = year(date)*100 + month(date);
run;	

* check;
proc sort data=daily_iid; by yearm; run;
proc means data=daily_iid noprint;
	var espread_pct espread_pct_dtaq qspread_pct;
	by yearm;
	output out = daily_iid_check median = / autoname;
run;		



* ==== SCREEN AND COLLAPSE ==== ;
data temp; set daily_iid; run;

proc sort data=temp; by symbol sym_root sym_suffix yearm date; run;
data temp; set temp;
  	where espread_pct < 4*qspread_pct
		and espread_pct < 40
		and qspread_pct < 40
		and not missing(espread_pct);  		
  	by symbol sym_root sym_suffix yearm;
  	if last.yearm then do;
  		espread_pct_month_end = espread_pct;
	end;		
run;	


proc means data=temp noprint;
	var espread_pct espread_pct_month_end;
	by symbol sym_root sym_suffix yearm;
	output out = monthly_iid mean= /autoname;
run;		

data monthly_iid; set monthly_iid;	
	espread_n = _freq_;
	rename espread_pct_month_end_Mean = espread_pct_month_end;
	keep symbol sym_root sym_suffix yearm espread:;
run;	


* ==== SAVE ==== ;
proc print data=monthly_iid (obs=20); run;

proc export data = monthly_iid
  outfile = "~/temp_output/wrds_iid_monthly.csv"
  dbms = csv
  replace;
run;


proc export data = daily_iid
  outfile = "~/temp_output/wrds_iid_daily.csv"
  dbms = csv
  replace;
run;
