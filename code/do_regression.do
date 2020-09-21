*==
*== Tropical cyclones adaptation
*==

local root "/Users/alexandre/development/work/cerna"

*== Load EM-DAT / TCE-DAT later and save it for later merge
clear
import excel "`root'/data/processed/final_storm_patent_data.xlsx", ///
	sheet("Sheet1") firstrow clear
sort ISO year
keep if year >= 1990

foreach x of varlist event_count event_count_v34 event_count_v64 event_count_v96 {
	replace `x' = 0. if `x' == .
}
* Create exclusive bins for event counts (evt_count64 : events with v_landfall between 64 and 96kn)
gen evt_count34 = event_count_v34 - event_count_v64
gen evt_count64 = event_count_v64 - event_count_v96
gen evt_count96 = event_count_v96
gen evt_count3464 = evt_count34 + evt_count64
gen evt_count6496 = evt_count64 + evt_count96
drop event_count_v64 event_count_v96
replace event_count_match_only = 0 if event_count_match_only == .

* Number of EM-DAT storms we could match per country. Drop countries with not enough data
egen tot_storms_matched = sum(event_count_match_only), by(ISO)
drop if tot_storms_matched < 2

* Replace NaN values with 0 for years where there was no EM-DAT event registered
foreach x of varlist pop34 pop64 pop96 assets34 assets64 assets96 ///
		pop34_d5 pop64_d5 pop96_d5 assets34_d5 assets64_d5 assets96_d5 ///
		pop34_d15 pop64_d15 pop96_d15 assets34_d15 assets64_d15 assets96_d15 ///
		pop34_d30 pop64_d30 pop96_d30 assets34_d30 assets64_d30 assets96_d30 ///
		TotalDeaths_match_only TotalDamages_match_only TotalDeaths TotalDamages {
	replace `x' = 0. if TotalDamages == .
}
	
*TODO: do better ?
* for now, replace missing damage data with 0
* We likely have years with exposure data matched with some EM-DAT storms, but not necessarily with damage data.
* In that case: TotalDamages=0, TotalDeaths_match_only=.
replace TotalDeaths_match_only = 0 if TotalDeaths_match_only == .
replace TotalDamages_match_only = 0 if TotalDamages_match_only == .

* Check for missing values
misstable summarize

*Experience stock
gen exp_stock_deaths = TotalDeaths_match_only
gen exp_stock_damages = TotalDamages_match_only
gen exp_stock_count = event_count // !! event_count_match_only also exists, this is EM-DAT total event count
gen exp_stock_count_v64 = evt_count64 // This time, only events that were matched with TCE-DAT, and with (1-min) v_land > 64kn (category 1+) 
gen exp_stock_count_v96 = evt_count96 // Same, with (1-min) v_land > 96kn (category 3+) 
gen exp_stock_pop96 = pop96
gen exp_stock_pop34 = pop34
by ISO: replace exp_stock_deaths = TotalDeaths_match_only + (1 - 0.15) * exp_stock_deaths[_n-1] if _n > 1
by ISO: replace exp_stock_damages = TotalDamages_match_only + (1 - 0.15) * exp_stock_damages[_n-1] if _n > 1
by ISO: replace exp_stock_count = event_count + (1 - 0.15) * exp_stock_count[_n-1] if _n > 1
by ISO: replace exp_stock_count_v64 = evt_count64 + (1 - 0.15) * exp_stock_count_v64[_n-1] if _n > 1
by ISO: replace exp_stock_count_v96 = evt_count96 + (1 - 0.15) * exp_stock_count_v96[_n-1] if _n > 1
by ISO: replace exp_stock_pop96 = pop96 + (1 - 0.15) * exp_stock_pop96[_n-1] if _n > 1
by ISO: replace exp_stock_pop34 = pop34 + (1 - 0.15) * exp_stock_pop34[_n-1] if _n > 1

*Scale down indicators to have bigger coeffs (instead of 1e-10)
foreach x of varlist pop34 pop64 pop96 pop34_d5 pop64_d5 pop96_d5 ///
	pop34_d15 pop64_d15 pop96_d15 pop34_d30 pop64_d30 pop96_d30 {
	replace `x' = `x' / 1e6
}
foreach x of varlist assets34 assets64 assets96 assets34_d5 assets64_d5 assets96_d5 ///
	assets34_d15 assets64_d15 assets96_d15 assets34_d30 assets64_d30 assets96_d30 {
	replace `x' = `x' / 1e12
}
gen pop3464 = pop34 + pop64
gen pop3464_d5 = pop34_d5 + pop64_d5
gen pop6496_d5 = pop64_d5 + pop96_d5
gen pop346496_d5 = pop34_d5 + pop64_d5 + pop96_d5
gen pop3464_d15 = pop34_d15 + pop64_d15
gen pop3464_d30 = pop34_d30 + pop64_d30
gen assets3464 = assets34 + assets64
gen assets6496 = assets64 + assets96
gen assets3464_d5 = assets34_d5 + assets64_d5
gen assets6496_d5 = assets64_d5 + assets96_d5
gen assets346496 = assets34 + assets64 + assets96
gen assets346496_d5 = assets34_d5 + assets64_d5 + assets96_d5
gen assets3464_d15 = assets34_d15 + assets64_d15
gen assets3464_d30 = assets34_d30 + assets64_d30
gen avg_pop3464_d5 = pop3464_d5 / (evt_count34 + evt_count64)
gen avg_pop6496_d5 = (pop64_d5 + pop96_d5) / (evt_count64 + evt_count96)
gen avg_pop346496_d5 = (pop34_d5 + pop64_d5 + pop96_d5) / (evt_count34 + evt_count64 + evt_count96)
gen avg_pop64_d5 = pop64_d5 / evt_count64
gen avg_pop96_d5 = pop96_d5 / evt_count96
replace exp_stock_deaths = exp_stock_deaths / 1e3
replace exp_stock_damages = exp_stock_damages / 1e6
replace exp_stock_pop96 = exp_stock_pop96 / 1e6

* Construct log variables
gen log_gdp_pc = log(gdp_pc_office)
gen log_pop = log(pop_office)

* Construct time lagged variables
by ISO: gen pat_count_both_t1 = pat_count_both[_n-1]
by ISO: gen pat_count_all_t1 = pat_count_all[_n-1]
by ISO: gen pat_stock_all_t1 = pat_stock_all[_n-1]
by ISO: gen pat_stock85_both_t1 = pat_stock85_both[_n-1]
by ISO: gen pat_stock70_both_t1 = pat_stock70_both[_n-1]
* HVI
by ISO: gen pat_count_both_hvi_t1 = pat_count_both_hvi[_n-1]
by ISO: gen pat_count_all_hvi_t1 = pat_count_all_hvi[_n-1]
by ISO: gen pat_stock_all_hvi_t1 = pat_stock_all_hvi[_n-1]
by ISO: gen pat_stock85_both_hvi_t1 = pat_stock85_both_hvi[_n-1]
by ISO: gen pat_stock70_both_hvi_t1 = pat_stock70_both_hvi[_n-1]
* Exp
by ISO: gen exp_stock_deaths_t1 = exp_stock_deaths[_n-1]
by ISO: gen exp_stock_damages_t1 = exp_stock_damages[_n-1]
by ISO: gen exp_stock_count_t1 = exp_stock_count[_n-1]
by ISO: gen exp_stock_count_v64_t1 = exp_stock_count_v64[_n-1]
by ISO: gen exp_stock_count_v96_t1 = exp_stock_count_v96[_n-1]
by ISO: gen exp_stock_pop96_t1 = exp_stock_pop96[_n-1]
by ISO: gen exp_stock_pop34_t1 = exp_stock_pop34[_n-1]

* Convert country to numeric
encode ISO, gen(country)
xtset country year

*== Collinearity between variables ?
* Stock storms and stock prec are highly correlated (0.98) and have a very high VIF, they should not be put together
* 34 and 64kn pop are slightly correlated (0.77, VIF 2.5/2.7), when combined it's better (VIF 1.26, 0.45 corr with pop96)
* 34 and 64 assets are quite correlated (0.86, VIF(64ass)=5.48), better when combined (VIF 1.58, 0.6 corr)
* Experience stock: exp_stock_deaths & exp_stock_damages not correlated at all ! (0.11, VIF 1.01)


*== Countfit command
//countfit TotalDeaths_match_only i.country i.year log_gdp_pc log_pop pat_stock85_both_hvi_t1 exp_stock_deaths_t1 assets3464 assets96, inf(event_count_v34) nocons 

*== Try to converge on a baseline spec, with a few alternatives
*== 1 - Regressions on the nb of deaths

* Exposition variables
* Try different combinations of pop_d5 
* (not evt_count as pop_d5 makes more sense in theory + evt_count seems to lower the significance of the interest variable)
* Exposed population that is close to the coastline
local dis_var1 pop34_d5 pop6496_d5
local dis_var2 pop3464_d5 pop96_d5
local dis_var3 evt_count34 evt_count6496
local dis_var4 evt_count3464 evt_count96


* Experience stock variables
* Use deaths-based experience stock, as it has the expeccted <0 effect
local exp_stock1 exp_stock_deaths_t1
local exp_stock2 exp_stock_count_v64_t1

* Patent variable: regular variables (with different discount factors), placebo variable (all patents), nothing (to use only experience)
local pat_var1 pat_stock85_both_hvi_t1
local pat_var2 pat_stock85_both_t1
local pat_var3


local filename "deaths"
* Different regression and files for all patents and HVI patents
local output_file "`root'/analysis/regressions/`filename'"
* Create a file for every option
cap erase "`output_file'.txt"

forvalues p = 1/1 {
	* Define patent variable
	local pat_var `pat_var`p''
	
	forvalues i = 1/4 {
	* Exposition variables
		forvalues j = 1/2 {
		* Experience stock variables
			glm TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				f(poisson) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)
			
			zip TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				inf(event_count_v34) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)

			glm TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				f(nbinomial ml) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)
			
			zinb TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				inf(event_count_v34) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)
		}
	}
}


*== 2 - Regressions on the damages ($)

* Disaster variables
* Exposed assets that is close to the coastline
local dis_var1 assets34 assets6496
local dis_var2 assets3464 assets96
local dis_var3 evt_count34 evt_count6496
local dis_var4 evt_count3464 evt_count96

* Experience stock variables
local exp_stock1 exp_stock_deaths_t1
local exp_stock2 exp_stock_damages_t1

* Patent variable: regular variables (with different discount factors), placebo variable (all patents), nothing (to use only experience)
local pat_var1 pat_stock85_both_hvi_t1
local pat_var2 pat_stock85_both_t1
local pat_var3

local filename "damages"

* Different regression and files for all patents and HVI patents
local output_file "`root'/analysis/regressions/`filename'"
cap erase "`output_file'.txt"

forvalues p = 1/1 {		
	* Define patent variable
	local pat_var `pat_var`p''
	
	forvalues i = 1/4 {
	* Disaster variables
		forvalues j = 1/2 {
		* Experience stock variables
			glm TotalDamages_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				f(poisson) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)
			
			zip TotalDamages_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				inf(event_count_v34) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)

			glm TotalDamages_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				f(nbinomial ml) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)
			
			zinb TotalDamages_match_only i.country i.year log_gdp_pc log_pop `pat_var' `dis_var`i'' `exp_stock`j'', ///
				inf(event_count_v34) vce(cluster country) difficult nocons
			outreg2 using "`output_file'.xls", drop(i.country i.year)
		}
	}
}


*== 3 - Final regressions (baseline and alternatives)

* baseline - f: NBIN, pat_stock: HVI, exp_stock: deaths/damages, exposure: pop/assets_d5
local spec_deaths1 pat_stock85_both_hvi_t1 exp_stock_deaths_t1 pop3464_d5 pop96_d5
local spec_deaths2 pat_stock85_both_hvi_t1 exp_stock_deaths_t1 evt_count3464 evt_count96
local spec_deaths3 pat_stock85_both_hvi_t1 exp_stock_count_v64_t1 pop3464_d5 pop96_d5
local spec_deaths4 pat_stock_all_hvi_t1 exp_stock_deaths_t1 pop3464_d5 pop96_d5
local spec_deaths5 pat_stock85_both_t1 exp_stock_deaths_t1 pop3464_d5 pop96_d5

local spec_damages1 pat_stock85_both_hvi_t1 exp_stock_deaths_t1 assets3464 assets96
local spec_damages2 pat_stock85_both_hvi_t1 exp_stock_deaths_t1 evt_count3464 evt_count96
local spec_damages3 pat_stock85_both_hvi_t1 exp_stock_count_v64_t1 assets3464 assets96
local spec_damages4 pat_stock_all_hvi_t1 exp_stock_deaths_t1 assets3464 assets96
local spec_damages5 pat_stock85_both_t1 exp_stock_deaths_t1 assets3464 assets96

* Deaths
local filename "final_deaths_nbin"
local output_file "`root'/analysis/regressions/`filename'"
cap erase "`output_file'.txt"
forvalues i = 1/6 {
	glm TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths`i'', f(nbinomial ml) vce(cluster country) difficult nocons
	outreg2 using "`output_file'.xls", drop(i.country i.year)
}

* Damages
local filename "final_damages_nbin"
local output_file "`root'/analysis/regressions/`filename'"
cap erase "`output_file'.txt"
forvalues i = 1/6 {
	glm TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages`i'', f(nbinomial ml) vce(cluster country) difficult nocons
	outreg2 using "`output_file'.xls", drop(i.country i.year)
}

* Baseline with other estimators
local filename "final_other_estimators"
local output_file "`root'/analysis/regressions/`filename'"
cap erase "`output_file'.txt"
//zinb TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths1', inf(event_count_v34) vce(cluster country) difficult nocons
//outreg2 using "`output_file'.xls", drop(i.country i.year)
//zip TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths1', inf(event_count_v34) vce(cluster country) difficult nocons
//outreg2 using "`output_file'.xls", drop(i.country i.year)
glm TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths1', f(poisson) vce(cluster country) difficult nocons
outreg2 using "`output_file'.xls", drop(i.country i.year)
//zinb TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages1', inf(event_count_v34) vce(cluster country) difficult nocons
//outreg2 using "`output_file'.xls", drop(i.country i.year)
//zip TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages1', inf(event_count_v34) vce(cluster country) difficult nocons
//outreg2 using "`output_file'.xls", drop(i.country i.year)
glm TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages1', f(poisson) vce(cluster country) difficult nocons
outreg2 using "`output_file'.xls", drop(i.country i.year)

* Robustness test: drop countries
* Deaths
local filename "robustness_countries"
local output_file "`root'/analysis/regressions/`filename'"
cap erase "`output_file'.txt"
foreach c in "AUS" "CAN" "CHN" "DOM" "HND" "JPN" "KOR" "MEX" "NIC" "NZL" "PHL" "SLV" "USA" "VNM" {
	glm TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths1' if ISO != "`c'", f(nbinomial ml) vce(cluster country) difficult nocons 
	outreg2 using "`output_file'.xls", drop(i.country i.year) ctitle("`c' deaths")
}
foreach c in "AUS" "CAN" "CHN" "DOM" "HND" "JPN" "KOR" "MEX" "NIC" "NZL" "PHL" "SLV" "USA" "VNM" {
	glm TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages1' if ISO != "`c'", f(nbinomial ml) vce(cluster country) difficult nocons
	outreg2 using "`output_file'.xls", drop(i.country i.year) ctitle("`c' damages")
}

* With ZINB
//local filename "final_zinb"
//local output_file "`root'/analysis/regressions/`filename'"
//cap erase "`output_file'.txt"
//forvalues i = 1/6 {
//	zinb TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths`i'', inf(event_count_v34) vce(cluster country) difficult nocons
//	outreg2 using "`output_file'.xls", drop(i.country i.year)
//}
//forvalues i = 1/6 {
//	zinb TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages`i'', inf(event_count_v34) vce(cluster country) difficult nocons
//	outreg2 using "`output_file'.xls", drop(i.country i.year)
//}

* With ZIP
//local filename "final_zip"
//local output_file "`root'/analysis/regressions/`filename'"
//cap erase "`output_file'.txt"
//forvalues i = 1/6 {
//	zip TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths`i'', inf(event_count_v34) vce(cluster country) difficult nocons
//	outreg2 using "`output_file'.xls", drop(i.country i.year)
//}
//forvalues i = 1/6 {
//	zip TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages`i'', inf(event_count_v34) vce(cluster country) difficult nocons
//	outreg2 using "`output_file'.xls", drop(i.country i.year)
//}

* With poisson
local filename "final_pois"
local output_file "`root'/analysis/regressions/`filename'"
cap erase "`output_file'.txt"
forvalues i = 1/6 {
	glm TotalDeaths_match_only i.country i.year log_gdp_pc log_pop `spec_deaths`i'', f(poisson) vce(cluster country) difficult nocons
	outreg2 using "`output_file'.xls", drop(i.country i.year)
}
forvalues i = 1/6 {
	glm TotalDamages_match_only i.country i.year log_gdp_pc log_pop `spec_damages`i'', f(poisson) vce(cluster country) difficult nocons
	outreg2 using "`output_file'.xls", drop(i.country i.year)
}


