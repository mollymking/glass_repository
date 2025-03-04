capture log close osf40
log using $stata/osf40_results_intro.smcl, name(osf40) replace text

//	project:	SocArXiv

//  task:		Results Intro

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

use  $raw/papers_authors_crosswalk.dta, clear
*drop if _merge == 2 // authors not in survey

merge m:1 jm_paper_id using $raw/papers_table_with_metadata.dta
drop _merge

save $clean/papers_auths.dta, replace


***--------------------------***
// SUBMISSIONS to SocArXiv
***--------------------------***

* Number of unique authors
use $clean/papers_auths.dta
keep if osfid != ""
keep jm_paper_id jm_auth_id osfid
duplicates drop jm_auth_id, force
count

* Number of unique OSF manuscripts
use $clean/papers_auths.dta, clear
keep if osfid != ""
keep jm_paper_id jm_auth_id osfid
duplicates drop jm_paper_id, force
count

* Number of unique WoS publications
use $clean/survey_authors_papers.dta, clear
* dataset from osf10 that includes survey
keep if responseid != ""
keep uid
duplicates drop
count 

* Number of unique OSF pubs
use $clean/survey_authors_papers.dta, clear
keep if responseid != ""
keep osfid
duplicates drop
count

