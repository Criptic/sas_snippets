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

* How long to iterate for?;
data _null_;
	set res.alldata(where=(p2='totalrecords'));
	call symputx ('stopCounter', value);
run;

%put &=stopCounter;

%macro api_pagination();
	%* Base request to build the baseline;
	filename res temp;
	proc http
		url = 'https://api.nasdaq.com/api/screener/stocks?tableonly=false&limit=25&offset=25'
		out = res;
	run;
	
	libname res json;
	
	data _null_;
		set res.alldata(where=(p2='totalrecords'));
		call symputx ('stopCounter', value);
	run;

	%* Base dataset with the first 25 rows;
	data work.results;
		set res.table_rows;
	run;

	libname res clear;
	filename res clear;

	
	%do i = 2 %to %sysfunc(ceil(&stopCounter. / 25));
		%let offset = %eval(&i. * 25);

		filename resIt temp;
		proc http
			url = 'https://api.nasdaq.com/api/screener/stocks'
			out = resIt
			query = (
				"tableonly" = "false"
				"limit" = "25"
				"offset" = "&offset."
			);
		run;

		libname resIt json;

		proc append base=work.results data=resIt.table_rows force;
		run;

		libname resIt clear;
		filename resIt clear;
	%end;
%mend api_pagination;

%api_pagination();