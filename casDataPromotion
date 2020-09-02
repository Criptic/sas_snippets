/*
Shortcut: cdp;
Description: Starts up a cas session, loads your data into cas, promotes the data and terminates the cas session
*/

cas dataPromotion;
caslib _all_ assign;

* Load your data into casuser and promote it;
proc casutil;
	load data=<lib.table> outcaslib="<caslib>"
	casout="<table>" promote;
run; quit;


cas dataPromotion terminate;
