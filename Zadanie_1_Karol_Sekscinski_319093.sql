/*
Imie Nazwisko, nr albumu: Karol Sekscinski, 319093

logowanie do sieci:
login: numerALbumu
hasło: numerAlbumu

logowanie do SQL w laboratorium (do kazdego SQL indywidualnie na kazdej stacji stąd z zewnątrz 
nie da się

program MS Management SQL studio (w lab wersja 2012)
host (musi być nazwa komputera typu P# gdzie # to numer komputera BEZ NICZEGO WIECEJ)
user: sa (małe litery)
hasło: Zima@2022
*/


/* proszę stworzyć skrypt w którym
1. Utworzycie Państwo bazę APBD23_ADM jeżeli takowa nie istnieje
2. Utworzycie Państwo tabele w tej bazie CRDB_LOG i CRUSR_LOG
kto_chcial, nazwa_bazy / lub loginu, data wstawienia rekordu, czy_powiodło się, opis błedu
kolumny mogą miec inne nazwy ale aby miały te właśnie informacje
*/
DECLARE @adm_db nvarchar(50), @sql nvarchar(2000)
SET @adm_db = N'APBD23_ADM'
IF NOT EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = @adm_db)
BEGIN
	SET @sql = N'CREATE database ' + @adm_db
	EXEC sp_sqlExec @sql
END

use APBD23_ADM;

/* stworzyc tabele CRDB_LOG 
CREATE TABLE APBD23_ADM.dbo.CRDB_LOG 
(row_id int not null IDENTITY CONSTRAINT PK_CRDB_LOG PRIMARY KEY
, db_nam nvarchar(50) not null
, cr_dt datetime not null default GETDATE()
, err_msg nvarchar(200) NULL -- jak NULL to udalo się 
)
 stworzyc tabele CRUSR_LOG 
CREATE TABLE APBD23_ADM.dbo.CRUSR_LOG 
(row_id int not null IDENTITY CONSTRAINT PK_CRUSR_LOG PRIMARY KEY
, db_nam nvarchar(50) not null
, u_nam nvarchar(50) not null
, cr_dt datetime not null default GETDATE()
, err_msg nvarchar(200) NULL -- jak NULL to udalo się 
)
*/ 

/* stworzyć procedurę jak poniżej 
CREATE procedure tworz_db(@db_name nvarchar(50), @u_name nvarchar(50) )
i za jej pomocą stworzyć 
baze
uzytkownika
przypisac mu bycie wlascicielem bazy
zapisac rekord do LOG-ów (i czy się udało czy nie)
a) sprawdzamy czy baza istnieje i jak TAK to wstawiamy do log opis błedu BAZA JUZ ISTNIEJE
b) sprawdzamy czy user istnieje i jak tak to wstawiamy do log opis błedu

przykładowo ponizsze polecenia tworzą baze pwx_db i uzytkownika pwx_db jako właściciela

	use pwx_db
	EXEC sp_addlogin @loginame='pwx_db',@passwd='pwx_db',@defdb=pwx_db
	EXEC sp_adduser @loginame='pwx_db'
	EXEC sp_addrolemember @rolename = 'db_owner',@membername='pwx_db' 

	chcąc wywołać te polecenia poprzez zapytania w zmiennej trzeba wiedziec ze
	EXEC sp_sqlExec N'use pwx_db'
	to polecenie przejdzie do bazy i wroci tam gdzie bylismy dlatego trzeba to robić tak
	jak ponizej

	DECLARE @db nvarchar(50), @u nvarchar(50), @sql nvarchar(2000)
	SET @db = N'pwx_db'
	SET @u = N'pwx_db'
	SET @sql = 'USE ' + @db 
			+ N';EXEC sp_addlogin @loginame=''' + @u + ''',
			+ ''',@passwd=''' + @u
			+ ''',@defdb=' + @db

	'''' wydrukuje pojedynczy apostrof 
	czyli chcac wykonac polecenie w ramach jakiejs bazy wewnatrz zmiennej łaczymu 'use Baza;polecenie'
	w jeden ciąg. Wtedy SQL przejdzie do tej bazy, wykona polecenie i wróci tam gdzie był

i przetestowac EXEC tworz_db @db_name = N'APBD23_TEST', @usr_name= N'APBD23_TEST'  
i sprawdzić czy uzytkownik i baza powstały oraz jest on właścicielem bazy
*/
GO
CREATE procedure tworz_db(@db_name nvarchar(50), @u_name nvarchar(50))
AS
BEGIN
/* Tworzenie baz danych */
	IF NOT EXISTS (SELECT 1 FROM sys.databases d WHERE d.name = @db_name)
		BEGIN
			DECLARE @sql nvarchar(2000)
			SET @sql = N'CREATE DATABASE ' + @db_name
			EXEC sp_sqlExec @sql
			INSERT INTO APBD23_ADM.dbo.CRDB_LOG (db_nam, cr_dt, err_msg) VALUES (@db_name, SYSDATETIME(), NULL) --udalo sie 
		END
	ELSE
		BEGIN
			INSERT INTO APBD23_ADM.dbo.CRDB_LOG (db_nam, cr_dt, err_msg) VALUES (@db_name, SYSDATETIME(), 'BAZA ISTNIEJE') --nie udalo sie baza istnieje
		END
	IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = @u_name)
		BEGIN
			DECLARE @loginsql nvarchar(2000)
			SET @loginsql = N'USE ' + @db_name + '';
			SET @loginsql = N'EXEC sp_addlogin @loginame ="' + @u_name + '", @passwd = "pass", @defdb = "' + @db_name + '";';
			EXEC sp_sqlExec @loginsql
			SET @loginsql = N'EXEC sp_adduser @loginame = "' + @u_name + '";';
			EXEC sp_sqlExec @loginsql
			SET @loginsql = N'ALTER AUTHORIZATION ON DATABASE:: ' + @db_name + ' TO ' + @u_name + ';';
			EXEC sp_sqlExec @loginsql
			INSERT INTO APBD23_ADM.dbo.CRUSR_LOG (db_nam, u_nam, cr_dt, err_msg) VALUES (@db_name, @u_name, SYSDATETIME(), NULL) --nie udalo sie baza istnieje
		END
	ELSE
		
			INSERT INTO APBD23_ADM.dbo.CRUSR_LOG (db_nam, u_nam, cr_dt, err_msg) VALUES (@db_name, @u_name, SYSDATETIME(), 'USER ISTNIEJE') --nie udalo sie baza istnieje
END
GO


EXEC tworz_db @db_name = 'APB2023_TEST', @u_name = 'APB2023_TEST'
SELECT * FROM sys.server_principals WHERE name = 'APB2023_TEST'
/* Wynik 
name                                                                                                                             principal_id sid                                                                                                                                                                          type type_desc                                                    is_disabled create_date             modify_date             default_database_name                                                                                                            default_language_name                                                                                                            credential_id owning_principal_id is_fixed_role
-------------------------------------------------------------------------------------------------------------------------------- ------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ---- ------------------------------------------------------------ ----------- ----------------------- ----------------------- -------------------------------------------------------------------------------------------------------------------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------- ------------------- -------------
APB2023_TEST                                                                                                                     261          0x49516EB59797924DBC02464DF628A04B                                                                                                                                           S    SQL_LOGIN                                                    0           2023-10-22 15:20:27.333 2023-10-22 15:20:27.347 APB2023_TEST                                                                                                                     us_english                                                                                                                       NULL          NULL                0
*/

SELECT * FROM sys.databases WHERE name = N'APB2023_TEST'
/* Wynik
name                                                                                                                             database_id source_database_id owner_sid                                                                                                                                                                    create_date             compatibility_level collation_name                                                                                                                   user_access user_access_desc                                             is_read_only is_auto_close_on is_auto_shrink_on state state_desc                                                   is_in_standby is_cleanly_shutdown is_supplemental_logging_enabled snapshot_isolation_state snapshot_isolation_state_desc                                is_read_committed_snapshot_on recovery_model recovery_model_desc                                          page_verify_option page_verify_option_desc                                      is_auto_create_stats_on is_auto_create_stats_incremental_on is_auto_update_stats_on is_auto_update_stats_async_on is_ansi_null_default_on is_ansi_nulls_on is_ansi_padding_on is_ansi_warnings_on is_arithabort_on is_concat_null_yields_null_on is_numeric_roundabort_on is_quoted_identifier_on is_recursive_triggers_on is_cursor_close_on_commit_on is_local_cursor_default is_fulltext_enabled is_trustworthy_on is_db_chaining_on is_parameterization_forced is_master_key_encrypted_by_server is_query_store_on is_published is_subscribed is_merge_published is_distributor is_sync_with_backup service_broker_guid                  is_broker_enabled log_reuse_wait log_reuse_wait_desc                                          is_date_correlation_on is_cdc_enabled is_encrypted is_honor_broker_priority_on replica_id                           group_database_id                    resource_pool_id default_language_lcid default_language_name                                                                                                            default_fulltext_language_lcid default_fulltext_language_name                                                                                                   is_nested_triggers_on is_transform_noise_words_on two_digit_year_cutoff containment containment_desc                                             target_recovery_time_in_seconds delayed_durability delayed_durability_desc                                      is_memory_optimized_elevate_to_snapshot_on is_federation_member is_remote_data_archive_enabled is_mixed_page_allocation_on is_temporal_history_retention_enabled catalog_collation_type catalog_collation_type_desc                                  physical_database_name                                                                                                           is_result_set_caching_on is_accelerated_database_recovery_on is_tempdb_spill_to_remote_store is_stale_page_detection_on is_memory_optimized_enabled
-------------------------------------------------------------------------------------------------------------------------------- ----------- ------------------ ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- ----------------------- ------------------- -------------------------------------------------------------------------------------------------------------------------------- ----------- ------------------------------------------------------------ ------------ ---------------- ----------------- ----- ------------------------------------------------------------ ------------- ------------------- ------------------------------- ------------------------ ------------------------------------------------------------ ----------------------------- -------------- ------------------------------------------------------------ ------------------ ------------------------------------------------------------ ----------------------- ----------------------------------- ----------------------- ----------------------------- ----------------------- ---------------- ------------------ ------------------- ---------------- ----------------------------- ------------------------ ----------------------- ------------------------ ---------------------------- ----------------------- ------------------- ----------------- ----------------- -------------------------- --------------------------------- ----------------- ------------ ------------- ------------------ -------------- ------------------- ------------------------------------ ----------------- -------------- ------------------------------------------------------------ ---------------------- -------------- ------------ --------------------------- ------------------------------------ ------------------------------------ ---------------- --------------------- -------------------------------------------------------------------------------------------------------------------------------- ------------------------------ -------------------------------------------------------------------------------------------------------------------------------- --------------------- --------------------------- --------------------- ----------- ------------------------------------------------------------ ------------------------------- ------------------ ------------------------------------------------------------ ------------------------------------------ -------------------- ------------------------------ --------------------------- ------------------------------------- ---------------------- ------------------------------------------------------------ -------------------------------------------------------------------------------------------------------------------------------- ------------------------ ----------------------------------- ------------------------------- -------------------------- ---------------------------
APB2023_TEST                                                                                                                     8           NULL               0x49516EB59797924DBC02464DF628A04B                                                                                                                                           2023-10-22 15:20:27.137 150                 NULL                                                                                                                             0           MULTI_USER                                                   0            1                0                 0     ONLINE                                                       0             1                   0                               0                        OFF                                                          0                             3              SIMPLE                                                       2                  CHECKSUM                                                     1                       0                                   1                       0                             0                       0                0                  0                   0                0                             0                        0                       0                        0                            0                       1                   0                 0                 0                          0                                 0                 0            0             0                  0              0                   7555A865-3174-422B-8AA9-B98C2D3F1E22 1                 0              NOTHING                                                      0                      0              0            0                           NULL                                 NULL                                 NULL             NULL                  NULL                                                                                                                             NULL                           NULL                                                                                                                             NULL                  NULL                        NULL                  0           NONE                                                         NULL                            NULL               NULL                                                         0                                          0                    0                              0                           0                                     0                      DATABASE_DEFAULT                                             NULL                                                                                                                             0                        0                                   0                               0                          1
*/

SELECT owner_sid FROM sys.databases WHERE name = N'APB2023_TEST'
/* Wynik
owner_sid
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
0x49516EB59797924DBC02464DF628A04B
*/

SELECT SUSER_SNAME(0x49516EB59797924DBC02464DF628A04B)
/* Wynik
--------------------------------------------------------------------------------------------------------------------------------
APB2023_TEST
*/




/* stworzyć tabele tymczasową 
CREATE TABLE #u (db_name nvarchar(50) not null, usr_name nvarchar(50) nut null)
i wstawić do niej 50 rekordów (np. za pomochą Excela jak pokazywałem na 1szych zajęciach
czyli generujemy 20 insertów za pomocą Excele
pewne bazy moga sie powtarzac aby udowodniec, ze procedura zapisze ten fakt do LOG-ów

sysusers i sysobjects są dostepne dla kazdej bazy osobno
chcąc sprawdzić czy uzytkownika w bazie istnieje mozna zrobic tak

create table #u (jest bit not null)
set @sql = 'USE ' + @db + ';if exists (select 1 from sysusers u where u.name=''' + @u + ''') insert into #u VALUES(1)'
EXEC sp_sqlExec @sql

i jak jest cos w #u to rejestrujemy w LOG

IF EXISTS (SELECT 1 FROM #u) 
	INSERT INTO jakis_tam_log (kolumny) VALUES (info ze user istnieje)
*/

/* udowodnic ze bazy powstaly, ze są w nich uzytkownicy - zapytaniami
** pokazac logi i uzasadnic ze OK ze sa pewne błedy w nich
*/

CREATE TABLE #u ([db_name] nvarchar(50) not null, usr_name nvarchar(50) not null)

INSERT INTO #u([db_name], [usr_name]) VALUES('aa','zz')
INSERT INTO #u([db_name], [usr_name]) VALUES('bb','yy')
INSERT INTO #u([db_name], [usr_name]) VALUES('cc','xx')
INSERT INTO #u([db_name], [usr_name]) VALUES('dd','ww')
INSERT INTO #u([db_name], [usr_name]) VALUES('ee','vv')
INSERT INTO #u([db_name], [usr_name]) VALUES('ff','uu')
INSERT INTO #u([db_name], [usr_name]) VALUES('gg','tt')
INSERT INTO #u([db_name], [usr_name]) VALUES('hh','ss')
INSERT INTO #u([db_name], [usr_name]) VALUES('ii','rr')
INSERT INTO #u([db_name], [usr_name]) VALUES('jj','qq')
INSERT INTO #u([db_name], [usr_name]) VALUES('kk','pp')
INSERT INTO #u([db_name], [usr_name]) VALUES('ll','oo')
INSERT INTO #u([db_name], [usr_name]) VALUES('mm','nn')
INSERT INTO #u([db_name], [usr_name]) VALUES('nn','mm')
INSERT INTO #u([db_name], [usr_name]) VALUES('oo','ll')
INSERT INTO #u([db_name], [usr_name]) VALUES('pp','kk')
INSERT INTO #u([db_name], [usr_name]) VALUES('qq','jj')
INSERT INTO #u([db_name], [usr_name]) VALUES('rr','ii')
INSERT INTO #u([db_name], [usr_name]) VALUES('ss','hh')
INSERT INTO #u([db_name], [usr_name]) VALUES('tt','gg')
INSERT INTO #u([db_name], [usr_name]) VALUES('tt','aa') --powtorzona baza
INSERT INTO #u([db_name], [usr_name]) VALUES('tt','bb') --powtorzona baza
INSERT INTO #u([db_name], [usr_name]) VALUES('zz','aa') --powtorzony user
INSERT INTO #u([db_name], [usr_name]) VALUES('yy','aa') --powtorzony user




DECLARE @d nvarchar(50), @u nvarchar(50)
DECLARE CI INSENSITIVE CURSOR FOR SELECT u.[db_name], u.usr_name FROM #u u
OPEN CI
FETCH NEXT FROM CI INTO @d, @u
WHILE @@FETCH_STATUS = 0
BEGIN
	EXEC tworz_db @db_name = @d, @u_name= @u
	FETCH NEXT FROM CI INTO @d, @u
END
CLOSE CI
DEALLOCATE CI



SELECT * FROM APBD23_ADM.dbo.CRDB_LOG WHERE err_msg IS NOT NULL
/* Wynik
row_id      db_nam                                             cr_dt                   err_msg
----------- -------------------------------------------------- ----------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
23          tt                                                 2023-10-22 15:45:11.990 BAZA ISTNIEJE
24          tt                                                 2023-10-22 15:45:11.993 BAZA ISTNIEJE
*/

SELECT * FROM APBD23_ADM.dbo.CRDB_LOG WHERE err_msg IS NULL
/* Wynik
row_id      db_nam                                             cr_dt                   err_msg
----------- -------------------------------------------------- ----------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
3           aa                                                 2023-10-22 15:45:08.813 NULL
4           bb                                                 2023-10-22 15:45:09.007 NULL
5           cc                                                 2023-10-22 15:45:09.210 NULL
6           dd                                                 2023-10-22 15:45:09.367 NULL
7           ee                                                 2023-10-22 15:45:09.480 NULL
8           ff                                                 2023-10-22 15:45:09.703 NULL
9           gg                                                 2023-10-22 15:45:09.873 NULL
10          hh                                                 2023-10-22 15:45:10.043 NULL
11          ii                                                 2023-10-22 15:45:10.170 NULL
12          jj                                                 2023-10-22 15:45:10.297 NULL
13          kk                                                 2023-10-22 15:45:10.487 NULL
14          ll                                                 2023-10-22 15:45:10.630 NULL
15          mm                                                 2023-10-22 15:45:10.817 NULL
16          nn                                                 2023-10-22 15:45:11.020 NULL
17          oo                                                 2023-10-22 15:45:11.160 NULL
18          pp                                                 2023-10-22 15:45:11.300 NULL
19          qq                                                 2023-10-22 15:45:11.470 NULL
20          rr                                                 2023-10-22 15:45:11.643 NULL
21          ss                                                 2023-10-22 15:45:11.847 NULL
22          tt                                                 2023-10-22 15:45:11.987 NULL
25          zz                                                 2023-10-22 15:45:12.190 NULL
26          yy                                                 2023-10-22 15:45:12.330 NULL
*/


SELECT * FROM APBD23_ADM.dbo.CRUSR_LOG WHERE err_msg IS NOT NULL
/* Wynik
row_id      db_nam                                             u_nam                                              cr_dt                   err_msg
----------- -------------------------------------------------- -------------------------------------------------- ----------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
25          zz                                                 aa                                                 2023-10-22 15:45:12.190 USER ISTNIEJE
26          yy                                                 aa                                                 2023-10-22 15:45:12.330 USER ISTNIEJE
*/

SELECT * FROM APBD23_ADM.dbo.CRUSR_LOG WHERE err_msg IS NULL
/* Wynik
row_id      db_nam                                             u_nam                                              cr_dt                   err_msg
----------- -------------------------------------------------- -------------------------------------------------- ----------------------- --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
1           APB2023_TEST                                       APB2023_TEST                                       2023-10-22 15:20:27.360 NULL
3           aa                                                 zz                                                 2023-10-22 15:45:08.837 NULL
4           bb                                                 yy                                                 2023-10-22 15:45:09.007 NULL
5           cc                                                 xx                                                 2023-10-22 15:45:09.213 NULL
6           dd                                                 ww                                                 2023-10-22 15:45:09.370 NULL
7           ee                                                 vv                                                 2023-10-22 15:45:09.483 NULL
8           ff                                                 uu                                                 2023-10-22 15:45:09.703 NULL
9           gg                                                 tt                                                 2023-10-22 15:45:09.873 NULL
10          hh                                                 ss                                                 2023-10-22 15:45:10.047 NULL
11          ii                                                 rr                                                 2023-10-22 15:45:10.173 NULL
12          jj                                                 qq                                                 2023-10-22 15:45:10.300 NULL
13          kk                                                 pp                                                 2023-10-22 15:45:10.487 NULL
14          ll                                                 oo                                                 2023-10-22 15:45:10.633 NULL
15          mm                                                 nn                                                 2023-10-22 15:45:10.820 NULL
16          nn                                                 mm                                                 2023-10-22 15:45:11.023 NULL
17          oo                                                 ll                                                 2023-10-22 15:45:11.163 NULL
18          pp                                                 kk                                                 2023-10-22 15:45:11.303 NULL
19          qq                                                 jj                                                 2023-10-22 15:45:11.473 NULL
20          rr                                                 ii                                                 2023-10-22 15:45:11.647 NULL
21          ss                                                 hh                                                 2023-10-22 15:45:11.847 NULL
22          tt                                                 gg                                                 2023-10-22 15:45:11.990 NULL
23          tt                                                 aa                                                 2023-10-22 15:45:11.993 NULL
24          tt                                                 bb                                                 2023-10-22 15:45:11.997 NULL
*/
