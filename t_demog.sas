FILENAME REFFILE '/home/u63513942/sasuser.v94/demog.xls';

PROC IMPORT DATAFILE=REFFILE
	DBMS=XLS
	OUT=WORK.DEMOG;
	GETNAMES=YES;
RUN;

/*Section 1: Summary stats for age */

data demog1;  /*demog1 is an intermediate data set that gets raw data from original demog */
 set demog;
 format dob1 date9.; /*format statement helps represent dob in a more meaningful way */
 
 /* variable for dob */
 /*dob=cat(day, '/',month,'/',year);*/ /* cat()stands for concatination function */
   dob=compress(cat(day, '/',month,'/',year)); /*compress function to remove additional space between data values */
   dob1=input(dob,ddmmyy10.); /*dob1 to numeric form. SAS takes dates from reference point 1st Jan 1960, all days aftre this have +ve values whereas before this have -ve */
   
   /*calculating age of pateint */
   age =(diagdt-dob1)/365;
   
   output; /*explicit output to create observations that already exists i.e trt =1 and trt =0 */
   trt=2;  /*coressponds to all patients cummulative of active and placebo groups */
   output; /*additional row within demog1 */
run;

/*evaluating statistical parameters for age */
proc sort data = demog1;
by trt;
run;


proc means data =demog1 noprint;
var age;
output out = agestats; /* comes in original dataset */
by trt;
run;

data agestats;
 set agestats;
 length value $10.;
 ord=1;
 if _stat_='N' then do; subord=1; value =strip(put(age,8.)); end; /*conditional parameter, age will take on only integer value */
 else if _stat_='MEAN' then do; subord=2; value =strip(put(age,8.1)); end; /*precision point of one decimal point */
 else if _stat_='STD' then do; subord=3; value = strip(put(age,8.2)); end; /*precision point of two decimal points */
 else if _stat_='MIN' then do; subord=4; value =strip(put(age,8.1)); end;/*precision point of one decimal point */
 else if _stat_='MAX' then do; subord=5; value =strip(put(age,8.1)); end; /*precision point of one decimal point */
 value=put(age,8.);
 rename _stat_=stat;
 drop _type_ _freq_ age;
run;

/* obtaining statistical parameter for gender */
proc format;
value genfmt /*format for gender variable */
1='Male'     /*mapping of gender variables */
2='Female'
;
run;

data demog2; /*second dataset which takes values from demog1 */
 set demog1;
 sex=put(gender,genfmt.); /* put fucntion converts numeric values to charecter format */
run;                      /* gender is var name, genfmt is format and sex is char typr */ 

proc freq data = demog2 noprint;
table trt*sex / outpct out = genderstats; /*2D proc frew with male and female subcategories */
                                          /* Pct used to obtain row */
run;

data genderstats;
 set genderstats;
 value =cat(count,'(',strip(put(round(pct_row,.1),8.1)), '%)');
 ord=2;
 if sex='MALE' then subord=1;
 else subord=2;
 rename sex=stat;
 drop count percent pct_row pct_col;
run;

/*obtain statistical parameters for race */
proc format;
value racefmt
1='White'
2='Black'
3='Hispanic'
4='Asian'
5='Other'
;
run;

data demog3; /*gets value from demog2 */
 set demog2;
 racec=put(race,racefmt.);
run;

proc freq data = demog3 noprint;
table trt*racec/outpct out = racestats;
run;

data racestats;
 set racestats;
 value =cat(count,'(',strip(put(round(pct_row,.1),8.1)), '%)');
 ord=3;
 if racec='Asian' then subord=1;
 else if racec='Black' then subord=2;
 else if racec='Hispanic' then subord=3;
 else if racec='White' then subord=4;
 else if racec='Other' then subord=5;
 rename racec=stat;
 drop count percent pct_row pct_col;
run;

/*appending data by treatment groups */
data allstats;
 set genderstats racestats agestats;
run;

/*transposing data by treatment groups */
proc sort data =allstats;
by ord subord stat;
run;

proc sql noprint;
select count(*) into: placebo from demog1 where trt=0;
select count(*) into:active from demog1 where trt=1;
select count(*) into:total from demog1 where trt=2;

proc transpose data =allstats out =t_allstats; /*input data set all stats, output dataset t_allstats */
var value;
id trt;
by ord subord stat;
run;

/*constructing final report*/

proc report data = t_allstats split='|';
columns ord subord stat_0_1_2;
define ord/ noprint order;/*ord and subord not part of final report */
define subord/ noprint order;
define stat/display width=50;
define _0/display width =30 "Placebo (N=&placebo)";
define _1/display width=30 "Active treatment (N=&active)";
define _2/display width=30 "All patients (N=&total)";
run;




