/***
    Created by David Weik
    Please check out the accompanying blog post https://www.davidweik.org/blog/from-curl-to-proc-http
*/

* cURLString contains the full curl command;
%let cURLString = curl --request GET --url http://example.com/files/files --header 'Accept: application/json, application/vnd.sas.collection+json, application/vnd.sas.error+json' --header 'Accept-Item: ' --header 'Authorization: Bearer <access-token-goes-here>';
%let cURLString = %sysfunc(translate(%superq(cURLString),%str(%'),%str(%")));

* Add SAS authentication;
* Set to 1 if you want to make a call to Viya from the same Viya Host;
%let sasAuthentication = 0;

* Output Options;
* 0 = ignore, 1 = print to log, 2 = save to table, 3 = create json lib;
%let outputOption = 3;
* Name of the output table - only applies if outputOption = 2;
%let tableName = work.http_response;

* Split up the cURL command into its parts;
data work._curlString;
    length curlComponent $32000. tag $32. contentType $10. skipFlip 8. proxyURL 8. headerFlip 8. dataFlip 8.;
    label curlComponent = 'Stores the value from the original curl command'
        tag = 'Stores what type of information is stored in the curlComponent'
        contentType = 'Specifies if something is a procedure options or statement'
        skipFlip = 'If 1 remove from output'
        proxyURL = 'If 1 then the next URL is a proxy URL'
        headerFlip = 'If 1 then collect header'
        dataFlip = 'If 1 then collect data';

    * Setup special case handling defaults;
    skipFlip = 0;
    proxyURL = 0;
    headerFlip = 0;
    dataFlip = 0;

    * Count the arguments of the cURL command;
    arguments = countw("%superq(cURLString)", ' ');
    do i = 1 to arguments;
        * Reset Tag value;
        tag = '';

        * Content Type - default is option as most cURL options are procedural options;
        contentType = 'option';

        curlComponent = compress(scan("%superq(cURLString)", i, ' '));

        * Tag assignment;
        if curlComponent in ('-G', '--get', 'GET', 'POST', 'HEAD', 'PUT', 'DELETE') then do;
            tag = 'method';
            headerFlip = 0;
            dataFlip = 0;
        end;
        else if curlComponent in ('-F', '--form', '--data-raw', '--data-urlencode', '--data-binary', '-T', '--upload-file', '-d', '--data') then do;
            dataFlip = 1;
            headerFlip = 0;
        end;
        else if prxmatch('/https{0,1}:\/\//', curlComponent) ne 0 then do;
            tag = 'url';
            dataFlip = 0;
            headerFlip = 0;
        end;
        else if curlComponent in ('-H', '--header') then do;
            headerFlip = 1;
            dataFlip = 0;
        end;
        else if prxmatch('/^--{0,1}/', curlComponent) ne 0 then do;
            tag = 'options';
            dataFlip = 0;
            headerFlip = 0;
        end;
        else tag = 'value';

        * Proxy URL Check;
        if proxyURL = 1 and tag = 'url' then do;
            tag = 'proxy';
            proxyURL = 0;
        end;

        * Check for header;
        if headerFlip = 1 and tag ne '' then tag = 'header';

        * Check for data;
        if dataFlip = 1 and tag ne '' then tag = 'data';

        * Data Warning to remind user of changing to filename;
        if curlComponent in ('--data-binary', '-T', '--upload-file', '-d', '--data') then do;
            put 'WARNING: You are sending data that might use a file as an input.';
            put 'WARNING: In SAS you need to change this to a filename and use the file reference in the in option.';
        end;

        * Content Type Check;
        if curlComponent in ('-v', '--verbose', '--trace') or tag = 'header' then contentType = 'statement';

        * Set skip flip;
        if curlComponent in ('--trace') then skipFlip = 1;

        * Remove meaningless content;
        if curlComponent = 'curl' then;
        else if curlComponent = '\' then;
        else if curlComponent in ('-X', '--request') then;
        else if curlComponent in ('-x', '--proxy') then proxyURL = 1;
        else if skipFlip = 1 and curlComponent not in ('--trace') then skipFlip = 0;
        else if headerFlip = 1 and tag eq '' then;
        else if dataFlip = 1 and tag eq '' then;
        else output;
    end;

    drop arguments skipFlip proxyURL headerFlip dataFlip i;
run;

* Start of the Proc HTTP & filename;
data work._procHTTPCodeStart;
    length outputCode $32000.;
    if &sasAuthentication. EQ 1 then do;
        outputCode = '* Get the Viya Host URL;';
        output;
        outputCode = '%let viyaHost=%sysfunc(getoption(SERVICESBASEURL));';
    end;
    outputCode = '* Create a temporary file;';
    output;
    outputCode = 'filename outResp temp;';
    output;
    outputCode = '';
    output;
    outputCode = '* Actual Proc HTTP Request;';
    output;
    outputCode = 'proc http';
    output;
run;

* Procedure options for Proc HTTP;
data work._procHTTPOpt(drop=retainFlip tmpData);
    length outputCode $32000. retainFlip 8. tmpData $32000.;
    set work._curlString(where=(contentType='option')) end=eof;
    
    * Remove potential quotes from url strings;
    if tag in ('url', 'proxy') and substr(curlComponent, 1, 1) in ("'", '"') then curlComponent = dequote(trim(curlComponent));

    * Handle data;
    if tag = 'data' and retainFlip in (., 0) then do;
        retainFlip = 1;
        tmpData = trim(curlComponent);
    end;
    else if tag ne 'data' then do;
        retainFlip = 0;
    end;
    else tmpData = catx(' ', trim(tmpData), trim(curlComponent));

    * Handle everything but data;
    if tag = 'url' then do;
        if &sasAuthentication. EQ 1 then do;
            outputCode = 'url="' || trim(tranwrd(curlComponent, 'http://example.com', '&viyaHost.')) || '"';
        end;
        else outputCode = "url='" || trim(curlComponent) || "'"; 
    end;
    else if tag = 'method' then outputCode = "method='" || trim(curlComponent) || "'";
    else if tag = 'proxy' then outputCode = "proxyhost='" || trim(curlComponent) || "'";
    else if tag = 'options' then do;
        warningMessage = catx(' ', 'WARNING: Unkown cURL option', curlComponent, ' found.');
        put warningMessage;
        put 'WARNING: The Proc HTTP might not be fully equivalent to the cURL command.';
    end;

    * Generating output;
    if tag in ('url', 'method', 'proxy') then output;
    else if retainFlip = 0 and tmpData ne '' then do;
        outputCode = 'in="' || trim(substr(trim(tmpData), 2, length(trim(tmpData)) - 2)) || '"';
        output;
    end;
    else if eof and tmpData ne '' then do;
        outputCode = 'in="' || trim(substr(trim(tmpData), 2, length(trim(tmpData)) - 2)) || '"';
        output;
    end;

    drop warningMessage;
    retain retainFlip tmpData;
run;

* End of Procedure options for Proc HTTP;
data work._procHTTPOptEnd;
    length outputCode $32000.;

    * Check for SAS authentication;
    if &sasAuthentication. then do;
        outputCode = 'oauth_bearer = sas_services';
        output;
    end;

    outputCode = 'out=outResp;';
    output;
run;

* Procedure statements for Proc HTTP;
data work._procHTTPStmnt(drop=retainFlip tmpHeader);
    length outputCode $32000. retainFlip 8. tmpHeader $32000.;
    set work._curlString(where=((contentType='statement')));

    * Handle headers;
    if substr(curlComponent, 1, 1) in ("'", '"') then do;
        retainFlip = 1;
        tmpHeader = "headers '" || trim(dequote(tranwrd(curlComponent, ':', ''))) || "' = '";
    end;
    else if prxmatch('/"$/', trim(curlComponent)) ne 0 or prxmatch("/'$/", trim(curlComponent)) ne 0 then do;
        retainFlip = 0;
        outputCode = catx(' ', trim(tmpHeader), left(reverse(dequote(left(reverse(curlComponent)))))) || "';";
    end;
    else if tag = 'header' then do;
        tmpHeader = catx(' ', trim(tmpHeader), trim(curlComponent));
    end;
    else retainFlip = 0;

    * Handle debugging;
    if curlComponent = '-v' then outputCode = 'debug level = 1;';
    else if curlComponent = '--verbose' then outputCode = 'debug level = 2;';
    else if curlComponent = '--trace' then outputCode = 'debug level = 3;';

    if tag = 'header' and retainFlip = 0 then do;
        put tmpHeader;
        if &sasAuthentication. EQ 1 and findw(tmpHeader, 'Bearer') GT 0 then do;
            putLog 'NOTE: Skipping authorization header for oauth_bearer method';
        end;
        else output;
    end;
    else if curlComponent in ('-v', '--verbose', '--trace') then output;

    if retainFlip = 0 then tmpHeader = '';
    retain retainFlip tmpHeader;
run;

* End of the Proc HTTP;
data work._procHTTPCodeEnd;
    length outputCode $32000.;
    outputCode = 'run;';
run;

* Output Generation;
data work._errorOutput;
    length outputCode $32000.;
    output;
    outputCode = '* HTTP Status Handling;';
    output;
    outputCode = 'data _null_;';
    output;
    outputCode = 'if &SYS_PROCHTTP_STATUS_CODE. lt 400 then do;';
    output;
    outputCode = 'put "NOTE: The request was most likely successful.";';
    output;
    outputCode = 'put "NOTE: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE..";';
    output;
    outputCode = 'put "NOTE: That means: &SYS_PROCHTTP_STATUS_PHRASE..";';
    output;
    outputCode = 'end;';
    output;
    outputCode = 'else do;';
    output;
    outputCode = 'put "ERROR: The request was most likely not successful.";';
    output;
    outputCode = 'put "ERROR: The HTTP Status Code is &SYS_PROCHTTP_STATUS_CODE..";';
    output;
    outputCode = 'put "ERROR: That means: &SYS_PROCHTTP_STATUS_PHRASE..";';
    output;
    outputCode = 'end;';
    output;
    outputCode = 'run;';
    output;
run;

* Handle the response;
data work._outputOption;
    length outputCode $32000.;

    if &outputOption. = 0 then output;
    else if &outputOption. = 1 then do;
        output;
        outputCode = '* Print response to Log;';
        output;
        outputCode = 'data _null_;';
        output;
        outputCode = 'infile outResp;';
        output;
        outputCode = 'input;';
        output;
        outputCode = 'put _infile_;';
        output;
        outputCode = 'run;';
        output;
    end;
    else if &outputOption. = 2 then do;
        output;
        outputCode = '* Save response to a Table;';
        output;
        outputCode = 'data &tableName.;';
        output;
        outputCode = 'infile outResp;';
        output;
        outputCode = 'input;';
        output;
        outputCode = 'responseLine = _infile_;';
        output;
        outputCode = 'run;';
        output;
    end;
    else if &outputOption. = 3 then do;
        output;
        outputCode = '* Create a JSON library from response;';
        output;
        outputCode = 'libname outResp json;';
        output;
    end;
run;

* Combine all code snippets;
data work._allCode;
    set work._procHTTPCodeStart work._procHTTPOpt work._procHTTPOptEnd work._procHTTPStmnt work._procHTTPCodeEnd work._errorOutput work._outputOption;

    drop tag curlComponent contentType;
run;

* Print the code;
ods listing close;
ods html5;
title1 'cURL to Proc HTTP conversion';
title2 'Just copy and paste the code below';
title3 'Hit CTRL+SHIFT+B or use the Format code button to make it look nice';
title4 'If you see empty lines in the Proc HTTP code then the parsing might have been unsuccessful';

proc report data=work._allCode noheader;
run;

title;
ods html5 close;

* Remove datasets;
proc datasets library=work nolist;
    delete _curlString _procHTTPCodeStart _procHTTPOpt _procHTTPOptEnd _procHTTPStmnt _procHTTPCodeEnd _errorOutput _allCode _outputOption;
run;