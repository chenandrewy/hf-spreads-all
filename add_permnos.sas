/*

adds permnos to high freq data

andrew chen 2021 08


*/

* ==== import issm, iid, and msenames ====;

%include '/wrds/lib/utility/wrdslib.sas' ;

proc import datafile = '~/temp_output/issm_monthly.csv' out=issm 
	dbms=csv replace;
	guessingrows=6000;
run;	

proc import datafile = '~/temp_output/wrds_iid_monthly.csv' out=iid 
	dbms=csv replace;
	guessingrows=6000;
run;	

data msenames; set crsp.msenames; 	
	linkyearmstart = year(namedt)*100 + month(namedt);
	linkyearmend = year(nameendt)*100 + month(nameendt);	
	keep permno namedt nameendt ticker shrcls linkyearm:;
run;

* ==== append into dataset hf0 ==== ;
* clean issm
separate symbol into root and suffix
select dw spreads to match iid data
;
data temp; set issm; 
	sym_root = scan(symbol,1,'.');
	sym_suffix = scan(symbol,2,'.');	
	
	espread_pct_mean = eff_spread_dw_ave*100;
	yearm = year*100 + month;
	espread_n = eff_spread_n;
	espread_pct_month_end = .;
	
	keep sym_root sym_suffix espread: symbol yearm;
run;


data hf0;
	set temp iid;
run;	



* ==== add permnos using ticker + shrcls as hf1 ==== ;
*
	according to wrds, this is sufficient for dtaq
	but we also use this for issm due to lack of other options	
	since sym_root is missing for all mtaq data, this step does not add permnos for mtaq
	creates a tiny amount of duplicates, not sure why.
;

proc sql; create table hf1 as select
	a.*, b.permno
	from hf0 as a
	left join msenames as b
	on a.sym_root = b.ticker and a.sym_suffix = b.shrcls
	and a.yearm >= b.linkyearmstart and a.yearm <= b.linkyearmend
	and not missing(a.sym_root);
quit;

* ==== add permnos using WRDS tclink algo as hf2 ==== ;

* create link table using WRDS code;
%include '~/hf-spreads-all/macro_tclink.sas';
%TCLINK (BEGDATE=199301,ENDDATE=201012,OUTSET=WORK.mtaq_link);

proc sql; create table hf2 as select
	a.*, coalesce(a.permno, b.permno) as permno2
	from hf1 as a 
	left join mtaq_link as b
	on a.symbol = b.symbol and a.yearm = year(b.date)*100+month(b.date);
run;

* clean up;	
data hf2; format permno permno2 yearm espread_pct_mean espread_n espread_pct_month_end symbol sym_root sym_suffix;
	set hf2;
	where not missing(permno2);
	drop permno;
run;	
data hf2; set hf2;
	rename permno2=permno;
run;	
proc sort data=hf2; by permno yearm; run;


* ==== export ==== ;
proc export data = hf2
  outfile = "~/temp_output/hf_monthly.csv"
  dbms = csv
  replace;
run;
