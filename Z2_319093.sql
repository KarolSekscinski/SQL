/*
Imie Nazwisko: Karol Sekściński
Numer Albumu: 319093
*/


/* proszę stworzyć skrypt w którym
1. Korzystając ze skryptu z Z1 proszę utworzyć minimum 5 baz
2. W 3ech z nich proszę utworzyć tabele i dane z wykładu z BAZ (WOJ,MIASTA,OSOBY,ETATY)
i wypełnić wartościami, jak nie mają Państwo swojego skryptu to w chmurze jest mój w
katalogu zaczynającym się od Z2...  stud_zal_baza.sql
3. Proszę w jednej z baz dodać kilka rekordów więcej do ETATY i OSOBY (według uznania)
4. Zadaniem jest śledzenie liczby rekordów w tabelach w bazach
4.1 Proszę utworzyć tabele:*/
/*Tabele utworzone 

CREATE TABLE APBD23_ADM.dbo.DB_CHECK
( check_id int not null IDENTITY CONSTRAINT PK_DB_CHECK PRIMARY KEY
, db_nam nvarchar(50) not null -- w jakiej bazie
, d_stamp datetime NOT NULL DEFAULT GETDATE() -- o której godzinie
, opis nvarchar(50) NOT NULL
)
CREATE TABLE APBD23_ADM.dbo.DB_CHECK_ITEMS
( check_id int not null CONSTRAINT FK_DB_CHECK__DB_CHECK_ITEMS FOREIGN KEY
	REFERENCES APBD23_ADM.dbo.DB_CHECK (check_id)
, tb_nam nvarchar(50) not null -- nazwa tabeli w bazie
, tb_check_d_stamp datetime NOT NULL DEFAULT GETDATE() -- o której godzinie dodano rekord
, LICZBA_REKORDOW int NOT NULL
)
*/
/*
4.2 Trzeba utworzyć procedurę, która ma kursor po wszystkich bazach
Trzeba utworzyć procedurę, która dla podanej bazy wylistuje wszystkie tabele
wstawi rekord do tabeli APBD23_ADM.dbo.DB_CHECK i z tak uzyskanym identyfikatorem
wstawi dla kazdej tabeli aktualną liczbę rekordów do tabeli
APBD23_ADM.dbo.DB_CHECK_ITEMS
*/


CREATE PROCEDURE proc42 (@db nvarchar(50))
AS
BEGIN
	DECLARE @sql nvarchar(2000), @d nvarchar(50), @i int
	INSERT INTO APBD23_ADM.dbo.DB_CHECK(db_nam, opis) VALUES (@db, N'Procedura XX - ' + @db)
	SET @i = SCOPE_IDENTITY()

	CREATE TABLE #t (t_name nvarchar(50) NOT NULL)

	SET @d = @db -- nazwa bazy ma byc parametrem procedury
	SET @sql = N'USE ' + @d
		+ N';INSERT INTO #t (t_name) '
		+ N' SELECT o.[name] FROM sysobjects o WHERE OBJECTPROPERTY(o.[ID],N''IsUserTable'')=1'
	EXEC sp_SqlExec @sql
	
	DECLARE @t NVARCHAR(50)
	DECLARE @record_count int
	DECLARE CI INSENSITIVE CURSOR FOR
		SELECT * FROM #t
	OPEN CI
	FETCH NEXT FROM CI INTO @t
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = N'SELECT @record_count = COUNT(*) FROM ' + @d + '.dbo.' + @t
		EXEC sp_executesql @sql, N'@record_count int OUTPUT', @record_count OUTPUT
		INSERT INTO APBD23_ADM.dbo.DB_CHECK_ITEMS(check_id, tb_nam, LICZBA_REKORDOW) VALUES (@i, @t, @record_count)
		FETCH NEXT FROM CI INTO @t
	END
	
	CLOSE CI
	DEALLOCATE CI
END
GO
EXEC proc42 @db = 'cc'

GO
/* 
check_id    db_nam                                             d_stamp                 opis
----------- -------------------------------------------------- ----------------------- --------------------------------------------------
1           cc                                                 2023-11-04 23:57:51.243 Procedura XX - cc

(1 row affected)
check_id    tb_nam                                             tb_check_d_stamp        LICZBA_REKORDOW
----------- -------------------------------------------------- ----------------------- ---------------
1           woj                                                2023-11-04 23:57:51.307 3
1           miasta                                             2023-11-04 23:57:51.310 6
1           osoby                                              2023-11-04 23:57:51.310 10
1           firmy                                              2023-11-04 23:57:51.310 3
1           etaty                                              2023-11-04 23:57:51.310 15

(5 rows affected)
*/
/*
teraz trzeba zrobić kursor po #t i dla kazdej z tabel policzyc liczbę rekordów
i tę liczbę zapisać w tabeli APBD23_ADM.dbo.DB_CHECK_ITEMS

4.3 Napisać procedurę, która dla wszystkich baz wywoła procedurę z punktu 4.2
*/


CREATE PROCEDURE proc43
AS
BEGIN
	DECLARE @d NVARCHAR(50)
	DECLARE CI1 INSENSITIVE CURSOR FOR
		SELECT d.[name] FROM sysdatabases d
	OPEN CI1 
	FETCH NEXT FROM CI1 INTO @d
	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE')
		BEGIN
			SELECT @d AS db_name
			EXEC proc42 @db = @d
		END
		FETCH NEXT FROM CI1 INTO @d
	END
	CLOSE CI1
	DEALLOCATE CI1
END
EXEC proc43
SELECT * FROM APBD23_ADM.dbo.DB_CHECK_ITEMS
/*
check_id    db_nam                                             d_stamp                 opis
----------- -------------------------------------------------- ----------------------- --------------------------------------------------
1           cc                                                 2023-11-04 23:57:51.243 Procedura XX - cc
2           master                                             2023-11-04 23:59:00.287 Procedura XX - master
3           tempdb                                             2023-11-04 23:59:00.300 Procedura XX - tempdb
4           model                                              2023-11-04 23:59:00.303 Procedura XX - model
5           msdb                                               2023-11-04 23:59:00.317 Procedura XX - msdb
6           APBD23_ADM                                         2023-11-04 23:59:00.333 Procedura XX - APBD23_ADM
7           aa                                                 2023-11-04 23:59:00.367 Procedura XX - aa
8           bb                                                 2023-11-04 23:59:00.463 Procedura XX - bb
9           cc                                                 2023-11-04 23:59:00.617 Procedura XX - cc
10          dd                                                 2023-11-04 23:59:00.770 Procedura XX - dd
11          ee                                                 2023-11-04 23:59:00.863 Procedura XX - ee

(11 rows affected)
check_id    tb_nam                                             tb_check_d_stamp        LICZBA_REKORDOW
----------- -------------------------------------------------- ----------------------- ---------------
1           woj                                                2023-11-04 23:57:51.307 3
1           miasta                                             2023-11-04 23:57:51.310 6
1           osoby                                              2023-11-04 23:57:51.310 10 --baza cc z wieksza iloscia osob i etatow
1           firmy                                              2023-11-04 23:57:51.310 3
1           etaty                                              2023-11-04 23:57:51.310 15 --baza cc z wieksza iloscia osob i etatow
2           spt_fallback_db                                    2023-11-04 23:59:00.300 0
2           spt_fallback_dev                                   2023-11-04 23:59:00.300 0
2           spt_fallback_usg                                   2023-11-04 23:59:00.300 0
2           spt_monitor                                        2023-11-04 23:59:00.300 1
2           MSreplication_options                              2023-11-04 23:59:00.300 3
6           CRDB_LOG                                           2023-11-04 23:59:00.360 5
6           CRUSR_LOG                                          2023-11-04 23:59:00.363 5
6           DB_CHECK                                           2023-11-04 23:59:00.363 6
6           DB_CHECK_ITEMS                                     2023-11-04 23:59:00.363 13
7           woj                                                2023-11-04 23:59:00.460 3
7           miasta                                             2023-11-04 23:59:00.460 6
7           osoby                                              2023-11-04 23:59:00.460 7
7           firmy                                              2023-11-04 23:59:00.460 3
7           etaty                                              2023-11-04 23:59:00.460 12
8           woj                                                2023-11-04 23:59:00.567 3
8           miasta                                             2023-11-04 23:59:00.567 6
8           osoby                                              2023-11-04 23:59:00.613 7
8           firmy                                              2023-11-04 23:59:00.617 3
8           etaty                                              2023-11-04 23:59:00.617 12
9           woj                                                2023-11-04 23:59:00.723 3
9           miasta                                             2023-11-04 23:59:00.723 6
9           osoby                                              2023-11-04 23:59:00.723 10 --baza cc z wieksza iloscia osob i etatow
9           firmy                                              2023-11-04 23:59:00.723 3
9           etaty                                              2023-11-04 23:59:00.770 15 --baza cc z wieksza iloscia osob i etatow

(29 rows affected)
*/
/*
4.4 Napisać procedurę, która dla parametru nazwa bazy, 
nazwa tabeli wypisze historię 
liczby rekordów dla podanej tabeli w podanej bazie
 
*/

GO
CREATE PROCEDURE proc44 (@db nvarchar(50), @t nvarchar(50))
AS
BEGIN
    DECLARE @SQL NVARCHAR(MAX)
    SET @SQL = 'USE ' + QUOTENAME(@db) + ';
                SELECT
                    dci.tb_check_d_stamp AS RecordCountDate,
                    dci.LICZBA_REKORDOW AS RecordCount,
					dc.db_nam AS DatabaseName
                FROM APBD23_ADM.dbo.DB_CHECK dc
                JOIN APBD23_ADM.dbo.DB_CHECK_ITEMS dci ON dc.check_id = dci.check_id
                WHERE dci.tb_nam = @t AND dc.db_nam = @db
                ORDER BY dci.tb_check_d_stamp;'

    EXEC sp_executesql @SQL, N'@t NVARCHAR(128), @db NVARCHAR(128)', @t, @db
END

EXEC proc44 @db = 'aa', @t = 'etaty'
/*
RecordCountDate         RecordCount DatabaseName
----------------------- ----------- --------------------------------------------------
2023-11-04 23:57:51.310 15          cc
2023-11-04 23:59:00.770 15          cc

(2 rows affected)
RecordCountDate         RecordCount DatabaseName
----------------------- ----------- --------------------------------------------------
2023-11-04 23:59:00.460 12          aa

(1 row affected)
*/
