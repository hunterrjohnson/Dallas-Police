/*******************************************************************************
     MERGE DISPATCH, ARREST, USE OF FORCE, AND OFFICER DEMOGRAPHICS
	   1. READ CSV AND CONVERT TO DTA FOR STATA
	   2. MERGE DISPATCH AND ARREST DATA BY incidentnum
	   3. MERGE FORCE WITH DISPATCH/ARREST BY incidentnum
	   4. MERGE REMAINING FORCE INCIDENTS BY OTHER CHARACTERISTICS
	   5. OUTPUT TO CSV
*******************************************************************************/

cd "/Users/hunterjohnson/Dropbox/Dallas Projects/"

* IMPORT DISPATCH, FIX PROBLEMS WITH incidentnum, SAVE AS DTA
import delimited "Data/Clean/dispatch.csv", encoding(ISO-8859-1) clear
drop v1
tostring year, gen(year2) force
replace year2 = "-"+year2
replace incidentnum = subinstr(incidentnum, ".0", year2, .)
replace incidentnum = "0" + incidentnum if length(incidentnum)<11 & length(incidentnum)!=0
drop year2
save "Data/Temp/dispatch.dta", replace

* IMPORT ARRESTS AND SAVE AS DTA
import delimited "Data/Clean/arrest.csv", encoding(ISO-8859-1) clear
drop v1
save "Data/Temp/arrest.dta", replace

* IMPORT FORCE AND SEPARATE ROWS WHERE incidentnum IS MISSING AND SAVE AS DTA
import delimited "Data/Clean/force.csv", encoding(ISO-8859-1) clear
preserve
	drop if incidentnum == "NA"
	save "Data/Temp/force_noNA.dta", replace
restore
preserve
	drop if incidentnum != "NA"
	save "Data/Temp/force_yesNA.dta", replace
restore

* MERGE DISPATCH AND ARRESTS USING JOINBY
use "Data/Temp/dispatch.dta", clear
use "Data/Temp/arrest.dta", clear
joinby incidentnum using "Data/Temp/arrest.dta", unmatched(master)

* CHECK COUNTS OF CALLS, INCIDENTS, AND ARRESTS
unique dispatchnum
unique incidentnum
unique arrestnum



