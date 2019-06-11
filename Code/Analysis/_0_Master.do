/* 
This set of do files generates Tables and Figures that are used in the paper
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

* Clean Data

do 			"${codedir}\_1_CleanData.do"

* Summarize Demographics

do 			"${codedir}\_2_SummarizeDemographicData.do"

* Treatment Effects 

do 			"${codedir}\_3_TreatmentEffects.do"

* Effort by worker's group identity

do 			"${codedir}\_4_EffortByWorkerGroups.do"

* Fairness and effort choices

do 			"${codedir}\_5_FairnessAndEffort.do"

* Miscellaneous figures for Appendix

do 			"${codedir}\_6_Miscellaneous.do"

