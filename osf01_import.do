capture log close osf01_import
log using $stata/osf01_import.smcl, name(osf01_import) replace text

//	project:	SocArXiv

//  task:     	Import

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
// IMPORT SURVEY DATA
***--------------------------***

import delimited $raw/clean_surveys_with_names.tsv, delimiter(tab) clear
do $stata/osf01a_survey_demographics.do
isid responseid
datasignature set
save $clean/survey_clean.dta, replace	
count


***--------------------------***
// IMPORT AUTHORS
***--------------------------***

*we have 34k author entries. some in the survey but not osf, others in osf but not the survey (no responseid). New unique ID for this is 'jm_auth_id' with individual IDs in the format "jmaid_" followed by numbers

import delimited $raw/authors_table.tsv, delimiter(tab) varnames(1) clear
datasignature set
save $raw/authors_table.dta, replace
isid jm_auth_id
count


***--------------------------***
// IMPORT PAPERS
***--------------------------***

import delimited $raw/papers_table_with_metadata.tsv, ///
	delimiter(tab) varnames(1) clear
rename v47 cites_5y
rename y_cites cites_2y
rename all_cites cites_all
datasignature set
save $raw/papers_table_with_metadata.dta, replace
isid jm_paper_id
count


***--------------------------***
// IMPORT PAPER-AUTHORS CROSSWALK
***--------------------------***

import delimited $raw/papers_authors_crosswalk.tsv, ///
	delimiter(tab) varnames(1) clear
datasignature set
save $raw/papers_authors_crosswalk.dta, replace
isid jm_paper_id jm_auth_id
count


***--------------------------***
log close osf01_import
exit
