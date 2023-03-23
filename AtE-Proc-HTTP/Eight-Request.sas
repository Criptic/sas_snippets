%let DeepLToken = <YOUR-DEEPL-API-TOKEN>;

filename deepL temp;

proc http
	url = "https://api-free.deepl.com/v2/translate"
	ct = 'application/x-www-form-urlencoded'
	in = form("target_lang" = "DE"
			"source_lang" = "EN"
			"text" = "Hello World")
    out = deepL;
    headers
        'Accept' = 'application/json'
		'Authorization' = "DeepL-Auth-Key &DeepLToken.";
run;

libname deepL json;