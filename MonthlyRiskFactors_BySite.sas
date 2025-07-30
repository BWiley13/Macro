
/******************************************************************************************************************/

LIBNAME CAPTIVA 'U:\DataDump\CAPTIVA\Daily';

PROC DATASETS;
	COPY IN= CAPTIVA
	OUT= WORK;
RUN;

proc sort data=subjectvisit; by zvisitid; run;
proc sort data=zvisit; by zvisitid; run;

data visit_window;
	merge subjectvisit zvisit (keep= zvisitid zvisitnm);
	by zvisitid;
	
	if zsubjectid ne . then output;
run;

proc sort data=visit_window; by zsubjectid; run;

proc transpose data=visit_window out=visit_window2;
	by zsubjectid;
	id zVisitNm;
	var zvisitdate;
run; 

data visit_window3;
	set visit_window2;

	bl_target=Baseline;
	one_target=intnx('month',Baseline,1,'same');
	four_target=intnx('month',Baseline,4,'same');
	eight_target=intnx('month',Baseline,8,'same');
	twelve_target=intnx('month',Baseline,12,'same');
	
	bl_l=bl_target - 90;
	bl_u=bl_target + 7;
	one_l= one_target - 10;
	one_u= one_target + 10;
	four_l= four_target - 30;
	four_u= four_target + 30;
	eight_l= eight_target - 30;
	eight_u= eight_target + 30;
	twelve_l= twelve_target - 30;

	if 'End of Study'n = . then twelve_u= twelve_target + 30;
	if 'End of Study'n ne . then twelve_u='End of Study'n;

	format bl_l bl_u one_l one_u four_l four_u eight_l eight_u twelve_l twelve_u date9.;
	format bl_target one_target four_target eight_target twelve_target date9.;
run;



proc sort data=form117; by zsubjectid f117zformdate; run; 

data form117_2;
	do until (last.zsubjectid);
	set form117;
	by zsubjectid f117zformdate;
	if f117zheightin ne . then height=f117q09v;
	if f117zheightin ne . then heightunit=f117q09u;
	output;
	end;

run;


proc sort data=form117_2; by zsubjectid f117zformdate; run;


data form117_bmi;
	set form117_2;
	by zsubjectid f117zformdate;

	if f117q08u=1 then weightlbs=round(f117q08v*2.2046,0.1);
		else weightlbs=round(f117q08v,0.1);

	if heightunit=1 then heightinches=round(height/2.54,0.1);
		else heightinches=round(height,0.1);

	/*if f117q08u=1 then bmi=f117q08v/((height/100)**2);
		else*/ bmi=(weightlbs/(heightinches**2))*703;

	/*if first.zsubjectid then do;
		if bmi le 27 then target3=25;
		 else if bmi>27 then target3=bmi-(bmi*.1);
	end;*/
run;

proc sql;
	create table bmi_target as
	select zsubjectid, case when bmi le 27 then 25 else bmi-(bmi*.1) end as target2
	from form117_bmi
	where bmi ne .
	group by zsubjectid
	having f117zformdate=min(f117zformdate)
	order by zsubjectid;
quit;


/*Stack all Laboratory Test Form Data*/
proc sql;

	create table f105 as
	select *
	from(

	select zsubjectid, zcrfid, zsiteid, zvisitnm, zvisitdate, f105q01, f105q13, f105q03v, f105q07v, f105q10v, f105q08v, f105q09v, f105q12v, f105q16, f105q15, f105q14, f105q18, f105q17, f105znotes, 1 as visit_ind, zvisitnm as visit_rename   
	from form105

	union

	select zsubjectid, zcrfid, zsiteid, zvisitnm, zvisitdate, f105aq01, f105aq13, f105aq03v, f105aq07v, f105aq10v, f105aq08v, f105aq09v, f105aq12v, f105aq16, f105aq15, f105aq14, f105aq18, f105aq17, f105aznotes, 2 as visit_ind_a, "Re-Assessment" as visit_rename_a
	from form105a

	union 

	select zsubjectid, zcrfid, zsiteid, zvisitnm, zvisitdate, f105bq01, f105bq13, f105bq03v, f105bq07v, f105bq10v, f105bq08v, f105bq09v, f105bq12v, f105bq16, f105bq15, f105bq14, f105bq18, f105bq17, /*CHANGE THIS ONCE WE HAVE DATA FOR F105B*/' ' as f105bznotes, 3 as visit_ind_b, "As Needed" as visit_rename_b
	from form105b

	)

	order by zsubjectid;
quit;


/*Stack all Vital Signs Form Data*/
proc sql;

	create table f117_0 as
	select *
	from(

	select zsubjectid, zcrfid, zsiteid, zvisitnm, zvisitdate, f117zformdate, f117q21, f117q23, f117q03, f117q04, f117q05, f117q26, f117q27, f117q28, f117q29, f117q33, f117q34, f117q35, f117znotes, bmi, 1 as visit_ind, zvisitnm as visit_rename, weightlbs     
	from form117_bmi

	union

	select zsubjectid, zcrfid, zsiteid, zvisitnm, zvisitdate, f117azformdate, f117aq21, f117aq23, f117aq03, f117aq04, f117aq05, f117aq26, f117aq27, f117aq28, f117aq29, f117aq33, f117aq34, f117aq35, f117aznotes, . as bmia, 2 as visit_ind_a, "Re-Assessment" as visit_rename_a, . as weightlbs  
	from form117a

	union 

	select zsubjectid, zcrfid, zsiteid, zvisitnm, zvisitdate, f117bzformdate, f117bq21, f117bq23, f117bq03, f117bq04, f117bq05, f117bq26, f117bq27, f117bq28, f117bq29, . as f117bq33, . as f117bq34, '' as f117bq35, f117bznotes, . as target_bmib, 3 as visit_ind_b, "As Needed" as visit_rename_b, . as weightlbs    
	from form117b

	)

	order by zsubjectid;
quit;

data f117;
	merge f117_0 bmi_target;
	by zsubjectid;
run;

 
data f105_2;
	merge f105 visit_window3;
	by zsubjectid;
run;

data f117_2;
	merge f117 visit_window3;
	by zsubjectid;
run;

data f105_3;
	set f105_2;
	
	
		 if f105q01 ne . and f105q01>bl_l and f105q01 <bl_u then zvisitnm2="Baseline";
	else if f105q01 ne . and f105q01>one_l and f105q01<one_u then zvisitnm2="1 Month";
	else if f105q01 ne . and f105q01>four_l and f105q01<four_u then zvisitnm2="4 Month";
	else if f105q01 ne . and f105q01>eight_l and f105q01<eight_u then zvisitnm2="8 Month";
	else if f105q01 ne . and f105q01>twelve_l and f105q01<twelve_u then zvisitnm2="12 Month";
	else if f105q01 ne . and visit_ind=2 then zvisitnm2="Re-Assess.";
	else if f105q01 ne . then zvisitnm2="Unsched.";


	/*if f105q01 ne . and visit_ind=2 then zvisitnm2='Re-Assessment';
	  if f105q01 ne . and visit_ind=3 then zvisitnm2='As Needed';*/

	/*****LOOK AT THIS PROGRAMMING - SHOULD IT BE ELSE IF OR JUST IF OR ELSE AT THE END???************/

	today=today();

	if today > one_u then ind1=1; else ind1=0;
	if today > four_u then ind4=1; else ind4=0;
	if today > eight_u then ind8=1; else ind8=0;
	if today > twelve_u then ind12=1; else ind12=0;

run;

	
data f117_3;
	set f117_2;

		 if f117zformdate ne . and f117zformdate>bl_l and f117zformdate<bl_u  then zvisitnm2="Baseline";
	else if f117zformdate ne . and f117zformdate>one_l and f117zformdate<one_u then zvisitnm2="1 Month";
	else if f117zformdate ne . and f117zformdate>four_l and f117zformdate<four_u then zvisitnm2="4 Month";
	else if f117zformdate ne . and f117zformdate>eight_l and f117zformdate<eight_u then zvisitnm2="8 Month";
	else if f117zformdate ne . and f117zformdate>twelve_l and f117zformdate<twelve_u then zvisitnm2="12 Month";
	else if f117zformdate ne . and visit_ind=2 then zvisitnm2="Re-Assess.";
	else if f117zformdate ne . then zvisitnm2="Unsched.";

	/*if f117zformdate ne . and visit_ind=2 then zvisitnm2='Re-Assessment';
	if f117zformdate ne . and visit_ind=3 then zvisitnm2='As Needed';*/

	/*****LOOK AT THIS PROGRAMMING - SHOULD IT BE ELSE IF OR JUST IF OR ELSE AT THE END???************/
	
	today=today();

	if today > one_u then ind1=1; else ind1=0;
	if today > four_u then ind4=1; else ind4=0;
	if today > eight_u then ind8=1; else ind8=0;
	if today > twelve_u then ind12=1; else ind12=0;

	msbl=intck('month',Baseline,today);

run;



/********************************************SBP*****************************************************/
proc sql noprint;

	/*LDL                                                                           */

	create table f105_baseline as
	select distinct zsubjectid, zsiteid, f105q01, f105q10v, zvisitnm2, case when f105q10v < 70 then 1 else 0 end as intarget
	from f105_3
	where zvisitnm2='Baseline' and f105q10v ne .
	group by zsubjectid
	having f105q01 = max(f105q01);

	create table f105_last as
	select distinct zsubjectid, zsiteid, f105q01, f105q10v, zvisitnm2, case when f105q10v < 70 then 1 else 0 end as intarget
	from f105_3
	where f105q10v ne . and zvisitnm2 ne 'Baseline'
	group by zsubjectid
	having f105q01 = max(f105q01);
	
	create table f105_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from f105_baseline
	group by zsiteid;

	create table f105_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from f105_baseline2;

	create table f105_baseline4 as
	select *
	from f105_baseline3;

	insert into f105_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from f105_baseline3;

	create table f105_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from f105_last
	group by zsiteid;

	create table f105_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from f105_last2; 

	create table f105_last4 as
	select *
	from f105_last3;

	insert into f105_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from f105_last3;

	/*SBP                                                                           */

	create table f117_baseline as
	select distinct zsubjectid, zsiteid, f117zformdate, f117q03, zvisitnm2, case when f117q03 < 140 then 1 else 0 end as intarget
	from f117_3
	where zvisitnm2='Baseline' and f117q03 ne .
	group by zsubjectid
	having f117zformdate = max(f117zformdate);

	create table f117_last as
	select distinct zsubjectid, zsiteid, f117zformdate, f117q03, zvisitnm2, case when f117q03 < 140 then 1 else 0 end as intarget
	from f117_3
	where f117q03 ne . and zvisitnm2 ne 'Baseline'
	group by zsubjectid
	having f117zformdate = max(f117zformdate);
	
	create table f117_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from f117_baseline
	group by zsiteid;

	create table f117_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from f117_baseline2;

	create table f117_baseline4 as
	select *
	from f117_baseline3;

	insert into f117_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from f117_baseline3;

	create table f117_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from f117_last
	group by zsiteid;

	create table f117_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from f117_last2; 

	create table f117_last4 as
	select *
	from f117_last3;

	insert into f117_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from f117_last3;

	/*SRF                                                                                                            */
	
	/*HDL*/

	create table hdl_baseline as
	select distinct zsubjectid, zsiteid, f105q01, (f105q08v - f105q09v) as value, zvisitnm2, case when (f105q08v - f105q09v) < 100 then 1 else 0 end as intarget
	from f105_3
	where zvisitnm2='Baseline' and f105q08v ne . and f105q09v ne .
	group by zsubjectid
	having f105q01 = max(f105q01);

	create table hdl_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from hdl_baseline
	group by zsiteid;

	create table hdl_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from hdl_baseline2;

	create table hdl_baseline4 as
	select *
	from hdl_baseline3;

	insert into hdl_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from hdl_baseline3;


	create table hdl_last as
	select distinct zsubjectid, zsiteid, f105q01, (f105q08v - f105q09v) as value, zvisitnm2, case when (f105q08v - f105q09v) < 100 then 1 else 0 end as intarget
	from f105_3
	where f105q08v ne . and f105q09v ne . and zvisitnm2 ne 'Baseline'
	group by zsubjectid
	having f105q01 = max(f105q01);

	create table hdl_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from hdl_last
	group by zsiteid;

	create table hdl_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from hdl_last2; 

	create table hdl_last4 as
	select *
	from hdl_last3;

	insert into hdl_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from hdl_last3;

	/*BMI*/

	create table bmi_baseline as
	select distinct zsubjectid, zsiteid, f117zformdate, bmi as value, zvisitnm2, case when bmi < target2 then 1 else 0 end as intarget
	from f117_3
	where zvisitnm2='Baseline' and bmi ne .
	group by zsubjectid
	having f117zformdate = max(f117zformdate);

	create table bmi_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from bmi_baseline
	group by zsiteid;

	create table bmi_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from bmi_baseline2;

	create table bmi_baseline4 as
	select *
	from bmi_baseline3;

	insert into bmi_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from bmi_baseline3;

	create table bmi_last as
	select distinct zsubjectid, zsiteid, f117zformdate, bmi as value, zvisitnm2, case when bmi < target2 then 1 else 0 end as intarget
	from f117_3
	where bmi ne . and zvisitnm2 ne 'Baseline'
	group by zsubjectid
	having f117zformdate = max(f117zformdate);

	create table bmi_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from bmi_last
	group by zsiteid;

	create table bmi_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from bmi_last2; 

	create table bmi_last4 as
	select *
	from bmi_last3;

	insert into bmi_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from bmi_last3;
	
	/*HgA1c*/

	create table hga1c_baseline as
	select distinct zsubjectid, zsiteid, f105q01, f105q17 as value, zvisitnm2, case when f105q17 < 7 then 1 else 0 end as intarget
	from f105_3
	where zvisitnm2='Baseline' and f105q17 ne .
	group by zsubjectid
	having f105q01 = max(f105q01);

	create table hga1c_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from hga1c_baseline
	group by zsiteid;

	create table hga1c_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from hga1c_baseline2;

	create table hga1c_baseline4 as
	select *
	from hga1c_baseline3;

	insert into hga1c_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from hga1c_baseline3;

	create table hga1c_last as
	select distinct zsubjectid, zsiteid, f105q01, f105q17 as value, zvisitnm2, case when f105q17 < 7 then 1 else 0 end as intarget
	from f105_3
	where f105q17 ne . and zvisitnm2 ne 'Baseline'
	group by zsubjectid
	having f105q01 = max(f105q01);

	create table hga1c_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from hga1c_last
	group by zsiteid;

	create table hga1c_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from hga1c_last2; 

	create table hga1c_last4 as
	select *
	from hga1c_last3;

	insert into hga1c_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from hga1c_last3;

	/*physical activity*/

	create table physical_baseline as
	select distinct zsubjectid, zsiteid, f507zformdate, f507q01 as value, zvisitnm, case when f507q01 ge 4 then 1 else 0 end as intarget
	from form507
	where zvisitnm='Baseline' and f507q01 ne .
	group by zsubjectid
	having f507zformdate = max(f507zformdate);

	create table physical_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from physical_baseline
	group by zsiteid;

	create table physical_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from physical_baseline2;

	create table physical_baseline4 as
	select *
	from physical_baseline3;

	insert into physical_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from physical_baseline3;
	
	create table physical_last as
	select distinct zsubjectid, zsiteid, f507zformdate, f507q01 as value, zvisitnm, case when f507q01 > 4 then 1 else 0 end as intarget
	from form507
	where f507q01 ne . and zvisitnm ne 'Baseline'
	group by zsubjectid
	having f507zformdate = max(f507zformdate);

	create table physical_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from physical_last
	group by zsiteid;

	create table physical_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from physical_last2; 

	create table physical_last4 as
	select *
	from physical_last3;

	insert into physical_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from physical_last3;

	/*smoking*/

	create table smoking_baseline as
	select distinct zsubjectid, zsiteid, f508zformdate, f508q01 as value, zvisitnm, case when f508q01 in (1 5 6) then 1 else 0 end as intarget
	from form508
	where zvisitnm='Baseline' and f508q01 ne .
	group by zsubjectid
	having f508zformdate = max(f508zformdate);

	create table smoking_baseline2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from smoking_baseline
	group by zsiteid;

	create table smoking_baseline3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Baseline' as group
	from smoking_baseline2;

	create table smoking_baseline4 as
	select *
	from smoking_baseline3;

	insert into smoking_baseline4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Baseline' as group 
	from smoking_baseline3;


	create table smoking_last as
	select distinct zsubjectid, zsiteid, f508zformdate, f508q01 as value, zvisitnm, case when f508q01 in (1 5 6) then 1 else 0 end as intarget
	from form508
	where f508q01 ne . and zvisitnm ne 'Baseline'
	group by zsubjectid
	having f508zformdate = max(f508zformdate);

	create table smoking_last2 as
	select distinct zsiteid, sum(intarget) as site_intarget, count(zsiteid) as site_total
	from smoking_last
	group by zsiteid;

	create table smoking_last3 as
	select *, site_intarget/site_total as site_pct format=percent10., 'Last' as group
	from smoking_last2; 

	create table smoking_last4 as
	select *
	from smoking_last3;

	insert into smoking_last4
  	select 9999 as zsiteid, sum(site_intarget) as site_intarget, sum(site_total) as site_total, sum(site_intarget)/sum(site_total) as site_pct, 'Last' as group 
	from smoking_last3;


quit;

data final_sbp;
	set f117_baseline4 f117_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;

data final_ldl;
	set f105_baseline4 f105_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;

data final_hdl;
	set hdl_baseline4 hdl_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;

data final_bmi;
	set bmi_baseline4 bmi_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;

data final_hga1c;
	set hga1c_baseline4 hga1c_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;

data final_physical;
	set physical_baseline4 physical_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;

data final_smoking;
	set smoking_baseline4 smoking_last4;
	var=cat(site_intarget,'/',site_total,' (',strip(put(site_pct,percent.)),')');
run;








proc format;
	value sitefmt 9999='CAPTIVA Overall'
				  0-9998='Your Site';

	value $groupfmt 'Baseline'='Baseline'
					'Last'='Last Follow-Up';
	
run; 








proc sort data=final_ldl; by zsiteid; run;
proc sort data=final_sbp; by zsiteid; run;

data mergetest;
	merge final_ldl (keep= zsiteid var group site_pct rename=(group=group1)) final_sbp (keep=zsiteid var group site_pct rename=(group=group2 var=var2 site_pct=site_pct2));
	by zsiteid;
run;

proc sort data=final_physical; by zsiteid; run;
proc sort data=final_hga1c; by zsiteid; run;
proc sort data=final_hdl; by zsiteid; run;
proc sort data=final_smoking; by zsiteid; run;
proc sort data=final_bmi; by zsiteid; run;

data mergetest2;
	merge final_physical (keep= zsiteid var group site_pct rename=(group=group1)) final_hga1c (keep=zsiteid var group site_pct rename=(group=group2 var=var2 site_pct=site_pct2))
		  final_hdl (keep=zsiteid var group site_pct rename=(group=group3 var=var3 site_pct=site_pct3)) final_smoking (keep=zsiteid var group site_pct rename=(group=group4 var=var4 site_pct=site_pct4))
          final_bmi (keep=zsiteid var group site_pct rename=(group=group5 var=var5 site_pct=site_pct5));
	by zsiteid;
run;




/*Produce Graphs                                                                                                               */

proc template;
define statgraph secondarygraph ;
 		begingraph / designheight=900px designwidth=850px ;

			layout lattice / columns=2 rows=3    ;

				cell; cellheader ; layout gridded ; entry "Physical Activity" ; endlayout; endcellheader; 

				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold)  linearopts=(viewmax=1)) 
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
				barchart x=group1 y=site_pct / group=zsiteid groupdisplay=cluster name="A";
					innermargin ;
						axistable x=group1 value=var / class=zsiteid classdisplay=cluster label=' ' ;	
					endinnermargin;
				endlayout;
				endcell;

				cell; cellheader ; layout gridded ; entry "HgA1c" ; endlayout; endcellheader;
				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold) 
												linearopts=(viewmax=1 tickvaluesequence=(start=0 end=1 increment=.2))
													)
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
		     
				barchart x=group2 y=site_pct2  / group=zsiteid groupdisplay=cluster ;
				
					innermargin / align=bottom ;
						axistable x=group2 value=var2 / class=zsiteid classdisplay=cluster label=' ' ;
					endinnermargin;
				endlayout;
				endcell;

				cell; cellheader ; layout gridded ; entry "Non-HDL" ; endlayout; endcellheader; 

				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold)  linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
				barchart x=group3 y=site_pct3 / group=zsiteid groupdisplay=cluster;
					innermargin ;
						axistable x=group3 value=var3 / class=zsiteid classdisplay=cluster label=' ' ;	
					endinnermargin;
				endlayout;
				endcell;

				cell; cellheader ; layout gridded ; entry "Smoking Cessation" ; endlayout; endcellheader; 

				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold)  linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
				barchart x=group4 y=site_pct4 / group=zsiteid groupdisplay=cluster;
					innermargin ;
						axistable x=group4 value=var4 / class=zsiteid classdisplay=cluster label=' ' ;	
					endinnermargin;
				endlayout;
				endcell;

				cell; cellheader ; layout gridded ; entry "Weight Management (BMI)" ; endlayout; endcellheader; 

				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold)  linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
				barchart x=group5 y=site_pct5 / group=zsiteid groupdisplay=cluster;
					innermargin ;
						axistable x=group5 value=var5 / class=zsiteid classdisplay=cluster label=' ' ;	
					endinnermargin;
				endlayout;
				endcell;

					sidebar / align=Top ;
						discretelegend "A"  / border=True  borderattrs=(Thickness=2) ;
					endsidebar;

					sidebar / align=left ;
						entry "% In Target"  / border=false  borderattrs=(Thickness=2) rotate=90 textattrs=( size=12pt) ;
					endsidebar;

			endlayout;
		endgraph;
end;
								
run;




proc sql;
	select distinct zsiteid into : site_list separated by " "
	from vsiteenrollmentsummary
	where zenrolled ne . and zcurrentstatusid ne 6;
quit;


proc sql;
	create table form126_new as
	select zsubjectid, '*' as ind
	from form126
	order by zsubjectid;
quit;

proc sql;
	create table ldltargetfailure as
	select zsubjectid, '+' as ind2
	from vldlrisktargetfailure
	where zldlq01=1 and zldlq02 ne .
	order by zsubjectid;
quit;

proc sql;
	create table sbptargetfailure as
	select zsubjectid, '+' as ind2
	from vsbprisktargetfailure
	where zsbpq01=1 and zsbpq02 ne .
	order by zsubjectid;
quit;

data f105_last_new;
	merge f105_last form126_new ldltargetfailure;
	by zsubjectid;

	tag=cats(zsubjectid,ind,ind2);

	if zsubjectid not in (1123 1300 1362) then output;
run;

data f117_last_new;
	merge f117_last form126_new sbptargetfailure;
	by zsubjectid;

	tag=cats(zsubjectid,ind,ind2);

	if zsubjectid not in (1123 1300 1362) then output;
run;


%macro site_report_monthly;


%let end=%sysfunc(countw(&site_list));   
%put &end.;

%do x=1 %to &end;

%let var=%scan(&site_list,&x.);

title "&var.";

proc sql;
	select distinct tag into : ldl_subj_&var. separated by " "
	from f105_last_new
	where intarget=0 and zsiteid in (&var.);
quit;



proc sql;
	select distinct tag into : sbp_subj_&var. separated by " "
	from f117_last_new
	where intarget=0 and zsiteid in (&var.);
quit;


proc template;
define statgraph primarygraph&var. ;
 		begingraph / designheight=800px designwidth=850px  ;

		layout lattice / columns=1 rows=3 rowweights=(.7 .15 .15);
			layout lattice / columns=2 columngutter=10 ;

				cell; cellheader ; layout gridded ; entry "LDL" ; endlayout; endcellheader; 

				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold)  linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
				barchart x=group1 y=site_pct / group=zsiteid groupdisplay=cluster name="A";
					innermargin ;
						axistable x=group1 value=var / class=zsiteid classdisplay=cluster label=' ' ;	
					endinnermargin;
				endlayout;
				endcell;

				cell; cellheader ; layout gridded ; entry "SBP" ; endlayout; endcellheader;
				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold) linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
		     
				barchart x=group2 y=site_pct2  / group=zsiteid groupdisplay=cluster ;
				
					innermargin / align=bottom ;
						axistable x=group2 value=var2 / class=zsiteid classdisplay=cluster label=' ' ;
					endinnermargin;

				endlayout;
				endcell;
			
					sidebar / align=Top ;
						discretelegend "A"  / border=True  borderattrs=(Thickness=2) across=2 ;
					endsidebar;

					sidebar / align=left ;
						entry "% In Target"  / border=false  borderattrs=(Thickness=2) rotate=90 textattrs=( size=12pt) ;
					endsidebar;	

			endlayout;

			cell;
			entry 
			%if %symexist(ldl_subj_&var.)  %then %do;
			"List of Subjects with LDL Out of Target at Last Follow-Up: &&&ldl_subj_&var.";
			%end;
			%else %do;
		
			"" ;
%end;
			endcell;

			cell;
			entry 
			%if %symexist(sbp_subj_&var.)  %then %do;
			"List of Subjects with SBP Out of Target at Last Follow-Up: &&&sbp_subj_&var.";
			%end;
			%else %do;
"" ;
%end;
			endcell;

			endlayout;

		endgraph;
end;
								
run;
%END;
%put _all_;


%let end=%sysfunc(countw(&site_list));   
%put &end.;

ods package(Zip) open nopf;

%do I=1 %to &end;

%let var=%scan(&site_list,&I.);  


footnote1 &textformat_left. color=black %sysfunc(datetime(),datetime16.) &textformat_right. color=black '~{thispage}';

title height=16pt justify=center "CAPTIVA Monthly Risk Factors Report -- Site" &var. "as of" &d_today2. ;

options orientation=portrait;

ods pdf style=pearl file="U:\Projects\CAPTIVA\Reports\RFM Reports\Monthly\&var..pdf" nogtitle nogfootnote startpage=no package(Zip);

/*ods graphics on / height=10in width=7in;*/



/*Primary Risk Factors*/

ods pdf text=' ';
ods pdf text="~S={outputwidth=100% font=('Times New Roman',12pt,bold) just=c}Primary Risk Factors";

proc sgrender data=mergetest template=primarygraph&var.;
where zsiteid=&var. or zsiteid=9999;
format group1 group2 $groupfmt.  zsiteid sitefmt.;
run;

ods pdf text="~S={outputwidth=100% font=('Times New Roman',8pt) just=l}*Subject is no longer active in the study";
ods pdf text="~S={outputwidth=100% font=('Times New Roman',8pt) just=l}+Subject has been declared failure to achieve target";


/*Secondary Risk Factors*/
ods pdf startpage=now;


ods pdf text=' ';
ods pdf text="~S={outputwidth=100% font=('Times New Roman',12pt,bold) just=c}Secondary Risk Factors";

proc sgrender data=mergetest2 template=secondarygraph;
where zsiteid=&var. or zsiteid=9999;
format group1 group2 group3 group4 group5 $groupfmt.  zsiteid sitefmt.;
run;

ods pdf close;



%END;

ods package(Zip) publish archive 
		properties (archive_name="monthlysitereports_&d_today..zip" 
					archive_path="U:\Projects\CAPTIVA\Reports\RFM Reports\Monthly");

ods package(Zip) close;	

%MEND;	






options nodate nonumber; 
options missing='';

%let textformat_left   = height=9pt  justify=l; 
%let textformat_center = height=9pt  justify=c; 
%let textformat_right = height=9pt  justify=r; 
%let currdt=%sysfunc(datetime());
%let d_today=%sysfunc(putn(%sysfunc(today()),date9.));
%let d_today2=%sysfunc(putn(%sysfunc(today()),mmddyy10.));

ods escapechar = "~";


%site_report_monthly;








/*PROC SGPLOT VERSION*/

/*proc sgplot data=final_ldl noautolegend;
where zsiteid=&var. or zsiteid=9999;
vbar group / response=site_pct group=zsiteid groupdisplay=cluster;
yaxis label='% in Target' max=1;
xaxis label=' ';
xaxistable zsiteid var / location=inside class=zsiteid classdisplay=cluster label=' ';
format group $groupfmt. zsiteid sitefmt.;
run;*/



/*PROC TEMPLATE VERSION*/

/*proc template;
define statgraph primarygraph ;
 		begingraph / designheight=700px designwidth=850px  ;

		layout lattice / columns=1 rows=3 rowweights=(.7 .15 .15);
			layout lattice / columns=2 columngutter=10 ;

				cell; cellheader ; layout gridded ; entry "LDL" ; endlayout; endcellheader; 

				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold)  linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
				barchart x=group1 y=site_pct / group=zsiteid groupdisplay=cluster name="A";
					innermargin ;
						axistable x=group1 value=var / class=zsiteid classdisplay=cluster label=' ' ;	
					endinnermargin;
				endlayout;
				endcell;

				cell; cellheader ; layout gridded ; entry "SBP" ; endlayout; endcellheader;
				layout overlay  / yaxisopts=(griddisplay=ON display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold) linearopts=(viewmax=1))
								  xaxisopts=(display=(Label Line ticks tickvalues )
													label=" " labelattrs=(weight=bold));
		     
				barchart x=group2 y=site_pct2  / group=zsiteid groupdisplay=cluster ;
				
					innermargin / align=bottom ;
						axistable x=group2 value=var2 / class=zsiteid classdisplay=cluster label=' ' ;
					endinnermargin;

				endlayout;
				endcell;
			
					sidebar / align=Bottom ;
						discretelegend "A"  / border=True  borderattrs=(Thickness=2) across=2 ;
					endsidebar;

					sidebar / align=left ;
						entry "% In Target"  / border=false  borderattrs=(Thickness=2) rotate=90 textattrs=( size=12pt) ;
					endsidebar;	

			endlayout;

			cell;
			entry "List of Subjects with LDL Out of Target at Last Follow-Up: &&&ldl_subj_&i.";
			endcell;

			cell;
			entry "List of Subjects with LDL Out of Target at Last Follow-Up: &&&sbp_subj_&i.";
			endcell;

			endlayout;

		endgraph;
end;
								
run;


proc sgrender data=mergetest template=primarygraph;
where zsiteid=1753 or zsiteid=9999;
format group1 $groupfmt. group2 $groupfmt.  zsiteid sitefmt.;
run;

proc sgrender data=mergetest2 template=secondarygraph;
where zsiteid=1753 or zsiteid=9999;
format group1 group2 group3 group4 group5 $groupfmt.  zsiteid sitefmt.;
run;


*/
