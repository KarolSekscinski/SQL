/* Z5
Imie Nazwisko: Karol Sekscinski
nr albumu 319093
*/


use DB_STAT
go

/* usuwanie kolumny z tabeli
** Procedura BD z 3 parametrami
** nazwa bazy, nazwa tabeli, nazwa kol
**
** 1. Sprawdzamy czy kolumna istnieje (zapytanie z syscolumns połaczone z sysobjects po ID)
** 1.1. Jak istnieje sprawdzamy czy są pewne ograniczenia (np DEFAULT był założony)
** 1.2 Jak TAK - usuwamy ograniczenia
** 1.3. Usuwamy kolumne
*/

/* przykład - tworzę tabelę z DEFALT - to tworzy automatycznie ograniczenie na kolumnie */
--DROP TABLE DB_STAT.dbo.test_us_kol
CREATE TABLE dbo.test_us_kol 
(	[id] nchar(6) not null
,	czy_wazny bit NOT NULL default 0 /* to powoduje powstanie constrain 
									** system nada unialną nazwę */
)
go
INSERT INTO test_us_kol ([id]) VALUES (N'ala')
INSERT INTO test_us_kol ([id], czy_wazny) VALUES (N'kot', 1)
SELECT * FROM test_us_kol 
/*
id	czy_wazny
ala   	0
kot   	1
*/

/* próbuję usunąć czy_wazny z tabeli 
*/
ALTER TABLE test_us_kol drop column czy_wazny
/* zapytanie z sysobjects - tu nazwa tabeli 
** połączone z syscolumns - tu nazwa kolumny
** aby stwierdzić czy taka kolumna istnieje
*/

/*
Msg 5074, Level 16, State 1, Line 1
The object 'DF__test_us_k__czy_w__48CFD27E' is dependent on column 'czy_wazny'.
Msg 4922, Level 16, State 9, Line 1
ALTER TABLE DROP COLUMN czy_wazny failed because one or more objects access this column.
*/

/* aby usunąć najpierw muszę usunąć ograniczenie a dopiero potem mogę usunąć kolumnę */
/* nazwę ograniczenia skopiowałem z komunikatu - Państwo muszą tę nazwę pobrać jakimś zapytaniem */

ALTER TABLE test_us_kol drop constraint  DF__test_us_k__czy_w__48CFD27E
/* po usunięciu ograniczenia mozna usunąć kolumnę */
ALTER TABLE test_us_kol drop column czy_wazny

select * from test_us_kol 
/*id
ala   
kot   
*/

/* 
** Projekt przewidziany do sylwestra ;)
** 1. Proszę poszukać/stworzyć zapytanie wyszukujące dla 
**  danej tabeli, danej kolumny - ograniczenia jakie są nałożone
** 2. Stworzyć procedure usun_kolumne z parametrami @nazwa_tabeli, @nazwa_kolumny
** która tworzy kursor z zapytania numer 1 i w petli kasuje wszystkie ograniczenia
** na koncu kasuję tę kolumnę
** 3. udowodnić na przykladzie jak powyżej że działa - jest kolumna przed
** ma ograniczenia a procedura usuwa ją i pokazujemy, że już nie ma takowej
*/


USE DB_STAT;
GO
IF NOT EXISTS 
(	SELECT 1 
		from sysobjects o (NOLOCK)
		WHERE	(o.[name] = 'usun_kolumne')
		AND		(OBJECTPROPERTY(o.[ID],'IsProcedure')=1)
)
BEGIN
	DECLARE @stmt nvarchar(100)
	SET @stmt = 'CREATE PROCEDURE dbo.usun_kolumne AS '
	EXEC sp_sqlexec @stmt
END
GO

USE DB_STAT
GO

ALTER PROCEDURE dbo.usun_kolumne (@nazwa_tabeli nvarchar(100), @nazwa_kolumny nvarchar(100))
AS
	DECLARE @sql nvarchar(500)
	DECLARE @contraint_name nvarchar(30)

	DECLARE C INSENSITIVE CURSOR FOR 
		SELECT 
			obj.name AS constraint_name
		FROM sys.objects obj
		INNER JOIN sys.columns col ON obj.parent_object_id = col.object_id
		INNER JOIN sys.tables t ON obj.parent_object_id = t.object_id
		INNER JOIN sys.schemas sch ON t.schema_id = sch.schema_id
		WHERE t.name = @nazwa_tabeli AND col.name = @nazwa_kolumny
	
	
	OPEN C
	FETCH NEXT FROM C INTO @contraint_name

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SET @sql = N'ALTER TABLE ' + @nazwa_tabeli + N' drop constraint  ' + @contraint_name
		EXEC sp_sqlexec @sql
		
		FETCH NEXT FROM C INTO @contraint_name

	END
	SET @sql = N'ALTER TABLE ' + @nazwa_tabeli + N' drop column ' + @nazwa_kolumny
	EXEC sp_sqlexec @sql
	CLOSE C
	DEALLOCATE C
GO

GO
--DROP PROCEDURE dbo.usun_kolumne

/* Przed wykonaniem procedury */
SELECT 
    t.name AS table_name,
    col.name AS column_name,
    obj.name AS constraint_name,
    obj.type_desc AS constraint_type
FROM sys.objects obj
INNER JOIN sys.columns col ON obj.parent_object_id = col.object_id
INNER JOIN sys.tables t ON obj.parent_object_id = t.object_id
INNER JOIN sys.schemas sch ON t.schema_id = sch.schema_id
WHERE t.name = 'test_us_kol' AND col.name = 'czy_wazny'



/*
table_name                                                                                                                       column_name                                                                                                                      constraint_name                                                                                                                  constraint_type
-------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------
test_us_kol                                                                                                                      czy_wazny                                                                                                                        DF__test_us_k__czy_w__5FB337D6                                                                                                   DEFAULT_CONSTRAINT

(1 row(s) affected)

*/

GO
EXEC DB_STAT.dbo.usun_kolumne @nazwa_tabeli = 'test_us_kol', @nazwa_kolumny = 'czy_wazny'
GO

/* Po wykonaniu procedury wywolanie tego samego zapytania co przed procedura
table_name                                                                                                                       column_name                                                                                                                      constraint_name                                                                                                                  constraint_type
-------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------------------------------------------------------

(0 row(s) affected)
*/

SELECT * FROM dbo.test_us_kol
/*
id
------
ala   
kot   

(2 row(s) affected)
*/