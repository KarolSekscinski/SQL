/*Z6 Karol Sekœciñski GR4 319093 */


/*
** 3 regu³y tworzenia TRIGGERA
** R1 - Trigger nie mo¿e aktualizowaæ CALEJ tabeli a co najwy¿ej elementy zmienione
** R2 - Trigger mo¿e wywo³aæ sam siebie - uzysamy niesoñczon¹ rekurencjê == stack overflow
** R3 - Zawsze zakladamy, ¿e wstawiono / zmodyfikowano / skasowano wiecej jak 1 rekord
**
** Z1: do tabeli FIRMY dodaæ kolumne NIP i NIP_BK (oba nvarchar(20) NULL)
*/

IF NOT EXISTS 
( SELECT c.[name] AS nazwa_kol 
	FROM sysobjects o 
	join syscolumns c ON (c.[id] = o.[id])
	WHERE	(o.[name] = N'firmy')
	AND		(c.[name] = N'NIP')
)
BEGIN
	ALTER TABLE FIRMY ADD NIP NVARCHAR(20) NULL 
END
GO
/*
Command(s) completed successfully.
*/
IF NOT EXISTS 
( SELECT c.[name] AS nazwa_kol 
	FROM sysobjects o 
	join syscolumns c ON (c.[id] = o.[id])
	WHERE	(o.[name] = N'firmy')
	AND		(c.[name] = N'NIP_BK')
)
BEGIN
	ALTER TABLE FIRMY ADD NIP_BK NVARCHAR(20) NULL 
END
GO
/*
Command(s) completed successfully.
*/

SELECT * FROM FIRMY
/*
nazwa_skr id_miasta   nazwa                                              kod_pocztowy ulica                                              NIP                  NIP_BK
--------- ----------- -------------------------------------------------- ------------ -------------------------------------------------- -------------------- --------------------
FIRMA0    8           FIRMA ZERO                                         01234        KACZORA                                            NULL                 NULL
FIRMA1    6           BALFA                                              12345        SEZAMKOWA                                          NULL                 NULL
FIRMA2    1           ABETA                                              23456        KONOPNICKIEJ                                       NULL                 NULL
FIRMA3    7           GAMMA                                              34567        KOSZYKOWA                                          NULL                 NULL
FIRMA4    3           ZETA                                               45678        PLAC POLITECHNIKI                                  NULL                 NULL
FIRMA5    9           BETAF                                              56789        PLAC ZAWISZY                                       NULL                 NULL
FIRMA6    5           FIRMA SZOSTA                                       67890        ZLOTA                                              NULL                 NULL
FIRMA7    10          FIRMA SIODMAA                                      78901        SIENNA                                             NULL                 NULL
FIRMA8    4           FIRMA OSMA                                         89012        WARYNSKIEGO                                        NULL                 NULL
FIRMA9    4           BETAK                                              90123        HARCERZY                                           NULL                 NULL

(10 row(s) affected)
*/

/*
** Napisaæ trigger, który bêdzie przepisywa³ zawartoœæ pola NIP do pola NIP_BK
** Trigger na INSERT, UPDATE (w polu NIP_BK przepisujemy NIP z pominiêciem - oraz SPACJI)
** UWAGA !! Trigger bêdzie robi³ UPDATE na polu NIP_BK
** To grozi REKURENCJ¥ i przepelnieniem stosu
** Dlatego trzeba bêdzie sprawdzaæ UPDATE(NIP) i sprawdzaæ czy we
** wstawionych rekordach by³y spacje/kreski i tylko takowe poprawiaæ
*/

GO
CREATE TRIGGER dbo.TR_przepisywanie_nipu ON FIRMY FOR INSERT, UPDATE
AS
	IF UPDATE(NIP)
	AND EXISTS (SELECT 1 FROM INSERTED AS I WHERE I.NIP_BK LIKE N'%-%-%-%')
		UPDATE FIRMY SET NIP_BK = REPLACE(NIP, N'-', N'')
		WHERE nazwa_skr IN 
			(SELECT Iw.nazwa_skr 
			FROM INSERTED AS Iw 
			WHERE Iw.NIP LIKE N'%-%-%-%')
GO

/*

Command(s) completed successfully.

*/
UPDATE FIRMY SET NIP = N'228-155-34-12' WHERE nazwa_skr = N'FIRMA0'
UPDATE FIRMY SET NIP = N'120-255-84-63' WHERE nazwa_skr = N'FIRMA1'
UPDATE FIRMY SET NIP = N'213-091-74-07' WHERE nazwa_skr = N'FIRMA2'

/*

(1 row(s) affected)

(1 row(s) affected)

(1 row(s) affected)

*/

SELECT * FROM FIRMY WHERE FIRMY.NIP is NOT NULL
/*

nazwa_skr id_miasta   nazwa                                              kod_pocztowy ulica                                              NIP                  NIP_BK
--------- ----------- -------------------------------------------------- ------------ -------------------------------------------------- -------------------- --------------------
FIRMA0    8           FIRMA ZERO                                         01234        KACZORA                                            228-155-34-12        NULL
FIRMA1    6           BALFA                                              12345        SEZAMKOWA                                          120-255-84-63        NULL
FIRMA2    1           ABETA                                              23456        KONOPNICKIEJ                                       213-091-74-07        NULL

(3 row(s) affected)

*/

/*
** Z2: Napisaæ procedurê szukaj¹c¹ firm z paramertrami
** @nazwa_wzor nvarchar(20) = NULL
** @nazwa_skr_wzor nvarchar(20) = NULL
** @pokaz_zarobki bit = 0
** Procedura ma mieæ zmienn¹ @sql nvarchar(1000), któr¹ buduje dynamicznie
** @pokaz_zarobki = 0 => (nazwa_skr, nazwa, nazwa_miasta)
** @pokaz_zarobki = 1 => (nazwa_skr, nazwa, srednia_z_akt_etatow)
** Mozliwe wywo³ania: EXEC sz_f @nazwa_wzor = N'%Polit%'
** powinno zbudowaæ zmienn¹ tekstow¹
** @sql = N'SELECT f.*, m.nazwa AS nazwa_miasta FROM firmy o join miasta m "
** + N' ON (m.id_miasta=f.id_miasta) WHERE f.nazwa LIKE N''%POLIT%'' '
** uruchomienie zapytania to EXEC sp_sqlExec @sql
** rekomendujê aby najpierw procedura zwraca³a zapytanie SELECT @sql
** a dopiero jak bêd¹ poprawne uruachamia³a je
 @sql = N'SELECT f.*, m.nazwa AS nazwa_miasta FROM firmy o join miasta m "
** + N' ON (m.id_miasta=f.id_miasta) WHERE f.nazwa LIKE N''%POLIT%'' '
** uruchomienie zapytania to EXEC sp_sqlExec @sql
*/


GO
CREATE PROCEDURE dbo.procedura (@nazwa_wzor nvarchar(20) = NULL, @nazwa_skr_wzor nvarchar(20) = NULL, @pokaz_zarobki bit = 0)
AS
	DECLARE @sql nvarchar(1000)

	IF @pokaz_zarobki = 0
		SET @sql = N'SELECT F.nazwa_skr,F.nazwa, M.nazwa AS nazwa_miasta FROM FIRMY AS F JOIN MIASTA AS M ON M.id_miasta = F.id_miasta'
	ELSE
		SET @sql = N'SELECT F.nazwa_skr,F.nazwa, AVG(E.pensja) AS srednie_zarobki FROM FIRMY AS F JOIN MIASTA AS M ON M.id_miasta = F.id_miasta JOIN ETATY AS E ON E.id_firmy = F.nazwa_skr'

	IF @nazwa_wzor IS NOT NULL OR @nazwa_skr_wzor IS NOT NULL
		SET @sql = @sql + N' WHERE '

	IF @nazwa_wzor IS NOT NULL
		SET @sql = @sql + N'F.nazwa LIKE N''' + @nazwa_wzor + N''' '

	IF @nazwa_wzor IS NOT NULL AND @nazwa_skr_wzor IS NOT NULL
		SET @sql = @sql + N'AND'

	IF @nazwa_skr_wzor IS NOT NULL
		SET @sql = @sql + N' F.nazwa_skr LIKE N''' + @nazwa_skr_wzor + N''' '

	IF @pokaz_zarobki = 1
		SET @sql = @sql + N' GROUP BY F.nazwa_skr,F.nazwa, M.nazwa'

	EXEC sp_sqlExec @sql
GO
/*
Commands completed successfully.
*/
EXEC procedura
/*
nazwa_skr nazwa                                              nazwa_miasta
--------- -------------------------------------------------- --------------------------------------------------
FIRMA0    FIRMA ZERO                                         SUWALKI
FIRMA1    BALFA                                              WYSZKOW
FIRMA2    ABETA                                              WARSZAWA
FIRMA3    GAMMA                                              BIALYSTOK
FIRMA4    ZETA                                               RADOM
FIRMA5    BETAF                                              SOKOLKA
FIRMA6    FIRMA SZOSTA                                       OSTROLEKA
FIRMA7    FIRMA SIODMAA                                      KRYNKI
FIRMA8    FIRMA OSMA                                         SIERPC
FIRMA9    BETAK                                              SIERPC

(10 row(s) affected)
*/
EXEC procedura @nazwa_wzor = N'ZET%'
/*
nazwa_skr nazwa                                              nazwa_miasta
--------- -------------------------------------------------- --------------------------------------------------
FIRMA4    ZETA                                               RADOM

(1 row(s) affected)
*/
EXEC procedura @pokaz_zarobki = 1

/*
nazwa_skr nazwa                                              srednie_zarobki
--------- -------------------------------------------------- ---------------------
FIRMA1    BALFA                                              3600,00
FIRMA2    ABETA                                              6000,00
FIRMA3    GAMMA                                              4250,00
FIRMA4    ZETA                                               9500,00
FIRMA5    BETAF                                              5500,00
FIRMA6    FIRMA SZOSTA                                       7500,00
FIRMA7    FIRMA SIODMAA                                      10000,00
FIRMA8    FIRMA OSMA                                         10000,00
FIRMA9    BETAK                                              6125,00

(9 row(s) affected)
*/


