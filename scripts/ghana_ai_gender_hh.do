

//Gender of hh head, between countries//

#delimit;
local PR_survey_list "
GHPR70FL.DTA
GHPR5AFL.DTA
GHPR4BFL.DTA
GHPR41FL.DTA
GHPR31FL.DTA
";    
                                                
#delimit cr;                               

foreach x of local PR_survey_list {
cd "\\gess-fs.d.ethz.ch\home$\tsamuel\Desktop\PR_GHANA"
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



*****HI in wealth by  gender of hh head*********************************************************************************************
use ai_`y', clear

*Select categorical variable of interest
tab hv219   //DHS variable for gender of household member
tab hv219, nol
drop if hv219>2

gen gender_hh =.
label variable gender_hh "gender of hh head"
replace gender_hh = hv219

*Generate group id's
egen g_id = group(gender_hh) 
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
collapse w_grp_ai_mean hv007 g_shr, by(g_id)
gen n_grp = _N
label variable n_grp "number of groups"

gen y = w_grp_ai_mean
label variable y "average asset index by group"

**HI with population weights
gen sum = .
local sum = 0
local i_max = _N
forvalues i = 1/`i_max' {
      forvalues j = 1/`i_max' {
           local sum = `sum' + g_shr[`i']*g_shr[`j']*abs(y[`i']-y[`j'])
                 }
     replace sum = `sum' in `i'
}
generate doublesum = sum[_N]
label variable doublesum "double summation"

gen mu = g_shr*y
label variable mu "population-weighted group asset index"

egen overall_mu = total(mu)
label variable overall_mu "population mean asset index"

*Generate weights for relative and absolute Gini
generate weight_rel = 1/(2*(overall_mu))
label variable weight_rel "weight for relative Gini"

generate weight_abs = (1/2)
label variable weight_abs "weight for absolute Gini"

gen ggini_rel = 100*weight_rel*doublesum    //normalize by multiplying with 100.
label variable ggini_rel "Group-based relative Gini Index"

gen ggini_abs = 100*weight_abs*doublesum    //normalize by multiplying with 100.
label variable ggini_abs "Group-based absolute Gini Index"

*Obtain results for HI and also the number of groups
display ggini_rel
tab ggini_rel //Relative Gini

display ggini_abs
tab ggini_abs    //Absolute Gini


generate str country_code = substr("`x'",1,4)
generate str measure ="Weighted"
generate str category = "gender_hh"
gen str match = "btwn"
gen str note = "all 10 assets/deprivations"

sort g_id

gen m_wealth = w_grp_ai_mean[1]
label var m_wealth "wealth index of male-headed households"

gen f_wealth = w_grp_ai_mean[2]
label var f_wealth "wealth index of female-headed households"


gen m_shr = g_shr[1]
label var m_shr "share of male-headed households"

gen f_shr = g_shr[2]
label var f_shr "share of female-headed households"

export excel country_code measure category hv007 ggini_abs ggini_rel overall_mu m_wealth m_shr f_wealth f_shr match note in 1 using "\\gess-fs.d.ethz.ch\home$\tsamuel\Desktop\PR_GHANA\results.xls", sheet("sam") firstrow(variables) replace 
import excel "\\gess-fs.d.ethz.ch\home$\tsamuel\Desktop\PR_GHANA\results.xls", sheet("sam") firstrow clear
_getfilename `x'

local z = r(filename)
save gender_hh_ai_btwn_wgt_`z', replace

}
