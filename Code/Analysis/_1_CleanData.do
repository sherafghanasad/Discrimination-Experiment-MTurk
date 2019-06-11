/* 
This file cleans data from demographic survey and experiment and combine them
together. 

Input: 
	Demographic Survey Data
	Experiment Data
Output:
	Cleaned data from experiment including demographic information	
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_1_CleanData_`c(current_date)'", replace

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

* Gender

gen 		Male = (Gender == "Male") * 100
gen 		Female = (Gender == "Female") * 100

* Age

tabulate 	Age, gen(Age)
foreach 	var of varlist Age1-Age6 {
replace 	`var' = `var'*100
}

* Education

tabulate 	Education, gen(Education)
foreach 	var of varlist Education1-Education6 {
replace 	`var' = `var'*100
}

* Race

tab			Race, gen(Race)

* Employer Race

bysort 		GroupID (Role): gen EmployerRace = Race[1]

* Fairness 

gen 			Fair = (PieceRate >= FairPieceRate)

save 		"${outdir}\CleanedData", replace
