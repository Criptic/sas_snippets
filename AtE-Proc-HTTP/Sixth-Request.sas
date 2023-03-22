filename res temp;
proc http
	url = 'https://api.nasdaq.com/api/screener/stocks?tableonly=false&limit=25&offset=0'
	out = res;
run;

libname res json;

libname res clear;
filename res clear;

* Getting the next twenty five?!;
%let startFrom = 25;

filename res temp;
proc http
	url = "https://api.nasdaq.com/api/screener/stocks?tableonly=false&limit=25&offset=&startFrom."
	out = res;
run;

libname res json;

* %nrstr to the resuce? or maybe the query statement?;
filename res temp;
proc http
	url = 'https://api.nasdaq.com/api/screener/stocks'
	out = res
					query = (
					"tableonly" = "false"
					"limit" = "25"
					"offset" = "0"
				);
run;

libname res json;