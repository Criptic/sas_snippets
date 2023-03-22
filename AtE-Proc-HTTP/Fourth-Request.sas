filename res temp;

proc http url='https://api.coindesk.com/v1/bpi/currentprice.json'
	out=res;
run;

libname res json;

data work.prices;
	set res.bpi_gbp(keep=code description rate_float);
	output;
	set res.bpi_eur(keep=code description rate_float);
	output;
	set res.bpi_usd(keep=code description rate_float);
	output;
run;

libname res clear;
filename res clear;