capture log close osf10
log using $stata/osf10_paper_outcomes.smcl, name(osf10) replace text

//	project:	SocArXiv

//  task:		Feminist Science: Paper Outcomes
//				Merge Survey + WoS + OSF

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
// MERGE DATA
***--------------------------***

use $raw/authors_table.dta, clear
drop if responseid == ""

merge 1:1 responseid using $clean/survey_clean.dta
drop if _merge == 2
drop _merge

merge 1:m jm_auth_id using $raw/papers_authors_crosswalk.dta
drop if _merge == 2 // authors not in survey
drop _merge

merge m:1 jm_paper_id using $raw/papers_table_with_metadata.dta
drop if _merge == 2 // authors not in survey
drop _merge

// create group id based on responseid (string)
egen responseid_n = group(responseid)
xtset responseid_n

save $clean/survey_authors_papers.dta, replace

***--------------------------***
// VARIABLE CREATION
***--------------------------***

// AUTHOR posted paper to SocArXiv
gen osfpub = .
	replace osfpub = 0 if osfid == ""
	replace osfpub = 1 if osfid != ""
lab var osfpub "Paper submitted to SocArXiv"
tab osfpub, m

// AUTHOR published paper in WoS
gen wospub = .
	replace wospub = 0 if uid == ""
	replace wospub = 1 if uid != ""
lab var wospub "Paper published in WoS"
tab wospub, m

// OSF DATE CREATED VARIABLE
split date_created, gen(osfpub_created) parse("-"":"" ")
rename osfpub_created1 osfpub_created_year 
rename osfpub_created2 osfpub_created_month
drop osfpub_created3 osfpub_created4 osfpub_created5
destring osfpub_created_year, replace
lab var osfpub_created_year "OSF created year"
lab var osfpub_created_month "OSF created month"
destring  osfpub_created_month, replace

gen osfpub_yearmonth = ym(osfpub_created_year, osfpub_created_month)
lab var  osfpub_yearmonth "Stata format OSF year-month"

// WoS PUBLICATION DATE VARIABLE
split wos_pubdate_clean, gen(wospub) parse("-")
rename wospub1 wospub_year
rename wospub2 wospub_month
drop wospub3
destring wospub_year, replace
destring wospub_month, replace
lab var wospub_year "WoS publciation year"
lab var wospub_month "WoS publciation month"

gen wospub_yearmonth = ym(wospub_year, wospub_month)
lab var wospub_yearmonth "Stata format WoS year-month"

// TIME from to SocArXiv SUBMISSION to WoS PUBLICATION
generate months_wospub_osfpub =  osfpub_yearmonth - wospub_yearmonth
lab var months_wospub_osfpub "Months OSF submit - WoS pub (+ osf posted after pub; - osf preprint before pub)"
generate years_wospub_osfpub = months_wospub_osfpub / 12
lab var years_wospub_osfpub "Years OSF submit - WoS pub (+ osf posted after pub; - osf preprint before pub)"
order years_wospub_osfpub months_wospub_osfpub wospub_yearmonth osfpub_yearmonth 
tab years_wospub_osfpub

// YEARS PHD to PUBLICATION
gen years_wospub_phd = .
	replace years_wospub_phd = pubyear - phd_year
lab var years_wospub_phd "Years after PhD published in WoS"
tab years_wospub_phd
hist years_wospub_phd

// YEARS PHD to SocArXiv SUBMISSION
tab phd_year
tab pubyear

gen years_osfpub_phd = .
	replace years_osfpub_phd = osfpub_created_year - phd_year
	replace years_osfpub_phd = . if osfpub_created_year == .
lab var years_osfpub_phd "Years since PhD to SocArXiv submission"
tab years_osfpub_phd
hist years_osfpub_phd


// PAPER PREPRINTed BEFORE WoS PUBLICATION 
gen preprint = .
	replace preprint = 1 if osfpub_yearmonth < wospub_yearmonth
	replace preprint = 0 if osfpub_yearmonth >= wospub_yearmonth & osfpub_yearmonth != .
lab var preprint "Submitted to SocArXiv before published in WoS"

// OPEN PUBLISHING BEHAVIOR
tab is_oa, m
gen open_pub = .
	replace open_pub = 0 if is_oa == ""
	replace open_pub = 1 if is_oa == "Yes"
	replace open_pub = 1 if osfid != ""
tab is_oa, m
	
// GREEN vs all
gen is_green = 0
replace is_green = 1 if ///
	ustrpos(oa_types, "green_submitted") > 0 | ///
	ustrpos(oa_types, "green_accepted") > 0 | ///
	ustrpos(oa_types, "green_published") > 0
replace is_green = 1 if osfid != ""
tab is_green, m

// GREEN OA or OSF
gen open_green = .
replace open_green = 0 if is_oa == "Yes"
replace open_green = 1 if ///
	ustrpos(oa_types, "green_submitted") > 0 | ///
	ustrpos(oa_types, "green_accepted") > 0 | ///
	ustrpos(oa_types, "green_published") > 0
replace open_green = 1 if osfid != ""

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
	
save $clean/survey_authors_papers.dta, replace

***--------------------------***
// Paper submitted to OSF or not
***--------------------------***

// MIXED EFFECTS Model of OSF Publishing 

*Base model
melogit osfpub author_gender_woman author_gender_tnb ///
	|| responseid_n: , or
estimates store model1

* add paper-level controls
melogit osfpub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	|| responseid_n: , or
estimates store model2

* add author-level controls
melogit osfpub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: , or
estimates store model3

* add paper published in feminist journal 
melogit osfpub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal ///
	|| responseid_n: , or
estimates store model4

// Paper submitted to OSF or not - interaction with career stage and gender
* add other paper-level controls
melogit osfpub author_gender_woman##c.years_wospub_phd author_gender_tnb ///
	$paper_level_controls ///
	|| responseid_n: , or
estimates store model2_int

* add author-level controls
melogit osfpub author_gender_woman##c.years_wospub_phd author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: , or
estimates store model3_int

* put models in a table
etable, estimates(model1 model2 model3 model4 model2_int model3_int) ///
	mstat(N) mstat(r2_a) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Mixed Effects Logistic Regression predicting SocArXiv submission" "(ORs)") ///
	export($results/osf10_osfpublish_melogit.docx, as(docx) replace)


* Hypothesis: "papers by junior men are more likely to be posted on SocArXiv."
margins author_gender_woman, at(years_wospub_phd=(-10(1)50)) atmeans
marginsplot, ///
	title("Predictive margins of posting a manuscript on SocArXiv by author gender" ///
		"by years pre- or post-PhD of manuscript publication date") ///
	xtitle("Years before (-) or after (+) PhD paper published in WoS") ///
	ytitle("Predicted probability of manuscript being posted on SocArXiv")  ///
	legend(label(1 "Not woman author" label(2 "Woman author"))) /// 
	recastci(rarea) // treat plot as rarea
graph export $results/osf10_osfpublish_careerstage_melogit.jpg, ///
	as(jpg) name("Graph") quality(90)  replace

tab feminist_journal osfpub, m
	
***--------------------------***
// General open behavior (pub in open journal OR OSF)
***--------------------------***

// MODEL: ALL OA BEHAVIOR

tab open_pub, m

*Base model
melogit open_pub author_gender_woman author_gender_tnb ///
	|| responseid_n: , or
estimates store model1

* add paper-level controls: 
melogit open_pub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	|| responseid_n: , or
estimates store model2

* add author-level controls:
melogit open_pub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: , or
estimates store model3

* add paper published in feminist journal 
melogit open_pub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal ///
	|| responseid_n: , or
estimates store model4

etable, estimates(model1 model2 model3 model4) ///
	mstat(N) mstat(r2_a) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Mixed Effects Logistic Regression predicting OA journal + SocArXiv (ORs)") ///
	export($results/osf10_oa.docx, as(docx) replace)


// MODEL: GREEN OA
	
tab open_green, m 	
	
* Base model
melogit open_green author_gender_woman author_gender_tnb  ///
	|| responseid_n: , or
estimates store model1

* add paper-level controls
melogit open_green author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	|| responseid_n: , or
estimates store model2

* add author-level controls
melogit open_green author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: , or
estimates store model3

* add paper published in feminist journal 
melogit open_green author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal ///
	|| responseid_n: , or
estimates store model4

etable, estimates(model1 model2 model3 model4) ///
	mstat(N) mstat(r2_a) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Mixed Effects Logistic Regression predicting green OA + SocArXiv (ORs)") ///
	export($results/osf10_oagreen_appendix.docx, as(docx) replace)

	
* green compared to all papers
melogit is_green author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal ///
	|| responseid_n: , or

	
* green compared to all papers
melogit is_green author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal#author_gender_woman ///
	|| responseid_n: , or

* get count for footnote
keep if osfpub == 1 & feminist_journal == 1
count
	
***--------------------------***
// Preprint / postprint
***--------------------------***

use $clean/survey_authors_papers.dta, clear

*Base model
melogit preprint author_gender_woman author_gender_tnb ///
	|| responseid_n: , or
estimates store model1

* add paper-level controls
melogit preprint author_gender_woman author_gender_tnb ///
	$paper_level_controls  ///
	|| responseid_n:  , or
estimates store model2

* add author-level controls
melogit preprint author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: , or
estimates store model3

* add paper published in feminist journal 
melogit open_pub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal ///
	|| responseid_n: , or
estimates store model4

// Preprint / postprint - Whether interaction with career stage and gender
* add other paper-level controls
melogit preprint author_gender_woman##c.years_wospub_phd author_gender_tnb ///
	$paper_level_controls  ///
	|| responseid_n: , or
estimates store model2cs_int

* add author-level controls: org status, race, profile claimed
melogit preprint author_gender_woman##c.years_wospub_phd author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: , or
estimates store model3cs_int

etable, estimates(model1 model2 model3 model4 model2cs_int model3cs_int) ///
	mstat(N) mstat(r2_a) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Mixed Effects Logistic Regression predicting paper preprint (ORs)") ///
	export($results/osf10_preprint.docx, as(docx) replace)


***--------------------------***
// Years between OSF submission and publication
***--------------------------***
* Proxy for quality: Shorter time to publication (only works in field where everyone preprints everything like CS) - also speaks to confidence
* coef negative: reduces number of years from preprint to publication

des years_wospub_osfpub, det
hist years_wospub_osfpub, by(author_gender_wtnb, cols(1))

*Base model
mixed years_wospub_osfpub author_gender_woman author_gender_tnb ///
	|| responseid_n:
estimates store model1

* add paper-level controls
mixed years_wospub_osfpub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	|| responseid_n: 
estimates store model2

* add author-level controls
mixed years_wospub_osfpub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	|| responseid_n: 
estimates store model3

* add paper published in feminist journal 
mixed years_wospub_osfpub author_gender_woman author_gender_tnb ///
	$paper_level_controls ///
	$author_level_controls ///
	feminist_journal ///
	|| responseid_n: 
estimates store model4

etable, estimates(model1 model2 model3 model4) ///
	mstat(N) mstat(r2) column(index) ///
	showstars showstarsnote stars(.05 "*" .01 "**" .001 "***", attach(_r_b)) ///
	title("Mixed-Effects Linear Regression Models" ///
		"predicting time from OSF to WoS publication (neg. coef --> shorter)") ///
	export($results/osf10_time_osf_to_wos.docx, as(docx) replace)
	
	
***--------------------------***
log close osf10
exit
