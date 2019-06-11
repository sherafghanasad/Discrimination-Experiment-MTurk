/* 
This file creates figures and tables for appendix. 

Input: 
	Cleaned Data
Output:
	Figure 
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_5_Miscellaneous_`c(current_date)'", replace

use 	"${outdir}\CleanedData", clear

* Distribution of points scored

histogram Points if Role ==1, width(25) start(0) xtitle("Points") ytitle("Frequency") ///
		freq title("Distribution of Points - All Treatments") graphregion(color(white)) lcolor(black) fcolor(black) ///
		xlabel(0(500)4000) xmtick(0(100)4000,grid) gap(75) ylabel(,nogrid)
graph 	export "${outdir}\PointsDist.png", replace

* Variation in piece rates

#d ;
graph 	bar (count) if Role == 1, 
		over(PieceRate) over(Race)
		ytitle(Frequency) 
		title("Piece-Rate Distribution") 
		note("Note: This graph represents the distribution of piece rates (in dollars per 100 points) as selected" "by Black and White Employers. ", 
		margin(zero)) 
		graphregion(color(white))
		;
#d cr
		
graph 	export "${outdir}\PieceRateDistribution.png", replace
		
* CDF of Effort by piece rate

gen	 		PR = 0 	if 		PieceRate == 0
replace 		PR = 3 	if 		PieceRate == 0.03
replace 		PR = 6 	if 		PieceRate == 0.06
replace 		PR = 9 	if 		PieceRate == 0.09

gen 			RowID = _n

levelsof PR, local(PR)

foreach p of local PR {
	preserve
		keep 	if PR == `p'
		cumul 	Points,  generate(cdfPoints`p') 
*		twoway (connected cdfPoints Points, sort msymbol(none)) 
*		graph 	export "${outdir}\CDF`p'", replace
		save 		"${tempdir}\Points`p'.dta", replace
	restore
	merge 		1:1 RowID using "${tempdir}\Points`p'.dta",  keepusing(cdfPoints`p') nogen
	}
	
#d ;
twoway 	(connected cdfPoints0 Points, sort msymbol(none)) 
				(connected cdfPoints3 Points, sort msymbol(none)) 
				(connected cdfPoints6 Points, sort msymbol(none)) 
				(connected cdfPoints9 Points, sort msymbol(none)), 
				ytitle(Cumulative Fraction) 
				xtitle(Points scored) 
				legend(order(1 "0 cents for 100" 2 "3 cents for 100"  3 "6 cents for 100" 4 "9 cents for 100"))	
				graphregion(color(white))
				;
#d cr

graph 	export "${outdir}\PieceRateCDFs.png", replace
