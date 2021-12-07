/**************************/
/* Importing the database */
/**************************/

use "C:\Users\Antoi\OneDrive\Université\Master 1\Semestre 2\Logiciels pour économistes\projet\bien_etre\database.dta", clear

/* We keep only the variables that we need and we rename them */

	keep F118 S003 X001 X002 S020 F034 E033 X023 X023R X025A2 

	rename (F118 S003 X001 X002 S020 F034 E033) (justif_homo country sex year_birth year_survey religion political_scale)

/* After creating a variable that represents the country in character class, we select only obersvations for United States */

	decode country, gen(country2) 

	keep if country2 == "United States"

/* Using 3 different variables that concern the age at which the individual complete his education, we generate the variable education
   and we create the label */
	
	generate education = .
	replace education = 1 if (X023 <= 12 | X023R == 1 | X025A2 == 0)
	replace education = 2 if (X023 == 13 | X023R == 2 )
	replace education = 3 if (X023 == 14 | X023R == 3 | X025A2 == 2)
	replace education = 4 if (X023 == 15 | X023R == 4)
	replace education = 5 if (X023 == 16 | X023R == 5)
	replace education = 6 if (X023 == 17 | X023R == 6 | X025A2 == 3)
	replace education = 7 if (X023 == 18 | X023R == 7 | X025A2 == 4)
	replace education = 8 if (X023 == 19 | X023R == 8 | X025A2 == 5)
	replace education = 9 if (X023 == 20 | X023R == 9 | X025A2 == 6)
	replace education = 10 if ( X023R == 10 |  X025A2 == 7 | X025A2 == 8)
	replace education = 10 if ( X023 >= 21 & X023 <= 98 )

	label define education2 1 "Less than 12 yo" 2 "13 yo" 3 "14 yo" 4 "15 yo" 5 "16 yo" 6 "17 yo" 7 "18 yo" 8 "19 yo" 9 "20 yo" 10 "more than 21 yo"
	label value education education2
	

/* We delete all the observations that have at least one missing values on our variables because these observations are useless for
   the model */
	
	keep if (justif_homo != .) & (sex != .)& (year_birth != .) & (year_survey != .) & (religion != .)  & (political_scale != .) & (education !=.)

/* Statistics on the numeric variables*/
 
	summarize justif_homo political_scale year_birth year_survey
	
	tabulate religion
	
	tabulate education
	
/*******************/
/*     Figures     */
/*******************/

	/* Average homosexuality acceptance by year */
	
	bysort year_survey: egen mean_jh = mean(justif_homo)

	twoway connected mean_jh year_survey, ytitle("Average acceptance homosexuality") xtitle("Year") 

	/* Average homosexuality acceptance by year of birth */
	
	graph bar justif_homo, over(year_birth)  yscale(range(0 10))
	
	/* Average homosexuality acceptance by political scale */ 
	
	graph bar justif_homo, over(political_scale) ytitle("Average acceptance homosexuality") ///
	title("Percentage of religious, non religious and atheists") 
	
	/* Average homosexuality acceptance by sex */
	
	graph bar justif_homo, over(sex)  blabel(total) yscale(range(0 10))
	
	/* Average homosexuality acceptance by religion */
	
	graph pie, over(religion) plabel(_all percent, size(*1.25) color(white)) ///
	 pie(1,explode color(red)) pie(2,explode color(blue)) pie(3,explode color(green))  ///
	 title("Percentage of religious, non religious and atheists") subtitle("In USA")
	
	graph bar justif_homo, over(religion)  blabel(total) yscale(range(0 10))
	
	/* Average homosexuality acceptance by level of education */
	
	graph bar justif_homo, over(dum_educ)  blabel(total) yscale(range(0 10))

/***************************/
/*   Creation of variable  */
/***************************/
 
	/* In order to make our results easier to understand, we recode the variable year but this will not affect our 
	   interpretation */ 
 
		generate year_survey2 = year_survey - 1981 
		
	/* We create a variable that represents the interaction between the year of the survey and the religion */

		generate year_survey2_not_religious= 0
		replace year_survey2_not_religious = year_survey2 if religion == 2

		generate year_survey2_ahteist_convinced= 0
		replace year_survey2_ahteist_convinced = year_survey2 if religion == 3
	
	/* We create a factorial variable that take different value depending on the level of education */
		
		generate dum_educ = .
		replace dum_educ = 1 if education <5
		replace dum_educ = 2 if (education >= 5 & education < 9)
		replace dum_educ = 3 if education >= 9
	
		label define label_educ 1 "less_16" 2 "between_16_19" 3 "more_19" 
		label value dum_educ label_educ
		
/* We check for a problem of multicollinearity by using the correlation matrix */

		spearman justif_homo year_birth year_survey2 political_scale

/*******************/
/*   Modelization  */
/*******************/

/* Ordered Probit */

	/* Main regression with marginal effects */

		xi: oprobit justif_homo i.sex year_birth year_survey2 i.religion i.dum_educ ///
		political_scale year_survey2_not_religious year_survey2_ahteist_convinced
		
		margins, dydx( _Isex_2 year_birth year_survey2 _Ireligion_2 _Ireligion_3 ///
		_Idum_educ_2 _Idum_educ_3 political_scale year_survey2_not_religious ///
		year_survey2_ahteist_convinced) predict(outcome(10)) post
		
		marginsplot, horizontal unique xline(0) recast(scatter) ylabel(1 "Female" 2 "Year birth" 3 "Year survey" 4 "Not religious" ///
		 5 "Convinced atheist" 6 "Educ btween 16 yo and 19 yo" 7 "Educ after 19" 8 "Political scale" 9 "Yeas survey : Not religious" ///
		 10 "Year survey : Convinced atheist") ytitle("") title ("Average marginal effect on P(justif_homo = 10)", color(black)) ///
		 subtitle(" ", margin(l+0 r+0 b-1 t-1))

	/* We compute the Variance Inflation Factor (VIF) to check one more time for a possible collinearity problem */ 
	
		xi: regress justif_homo i.sex year_birth year_survey2 i.religion i.dum_educ ///
		political_scale year_survey2_not_religious year_survey2_ahteist_convinced
		
		estat vif
		
/*******************/
/*     Function    */
/*******************/

/* Firstly, we create a program that prepare the data. Of course, we could have done everything in only one program but we prefered
   to do it in two steps for the sake of understanding */

program prepare_data

	use "C:\Users\Antoi\OneDrive\Université\Master 1\Semestre 2\Logiciels pour économistes\projet\bien_etre\database.dta", clear
	
	keep F118 S003 X001 X002 S020 F034 E033 X023 X023R X025A2 

	rename (F118 S003 X001 X002 S020 F034 E033) (justif_homo country sex year_birth year_survey religion political_scale)

	decode country, gen(country2) 

	generate education = .
	replace education = 1 if (X023 <= 12 | X023R == 1 | X025A2 == 0)
	replace education = 2 if (X023 == 13 | X023R == 2 )
	replace education = 3 if (X023 == 14 | X023R == 3 | X025A2 == 2)
	replace education = 4 if (X023 == 15 | X023R == 4)
	replace education = 5 if (X023 == 16 | X023R == 5)
	replace education = 6 if (X023 == 17 | X023R == 6 | X025A2 == 3)
	replace education = 7 if (X023 == 18 | X023R == 7 | X025A2 == 4)
	replace education = 8 if (X023 == 19 | X023R == 8 | X025A2 == 5)
	replace education = 9 if (X023 == 20 | X023R == 9 | X025A2 == 6)
	replace education = 10 if ( X023R == 10 |  X025A2 == 7 | X025A2 == 8)
	replace education = 10 if ( X023 >= 21 & X023 <= 98 )

	label define education2 1 "Less than 12 yo" 2 "13 yo" 3 "14 yo" 4 "15 yo" 5 "16 yo" 6 "17 yo" 7 "18 yo" 8 "19 yo" 9 "20 yo" 10 "more than 21 yo"
	label value education education2
	
	keep if (justif_homo != .) & (sex != .)& (year_birth != .) & (year_survey != .) & (religion != .)  & (political_scale != .) & (education !=.)

	generate year_survey2 = year_survey - 1981 

	generate year_survey2_not_religious= 0
	replace year_survey2_not_religious = year_survey2 if religion == 2

	generate year_survey2_ahteist_convinced= 0
	replace year_survey2_ahteist_convinced = year_survey2 if religion == 3
		
	generate dum_educ = .
	replace dum_educ = 1 if education <5
	replace dum_educ = 2 if (education >= 5 & education < 9)
	replace dum_educ = 3 if education >= 9

	label define label_educ 1 "less_16" 2 "between_16_19" 3 "more_19" 
	label value dum_educ label_educ
	
		
end

/* Secondly, we create the program that displays the graphs of average marginal effects for a country chosen by the user. Moreover,
	in order to help the user to understand some result, the program also displays the table of the year for which the survey
	were implementing in the corresponding country */

program marg_effect

	prepare_data

	keep if country2 == "`0'"
	
	xi: quietly oprobit justif_homo i.sex year_birth year_survey2 i.religion i.dum_educ ///
	political_scale year_survey2_not_religious year_survey2_ahteist_convinced
	
	quietly margins, dydx( _Isex_2 year_birth year_survey2 _Ireligion_2 _Ireligion_3 ///
	_Idum_educ_2 _Idum_educ_3 political_scale year_survey2_not_religious ///
	year_survey2_ahteist_convinced) predict(outcome(10)) post
	
	marginsplot, horizontal unique xline(0) recast(scatter) ylabel(1 "Female" 2 "Year birth" 3 "Year survey" 4 "Not religious" ///
	 5 "Convinced atheist" 6 "Educ btween 16 yo and 19 yo" 7 "Educ after 19" 8 "Political scale" 9 "Yeas survey : Not religious" ///
	 10 "Year survey : Convinced atheist") ytitle("") title ("Average marginal effect on P(justif_homo = 10)", color(black)) ///
	 subtitle(" ", margin(l+0 r+0 b-1 t-1))

	tabulate year_survey
end

marg_effect United States

marg_effect France

/* We can calculate the result of our probit model for the country you want included in this list of countries */

/*
Albania					Finland					Mexico					South Africa
Algeria					France					Moldova					South Korea
Andorra					Georgia					Montenegro				Spain
Argentina				Germany					Morocco					Sweden
Armenia					Ghana					Netherlands				Switzerland
Australia				Greece					New Zealand				Taiwan ROC
Azerbaijan				Guatemala				Nicaragua				Tanzania
Bangladesh				Hong Kong SAR			Nigeria					Thailand
Belarus					Hungary					North Macedonia			Trinidad and Tobago
Bolivia					India					Norway					Tunisia
Bosnia Herzegovina		Indonesia				Pakistan				Turkey
Brazil					Iran					Palestine				Uganda
Bulgaria				Iraq					Peru					Ukraine
Burkina Faso			Italy					Philippines				United Kingdom
Canada					Japan					Poland					United States
Chile					Jordan					Portugal				Uruguay
Colombia				Kazakhstan				Puerto Rico				Uzbekistan
Cyprus					Kyrgyzstan				Romania					Venezuela
Czech Rep.				Lebanon					Russia					Vietnam
Dominican Rep.			Libya					Rwanda					Yemen
Ecuador					Macau SAR				Serbia					Zambia
Estonia					Malaysia				Slovakia				Zimbabwe
Ethiopia				Mali					Slovenia	
*/

















