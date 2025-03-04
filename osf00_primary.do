cd "~/Documents/SocResearch/SocArXiv_gender/stata/"

capture log close primary
log using "osf00_primary.smcl", name(primary) replace text

set more off

** Primary SocArXiv Project Do File ***
 
//	project:	SocArXiv Gender

//  task:		Primary file
//				This will run all files in folder: SocArXiv_gender

//  github:		SocArXiv_gender

//  author:		Molly King 

display "$S_DATE  $S_TIME"


***--------------------------***

// CHANGE DIRECTORIES to local files to run replication code:

global arxg  	"~/Documents/SocResearch/SocArXiv_gender"		
global stata  	"~/Documents/SocResearch/SocArXiv_gender/stata"
global results  "~/Documents/SocResearch/SocArXiv_gender/results"		

*Data
global raw		"~/Documents/SocResearch/SocArXiv_gender/data/raw_data"
global clean	"~/Documents/SocResearch/SocArXiv_gender/data/clean_data"
global temp		"~/Documents/SocResearch/SocArXiv_gender/data/temp_data"


* Paper-level Controls for Models: year of journalpub, career stage
global paper_level_controls  "pubyear c.years_wospub_phd" 

* Author-level Controls for Models: race
global author_level_controls "race_black race_other_asian race_chinese race_indian race_mena race_latine race_other_new"

***--------------------------***

// SETUP, MERGE, & VARIABLE CREATION
do $stata/osf01_import.do 						// Import and merge data

// ANALYSES
do $stata/osf10_paper_outcomes.do 				// Science: Paper Outcomes [paper-author-level]
do $stata/osf20_author_outcomes.do 				// Careers: Author Outcomes [author-level]
do $stata/osf40_results_intro.do 				// Basic Descriptive Stats

***--------------------------***

log close primary
exit
