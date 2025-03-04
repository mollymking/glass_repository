
***--------------------------***
// GENDER
***--------------------------***

rename gender_man author_gender_man
label var author_gender_man "Author gender man=1 not=0"
label define author_gender_man 0 "Not man" 1 "Man"
label val author_gender_man author_gender_man

rename gender_woman author_gender_woman
label var author_gender_woman "Author woman"
label define author_gender_woman 0 "Not woman" 1 "Woman"
lab val author_gender_woman author_gender_woman

rename gender_nb author_gender_nb
label var author_gender_nb "Author nonbinary=1 binary=0"
label define author_gender_nb 0 "Not nonbinary" 1 "Nonbinary"  
lab var author_gender_nb author_gender_nb

gen author_gender_tnb = .
	replace author_gender_tnb = 0 if author_gender_man == 1
	replace author_gender_tnb = 0 if author_gender_woman == 1
	replace author_gender_tnb = 1 if author_gender_nb == 1 | trans == 1	
tab author_gender_tnb trans, m
tab author_gender_tnb author_gender_nb, m
label var author_gender_tnb "Author trans/nonbinary" 
label define author_gender_tnb 0 "trans/nonbinary" 1 "cis/binary"
lab var author_gender_nb author_gender_tnb

gen author_gender_wtnb = .
	replace author_gender_wtnb = 0 if author_gender_man == 1
	replace author_gender_wtnb = 1 if author_gender_woman == 1
	replace author_gender_wtnb = 1 if author_gender_nb == 1 | trans == 1
label var author_gender_wtnb "Author woman/trans/nonbinary	= 1" 
label define author_gender_wtnb 0 "man" 1 "woman/trans/nonbinary"
label var author_gender_wtnb author_gender_wtnb


count


***--------------------------***
// RACE
***--------------------------***

tab race_puerto_rican
tab race_cuban
tab race_salvadoran
tab race_dominican
tab race_guatemalan
tab race_columbian
tab race_filipino
tab race_korean
tab race_vietnamese

* racial categories for groups with 500+
gen race_other_asian = 0
replace race_other_asian = 1 if race_asian == 1 & race_chinese == 0 & race_indian == 0

clonevar race_other_new = race_other
	replace race_other_new = 1 if race_aian == 1
	replace race_other_new = 1 if race_nhpi == 1
	
tab race_black 
label var race_black "Black or African American" 

tab race_other_asian 
label var race_other_asian "Other Asian" 

tab race_chinese
lab var race_chinese "Chinese"

tab race_indian
lab var race_indian "Indian"

tab race_mena
lab var race_mena "Middle Eastern or North African"

tab race_latine
label var race_latine "Hispanic, Spanish, or Latina/o/x"

tab race_other_new
lab var race_other_new "Other Race / American Indian / Alaska Native or Native Hawiian / Pacific Islander"



***--------------------------***
// SELF-ID DISCIPLINE
***--------------------------***
tab discipline
encode discipline, generate(author_discipline_num)
tab author_discipline_num
tab author_discipline_num, nolab m
lab var author_discipline "Self-ID disc. (econ, or soc)"
rename author_discipline_num author_discipline

gen author_soc = 0
replace author_soc = . if author_discipline == .
replace author_soc = 1 if author_discipline == 16
lab var author_soc "Author discipline sociology"

tab author_soc author_discipline, m

gen author_econ = 0
replace author_econ = . if author_discipline == .
replace author_econ = 1 if author_discipline == 5
lab var author_econ "Author discipline economics"

gen author_comm = 0
replace author_comm = . if author_discipline == .
replace author_comm = 1 if author_discipline == 3
lab var author_comm "Author discipline communication"

*variable to indicate not soc/econ
tab author_discipline, m
gen author_disc_other = 0
replace author_disc_other = . if author_discipline == .
replace author_disc_other = 1 if author_discipline != 16 & author_discipline != 5 
lab var author_disc_other "Binary indicator that author not in econ, soc"
tab author_discipline author_disc_other, m

