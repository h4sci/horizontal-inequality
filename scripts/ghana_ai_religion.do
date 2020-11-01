
set more off
global dir `"L:\research\Data\samuel\HI Paper\Analysis_of_Results"'

#delimit;
local PR_MR_IR_survey_list "
ghana_ai_men&women_2014.dta
ghana_ai_men&women_2008.dta
ghana_ai_men&women_2003.dta
ghana_ai_men&women_1998.dta
ghana_ai_men&women_1993.dta
";    
  
#delimit cr;  

*******************HI by religion*************************************
foreach x of local PR_MR_IR_survey_list {


cd `"${dir}\Ghana\ghana_data"'

use `x', clear
_getfilename `x'

gen double hh_id = hv001*10000+hv002
format hh_id %30.0g

sort hh_id
by hh_id: gen person_id=_n

generate ai_ele=hv206== 1
replace ai_ele = . if hv206==.

generate ai_rad=hv207== 1
replace ai_rad = . if hv207==.

generate ai_tv=hv208== 1
replace ai_tv = . if hv208==.

generate ai_fri = hv209 == 1
replace ai_fri = . if hv209==.

generate ai_bik = hv210 != 1
replace ai_bik = . if hv210==.

generate ai_mot =(hv211 == 1 | hv212 == 1)
replace ai_mot =. if (hv211 == . & hv212 == .)

gen ai_pdw=(hv201==11| hv201==12)
replace ai_pdw=. if hv201==. | hv201==96

generate ai_sdw =(hv201<30 | hv201>70) 
replace ai_sdw=. if hv201==. | hv201==96

*generate ai_sdw =(hv201>=30 & hv201<=70) 
*replace ai_sdw=. if hv201==. | hv201==96

gen ai_not = (hv205 != 31)
replace ai_not=. if hv205==. | hv205==96

generate ai_lfm = (hv213<10 | hv213>30)
replace ai_lfm=. if hv213==. | hv213==96

gen splwt=round(hv005/1000)

factor ai_* [fweight=splwt], factors(1) pcf
predict ai


* Weights: Total means
factor ai_ele ai_rad ai_tv ai_fri ai_bik ai_mot ai_pdw ai_sdw ai_not ai_lfm  [weight=hv005], factors(1) pcf

matrix factor=e(L)
matlist factor

gen ai_pooled=ai_ele*factor[1,1]+ai_rad*factor[2,1]+ai_tv*factor[3,1]+ai_fri*factor[4,1]+ai_bik*factor[5,1]+ai_mot*factor[6,1]+ai_pdw*factor[7,1]+ai_sdw*factor[8,1]+ai_not*factor[9,1]+ai_lfm*factor[10,1]

* test with factor analysis
factor ai_ele ai_rad ai_tv ai_fri ai_bik ai_mot ai_pdw ai_sdw ai_not ai_lfm  [weight=hv005], factors(1)

matrix factor=e(L)
matlist factor

gen ai_factor=ai_ele*factor[1,1]+ai_rad*factor[2,1]+ai_tv*factor[3,1]+ai_fri*factor[4,1]+ai_bik*factor[5,1]+ai_mot*factor[6,1]+ai_pdw*factor[7,1]+ai_sdw*factor[8,1]+ai_not*factor[9,1]+ai_lfm*factor[10,1]
replace ai_factor = uniform()*0.0001 + ai_factor
label variable ai_factor "asset index"

*kdensity ai_factor
drop if ai_factor==.

replace ai= ai_factor

capture drop sw
gen sw=hv005/1000000
desc sw
summ sw

svyset [pweight=sw], psu(hv021)
rename sw wgt


local y = r(filename)
save ai_`y', replace


*****HI in wealth by religion*********************************************************************************************
use ai_`y', clear

*Select categorical variable of interest
tab religion 

tab rel
gen rel ="."
label variable rel "religious group" 

**************************************************
replace rel = "Christian" if religion=="catholic" | religion=="anglican"  | religion=="methodist" | religion=="presbyterian" | religion=="pentecostal/charismatic" ///
	| religion=="other christian" | religion=="roman catholic" | religion=="protestant"
replace rel = "Muslim" if religion=="islam" | religion=="moslem"  | religion=="muslim"
replace rel = "Other" if religion=="no religion"  | religion=="other"  | religion=="no religion + other" | religion=="traditional/spiritualist" | religion=="traditional"  | religion=="spiritualist"
***************************************
drop if rel=="."

*Generate group id's
egen g_id = group(rel) 
sort g_id

drop if ai==.
drop if g_id==.

*Now obtain the mean asset index by each group. Since egen command does not support sampling weights, I execute this task manually in the following Stata codes. 
gen w_ai=wgt*ai 
label variable w_ai "weighted asset index"

egen grp_tot_wgt = total(wgt),by(g_id)  
label variable grp_tot_wgt "total group weight"

egen w_grp_ai=total(w_ai), by(g_id) 
label variable w_grp_ai "sum of weighted asset index"
  
gen w_grp_ai_mean = w_grp_ai/grp_tot_wgt
label variable w_grp_ai_mean "mean of weighted asset index"

*Calculate group weights, ie, share of each group in the total population
egen g_obs = total(wgt),by(g_id)
label variable g_obs "representative number of group obs"

egen t_obs = total(wgt)  // Alternatively: gen t_obs = _N (supposing no obs has been dropped at all).
label variable t_obs "total number of obs"

gen g_shr = g_obs/t_obs
label variable g_shr "share of group in population"

*Collapse data to reduce it to what is relevant for the calculation of HI
collapse w_grp_ai_mean survey_year g_obs g_shr, by(g_id)
gen n_grp = _N
label variable n_grp "number of groups"

gen n_rel1 = g_obs[1]
gen n_rel2 = g_obs[2]
gen n_rel3 = g_obs[3]
*gen n_rel4 = g_obs[4]

gen y = w_grp_ai_mean
label variable y "average asset index by group"

gen wlth_rel1 = y[1]
label var wlth_rel1 "mean wealth index for religion 1"

gen wlth_rel2 = y[2]
label var wlth_rel2 "mean wealth index for religion 2"

capture gen wlth_rel3 = y[3]
capture label var wlth_rel3 "mean wealth index for religion 3"

capture gen wlth_rel4 = y[4]
capture label var wlth_rel4 "mean wealth index for religion 4"

preserve
**HI with population weights
ineqdeco y [aw=g_shr]

gen gini_wlth = 100*r(gini)
gen theil_wlth =r(ge1)
gen cov_wlth=2*sqrt(r(ge2))
gen wlth = r(mean)


generate str country_code = substr("`x'",1,4)
generate str measure ="Weighted"
generate str category = "religion"
rename n_grp n_rel_grps

gen str stand_rel = "yes"
lab var stand_rel "standardized religion"

gen str note = "Christian, Muslim, Other" 
lab var note "list of religions"

export excel country_code category measure survey_year gini_wlth theil_wlth cov_wlth wlth n_rel_grps stand_rel note n_rel* wlth_rel* in 1 using `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow(variables) replace 

import excel `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow clear
_getfilename `x'

local z = r(filename)
save "temp_ai_data_folder\nr_religion_wgt_`z'", replace

restore

**HI without population weights
ineqdeco y [aw=1]

gen gini_wlth = 100*r(gini)
gen theil_wlth =r(ge1)
gen cov_wlth=2*sqrt(r(ge2))
gen wlth = r(mean)


generate str country_code = substr("`x'",1,4)
generate str measure ="Unweighted"
generate str category = "religion"
rename n_grp n_rel_grps

gen str stand_rel = "yes"
lab var stand_rel "standardized religion"

gen str note = "Christian, Muslim, Other" 
lab var note "list of religions"

export excel country_code category measure survey_year gini_wlth theil_wlth cov_wlth wlth n_rel_grps stand_rel note n_rel* wlth_rel* in 1 using `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow(variables) replace 

import excel `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow clear
_getfilename `x'

local z = r(filename)
save "temp_ai_data_folder\nr_religion_nowgt_`z'", replace
}
