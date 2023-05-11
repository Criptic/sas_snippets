* Get the Viya Host URL;
%let viyaHost=%sysfunc(getoption(SERVICESBASEURL)); 

filename files temp;

* Make a REST call to the files endpoint;
proc http url="&viyaHost./files/files"
	method='get'
	out=files
	oauth_bearer = sas_services;
	headers 'Accept'='application/json';
run;

libname files json;

* Display results;
proc print data=files.items noobs;
run;

* Clean up;
libname files clear;
filename files clear;