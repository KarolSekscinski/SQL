/* Z3
Imie Nazwisko: Karol Sekscinski
Nr albumu 319093
** proszê zrobiæ w bazie administracyjnej tabelê do przechowania uruchomieñ backupu
** BK_LOG ( bk_id int not null identity CONSTRAINT PK_BK_LOG PRIMARY KEY
, nazwa_b nvarchar(100) not null, nazwa_pliku_bk nvarchar(200) not null,
, kto nvarchar(100) not null default USER_NAME(), skad nvarchar(100) not null 
default host_name(), kiedy datetime not null default getdate() ) 

** Napisac 3 procedury
** bk_db - backup pojedynczej bazy
** bk_all_db - backup wszystkich baz
** do pliku na wyznaczonym katalogu
** nazwa kazdego pliku to nazwabazy PODKRESLENIE YYYYYMMDDHHMM
** Zaplanowaæ uruchamianie procedury backupy wszystkich baz poprzez SQL Agent na co dzien
** Zdokumentowac i udowodnic, ze JOB zadziala³ i pliki powsta³y
** prawozdanie raczej w PDF bo oczekujê zdjêcia z SQL Agenta jobów
** (uwaga job po protu wo³a procedurê SQL)
** oraz screen ze pliki backupu powta³y

** Ostatnie 3cia proedura:
** Napisaæ procedurê, która 
1. KOrzystaj¹c z tabel z zadania Z2 i procedur do statystyk
, które przechowuj¹ liczby rekordów
2. do backupu wybierze bazy gdzie pomiêdzy dwoma statystykimi
dla tej samej bazy
w tej samej tabeli
nast¹pi³ przyrost powyzej 100 rekordów (lub zadany parametr @liczba)

Czyli robimy backup tej bazy w której chocia¿ w jednej tabeli pomiêdzy dwoma kolejnymi statystykami
przyros³o o ileœ tam,
UWAGA trzeba zrobiæ pêtlê po bazach z tabeli statystyk
znalezc id ostatniej statystyki !!!!
znalezc id poprzedniej MAX(z id) gdzie id < ostatnia
CZYLI POROWNUJEMY 2 OSTATNIE staystyki !!! TYLKO a NIE DOWOLNE 
UWAGA !!! dopuszczam tez algorytm:
1. Odpalacie statystyki
2. Porównujecie ostatni¹ do takiej dla kazdej z baz która by³a ostatnia i starsza ni¿ 12 godzin
DATEDIFF - porównuje róznice DATEDIFF(HH,@d1,@d2) na przyk³ad
Dlaczego ?
Powiedzmy, ze backup odpalacie co 12 godzin i chcecie najpierw wymusic ostatnie statystyki
ale chcecie porownac do ostatnich statystyk sprzed 12tu godzin
czyli bedzie to SELECT MAX(st_id) FROM stat s WHERE DATEDIFF(HH,s.data_st,GETDATE()) >= 12  
czyli ostatnia ze starszych niz 12 godzin
*/

/* wskazówka -> s³adnia backupu do pliku 
*/

DECLARE @db nvarchar(100) -- to bedzie parametr procedury
, @path nvarchar(200) -- drugi parametr np domyslnie C:\temp\ musi sie konczyc na \
						-- jak sie nie konczy to dodajemy
, @fname nvarchar(1000)

/* normalnie to bed¹ parametry wywolania - sprawdzamy czy baza istnieje */

SET @db = N'aa'
SET @path = N'C:\Users\seksc\Documents\sem5\abd\backup\'  

SET @fname = REPLACE(REPLACE(CONVERT(nchar(19), GETDATE(), 126), N':', N'_'),'-','_')
SET @fname = @path + RTRIM(@db)  + @fname + N'.bak'

-- test
-- SELECT @fname
-- C:\temp\PWX_DB2020_10_29T15_13_50.bak

DECLARE @sql nvarchar(100)

SET @sql = 'backup database ' + @db + ' to DISK= ''' + @fname + ''''
--backup database PWX_DB to DISK= 'C_\temp\PWX_DB2020_10_29T15_12_43.bak'
-- test
SELECT @sql
--backup database aa to DISK= 'C:\temp\PWX_DB2020_10_29T15_14_29.bak'

EXEC sp_sqlexec @sql
/* Tworzenie tabeli 
use APBD23_ADM;
GO
CREATE TABLE BK_LOG ( bk_id int not null identity CONSTRAINT PK_BK_LOG PRIMARY KEY
, nazwa_b nvarchar(100) not null, nazwa_pliku_bk nvarchar(200) not null
, kto nvarchar(100) not null default USER_NAME(), skad nvarchar(100) not null 
default host_name(), kiedy datetime not null default getdate() ) 
*/

GO
CREATE PROCEDURE bk_db 
(@db_name nvarchar(100)
, @path nvarchar(200) = NULL
, @fname nvarchar(1000) = NULL)
AS
BEGIN


	IF EXISTS (SELECT 1 FROM sys.databases WHERE name = @db_name)
		BEGIN
			IF @path IS NULL
				BEGIN
					SET @path = 'C:\Users\seksc\Documents\sem5\abd\backup\'
					PRINT(@path)
				END
			ELSE
				BEGIN
					IF RIGHT(@path, 1) = N'\'
						BEGIN
							SET @path = @path + '\'
							PRINT(@path)
						END
				END
			IF @fname IS NULL
				BEGIN
					--SET @fname = @path + RTRIM(@db_name) + '_' + REPLACE(CONVERT(NVARCHAR(50), GETDATE(), 120), ':', '') + '.bak'

					SET @fname = REPLACE(REPLACE(REPLACE(CONVERT(nchar(16), GETDATE(), 126), N':', N''),'-',''), 'T', '')
					SET @fname = @path + RTRIM(@db_name) + '_' + @fname + N'.bak'

					PRINT(@fname)
				END
			DECLARE @sql nvarchar(1000)
			
			SET @sql = 'BACKUP DATABASE ' + @db_name + ' TO DISK= ''' + @fname + ''''
			DECLARE @returnValue INT
			EXEC @returnValue = sp_sqlexec @sql
			
			IF @returnValue = 0
			BEGIN
			
				INSERT INTO APBD23_ADM.dbo.BK_LOG(nazwa_b, nazwa_pliku_bk) VALUES (@db_name, @fname)
			END
		END
END

EXEC bk_db @db_name = 'aa'
/*
Processed 432 pages for database 'aa', file 'aa' on file 1.
Processed 2 pages for database 'aa', file 'aa_log' on file 1.
BACKUP DATABASE successfully processed 434 pages in 0.020 seconds (169.335 MB/sec).

(1 row affected)

Completion time: 2023-11-17T16:57:10.7968868+01:00
*/
SELECT * FROM APBD23_ADM.dbo.BK_LOG

/*
bk_id       nazwa_b                                                                                              nazwa_pliku_bk                                                                                                                                                                                           kto                                                                                                  skad                                                                                                 kiedy
----------- ---------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- -----------------------
1           aa                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\aa_202311171657.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 16:57:10.790

(1 row affected)
*/
GO
CREATE PROCEDURE bk_all_db
AS
BEGIN
	DECLARE @d NVARCHAR(50)
	DECLARE CI INSENSITIVE CURSOR FOR
		SELECT d.[name] FROM sysdatabases d
	OPEN CI 
	FETCH NEXT FROM CI INTO @d
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @d AS db_name
		EXEC bk_db @db_name = @d
		FETCH NEXT FROM CI INTO @d
	END
	CLOSE CI
	DEALLOCATE CI
END
EXEC bk_all_db
SELECT * FROM APBD23_ADM.dbo.BK_LOG
/*
bk_id       nazwa_b                                                                                              nazwa_pliku_bk                                                                                                                                                                                           kto                                                                                                  skad                                                                                                 kiedy
----------- ---------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- -----------------------
1           aa                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\aa_202311171657.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 16:57:10.790
2           master                                                                                               C:\Users\seksc\Documents\sem5\abd\backups\master_202311171700.bak                                                                                                                                        dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:05.713
3           tempdb                                                                                               C:\Users\seksc\Documents\sem5\abd\backups\tempdb_202311171700.bak                                                                                                                                        dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:05.713
4           model                                                                                                C:\Users\seksc\Documents\sem5\abd\backups\model_202311171700.bak                                                                                                                                         dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:05.750
5           msdb                                                                                                 C:\Users\seksc\Documents\sem5\abd\backups\msdb_202311171700.bak                                                                                                                                          dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:05.850
6           aa                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\aa_202311171700.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:05.927
7           bb                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\bb_202311171700.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:06.003
8           cc                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\cc_202311171700.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:06.067
9           dd                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\dd_202311171700.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:06.130
10          ee                                                                                                   C:\Users\seksc\Documents\sem5\abd\backups\ee_202311171700.bak                                                                                                                                            dbo                                                                                                  DESKTOP-LQ7RAM1                                                                                      2023-11-17 17:00:06.190

(10 rows affected)
*/

GO
CREATE PROCEDURE trzecia (@liczba INT = 5)
AS
BEGIN
	
	DECLARE @db NVARCHAR(50), @FileName NVARCHAR(1000);

	CREATE TABLE #t (
		DatabaseName NVARCHAR(50),
		FileName NVARCHAR(500)
	);

	;WITH LatestRows AS (
    SELECT
        dc.db_nam AS DatabaseName,
        dci.tb_nam AS TableName,
        dci.tb_check_d_stamp AS RecordDate,
        dci.LICZBA_REKORDOW AS RecordCount,
        ROW_NUMBER() OVER(PARTITION BY dc.db_nam, dci.tb_nam ORDER BY dci.tb_check_d_stamp DESC) AS RowNum
    FROM
        APBD23_ADM.dbo.DB_CHECK dc
    INNER JOIN
        APBD23_ADM.dbo.DB_CHECK_ITEMS dci ON dc.check_id = dci.check_id
)

	INSERT INTO #t (DatabaseName, FileName)
	SELECT DatabaseName, (
		SELECT TOP 1 nazwa_pliku_bk 
		FROM APBD23_ADM.dbo.BK_LOG
		WHERE nazwa_b = DatabaseName
		ORDER BY kiedy DESC
	)
	FROM LatestRows LR1
	
	WHERE
    LR1.RowNum = 1
    AND EXISTS (
        SELECT 1
        FROM LatestRows LR2
        WHERE
            LR1.DatabaseName = LR2.DatabaseName
            AND LR1.TableName = LR2.TableName
            AND LR2.RowNum = 2
            AND LR1.RecordCount - LR2.RecordCount > @liczba
    );

	DECLARE db_cursor CURSOR FOR
	SELECT DatabaseName, FileName
	FROM #t;

	OPEN db_cursor;
	FETCH NEXT FROM db_cursor INTO @db, @FileName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		RESTORE DATABASE @db
		FROM DISK = @FileName
		
		FETCH NEXT FROM db_cursor INTO @db, @FileName;
	END

	CLOSE db_cursor;
	DEALLOCATE db_cursor;
	DROP TABLE #t;
END


EXEC trzecia