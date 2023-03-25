CREATE TABLE dbo.WOJ 
(	kod_woj			nchar(4)			NOT NULL CONSTRAINT PK_WOJ PRIMARY KEY
,	nazwa			nvarchar(50)		NOT NULL
)
GO

CREATE TABLE dbo.MIASTA
(	id_miasta		int					not null IDENTITY CONSTRAINT PK_MIASTA PRIMARY KEY
,	nazwa			nvarchar(50)		NOT NULL 
,	kod_woj			nchar(4)			NOT NULL 
	CONSTRAINT FK_MIASTA_WOJ FOREIGN KEY REFERENCES WOJ(kod_woj)
)
GO

CREATE TABLE dbo.OSOBY
(	id_miasta		int					not null CONSTRAINT FK_OSOBY_MIASTA FOREIGN KEY
		REFERENCES MIASTA(id_miasta)
,	imie			nvarchar(50)		NOT NULL
,	nazwisko		nvarchar(50)		NOT NULL 
,	id_osoby		int					NOT NULL IDENTITY CONSTRAINT PK_OSOBY PRIMARY KEY
)
GO
CREATE TABLE dbo.FIRMY
(	nazwa_skr		nchar(6)			not null CONSTRAINT PK_FIRMY PRIMARY KEY
,	id_miasta		int					NOT NULL CONSTRAINT FK_FIRMY_MIASTA FOREIGN KEY REFERENCES MIASTA(id_miasta)
,	nazwa			nvarchar(50)		NOT NULL
,	kod_pocztowy	nvarchar(6)			NOT NULL
,	ulica			nvarchar(50)		NOT NULL
)
GO
CREATE TABLE dbo.ETATY
(	id_osoby		int					NOT NULL CONSTRAINT FK_OSOBY_ID_OSOBY FOREIGN KEY REFERENCES OSOBY(id_osoby)
,	id_firmy		nchar(6)			NOT NULL CONSTRAINT FK_FIRMY_ID_FIRMY FOREIGN KEY REFERENCES FIRMY(nazwa_skr)
,	stanowisko		nvarchar(50)		NOT NULL 
,	pensja			money				NOT NULL
,	od				datetime			NOT NULL
,	do				datetime			NULL
,	id_etatu		int					not null IDENTITY CONSTRAINT PK_ETATY PRIMARY KEY
)
GO

DECLARE @id_wysz int, @id_bia int, @ID_waw int, @id_rad int, @id_sok int, @id_ost int, @id_sup int , @id_suw int, @id_plo int, @id_kry int, @id_sie int

/*WSTAWIANIE WARTOSCI DO WOJ*/

INSERT INTO WOJ (kod_woj, nazwa) VALUES (N'MAZ', N'MAZOWIECKIE')
INSERT INTO WOJ (kod_woj, nazwa) VALUES (N'POD', N'PODLASKIE')
INSERT INTO WOJ (kod_woj, nazwa) VALUES (N'POM', N'POMORSKIE') /* WOJ bez miast */

/*WSTAWIANIE WARTOSCI DO MIAST*/

INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'MAZ', N'WARSZAWA')
SET @id_waw = SCOPE_IDENTITY() /* id_maz dostaje wartosc z poprzedniego polecenia */
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'MAZ', N'PLOCK')
SET @id_plo = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'MAZ', N'RADOM')
SET @id_rad = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'MAZ', N'SIERPC') /* miasto bez mieszkancow */
SET @id_sie = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'MAZ', N'OSTROLEKA')
SET @id_ost = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'MAZ', N'WYSZKOW')
SET @id_wysz = SCOPE_IDENTITY() 
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'POD', N'BIALYSTOK')
SET @id_bia = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'POD', N'SUWALKI')
SET @id_suw = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'POD', N'SOKOLKA')
SET @id_sok = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'POD', N'KRYNKI')
SET @id_kry = SCOPE_IDENTITY()
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'POD', N'SUPRASL')
SET @id_sup = SCOPE_IDENTITY() 
INSERT INTO MIASTA (kod_woj, nazwa) VALUES (N'POD', N'BIALOWIEZA') /* miasto bez mieszkancow */

/*WSTAWIANIE WARTOSCI DO OSOBY*/

DECLARE @id_jn int, @id_jk int, @id_an int, @id_zl int, @id_kb int, @id_zs int, @id_kk int, @id_am int, @id_lm int, @id_lh int, @id_mv int, @id_dr int, @id_gr int, @id_ln int, @id_rk int
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_wysz, N'JAN', N'NOWAK')
SET @id_jn = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_waw, N'JANUSZ', N'KOWALSKI')
SET @id_jk = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_bia, N'ANNA', N'NOWAK')
SET @id_an = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_waw, N'ZUZANNA', N'LEWANDOWSKA')
SET @id_zl = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_bia, N'KLAUDIA', N'BEC')
SET @id_kb = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_rad, N'ZYGRYD', N'SZCZESNY')
SET @id_zs = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_wysz, N'KLAUDIUSZ', N'KOWALSKI')
SET @id_kk = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_rad, N'ARKADIUSZ', N'MILIK')
SET @id_am = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_sok, N'LEO', N'MESSI')
SET @id_lm = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_sok, N'LEWIS', N'HAMILTON')
SET @id_lh = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_ost, N'MAX', N'VERSTAPPEN')
SET @id_mv = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_kry, N'DANIEL', N'RICCARDO')
SET @id_dr = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_sup, N'GEORGE', N'RUSELL')
SET @id_gr = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_plo, N'LANDO', N'NORRIS')
SET @id_ln = SCOPE_IDENTITY()
INSERT INTO OSOBY ( id_miasta, imie, nazwisko) VALUES (@id_suw, N'ROBERT', N'KUBICA')
SET @id_rk = SCOPE_IDENTITY()

/*WSTAWIANIE WARTOSCI DO FIRMY*/

INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_wysz, N'FIRMA1', N'FIRMA PIERWSZA', N'12345', N'SEZAMKOWA')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_waw, N'FIRMA2', N'FIRMA DRUGA', N'23456', N'KONOPNICKIEJ')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_bia, N'FIRMA3', N'FIRMA TRZECIA', N'34567', N'KOSZYKOWA')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_rad, N'FIRMA4', N'FIRMA CZWARTA', N'45678', N'PLAC POLITECHNIKI')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_sok, N'FIRMA5', N'FIRMA PIATA', N'56789', N'PLAC ZAWISZY')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_ost, N'FIRMA6', N'FIRMA SZOSTA', N'67890', N'ZLOTA')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_kry, N'FIRMA7', N'FIRMA SIODMA', N'78901', N'SIENNA')
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_sie, N'FIRMA8', N'FIRMA OSMA', N'89012', N'WARYNSKIEGO') /*FIRMA GDZIE NIKT NIE MIESZKA*/
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_sie, N'FIRMA9', N'FIRMA DZIEWIATA', N'90123', N'HARCERZY') /*FIRMA GDZIE NIKT NIE MIESZKA*/
INSERT INTO FIRMY ( id_miasta, nazwa_skr, nazwa, kod_pocztowy, ulica) VALUES (@id_suw, N'FIRMA0', N'FIRMA ZERO', N'01234', N'KACZORA')

/*WSTAWIANIE WARTOSCI DO ETATY*/ 

INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_jn, N'FIRMA1', N'PREZES', N'100000', CONVERT(datetime, '20051106', 112)) /*1*/ /*DATETIME W FORMACIE RRRRMMDD*/
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_jk, N'FIRMA1', N'WOZNY', N'3000', CONVERT(datetime, '20201205', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_an, N'FIRMA2', N'DYREKTOR', N'8000', CONVERT(datetime, '20210609', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_zl, N'FIRMA2', N'KSIEGOWY', N'6000', CONVERT(datetime, '20220219', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_kb, N'FIRMA3', N'ROBOTNIK BUDOWLANY', N'4000', CONVERT(datetime, '20160813', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_zs, N'FIRMA3', N'ELEKTRYK', N'4500', CONVERT(datetime, '19990526', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_kk, N'FIRMA4', N'KOSMONAUTA', N'15000', CONVERT(datetime, '20070616', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_am, N'FIRMA4', N'FRYZJER', N'4000', CONVERT(datetime, '20120305', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_lm, N'FIRMA5', N'STRAZAK', N'2000', CONVERT(datetime, '20130608', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_mv, N'FIRMA5', N'INFORMATYK', N'9000', CONVERT(datetime, '20100611', 112))/*10*/
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_dr, N'FIRMA6', N'HELPDESK', N'5000', CONVERT(datetime, '20021220', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_gr, N'FIRMA6', N'FRONTEND DEV', N'10000', CONVERT(datetime, '20190308', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_ln, N'FIRMA7', N'JUNIOR SQL DEV', N'8000', CONVERT(datetime, '20170308', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_rk, N'FIRMA7', N'SCRUM MASTER', N'12000', CONVERT(datetime, '20011123', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_am, N'FIRMA8', N'ANALITYK DANYCH', N'15000', CONVERT(datetime, '20030501', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_rk, N'FIRMA8', N'ZOLNIERZ', N'5000', CONVERT(datetime, '20070402', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_jk, N'FIRMA9', N'KIEROWCA', N'4000', CONVERT(datetime, '20210912', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_an, N'FIRMA9', N'LEKARZ', N'10000', CONVERT(datetime, '20200128', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_kb, N'FIRMA9', N'PREZES', N'50000', CONVERT(datetime, '20210331', 112))
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (@id_mv, N'FIRMA9', N'KIEROWNIK PRODUKCJI', N'7000', CONVERT(datetime, '19910318', 112))/*20*/

/* LINIJKI POWODUJACA BLAD 
INSERT INTO ETATY( id_osoby, id_firmy, stanowisko, pensja, od) VALUES (100, N'FIRMA9', N'KIEROWNIK PRODUKCJI', N'7000', CONVERT(datetime, '19910318', 112))
DROP TABLE WOJ*/
/*WYSWIETLANIE TABEL*/

SELECT * FROM  WOJ
SELECT * FROM MIASTA
SELECT * FROM OSOBY
SELECT * FROM FIRMY
SELECT * FROM ETATY

/* USUWANIE TABEL*/
IF OBJECT_ID(N'ETATY') IS NOT NULL
	DROP TABLE ETATY
GO
IF OBJECT_ID(N'OSOBY') IS NOT NULL
	DROP TABLE OSOBY
GO
IF OBJECT_ID(N'FIRMY') IS NOT NULL
	DROP TABLE FIRMY
GO
IF OBJECT_ID(N'MIASTA') IS NOT NULL
	DROP TABLE MIASTA
GO
IF OBJECT_ID(N'WOJ') IS NOT NULL
	DROP TABLE WOJ
GO
/*

TABELA WOJ

kod_woj nazwa
------- --------------------------------------------------
MAZ     MAZOWIECKIE
POD     PODLASKIE
POM     POMORSKIE

TABELA MIASTA

id_miasta   nazwa                                              kod_woj
----------- -------------------------------------------------- -------
1           WARSZAWA                                           MAZ 
2           PLOCK                                              MAZ 
3           RADOM                                              MAZ 
4           SIERPC                                             MAZ 
5           OSTROLEKA                                          MAZ 
6           WYSZKOW                                            MAZ 
7           BIALYSTOK                                          POD 
8           SUWALKI                                            POD 
9           SOKOLKA                                            POD 
10          KRYNKI                                             POD 
11          SUPRASL                                            POD 
12          BIALOWIEZA                                         POD 

TABELA OSOBY

id_miasta   imie                                               nazwisko                                           id_osoby
----------- -------------------------------------------------- -------------------------------------------------- -----------
6           JAN                                                NOWAK                                              1
1           JANUSZ                                             KOWALSKI                                           2
7           ANNA                                               NOWAK                                              3
1           ZUZANNA                                            LEWANDOWSKA                                        4
7           KLAUDIA                                            BEC                                                5
3           ZYGRYD                                             SZCZESNY                                           6
6           KLAUDIUSZ                                          KOWALSKI                                           7
3           ARKADIUSZ                                          MILIK                                              8
9           LEO                                                MESSI                                              9
9           LEWIS                                              HAMILTON                                           10
5           MAX                                                VERSTAPPEN                                         11
10          DANIEL                                             RICCARDO                                           12
11          GEORGE                                             RUSELL                                             13
2           LANDO                                              NORRIS                                             14
8           ROBERT                                             KUBICA                                             15

TABELA FIRMY

nazwa_skr id_miasta   nazwa                                              kod_pocztowy ulica
--------- ----------- -------------------------------------------------- ------------ --------------------------------------------------
FIRMA0    8           FIRMA ZERO                                         01234        KACZORA
FIRMA1    6           FIRMA PIERWSZA                                     12345        SEZAMKOWA
FIRMA2    1           FIRMA DRUGA                                        23456        KONOPNICKIEJ
FIRMA3    7           FIRMA TRZECIA                                      34567        KOSZYKOWA
FIRMA4    3           FIRMA CZWARTA                                      45678        PLAC POLITECHNIKI
FIRMA5    9           FIRMA PIATA                                        56789        PLAC ZAWISZY
FIRMA6    5           FIRMA SZOSTA                                       67890        ZLOTA
FIRMA7    10          FIRMA SIODMA                                       78901        SIENNA
FIRMA8    4           FIRMA OSMA                                         89012        WARYNSKIEGO
FIRMA9    4           FIRMA DZIEWIATA                                    90123        HARCERZY

TABELA ETATY
id_osoby    id_firmy stanowisko                                         pensja                od                      do                      id_etatu
----------- -------- -------------------------------------------------- --------------------- ----------------------- ----------------------- -----------
1           FIRMA1   PREZES                                             100000,00             2005-11-06 00:00:00.000 NULL                    1
2           FIRMA1   WOZNY                                              3000,00               2020-12-05 00:00:00.000 NULL                    2
3           FIRMA2   DYREKTOR                                           8000,00               2021-06-09 00:00:00.000 NULL                    3
4           FIRMA2   KSIEGOWY                                           6000,00               2022-02-19 00:00:00.000 NULL                    4
5           FIRMA3   ROBOTNIK BUDOWLANY                                 4000,00               2016-08-13 00:00:00.000 NULL                    5
6           FIRMA3   ELEKTRYK                                           4500,00               1999-05-26 00:00:00.000 NULL                    6
7           FIRMA4   KOSMONAUTA                                         15000,00              2007-06-16 00:00:00.000 NULL                    7
8           FIRMA4   FRYZJER                                            4000,00               2012-03-05 00:00:00.000 NULL                    8
9           FIRMA5   STRAZAK                                            2000,00               2013-06-08 00:00:00.000 NULL                    9
11          FIRMA5   INFORMATYK                                         9000,00               2010-06-11 00:00:00.000 NULL                    10
12          FIRMA6   HELPDESK                                           5000,00               2002-12-20 00:00:00.000 NULL                    11
13          FIRMA6   FRONTEND DEV                                       10000,00              2019-03-08 00:00:00.000 NULL                    12
14          FIRMA7   JUNIOR SQL DEV                                     8000,00               2017-03-08 00:00:00.000 NULL                    13
15          FIRMA7   SCRUM MASTER                                       12000,00              2001-11-23 00:00:00.000 NULL                    14
8           FIRMA8   ANALITYK DANYCH                                    15000,00              2003-05-01 00:00:00.000 NULL                    15
15          FIRMA8   ZOLNIERZ                                           5000,00               2007-04-02 00:00:00.000 NULL                    16
2           FIRMA9   KIEROWCA                                           4000,00               2021-09-12 00:00:00.000 NULL                    17
3           FIRMA9   LEKARZ                                             10000,00              2020-01-28 00:00:00.000 NULL                    18
5           FIRMA9   PREZES                                             50000,00              2021-03-31 00:00:00.000 NULL                    19
11          FIRMA9   KIEROWNIK PRODUKCJI                                7000,00               1991-03-18 00:00:00.000 NULL                    20

*/
/* 
KOMUNIKATY O BLEDACH

Msg 3726, Level 16, State 1, Line 114
Could not drop object 'WOJ' because it is referenced by a FOREIGN KEY constraint.

Msg 547, Level 16, State 0, Line 105
The INSERT statement conflicted with the FOREIGN KEY constraint "FK_OSOBY_ID_OSOBY". The conflict occurred in database "b_319093", table "dbo.OSOBY", column 'id_osoby'.
The statement has been terminated.
*/