/* Projet SAS */



/******************************/
/*     PARTIE I : SAS SQL      /
/******************************/

/**************/
/* Question 1 */
/**************/

/* Au lieu de répéter 8 fois un code similaire d'importation des données, nous créons une macro fonction permettant d'importer les différentes 
tables.*/

libname projet "C:\Users\Antoi\OneDrive\Université\Master 1\Semestre 2\SAS\Projet";

%macro importer_data(tab_name, file_name, add_date, variab1, variab2, variab3, variab4, variab5, variab6, variab7, variab8, variab9, variab10, variab11, variab12, variab13, variab14, variab15, variab16 );  

	data projet.&tab_name;
		infile "C:\Users\Antoi\OneDrive\Université\Master 1\Semestre 2\SAS\Projet\Données - projet-20210130\Fichiers de données\&file_name"
			 dlm = ";"
	         firstobs=2
	         DSD;

 
     	input
	         &variab1 
	         &variab2 
	         &variab3 
	         &variab4 
			 &variab5 
			 &variab6
			 &variab7
			 &variab8
			 &variab9
			 &variab10
			 &variab11
			 &variab12
			 &variab13
			 &variab14
			 &variab15
			 &variab16

     ;
 	run;

	/* Certaines tables contiennent des dates qui doivent être formatées. Ainsi, nous posons une condition dans la fonction,
	celle-ci peut être validée ou non par l'usagé, en fonction de la présence d'une variable "date" dans les données. */

%IF &add_date = "yes" %THEN 
%do;

	data projet.&tab_name;

		
		set projet.&tab_name;

		 date = input(put(date,10.), yymmdd10.);


		 format date yymmdd10. ;
 
run;

%end;


%mend;

/* Option yearcutoff = 1900 prend 1900 comme année de référence lorsque l'on rencontre une valeur annuelle à deux chiffres,  
ce qui nous permet une cohérence dans de futurs résultats.
 Sans cette commande, nous obtenons des âges négatifs. */

option yearcutoff = 1900;

%importer_data(account,account.txt, "yes", account_id, district_id, frequency :$30. , date);
%importer_data(card1,card.txt, "no", card_id, disp_id, type $, issued :$30.) ;
%importer_data(client1,client.txt, "no", client_id, birth_number, district_id);
%importer_data(disp,disp.txt, "no", disp_id, client_id, account_id, type :$30.);
%importer_data(district,district.txt, "no", district_id, district_name :$30., region :$30., A4, A5, A6, A8, A9, A10, A11, A12, A13, A14, A15, A16);
%importer_data(loan,loan.txt, "yes", loan_id, account_id, date, amount, duration, payments, status $);
%importer_data(order,order.txt, "no", order_id, account_id, bank_to $, account_to, amount, k_symbol $);
%importer_data(trans,trans.txt, "yes", trans_id, account_id, date, type $, operation $, amount, balance, k_symbol $, bank $, account);

/* La table Client contient une spécialité : la colonne "birth_corr" contient l'information du sexe de l'individu. 
En effet, si l'individu est une femme, alors birth_corr = birth_number - 5000. */

data projet.client;
	set projet.client1;
	
  	birth_corr = input(put(birth_number,10.), yymmdd10.);
  	format birth_corr yymmdd10. ;
	if (birth_corr = .) then sex = "F" ; else sex = "H";
	if (sex = "F") then birth_corr = input(put(birth_number - 5000, 10.), yymmdd10.);

 
run;

/* Création d'une variable permettant de recoder la date */

data projet.card;

	set projet.card1;
  	issued_corr = input(issued,ANYDTDTE19.);
  	format issued_corr yymmdd10. ;
	
run;

/* Nous supprimons les tables superflues */

proc datasets library = projet ;
    delete Client1 Card1;
run;

/**************/
/* Question 3 */
/**************/

/* Nombre de clients par sexe en fonction du district */

proc sql ;

	select district_id label = "Identifiant district", 
		   sex label = "Sexe",
		   count(distinct client_id) as nb_client label = "Nombre de clients"
	from projet.client
	group by district_id, sex
	order by district_id asc
	;

quit ;

/**************/
/* Question 4 */
/**************/

/* Nombre de clients par sexe en fonction du district et de la région */

proc sql ;

	select A.district_id label = "Identifiant du district", 
		   B.district_name label = "Nom du district",
		   B.region lavel = "Region",
		   A.sex label = "Sexe du client", 
		   count(distinct A.client_id) as nb_client label = "Nombre de clients"
			
			
	from projet.client as A, projet.district as B
	where A.district_id = B.district_id
	group by A.district_id, A.sex, B.district_name, B.region
	order by A.district_id asc
	;

quit ;

/**************/
/* Question 5 */
/**************/

/* Nombre de clients homme et femme en fonction du discrict, pour les districts contenant plus de 100 clients */

proc sql ;

	select A.district_id label = "Identifiant district",
		   B.district_name label = "Nom du district",
		   B.region lavel = "Région",
		   count(distinct A.client_id) as nb_client label = "Nombre de clients",
		   sum(A.sex = "H") as clients_hommes,
		   sum(A.sex = "F") as clients_femmes

	from projet.client as A, projet.district as B
	where A.district_id = B.district_id 
	group by A.district_id, B.district_name , B.region
	having nb_client > 100
	;

quit ;

/**************/
/* Question 6 */
/**************/

/* Nombre d'ordres pour les clients possédant au moins un compte, en fonction de l'âge */

proc sql ;

	select  2010 - YEAR(birth_corr) as age label = "Age des clients",
			count(distinct A.client_id) as nb_clients label = "Nombre de clients",
			count( C.account_id) as nb_ordres label = "Nombre d'ordres"	

	from projet.client as A, projet.disp as B , projet.order as C
	where A.client_id = B.client_id and B.account_id = C.account_id  
	group by age
	;

quit ;


/**************/
/* Question 7 */
/**************/

/* Informations concernant les prêts telles que leur nombre ou leur durée en fonction du type de carte */

proc sql ;

	select A.type, 
			count(distinct C.account_id) as nb_account label = "Nombre de comptes avec un emprunt",
			min(C.amount) format=dollar16. as min_amount label = "Montant minimum des emprunts",
			avg(C.amount) format=dollar16. as mean_amount label = "Montant moyen des emprunts",
			max(C.amount) format=dollar16. as max_amount label = "Montant maximum des emprunts",
			min(C.duration) as min_duration label = "Durée minimum des emprunts",
			avg(C.duration) format = 6. as mean_duration label = "Durée minimum des emprunts",
			max(C.duration) as max_duration label = "Durée minimum des emprunts",
			sum(C.status = "A") as nb_A label = "Nombre d'emprunts catégorie A",
			sum(C.status = "B") as nb_B label = "Nombre d'emprunts catégorie B",
			sum(C.status = "C") as nb_C label = "Nombre d'emprunts catégorie C",
			sum(C.status = "D") as nb_D label = "Nombre d'emprunts catégorie D"

	from projet.card as A, projet.disp as B , projet.loan as C
	where A.disp_id = B.disp_id and B.account_id = C.account_id

	group by A.type
	;

quit ;


/**************/
/* Question 8 */
/**************/

/* Nombre de compte ayant bénéficié d'un emprunt par type de carte et catégorie d'emprunt suivi de statistiques
   quantitatives sur le montant et la durée du prêt */

proc sql ;

	select C.status,
			A.type, 
			count(distinct C.account_id) as nb_account label = "Nombre de comptes avec un emprunt",
			avg(C.amount) format=dollar16. as mean_amount label = "Montant moyen des emprunts",
			min(C.amount) format=dollar16. as min_amount label = "Montant minimum des emprunts",
			max(C.amount) format=dollar16. as max_amount label = "Montant maximum des emprunts",
			var(C.amount) as var_amount label = "Variance des montants",
			std(C.amount) as sd_amount label = "Écart moyen des montants",
			avg(C.duration) as mean_duration format = 10. label = "Durée minimum des emprunts",
			min(C.duration) as min_duration label = "Durée minimum des emprunts",
			max(C.duration) as max_duration label = "Durée minimum des emprunts",
			var(C.duration) as var_duration label = "Variance des durées",
			std(C.duration) as sd_duration label = "Écart moyen des durées"

	from projet.card as A, projet.disp as B , projet.loan as C
	where A.disp_id = B.disp_id and B.account_id = C.account_id

	group by  C.status, A.type
	;

quit ;


/**************/
/* Question 9 */
/**************/

/* Création d'une table qui regroupe les informations de chaque clients en y ajoutant leur âge.
   On fusionne les tables clients et disp avec un full join car leur relation est 1-1.
   Afin de garder toutes les lignes de la table clients, on effectue un left join lors de la fusion avec
   la table card 
*/


/*
proc sql ;
create table client_macro as
	select  A.client_id, A.birth_number, A.district_id, A.birth_corr, A.sex,
			B.disp_id, B.account_id, B.type, C.card_id, C.issued, C.issued_corr, C.type as type_card ,
			2010 - YEAR(birth_corr) as age 
	from projet.client as A, projet.disp as B, projet.card as C
	where A.client_id = B.client_id and B.disp_id = C.disp_id
	;
quit;
*/

proc sql;
	create table projet.client_mac (drop =type) as
	select *, 
		   2010 - YEAR(birth_corr) as age, 
           type as type_account   

	from  projet.client Full join projet.disp
	on client.client_id = disp.client_id
	;
quit;

proc sql; 
	create table projet.client_macro (drop = type) as
	select *, 
		   type as type_card 

	from projet.client_mac left join projet.card
	on client_mac.disp_id = card.disp_id
	;
quit;



/******************************/
/*   PARTIE II : SAS MACRO     /
/******************************/

/* A - Sondage aléatoire simple (AS) */

/**************/
/* Question 1 */
/**************/

/* Création d'un échantillon aléatoire de 200 observations sur la table "client_macro" */

data projet.test;
	set projet.client_macro;
		 alea = ranuni(0);
run;

/* Tri des observations en fonction de l'alée */

proc sort data=projet.test out=projet.test;
   by alea ;
run;

data projet.test;
    set projet.test(obs=200);
run;

/**************/
/* Question 2 */
/**************/

/* Ajout de paramètre permettant de choisir la taille de l'échantillon, la table à échantilloner et le nom de la table
de sortie */

%let tab_entree = client_macro;
%let tab_sortie = client_macro1;
%let nb_obs = 200;

data projet.&tab_sortie;
	set projet.&tab_entree;
		 alea = ranuni(0);
run;

proc sort data=projet.&tab_sortie out=projet.&tab_sortie;
   by alea ;
run;

data projet.&tab_sortie;
    set projet.&tab_sortie(obs=&nb_obs);
run;

/**************/
/* Question 3 */
/**************/

/* Ici, l'usager ne choisit plus un nombre d'observations mais un pourcentage d'observation à extraire */

%let tab_entree = client_macro;
%let tab_sortie = client_macro1;
%let part_obs = %sysevalf(10);

data projet.&tab_sortie;
	set projet.&tab_entree;
		 alea = ranuni(0);
run;

proc sort data=projet.&tab_sortie out=projet.&tab_sortie;
   by alea ;
run;

/* On récupère le nombre de lignes de la table client_macro pour pouvoir ensuite 
  en retirer le pourcentage souhaité d'observations */

data _null_;
	set projet.&tab_sortie end = last;
	If last then call symput("n_obs", _N_);
run;

data projet.&tab_sortie;
    set projet.&tab_sortie(obs = %sysfunc(round(%sysevalf((&part_obs/100) * &n_obs),1)));
run;

/**************/
/* Question 4 */
/**************/

/* Création d'une macro fonction permettant de prélever un échantillon aléatoire sur une table de données */

%macro AS(tab_entree, tab_sortie, part_obs);

	data projet.&tab_sortie;
		set projet.&tab_entree;
			 alea = ranuni(0);
	run;

	proc sort data=projet.&tab_sortie out=projet.&tab_sortie;
	   by alea ;
	run;

	data _null_;
		set projet.&tab_sortie end = last;
		If last then call symput("n_obs", _N_);
	run;

	data projet.&tab_sortie;
	    set projet.&tab_sortie(obs = %sysfunc(round(%sysevalf((&part_obs/100) * &n_obs),1)));
	run;

%mend;

%AS(client_macro, client_macro1, 20)


/* B - Sondage aléatoire stratifié */


/**************/
/* Question 1 */
/**************/

%macro ASTR(lib, tab, var_strat);

	/* Le proc sort permet d'isoler dans un tableau les modalités clés non dupliquées */
	
/*1*/

	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	/* Le data _null_ permet de créer des macros variables dans lesquelles sont introduites 
		le nombre de modalités et leur valeur */

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Le code ci-dessous permet d'afficher un message à l'utilisateur (nombre de modalités et 
	valeur des modalités */
	
	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;


%mend;

%ASTR(projet, client_macro, sex);

/**************/
/* Question 2 */
/**************/

%macro ASTR(lib, tab, var_strat);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Cette boucle permet de  créer, pour chaque modalité, un tableau ne contenant
	que les informations relatives à cette modalités.*/

	%do i=1 %to &N_modalite;

		data &lib..&&&modalite&i;

			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";

		run;

	%end;

	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;

%mend;

%ASTR(projet, client_macro, sex);

/**************/
/* Question 3 */
/**************/

%macro ASTR(lib, tab, var_strat, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	%do i=1 %to &N_modalite;
		data &lib..&&&modalite&i;
			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";
		run;

		/* Ici, nous faisons appel à la macro utilisée dans la partie A, afin de créer une nouvelle
		table représentant l'échantillon pour la modalité concernée*/
		
		%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

	%end;

	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;

%mend;

%ASTR(projet, client_macro, sex, 50);


/**************/
/* Question 4 */
/**************/

%macro ASTR(lib, tab, var_strat, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	data &lib..stratif;
		set &lib..stratif;
		where &var_strat <>"";
	run;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	%do i=1 %to &N_modalite;
		data &lib..&&&modalite&i;
			set &lib..&tab;
			where compress(&var_strat)="&&&modalite&i";
		run;
		
		%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);
		
	%end;

	/* La commande ci-dessous permet de concatener l'ensemble des échantillons en une seule table */

	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;


%mend;

%ASTR(projet, client_macro, sex, 50);

%ASTR(projet, client_macro, type_card, 50);

/**************/
/* Question 5 */
/**************/

%macro ASTR(lib, tab, var_strat, format, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;
	
	%if &format = "character" %then
		%do;
			data &lib..stratif;
				set &lib..stratif;
				where &var_strat <> "";
			run;
		%end;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* C'est au niveau du where que la condition change lorsque la variable stratifiée est sous
	format numérique. Ainsi, nous prenons en compte cette différence en rajoutant un IF, qui exécute
	un certain code en fonction du format de notre variable stratifiée*/

	%if &format = "numeric" %then

		%do i=1 %to &N_modalite;

			data &lib..data&&&modalite&i;
				set &lib..&tab;
				where &var_strat=&&&modalite&i;
			run;
			
			%AS(data&&&modalite&i, echant&&&modalite&i, &pourcent_obs);
			
		%end;

	%else

		%do i=1 %to &N_modalite;
			data &lib..&&&modalite&i;
				set &lib..&tab;
				where compress(&var_strat)="&&&modalite&i";
			run;
			
			%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);
			
		%end;
			
	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;


%mend;


%ASTR(projet, client_macro, sex, "character", 50);

%ASTR(projet, client_macro, district_id, "numeric", 50);


/**************/
/* Question 6 */
/**************/

%macro ASTR(lib, tab, var_strat, format, pourcent_obs);
		
	proc sort data = &lib..&tab(keep = &var_strat) out = &lib..stratif nodupkeys;
		by &var_strat;
	run;

	%if &format = "character" %then
		%do;
			data &lib..stratif;
				set &lib..stratif;
				where &var_strat <> "";
			run;
		%end;

	%global N_modalite;

	data _null_;
		set &lib..stratif end = last;
		call symput(compress("modalite"!!_N_), compress(&var_strat));
		If last then call symput("N_modalite", _N_);
	run;

	/* Dans la boucle de création des échantillons, nous créons, à chaque itération, une macro-variable 
	prenant la valeur du nombre d'observations dans chaque échantillon.*/
	
	%if &format = "numeric" %then

		%do i=1 %to &N_modalite;

			data &lib..data&&&modalite&i;
				set &lib..&tab;
				where &var_strat=&&&modalite&i;
			run;
			
			%AS(data&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

			%global taille_sample&i;

			data _null_;
				set &lib..echant&&&modalite&i end = last;
				If last then call symput(compress("taille_sample"!!&i), _N_);
			run;
			
		%end;

	%else

		%do i=1 %to &N_modalite;
			data &lib..&&&modalite&i;
				set &lib..&tab;
				where compress(&var_strat)="&&&modalite&i";
			run;
			
			%AS(&&&modalite&i, echant&&&modalite&i, &pourcent_obs);

			%global taille_sample&i;

			data _null_;
				set &lib..echant&&&modalite&i end = last;
				If last then call symput(compress("taille_sample"!!&i), _N_);
			run;
			
		%end;

	data &lib..echantillon_final;
	  set
		%do i=1 %to &N_modalite ;
		   &lib..echant&&&modalite&i
		%end;
		;
	run;
	
	%global taille_final;

	data _null_;
		set &lib..echantillon_final end = last;
		If last then call symput("taille_final", _N_);
	run;

	%put "Il y a &N_modalite modalités dans cette variable";

	%do i=1 %to &N_modalite ;
		   %put "La modalité &i est &&&modalite&i";
	%end;

	/* Le code ci-dessous permet d'afficher le nombre d'observations pour chaque échantillon et pour la 
	table finale.*/

	%do i=1 %to &N_modalite ;
		   %put "Le nombre d'observations de l'échantillon &&&modalite&i est de &&&taille_sample&i";
	%end;

	%put "Le nombre d'observations de l'échantillon total est de &taille_final";

	%put &modalite1;

%mend;

%ASTR(projet, client_macro, sex, "character", 10);

%ASTR(projet, client_macro, district_id, "numeric", 50);



