* Inspired by this blog post: https://www.zeta-alpha.com/post/must-read-the-100-most-cited-ai-papers-in-2022;
* Download the data as a tsv file to work;
filename data "%sysfunc(getoption(WORK))/top-cited-2022-papers.tsv";

* Get the data from GitHub;
proc http
	url="https://gist.githubusercontent.com/sergicastellasape/7eb3f0fe219548010f0fbc42a9c5afa6/raw/d0a049d01ff4f4f2cfec78641a7cc8745acdf86c/top-cited-2022-papers.tsv"
	out=data;
run;

* Check HTTP response code and notify the user accordingly;
data _null_;
	if &SYS_PROCHTTP_STATUS_CODE. ne 200 then do;
    	putlog 'ERROR: The data could not be downloaded';
  	end;
  	else putlog 'INFO: The data was successfully downloaded';
run;

* Load the data into CAS for visualization;
cas mysess;
libname casuser cas caslib='casuser';

proc casutil;
	droptable incaslib='casuser' casdata='top_cited_2022' quiet;
run;

data casuser.top_cited_2022(promote=yes);
	infile data delimiter='09'x TRUNCOVER DSD lrecl=32767 firstobs=2;
	informat Title $512.;
 	informat Tweets 8.;
 	informat Citations 8.;
 	informat Organizations $512.;
 	informat Countries $32.;
 	informat Org_Types $512.;
	format Title $512.;
 	format Tweets 8.;
 	format Citations 8.;
 	format Organizations $512.;
 	format Countries $32.;
 	format Org_Types $512.;
;
  input Title -- Org_Types ;
run;

* Clean up;
%let rc = %sysfunc(fdelete(data));
%symdel rc;
filename data clear;

cas mysess terminate;