* Establish a CAS session and connect all available CAS Libs;
cas mysess;
caslib _all_ assign;

* Ensuring a clean slate for the tables that will be created;
proc casutil;
	droptable incaslib='public' casdata='news_data_raw' quiet;
	droptable incaslib='public' casdata='news_data_stoplist' quiet;
	droptable incaslib='public' casdata='news_data' quiet;
	droptable incaslib='public' casdata='news_data_unique' quiet;
	droptable incaslib='public' casdata='news_data_punctuation' quiet;
	droptable incaslib='public' casdata='news_data_stopList_LDA' quiet;
	droptable incaslib='public' casdata='news_data_ldaTopicDis' quiet;
	droptable incaslib='public' casdata='news_data_ldaTopTerms' quiet;
	droptable incaslib='public' casdata='news_data_svdTopics' quiet;
quit;

* Import the CSV file and loading the default Stopword List;
* You will need to adjust the path in the load statement;
proc casutil;
	load file='/export/pvs/sasdata/homes/gerdaw/Data/abcnews-date-text.csv'
		outcaslib='public' casout='news_data_raw';
	load casdata="en_stoplist.sashdat" incaslib='referencedata'
		outcaslib='public' casout='news_data_stoplist';
quit;

* Print the definition of the file to the Results;
proc contents data=public.news_data_raw;
quit;

* Print the first ten lines to the Results;
proc print data=public.news_data_raw(obs=10);
quit;

* Add a unique document ID and profile the text;
proc cas;
	textManagement.generateIds result = rsGI /
		table = {caslib = 'public', name = 'news_data_raw'}
		id = 'documentID'
		casOut = {caslib = 'public', name = 'news_data', replace = True};

	print rsGI;

	textManagement.profileText result = rsPT /
		table = {caslib = 'public', name = 'news_data'}
		documentID = 'documentID'
		text = 'headline_text'
		referenceData = True
		casOut = {caslib = 'public', name = 'news_data_ref', replace = True};

	print rsPT;

	table.fetch / table = {caslib = 'public', name = 'news_data_ref'};
run; quit;

* Generating the unique stopword list for LDA;
proc fedsql sessref=mysess;
	create table public.news_data_unique as
		select distinct term
			from public.news_data_stoplist;
quit;

data public.news_data_punctuation;
	length TERM varchar(*);
	if _n_ = 1 then do;
		term = '.';
		output;
	end;
	input term @@;
	output;
	datalines4;
! " # $ % & ' ( ) * + , - / : ; < = > ? @ [ \ ] ^ _ ` { | } ~
;;;;
run;

data public.news_data_stopList_LDA;
	set public.news_data_unique(keep=term) public.news_data_punctuation;
run;

* Feel free to take a look at the profile as it can help you understand better the structure of the text;
* We will move on to the text modeling - and as with the blog post we will start of with;
* We will leave the algorithms on their respective default settings + applying the default stopword list;
* We will have it create 10 topics;
* LDA Topic Modeling;
proc cas;
	ldaTopic.ldaTrain result = resLT /
		table = {caslib = 'public', name = 'news_data'}
		docID = 'documentID'
		text = {'headline_text'}
		k = 10
		stopWords = {caslib = 'public', name = 'news_data_stopList_LDA'}
		casOut = {caslib = 'public', name = 'news_data_ldaTopicDis', replace = True};

	print resLT;
run; quit;

* Sort the data by topicID and term Proability;
proc sort data=public.news_data_ldaTopicDis out=work.news_data_ldaTopicDis_sort;
	by _topicID_ descending _Probability_;
quit;

* Select the top five terms by topic;
data public.news_data_ldaTopTerms(drop = i _termID_ _Term_ _Probability_);
	length topicTerms $256.;
	set work.news_data_ldaTopicDis_sort;
	by _topicID_;

	if first._topicID_ then do;
		i = 0;
		topicTerms = strip(_Term_);
	end;

	if i > 0 and i < 5 then topicTerms = strip(topicTerms) || ', ' || strip(_Term_);
	if i = 4 then output;

	i = i + 1;
	retain i topicTerms;
run;

* SVD Topic Modeling;
* I'm using the tmMine action instead of the tmSvd action as this action includes the parsing;
proc cas;
	textMining.tmMine result = resTM /
		documents = {caslib = 'public', name = 'news_data'}
		docID = 'documentID'
		text = 'headline_text'
		k = 10
		stopList = {caslib = 'public', name = 'news_data_stoplist'}
		topics = {caslib = 'public', name = 'news_data_svdTopics', replace = True};

	print resTM;
run; quit;

title 'Results of the LDA Topic Modeling';
proc print data = public.news_data_ldaTopTerms;
quit;

title 'Results of the SVD Topic Modeling';
proc print data = public.news_data_svdTopics(drop=_TermCutOff_);
quit;