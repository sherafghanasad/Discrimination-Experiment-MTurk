/* 
This file generates an excel file which will be used to convert picture codes to graphic files
Input: 
	Demographic Survey Data
	Experiment Data
Output:
	Approvals (file which is uploaded in MTurk to approve/reject submissions)
	Bonus Payments (file which gives the code to use in CLI for bonus payments)

Written by: Sher Afghan Asad
Date: 2018-09-24
	
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
			
global		codedir		"${rootdir}\Code\Analysis"
global		rawdatadir	"${rootdir}\Input\Raw Data"
global		outdir		"${rootdir}\Output\Analysis"
global		tempdir		"${rootdir}\Temp\Analysis"
global		writingdir	"${rootdir}\Documentation\Analysis"

log			using 		"${writingdir}\Analysis_`c(current_date)'", replace

* Import raw data from demographic survey

#d ;
import 	excel 
		SurveyCode = B
		WorkerID = P
		Gender =Q
		Race = R
		Age = S
		Education = T
		Image = U
		LastPage = H
		using 
		"${rawdatadir}\demographic_survey_2018-10-03.xlsx", 
		sheet("Sheet1") 
		cellrange(A2) clear
		;
#d cr

drop 	in 1/6 // These obs are from testing session
drop 	if LastPage == "Survey" | LastPage == "Consent" | LastPage == "" // These guys didn't complete the survey
keep 	if LastPage == "Qualified"

replace 	WorkerID = subinstr(WorkerID, ": COPIED", "",.) 
replace 	WorkerID = upper(WorkerID)
replace 	WorkerID = trim(WorkerID)

duplicates drop WorkerID Gender Race Age Education LastPage, force
isid 	WorkerID

save 	"${tempdir}\DemographicData", replace

* Import raw data from experiment

#d ;
import 	excel 
		WorkerID = P
		LastPage = H
		PieceRate = AH
		GuessedPieceRate = AI
		FairPieceRate = AJ
		GuessedPoints = AN
		Treatment = AG
		Points = AL
		GroupID = AF
		Role = O
		Feedback = AB
		IPAddress = I
		using 
		"${rawdatadir}\experiment_2018-10-03.xlsx", 
		sheet("Sheet1") 
		cellrange(A2) clear
		;
#d cr

drop 	in 1/16
drop 	if GroupID == 1 & PieceRate == 0
drop 	if LastPage == "" 

* Workers in following groups participated on phone so they couldn't do the button pressing task

#d ;
drop 	if GroupID == 4 | GroupID == 18 | GroupID == 41 | GroupID == 53 |
		GroupID == 71 | GroupID == 125
		;
#d cr

* Workers in following groups dropped out before working on the task

#d ;
drop 	if GroupID == 6 | GroupID == 8 | GroupID == 14 | GroupID == 16 | 
		GroupID == 17 | GroupID == 21 | GroupID == 22 | GroupID == 24 |
		GroupID == 32 | GroupID == 35 | GroupID == 38 | GroupID == 39 |
		GroupID == 46 | GroupID == 49 | GroupID == 67 | GroupID == 77 |
		GroupID == 78 | GroupID == 80 | GroupID == 82 | GroupID == 92 | 
		GroupID == 95 | GroupID == 97 | GroupID == 105 | GroupID == 126 |
		GroupID == 127 | GroupID == 134 | GroupID == 141 | GroupID == 145 |
		GroupID == 149 | GroupID == 152 | GroupID == 154 | GroupID == 157 |
		GroupID == 159 | GroupID == 165
		;
#d cr

* Assigned to Multiple treatments

drop 	if GroupID == 136 | GroupID == 131

* Drop subjects which did not provide M-Turk ID

gen 		ID = _n
tostring 	ID, replace
replace 	WorkerID = ID if WorkerID == "NOT PROVIDED"
replace 	WorkerID = subinstr(WorkerID, ": COPIED", "",.) 
replace 	WorkerID = upper(WorkerID)
replace 	WorkerID = trim(WorkerID)

*drop 	if LastPage != "SurveyCode" // These guys didn't complete the survey
drop 	LastPage
*drop 	if WorkerID == "AZ5ZYUCAQ0XDL" & Treatment == "Baseline"

* Dropping groups that scored zero points, this must be because of technical issues

drop 	if Points == 0 

isid 		WorkerID
merge 		1:1 WorkerID using "${tempdir}\DemographicData", keep(1 3) keepusing(Gender Race Age Education) nogen

replace 	Gender = "Male" if Gender == "" 
replace 	Race = "Black or African-American" if Race == ""

replace 	Education = "College Graduate" if Education == "other_:Bachelors Degree"  
replace 	Gender = "" if Gender == "Prefer not to answer" | Gender == "other_:transgender female"
replace 	Education = "Master's Degree" if Education == "Professional Degree"
replace 	Education = "High School or equivalent" if Education == "Vocational/Technical School"

label 		define education 1 "Less than high school" 2 "High School or equivalent" 3 "Some College" 4 "College Graduate" 5 "Master's Degree" 6 "Doctoral Degree"
encode 		Education, gen(EducEnc) label(education) noextend
drop 		Education
ren 		EducEnc Education

* Variation in piece rates

#d ;
graph 	bar (count) if Role == 1, 
		over(PieceRate) over(Race)
		ytitle(Frequency) 
		title("Piece-Rate Distribution") 
		note("Note: This graph represents the distribution of piece rates (in dollars per 100 points) as selected" "by Black and White Employers. ", 
		margin(zero))
		;
#d cr
		
graph 	export "${outdir}\PieceRateDistribution$S_DATE.png", replace
		
* Demographics of Subjects

* Gender

gen 	Male = (Gender == "Male") * 100
gen 	Female = (Gender == "Female") * 100

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

tabulate 	Age, gen(Age)
foreach var of varlist Age1-Age6 {
replace 	`var' = `var'*100
}

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

tabulate 	Education, gen(Education)
foreach var of varlist Education1-Education6 {
replace 	`var' = `var'*100
}

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

tab		Race, gen(Race)

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


* Distribution of points scored

histogram Points if Role ==1, width(25) start(0) xtitle("Points") ytitle("Frequency") ///
		freq title("Distribution of Points - All Treatments") graphregion(color(white)) lcolor(black) fcolor(black) ///
		xlabel(0(500)4000) xmtick(0(100)4000,grid) gap(75) ylabel(,nogrid)
graph 	export "${outdir}\PointsDist.png", replace

* Effort against different piece rates

eststo clear
eststo estBaseline, title(Baseline): estpost tabstat Points if Role == 2 & Treatment == "Baseline", statistics(count mean sd semean) by(PieceRate) 

bysort GroupID (Role): gen EmployerRace = Race[1]
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

* Effort by the identity of worker in the Race Salient treatment
preserve
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

restore

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
	
* Treatment Effect

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

*Female Education2 Education3 Education4 Education5 Race1 Age2 Age3 Age4 Age5 Age6
*2b.Treat 1.Treat#1.EmpRace 1o.Treat#2b.EmpRace 2b.Treat#2b.EmpRace
*reg 	Points PieceRate i.Treat	
*		refcat(Fixed Effects "Gender" Race1 "Race" Age2 "Age" Education2 "Education",nolabel)


* Fairness and Effort 

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
