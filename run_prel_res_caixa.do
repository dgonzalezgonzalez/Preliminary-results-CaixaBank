**************************************************
**************** CaixaBank Data ******************
**************************************************

clear all
global wd "Q:\PIFIN\CaixaBank\Diego"

/// Selection of outcome variables:

global vars "personasatendidas reintegros m ingresos o impuestos q traspasos s opdivisa u impuestosaeat w chequespropios y tributos aa chequesajenos ac transferencias ae resto apertctacorriente apertvalores apertfondoinvers aperturatarjetas aperturaseguros altaprodactivo persatendidas an ao impuestorecibos aq ar as restooperaciones au clientescbk clientescbk65"
global vars1 "personasatendidas reintegros m ingresos o traspasos s chequespropios y chequesajenos"
global vars2 "ac transferencias ae resto persatendidas an ao restooperaciones au"
global vars3 "personasatendidas reintegros m ingresos o traspasos s chequespropios y chequesajenos ac transferencias ae resto"
global vars4 "persatendidas an ao restooperaciones au"
global vars5 "pers_tot reint_n_tot reint_e_tot ingr_n_tot ingr_e_tot tras_n_tot tras_e_tot"
global vars6 "check_n_tot check_e_tot trans_n_tot trans_e_tot rest_n_tot rest_e_tot"
global vars7 "reint_e_n ingr_e_n tras_e_n check_e_n trans_e_n"

/// Prepare latest merged dta:

cd "$wd\data"

local archivos : dir . files "Informe GenCAT 202*_sent.xlsx"
local periodos
foreach archivo of local archivos {
	local num = substr("`archivo'", 16, 6)
	local periodos `periodos' `num'
}
local max = `num'
cd "$wd"

local months "Dic'24 _Ene'25 _Feb'25 _Mar'25 _Abr25 _May25"
if `max'<202502 local months "Dic _Ene"
local n=1
foreach month of local months {
	capture {
		import excel "$wd\data\Informe GenCAT `max'_sent.xlsx", sheet("Calendario`month'") firstrow case(lower) clear
		if "`month'"!="_May25" {
			rename codiine ine
		}
		rename ofibús ofibus
		keep ine ofibus horadinici fin tiempodeatención diadepas
		gen j=.
		levelsof (ine), local (ine_values)
		foreach val of local ine_values {
			sum diadepas if ine==`val'
			if r(min)==r(max) {
				replace j=1 if ine==`val'
			}
			else {
				replace j=1 if ine==`val' & diadepas==r(min)
				replace j=2 if ine==`val' & diadepas==r(max)
			}
		}
		missings dropobs, force
		reshape wide ofibus horadinici fin tiempodeatención diadepas, i(ine) j(j)
		gen wave=`n'
		save "$wd\data\ofibus_`n'.dta", replace
		local ++n
	}
	if _rc!=0 {
		continue
		local ++n
	}
}

local periodos1
foreach archivo of local archivos {
	local num = substr("`archivo'", 16, 6)
	if `num'>=202506 local periodos1 `periodos1' `num'
}
local max1 = `num'

foreach month of local periodos1 { // This loop will only work if all ofibus-related sheets after May 2025 are provided in the same format every month. Otherwise, the code should be changed.
	local anio = substr("`month'", 3, 2)
	local mesnum = substr("`month'", 5, 2)
	local mes = word("Ene Feb Mar Abr May Jun Jul Ago Sep Oct Nov Dic", `mesnum')
	import excel "$wd\data\Informe GenCAT `month'_sent.xlsx", sheet("Calendario_`mes'`anio'") firstrow case(lower) clear
	rename cod_ine ine
	rename hora_inicio_operacion horadinici
	rename hora_fin fin
	rename tiempo_de_atencion tiempodeatención
	rename dia_de_pase diadepas
	keep ine ofibus horadinici fin tiempodeatención diadepas
	gen j=.
	levelsof (ine), local (ine_values)
	foreach val of local ine_values {
		sum diadepas if ine==`val'
		if r(min)==r(max) {
			replace j=1 if ine==`val'
		}
		else {
			replace j=1 if ine==`val' & diadepas==r(min)
			replace j=2 if ine==`val' & diadepas==r(max)
		}
	}
	missings dropobs, force
	reshape wide ofibus horadinici fin tiempodeatención diadepas, i(ine) j(j)
	gen wave=`n'
	capture {
		foreach var in horadinici1 fin1 horadinici2 fin2 {
			gen `var'_num=clock(`var', "hm")
			format `var'_num %tcHH:MM
			drop `var'
			rename `var'_num `var'
		}
	}
	if _rc!=0 {
		save "$wd\data\ofibus_`n'.dta", replace
		local ++n
		continue
	}
	save "$wd\data\ofibus_`n'.dta", replace
	local ++n
}

use "$wd\data\ofibus_1.dta", clear
local n1=`n'-1
forvalues i=2(1)`n1' {
	append using "$wd\data\ofibus_`i'.dta"
}

save "$wd\data\ofibus_merged.dta", replace

import excel "$wd\data\Informe GenCAT 202508_sent.xlsx", sheet("Formación_Nov'24") cellrange(B2:K22) firstrow case(lower) clear

rename codmunine ine
rename asistentes asistentes1
label variable asistentes1 "Asistentes formación Nov. 2024"
keep ine asistentes1
	missings dropobs, force
save "$wd\data\info_1.dta", replace

if `max'>=202502 {
	import excel "$wd\data\Informe GenCAT 202508_sent.xlsx", sheet("Formación_Feb25") cellrange(B2:K17) firstrow case(lower) clear

	rename codmunicine ine
	rename asistentes asistentes2
	label variable asistentes2 "Asistentes formación Feb. 2025"
	keep ine asistentes2
	missings dropobs, force
	save "$wd\data\info_2.dta", replace
}

clear all

local i=1
foreach n of local periodos {
	import excel "$wd\data\Informe GenCAT `max'_sent.xlsx", sheet("OUTPUT_`n'") cellrange(B7:AU169) firstrow case(lower)

	foreach var in $vars {
		capture confirm string variable `var'
		if _rc==0 {
			replace `var'="" if `var'=="-"
			destring `var', replace
		}
		rename `var' `var'`i'
	}

	save "$wd\data\output_`n'.dta", replace

	clear all
	local ++i
}

use "$wd\data\output_`max'.dta"

foreach n of local periodos {
	if `n'<`max' {
		merge 1:1 ine using "$wd\data\output_`n'.dta", nogen
	}
}

reshape long $vars, i(ine) j(wave)

label define wave 1 "Wave Dec. 2024" 2 "Wave Jan. 2025" 3 "Wave Feb. 2025" 4 "Wave Mar. 2025" 5 "Wave Apr. 2025" 6 "Wave May 2025" 7 "Wave Jun. 2025" 8 "Wave Jul. 2025" 9 "Wave Aug. 2025" // Change if wanted, not necessary for estimations.
label values wave wave

merge 1:1 ine wave using "$wd\data\ofibus_merged.dta", nogen
merge m:1 ine using "$wd\data\info_1.dta", nogen
merge m:1 ine using "$wd\data\info_2.dta", nogen

sum wave
local max_w=r(max)
forvalues n=1(1)`max_w' {
	local m=ceil(`n'/7)
	global wavelist_`m'
	global wavelist_lab_`m'
}

sum wave
local max_w=r(max)
forvalues n=1(1)`max_w' {
	local m=ceil(`n'/7)
	global wavelist_`m' ${wavelist_`m'} `n'.wave#c.treat1 `n'.wave#c.treat2
}

forvalues n=1(1)`max_w' {
	local m=`n'-1
	local k=ceil(`n'/7)
	global wavelist_lab_`k' ${wavelist_lab_`k'} `n'.wave#c.treat1 "Tratado (doble ofibus) \times I(\text{mes}=`m')" `n'.wave#c.treat2 "Tratado (información) \times I(\text{mes}=`m')"
}

rename asignación asignacion
replace asignacion="Primera ronda formación" if asignacion=="1ª ronda formación Nov'24"
replace asignacion="Segunda ronda formación" if asignacion=="2ª ronda formación Feb'25"

label variable personasatendidas "Personas atendidas (\#) ARE"
label variable reintegros "Reintegros (\#)"
label variable m "Reintegros (\euro) ARE"
label variable ingresos "Ingresos (\#) ARE"
label variable o "Ingresos (\euro) ARE"
label variable traspasos "Traspasos (\#) ARE "
label variable ar "Traspasos (\#) Cajero "
label variable s "Traspasos (\euro) ARE"
label variable as "Traspasos (\euro) Cajero"
label variable chequespropios "Cheques propios (\#) ARE"
label variable y "Cheques propios (\euro) ARE"
label variable chequesajenos "Cheques ajenos (\#) ARE"
label variable ac "Cheques ajenos (\euro) ARE"
label variable transferencias "Transferencias (\#) ARE"
label variable ae "Transferencias (\euro) ARE"
label variable resto "Resto (\#) ARE"
label variable persatendidas "Personas atendidas (\#) Cajero"
label variable an "Reintegros (\#) Cajero"
label variable ao "Reintegros (\euro) Cajero"
label variable restooperaciones "Resto operaciones (\#) Cajero"
label variable au "Resto operaciones (\euro)"

gen reintegros_mean=m/reintegros
gen ingresos_mean=o/ingresos
gen traspasos_mean=s/traspasos
gen cheqaj_mean=ac/chequesajenos
gen trans_mean=ae/transferencias
gen rntg_caj_mean=ao/an
gen resto_caj_mean=au/restooperaciones

gen pers_tot=personasatendidas+persatendidas
gen reint_n_tot=reintegros+an
gen reint_e_tot=m+ao
gen ingr_n_tot=ingresos
gen ingr_e_tot=o
gen tras_n_tot=traspasos+ar
gen tras_e_tot=s+as
gen check_n_tot=chequespropios+chequesajenos
gen check_e_tot=y+ac
gen trans_n_tot=transferencias
gen trans_e_tot=ae
gen rest_n_tot=restooperaciones+resto
gen rest_e_tot=au

foreach y in reint ingr tras check trans {
	gen `y'_e_n=`y'_e_tot/`y'_n_tot
}
*We will calculate the days between ofibuses.
gen dias_treat2_ofibus = diadepas2 - diadepas1 if !missing(diadepas2)
gen dia_ultimo_bus = diadepas2
replace dia_ultimo_bus = diadepas1 if asignacion!="doble ofibus"
format dia_ultimo_bus %td
gen dia_primer_bus = diadepas1 
format dia_primer_bus %td

gen treat=1
replace treat=0 if asignacion=="Control" | (asignacion=="Segunda ronda formación" & wave<3)
gen treat1=1 if asignacion=="doble ofibus"
replace treat1=0 if asignacion=="Control" | asignacion=="Segunda ronda formación" | asignacion=="Primera ronda formación"
gen treat2=1 if asignacion=="Primera ronda formación" | (asignacion=="Segunda ronda formación" & wave>=3)
replace treat2=0 if asignacion=="Control" | (asignacion=="Segunda ronda formación" & wave<3) | asignacion=="doble ofibus"

save "$wd\data\output_merged.dta", replace

/// Preliminary results:

* Descriptive statistics:

file close _all
file open table using "${wd}\output\desc.tex", write replace

file write table "\begin{table}[H]\centering"
file write table _n
file write table "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
file write table _n
file write table "\caption{Estad\'isticos descriptivos \label{desc}}"
file write table _n
file write table "\scalebox{0.9}{\begin{tabular}{lccccccc}"
file write table _n
file write table "\hline\hline"
file write table _n
file write table " & Media (tratados) & Media (controles) & SD & Min. & Max. & $ p$-value (T-C) & $ N$ \\"
file write table _n
file write table "\hline"
file write table _n

file write table "\multicolumn{8}{l}{\textbf{Panel A: ARE}} \\"
file write table "\hline"
file write table _n

foreach var in $vars3 {
	local v`var' : variable label `var'
    file write table "`v`var'' & "
    
    // Tratados
    sum `var' if treat == 1
    file write table (string(r(mean),"%15.3fc")) " & "
    
    // Controles
    sum `var' if treat == 0
    file write table (string(r(mean),"%15.3fc")) " & "
	
	// Todos
    sum `var'
    file write table (string(r(sd),"%15.3fc")) " & "	
    file write table "`r(min)' & "	
    file write table "`r(max)' & "	
   
    // p-value
    reg `var' treat, robust
    test treat
    local pval = r(p)
    
    local sig ""
    if `pval'<.1 local sig "*"
    if `pval'<.05 local sig "**"
    if `pval'<.01 local sig "***"
    
    file write table (string(r(p),"%15.3fc")) "`sig'" " & "
 	
	// N
    sum `var'
    file write table "`r(N)' \\ "	
   file write table _n
}

file write table "\hline"
file write table _n
file write table "\multicolumn{8}{l}{\textbf{Panel B: Cajero}} \\"
file write table "\hline"
file write table _n

foreach var in $vars4 {
	local v`var' : variable label `var'
    file write table "`v`var'' & "
    
    // Tratados
    sum `var' if treat == 1
    file write table (string(r(mean),"%15.3fc")) " & "
    
    // Controles
    sum `var' if treat == 0
    file write table (string(r(mean),"%15.3fc")) " & "
	
	// Todos
    sum `var'
    file write table (string(r(sd),"%15.3fc")) " & "	
    file write table "`r(min)' & "	
    file write table "`r(max)' & "	
   
    // p-value
    reg `var' treat, robust
    test treat
    local pval = r(p)
    
    local sig ""
    if `pval'<.1 local sig "*"
    if `pval'<.05 local sig "**"
    if `pval'<.01 local sig "***"
    
    file write table (string(r(p),"%15.3fc")) "`sig'" " & "
 	
	// N
    sum `var'
    file write table "`r(N)' \\ "	
   file write table _n
}

file write table "\hline\hline"
file write table _n

file write table _n
file write table "\multicolumn{4}{l}{\footnotesize Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\"
file write table _n
file write table "\end{tabular}}"
file write table _n
file write table "\end{table}"
file write table _n

file close table

* Preliminary regressions (all months):
sum wave
local max_w=r(max)
local max_w_1=`max_w'-1
foreach y in $vars1 $vars2 reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean $vars5 $vars6 $vars7 {
	preserve
	sum wave
	local max=r(max)
	forvalues m=1(1)`max' {
		sum `y' if wave==`m'
		if r(N)==0 replace `y'=0 if wave==`m'
	}
	reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estimates store model
	matrix list e(b)
	postfile lincom_results_`y' year coefficient lower upper type using "$wd\data\lincom_results_`y'.dta", replace
	foreach m of numlist 1/`max_w' {
		local l=`m'-1
		lincom c.treat1#`m'.wave, level(95)
		post lincom_results_`y' (`l'-0.15) (`r(estimate)') (`r(lb)') (`r(ub)') (1)
		lincom c.treat2#`m'.wave, level(95)
		post lincom_results_`y' (`l'+0.15) (`r(estimate)') (`r(lb)') (`r(ub)') (0)
		}
	postclose lincom_results_`y'
	use "$wd\data\lincom_results_`y'.dta", clear
	twoway (scatter coefficient year if type == 1, mcolor(stc1)) ///
		   (rcap lower upper year if type == 1, lcolor(stc1)) ///
		   (scatter coefficient year if type == 0, mcolor(stc2)) ///
		   (rcap lower upper year if type == 0, lcolor(stc2)), ///
		   xlabel(0(1)`max_w_1') ylabel(, angle(horizontal)) ///
		   ytitle("Coeficiente") ///
		   xti("Meses desde inicio del programa") legend(order(1 "Tratado (doble ofibus)" 3 "Tratado (información)") position(6) rows(1)) yline(0, lp(dash))
	graph export "$wd\output\dynamic_fx_`y'.png", replace
	restore
	preserve
	replace ine=ine+100000 if (treat2==0 & wave==1) & (treat2==1 & wave==3)
	collapse `y' treat1 treat2, by(ine)
	cumul `y' if treat1==1, gen(Tratadodobleofibus)
	cumul `y' if treat2==1, gen(Tratadoinformación)
	cumul `y' if treat2==0 & treat1==0, gen(Control)
	stack Tratadodobleofibus `y' Tratadoinformación `y' Control `y', into(c `y') wide clear
	line Tratadodobleofibus Tratadoinformación Control `y', xaxis(1 2) xtitle("", axis(2)) xtitle("", axis(1)) sort legend(order(1 "Tratado (doble ofibus)" 2 "Tratado (información)" 3 "Control") pos(6) rows(1))
	graph export "$wd\output\distr_fx_`y'.png", replace
	restore
}
foreach y in $vars1 $vars2 reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean $vars5 $vars6 $vars7 {
	erase "$wd\data\lincom_results_`y'.dta"
}

local nvars=0
foreach y in $vars1 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg1.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera \label{reg1}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars1 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

sum wave
local m=ceil(r(max)/7)

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg11`n'.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera `cont' \label{reg11`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.
}

eststo clear

local nvars=0
foreach y in $vars5 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg7.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) \label{reg7}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

local nvars=0
foreach y in $vars5 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

sum wave
local m=ceil(r(max)/7)

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg71`n'.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) `cont' \label{reg71`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})
}

eststo clear

local nvars=0
foreach y in $vars2 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg2.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) \label{reg2}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars2 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	esttab using "${wd}\output\reg21`n'.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) \label{reg21`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.
}

eststo clear

local nvars=0
foreach y in $vars6 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg8.tex", mti("Cheques (\#)" "Cheques (\euro)" "Transferencias (\#)" "Transferencias (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) (continuado) \label{reg8}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

local nvars=0
foreach y in $vars6 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	esttab using "${wd}\output\reg81`n'.tex", mti("Cheques (\#)" "Cheques (\euro)" "Transferencias (\#)" "Transferencias (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) (continuado) \label{reg81`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})
}

eststo clear

foreach y in reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg3.tex", title("Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) \label{reg3}") mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear

preserve
foreach y in reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean {
	replace `y'=0 if `y'==.
	eststo: tobit `y' treat1 treat2 i.wave, vce(cluster ine) ll(0)
	estadd local rsq=string(e(r2_p),"%15.3fc")
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg32.tex", title("Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, estimación por Tobit) \label{reg32}") mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("rsq $ \text{Pseudo-}R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}.") nofloat compress substitute("main" "%main") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear
restore

local nvars=0
foreach y in reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg31`n'.tex", title("") mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) `cont' \label{reg31`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{3}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.
}

eststo clear

local nvars=0
foreach y in $vars7 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg9.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, agregado ARE+Cajero) \label{reg9}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

local nvars=0
foreach y in $vars7 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg91`n'.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, agregado ARE+Cajero) `cont' \label{reg91`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})
}

eststo clear

* Preliminary regressions (by month):

sum wave
local max=r(max)
local nvars=0
forvalues m=1(1)`max' {
	foreach y in $vars1 {
		preserve
		sum `y' if wave==`m'
		if r(N)==0 replace `y'=0 if wave==`m'
		eststo `y'_`m': reg `y' treat1 treat2 if wave==`m', vce(cluster ine)
		sum `y' if treat1==0 & treat2==0 & e(sample)==1 & wave==`m'
		estadd local avg=string(r(mean),"%15.3fc")
		estadd local sd=string(r(sd),"%15.3fc")
		estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
		estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
		restore
		local ++nvars
	}
}
local nvars = `nvars' / `max'
local nvars1=`nvars'+1
	
forvalues m=1(1)`max' { // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.
	local anio = substr("`periodos'", 1+7*(`m'-1), 4)
	local mesnum = substr("`periodos'", 5+7*(`m'-1), 2)
	local mes = word("Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre", `mesnum')
	local letra = char(64 + `m')
	local new = cond(mod(`m'-1, 3) == 0, 1, 0)
	local last = cond(mod(`m', 3) == 0, 1, 0)
	if `m'==`max' local last = 1
	if `m'==1 local new = 0
	if `m'<4 {
		if `last'==1 & `m'==1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4.tex", mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes \label{reg4`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `m'==1 & `last'!=1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4.tex", fragment mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes \label{reg4}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `m'!=1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4.tex", fragment mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `m'!=1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4.tex", mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
	else {
		local k=floor((`m'-1)/3)
		if `last'==1 & `new'==1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4`k'.tex", mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes \label{reg4`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `new'==1 & `last'!=1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4`k'.tex", fragment mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes \label{reg4`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `new'!=1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4`k'.tex", fragment mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `new'!=1 {
			esttab personasatendidas_`m' reintegros_`m' m_`m' ingresos_`m' o_`m' traspasos_`m' s_`m' chequespropios_`m' y_`m' chequesajenos_`m' using "${wd}\output\reg4`k'.tex", mgroups("ARE", pattern(1 0 0 0 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
}

eststo clear

local nvars=0
forvalues m=1(1)`max' {
	foreach y in $vars2 {
		preserve
		sum `y' if wave==`m'
		if r(N)==0 replace `y'=0 if wave==`m'
		eststo `y'_`m': reg `y' treat1 treat2 if wave==`m', vce(cluster ine)
		sum `y' if treat1==0 & treat2==0 & e(sample)==1 & wave==`m'
		estadd local avg=string(r(mean),"%15.3fc")
		estadd local sd=string(r(sd),"%15.3fc")
		estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
		estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
		restore
		local ++nvars
	}
}
local nvars=`nvars'/`max'
local nvars1=`nvars'+1

forvalues m=1(1)`max' { // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.
	local anio = substr("`periodos'", 1+7*(`m'-1), 4)
	local mesnum = substr("`periodos'", 5+7*(`m'-1), 2)
	local mes = word("Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre", `mesnum')
	local letra = char(64 + `m')
	local new = cond(mod(`m'-1, 3) == 0, 1, 0)
	local last = cond(mod(`m', 3) == 0, 1, 0)
	if `m'==`max' local last = 1
	if `m'==1 local new = 0
	if `m'<4 {
		if `last'==1 & `m'==1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5.tex", mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes (continuado) \label{reg5}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `m'==1 & `last'!=1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes (continuado) \label{reg5}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `m'!=1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append

		}
		if `last'==1 & `m'!=1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
	else {
		local k=floor((`m'-1)/3)
		if `last'==1 & `new'==1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5`k'.tex", mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes (continuado) \label{reg5`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `new'==1 & `last'!=1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por mes (continuado) \label{reg5}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `new'!=1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `new'!=1 {
			esttab ac_`m' transferencias_`m' ae_`m' resto_`m' persatendidas_`m' an_`m' ao_`m' restooperaciones_`m' au_`m' using "${wd}\output\reg5`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 1 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
}

eststo clear

local nvars=0
forvalues m=1(1)`max' {
	foreach y in reintegros_mean ingresos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean {
		preserve
		sum `y' if wave==`m'
		if r(N)==0 replace `y'=0 if wave==`m'
		eststo `y'_`m': reg `y' treat1 treat2 if wave==`m', vce(cluster ine)
		sum `y' if treat1==0 & treat2==0 & e(sample)==1 & wave==`m'
		estadd local avg=string(r(mean),"%15.3fc")
		estadd local sd=string(r(sd),"%15.3fc")
		estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
		estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
		restore
		local ++nvars
	}
}
local nvars=`nvars'/`max'
local nvars1=`nvars'+1

forvalues m=1(1)`max' { // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.
	local anio = substr("`periodos'", 1+7*(`m'-1), 4)
	local mesnum = substr("`periodos'", 5+7*(`m'-1), 2)
	local mes = word("Enero Febrero Marzo Abril Mayo Junio Julio Agosto Septiembre Octubre Noviembre Diciembre", `mesnum')
	local letra = char(64 + `m')
	local new = cond(mod(`m'-1, 3) == 0, 1, 0)
	local last = cond(mod(`m', 3) == 0, 1, 0)
	if `m'==`max' local last = 1
	if `m'==1 local new = 0
	if `m'<4 {
		if `last'==1 & `m'==1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `m'==1 & `last'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `m'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `m'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
	else {
		local k=floor((`m'-1)/3)
		if `last'==1 & `new'==1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `new'==1 & `last'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `new'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `new'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' trans_mean_`m' rntg_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
}

eststo clear

*** Uncomment below to run census data prep: ***
*do "$wd\code\census_prep.do"

/// Checks that the assignment is the same:

preserve
clear all

import excel "Q:\PIFIN\CaixaBank\Marina\tabla_general_tratamiento_perc_clientes.xlsx", sheet("Sheet1") firstrow case(lower) // Según el ReadMe de Marina, esta es la asignación final.

merge 1:m ine asignacion using "$wd\data\output_merged.dta"

table ine asignacion if _merge==2, zerocounts
table ine asignacion if _merge==1, zerocounts
restore

use "$wd\data\output_merged.dta", clear

preserve
clear all

import excel "Q:\PIFIN\CaixaBank\Marina\tabla_general_tratamiento_perc_clientes.xlsx", sheet("Sheet1") firstrow case(lower) // Según el ReadMe de Marina, esta es la asignación final.
save "$wd\data\cbk_controls.dta", replace
restore

merge m:1 ine using "$wd\data\cbk_controls.dta"

merge m:1 ine using "$wd\data\census_2021.dta", nogen keep(3)
merge m:1 ine using "$wd\data\distr_2022.dta", nogen keep(3)
merge m:1 ine using "$wd\data\income_2022.dta", nogen keep(3)
merge m:1 ine using "$wd\data\pop_2022.dta", nogen keep(3)

* Include discrepant observations with CaixaBank:

gen observaciones_cxb=""
replace observaciones_cxb="El Municipio renunció al servicio y no está en el perímetro actual de rutas" if _merge==1 & asignacion=="Control"
replace observaciones_cxb="El Municipio renunció al servicio y no está en el perímetro actual de rutas" if ine==25064 | ine==25905 | ine==25032 | ine==25094 
replace observaciones_cxb="La segunda ruta Peramola y Alos de Balaguer se desestimó por apenas tener potenciales usuarios y ser ineficiente desde el punto de vista de los tiempos, kilometraje y recursos disponibles" if ine==25022 | ine==25165
replace observaciones_cxb="Renunció al servicio, pero recientemente recitifica e incluiremos en el servicio a partir del mes de marzo" if ine==43084

encode entidadúltimapresencia, gen(ent_pres)
encode entidadagentefinancieroactual, gen(ent_agent)

rename agentesfinancieroscompetencia agent_comp
rename Porcentajedepoblaciónmenorde menor_18
rename Porcentajedepoblaciónde65y mayor_65
rename Tamañomediodelhogar hhld_sz
rename Porcentajedepoblaciónespañola native
rename Rentanetamediaporpersona inc_pc

global xlist habitantes clientescbk clientescbk65años distanciam i.ent_pres agent_comp i.ent_agent Edadmediadelapoblación menor_18 mayor_65 hhld_sz native inc_pc ÍndicedeGini z2est_superiores z2ocupados
global xlist1 habitantes distanciam i.ent_pres agent_comp i.ent_agent Edadmediadelapoblación menor_18 mayor_65 hhld_sz native inc_pc ÍndicedeGini z2est_superiores z2ocupados

label variable habitantes "Tamaño poblacional"
label variable clientescbk "Clientes de CaixaBank"
label variable clientescbk65años "Clientes de CaixaBank mayores de 65 años"
label variable distanciam "Distancia al cajero más cercano"
label variable agent_comp "Agentes financieros de otras entidades"
label variable z2est_superiores "Personas con estudios superiores"
label variable z2ocupados "Población ocupada"
label variable z3t_ingresos_uc_menor_40p "Población con ingresos por unidad de consumo por debajo 40% de la mediana"

save "$wd\data\output_merged.dta", replace

* Balance of covariates:

file close _all
file open table using "${wd}\output\balance.tex", write replace

file write table "\begin{table}[H]\centering"
file write table _n
file write table "\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}"
file write table _n
file write table "\caption{Balance de variables de control \label{balance}}"
file write table _n
file write table "\scalebox{0.8}{\begin{tabular}{lccccccc}"
file write table _n
file write table "\hline\hline"
file write table _n
file write table " & Media (tratados) & Media (controles) & SD & Min. & Max. & $ p$-value (T-C) & $ N$ \\"
file write table _n
file write table "\hline"
file write table _n

foreach var in habitantes clientescbk clientescbk65años distanciam agent_comp Edadmediadelapoblación menor_18 mayor_65 hhld_sz native inc_pc ÍndicedeGini z2est_superiores z2ocupados {
	local v`var' : variable label `var'
    file write table "`v`var'' & "
    
    // Tratados
    sum `var' if treat == 1
    file write table (string(r(mean),"%15.3fc")) " & "
    
    // Controles
    sum `var' if treat == 0
    file write table (string(r(mean),"%15.3fc")) " & "
	
	// Todos
    sum `var'
    file write table (string(r(sd),"%15.3fc")) " & "	
    file write table "`r(min)' & "	
    file write table "`r(max)' & "	
   
    // p-value
    reg `var' treat, robust
    test treat
    local pval = r(p)
    
    local sig ""
    if `pval'<.1 local sig "*"
    if `pval'<.05 local sig "**"
    if `pval'<.01 local sig "***"
    
    file write table (string(r(p),"%15.3fc")) "`sig'" " & "
 	
	// N
    sum `var'
    file write table "`r(N)' \\ "	
   file write table _n
}

file write table "\hline\hline"
file write table _n

file write table _n
file write table "\multicolumn{4}{l}{\footnotesize Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\"
file write table _n
file write table "\end{tabular}}"
file write table _n
file write table "\end{table}"
file write table _n

file close table

foreach y in habitantes clientescbk clientescbk65años distanciam agent_comp Edadmediadelapoblación menor_18 {
	eststo: reg `y' treat1 treat2 if wave==3, r
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\balance1.tex", title("Balance de variables de control \label{balance1}") mgroups("CaixaBank" "Censo", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Tamaño\\población\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Clientes\\CaixaBank\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Clientes CaixaBank\\(>65 años)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Distancia\\cajero\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Agentes\\otros bancos\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Edad\\media\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Población\\<18 años (\%)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear

foreach y in mayor_65 hhld_sz native inc_pc ÍndicedeGini z2est_superiores z2ocupados {
	eststo: reg `y' treat1 treat2 if wave==3, r
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\balance2.tex", title("Balance de variables de control (continuado) \label{balance2}") mgroups("Censo", pattern(1 0 0 0 0 0 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("\begin{tabular}[c]{@{}c@{}} Población\\>65 años (\%)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Tamaño\\medio hogar\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Población\\española (\%)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Renta\\per capita\end{tabular}" "Gini" "\begin{tabular}[c]{@{}c@{}} Personas con\\educación superior\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Personas\\ocupadas\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear

/// Regressions with controls:

foreach var in habitantes clientescbk clientescbk65años distanciam ent_pres agent_comp ent_agent Edadmediadelapoblación menor_18 mayor_65 hhld_sz native inc_pc ÍndicedeGini z2est_superiores z2ocupados {
	gen `var'_miss=(`var'==.)
	replace `var'=99999 if `var'==.
	global xlist $xlist `var'_miss
}
foreach var in habitantes distanciam ent_pres agent_comp ent_agent Edadmediadelapoblación menor_18 mayor_65 hhld_sz native inc_pc ÍndicedeGini z2est_superiores z2ocupados {
	global xlist1 $xlist1 `var'_miss
}

local nvars=0
foreach y in $vars1 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg11.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) \label{reg11}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear
local nvars=0
foreach y in $vars5 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg71.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) (continuado) \label{reg71}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear
local nvars=0
foreach y in $vars2 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg21.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) \label{reg21}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear
local nvars=0
foreach y in $vars6 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg81.tex", mti("Cheques (\#)" "Cheques (\euro)" "Transferencias (\#)" "Transferencias (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) (continuado) \label{reg81}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear
foreach y in reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg31.tex", title("Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) (continuado) \label{reg31}") mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear
local nvars=0
foreach y in $vars7 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg91.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, agregado ARE+Cajero) (continuado) \label{reg91}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

local nvars=0
foreach y in $vars1 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

sum wave
local m=ceil(r(max)/7)

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg12`n'.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera `cont' \label{reg12`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.
}

eststo clear

local nvars=0
foreach y in $vars2 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	esttab using "${wd}\output\reg22`n'.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) \label{reg22`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.
}

eststo clear

local nvars=0
foreach y in reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg32`n'.tex", title("") mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) `cont' \label{reg32`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{3}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.
}

eststo clear

local nvars=0
foreach y in $vars7 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg92`n'.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, agregado ARE+Cajero) `cont' \label{reg92`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})
}

eststo clear
local nvars=0
foreach y in $vars6 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

forvalues n=1(1)`m' {
	esttab using "${wd}\output\reg82`n'.tex", mti("Cheques (\#)" "Cheques (\euro)" "Transferencias (\#)" "Transferencias (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) (continuado) \label{reg82`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})
}

eststo clear
local nvars=0
foreach y in $vars5 {
	eststo: reg `y' c.treat1#i.wave c.treat2#i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

sum wave
local m=ceil(r(max)/7)

forvalues n=1(1)`m' {
	local cont=""
	if `n'>1 local cont="(continuado)"
	esttab using "${wd}\output\reg72`n'.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)") coeflabels(${wavelist_lab_`n'}) keep(${wavelist_`n'}) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (agregado ARE+Cajero) `cont' \label{reg72`n'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})
}

eststo clear

/// Generate outcome variables per capita (per person aged >18):

foreach var in $vars1 $vars2 reintegros_mean ingresos_mean traspasos_mean cheqaj_mean trans_mean rntg_caj_mean resto_caj_mean $vars7 $vars6 $vars5 clientescbk clientescbk65 {
	gen `var'_18=`var'/(población*(1-(menor_18/100)))
}

forvalues n=1/7 {
	global vars`n'_18
	foreach var in ${vars`n'} {
		global vars`n'_18 ${vars`n'_18} `var'_18
	}
}

/// Regressions with per capita outcomes:

local nvars=0
foreach y in $vars1_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg1_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años \label{reg1pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars1_18 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg11_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (continuado) \label{reg11pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars2_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg2_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (continuado) \label{reg2pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars2_18 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg21_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (continuado) \label{reg21pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

foreach y in reintegros_mean_18 ingresos_mean_18 traspasos_mean_18 cheqaj_mean_18 trans_mean_18 rntg_caj_mean_18 resto_caj_mean_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg3_pc.tex", title("Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) por habitante >18 años \label{reg3pc}") mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear

foreach y in reintegros_mean_18 ingresos_mean_18 traspasos_mean_18 cheqaj_mean_18 trans_mean_18 rntg_caj_mean_18 resto_caj_mean_18 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg31_pc.tex", title("Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) por habitante >18 años (continuado) \label{reg31pc}") mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars5_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg4_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (agregado ARE+Cajero) \label{reg4pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

//Aqui toca hacer las modificaciones (Tabla11)
local nvars=0
foreach y in $vars5_18 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg41_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (continuado) (agregado ARE+Cajero) \label{reg41pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear


local nvars=0
foreach y in $vars6_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg5_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (continuado) (agregado ARE+Cajero) \label{reg5pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

//Aqui toca hacer las modificaciones (Tabla12 y continuacion)


local nvars=0
foreach y in $vars6_18 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg51_pc.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera por habitante >18 años (continuado) (agregado ARE+Cajero) \label{reg51pc}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

foreach y in $vars7_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg6_pc.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, agregado ARE+Cajero) por habitante >18 años \label{reg6pc}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

//Aqui toca hacer las modificaciones (Tabla13 y continuacion)


foreach y in $vars7_18 {
	eststo: reg `y' treat1 treat2 i.wave $xlist, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg61_pc.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, agregado ARE+Cajero) por habitante >18 años (continuado) \label{reg61pc}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

/// Regressions in logs:

foreach y in $vars7 {
	preserve
	replace `y'=ln(`y')
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	restore
}

esttab using "${wd}\output\reg1_log.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (log \euro/\#, agregado ARE+Cajero) \label{reg1log}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

/// Regressions with collapsed outcomes:

preserve
collapse (sum) $vars5 $vars6 $vars7 (mean) treat1 treat2, by(ine)

local nvars=0
foreach y in $vars5 {
	eststo: reg `y' treat1 treat2, vce(robust)
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg1_clps.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (suma de todos los meses agregado ARE+Cajero) \label{reg1clps}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

local nvars=0
foreach y in $vars6 {
	eststo: reg `y' treat1 treat2, vce(robust)
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg2_clps.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) (suma de todos los meses agregado ARE+Cajero) \label{reg2clps}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear

foreach y in $vars7 {
	eststo: reg `y' treat1 treat2, vce(robust)
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg3_clps.tex", mti("Reintegros" "Ingresos" "Traspasos" "Cheques" "Transferencias") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#, suma de todos los meses agregado ARE+Cajero) \label{reg3clps}}\begin{tabular}{l*{`nvars'}{c}}\hline\hline) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar robustos en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance}. \end{footnotesize} \end{tablenotes}\end{table})

eststo clear
restore

/// Regressions for number of clients:

local nvars=0
foreach y in clientescbk clientescbk65 clientescbk_18 clientescbk65_18 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "No"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
	eststo: reg `y' treat1 treat2 i.wave $xlist1, vce(cluster ine)
	estadd local mfe "S\'i"
	estadd local controls "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")	
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg10.tex", mti("Todos" "Todos" ">65 años" ">65 años" "Todos" "Todos" ">65 años" ">65 años") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "controls Controles" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en número de clientes \label{reg10}} \begin{tabular}{l*{`nvars'}{c}}\hline\hline & \multicolumn{4}{c}{Total de clientes}& \multicolumn{4}{c}{Clientes por habitantes >18 años} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\\\end{tabular}\begin{tablenotes}[para]\begin{footnotesize} \item Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$. Los controles incluyen los mostrados en la Tabla \ref{balance} a excepción de \textit{Clientes CaixaBank} y \textit{Clientes CaixaBank (>65 años)}. \end{footnotesize} \end{tablenotes}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear
