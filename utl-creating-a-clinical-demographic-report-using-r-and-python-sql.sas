%let pgm=utl-creating-a-clinical-demographic-report-using-r-and-python-sql;

Creating a clinical demographic report using r and python sql

github
https://tinyurl.com/4st3wdxz
https://github.com/rogerjdeangelis/utl-creating-a-clinical-demographic-report-using-r-and-python-sql

 SOLUTIONS (Note SQL tens ro have less Klingon language and is easilt expandable)

    1 wps r sql

    2 wps python sql
      Python is a little less nmature than R
         a. No direct support for standard deviation
         b, No support for the enhanced formatting function (FORMAT)
         c. Much slower
         d. Note the trim function is needed in python but not R

    3 Related repos
      Many sas/wps reportoing repos

/*                   _
(_)_ __  _ __  _   _| |_
| | `_ \| `_ \| | | | __|
| | | | | |_) | |_| | |_
|_|_| |_| .__/ \__,_|\__|
        |_|
*/

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;informat
AGE 8.
SEX $2.
RACE $40.
ARM $40.
;input
AGE SEX RACE ARM @@;
cards4;
51 M Black Placebo 48 M Black Active
78 F White Active  59 F White Placebo
46 M Black Active  52 M White Placebo
52 F White Placebo 68 M Black Placebo
46 M Black Active  64 F Black Active
47 F White Placebo 58 M White Active
76 M Black Active  64 M White Placebo
58 F White Placebo 53 F Black Placebo
54 M Black Active  44 F White Active
74 F White Placebo 47 M White Placebo
46 M Black Active  69 F White Active
77 F White Active  53 M Black Placebo
83 M White Placebo 58 M White Active
46 M Black Placebo 57 F Black Placebo
57 M White Active  79 F White Active
67 M White Placebo 70 M White Placebo
59 M White Active  75 F White Active
65 M Black Placebo 65 M Black Active
54 F White Active  73 M White Active
44 F Black Placebo 70 M White Placebo
51 M White Active  69 M Black Active
71 M White Active  52 F White Placebo
85 F White Placebo 43 M Black Active
55 M Black Active  59 M White Active
46 M Black Placebo 52 M White Active
58 F White Active  46 F White Placebo
62 M White Active  84 F Black Placebo
48 M Black Placebo 75 M White Placebo
55 M Black Active  74 M Black Active
60 M White Placebo 76 F White Placebo
;;;;
run;quit;

/**************************************************************************************************************************/
/*                           |                                           |                                                */
/*         INPUT             |        PROCESS (EXAMPLE)                  |                  OUTPUT                        */
/*                           |                                           |                                                */
/* AGE  SEX  RACE     ARM    |                                           | STATISTIC           ACTIVE        PLACEBO      */
/*                           |                                           |                                                */
/*  51   M   Black  Placebo  |  select                                   | N                   N=31          N=29         */
/*  78   F   White  Active   |    1 as odr                               |                                                */
/*  46   M   Black  Active   |   ,arm as major                           | Gender N(Pct) F     9 (15.0%)     13 (21.7%)   */
/*  52   F   White  Placebo  |   ,`Gender N(Pct) ` || sex   as minor     | Gender N(Pct) M     22 (36.7%)    16 (26.7%)   */
/*  46   M   Black  Active   |   ,format(`%.0f`,1.0*count(*))  || ` (` |||                                                */
/*  47   F   White  Placebo  |      format(`%.1f`,100.0*count(sex)       | Race N(Pct) Black   13 (21.7%)    11 (18.3%)   */
/*  76   M   Black  Active   |       /(select 1.0*count(*) from have)) | | Race N(Pct) White   18 (30.0%)    18 (30.0%)   */
/*  58   F   White  Placebo  |        | `%)` as val                      |                                                */
/*  54   M   Black  Active   |   from                                    | Age Mean(Stdev)     60 (11.1)     60 (12.6)    */
/*  74   F   White  Placebo  |     have                                  |                                                */
/*  46   M   Black  Active   |   group                                   | Age Min Max         (43 79)       (44 85)      */
/*  77   F   White  Active   |     by sex, arm                           |                                                */
/*  83   M   White  Placebo  |                                           | Age >= 65 Years     11 (18.3%)    11 (18.3%)   */
/*  46   M   Black  Placebo  | STATISTIC         ACTIVE     PLACEBO      | Age Under 65 Years  20 (33.3%)    18 (30.0%)   */
/*  .....                    |                                           |                                                */
/*  48   M   Black  Placebo  | Gender N(Pct) F   9 (15.0%)  13 (21.7%)   |                                                */
/*  55   M   Black  Active   | Gender N(Pct) M   22 (36.7%) 16 (26.7%)   |                                                */
/*  60   M   White  Placebo  |                                           |                                                */
/*                           |                                           |                                                */
*/ /***********************************************************************************************************************/

/*                                         _
/ | __      ___ __  ___   _ __   ___  __ _| |
| | \ \ /\ / / `_ \/ __| | `__| / __|/ _` | |
| |  \ V  V /| |_) \__ \ | |    \__ \ (_| | |
|_|   \_/\_/ | .__/|___/ |_|    |___/\__, |_|
             |_|                        |_|
*/

proc datasets lib=sd1 nolist nodetails;delete want; run;quit;

%utl_submit_wps64x(resolve('

%macro _space(odr)/des="create a blank line between categories";
   union
   select
      &odr as odr
     ,arm  as major
     ,` `  as minor
     ,` `  as val
  from
    have
  group
    by arm
%mend _space;

libname sd1 "d:/sd1";
proc r;
export data=sd1.have r=have;
submit;
library(sqldf);
wantnrm <- sqldf("
   select
     1 as odr
     ,arm as major
     ,`N`            as minor
     ,`N=` || format(`%.0f`,1.0*count(*)) as val
  from
    have
  group
    by arm
  %_space(1.5)
  union
  select
    2 as odr
   ,arm as major
   ,`Gender N(Pct) ` || sex   as minor
   ,format(`%.0f`,1.0*count(*))  || ` (` ||
      format(`%.1f`,100.0*count(sex)/(select 1.0*count(*) from have)) || `%)` as val
  from
    have
  group
    by sex, arm
  %_space(2.5)
  union
  select
    3 as odr
   ,arm as major
   ,`Race N(Pct) ` || race   as minor
   ,format(`%.0f`,1.0*count(*))  || ` (` ||
      format(`%.1f`,100.0*count(race)/(select 1.0*count(*) from have)) || `%)` as val
  from
    have
  group
    by race, arm
  %_space(3.5)
  union
  select
    4 as odr
   ,arm                as major
   ,`Age Mean(Stdev) ` as minor
   ,printf(`%.0f`,avg(age)) || ` (` || printf(`%.1f`,stdev(age)) || `)` as val
  from
    have
  group
    by arm
  %_space(4.5)
  union
  select
    5 as odr
   ,arm                as major
   ,`Age Min Max `     as minor
   ,`(` || printf(`%.0f`,min(age)) || `,` || printf(`%.0f`,max(age)) || `)` as val
  from
    have
  group
    by arm
  %_space(5.5)
  union
  select
    6 as odr
   ,arm as major
   ,case when age >= 65 then `Age >= 65 Years` else `Age Under 65 Years` end as minor
   ,format(`%.0f`,1.0*count(arm))  || ` (` ||
      format(`%.1f`,100.0*count(arm)/(select 1.0*count(*) from have)) || `%)` as val
  from
    have
  group
    by  case when age >= 65 then `Age >= 65 Years` else `Age under 65 Years` end, arm
  order
    by odr
");
want <- sqldf("
  select
     l.minor  as Statistic
    ,l.val as Active
    ,r.val as Placebo
  from
     wantnrm as l inner join wantnrm as r
  on
          l.major = `Active`
     and  r.major = `Placebo`
     and  r.minor = l.minor
     and  r.odr   = l.odr
");
want;
str(want);
endsubmit;
import data=sd1.want r=want;
run;quit;
'));

proc print data=sd1.want;
run;quit;

/**************************************************************************************************************************/
/*                                                                                                                        */
/*    STATISTIC             ACTIVE        PLACEBO                                                                         */
/*                                                                                                                        */
/*    N                     N=31          N=29                                                                            */
/*                                                                                                                        */
/*    Gender N(Pct) F       9 (15.0%)     13 (21.7%)                                                                      */
/*    Gender N(Pct) M       22 (36.7%)    16 (26.7%)                                                                      */
/*                                                                                                                        */
/*    Race N(Pct) Black     13 (21.7%)    11 (18.3%)                                                                      */
/*    Race N(Pct) White     18 (30.0%)    18 (30.0%)                                                                      */
/*                                                                                                                        */
/*    Age Mean(Stdev)       60 (11.1)     60 (12.6)                                                                       */
/*                                                                                                                        */
/*    Age Min Max           (43 79)       (44 85)                                                                         */
/*                                                                                                                        */
/*    Age >= 65 Years       11 (18.3%)    11 (18.3%)                                                                      */
/*    Age Under 65 Years    20 (33.3%)    18 (30.0%)                                                                      */
/*                                                                                                                        */
/**************************************************************************************************************************/

/*___                                     _   _                             _
|___ \  __      ___ __  ___   _ __  _   _| |_| |__   ___  _ __    ___  __ _| |
  __) | \ \ /\ / / `_ \/ __| | `_ \| | | | __| `_ \ / _ \| `_ \  / __|/ _` | |
 / __/   \ V  V /| |_) \__ \ | |_) | |_| | |_| | | | (_) | | | | \__ \ (_| | |
|_____|   \_/\_/ | .__/|___/ | .__/ \__, |\__|_| |_|\___/|_| |_| |___/\__, |_|
                 |_|         |_|    |___/                                |_|
*/

%macro _space(odr)/des="create a blank line between categories";
   union
   select
      &odr as odr
     ,arm  as major
     ,` `  as minor
     ,` `  as val
  from
    have
  group
    by arm
%mend _space;

proc datasets lib=sd1 nolist nodetails;delete want; run;quit;

%utl_submit_wps64x("
options validvarname=any lrecl=32756;
libname sd1 'd:/sd1';
proc python;
export data=sd1.have python=have;
submit;
from os import path;
import pandas as pd;
import numpy as np;
from pandasql import sqldf;
mysql = lambda q: sqldf(q, globals());
from pandasql import PandaSQL;
pdsql = PandaSQL(persist=True);
sqlite3conn = next(pdsql.conn.gen).connection.connection;
sqlite3conn.enable_load_extension(True);
sqlite3conn.load_extension('c:/temp/libsqlitefunctions.dll');
mysql = lambda q: sqldf(q, globals());
wantnrm = pdsql('''
   select
     1 as odr
     ,arm as major
     ,`N`            as minor
     ,`N=` || printf(`%.0f`,1.0*count(*)) as val
  from
    have
  group
    by arm
  %_space(1.5)
  union
  select
    2 as odr
   ,arm as major
   ,`Gender N(Pct) ` || sex   as minor
   ,printf(`%.0f`,1.0*count(*))  || ` (` ||
      printf(`%.1f`,100.0*count(sex)/(select 1.0*count(*) from have)) || `%)` as val
  from
    have
  group
    by sex, arm
  %_space(2.5)
  union
  select
    3 as odr
   ,arm as major
   ,`Race N(Pct) ` || race   as minor
   ,printf(`%.0f`,1.0*count(*))  || ` (` ||
      printf(`%.1f`,100.0*count(race)/(select 1.0*count(*) from have)) || `%)` as val
  from
    have
  group
    by race, arm
  %_space(3.5)
  union
  select
    4 as odr
   ,arm                as major
   ,`Age Mean(Stdev) ` as minor
   ,printf(`%.0f`,avg(age)) || ` (` || printf(`%.1f`,stdev(age)) || `)` as val
  from
    have
  group
    by arm
  %_space(4.5)
  union
  select
    5 as odr
   ,arm                as major
   ,`Age Min Max `     as minor
   ,`(` || printf(`%.0f`,min(age)) || `,` || printf(`%.0f`,max(age)) || `)` as val
  from
    have
  group
    by arm
  %_space(5.5)
  union
  select
    6 as odr
   ,arm as major
   ,case when age >= 65 then `Age >= 65 Years` else `Age Under 65 Years` end as minor
   ,printf(`%.0f`,1.0*count(arm))  || ` (` ||
      printf(`%.1f`,100.0*count(arm)/(select 1.0*count(*) from have)) || `%)` as val
  from
    have
  group
    by  case when age >= 65 then `Age >= 65 Years` else `Age under 65 Years` end, arm
  order
    by odr;
''');
print(wantnrm);
print(wantnrm.info());
want = pdsql('''
  select
     l.minor  as Statistic
    ,l.val as Active
    ,r.val as Placebo
  from
     wantnrm as l inner join wantnrm as r
  on
          trim(l.major) = `Active`
     and  trim(r.major) = `Placebo`
     and  trim(r.minor) = trim(l.minor)
     and  r.odr   = l.odr
''');
print(want);
endsubmit;
import data=sd1.want python=want;
run;quit;
");

proc print data=sd1.want;
run;quit;

/**************************************************************************************************************************/
/*                                                                                                                        */
/*  Obs    STATISTIC             ACTIVE        PLACEBO                                                                    */
/*                                                                                                                        */
/*    1    N                     N=31          N=29                                                                       */
/*    2                                                                                                                   */
/*    3    Gender N(Pct) F       9 (15.0%)     13 (21.7%)                                                                 */
/*    4    Gender N(Pct) M       22 (36.7%)    16 (26.7%)                                                                 */
/*    5                                                                                                                   */
/*    6    Race N(Pct) Black     13 (21.7%)    11 (18.3%)                                                                 */
/*    7    Race N(Pct) White     18 (30.0%)    18 (30.0%)                                                                 */
/*    8                                                                                                                   */
/*    9    Age Mean(Stdev)       60 (11.1)     60 (12.6)                                                                  */
/*   10                                                                                                                   */
/*   11    Age Min Max           (43,79)       (44,85)                                                                    */
/*   12                                                                                                                   */
/*   13    Age >= 65 Years       11 (18.3%)    11 (18.3%)                                                                 */
/*   14    Age Under 65 Years    20 (33.3%)    18 (30.0%)                                                                 */
/*                                                                                                                        */
/**************************************************************************************************************************/

/*____            _       _           _
|___ /   _ __ ___| | __ _| |_ ___  __| |  _ __ ___ _ __   ___  ___
  |_ \  | `__/ _ \ |/ _` | __/ _ \/ _` | | `__/ _ \ `_ \ / _ \/ __|
 ___) | | | |  __/ | (_| | ||  __/ (_| | | | |  __/ |_) | (_) \__ \
|____/  |_|  \___|_|\__,_|\__\___|\__,_| |_|  \___| .__/ \___/|___/
                                                  |_|
*/
  select
     l.minor  as Statistic
    ,l.val    as Active
    ,r.val    as Placebo
  from
     wantnrm as l inner join wantnrm as r
  on
          l.major = `Active`
     and  r.major = `Placebo`
     and  r.minor = l.minor
     and  r.odr   = l.odr

https://github.com/rogerjdeangelis/utl-Compendium-of-proc-report-clinical-tables
https://github.com/rogerjdeangelis/utl-create-a-simple-n-percent-clinical-table-in-r-sas-wps-python-output-pdf-rtf-xlsx-html-list
https://github.com/rogerjdeangelis/utl-creating-a-clinical-n-mean-stddev-median-min-max-sas-dataset-from-proc-tabulate
https://github.com/rogerjdeangelis/utl-do-clinical-visits-occur-according-to-study-schedule
https://github.com/rogerjdeangelis/utl-excluding-patients-that-had-same-condition-pre-and-post-clinical-randomization-hash
https://github.com/rogerjdeangelis/utl-make-fake-relational-clinical-tables-demographics-lab-exposure-adverse-events
https://github.com/rogerjdeangelis/utl-set-the-clinical-programming-environment-and-extract-titles-foot-column-headings-from-mocks
https://github.com/rogerjdeangelis/utl_clinical_report
https://github.com/rogerjdeangelis/utl_minimal_code_for_demographic_clinical_n_percent_report
https://github.com/rogerjdeangelis/utl_minimum_code_npct_clinical_report_with_bigN_headers

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/

























































































libname xpt xport "d:/xpt/c01sdm_Dm.xpt";
*libname xpt xport "d:/xpt/Dm.xpt";

proc contents data=xpt._all_ position;
run;quit;

options validvarname=upcase;
libname sd1 "d:/sd1";
data have;
  set xpt.dm;
  armcd=armcd+1;
  studyid='ACHME123' ;
  subjid=substr(usubjid,3);
  usubjid=cats(siteid,'-',SUBJID);
  if sex='Wh' then sex='M';else sex='F';
  if race='Other' then race='Black';
  age=age+15;
  drop RFSTDTC       RFENDTC      SITEID     BRTHDTC AGEU;
run;quit;

proc datasets lib=sd1 nolist nodetails;delete want; run;quit;


%let _vls=%utl_varlist(have) ;
%array(_var,values=&_vls);

data _null_;
  set have end=dne;
  if _n_=1 then do;
     put "data have;informat ";
     %do_over(_var,phrase=%str(
         if vtype(?) ne "N" then typ='$';
         else typ = "";
         typLen = cats(typ,vlength(?),'.');
         put "?" +1 typLen;
         )
     );
     put ';input';
     put "&_vls;";
     put 'cards4;';
     if dne then put ';run;quit;';
  end;

  put &_vls ;
  if dne then put ';;;;' / 'run;quit;';

run;quit;

/*____            _       _           _
|___ /   _ __ ___| | __ _| |_ ___  __| |  _ __ ___ _ __   ___  ___
  |_ \  | `__/ _ \ |/ _` | __/ _ \/ _` | | `__/ _ \ `_ \ / _ \/ __|
 ___) | | | |  __/ | (_| | ||  __/ (_| | | | |  __/ |_) | (_) \__ \
|____/  |_|  \___|_|\__,_|\__\___|\__,_| |_|  \___| .__/ \___/|___/
                                                  |_|
*/

https://github.com/rogerjdeangelis/utl-Compendium-of-proc-report-clinical-tables
https://github.com/rogerjdeangelis/utl-clinical-if-a-patient-answers-yes-to-any-of-four-questions-they-will-be-ineligible
https://github.com/rogerjdeangelis/utl-clinical-trials-futility-analysis
https://github.com/rogerjdeangelis/utl-create-a-simple-n-percent-clinical-table-in-r-sas-wps-python-output-pdf-rtf-xlsx-html-list
https://github.com/rogerjdeangelis/utl-creating-a-clinical-n-mean-stddev-median-min-max-sas-dataset-from-proc-tabulate
https://github.com/rogerjdeangelis/utl-data-process-model-for-clinical-adverse-events
https://github.com/rogerjdeangelis/utl-do-clinical-visits-occur-according-to-study-schedule
https://github.com/rogerjdeangelis/utl-excluding-patients-that-had-same-condition-pre-and-post-clinical-randomization-hash
https://github.com/rogerjdeangelis/utl-extract-icd9-codes-from-strings-clinical
https://github.com/rogerjdeangelis/utl-last-assay-date-prior-to-exposure-date-clinical
https://github.com/rogerjdeangelis/utl-make-fake-relational-clinical-tables-demographics-lab-exposure-adverse-events
https://github.com/rogerjdeangelis/utl-mapping-clinical-terms-to-descriptions-for-a-large-number-of-vocabularies
https://github.com/rogerjdeangelis/utl-randomly-select-an-equal-number-of-screened-subjects-to-each-arm-of-a-clinical-trial
https://github.com/rogerjdeangelis/utl-scan-and-extract-character-and-numeric-data-from-a-clinical-narative-of-one-million-bytes
https://github.com/rogerjdeangelis/utl-set-the-clinical-programming-environment-and-extract-titles-foot-column-headings-from-mocks
https://github.com/rogerjdeangelis/utl_clinical_n_percent_crosstab
https://github.com/rogerjdeangelis/utl_clinical_report
https://github.com/rogerjdeangelis/utl_minimal_code_for_demographic_clinical_n_percent_report
https://github.com/rogerjdeangelis/utl_minimum_code_npct_clinical_report_with_bigN_headers

/*              _
  ___ _ __   __| |
 / _ \ `_ \ / _` |
|  __/ | | | (_| |
 \___|_| |_|\__,_|

*/
