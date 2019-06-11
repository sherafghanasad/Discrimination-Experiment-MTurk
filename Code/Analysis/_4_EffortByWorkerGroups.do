/* 
This file calculates effort choices by worker's racial groups for each treatment. 

Input: 
	Cleaned Data
Output:
	Table 4: EffortByWorkerGroup
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_4_EffortByWorkerGroups_`c(current_date)'", replace

use 	"${outdir}\CleanedData", clear

* Effort by the identity of worker in the Race Salient treatment

keep 		if Treatment == "Race Salient"
tostring 	PieceRate, gen(PR)
replace 	PR = "0.00" if PR == "0"
replace 	PR = "0.03" if PR == ".03"
replace 	PR = "0.06" if PR == ".06"
replace 	PR = "0.09" if PR == ".09"

eststo clear

eststo estBB, title(Black-Black): estpost tabstat Points if Role == 2 & Race == "Black or African-American" & EmployerRace == "Black or African-American", statistics(count mean sd semean) by(PR) 
eststo estBW, title(Black-White): estpost tabstat Points if Role == 2 & Race == "Black or African-American" & EmployerRace == "White or Caucasian", statistics(count mean sd semean) by(PR) 

eststo estWB, title(White-Black): estpost tabstat Points if Role == 2 & Race == "White or Caucasian" & EmployerRace == "Black or African-American", statistics(count mean sd semean) by(PR) 
eststo estWW, title(White-White): estpost tabstat Points if Role == 2 & Race == "White or Caucasian" & EmployerRace == "White or Caucasian", statistics(count mean sd semean) by(PR)

#d ;  
esttab 	estWW estBW estWB  estBB using "${outdir}\EffortByWorkerGroup.tex", 
		label mtitles
		cells("count(fmt(0) label(N\?))  mean(fmt(2) label(Mean (s.e)\?))" "b(label(\hspace{0.01cm})) semean(fmt(2) par label(\hspace{0.01cm}))")
		noobs
		coeflabels(1 "0.00" 2 "0.03" 3 "0.06" 4 "0.09")
		nostar gaps
		width(\hsize)
		replace
		;
#d cr
