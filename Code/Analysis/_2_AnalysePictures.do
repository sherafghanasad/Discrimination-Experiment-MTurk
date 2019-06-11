/* 
This file uses data from pictures' inspections and combine that with other data. 

Input: 
	CleanedData
Output:
	Updated data with information from pictures
*/	

clear 		all
set			more off
capture		log close

log			using 		"${writingdir}\_2_AnalysePictures_`c(current_date)'", replace

use 		"${outdir}\CleanedData", clear

* First verify if the reported race match with observed race from hand

#d ;
import 		excel 
			WorkerID = A
			HandRaceMatched = E
			HandGenderMatched = F
			using 
			"${rawdatadir}\RaceVerification.xls", 
			cellrange(A2) clear
			;
#d cr

replace 	WorkerID = subinstr(WorkerID, ": COPIED", "",.) 
replace 	WorkerID = upper(WorkerID)
replace 	WorkerID = trim(WorkerID)

foreach 	var of varlist HandRaceMatched HandGenderMatched {
			bysort 	WorkerID (`var'): replace `var' = `var'[1] if `var'==.
			}
duplicates 	drop
			
isid 		WorkerID
			
merge 		1:1 WorkerID using "${outdir}\CleanedData", keep(2 3) 
isid 		WorkerID
drop	 	_merge
save 		"${tempdir}\CleanedDataWithHandPic", replace

#d ;
import 		excel 
			WorkerID = A
			AmountVisible = H
			FaceVisible = I
			HandVisible = J
			OtherInfoVisible = K
			RaceSalient = L
			GenderSalient = M
			using 
			"${rawdatadir}\PieceRatePicVerification.xls", 
			cellrange(A2) clear
			;
#d cr

replace 	WorkerID = subinstr(WorkerID, ": COPIED", "",.) 
replace 	WorkerID = upper(WorkerID)
replace 	WorkerID = trim(WorkerID)

foreach 	var of varlist AmountVisible FaceVisible HandVisible OtherInfoVisible RaceSalient GenderSalient{
			bysort 	WorkerID (`var'): replace `var' = `var'[1] if `var'==.
			}
duplicates 	drop
isid 		WorkerID

merge 		1:1 WorkerID using "${tempdir}\CleanedDataWithHandPic", keep(2 3)

