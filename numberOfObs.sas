/*
Shortcut: noo;
Description: Read the number of obs in dataset and write it into a macro variable names nobs
*/

%let dsid=%sysfunc(open(<lib.table>));
%let nobs=%sysfunc(attrn(&dsid,nobs));
%let dsid=%sysfunc(close(&dsid));

%put &=nobs;
