filename resp temp;
proc http url = 'httpbin.org/get'
	out = resp;
run;

libname resp json;

proc print data = resp.alldata noobs;
run;

* Clean up;
libname resp clear;
filename resp clear;