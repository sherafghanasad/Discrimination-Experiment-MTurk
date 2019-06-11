/* 
This file summarize the demographic data for the paper. 

Input: 
	Cleaned Data
Output:
	Table 1: Demogrphics
	Figure 1: Demographics
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_2_SummarizeDemographicData_`c(current_date)'", replace

use 	"${outdir}\CleanedData", clear

* Demographics of Subjects

#d ;
graph 	bar 
		(mean) Male 
		(mean) Female, 
		over(Race) 
		ytitle(Percentage) 
		title("Overall Gender Distribution") 
		note("Note: This graph represents the gender distribution of subjects by racial groups.") 
		legend(order(1 "Male" 2 "Female")) 
		scheme(s2mono)
		saving("${outdir}\Gender", replace)
		;
#d cr

*drop 	Male Female

/*
#d ;
graph 	bar (mean), 
		over(Male) over(Race) 
		asyvars  
		title("Gender Distribution") 
		note("Note: This graph represents the gender distribution of subjects by racial groups.",margin(zero)) 
		
		;
#d cr		

graph 	export "${outdir}\GenderDistribution$S_DATE.png", replace
*/

* Age


#d ;
graph 	bar 
		(mean) Age1 
		(mean) Age2
		(mean) Age3 
		(mean) Age4
		(mean) Age5 
		(mean) Age6		, 
		over(Race) 
		ytitle(Percentage) 
		title("Overall Age Distribution") 
		note("Note: This graph represents the age distribution of subjects by racial groups.") 
		legend(order(1 "18-24" 2 "25-30" 3 "31-40" 4 "41-50" 5 "51-60" 6 "65 or over")) 
		scheme(s2mono)
		saving("${outdir}\Age", replace)
		;
#d cr

/*
#d ;
graph 	bar (count), 
		over(Age) over(Race) 
		asyvars  
		title("Age Distribution") 
		note("Note: This graph represents the age distribution of subjects by racial groups.",margin(zero)) 
		;
#d cr		

graph 	export "${outdir}\AgeDistribution$S_DATE.png", replace
*/

* Education

#d ;
graph 	bar 
		(mean) Education1 
		(mean) Education2
		(mean) Education3 
		(mean) Education4
		(mean) Education5 
		(mean) Education6, 
		over(Race) 
		ytitle(Percentage) 
		title("Overall Education Distribution") 
		note("Note: This graph represents the education distribution of subjects by racial groups.") 
		legend(order(1 "Less than high school" 2 "High school or equivalent" 3 "Some college" 4 "College Graduate" 5 "Master's Degree" 6 "Doctoral Degree")) 
		scheme(s2mono)
		saving("${outdir}\Education", replace)
		;
#d cr

/*
#d ;
graph 	bar (count), 
		over(Education) over(Race) 
		asyvars  
		title("Education Distribution") 
		note("Note: This graph represents the education distribution of subjects by racial groups.",margin(zero)) 
		;
#d cr		

graph 	export "${outdir}\EducationDistribution$S_DATE.png", replace
*/

#d ;
graph 	combine 
		"${outdir}\Gender" "${outdir}\Age" "${outdir}\Education", 
		title(Demographics of Overall Sample) 
		iscale(*0.69) saving("${outdir}\Demographics.png", replace)
		;
#d cr		

graph 	export "${outdir}\Demographics.png", replace

*drop 	Age? Education?

* Generate a table of demographic information

foreach var of varlist Male Female Age1-Age6 Education1-Education6 {
	replace `var' = `var'/100
}

label 	var Male "\hspace{0.5cm}Male"
label 	var Female "\hspace{0.5cm}Female"

label 	var Age1 "\hspace{0.5cm}18-24"
label 	var Age2 "\hspace{0.5cm}25-30"
label 	var Age3 "\hspace{0.5cm}31-40"
label 	var Age4 "\hspace{0.5cm}41-50"
label 	var Age5 "\hspace{0.5cm}51-64"
label 	var Age6 "\hspace{0.5cm}65 and over"

label 	var Education1 "\hspace{0.5cm}Less than high school"
label 	var Education2 "\hspace{0.5cm}High school or equivalent"
label 	var Education3 "\hspace{0.5cm}Some college"
label 	var Education4 "\hspace{0.5cm}College graduate"
label 	var Education5 "\hspace{0.5cm}Master's degree"
label 	var Education6 "\hspace{0.5cm}Doctoral degree"

label 	var Race1 "\hspace{0.5cm}Black or African American"
label 	var Race2 "\hspace{0.5cm}White or Caucasian"

eststo 	clear

eststo estBlacks, title(Blacks): estpost sum Male Female Race1 Race2 Age1-Age6 Education1-Education6 if Race == "Black or African-American"
eststo estWhites, title(Whites): estpost sum Male Female Race1 Race2 Age1-Age6 Education1-Education6 if Race == "White or Caucasian"

eststo estAll, title("All Subjects"): estpost sum Male Female Race1 Race2 Age1-Age6 Education1-Education6

eststo estWorkers, title(Workers): estpost sum Male Female Race1 Race2 Age1-Age6 Education1-Education6 if Role == 2
eststo estEmployers, title(Employers): estpost sum Male Female Race1 Race2 Age1-Age6 Education1-Education6 if Role == 1

#d ;  
esttab 	estAll estBlacks estWhites estEmployers estWorkers using "${outdir}\Demographic.tex", 
		label mtitles 
		main(mean) b(2) 
		nostar nonote nogap
		width(\hsize)
		refcat(Male "Gender" Race1 "Race" Age1 "Age" Education1 "Education",nolabel)
		replace
		;
#d cr
