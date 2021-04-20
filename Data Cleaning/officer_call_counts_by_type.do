cd "/Users/hunterjohnson/Dropbox/Dallas Police CJL/"

use "2-stata_data/DPD_calls_for_service.dta", clear

* GENERATE DUMMIES FOR EACH PROBLEM TYPE
tab cfs_problem_t, gen(probl)

* CALCULATE RUNNING TOTAL OF CALL TYPE COUNTS BY OFFICER
forvalues i=1/20 {
	
	* ROWS ARE SOMETIMES DUPLICATED BY cse_id
	bysort cfs_off_badge inc_id : gen probl`i'n = _n
	replace probl`i' = 0 if probl`i'n > 1
	
	* CUMULATIVE CALL COUNTS BY TYPE AND OFFICER
	bysort cfs_off_badge (cfs_assigned_datetime) : gen cum_probl`i' = sum(probl`i')
	
	* DROP TEMP VARIABLES AFTER USE
	drop probl`i'n probl`i'
	
}

keep inc_id cfs_off_badge cfs_assigned_datetime cum_probl*

save "2-stata_data/DPD_call_type_counts.dta", replace

