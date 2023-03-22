filename res temp;

proc http
	url = 'https://query1.finance.yahoo.com/v7/finance/quote?symbols=AMZN'
	out = res;
run;

libname res json;