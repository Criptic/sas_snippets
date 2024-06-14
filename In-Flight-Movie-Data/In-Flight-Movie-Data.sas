/*************************************************
    In flight movie data

    This program retrieves data from the
    Lufthansa API and prepares it to be
    used in SAS Visual Analytics report

    In order to enable everything you will
    also need to register for an OMDB API-key
    (Open Movie Data Base):
    https://www.omdbapi.com/apikey.aspx

    You can find a post about this here:
*************************************************/

* Set you OMDB API key here;
%let omdbAPIKey = REPLACEME;

filename lfthns temp;

* Retrieve data from the API;
proc http
    method = 'Get'
    url = 'https://www.lufthansa-inflightentertainment.com/api/proxy/request?api=/film/&resource=buckets/46/films&lang=en&type=Movies&page=1&pageSize=500&orderBy=titleasc'
    out = lfthns;
quit;

libname lfthns json;

* Join the data;
proc sql;
    create table work.in_flight_movies as
        select a.id,
            a.title,
            a.year,
            a.runtime,
            a.rating,
            b.url as image_url,
            c.url as video_url
        from lfthns.data as a
            left join (select * from lfthns.data_images where type EQ 'Poster') as b
                on a.ordinal_data EQ b.ordinal_data
            left join (select * from lfthns.data_videos where type EQ 'Trailer') as c
                on a.ordinal_data EQ c.ordinal_data;
run; quit;

* Plot can also be set to short;
%macro enrich_movie_data(id, title, year, plot=full);
    %local id
        title
        year
        plot;

    filename _omdbOut temp;

    * Call the OMDB API;
    proc http
        method = 'Get'
        url = "http://www.omdbapi.com/?t=&title.%nrstr(&y)=&year.%nrstr(&plot)=&plot.%nrstr(&apikey)=&omdbAPIKey."
        out = _omdbOut;
    quit;

    libname _omdbOut json;

    * Parse the result into the target table structure;
    data work._tmp_omdbResult;
        length id 8.
            title $128.
            releaseYear 8.
            rated $32.
            releaseDate 8.
            runtime 8.
            genre1 genre2 genre3 $32.
            director1 director2 director3 $128.
            writer1 writer2 writer3 $128.
            actor1 actor2 actor3 $128.
            plot $32000.
            language $32.
            country $64.
            awards $256.
            post $256.
            metaScore 8.
            imdbRating 8.
            imdbVotes 8.
            imdbID $32.
            type $32.
            boxOffice 8.;

        format releaseDate date9.
            boxOffice dollar12.;

        set _omdbOut.AllData(where=(V=1)) end=EoF;
        
        if _n_ = 1 then id = &id.;

        if Value eq 'N/A' then Value = '';

        if P1 eq 'Title' then title = Value;
        else if P1 eq 'Year' then releaseYear = input(Value, 8.);
        else if P1 eq 'Rated' then rated = Value;
        else if P1 eq 'Released' then releaseDate = input(compress(Value), date9.);
        else if P1 eq 'Runtime' then runtime = input(substr(Value, 1, prxmatch('/ min/', Value)), 8.);
        else if P1 eq 'Genre' then do;
            counter = count(Value, ',') + 1;
            if counter > 1 then do;
                i = 1;
                do while(i <= counter);
                    if i = 1 then genre1 = scan(Value, 1, ',');
                    else if i = 2 then genre2 = scan(Value, 2, ',');
                    else if i = 3 then genre3 = scan(Value, 3, ',');
                    i = i + 1;
                end;
            end;
            else genre1 = Value;
        end;
        else if P1 eq 'Director' or P1 eq 'Directors' then do;
            counter = count(Value, ',') + 1;
            if counter > 1 then do;
                i = 1;
                do while(i <= counter);
                    if i = 1 then director1 = scan(Value, 1, ',');
                    else if i = 2 then director2 = scan(Value, 2, ',');
                    else if i = 3 then director3 = scan(Value, 3, ',');
                    i = i + 1;
                end;
            end;
            else director1 = Value;
        end;
        else if P1 eq 'Writer' or P1 eq 'Writers' then do;
            counter = count(Value, ',') + 1;
            if counter > 1 then do;
                i = 1;
                do while(i <= counter);
                    if i = 1 then writer1 = scan(Value, 1, ',');
                    else if i = 2 then writer2 = scan(Value, 2, ',');
                    else if i = 3 then writer3 = scan(Value, 3, ',');
                    i = i + 1;
                end;
            end;
            else writer1 = Value;
        end;
        else if P1 eq 'Actor' or P1 eq 'Actors' then do;
            counter = count(Value, ',') + 1;
            if counter > 1 then do;
                i = 1;
                do while(i <= counter);
                    if i = 1 then actor1 = scan(Value, 1, ',');
                    else if i = 2 then actor2 = scan(Value, 2, ',');
                    else if i = 3 then actor3 = scan(Value, 3, ',');
                    i = i + 1;
                end;
            end;
            else actor1 = Value;
        end;
        else if P1 eq 'Plot' then plot = Value;
        else if P1 eq 'Language' then language = Value;
        else if P1 eq 'Country' then country = Value;
        else if P1 eq 'Awards' then awards = Value;
        else if P1 eq 'Poster' then post = Value;
        else if P1 eq 'Metascore' then metaScore = input(Value, 8.);
        else if P1 eq 'imdbRating' then imdbRating = input(Value, 8.);
        else if P1 eq 'imdbVotes' then imdbVotes = input(Value, comma10.);
        else if P1 eq 'imdbID' then imdbID = Value;
        else if P1 eq 'Type' then type = Value;
        else if P1 eq 'BoxOffice' then boxOffice = input(Value, comma12.);

        if EoF then output;

        retain id title releaseYear rated releaseDate runtime genre1 genre2 genre3 director1 director2 director3 writer1 writer2 writer3 actor1 actor2 actor3 plot language country awards post metaScore imdbRating imdbVotes imdbID type boxOffice;
		keep id title releaseYear rated releaseDate runtime genre1 genre2 genre3 director1 director2 director3 writer1 writer2 writer3 actor1 actor2 actor3 plot language country awards post metaScore imdbRating imdbVotes imdbID type boxOffice;
    run;

    proc append base=work._omdbResult data=work._tmp_omdbResult;
    quit;
%mend enrich_movie_data;

* Initialize the target table structure;
data work._omdbResult;
    length id 8.
        title $128.
        releaseYear 8.
        rated $32.
        releaseDate 8.
        runtime 8.
        genre1 genre2 genre3 $32.
        director1 director2 director3 $128.
        writer1 writer2 writer3 $128.
        actor1 actor2 actor3 $128.
        plot $32000.
        language $32.
        country $64.
        awards $256.
        post $256.
        metaScore 8.
        imdbRating 8.
        imdbVotes 8.
        imdbID $32.
        type $32.
        boxOffice 8.;

    format releaseDate date9.
        boxOffice dollar12.;
run;

data _null_;
    set work.in_flight_movies(firstobs=2);
        
    * Remove brackets from titles which contain the movie title translated into English;
    if prxmatch('/ \(/', title) then title = substr(title, 1, prxmatch('/ \(/', title));
	* Clean up characters to reduce complexity;	
	title = compress(title, ",'");
	title = tranwrd(title, '&', 'and');
	* Call the macro;
    call execute('%nrstr(%enrich_movie_data('||strip(id)||','||strip(%nrquote(title))||','||strip(year)||'));');
run;

* Drop the first row as that was used to initialized the table;
data work._omdbResult;
    set work._omdbResult(firstobs=2);
run;

* Join the results together;
proc sql;
    create table work.in_flight_movies_extended as
        select a.*,
            b.releaseDate,
            b.genre1,
            b.genre2,
            b.genre3,
            b.director1,
            b.director2,
            b.director3,
            b.writer1,
            b.writer2,
            b.writer3,
            b.actor1,
            b.actor2,
            b.actor3,
            b.plot,
            b.metaScore,
            b.imdbRating,
            b.imdbVotes,
            b.boxOffice
            from work.in_flight_movies as a
                left join work._omdbResult as b
                    on a.id EQ b.id;
run; quit;

* Clean up;
libname lfthns clear;
filename lfthns clear;

* Load the data into CAS;
cas mysess;
libname casuser cas caslib='casuser';

proc casUtil;
    dropTable inCASLib='casuser' casData='in_flight_movies' quiet;
    load data=work.in_flight_movies_extended outCASLib='casuser' casOut='in_flight_movies';
    promote inCASLib='casuser' casData='in_flight_movies';
    save inCASLib='casuser' casData='in_flight_movies' outCASLib='casuser' casOut='in_flight_movies.sashdat' replace;
run; quit;

cas mysess terminate;

* Clean up;
proc datasets library=work nolist;
    delete _omdbResult _tmp_omdbResult in_flight_movies in_flight_movies_extended;
run;