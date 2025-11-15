/*******************************************************************************************************
    This snippet showcases how you can append data to a global scope CAS table.

    This example is based on this example from the SAS documentaiton:
    https://go.documentation.sas.com/doc/en/pgmsascdc/default/casref/n1lmowayn4qghtn18lj7kupsdzi7.htm
*******************************************************************************************************/

cas mySess;

* Load the data and promote our target table (cars);
* The cars table will have 38 rows;
proc casUtil inCASLib='casuser' outCASLib='casuser';
    dropTable casData='cars' quiet;
    load data=sashelp.cars(where=(make in ('Ford', 'Chrysler'))) casOut='cars' replace;
    promote casData='cars';
    list tables;
quit;

* Now we pretend some time has past and we add more data;
* Now the cars table should have 47 rows;
proc casutil inCASLib='casuser' outCASLib='casuser';
    dropTable casData='buick_cars' quiet;
    load data=sashelp.cars(where=(make='Buick')) casOut='buick_cars' replace;
    * Now comes the appending;
    append srcCASLib='casuser' source='buick_cars' dataSourceOptions={dataTransferMode='serial'}
        target='cars' tgtCASLib='casuser';
    list tables;
quit;

* Now let's terminate the cas session, establish a new one and check that our table was actually appened in global scope;
cas mySess terminate;
cas mySess;

* The cars table should still have 47 rows;
proc casUtil inCASLib='casuser' outCASLib='casuser';
    list tables;
quit;

cas mySess terminate;