**************************************************
**************** CaixaBank Data ******************
**************************************************

clear all
global wd "Q:\PIFIN\CaixaBank\Diego"

/// Selection of outcome variables:

global vars "personasatendidas reintegros m ingresos o impuestos q traspasos s opdivisa u impuestosaeat w chequespropios y tributos aa chequesajenos ac transferencias ae resto apertctacorriente apertvalores apertfondoinvers aperturatarjetas aperturaseguros altaprodactivo persatendidas an ao impuestorecibos aq ar as restooperaciones au"
global vars1 "personasatendidas reintegros m ingresos o traspasos s chequespropios y chequesajenos"
global vars2 "ac transferencias ae resto persatendidas an ao restooperaciones au"
global vars3 "personasatendidas reintegros m ingresos o traspasos s chequespropios y chequesajenos ac transferencias ae resto"
global vars4 "persatendidas an ao restooperaciones au"

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

label define wave 1 "Wave Dec. 2024" 2 "Wave Jan. 2025" 3 "Wave Feb. 2025" 4 "Wave Mar. 2025" 5 "Wave Apr. 2025" 6 "Wave May 2025" 7 "Wave Jun. 2025" // Change if wanted, not necessary for estimations.
label values wave wave

rename asignación asignacion
replace asignacion="Primera ronda formación" if asignacion=="1ª ronda formación Nov'24"
replace asignacion="Segunda ronda formación" if asignacion=="2ª ronda formación Feb'25"

label variable personasatendidas "Personas atendidas (\#)"
label variable reintegros "Reintegros (\#)"
label variable m "Reintegros (\euro)"
label variable ingresos "Ingresos (\#)"
label variable o "Ingresos (\euro)"
label variable traspasos "Traspasos (\#)"
label variable s "Traspasos (\euro)"
label variable chequespropios "Cheques propios (\#)"
label variable y "Cheques propios (\euro)"
label variable chequesajenos "Cheques ajenos (\#)"
label variable ac "Cheques ajenos (\euro)"
label variable transferencias "Transferencias (\#)"
label variable ae "Transferencias (\euro)"
label variable resto "Resto (\#)"
label variable persatendidas "Personas atendidas (\#)"
label variable an "Reintegros (\#)"
label variable ao "Reintegros (\euro)"
label variable restooperaciones "Resto operaciones (\#)"
label variable au "Resto operaciones (\euro)"

gen reintegros_mean=m/reintegros
gen ingresos_mean=o/ingresos
gen traspasos_mean=s/traspasos
gen cheqaj_mean=ac/chequesajenos
gen transferencias_mean=ae/transferencias
gen reintegros_caj_mean=ao/an
gen resto_caj_mean=au/restooperaciones

save "$wd\data\output_merged.dta", replace

/// Preliminary results:

gen treat=1
replace treat=0 if asignacion=="Control" | (asignacion=="Segunda ronda formación" & wave<3)
gen treat1=1 if asignacion=="doble ofibus"
replace treat1=0 if asignacion=="Control" | asignacion=="Segunda ronda formación" | asignacion=="Primera ronda formación"
gen treat2=1 if asignacion=="Primera ronda formación" | (asignacion=="Segunda ronda formación" & wave>=3)
replace treat2=0 if asignacion=="Control" | (asignacion=="Segunda ronda formación" & wave<3) | asignacion=="doble ofibus"

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

foreach y in $vars {
	reg `y' treat1 treat2 i.wave, vce(cluster ine)
	qui sum `y' if treat1==0 & treat2==0
	di "SD (control): `r(sd)'"
	qui local b1=_b[treat1]/`r(sd)'
	di "Effect SD (doble ofibus): `b1'"
	qui local b2=_b[treat2]/`r(sd)'
	di "Effect SD (info): `b2'"
}

local nvars=0
foreach y in $vars1 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg1.tex", mti("\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "Ingresos (\#)" "Ingresos (\euro)" "Traspasos (\#)" "Traspasos (\euro)" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\propios (\euro)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\#)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera \label{reg1}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{`nvars'}{c}{ARE} \\\cmidrule(lr){2-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

local nvars=0
foreach y in $vars2 {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
	local ++nvars
}
local nvars1=`nvars'+1

esttab using "${wd}\output\reg2.tex", mti("\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos (\euro)\end{tabular}" "Transferencias (\#)" "Transferencias (\euro)" "Resto (\#)" "\begin{tabular}[c]{@{}c@{}} Personas\\atendidas (\#)\end{tabular}" "Reintegros (\#)" "Reintegros (\euro)" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\#)\end{tabular}" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones (\euro)\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera (continuado) \label{reg2}}\scalebox{0.75}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline &\multicolumn{4}{c}{ARE} &\multicolumn{5}{c}{Cajero} \\\cmidrule(lr){2-5}\cmidrule(lr){6-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) // Note that \cmidrule(lr){.} might have to be changed manually if different variables are selected.

eststo clear

foreach y in reintegros_mean ingresos_mean traspasos_mean cheqaj_mean transferencias_mean reintegros_caj_mean resto_caj_mean {
	eststo: reg `y' treat1 treat2 i.wave, vce(cluster ine)
	estadd local mfe "S\'i"
	sum `y' if treat1==0 & treat2==0 & e(sample)==1
	estadd local avg=string(r(mean),"%15.3fc")
	estadd local sd=string(r(sd),"%15.3fc")
	estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
	estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
}

esttab using "${wd}\output\reg3.tex", title("Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on (\euro/\#) \label{reg3}") mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "mfe EF de mes" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") addnote("Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.") compress substitute("[htbp]" "[H]") // Note that mgourps(., pattern(.)) might have to be changed manually if different variables are selected.

eststo clear

* Preliminary regressions (by month):

sum wave
local max=r(max)
local nvars=0
forvalues m=1(1)`max' {
	foreach y in $vars1 {
		eststo `y'_`m': reg `y' treat1 treat2 if wave==`m', vce(cluster ine)
		sum `y' if treat1==0 & treat2==0 & e(sample)==1 & wave==`m'
		estadd local avg=string(r(mean),"%15.3fc")
		estadd local sd=string(r(sd),"%15.3fc")
		estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
		estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
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
		eststo `y'_`m': reg `y' treat1 treat2 if wave==`m', vce(cluster ine)
		sum `y' if treat1==0 & treat2==0 & e(sample)==1 & wave==`m'
		estadd local avg=string(r(mean),"%15.3fc")
		estadd local sd=string(r(sd),"%15.3fc")
		estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
		estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
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
	foreach y in reintegros_mean ingresos_mean cheqaj_mean transferencias_mean reintegros_caj_mean resto_caj_mean {
		eststo `y'_`m': reg `y' treat1 treat2 if wave==`m', vce(cluster ine)
		sum `y' if treat1==0 & treat2==0 & e(sample)==1 & wave==`m'
		estadd local avg=string(r(mean),"%15.3fc")
		estadd local sd=string(r(sd),"%15.3fc")
		estadd local b1_sd=string(_b[treat1]/r(sd),"%15.3fc")
		estadd local b2_sd=string(_b[treat2]/r(sd),"%15.3fc")
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
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `m'==1 & `last'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `m'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `m'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
	else {
		local k=floor((`m'-1)/3)
		if `last'==1 & `new'==1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table})
		}
		if `new'==1 & `last'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) replace star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\begin{table}[H]\centering\def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}\caption{Efectos preliminares en medidas de inclusi\'on financiera, importe por operaci\'on por mes (\euro/\#) \label{reg6`k'}}\scalebox{0.65}{\begin{tabular}{l*{`nvars'}{c}}\hline\hline\\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'})
		}
		if `last'==0 & `new'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars1'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) append
		}
		if `last'==1 & `new'!=1 {
			esttab reintegros_mean_`m' ingresos_mean_`m' cheqaj_mean_`m' transferencias_mean_`m' reintegros_caj_mean_`m' resto_caj_mean_`m' using "${wd}\output\reg6`k'.tex", fragment mgroups("ARE" "Cajero", pattern(1 0 0 0 0 1 0)prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) mti("Reintegros" "Ingresos" "Traspasos" "\begin{tabular}[c]{@{}c@{}} Cheques\\ajenos\end{tabular}" "Transferencias" "Reintegros" "\begin{tabular}[c]{@{}c@{}} Resto\\operaciones\end{tabular}") coeflabels(treat1 "Tratado (doble ofibus)" treat2 "Tratado (información)") keep(treat1 treat2) nocon nonotes b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) scalars("r2 $ R^2$" "N $ N$" "avg Promedio var. dep. (control)" "sd SD var. dep. (control)" "b1_sd Efecto en SD (doble ofibus)" "b2_sd Efecto en SD (información)") compress prehead(\hline\hline & & & & & & \\ \multicolumn{`nvars'}{l}{\textbf{Panel `letra': `mes' `anio'}} \\\cmidrule(lr){1-`nvars1'}) postfoot(\hline\hline\multicolumn{`nvars1'}{l}{\footnotesize Notas: Errores est\'andar agrupados en par\'entesis. * $ p<0.1$, ** $ p<0.05$, *** $ p<0.01$.}\\\end{tabular}}\end{table}) append
		}
	}
}

eststo clear

/// Checks that the assignment is the same:

clear all

import excel "Q:\PIFIN\CaixaBank\Marina\tabla_general_tratamiento_perc_clientes.xlsx", sheet("Sheet1") firstrow case(lower) /// Según el ReadMe de Marina, esta es la asignación final.

merge 1:m ine asignacion using "$wd\data\output_merged.dta"

table ine asignacion if _merge==2, zerocounts
table ine asignacion if _merge==1, zerocounts

* Include discrepant observations with CaixaBank:

gen observaciones_cxb=""
replace observaciones_cxb="El Municipio renunció al servicio y no está en el perímetro actual de rutas" if _merge==1 & asignacion=="Control"
replace observaciones_cxb="El Municipio renunció al servicio y no está en el perímetro actual de rutas" if ine==25064 | ine==25905 | ine==25032 | ine==25094 
replace observaciones_cxb="La segunda ruta Peramola y Alos de Balaguer se desestimó por apenas tener potenciales usuarios y ser ineficiente desde el punto de vista de los tiempos, kilometraje y recursos disponibles" if ine==25022 | ine==25165
replace observaciones_cxb="Renunció al servicio, pero recientemente recitifica e incluiremos en el servicio a partir del mes de marzo" if ine==43084

save "$wd\data\output_merged.dta", replace
