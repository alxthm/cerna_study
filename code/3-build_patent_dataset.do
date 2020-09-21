*==
*== Tropical cyclones adaptation
*==

*== Data processing
*== Merge patent data from Simon into a single dataset with patent counts and patent stocks (1980-2015), for
*== - all patents filed & HVI patents only (HVI patents received by the country and invented by the country — usually but not necessarily filed here)
*== - adaptation patents (Y02A) for storm related technologies or all patents (all technologies, all categories)
*== Also provide control data (gdp/capita, population)


*== 1. Load invention patents dataset and save for later merge
*== nb_inv_adapt/all : Number of inventions made by the country. They are not necessarily filed in the country, although it's mostly the case
*== nb_hvi_adapt/all : Number of HVI inventions made by the country, i.e. inventions filed in at least 2 countries
*== 
*== adapt/all refers to the patent category considered: adaptation patents (i.e. in the Y02A category) or patents in all categories.
*== For hazard=All, adapt refers to all Y02A patents, and all refers to all patents in all categories
*== For hazard=Storms or Precipitation, adapt refers to Y02A patents in sub categories related to storm impact mitigation, while all refers to patents
*==  with technologies often found in the adapt patents (e.g. building in general, etc), but not (or not necessarily?) in the Y02A category

local root "/Users/alexandre/development/work/cerna"

use "`root'/data/raw/inv_data_SIM_17_08.dta", clear
drop invt_country
rename (invt_iso appln_year) (ISO year)
* Drop duplicates (there are very few cases, for countries that we don't use anyway, so simply keep the first value)
quietly by technology hazard ISO year: gen dup=cond(_N==1,0,_n)
drop if dup>1
drop dup
* Replace NA values with 0
foreach x of varlist nb_inv_adapt nb_hvi_adapt nb_inv_all nb_hvi_all {
	replace `x' = 0. if `x' == .
}
save hvi_patents, replace



*== 2. Load patent and control data (namely GDP/capita, population data)
*== adapt/all_filed_year : Total number of patents (=inventions) filed in the country during the year. This includes patents made in the country, and 
*== received from another country
*== adapt/all_rec_year : Number of patents received by the country (i.e. patents filed in the country, but invented in another country)

use "`root'/data/raw/patent_data_SIM_28_07.dta", clear
rename (patent_office_iso appln_year) (ISO year)

keep if technology == "Y02A" & (hazard == "Storms" | hazard == "Precipitation" | hazard == "All")
keep if year <= 2015 & year >= 1980
keep technology hazard ISO patent_office_name year gdp_office gdp_pc_office pop_office adapt_filed_year all_filed_year adapt_rec_year all_rec_year
sort ISO year

* Target and drop countries for which there is at least one missing value (in 1990-2015, where we will use it) for
** the number of adaptation patents invented 
gen byte x= 1 if adapt_filed_year ==. & year >= 1990
by ISO: egen miss = sum(x)
drop if miss > 0
drop x miss
** the value of the gdp_pc
gen byte x= 1 if gdp_pc_office ==. & year >= 1990
by ISO: egen miss = sum(x)
drop if miss > 0
drop x miss

* Drop Czech Republic (CZE) duplicate (exists both as Czechia and Czech Republic)
drop if patent_office_name=="Czechia"



*== 3. Merge HVI patent data with master dataset, then compute useful indicators
merge 1:1 technology hazard ISO year using hvi_patents
sort ISO year
keep if _merge==3 // match only
drop _merge patent_office_name
keep ISO year hazard gdp_pc_office pop_office all_filed_year adapt_filed_year nb_hvi_all nb_hvi_adapt all_rec_year adapt_rec_year

* Scale patent count down to have more readable coefs in the regression
foreach x of varlist all_filed_year adapt_filed_year nb_hvi_all nb_hvi_adapt all_rec_year adapt_rec_year {
	replace `x' = `x' / 1e3
}

* Compute patent count (storms and precipitations)
*= All patents filed in the country, all categories
egen pat_count_all = sum(all_filed_year * (hazard=="All")), by(ISO year)
*= All adaptation patents filed in the country, using technologies related to storm impact mitigation
egen pat_count_both = sum(adapt_filed_year * (hazard=="Storms" | hazard=="Precipitation")), by(ISO year)
egen pat_count_storms = sum(adapt_filed_year * (hazard=="Storms")), by(ISO year)
egen pat_count_prec = sum(adapt_filed_year * (hazard=="Precipitation")), by(ISO year)

*= Approximately all high value patents (i.e. filed at least in 2 countries), all categories/technologies.
*= Exactly: HVI patents invented by the country (almost always filed in the country) + (almost always HVI) patents received
egen pat_count_all_hvi = sum((nb_hvi_all + all_rec_year) * (hazard=="All")), by(ISO year)
*== Approximately HVI patents using technologies related to storm impact mitigation
egen pat_count_both_hvi = sum((nb_hvi_adapt + adapt_rec_year) * (hazard=="Storms" | hazard=="Precipitation")), by(ISO year)
egen pat_count_storms_hvi = sum((nb_hvi_adapt + adapt_rec_year) * (hazard=="Storms")), by(ISO year)
egen pat_count_prec_hvi = sum((nb_hvi_adapt + adapt_rec_year) * (hazard=="Precipitation")), by(ISO year)

quietly by ISO year: gen dup=cond(_N==1,0,_n)
drop if dup>1
drop dup hazard all_filed_year adapt_filed_year nb_hvi_all nb_hvi_adapt all_rec_year adapt_rec_year

* Build patent stocks iteratively, with different discount factors (default is 0.85)
gen pat_stock_all = pat_count_all
gen pat_stock85_both = pat_count_both
gen pat_stock70_both = pat_count_both
by ISO: replace pat_stock_all = pat_count_all + 0.85 * pat_stock_all[_n-1] if _n > 1
by ISO: replace pat_stock85_both = pat_count_both + 0.85 * pat_stock85_both[_n-1] if _n > 1
by ISO: replace pat_stock70_both = pat_count_both + 0.70 * pat_stock70_both[_n-1] if _n > 1
* and for HVI patents
gen pat_stock_all_hvi = pat_count_all_hvi
gen pat_stock85_both_hvi = pat_count_both_hvi
gen pat_stock70_both_hvi = pat_count_both_hvi
by ISO: replace pat_stock_all_hvi = pat_count_all_hvi + 0.85 * pat_stock_all_hvi[_n-1] if _n > 1
by ISO: replace pat_stock85_both_hvi = pat_count_both_hvi + 0.85 * pat_stock85_both_hvi[_n-1] if _n > 1
by ISO: replace pat_stock70_both_hvi = pat_count_both_hvi + 0.70 * pat_stock70_both_hvi[_n-1] if _n > 1


save "`root'/data/processed/patent_dataset.dta", replace
