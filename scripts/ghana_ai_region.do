
set more off
global dir `"L:\research\Data\samuel\HI Paper\Analysis_of_Results"'


#delimit;
local PR_survey_list "
Ghana_pr_2014_pooled.dta
Ghana_pr_2003_pooled.dta
Ghana_pr_1998_pooled.dta
Ghana_pr_1993_pooled.dta
Ghana_pr_2008_pooled.dta
";    
                                                
#delimit cr;                               

foreach x of local PR_survey_list {

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

preserve
/////////////////////////////////////////////////////////////////
*Obtain VI in wlth

duplicates drop

capture corr ai hv271
capture gen corr = r(rho)
lab var corr "Wealth index - Correlation with DHS wealth index"

ineqdeco ai [aw=wgt]

gen VI_wlth_gini = 100*r(gini)
gen VI_wlth_theil =r(ge1)
gen VI_wlth_cov=2*sqrt(r(ge2))
gen VI_wlth = r(mean)

generate str country_code = substr("`x'",1,4)

export excel country_code hv007 VI_wlth_gini VI_wlth_theil VI_wlth_cov VI_wlth corr in 1 using `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow(variables) replace 
import excel `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow clear

_getfilename `x'

local z = r(filename)

save "temp_ai_data_folder\VI_wlth_`z'", replace
////////////////////////////////////////////////////////////
restore


local y = r(filename)
save ai_`y', replace


*****HI in wealth by region*********************************************************************************************
use ai_`y', clear

**Standardize regions across surveys
gen region="."
label variable region "administrative region"

************************************************************************************************
replace region="Ashanti" if region_3=="ashanti" | region_3== "ashanti region"  
replace region="Brong Ahafo" if region_3=="brong ahafo" | region_3=="brong ahafo region" | region_3=="brong-ahafo"  
replace region="Central" if region_3=="central" | region_3=="central region"  
replace region="Eastern" if region_3=="eastern" | region_3=="eastern region"  
replace region="Greater Accra" if region_3=="greater accra" | region_3=="greater accra region"  
replace region="Northern" if region_3=="northern" | region_3=="northern region"  
replace region="Upper East" if region_3=="upper east" | region_3=="upper east region"  
replace region="Upper Eest" if region_3=="upper west" | region_3=="upper west region"  
replace region="Volta" if region_3=="volta" | region_3=="volta region"  
replace region="Western" if region_3=="western" | region_3=="western region"   
****************************************************************************************** 

*Select categorical variable of interest
tab region   
drop if region=="."

*Generate group id's
egen g_id = group(region) 
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
collapse w_grp_ai_mean hv007 g_obs g_shr, by(g_id)
gen n_grp = _N
label variable n_grp "number of groups"

gen n_reg1 = g_obs[1]
gen n_reg2 = g_obs[2]
gen n_reg3 = g_obs[3]
gen n_reg4 = g_obs[4]
gen n_reg5 = g_obs[5]
gen n_reg6 = g_obs[6]
gen n_reg7 = g_obs[7]
gen n_reg8 = g_obs[8]
gen n_reg9 = g_obs[9]
gen n_reg10 = g_obs[10]

gen y = w_grp_ai_mean
label variable y "average asset index by group"

preserve
**HI with population weights
ineqdeco y [aw=g_shr]

gen gini_wlth = 100*r(gini)
gen theil_wlth =r(ge1)
gen cov_wlth=2*sqrt(r(ge2))
gen wlth = r(mean)

generate str country_code = substr("`x'",1,4)
generate str measure ="Weighted"
generate str category = "region"
rename n_grp n_regions
gen str note = "Ashanti, Brong Ahafo, Central, Eastern, Greater Accra, Northern, Upper East, Upper West, Volta, Western" 
gen str stand_reg = "yes"
lab var stand_reg "standardized region"

gen str match = "btwn"

export excel country_code category measure hv007 gini_wlth theil_wlth cov_wlth wlth n_regions stand_reg note match n_reg* in 1 using `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow(variables) replace 

import excel `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow clear
_getfilename `x'

local z = r(filename)
save "temp_ai_data_folder\nr_region_wgt_`z'", replace

restore

**HI with population weights
ineqdeco y [aw=1]

gen gini_wlth = 100*r(gini)
gen theil_wlth =r(ge1)
gen cov_wlth=2*sqrt(r(ge2))
gen wlth = r(mean)

generate str country_code = substr("`x'",1,4)
generate str measure ="Unweighted"
generate str category = "region"
rename n_grp n_regions
gen str note = "Ashanti, Brong Ahafo, Central, Eastern, Greater Accra, Northern, Upper East, Upper West, Volta, Western" 
gen str stand_reg = "yes"
lab var stand_reg "standardized region"

gen str match = "btwn"

export excel country_code category measure hv007 gini_wlth theil_wlth cov_wlth wlth n_regions stand_reg note match n_reg* in 1 using `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow(variables) replace 

import excel `"${dir}\Ghana\ghana_data\temp_ai_data_folder\results.xls"', sheet("sam") firstrow clear
_getfilename `x'

local z = r(filename)
save "temp_ai_data_folder\nr_region_nowgt_`z'", replace
}

