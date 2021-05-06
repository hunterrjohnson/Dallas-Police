***** BALANCE TESTS - REPLICATION OF HOEKSTRA/SLOAN (2020) *********************

cd "/Users/hunterjohnson/Dropbox/Dallas Projects/"

use "1_Data/2_Clean/analysis.dta", clear

gen watch = 0
replace watch = 1 if hour>=0 & hour<8
replace watch = 2 if hour>=8 & hour<16
replace watch = 3 if hour>=16

* Convert to Stata date format
replace date = substr(date, 1, 10)
gen new_date = date(date, "YMD")
format %td new_date
drop date
rename new_date date
gen week = week(date)
gen dow = dow(date)

destring latitude longitude, replace force

* Generate location-by-time fixed effects
egen div_year_week_watch = group(division year week watch)
egen div_year_week = group(division year week)
egen div_year = group(division year)

* Generate weights for number of officers per call
gen weight = 1/n_offs

***** BLACK NEIGHBORHOODS ******************************************************
foreach x in div_year_week_watch div_year_week div_year division {
	global basic "`x'"
	global controls_pred "bg_prop_black md_dispatch latitude longitude medhhinc lessthanhs"
	global fixed_eff_pred "dow priority problem"
	
	drop if off_race=="OTHER"
	
	preserve
		* Take out basic FE
		reghdfe force_used [pweight=weight], absorb($basic, save) keepsingletons residuals
		predict res_uof, res

		* Add back in mean
		sum force_used
		gen res_uof_NOMEAN=res_uof
		replace res_uof=res_uof+r(mean)

		* Predict force_used using everything observed about call before it was assigned to an officer
		reghdfe res_uof $controls_pred [pweight=weight], absorb($fixed_eff_pred, save) vce(cluster badge) keepsingletons residuals
		predict pred_uof, xbd

		* Make figures
		foreach var of varlist pred_uof res_uof_NOMEAN force_used {
			binscatter `var' bg_prop_black, by(off_race) ylabel(".002(.001).01") ytitle(${ytitle_`var'}) xtitle(Proportion Black)
				graph save "3_results/balance_replication/black_`x'_bin_`var'", replace
				graph export "3_results/balance_replication/black_`x'_bin_`var'.png", replace
		}
	restore
}

***** HISPANIC NEIGHBORHOODS ***************************************************
foreach x in div_year_week_watch div_year_week div_year division {
	global basic "`x'"
	global controls_pred "bg_prop_hisp md_dispatch latitude longitude medhhinc lessthanhs"
	global fixed_eff_pred "dow priority problem"
	
	drop if off_race=="OTHER"
	
	preserve
		* Take out basic FE
		reghdfe force_used [pweight=weight], absorb($basic, save) keepsingletons residuals
		predict res_uof, res

		* Add back in mean
		sum force_used
		gen res_uof_NOMEAN=res_uof
		replace res_uof=res_uof+r(mean)

		* Predict force_used using everything observed about call before it was assigned to an officer
		reghdfe res_uof $controls_pred [pweight=weight], absorb($fixed_eff_pred, save) vce(cluster badge) keepsingletons residuals
		predict pred_uof, xbd

		* Make figures
		foreach var of varlist pred_uof res_uof_NOMEAN force_used {
			binscatter `var' bg_prop_hisp, by(off_race) ylabel(".002(.001).01") ytitle(${ytitle_`var'}) xtitle(Proportion Hispanic)
				graph save "3_results/balance_replication/hisp_`x'_bin_`var'", replace
				graph export "3_results/balance_replication/hisp_`x'_bin_`var'.png", replace
		}
	restore
}


