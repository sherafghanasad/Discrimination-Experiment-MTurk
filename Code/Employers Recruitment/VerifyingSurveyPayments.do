/* 
This file randomly select employers for participation in the video-recording
Input: 
	Participation interest form
Output:
	List of employer's email who will be invited to participate

Written by: Sher Afghan Asad
Date: 2019-04-02
	
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
			
global		codedir		"${rootdir}\Code\Employers Recruitment"
global		rawdatadir	"${rootdir}\Input\Raw Data"
global		outdir		"${rootdir}\Output\Employers Recruitment"
global		tempdir		"${rootdir}\Temp\Employers Recruitment"
global		writingdir	"${rootdir}\Documentation\Employers Recruitment"

log			using 		"${writingdir}\Employers Recruitment_`c(current_date)'", replace

* Import raw data from participation interest form

#d ;
import 	delimited 
			"${rawdatadir}\Employers Recruitment\Participation interest form.csv", 
			varnames(1) 
			case(preserve) 
			;
#d cr

* Drop people who don't meet the eligibility criteria

drop 	if Abovetheageof18 == "No" | Gender  != "Male"  | (Raciallyidentifyas != "Black or African American" & Raciallyidentifyas != "White or Caucasian") |  Speakenglishasyourfirstlanguage != "Yes"

* We need to select 25 blacks and 25 whites to participate in the study. 

count 	if Raciallyidentifyas == "Black or African American"

preserve 
	keep 	if Raciallyidentifyas == "Black or African American"
	tempfile Blacks
	save 		`Blacks'
restore
	
* Since there are not enough Blacks we will recruit all of them

count 	if Raciallyidentifyas == "White or Caucasian"

* We will randomly select 25 people from White group. 
preserve
	set 			seed 12345
	keep 		if Raciallyidentifyas == "White or Caucasian"
	gen 			Random = runiform()
	sort 			Random
	keep 		in 1/25
	
	tempfile 	Whites
	save 			`Whites'
restore

use 		`Blacks', clear	
append using `Whites'
	
export 	excel using "${outdir}\EmployersToBeInvited", firstrow(var) replace

