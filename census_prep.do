clear all 
set more off

use "$wd\data\exclusion\Indicadores.dta", clear

replace id_s = floor(id_s / 100000)
keep if year==2021
rename id_s ine
preserve
keep ine z1h_nacimiento_esp-z1t_edad_tot z2pop_total z2total_viv-z2viv_9_o_mas_hab z3pob z4h_nacionalidad_cont_afr-z4t_nacionalidad_ue_nor_y_uk
collapse (sum) z1h_nacimiento_esp-z1t_edad_tot z2pop_total z2total_viv-z2viv_9_o_mas_hab z3pob z4h_nacionalidad_cont_afr-z4t_nacionalidad_ue_nor_y_uk, by(ine)
save "$wd\data\temp.dta", replace
restore
keep ine year z2pop_total z2edad_media z3renta_bruta_mean_h-z3hog_uni z3pob_esp-z3t_ingresos_uc_menor_60p
collapse (mean) year z2edad_media z3renta_bruta_mean_h-z3hog_uni z3pob_esp-z3t_ingresos_uc_menor_60p [aweight=z2pop_total], by(ine)
merge 1:1 ine using "$wd\data\temp.dta", nogen
erase "$wd\data\temp.dta"

save "$wd\data\census_2021.dta", replace

import excel "$wd\data\37677.xlsx", sheet("tabla-37677") cellrange(A7:Q55652) firstrow clear

keep ÍndicedeGini DistribucióndelarentaP80P20 A
drop in 1/1
drop in 55638/55644

replace ÍndicedeGini="" if ÍndicedeGini==".."
replace DistribucióndelarentaP80P20="" if DistribucióndelarentaP80P20==".."

destring ÍndicedeGini, replace
destring DistribucióndelarentaP80P20, replace
gen ine = substr(A, 1, strpos(A, " ") - 1)
destring ine, replace
drop if ine>=100000
drop A

save "$wd\data\distr_2022.dta", replace

import excel "$wd\data\30824.xlsx", sheet("tabla-30824") cellrange(A7:AW55652) firstrow clear

keep A Rentanetamediaporpersona Rentanetamediaporhogar Mediadelarentaporunidadde Medianadelarentaporunidadd Rentabrutamediaporpersona Rentabrutamediaporhogar
drop in 1/1

foreach var in Rentanetamediaporpersona Rentanetamediaporhogar Mediadelarentaporunidadde Medianadelarentaporunidadd Rentabrutamediaporpersona Rentabrutamediaporhogar {
	replace `var'="" if `var'==".."
	destring `var', replace
}
gen ine = substr(A, 1, strpos(A, " ") - 1)
destring ine, replace
drop if ine>=100000
drop A

save "$wd\data\income_2022.dta", replace

import excel "$wd\data\30832.xlsx", sheet("tabla-30832") cellrange(A7:BE55646) firstrow clear

keep A Edadmediadelapoblación Porcentajedepoblaciónmenorde Porcentajedepoblaciónde65y Tamañomediodelhogar Porcentajedehogaresunipersona Población Porcentajedepoblaciónespañola
drop in 1/1

foreach var in Edadmediadelapoblación Porcentajedepoblaciónmenorde Porcentajedepoblaciónde65y Tamañomediodelhogar Porcentajedehogaresunipersona Población Porcentajedepoblaciónespañola {
	replace `var'="" if `var'==".."
	destring `var', replace
}
gen ine = substr(A, 1, strpos(A, " ") - 1)
destring ine, replace
drop if ine>=100000
drop A

save "$wd\data\pop_2022.dta", replace
