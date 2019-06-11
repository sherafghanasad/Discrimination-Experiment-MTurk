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
			
global		codedir		"${rootdir}\Code\Review Photographs"
global		rawdatadir	"${rootdir}\Input\Raw Data"
global		outdir		"${rootdir}\Output\Review Photographs"
global		tempdir		"${rootdir}\Temp\Review Photographs"
global		writingdir	"${rootdir}\Documentation\Review Photographs"

log			using 		"${writingdir}\Review Photographs_`c(current_date)'", replace

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
		"${rawdatadir}\demographic_survey_2018-10-01.xlsx", 
		sheet("Sheet1") 
		cellrange(A2) clear
		;
#d cr

drop 	in 1/6 // These obs are from testing session
drop 	if LastPage == "Survey" | LastPage == "Consent" | LastPage == "" // These guys didn't complete the survey
keep 	if LastPage == "Qualified"

duplicates drop
*isid 	WorkerID

save 	"${tempdir}\DemographicData", replace

gen 	FileName = substr(Race,1,1) + substr(Gender,1,1) + "_" + WorkerID

keep 	WorkerID Image FileName
gen 	Saved = ""
gen 	RaceMatched = ""
gen 	GenderMatched = "" 

export 	excel using "${outdir}\RaceVerification_$S_DATE", replace firstrow(var)

* Import raw data from experiment

#d ;
import 	excel 
		WorkerID = P
		LastPage = H
		PieceRateImage = AC
		PieceRate = AH
		using 
		"${rawdatadir}\experiment_2018-10-01.xlsx", 
		sheet("Sheet1") 
		cellrange(A2) clear
		;
#d cr

drop 	in 1/16
drop 	if LastPage != "SurveyCode" // These guys didn't complete the survey
drop 	if PieceRateImage == "0"

isid 		WorkerID
merge 		1:m WorkerID using "${tempdir}\DemographicData", keep(3) keepusing(Gender Race) nogen
drop 		LastPage
tostring	PieceRate, replace
replace 	PieceRate = subinstr(PieceRate, ".0","",.)

gen 		FileName = substr(Race,1,1) + substr(Gender,1,1) + "_" + PieceRate + "_" + WorkerID

gen 		Saved = ""
gen 		AmountVisible = ""
gen 		FaceVisible = ""
gen 		HandVisible = ""
gen 		OtherInfo = "" 
gen 		RaceSalient = ""
export 	excel using "${outdir}\PieceRatePicVerification_$S_DATE", replace firstrow(var)
