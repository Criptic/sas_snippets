* Featured in https://youtu.be/CXXZPR_GetA;

* Data found here https://huggingface.co/datasets/SocialGrep/one-year-of-tsla-on-reddit;
* Download the data;
filename tsla temp;

proc http
	url = 'https://datasets-server.huggingface.co/first-rows?dataset=SocialGrep%2Fone-year-of-tsla-on-reddit&config=comments&split=train'
	out = tsla;
run;

libname tsla json;

* Start CAS session;
cas mysess;
caslib _all_ assign;

* Clean up with ran previously;
proc casutil;
	droptable incaslib='casuser' casdata='tsla_train' quiet;
run;

* Load data into CAS and create a label;
data casuser.tsla_train(promote=yes);
	length sentClass $12.;
	set tsla.rows_row;

	if sentiment < 0 then sentClass = 'Paper Hands';
	else if sentiment > 0 then sentClass = 'Diamond Hands';
	else sentClass = 'Lurker';
run;

* Clean up;
libname tsla clear;
filename tsla clear;

* Train and Score the Classifier;
proc cas;
	textClassifier.trainTextClassifier /
		table = {caslib = 'casuser', name = 'tsla_train'}
		modelOut = {caslib = 'casuser', name = 'textClassifierModel', replace = true}
		seed = 4711
		maxEpochs = 1
		chunkSize = 4
		gpu = false
		target = 'sentClass'
		text = 'body';
   run;

	textClassifier.scoreTextClassifier /
		casOut = {caslib = 'casuser' name = 'tsla_scored', replace = true}
		docId = 'id'
		includeAllScores = true
		model = {caslib = 'casuser', name = 'textClassifierModel'}
		table = {caslib = 'casuser', name = 'tsla_train'}
		text = 'body';
	run;
quit;