
capture log close osf20
log using $stata/osf20_author_outcomes.smcl, name(osf20) replace text

//	project:	SocArXiv

//  task:		Feminist Careers: Author Outcomes
//				Merge all WoS + OSF + Survey

//  github:   	SocArXiv_gender
//  author:   	Molly King 

display "$S_DATE  $S_TIME"

***--------------------------***
// PROGRAM SETUP
***--------------------------***

version 18 // keeps program consistent for future replications
set linesize 80
clear all
set more off

***--------------------------***

use $raw/authors_table.dta, clear
drop if responseid == ""

merge 1:1 responseid using $clean/survey_clean.dta
drop if _merge == 2
drop _merge

merge 1:m jm_auth_id using $raw/papers_authors_crosswalk.dta
*drop if _merge == 2 // authors not in survey
drop _merge

merge m:1 jm_paper_id using $raw/papers_table_with_metadata.dta
drop if _merge == 2 // authors not in survey
drop _merge

drop if responseid == ""  // authors not in survey

***--------------------------***
// VARIABLE CREATION
***--------------------------***

// Author ever posted to SocArXiv
gen osfpub = .
	replace osfpub = 0 if osfid == ""
	replace osfpub = 1 if osfid != ""
lab var osfpub "Paper submitted to SocArXiv"
tab osfpub, m

bysort responseid: egen osfpub_ever = max(osfpub)
	tab osfpub_ever, m
	lab var osfpub_ever "Author ever posted to SocArXiv"
	lab define osfpub_ever ///
		0 "never osfpub (author level)" ///
		1 "osfpub ever (author level)"
	lab val osfpub_ever osfpub_ever
	
// Number of osfpubs per author
bysort responseid: egen osfpub_num = total(osfpub)
tab osfpub_num
lab var osfpub_num "No.SocArXiv pubs (by author)"

// Number of WoS records per author
gen wospub = .
	replace wospub = 0 if uid == ""
	replace wospub = 1 if uid != ""
	tab wospub, m
by responseid: egen wospub_num = total(wospub)
tab wospub_num, m
lab var wospub_num "No. WoS pubs (by author)"

// % of work they osfpub
gen wospub_osfposted = .
	replace wospub_osfposted = 0 if osfpub == 0 & wospub == 1
	replace wospub_osfposted = 1 if osfpub == 1 & wospub == 1
tab wospub_osfposted, m

by responseid: egen wospub_osfposted_num = total(wospub_osfposted)
lab var wospub_osfposted_num "No. WoS pubs posted on SocArXiv (by author)" 
	
gen osfpub_percent = wospub_osfposted_num / wospub_num
lab var osfpub_percent "% WoS pubs posted on SocArXiv (by author)"
sum osfpub_percent
sort osfpub_percent


// AUTHOR EVER PUBLISHED IN FEMINIST JOURNAL
tab feminist_journal, m
lab var feminist_journal "Paper submitted to feminist journal"
tab feminist_journal osfpub, m

bysort jm_auth_id: egen journal_feminist_ever = max(feminist_journal)
	tab journal_feminist_ever, m
	lab var journal_feminist_ever "Author ever published article in feminist journal"
	lab define journal_feminist_ever ///
		0 "never pub in feminist journal (author level)" ///
		1 "ever pub in feminist journal (author level)"
	lab val journal_feminist_ever journal_feminist_ever
tab journal_feminist_ever, m

***--------------------------***
// DESCRIPTIVE STATS
***--------------------------***

* count of SocArXiv papers
tab osfpub

* count of WoS papers
tab wospub

** % of total papers in WoS that come from (row name)
tab wospub author_gender_woman, m
di 151496/468088

tab wospub author_gender_man, m
di 295378/468088

tab wospub author_gender_tnb, m
di 3626/468088

** % of total submissions to SocArXiv that come from (row name)
tab osfpub author_gender_woman, m
di 692/2485

tab osfpub author_gender_man, m
di 1713/2485

tab osfpub author_gender_tnb, m
di 22/2485



***--------------------------***
// REDUCE down to AUTHOR-LEVEL
***--------------------------***

drop jm_paper_id uid osfid is_review is_oa pubyear wos_pubdate_clean pubtype doctypes n_references oa_types oa source_title date_created date_modified date_published original_publication_date likely* abstract* title_says_fem fulltext_ever_says_fem fem_added fem_removed feminist_journal cites* rank gender_and_society sjr* hindex wospub osfpub wospub_osfposted soc_journal

duplicates drop
count
isid responseid

save $clean/survey_authors.dta, replace

***--------------------------***
// DEMOGRAPHICS of AUTHORS of PAPERS published on OSF vs and WHO DOESN'T (author level)
***--------------------------***

// OUR SURVEY
tab author_gender_man, m
tab author_gender_woman, m
tab author_gender_tnb, m

di 18909/19607

// EVER SUBMIT
	
** Among those who ever osfpub, what is gender breakdown
table author_gender_man, stat(mean osfpub_ever) stat(n osfpub_ever) 
tab author_gender_man osfpub_ever, m
di 558/918

table author_gender_woman, stat(mean osfpub_ever) stat(n osfpub_ever) 
tab author_gender_woman osfpub_ever, m
di 320/918

table author_gender_tnb, stat(mean osfpub_ever) stat(n osfpub_ever) 
tab author_gender_tnb osfpub_ever, m
di 16/918

* total 
di 918/19607
	
// MEAN PUB COUNTS

** Mean (SD) SocArXiv papers by (row name) -- for all authors
table author_gender_man, stat(mean osfpub_num) stat(sd osfpub_num) stat (n osfpub_num)
table author_gender_woman, stat(mean osfpub_num) stat(sd osfpub_num) stat (n osfpub_num)
table author_gender_tnb, stat(mean osfpub_num) stat(sd osfpub_num) stat (n osfpub_num)

reg osfpub_num author_gender_woman

** Mean (SD) by gender if EVER submit
table author_gender_man if osfpub_ever == 1, stat(mean osfpub_num) stat(sd osfpub_num) stat (n osfpub_num)
table author_gender_woman if osfpub_ever == 1, stat(mean osfpub_num) stat(sd osfpub_num) stat (n osfpub_num)
table author_gender_tnb if osfpub_ever == 1, stat(mean osfpub_num) stat(sd osfpub_num) stat (n osfpub_num)

reg osfpub_num author_gender_woman if osfpub_ever == 1

** Mean (SD) number WoS papers by (row name)
table author_gender_man, stat(mean wospub_num) stat(sd wospub_num) stat (n wospub_num)
table author_gender_woman, stat(mean wospub_num) stat(sd wospub_num) stat(n wospub_num)
table author_gender_tnb, stat(mean wospub_num) stat(sd wospub_num) stat(n wospub_num)

** Is gender significant predictor of WoS / SocArXiv publication totals?
reg wospub_num author_gender_woman author_gender_tnb
reg osfpub_num author_gender_woman author_gender_tnb


// WHAT % OF WORK AUTHORS PUT ON osfpub (author level)

** % of total submissions to SocArXiv that come from (row name)
table author_gender_man, stat(mean osfpub_percent) stat(n osfpub_percent)
table author_gender_woman, stat(mean osfpub_percent) stat(n osfpub_percent)
table author_gender_tnb, stat(mean osfpub_percent) stat(n osfpub_percent)


***--------------------------***
*MODELS: for whether osfpub ever
***--------------------------***

*Base model
logit osfpub_ever author_gender_woman author_gender_tnb, or
estimates store model1

* add author-level controls
logit osfpub_ever author_gender_woman author_gender_tnb ///
	$author_level_controls ///
	, or
estimates store model2

* add author ever published in feminist journal 
logit osfpub_ever author_gender_woman author_gender_tnb ///
	$author_level_controls ///
	journal_feminist_ever ///
	, or
estimates store model3

etable, estimates(model1 model2 model3) ///
	mstat(N) mstat(r2_a) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Logistic Regression Models predicting whether author ever publishes on SocArXiv (ORs)") ///
	export($results/osf20_osfpub_ever.docx, as(docx) replace)


***--------------------------***
* MODEL: PROPORTION OF WORK PUT on SocArXiv
***--------------------------***
* fracreg logit osfpub_percent independent_variables, or
* fractional logit appropriate for DVs that can also = 0 or 1

use $clean/survey_authors.dta, clear

sum osfpub_percent, det

* Base model
fracreg logit osfpub_percent author_gender_woman author_gender_tnb ///
	, or
estimates store model1

* add author-level controls
fracreg logit osfpub_percent author_gender_woman author_gender_tnb ///
	$author_level_controls ///
	, or
estimates store model2

* add author ever published in feminist journal 
fracreg logit osfpub_percent author_gender_woman author_gender_tnb ///
	$author_level_controls ///
	journal_feminist_ever ///
	, or
estimates store model3


etable, estimates(model1 model2 model3) ///
	mstat(N) mstat(r2) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Fractional Response Logistic Regression Models predicting" ///
		  "% of published work author posts in SocArXiv") ///
	export($results/osf20_osfpub_percent_allauthors_appendix.docx, as(docx) replace)


** SAME SET of MODELS but only for those who EVER SUBMIT TO OSF
keep if osfpub_ever == 1
sum osfpub_percent, det

* Base model
fracreg logit osfpub_percent author_gender_woman author_gender_tnb ///
	, or
estimates store model1

* add author-level controls
fracreg logit osfpub_percent author_gender_woman author_gender_tnb ///
	$author_level_controls ///
	, or
estimates store model2

* add author ever published in feminist journal 
fracreg logit osfpub_percent author_gender_woman author_gender_tnb ///
	$author_level_controls ///
	journal_feminist_ever ///
	, or
estimates store model3

etable, estimates(model1 model2 model3) ///
	mstat(N) mstat(r2) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Fractional Response Logistic Regression Models predicting" ///
		  "% of published work author posts in SocArXiv," ///
		  "for those who ever submit") ///
	export($results/osf20_osfpub_percent_everosf_appendix.docx, as(docx) replace)
	

***--------------------------***
log close osf20
exit
