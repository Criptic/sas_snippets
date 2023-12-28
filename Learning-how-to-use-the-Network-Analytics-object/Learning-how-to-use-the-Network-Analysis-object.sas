cas mysess;

* Quietly dropping the table so you can always rerun this code;
proc casutil;
	droptable incaslib='casuser' casdata='Employees' quiet;
quit;

* This example data can be found in the SAS Documentation;
data casuser.Employees(promote=yes);
	length Link $512.;
   input Employee $ Manager $ Team $ Salary EmployeeID ManagerID Country $ State $ State2 $ Link $;
   datalines;
EMP1 MGR1 A 40000 2 1 US NC NY https://go.documentation.sas.com/doc/en/vacdc/default/vaobj/n0kcvb9vm0kd1sn1b199uu8hgq1w.htm?requestorId=b499afb9-a7cb-4a66-b985-92b1fab6f3ee#n0r57nk56ysfnln1xd64od5b5s8i
EMP2 MGR1 A 55000 3 1 US NY TX https://go.documentation.sas.com/doc/en/vacdc/default/vaobj/n0kcvb9vm0kd1sn1b199uu8hgq1w.htm?requestorId=b499afb9-a7cb-4a66-b985-92b1fab6f3ee#n0zuutt5v6onehn1uuszwsvrpyl9
EMP3 MGR1 B 50000 4 1 US TX NC https://go.documentation.sas.com/doc/en/vacdc/default/vaobj/n0kcvb9vm0kd1sn1b199uu8hgq1w.htm?requestorId=b499afb9-a7cb-4a66-b985-92b1fab6f3ee#p0izq756yfu1syn177wdhj69ithm
MGR1 . . 75000 1 . US NC TX https://go.documentation.sas.com/doc/en/vacdc/default/vaobj/n0kcvb9vm0kd1sn1b199uu8hgq1w.htm?requestorId=b499afb9-a7cb-4a66-b985-92b1fab6f3ee#p09pqxhkq5urgin1vdqg93trlcgga
;
run;

