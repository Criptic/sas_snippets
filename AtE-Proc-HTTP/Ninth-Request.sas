* https://docs.google.com/spreadsheets/d/19SnoqFxcgVnqk2cfMFOIcu_Y7F7EduckGuSW6rH2nCw/edit#gid=0;

* Download the Google Sheet as a csv file to work;
filename sheet "%sysfunc(getoption(WORK))/sheet.csv";
proc http
	url="https://docs.google.com/feeds/download/spreadsheets/Export"
	out=sheet
	query = (
		"key" = "19SnoqFxcgVnqk2cfMFOIcu_Y7F7EduckGuSW6rH2nCw"
		"exportFormat" = "csv"
		"gid" = "0"
	);
run;

* Check HTTP response code and notify the user accordingly;
data _null_;
	if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
    	putlog 'ERROR: Google Sheet could not be downloaded';
  	end;
  	else putlog 'INFO: Google Sheet was successfully downloaded';
run;

* Import the csv file;
proc import
 	file=sheet
	out=work.sheet
	dbms=csv
	replace;
	guessingrows=10;
run;

* Clean up;
%let rc = %sysfunc(fdelete(sheet));
%symdel rc;
filename sheet clear;