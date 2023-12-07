/* maciej.stodolski@gmail.com  Administrowanie Bazami Danych Z4 28.11.2023 */

/* Z4
Imie Nazwisko: Karol Sekscinski
nr albumu 319093


** Opis historyczny
wiele baz danych wymaga załadowania danych inicjalnych
lub ma opcję dodania danych do tabel (wszystkich lub częsci)
Jak baza ma setki tabel to niemozliwe staje sie ustalenie 
do ktorej tabeli najpierw trzeba dane bo inaczej klucze obce odrzuca

dlatego bardzo czesto jest sytuacja gdzie proszą adminow aby
a) usuneli wszystkie klucze obce z bazy
b) laduja dane
c) proszą o odtworzenie kluczy obcych i jak sa bledy o ic przeslanie
(wtedy sprawdzaja co z czym nie gra)

Przykladowo baza z wykladu
Najpierw mozna cos dograc do WOJ potem MIASTA, potem OSOBY, potem FIRMY a na koncu ETATY
jakakolwiek zmiana kolejnosci moze spowodowac ze np
dodamy miasta ktore sa w WOJ ktorego jeszcze nie dogralismy wiec klucz na to nie pozwoli

**
** Stworzymy narzędzia
** 0) Tabele/procedury mają działać dla wszyskich baz na naszym serwerze
** Narzędzia mają służyć do (wszystko procedurami SQL zapamiętanymi na bazie adm):
** WA) Zapamiętywania stanu bazy
** - liczby rekordów
** - indeksow w tabeli
** - kluczy obcych
** WB) Ma być możliwość skasowania wszystkich kluczy obcych za pomocą procedury
**   W zadanie bazie !!!
**   Taka procedure ma najpierw zapamietac w tabeli jakie są klucze
**   a potem je skasowac TYLKO JAK SIE UDA ZAPAMIETAC NAJPIERW KLUCZE
** WC) Ma być możliwość odtworzenia kluczy obcych procedurą na wybranej bazie
**  podajemy według jakiego stanu (ID stanu) jak NULL to 
**  - procedura szuka ostatniego stanu dla tej bazy i odtwarza ten stan
** Sprawozdanie umieszczmy w iSOD do 10.12.2020 do godziny 20.00 w kolumnie Z4
** Sprawozdanie w PDF lub pliku Z4_num_indeksu_imie_nazw(bez PL znakow).sql:
** Opis wymagan
** Opis sposobu realizacji
** Kod SQL z komentarzami
** Dowód ze dziala (np zapamietany stan liczby wierszy w bazie, skasowane klucze obce,odtworzone według stanu X)
*/

/*
CREATE DATABASE DB_STAT
*/
IF NOT EXISTS (SELECT d.name, d.database_id
					FROM sys.databases d 
					WHERE	(d.database_id > 4) -- systemowe mają ID poniżej 5
					AND		(d.[name] = N'DB_STAT')
)
BEGIN
	CREATE DATABASE DB_STAT
END
GO

USE DB_STAT;
GO

IF NOT EXISTS 
(	SELECT 1
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_STAT')
		AND		(OBJECTPROPERTY(o.[ID],N'IsUserTable')=1)
)
BEGIN
	/* czyszczenie jak trzeba od nowa
		DROP TABLE DB_STAT.dbo.DB_RCOUNT
		DROP TABLE DB_STAT.dbo.DB_FK
		DROP TABLE DB_STAT.dbo.DB_IDX
		DROP TABLE DB_STAT.dbo.DB_STAT
	*/
	/*
	Szukanie ostatniego stat_id dla ostatniego zrzutu kluczy
	SELECT MAX(o.stat_id)
		FROM DB_STAT o
		WHERE o.[db_nam] = 'aa'
		AND EXISTS ( SELECT 1 FROM db_fk f WHERE f.stat_id = o.stat_id)
	*/
	CREATE TABLE dbo.DB_STAT
	(	stat_id		int				NOT NULL IDENTITY /* samonumerująca kolumna */
			CONSTRAINT PK_DB_STAT PRIMARY KEY
	,	[db_nam]	nvarchar(20)	NOT NULL
	,	[comment]	nvarchar(20)	NOT NULL
	,	[when]		datetime		NOT NULL DEFAULT GETDATE()
	,	[usr_nam]	nvarchar(100)	NOT NULL DEFAULT USER_NAME()
	,	[host]		nvarchar(100)	NOT NULL DEFAULT HOST_NAME()
	)
END
GO

use DB_STAT;
GO
IF NOT EXISTS 
(	SELECT 1
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_IDX')
		AND		(OBJECTPROPERTY(o.[ID],N'IsUserTable')=1)
)
BEGIN
	SELECT N'Tabela z informacjami o indeksach w kazdej bazie' AS [msg]
	CREATE TABLE dbo.DB_IDX
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_IDX__RCOUNT FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	name_table	nvarchar(100)	NOT NULL
	,	name_index	NVARCHAR(100)	
	,	type_index	NVARCHAR(100)	NOT NULL 		
	,	[RDT]		datetime		NOT NULL DEFAULT GETDATE()
	)
END
GO

USE DB_STAT
GO

IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_RCOUNT')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)
BEGIN
	SELECT N'Tabela z informacjami ilosci recordow w kazdej tabeli' AS [msg]
	CREATE TABLE dbo.DB_RCOUNT
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_STAT__RCOUNT FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	[table]		nvarchar(100)	NOT NULL
	,	[RCOUNT]	int				NOT NULL DEFAULT 0
	,	[RDT]		datetime		NOT NULL DEFAULT GETDATE()
	)
END
GO

USE DB_STAT
GO

/* stworzyć tabelę do przechowywania kluczy obcych na bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = N'DB_FK')
		AND		(OBJECTPROPERTY(o.[ID], N'IsUserTable')=1)
)
BEGIN
	SELECT N'Tabela z informacjami o kluczach obcych w tabelach' AS [msg]
	
	CREATE TABLE dbo.DB_FK
	(	stat_id		int				NOT NULL CONSTRAINT FK_DB_FK__RCOUNT FOREIGN KEY
											REFERENCES dbo.DB_STAT(stat_id)
	,	nazwa_ogr	NVARCHAR(100)	NOT NULL
	,	w_jakiej_tab_jest_ogr NVARCHAR(100) NOT NULL
	,	nazwa_kol_w_tej_tabeli NVARCHAR(100) NOT NULL
	,	na_jaka_tab_wskazuje	NVARCHAR(100) NOT NULL
	,	na_jaka_nazwa_kol	NVARCHAR(100) NOT NULL	
	)
	
	/* przykładowe zapytanie dla kluczy obcych na wybranej bazie */
	/*

	USE aa

	SELECT  f.name				AS nazwa_ogr
		,	OBJECT_NAME(f.parent_object_id) 
								AS w_jakiej_tab_jest_ogr
		,	COL_NAME(fc.parent_object_id, fc.parent_column_id) 
								AS nazwa_kol_w_tej_tabeli
		,	OBJECT_NAME (f.referenced_object_id) 
								AS na_jaka_tab_wskazuje
		,	COL_NAME(fc.referenced_object_id, fc.referenced_column_id) 
								AS na_jaka_nazwa_kol
		FROM sys.foreign_keys AS f
		JOIN sys.foreign_key_columns AS fc
		ON f.[object_id] = fc.constraint_object_id
		ORDER BY f.name

	*/
END
GO

USE DB_STAT 
GO

/* stworzyć procedurę do przechowywania liczby wierszy w wybranej bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_TC_STORE')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_TC_STORE AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_TC_STORE (@db nvarchar(100), @commt nvarchar(20) = '<unkn>')
AS
	DECLARE @sql nvarchar(MAX) -- tu będzie polecenie SQL wstawiajace wynik do tabeli
	,		@id int -- id nadane po wstawieniu rekordu do tabeli DB_STAT 
	,		@tab nvarchar(256) -- nazwa kolejne tabeli
	,		@cID nvarchar(20) -- skonwertowane @id na tekst
	
	SET @db = LTRIM(RTRIM(@db)) -- usuwamy spacje początkowe i koncowe z nazwy bazy

	/* wstawiamy rekord do tabeli DB_STAT i zapamiętujemy ID jakie nadano nowemu wierszowi */
	INSERT INTO DB_STAT.dbo.DB_STAT (comment, db_nam) VALUES (@commt, @db)
	SET  @id = SCOPE_IDENTITY() -- jakie ID zostało nadane wstawionemu wierszowi
	/* tekstowo ID aby ciągle nie konwetować w pętli */
	SET @cID = RTRIM(LTRIM(STR(@id,20,0)))
	SELECT @cID
	
	/* zapisujemy klucze obce do tabeli DB_FK */
	SET @sql = N'USE [' + @db + N']; '
					+ N' INSERT INTO DB_STAT.dbo.DB_FK (stat_id, nazwa_ogr, w_jakiej_tab_jest_ogr, nazwa_kol_w_tej_tabeli, na_jaka_tab_wskazuje, na_jaka_nazwa_kol) SELECT '
					+ @cID
					+ ',	 f.name				AS nazwa_ogr
						,	OBJECT_NAME(f.parent_object_id) 
								AS w_jakiej_tab_jest_ogr
						,	COL_NAME(fc.parent_object_id, fc.parent_column_id) 
								AS nazwa_kol_w_tej_tabeli
						,	OBJECT_NAME (f.referenced_object_id) 
								AS na_jaka_tab_wskazuje
						,	COL_NAME(fc.referenced_object_id, fc.referenced_column_id) 
								AS na_jaka_nazwa_kol
						FROM sys.foreign_keys AS f
						JOIN sys.foreign_key_columns AS fc
						ON f.[object_id] = fc.constraint_object_id
						ORDER BY f.name'
	EXEC sp_sqlexec @sql
	SET @sql = N'USE [' + @db + N']; 
    INSERT INTO DB_STAT.dbo.DB_IDX (stat_id, name_table, name_index, type_index) 
    SELECT ' + @cID + ',
        t.name,
        idx.name,
        idx.type_desc
    FROM ' + QUOTENAME(@db) + '.sys.indexes idx
    INNER JOIN ' + QUOTENAME(@db) + '.sys.tables t ON t.object_id = idx.object_id
    INNER JOIN ' + QUOTENAME(@db) + '.sys.dm_db_partition_stats ps ON idx.object_id = ps.object_id AND idx.index_id = ps.index_id
    GROUP BY t.name, idx.name, idx.type_desc';

	EXEC sp_sqlexec @sql;

	CREATE TABLE #TC ([table] nvarchar(100) )

	/* w procedurze sp_sqlExec USE jakas_baza tymczasowo przechodzi w ramach polecenia TYLO */
	SET @sql = N'USE [' + @db + N']; INSERT INTO #TC ([table]) '
			+ N' SELECT o.[name] FROM sysobjects o '
			+ N' WHERE (OBJECTPROPERTY(o.[ID], N''isUserTable'') = 1)'
	/* for debug reason not execute but select */
	--SELECT @sql 
	EXEC sp_sqlexec @sql

	-- SELECT * FROM #TC

	/* kursor po wszystkich tabelach uzytkownika */
	DECLARE CC INSENSITIVE CURSOR FOR 
			SELECT o.[table]
				FROM #TC o
				ORDER BY 1

	OPEN CC -- stoimi przed pierwszym wierszem wyniu
	FETCH NEXT FROM CC INTO @tab -- NEXT ->przejdz do kolejnego wiersza i pobierz dane
								-- do zmiennych pamięciowych

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @sql = N'USE [' + @db + N']; '
					+ N' INSERT INTO DB_STAT.dbo.DB_RCOUNT (stat_id,[table],rcount) SELECT '
					+ @cID 
					+ ',''' + RTRIM(@tab) + N''', COUNT(*) FROM [' +@db + ']..' + RTRIM(@tab)
		EXEC sp_sqlexec @sql
/*
USE [pwx_db]; 
--INSERT INTO DB_STAT.dbo.DB_RCOUNT (stat_id,[table],rcount) 
 SELECT  'etaty', COUNT(*) FROM [pwx_db]..etaty
*/
		--SELECT @sql as syntax
		/* przechodzimy do następnej tabeli */
		FETCH NEXT FROM CC INTO @tab
	END
	CLOSE CC
	DEALLOCATE CC
GO

/* test procedury 
use DB_STAT
DROP PROCEDURE dbo.DB_TC_STORE
*/
GO
EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'test', @db = N'bb'
SELECT * FROM DB_STAT WHERE stat_id = 1
/*
stat_id     db_nam               comment              when                    usr_nam                                                                                              host
----------- -------------------- -------------------- ----------------------- ---------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------
1           bb                   test                 2023-12-07 14:42:00.030 dbo                                                                                                  DESKTOP-LQ7RAM1

(1 row(s) affected)
*/

SELECT * FROM DB_STAT.dbo.DB_RCOUNT WHERE stat_id=1
SELECT * FROM DB_STAT.dbo.DB_FK WHERE stat_id = 1
SELECT * FROM DB_STAT.dbo.DB_IDX
/*
stat_id     table                                                                                                RCOUNT      RDT
----------- ---------------------------------------------------------------------------------------------------- ----------- -----------------------
1           etaty                                                                                                12          2023-12-07 14:42:00.207
1           firmy                                                                                                3           2023-12-07 14:42:00.207
1           miasta                                                                                               6           2023-12-07 14:42:00.210
1           osoby                                                                                                7           2023-12-07 14:42:00.210
1           woj                                                                                                  3           2023-12-07 14:42:00.210

(5 row(s) affected)

stat_id     nazwa_ogr                                                                                            w_jakiej_tab_jest_ogr                                                                                nazwa_kol_w_tej_tabeli                                                                               na_jaka_tab_wskazuje                                                                                 na_jaka_nazwa_kol
----------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------
1           fk_miasta__woj                                                                                       miasta                                                                                               kod_woj                                                                                              woj                                                                                                  kod_woj
1           fk_osoby__miasta                                                                                     osoby                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
1           fk_firmy__miasta                                                                                     firmy                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
1           fk_etaty__osoby                                                                                      etaty                                                                                                id_osoby                                                                                             osoby                                                                                                id_osoby
1           fk_etaty__firmy                                                                                      etaty                                                                                                id_firmy                                                                                             firmy                                                                                                nazwa_skr

(5 row(s) affected)
*/



/* mozna zrobić kursor po bazach i w petli wołąc procedurę i mieć zrzut dla wszystkich baz */

--SELECT d.name FROM sys.databases d WHERE d.database_id > 4 -- ponizej 5 są systemowe

USE DB_STAT
GO

/* Można stworzyć procedurę do przechowywania liczby wierszy w KAZDEJ !!! bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_STORE_ALL')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_STORE_ALL AS '
	EXEC sp_sqlexec @stmt
END
GO


USE DB_STAT
GO

ALTER PROCEDURE dbo.DB_STORE_ALL (@commt nvarchar(20) = N'<all>')
AS
	DECLARE CCA INSENSITIVE CURSOR FOR
			SELECT d.name 
			FROM sys.databases d 
			WHERE d.database_id > 6 -- ponizej 5 są systemowe
	DECLARE @db nvarchar(100)
	OPEN CCA
	FETCH NEXT FROM CCA INTO @db

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC DB_STAT.dbo.DB_TC_STORE @commt = 'test', @db = @db
		FETCH NEXT FROM CCA INTO @db
	END
	CLOSE CCA
	DEALLOCATE CCA
GO
/* testowanie 
use DB_STAT;
DROP PROCEDURE dbo.DB_STORE_ALL
*/
EXEC DB_STAT.dbo.DB_STORE_ALL

SELECT * FROM DB_STAT.dbo.DB_STAT
/*
stat_id     db_nam               comment              when                    usr_nam                                                                                              host
----------- -------------------- -------------------- ----------------------- ---------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------
1           bb                   test                 2023-12-07 14:42:00.030 dbo                                                                                                  DESKTOP-LQ7RAM1
2           ReportServer$LOCALDB test                 2023-12-07 14:53:53.823 dbo                                                                                                  DESKTOP-LQ7RAM1
4           APBD23_ADM           test                 2023-12-07 14:53:54.070 dbo                                                                                                  DESKTOP-LQ7RAM1
5           cc                   test                 2023-12-07 14:53:54.110 dbo                                                                                                  DESKTOP-LQ7RAM1
6           aa                   test                 2023-12-07 14:53:54.147 dbo                                                                                                  DESKTOP-LQ7RAM1
7           bb                   test                 2023-12-07 14:53:54.180 dbo                                                                                                  DESKTOP-LQ7RAM1
8           DB_STAT              test                 2023-12-07 14:53:54.223 dbo                                                                                                  DESKTOP-LQ7RAM1
9           dd                   test                 2023-12-07 14:53:54.260 dbo                                                                                                  DESKTOP-LQ7RAM1
10          ee                   test                 2023-12-07 14:53:54.290 dbo                                                                                                  DESKTOP-LQ7RAM1

(9 row(s) affected)
*/
SELECT * FROM DB_STAT.dbo.DB_RCOUNT
/*
stat_id     table                                                                                                RCOUNT      RDT
----------- ---------------------------------------------------------------------------------------------------- ----------- -----------------------
1           etaty                                                                                                12          2023-12-07 14:42:00.207
1           firmy                                                                                                3           2023-12-07 14:42:00.207
1           miasta                                                                                               6           2023-12-07 14:42:00.210
1           osoby                                                                                                7           2023-12-07 14:42:00.210
1           woj                                                                                                  3           2023-12-07 14:42:00.210
2           ActiveSubscriptions                                                                                  0           2023-12-07 14:53:53.987
2           Batch                                                                                                0           2023-12-07 14:53:53.990
2           CachePolicy                                                                                          0           2023-12-07 14:53:53.990
2           Catalog                                                                                              1           2023-12-07 14:53:53.990
2           ChunkData                                                                                            0           2023-12-07 14:53:53.993
2           ChunkSegmentMapping                                                                                  0           2023-12-07 14:53:53.997
2           ConfigurationInfo                                                                                    25          2023-12-07 14:53:54.000
2           DataSets                                                                                             0           2023-12-07 14:53:54.000
2           DataSource                                                                                           0           2023-12-07 14:53:54.000
2           DBUpgradeHistory                                                                                     46          2023-12-07 14:53:54.003
2           Event                                                                                                0           2023-12-07 14:53:54.003
2           ExecutionLogStorage                                                                                  0           2023-12-07 14:53:54.007
2           History                                                                                              0           2023-12-07 14:53:54.007
2           Keys                                                                                                 2           2023-12-07 14:53:54.010
2           ModelDrill                                                                                           0           2023-12-07 14:53:54.010
2           ModelItemPolicy                                                                                      0           2023-12-07 14:53:54.010
2           ModelPerspective                                                                                     0           2023-12-07 14:53:54.010
2           Notifications                                                                                        0           2023-12-07 14:53:54.013
2           Policies                                                                                             2           2023-12-07 14:53:54.013
2           PolicyUserRole                                                                                       4           2023-12-07 14:53:54.017
2           ReportSchedule                                                                                       0           2023-12-07 14:53:54.017
2           Roles                                                                                                8           2023-12-07 14:53:54.020
2           RunningJobs                                                                                          0           2023-12-07 14:53:54.020
2           Schedule                                                                                             0           2023-12-07 14:53:54.020
2           SecData                                                                                              2           2023-12-07 14:53:54.020
2           Segment                                                                                              0           2023-12-07 14:53:54.023
2           SegmentedChunk                                                                                       0           2023-12-07 14:53:54.023
2           ServerParametersInstance                                                                             0           2023-12-07 14:53:54.027
2           ServerUpgradeHistory                                                                                 2           2023-12-07 14:53:54.027
2           SnapshotData                                                                                         0           2023-12-07 14:53:54.027
2           Subscriptions                                                                                        0           2023-12-07 14:53:54.030
2           SubscriptionsBeingDeleted                                                                            0           2023-12-07 14:53:54.030
2           UpgradeInfo                                                                                          1           2023-12-07 14:53:54.030
2           Users                                                                                                3           2023-12-07 14:53:54.033
4           BK_LOG                                                                                               205         2023-12-07 14:53:54.103
4           CRDB_LOG                                                                                             25          2023-12-07 14:53:54.103
4           CRUSR_LOG                                                                                            25          2023-12-07 14:53:54.107
4           DB_CHECK                                                                                             108         2023-12-07 14:53:54.107
4           DB_CHECK_ITEMS                                                                                       648         2023-12-07 14:53:54.110
5           etaty                                                                                                12          2023-12-07 14:53:54.140
5           firmy                                                                                                3           2023-12-07 14:53:54.143
5           miasta                                                                                               6           2023-12-07 14:53:54.143
5           osoby                                                                                                7           2023-12-07 14:53:54.143
5           woj                                                                                                  3           2023-12-07 14:53:54.143
6           etaty                                                                                                15          2023-12-07 14:53:54.177
6           firmy                                                                                                3           2023-12-07 14:53:54.177
6           miasta                                                                                               6           2023-12-07 14:53:54.180
6           osoby                                                                                                10          2023-12-07 14:53:54.180
6           woj                                                                                                  3           2023-12-07 14:53:54.180
7           etaty                                                                                                12          2023-12-07 14:53:54.213
7           firmy                                                                                                3           2023-12-07 14:53:54.217
7           miasta                                                                                               6           2023-12-07 14:53:54.220
7           osoby                                                                                                7           2023-12-07 14:53:54.220
7           woj                                                                                                  3           2023-12-07 14:53:54.220
8           DB_FK                                                                                                49          2023-12-07 14:53:54.253
8           DB_RCOUNT                                                                                            60          2023-12-07 14:53:54.257
8           DB_STAT                                                                                              7           2023-12-07 14:53:54.257

(62 row(s) affected)
*/
SELECT * FROM DB_STAT.dbo.DB_FK
/*
stat_id     nazwa_ogr                                                                                            w_jakiej_tab_jest_ogr                                                                                nazwa_kol_w_tej_tabeli                                                                               na_jaka_tab_wskazuje                                                                                 na_jaka_nazwa_kol
----------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ----------------------------------------------------------------------------------------------------
1           fk_miasta__woj                                                                                       miasta                                                                                               kod_woj                                                                                              woj                                                                                                  kod_woj
1           fk_osoby__miasta                                                                                     osoby                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
1           fk_firmy__miasta                                                                                     firmy                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
1           fk_etaty__osoby                                                                                      etaty                                                                                                id_osoby                                                                                             osoby                                                                                                id_osoby
1           fk_etaty__firmy                                                                                      etaty                                                                                                id_firmy                                                                                             firmy                                                                                                nazwa_skr
2           FK_DataSetItemID                                                                                     DataSets                                                                                             ItemID                                                                                               Catalog                                                                                              ItemID
2           FK_DataSetLinkID                                                                                     DataSets                                                                                             LinkID                                                                                               Catalog                                                                                              ItemID
2           FK_ModelDrillModel                                                                                   ModelDrill                                                                                           ModelID                                                                                              Catalog                                                                                              ItemID
2           FK_ModelDrillReport                                                                                  ModelDrill                                                                                           ReportID                                                                                             Catalog                                                                                              ItemID
2           FK_ModelPerspectiveModel                                                                             ModelPerspective                                                                                     ModelID                                                                                              Catalog                                                                                              ItemID
2           FK_CachePolicyReportID                                                                               CachePolicy                                                                                          ReportID                                                                                             Catalog                                                                                              ItemID
2           FK_DataSourceItemID                                                                                  DataSource                                                                                           ItemID                                                                                               Catalog                                                                                              ItemID
2           FK_Catalog_ParentID                                                                                  Catalog                                                                                              ParentID                                                                                             Catalog                                                                                              ItemID
2           FK_Catalog_LinkSourceID                                                                              Catalog                                                                                              LinkSourceID                                                                                         Catalog                                                                                              ItemID
2           FK_Subscriptions_Catalog                                                                             Subscriptions                                                                                        Report_OID                                                                                           Catalog                                                                                              ItemID
2           FK_ReportSchedule_Report                                                                             ReportSchedule                                                                                       ReportID                                                                                             Catalog                                                                                              ItemID
2           FK_PolicyUserRole_User                                                                               PolicyUserRole                                                                                       UserID                                                                                               Users                                                                                                UserID
2           FK_Catalog_CreatedByID                                                                               Catalog                                                                                              CreatedByID                                                                                          Users                                                                                                UserID
2           FK_Catalog_ModifiedByID                                                                              Catalog                                                                                              ModifiedByID                                                                                         Users                                                                                                UserID
2           FK_Subscriptions_ModifiedBy                                                                          Subscriptions                                                                                        ModifiedByID                                                                                         Users                                                                                                UserID
2           FK_Subscriptions_Owner                                                                               Subscriptions                                                                                        OwnerID                                                                                              Users                                                                                                UserID
2           FK_Schedule_Users                                                                                    Schedule                                                                                             CreatedById                                                                                          Users                                                                                                UserID
2           FK_PolicyUserRole_Policy                                                                             PolicyUserRole                                                                                       PolicyID                                                                                             Policies                                                                                             PolicyID
2           FK_SecDataPolicyID                                                                                   SecData                                                                                              PolicyID                                                                                             Policies                                                                                             PolicyID
2           FK_PoliciesPolicyID                                                                                  ModelItemPolicy                                                                                      PolicyID                                                                                             Policies                                                                                             PolicyID
2           FK_Catalog_Policy                                                                                    Catalog                                                                                              PolicyID                                                                                             Policies                                                                                             PolicyID
2           FK_PolicyUserRole_Role                                                                               PolicyUserRole                                                                                       RoleID                                                                                               Roles                                                                                                RoleID
2           FK_ActiveSubscriptions_Subscriptions                                                                 ActiveSubscriptions                                                                                  SubscriptionID                                                                                       Subscriptions                                                                                        SubscriptionID
2           FK_Notifications_Subscriptions                                                                       Notifications                                                                                        SubscriptionID                                                                                       Subscriptions                                                                                        SubscriptionID
2           FK_ReportSchedule_Subscriptions                                                                      ReportSchedule                                                                                       SubscriptionID                                                                                       Subscriptions                                                                                        SubscriptionID
2           FK_ReportSchedule_Schedule                                                                           ReportSchedule                                                                                       ScheduleID                                                                                           Schedule                                                                                             ScheduleID
4           FK_DB_CHECK__DB_CHECK_ITEMS                                                                          DB_CHECK_ITEMS                                                                                       check_id                                                                                             DB_CHECK                                                                                             check_id
5           fk_miasta__woj                                                                                       miasta                                                                                               kod_woj                                                                                              woj                                                                                                  kod_woj
5           fk_osoby__miasta                                                                                     osoby                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
5           fk_firmy__miasta                                                                                     firmy                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
5           fk_etaty__osoby                                                                                      etaty                                                                                                id_osoby                                                                                             osoby                                                                                                id_osoby
5           fk_etaty__firmy                                                                                      etaty                                                                                                id_firmy                                                                                             firmy                                                                                                nazwa_skr
6           fk_miasta__woj                                                                                       miasta                                                                                               kod_woj                                                                                              woj                                                                                                  kod_woj
6           fk_osoby__miasta                                                                                     osoby                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
6           fk_firmy__miasta                                                                                     firmy                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
6           fk_etaty__osoby                                                                                      etaty                                                                                                id_osoby                                                                                             osoby                                                                                                id_osoby
6           fk_etaty__firmy                                                                                      etaty                                                                                                id_firmy                                                                                             firmy                                                                                                nazwa_skr
7           fk_miasta__woj                                                                                       miasta                                                                                               kod_woj                                                                                              woj                                                                                                  kod_woj
7           fk_osoby__miasta                                                                                     osoby                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
7           fk_firmy__miasta                                                                                     firmy                                                                                                id_miasta                                                                                            miasta                                                                                               id_miasta
7           fk_etaty__osoby                                                                                      etaty                                                                                                id_osoby                                                                                             osoby                                                                                                id_osoby
7           fk_etaty__firmy                                                                                      etaty                                                                                                id_firmy                                                                                             firmy                                                                                                nazwa_skr
8           FK_DB_STAT__RCOUNT                                                                                   DB_RCOUNT                                                                                            stat_id                                                                                              DB_STAT                                                                                              stat_id
8           FK_DB_FK__RCOUNT                                                                                     DB_FK                                                                                                stat_id                                                                                              DB_STAT                                                                                              stat_id

(49 row(s) affected)
*/

/* 
bezpieczne podglądanie pracy procedury:
1. Otwieramy nowe okno i wpisujemy 
SELECT * FROM DB_STAT (NOLOCK) 

SELECT * FROM DB_STAT.dbo.DB_RCOUNT (NOLOCK) WHERE stat_id=3
-- 3 bo takie ID chialem podejrzec
*/
/* 
-- usuwanie klucza
ALTER TABLE NazwaTabeli DROP CONSTRAINT NazwaOgr

PROCEDURA USUWANIA KLUCZY NAJPIERW POWINNA JE ZAPAMIETAC W TABELACH !!!

-- dodawanie kluczy do tabeli
USE baza;
ALTER TABLE dbo.nazwa_tabeli ADD CONSTRAINT nazwa_klucza FOREIGN KEY (kolumna) REFERENCES MasterTabela(kolumna_w_master)

Przykładowo:
EXEC dbo.DB_FK_RESTORE  @db='pwx_db'
generuje i wykonuje ponisze polecenia (przykładowo tylko dla ETATY):
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT FK_ETATY_ETATY FOREIGN KEY (z_etatu) REFERENCES etaty(id_etatu)
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT fk_etaty__osoby FOREIGN KEY (id_osoby) REFERENCES osoby(id_osoby)
USE [pwx_db];  ALTER TABLE etaty ADD CONSTRAINT fk_etaty__firmy FOREIGN KEY (id_firmy) REFERENCES firmy(nazwa_skr)

*/

/* Procedura do usuwania kluczy obcych w konkretnej bazie 
Najpierw sprawdza czy udalo sie zapisac obecny stan bazy
*/
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_FK_DELETE')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_FK_DELETE AS '
	EXEC sp_sqlexec @stmt
END
GO


USE DB_STAT;
GO

ALTER PROCEDURE dbo.DB_FK_DELETE (@db nvarchar(100), @commt nvarchar(20) = 'Usuwanie kluczy' )
AS
	DECLARE @returnValue INT, @max_id INT
	DECLARE @table_name NVARCHAR(100), @nazwa_ogr NVARCHAR(150), @sql NVARCHAR(1000)
	EXEC @returnValue = DB_STAT.dbo.DB_TC_STORE @db = @db, @commt = @commt
	/* Jesli udalo sie zachowac obecny stan kluczy obcych w bazie wykonaj operacje usuwania kluczy 
		wez ostatni max(stad_id) z tabeli DB_FK i na tej podstawie usun klucze
	*/
	IF @returnValue = 0
		BEGIN
			SET @max_id = (SELECT MAX(o.stat_id)
								FROM DB_STAT o
								WHERE o.[db_nam] = @db
								AND EXISTS ( SELECT 1 FROM db_fk f WHERE f.stat_id = o.stat_id))
			DECLARE CDFK INSENSITIVE CURSOR FOR
				SELECT
					d.w_jakiej_tab_jest_ogr,
					d.nazwa_ogr
				FROM DB_STAT.dbo.DB_FK d
				WHERE d.stat_id = @max_id
			OPEN CDFK
			FETCH NEXT FROM CDFK INTO @table_name, @nazwa_ogr
			WHILE @@FETCH_STATUS = 0
			BEGIN
				SET @sql = N'USE [' + @db + N']; '
					+ N' ALTER TABLE ' + @table_name + N' DROP CONSTRAINT ' + @nazwa_ogr
				EXEC sp_sqlexec @sql
				FETCH NEXT FROM CDFK INTO @table_name, @nazwa_ogr
			END
			CLOSE CDFK
			DEALLOCATE CDFK
				
		END
	ELSE
	/* Jesli nie udalo sie to zwroc informacje o bledzie */
		BEGIN
		PRINT('Nie udalo sie usunac kluczy obcych dla bazy: ' + @db)
		END
	
GO

/* Testowanie i usuwanie procedury 
use DB_STAT;
DROP PROCEDURE dbo.DB_FK_DELETE
*/
GO

EXEC DB_FK_DELETE @db = 'aa'


/* Sprawdzenie czy klucze zostaly usuniete */
USE aa;

	SELECT  f.name				AS nazwa_ogr
		,	OBJECT_NAME(f.parent_object_id) 
								AS w_jakiej_tab_jest_ogr
		,	COL_NAME(fc.parent_object_id, fc.parent_column_id) 
								AS nazwa_kol_w_tej_tabeli
		,	OBJECT_NAME (f.referenced_object_id) 
								AS na_jaka_tab_wskazuje
		,	COL_NAME(fc.referenced_object_id, fc.referenced_column_id) 
								AS na_jaka_nazwa_kol
		FROM sys.foreign_keys AS f
		JOIN sys.foreign_key_columns AS fc
		ON f.[object_id] = fc.constraint_object_id
		ORDER BY f.name
/*
nazwa_ogr                                                                                                                        w_jakiej_tab_jest_ogr                                                                                                            nazwa_kol_w_tej_tabeli                                                                                                           na_jaka_tab_wskazuje                                                                                                             na_jaka_nazwa_kol
-------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------

(0 row(s) affected)
*/




/* Procedura do dodawania kluczy obcych w konkretnej bazie */
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'DB_FK_RESTORE')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.DB_FK_RESTORE AS '
	EXEC sp_sqlexec @stmt
END
GO


USE DB_STAT;
GO

ALTER PROCEDURE dbo.DB_FK_RESTORE (@db nvarchar(100), @stat_id INT = NULL)
AS
	DECLARE @table_name NVARCHAR(100), @nazwa_ogr NVARCHAR(100), @nazwa_kol_tab NVARCHAR(100), @druga_tabela NVARCHAR(100), @druga_kolumna NVARCHAR(100)
	DECLARE @sql NVARCHAR(1000)
	IF @stat_id IS NULL
		BEGIN
			/* Jesli stat_id nie zostal podany to bierzemy ostatni wpis */
			SET @stat_id = (SELECT MAX(o.stat_id)
								FROM DB_STAT o
								WHERE o.[db_nam] = @db
								AND EXISTS ( SELECT 1 FROM db_fk f WHERE f.stat_id = o.stat_id))
		END
	DECLARE CDFRK INSENSITIVE CURSOR FOR
				SELECT
					d.w_jakiej_tab_jest_ogr,
					d.nazwa_ogr,
					d.nazwa_kol_w_tej_tabeli,
					d.na_jaka_tab_wskazuje,
					d.na_jaka_nazwa_kol
				FROM DB_STAT.dbo.DB_FK d
				WHERE d.stat_id = 10
			OPEN CDFRK
	FETCH NEXT FROM CDFRK INTO @table_name, @nazwa_ogr, @nazwa_kol_tab, @druga_tabela, @druga_kolumna
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = N'USE [' + @db + N']; '
					+ N' ALTER TABLE ' 
					+ @table_name 
					+ N' ADD CONSTRAINT ' 
					+ @nazwa_ogr 
					+ N' FOREIGN KEY (' 
					+ @nazwa_kol_tab 
					+ N') REFERENCES ' 
					+ @druga_tabela 
					+ N'('
					+ @druga_kolumna
					+ N')' 
		
		EXEC sp_sqlexec @sql
		FETCH NEXT FROM CDFRK INTO @table_name, @nazwa_ogr, @nazwa_kol_tab, @druga_tabela, @druga_kolumna
	END
	CLOSE CDFRK
	DEALLOCATE CDFRK
GO

SELECT * FROM DB_STAT.dbo.DB_FK
SELECT * FROM aa.dbo.woj
SELECT * FROM aa.dbo.miasta
/* Testowanie i usuwanie procedury 
use DB_STAT;
DROP PROCEDURE dbo.DB_FK_RESTORE
WZOR DODAWANIA
USE [pwx_db];  ALTER TABLE osoby ADD CONSTRAINT FK_osoby__miasta FOREIGN KEY (id_miasta) REFERENCES miasta(id_miasta)
fk_osoby__miasta    osoby    id_miasta          miasta   id_miasta

id_miasta	int 		not null
	constraint fk_osoby__miasta foreign key
	references miasta(id_miasta)
*/
GO

EXEC DB_FK_RESTORE @db = 'aa', @stat_id = 10
/* Sprawdzenie czy powstaly klucze obce */
USE aa;

	SELECT  f.name				AS nazwa_ogr
		,	OBJECT_NAME(f.parent_object_id) 
								AS w_jakiej_tab_jest_ogr
		,	COL_NAME(fc.parent_object_id, fc.parent_column_id) 
								AS nazwa_kol_w_tej_tabeli
		,	OBJECT_NAME (f.referenced_object_id) 
								AS na_jaka_tab_wskazuje
		,	COL_NAME(fc.referenced_object_id, fc.referenced_column_id) 
								AS na_jaka_nazwa_kol
		FROM sys.foreign_keys AS f
		JOIN sys.foreign_key_columns AS fc
		ON f.[object_id] = fc.constraint_object_id
		ORDER BY f.name
/*
nazwa_ogr                                                                                                                        w_jakiej_tab_jest_ogr                                                                                                            nazwa_kol_w_tej_tabeli                                                                                                           na_jaka_tab_wskazuje                                                                                                             na_jaka_nazwa_kol
-------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- --------------------------------------------------------------------------------------------------------------------------------
fk_etaty__firmy                                                                                                                  etaty                                                                                                                            id_firmy                                                                                                                         firmy                                                                                                                            nazwa_skr
fk_etaty__osoby                                                                                                                  etaty                                                                                                                            id_osoby                                                                                                                         osoby                                                                                                                            id_osoby
fk_firmy__miasta                                                                                                                 firmy                                                                                                                            id_miasta                                                                                                                        miasta                                                                                                                           id_miasta
fk_miasta__woj                                                                                                                   miasta                                                                                                                           kod_woj                                                                                                                          woj                                                                                                                              kod_woj
fk_osoby__miasta                                                                                                                 osoby                                                                                                                            id_miasta                                                                                                                        miasta                                                                                                                           id_miasta

(5 row(s) affected)
*/
/* Czyli udalo sie odtworzyc klucze obce w bazie aa */
