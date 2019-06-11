/* 
This file analyses effort choices and fairness perceptions in all the data. 

Input: 
	Cleaned Data
Output:
	Figure 2: Chosen piece rate vs. fair piece rate
	Figure 3: Fairness Perception
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_5_FairnessAndEffort_`c(current_date)'", replace

use 	"${outdir}\CleanedData", clear


preserve

	bysort 	PieceRate: egen PR = count(PieceRate)
	
	bysort 		FairPieceRate: egen FPRCount = count(FairPieceRate)
	gen 		FPR = FPRCount if (PieceRate == FairPieceRate)
	bysort 		PieceRate (FPR): replace FPR = FPR[1]
	replace		FPR = 2 if PieceRate == 0
	keep 		PieceRate PR FPR
	duplicates	drop

	egen 		PRPer = pc(PR)
	egen 		FPRPer = pc(FPR)	

	#d ;
	graph 	bar (asis) 
		PRPer FPRPer, 
		over(PieceRate) 
		ytitle(Percentage) 
		title("Distribution of selected and fair piece rate") 
		legend(order(1 "Chosen Piece Rate" 2 "Fair Piece Rate"))
		graphregion(color(white)) 
		;
	#d cr	
	
	graph 	export "${outdir}\ChosenAndFairRate.png", replace

restore

		
#d ;
graph 	bar (mean) Fair 
		if Role == 2, 
		over(PieceRate) 
		ytitle(Fraction of workers who perceived the rate as fair) 
		title("Fairness Perception")
		graphregion(color(white)) 
		;
#d cr

graph 	export "${outdir}\FairnessPerception.png", replace
