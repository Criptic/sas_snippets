filename resp temp;
proc http url = 'httpbin.org/post'
	in = 'Hello World'
	out = resp;
run;

libname resp json;

proc print data = resp.alldata noobs;
run;

* Clean up;
libname resp clear;
filename resp clear;