/* 
This file summarize the treatment effects for the paper. 

Input: 
	Cleaned Data
Output:
	Table 2: Effort choices by treatment
	Table 3: OLS Regression results for effort
	Figure 1: Piece rate and effort
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_3_TreatmentEffects_`c(current_date)'", replace

use 	"${outdir}\CleanedData", clear


* Effort against different piece rates

eststo clear
eststo estBaseline, title(Baseline): estpost tabstat Points if Role == 2 & Treatment == "Baseline", statistics(count mean sd semean) by(PieceRate) 

eststo estBlack, title(Black Employer): estpost tabstat Points if Role == 2 & Treatment == "Race Salient" & EmployerRace == "Black or African-American", statistics(count mean sd semean) by(PieceRate) 
eststo estWhite, title(White Employer): estpost tabstat Points if Role == 2 & Treatment == "Race Salient" & EmployerRace == "White or Caucasian", statistics(count mean sd semean) by(PieceRate) 

#d ;  
esttab 	estBaseline estBlack estWhite using "${outdir}\EffortByTreatments.tex", 
		label mtitles
		cells("count(fmt(0) label(N\?))  mean(fmt(2) label(Mean (s.e)\?))" "b(label(\hspace{0.01cm})) semean(fmt(2) par label(\hspace{0.01cm}))")
		noobs
		coeflabels(1 "0.00" 2 "0.03" 3 "0.06" 4 "0.09")
		nostar gaps
		width(\hsize)
		replace
		;
#d cr


* Figure of incentive effect by treatment

#d ;
twoway 	(fpfit Points PieceRate if Treatment == "Baseline") 
		(fpfit Points PieceRate if Treatment == "Race Salient" & 
		EmployerRace == "Black or African-American") 
		(fpfit Points PieceRate if Treatment == "Race Salient" & 
		EmployerRace == "White or Caucasian"), 
		ytitle(Points Scored) xtitle(Piece Rate (in cents)) 
		title("Incentive effect by treatment") 
		legend(order(1 "Baseline" 2 "Black Employers" 3 "White Employers"))
		graphregion(color(white)) 
		;
#d cr	

graph 	export "${outdir}\IncentiveEffectByTreatment.png", replace
	

* Treatment Effect Regression

encode 	Treatment, gen(Treat)
gen 	lPoints = ln(Points)
gen 	lPieceRate = ln(PieceRate + 1)
gen 	Fair = (PieceRate >= FairPieceRate)
gen 	Fair1 = (PieceRate == FairPieceRate)
encode 	EmployerRace, gen(EmpRace)
label 	def EmpRace 1 "Black Employer" 2 "White Employer", replace
	
eststo 	clear

eststo 	estTE, 		title(Model 1): reg 	lPoints lPieceRate ib2.Treat if Role == 2
eststo 	estTEInt, 	title(Model 2): reg 	lPoints lPieceRate ib2.Treat ib2.Treat#b2.EmpRace  if Role == 2
eststo 	estTEFair, 	title(Model 3): reg 	lPoints lPieceRate ib2.Treat ib2.Treat#b2.EmpRace Fair  if Role ==2
eststo 	estTEFE, 	title(Model 4): reg 	lPoints lPieceRate ib2.Treat ib2.Treat#ib2.EmpRace Fair Female Education2-Education6 Race1 Age2-Age6 if Role ==2

label 	var lPieceRate "Piece Rate"

#d ;  
esttab 	estTE estTEInt estTEFair estTEFE using "${outdir}\TreatmentEffect.tex", 
		drop(2.Treat 1.Treat#1.EmpRace 2.Treat#2.EmpRace )
		indicate(Fixed Effects = Female Education2 Education3 Education4 Education5 Race1 Age2 Age3 Age4 Age5 Age6)
		label mtitles 
		main() b(2) 
		p
		noomitted
		gap
		width(\hsize)
		replace
		;
#d cr
