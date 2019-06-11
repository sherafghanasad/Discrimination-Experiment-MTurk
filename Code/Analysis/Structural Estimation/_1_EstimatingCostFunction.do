/* 
This file estimate the parameters of cost function using minimum distance 
estimation. 
Input: 
	Individual level raw data
Output:
	Table with paramter values
	
Written by: Sher Afghan Asad
Date: 2018-08-06
	
*/	

clear 		all
set			more off
capture		log close

/* If you want to run this on your system, add your path here. */

if						"`c(username)'" == "asads"		{
						global		rootdir "C:\Users\asads\Dropbox\Discrimination\Intensive Margin"
			}
else		if 			"`c(username)'" == "SherAfghan"	{
						global		rootdir		"C:\Users\SherAfghan\Dropbox\Discrimination\Intensive Margin"
			}
			
global		codedir		"${rootdir}\Code\Analysis\Structural Estimation"
global		rawdatadir	"${rootdir}\Input\Raw Data"
global		outdir		"${rootdir}\Output\Analysis\Structural Estimation"
global		tempdir		"${rootdir}\Temp\Analysis\Structural Estimation"
global		writingdir	"${rootdir}\Documentation\Analysis\Structural Estimation"

log			using 		"${writingdir}\Structural Estimation_`c(current_date)'", replace

* Set some parameters

set 		seed 123
local 	draws = 1000

* Import cleaned data from experiment

use 		"${rootdir}\Output\Analysis\CleanedData.dta", clear

* Since each observation appear twice (once for each participant), we drop the employer observations

keep 		if Role == 2

* For parameters of cost function we only use data from baseline treatment 

keep 	if Treatment == "Baseline"
*drop 	Treatment

*sort 	PieceRate Points

replace 	PieceRate = 3 if PieceRate == 0.03
replace 	PieceRate = 6 if PieceRate == 0.06
replace 	PieceRate = 9 if PieceRate == 0.09

save 		"${tempdir}\BaselineData", replace

* Draw a bootstrap sample of 1000 means of observations for each piece rate

clear
set 	obs `draws'
foreach x of numlist 0 3 6 9 {
	gen Points`x' = 0
	}
count

forvalues i = 1/`r(N)' {
		foreach x of numlist 0 3 6 9 {
			preserve
				use 		"${tempdir}\BaselineData", clear
				quietly 	count 		if PieceRate == `x'
					
				quietly 	bsample 	`r(N)' if PieceRate == `x'
				quietly 	summ Points
				quietly 	local 		mean`x' = `r(mean)'
			restore	
			
			quietly 		replace Points`x' = round(`mean`x'') in `i'	
		}		
}

save 	"${tempdir}\BootstrapSample", replace

* Solving the equations for parameter values

gen 	G = .
gen 	S = .
gen 	K = .
	
capture program drop nlcostsolver
program nlcostsolver
	syntax 		varlist(min=1 max=1) [if], at(name)

	tempname 	G S K
	scalar 		`G' = `at'[1,1]
	scalar 		`S' = `at'[1,2]
	scalar 		`K' = `at'[1,3]
	
	tempvar 	yh
	gen 		double `yh' = `G'*log($e0) - log(`S'+0) + log(`K') + 1 in 1
	replace 	`yh' = `G'*log($e3) - log(`S'+0.03) + log(`K') in 2
	replace 	`yh' = `G'*log($e9) - log(`S'+0.09) + log(`K') in 3

	replace 	`varlist' = `yh'	
	
end	

forvalues i = 1/`draws' {
	dis 		"Solving equation `i' " 
	global 	e0 = Points0[`i']
	global 	e3 = Points3[`i']
	global 	e9 = Points9[`i']

	scalar 		k = exp((log(0.09) - ((log(0.03)*log(${e9}))/log(${e3}))) / (1 - (log(${e9})/log(${e3}))))
	
	if k == 0 | k == . {
	scalar 		k = exp((log(0.10) - ((log(0.01)*log(2175))/log(2029))) / (1 - (log(2175)/log(2029))))
	}
	
	scalar 		gamma = (log(0.03) - log(k))/log(${e3})
	scalar 		s = exp(gamma*log(${e0}) + log(k))

	preserve
		clear

		quietly 	set 		obs 3
		quietly 	generate 	y = 0
		quietly 	replace 	y = 1 in 1

		quietly nl costsolver @ y, parameters(G S K) initial(G gamma S s K k) eps(0.5e-3)  nolog
	restore
		
	quietly replace G 			= 	[G]_b[_cons] 	in `i'
	quietly replace S 			= 	[S]_b[_cons] 	in `i'
	quietly replace K 			= 	[K]_b[_cons] 	in `i'
}
beep
keep 	if K >0 & S>0

eststo clear
*eststo estCostParametersSD, title(): estpost summ G S K  
*matrix 	SD = e(sd)

global 	e0 = 1125
global 	e3 = 1750
global 	e9 = 1926

	preserve
		clear

		quietly 	set 		obs 3
		quietly 	generate 	y = 0
		quietly 	replace 	y = 1 in 1

		eststo estCostParameters: nl costsolver @ y, parameters(G S K) initial(G gamma S s K k) eps(0.5e-4)  nolog
	restore
	matrix 	define Beta = e(b)
	matrix coleq Beta = :G :S :K   
	
	eststo estCostParametersSD, title("Minimum distance estimator"): estpost summ G S K  

	estadd 	matrix Coef = Beta

* Out of sample prediction . Predict effort when p = 6 cent

*scalar e6 = ((Beta[1,2]+0.06)/Beta[1,3])^(1/Beta[1,1])

estadd 	scalar e6 = ((Beta[1,2]+0.06)/Beta[1,3])^(1/Beta[1,1])
/*
#d ;  
		esttab 	estCostParametersSD using "${outdir}\StructuralParameters.tex", 
		label mtitles
		main(Coef) 
		aux(sd %8.3g)
		stats(e6 N, labels("Implied effort at 6-cents" "N") )
		sfmt(0)
		coeflabel(G  "Curvature $\gamma$ of cost of effort function" S "Level k of cost of effort function" 
						K "Intrinsic motivation s (cents per point)")
		gap
		nonotes
		addnotes(standard errors in parenthesis)
		width(\hsize)
		replace
		;
#d cr
*/

/* 
Estimating parameters from race salient treatment

Taking parameters of cost function (gamma and k) and intrinsic motivation (s) as given, we solve for delta s
for both black and white employers. 

Because of limited sample size and very few observations for racial combinations of Black/White workers
with Black/White employers for each piece rate, we only restrict to average effort by All Worker under
all piece rates to Black/White Employer. So we will only estimate two parameters in this case. 
*/


scalar DeltaSb = (Beta[1,3] * (2191^Beta[1,1])) - Beta[1,2]
scalar DeltaSw = (Beta[1,3] * (2051^Beta[1,1])) - Beta[1,2]

/* To generate confidence intervals for these estimate, we generate a bootstrap sample of workers and 
restimating these parameters.*/ 

* Generating bootstrap sample

* Import cleaned data from experiment

use 		"${rootdir}\Output\Analysis\CleanedData.dta", clear

* Since each observation appear twice (once for each participant), we drop the employer observations

keep 		if Role == 2
keep 		if Treatment == "Race Salient"

replace 		EmployerRace = "Black" if EmployerRace == "Black or African-American"
replace 		EmployerRace = "White" if EmployerRace == "White or Caucasian"

save 		"${tempdir}\RaceSalientData", replace

* Draw a bootstrap sample of 1000 means of observations for each treatment (Black Employer and White Employer)

clear
set 	obs `draws'

gen 	PointsBlack = 0 
gen 	PointsWhite = 0

count
forvalues i = 1/`r(N)' {
		foreach x in "Black" "White" {
			preserve
				use 		"${tempdir}\RaceSalientData", clear
				quietly 	count 		if EmployerRace == "`x'"
					
				quietly 	bsample 	`r(N)' if EmployerRace == "`x'"
				quietly 	summ Points
				quietly 	local 		mean`x' = `r(mean)'
			restore	

			quietly 		replace Points`x' = round(`mean`x'') in `i'	
		}		
}

save 	"${tempdir}\BootstrapSampleRace", replace

gen 		DeltaSb = (Beta[1,3] * (PointsBlack^Beta[1,1])) - Beta[1,2]
gen 		DeltaSw = (Beta[1,3] * (PointsWhite^Beta[1,1])) - Beta[1,2]

eststo 		estRSParametersSD, title(): estpost summ DeltaSb DeltaSw
matrix 		DeltasSD = e(sd)
matrix 		rownames DeltasSD = y1
matrix 		define Deltas = [DeltaSb, DeltaSw]

estimates 	restore estCostParametersSD

estadd 		matrix Deltas
matrix 		colnames Deltas = DeltaSb DeltaSw
matrix 		rownames Deltas = y1

estadd 		matrix DeltasSD

matrix 		Coef = [Beta, Deltas]
estadd 		matrix Coef, replace

matrix 		SDs = [e(sd), DeltasSD]
estadd 		matrix SDs, replace

#d ;  
		esttab 	estCostParametersSD using "${outdir}\StructuralParameters.tex", 
		label mtitles
		main(Coef) b(2)
		aux(SDs %8.3g)
		stats(e6 N, labels("Implied effort at 6-cents (using baseline parameters)" "N")  fmt(0))
		coeflabel(G  "\hspace{0.2cm}Curvature $\gamma$ of cost of effort function" S "\hspace{0.2cm}Level k of cost of effort function" 
						K "\hspace{0.2cm}Intrinsic motivation s (cents per point)" DeltaSb "\hspace{0.2cm}Taste parameter towards Black employer $\Delta s_{.B}$"
						DeltaSw "\hspace{0.2cm}Taste parameter towards White employer $\Delta s_{.W}$")
		gap
		nonotes
		refcat(G "\emph{Baseline Parameters}" DeltaSb "\emph{Race Salient Parameters}", nolabel)
		addnotes(standard errors in parenthesis)
		width(\hsize)
		replace
		;
#d cr

