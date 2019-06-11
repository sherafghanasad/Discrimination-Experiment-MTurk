/* 
This file review the survey codes submitted by MTurkers to see if they needs to be paid or not. 
Input: 
	Demographic Survey Data
	Experiment Data
	MTurk Batch Results
Output:
	Approvals (file which is uploaded in MTurk to approve/reject submissions)
	Bonus Payments (file which gives the code to use in CLI for bonus payments)

Bulk bonus payments are explained here; 
http://research-tricks.blogspot.com/2012/07/bulk-bonuses-on-mturk.html

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
			
global		codedir		"${rootdir}\Code\Payments"
global		rawdatadir	"${rootdir}\Input\Raw Data"
global		outdir		"${rootdir}\Output\Payments"
global		tempdir		"${rootdir}\Temp\Payments"
global		writingdir	"${rootdir}\Documentation\Payments"

log			using 		"${writingdir}\Payments_`c(current_date)'", replace

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
*drop 	LastPage

replace SurveyCode = upper(SurveyCode)
replace	SurveyCode = trim(SurveyCode)

replace WorkerID = upper(WorkerID)
replace	WorkerID = trim(WorkerID)

isid 	SurveyCode WorkerID

save 	"${tempdir}\SurveyData", replace

* Import raw data from experiment

#d ;
import 	excel 
		SurveyCode = B
		WorkerID = P
		LastPage = H
		Bonus = AE
		PieceRateImage = AC
		using 
		"${rawdatadir}\experiment_2018-10-03.xlsx", 
		sheet("Sheet1") 
		cellrange(A2) clear
		;
#d cr

drop 	if LastPage != "SurveyCode" // These guys didn't complete the survey

replace SurveyCode = upper(SurveyCode)
replace	SurveyCode = trim(SurveyCode)

replace WorkerID = upper(WorkerID)
replace	WorkerID = trim(WorkerID)

save 	"${tempdir}\ExperimentData", replace

* Import data from MTurk

#d ;
import 	delimited 
		"${rawdatadir}\Batch_3380463_batch_results.csv", 
		clear
		;
#d cr

*keep 	assignmentid workerid answersurveycode approve reject

keep 	if assignmentstatus == "Submitted"

ren 	answersurveycode SurveyCode
ren 	workerid WorkerID

foreach var of varlist SurveyCode WorkerID {
	replace `var' = upper(`var')
	replace `var' = trim(`var')
}	

isid 	SurveyCode WorkerID

merge 	1:1 SurveyCode WorkerID using "${tempdir}\SurveyData", keep(1 3) keepusing(SurveyCode WorkerID Image)
merge 	1:1 SurveyCode WorkerID using "${tempdir}\ExperimentData", keep(1 3) keepusing(SurveyCode WorkerID Bonus PieceRateImage) gen(_merge1)

foreach 	var of varlist approve reject Bonus {
	tostring	`var', replace
	replace 	`var' = "" if `var' == "."
}

replace		approve = "x" if (_merge == 3 | _merge1 == 3)
replace 	reject = "Wrong worker id or survey code" if approve == ""

ren 		(SurveyCode WorkerID) (answersurveycode workerid)

* Export sheet to accept or reject HITS on MTurk

preserve
	drop 	Image Bonus PieceRateImage _merge _merge1
	export 	delimited using "${outdir}\Approvals$S_DATE", replace 
restore

* Determine bonus payments

gen 	BonusFormula = "grantBonus " + "–workerid " + workerid + " –amount " + Bonus + " –assignment " + assignmentid + " –reason " + `"""' + "Your earnings from the labor market experiment" + `"""'  if Bonus != "" & Bonus != "0"
keep 	if BonusFormula != "" 

keep 		hitid assignmentid workerid Bonus BonusFormula
destring 	Bonus, replace

export 		excel using "${outdir}\BonusPayments$S_DATE", firstrow(var) replace

append 		using "${outdir}\BonusPayments",
duplicates 	drop
save 		"${outdir}\BonusPayments", replace

