/*Z7 Karol Sekœciñski GR4 319093 */

/* Projekt na 3 zajêcia /
/ stworzyæ bibliotekê (uproszczon¹)
**
** Tabela Ksiazka (tytul, autor, id_ksiazki, stan_bibl, stan_dostepny - dom stan_bibl)
** Skorzystaæ z tabeli OSOBY któr¹ macie
** Tabela WYP (id_osoby, id_ksiazki, liczba, data, id_wyp PK)
** Tabela ZWR (id_osoby, id_ksiazki, liczba, data, id_zwr PK (int not null IDENTITY))
*/
DROP TABLE dbo.WYP
DROP TABLE dbo.ZWR
DROP TABLE dbo.SKASOWANE
DROP TABLE dbo.KSIAZKA


CREATE TABLE dbo.KSIAZKA
(	tytul			nvarchar(100)	not null
,	autor			nvarchar(100)	not null
,	id_ksiazki		int				not null IDENTITY CONSTRAINT PK_KSIAZKA PRIMARY KEY
,	stan_bibl		int				not null
,	stan_dostepny	int			
)

CREATE TABLE dbo.WYP
(	id_osoby		int				not null CONSTRAINT FK_WYP_OSOBY FOREIGN KEY REFERENCES dbo.OSOBY(id_osoby)
,	id_ksiazki		int				not null CONSTRAINT FK_WYP_KSIAZKA FOREIGN KEY REFERENCES dbo.KSIAZKA(id_ksiazki)
,	liczba			int				not null
,	data			datetime		not null
,	id_wyp			int				not null IDENTITY CONSTRAINT PK_WYP PRIMARY KEY
)

CREATE TABLE dbo.ZWR
(	id_osoby		int				not null CONSTRAINT FK_ZWR_OSOBY FOREIGN KEY REFERENCES dbo.OSOBY(id_osoby)
,	id_ksiazki		int				not null CONSTRAINT FK_ZWR_KSIAZKA FOREIGN KEY REFERENCES dbo.KSIAZKA(id_ksiazki)
,	liczba			int				not null
,	data			datetime		not null
,	id_zwr			int				not null IDENTITY CONSTRAINT PK_ZWR PRIMARY KEY
)

CREATE TABLE dbo.SKASOWANE
(	rodzaj			nvarchar(4)		not null 
,	id_osoby		int				not null CONSTRAINT FK_SKASOWANE_OSOBY FOREIGN KEY REFERENCES dbo.OSOBY(id_osoby)
,	id_ksiazki		int				not null CONSTRAINT FK_SKASOWANE_KSIAZKA FOREIGN KEY REFERENCES dbo.KSIAZKA(id_ksiazki)
,	liczba			int				not null
)
/*
** Napisaæ triggery aby:
** dodanie rekordow do WYP powodowalo aktualizacjê Ksiazka (stan_dostepny)
** UWAGA zakladamy ze na raz mozna dodawac wiele rekordow
** w tym dla tej samej osoby, z tym samym id_ksiazki
/
CREATE TABLE #wyp(id_os int not null, id_ks int not null, liczba int not null)
INSERT INTO #wyp (id_os, id_ks, liczba) VALUES (1, 1, 1), (1, 1, 2), (2, 5, 6)
/
Zwrot zwiêksza stan_dostepny
** UWAGA
** Zrealizowaæ TRIGERY na kasowanie z WYP lub ZWR
**
** Zrealizowaæ triggery, ze nastapi³a pomy³ka czyli UPDATE na WYP lub ZWR
** Wydaje mi sie, ze mozna napisac po jednym triggerze na WYP lub ZWR na
** wszystkie akcje INSERT / UPDATE / DELETE
**
*/



GO
CREATE TRIGGER dbo.KSIAZKA_ON_INSERT on KSIAZKA FOR INSERT
AS
	IF UPDATE(stan_bibl)
	and exists (SELECT 1 FROM inserted i)
		UPDATE KSIAZKA SET stan_dostepny = stan_bibl
		WHERE id_ksiazki IN 
		(SELECT i.id_ksiazki FROM inserted i)



GO
CREATE TRIGGER dbo.WYP_ON_INSERT ON WYP FOR INSERT
AS
	IF UPDATE(id_ksiazki)
	and exists (SELECT 1 FROM inserted i)
	BEGIN
		DECLARE @ilosc		int
		DECLARE @id			int
		DECLARE WYP_cursor	cursor for
			SELECT id_ksiazki, liczba FROM inserted
		OPEN WYP_cursor
		FETCH NEXT FROM WYP_cursor INTO @id, @ilosc
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE KSIAZKA SET stan_dostepny = stan_dostepny - @ilosc
			WHERE id_ksiazki = @id
			FETCH NEXT FROM WYP_cursor INTO @id, @ilosc
		END

		CLOSE WYP_cursor
		DEALLOCATE WYP_cursor
	END


GO
CREATE TRIGGER dbo.WYP_ON_UPDATE ON WYP FOR UPDATE
AS
	IF exists (SELECT 1 FROM inserted i)
	BEGIN
		DECLARE @ilosc_przed		int
		DECLARE @ilosc_po			int
		DECLARE @id_przed			int
		DECLARE @id_po				int

		DECLARE WYP_cursor CURSOR FOR 
			SELECT i.id_ksiazki, d.id_ksiazki, d.liczba, i.liczba
			FROM inserted i
			join deleted d ON (i.id_wyp = d.id_wyp)
		OPEN WYP_cursor

		FETCH NEXT FROM WYP_cursor INTO @id_po, @id_przed, @ilosc_przed, @ilosc_po
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE KSIAZKA SET stan_dostepny = stan_dostepny + @ilosc_przed
			WHERE id_ksiazki = @id_przed
			UPDATE KSIAZKA SET stan_dostepny = stan_dostepny - @ilosc_po
			WHERE id_ksiazki = @id_po
			FETCH NEXT FROM WYP_cursor INTO @id_po, @id_przed, @ilosc_przed, @ilosc_po
		END

		CLOSE WYP_cursor
		DEALLOCATE WYP_cursor
	END


GO
CREATE TRIGGER dbo.WYP_ON_DELETE ON WYP FOR DELETE
AS
	IF exists (SELECT 1 FROM deleted d)
	BEGIN
		DECLARE @id_osoby			int
		DECLARE @id_ksiazki			int
		DECLARE @ilosc				int

		DECLARE WYP_cursor CURSOR FOR
		SELECT d.id_osoby, d.id_ksiazki, d.liczba
		FROM deleted d

		OPEN WYP_cursor

		FETCH NEXT FROM WYP_cursor INTO @id_osoby, @id_ksiazki, @ilosc
		WHILE @@FETCH_STATUS = 0
		BEGIN
			INSERT INTO dbo.SKASOWANE (rodzaj, id_osoby, id_ksiazki, liczba) VALUES (N'WYP', @id_osoby, @id_ksiazki, @ilosc)
			UPDATE dbo.KSIAZKA SET stan_dostepny = stan_dostepny + @ilosc
			WHERE id_ksiazki = @id_ksiazki
			FETCH NEXT FROM WYP_cursor INTO @id_osoby, @id_ksiazki, @ilosc
		END

		CLOSE WYP_cursor
		DEALLOCATE WYP_cursor
	END

GO
CREATE TRIGGER dbo.ZWR_ON_INSERT ON ZWR FOR INSERT
AS
	IF UPDATE(id_ksiazki)
	and exists (SELECT 1 FROM inserted i)
	BEGIN
		DECLARE @id				int
		DECLARE @ilosc			int

		DECLARE ZWR_cursor CURSOR FOR
			SELECT id_ksiazki, liczba FROM inserted 
		OPEN ZWR_cursor

		FETCH NEXT FROM ZWR_cursor INTO @id, @ilosc
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE KSIAZKA SET stan_dostepny = stan_dostepny + @ilosc
			WHERE id_ksiazki = @id
			FETCH NEXT FROM ZWR_cursor INTO @id, @ilosc
		END

		CLOSE ZWR_cursor
		DEALLOCATE ZWR_cursor
	END

GO
CREATE TRIGGER dbo.ZWR_ON_UPDATE ON ZWR FOR UPDATE
AS
	IF exists (SELECT 1 FROM inserted i)
	BEGIN
		DECLARE @ilosc_przed			int
		DECLARE @ilosc_po				int
		DECLARE @id_przed				int
		DECLARE @id_po					int

		DECLARE ZWR_cursor cursor FOR
			SELECT i.id_ksiazki, d.id_ksiazki, d.liczba, i.liczba
			FROM inserted i
			join deleted d ON (d.id_zwr = i.id_zwr)
		OPEN ZWR_cursor

		FETCH NEXT FROM ZWR_cursor INTO @id_po, @id_przed, @ilosc_przed, @ilosc_po
		WHILE @@FETCH_STATUS = 0
		BEGIN
			UPDATE KSIAZKA SET stan_dostepny = stan_dostepny - @ilosc_przed
			WHERE id_ksiazki = @id_przed
			UPDATE KSIAZKA SET stan_dostepny = stan_dostepny + @ilosc_po
			WHERE id_ksiazki = @id_po 
			FETCH NEXT FROM ZWR_cursor INTO @id_po, @id_przed, @ilosc_przed, @ilosc_po
		END
		
		CLOSE ZWR_cursor
		DEALLOCATE ZWR_cursor
	END


GO
CREATE TRIGGER dbo.ZWR_ON_DELETE ON ZWR FOR DELETE
AS
	IF exists (SELECT 1 FROM deleted d)

	DECLARE @id_osoby			int
	DECLARE @id_ksiazki			int
	DECLARE @ilosc				int

	DECLARE ZWR_cursor CURSOR FOR
		SELECT d.id_osoby, d.id_ksiazki, d.liczba FROM deleted d

	OPEN ZWR_cursor

	FETCH NEXT FROM ZWR_cursor INTO @id_osoby, @id_ksiazki, @ilosc
	WHILE @@FETCH_STATUS = 0
	BEGIN
		INSERT INTO dbo.SKASOWANE ( rodzaj, id_osoby, id_ksiazki, liczba) VALUES (N'ZWR', @id_osoby, @id_ksiazki, @ilosc)
		UPDATE dbo.KSIAZKA SET stan_dostepny = stan_dostepny - @ilosc
		WHERE id_ksiazki = @id_ksiazki
		FETCH NEXT FROM ZWR_cursor INTO @id_osoby, @id_ksiazki, @ilosc
	END

	CLOSE ZWR_cursor
	DEALLOCATE ZWR_cursor

GO
/*
** Testowanie: stworzcie procedurê, która pokaze wszystkie ksi¹zki,
** dane ksi¹zki, stan_bibl, stan_dost + SUM(liczba) z ZWR - SUM(liczba) z WYP =>
** ISNULL(SUM(Liczba),0)
** te dwie kolumny powiny byæ równe
** po wielu dzialaniach w bazie
** dzialania typu kasowanie rejestrowac w tabeli skasowane
** (rodzaj (wyp/zwr), id_os, id_ks, liczba)
** osobne triggery na DELETE z WYP i ZWR które bêd¹ rejestrowaæ skasowania
** opisaæ pe³n¹ historie wyp i zwr (³aczniem z kasowaniem) i ze po wszystkim stan OK
*/

CREATE PROCEDURE dbo.POKAZ_KSIAZKI
AS
	SELECT k.id_ksiazki, k.tytul AS tytul, k.stan_dostepny AS stan_dostepny, k.stan_bibl + ISNULL(z.suma_zwr, 0) - ISNULL(w.suma_wyp, 0) AS BILANS
	FROM KSIAZKA k
	left outer join (SELECT w.id_ksiazki, ISNULL(SUM(w.liczba), 0) suma_wyp FROM WYP w GROUP BY w.id_ksiazki) w ON w.id_ksiazki = k.id_ksiazki
	left outer join (SELECT z.id_ksiazki, ISNULL(SUM(z.liczba), 0) suma_zwr FROM ZWR z GROUP BY z.id_ksiazki) z ON z.id_ksiazki = k.id_ksiazki
	GROUP BY k.id_ksiazki, z.suma_zwr, w.suma_wyp, k.tytul, k.stan_bibl, k.stan_dostepny


GO
CREATE PROCEDURE dbo.POKAZ_KSIAZKI_2
AS
	SELECT k.id_ksiazki, k.tytul AS tytul, k.stan_bibl AS stan_bibl, k.stan_dostepny - ISNULL(z.suma_zwr, 0) + ISNULL(w.suma_wyp, 0) AS BILANS
	FROM KSIAZKA k
	left outer join (SELECT w.id_ksiazki, ISNULL(SUM(w.liczba), 0) AS suma_wyp FROM WYP w GROUP BY w.id_ksiazki) w ON w.id_ksiazki = k.id_ksiazki
	left outer join (SELECT z.id_ksiazki, ISNULL(SUM(z.liczba), 0) AS suma_zwr FROM ZWR z GROUP BY z.id_ksiazki) z ON z.id_ksiazki = k.id_ksiazki
	GROUP BY k.id_ksiazki, z.suma_zwr, w.suma_wyp, k.tytul, k.stan_bibl, k.stan_dostepny


/*
** Testowanie: stworzcie procedurê, która pokaze wszystkie ksi¹zki,
** dane ksi¹zki, stan_bibl, stan_dost + SUM(liczba) z ZWR - SUM(liczba) z WYP =>
** ISNULL(SUM(Liczba),0)
** te dwie kolumny powiny byæ równe
** po wielu dzialaniach w bazie
** dzialania typu kasowanie rejestrowac w tabeli skasowane
** (rodzaj (wyp/zwr), id_os, id_ks, liczba)
** osobne triggery na DELETE z WYP i ZWR które bêd¹ rejestrowaæ skasowania
** opisaæ pe³n¹ historie wyp i zwr (³aczniem z kasowaniem) i ze po wszystkim stan OK
*/
INSERT INTO dbo.KSIAZKA (tytul, autor, stan_bibl) VALUES (N'Mechaniczna pomarancza', N' Anthony Burgess', 30),
														 (N'Bracia Karamazow', N'Fiodor Dostojewski', 25),
														 (N'Wielki Gatsby', N'F.Scott Fitzgerald', 15),
														 (N'Wilk stepowy', N'Herman Hesse', 20),
														 (N'Dzuma',N'Albert Camus', 35)
SELECT * FROM KSIAZKA
/*
tytul                                                                                                autor                                                                                                id_ksiazki  stan_bibl   stan_dostepny
---------------------------------------------------------------------------------------------------- ---------------------------------------------------------------------------------------------------- ----------- ----------- -------------
Mechaniczna pomarancza                                                                                Anthony Burgess                                                                                     1           30          30
Bracia Karamazow                                                                                     Fiodor Dostojewski                                                                                   2           25          25
Wielki Gatsby                                                                                        F.Scott Fitzgerald                                                                                   3           15          15
Wilk stepowy                                                                                         Herman Hesse                                                                                         4           20          20
Dzuma                                                                                                Albert Camus                                                                                         5           35          35

(5 row(s) affected)

*/

INSERT INTO dbo.WYP (id_ksiazki, id_osoby, liczba, data) VALUES (1, 1, 5, GETDATE()), (2, 1, 3, GETDATE()), (3, 1, 4, GETDATE()),
															    (4, 5, 1, GETDATE()), (5, 1, 1, GETDATE())


SELECT * FROM WYP
/*
id_osoby    id_ksiazki  liczba      data                    id_wyp
----------- ----------- ----------- ----------------------- -----------
1           1           5           2022-05-29 13:04:28.027 1
1           2           3           2022-05-29 13:04:28.027 2
1           3           4           2022-05-29 13:04:28.027 3
5           4           1           2022-05-29 13:04:28.027 4
1           5           1           2022-05-29 13:04:28.027 5

(5 row(s) affected)
*/
INSERT INTO dbo.ZWR (id_ksiazki, id_osoby, liczba, data) VALUES (1, 2, 1, GETDATE()), (2, 3, 1, GETDATE()), (3, 4, 2, GETDATE()),
																(4, 5, 1, GETDATE()), (5, 1, 1, GETDATE())

SELECT * FROM ZWR

/*
id_osoby    id_ksiazki  liczba      data                    id_zwr
----------- ----------- ----------- ----------------------- -----------
2           1           1           2022-05-29 13:04:42.540 1
3           2           1           2022-05-29 13:04:42.540 2
4           3           2           2022-05-29 13:04:42.540 3
5           4           1           2022-05-29 13:04:42.540 4
1           5           1           2022-05-29 13:04:42.540 5

(5 row(s) affected)
*/


UPDATE dbo.WYP SET liczba = 4 WHERE id_wyp = 1
UPDATE dbo.ZWR SET liczba = 2 WHERE id_zwr = 1
UPDATE dbo.WYP SET id_ksiazki = 2 WHERE id_wyp = 4
UPDATE dbo.ZWR SET id_ksiazki = 2 WHERE id_zwr = 4

DELETE FROM dbo.WYP WHERE id_wyp = 5
DELETE FROM dbo.ZWR WHERE id_zwr = 5




SELECT * FROM WYP
/*
id_osoby    id_ksiazki  liczba      data                    id_wyp
----------- ----------- ----------- ----------------------- -----------
1           1           4           2022-05-29 13:04:28.027 1
1           2           3           2022-05-29 13:04:28.027 2
1           3           4           2022-05-29 13:04:28.027 3
5           2           1           2022-05-29 13:04:28.027 4

(4 row(s) affected)
*/
SELECT * FROM ZWR
/*
id_osoby    id_ksiazki  liczba      data                    id_zwr
----------- ----------- ----------- ----------------------- -----------
2           1           2           2022-05-29 13:04:42.540 1
3           2           1           2022-05-29 13:04:42.540 2
4           3           2           2022-05-29 13:04:42.540 3
5           2           1           2022-05-29 13:04:42.540 4

(4 row(s) affected)
*/
SELECT * FROM SKASOWANE
/*
rodzaj id_osoby    id_ksiazki  liczba
------ ----------- ----------- -----------
WYP    1           5           1
ZWR    1           5           1

(2 row(s) affected)
*/
EXEC dbo.POKAZ_KSIAZKI
/*
id_ksiazki  tytul                                                                                                stan_dostepny BILANS
----------- ---------------------------------------------------------------------------------------------------- ------------- -----------
1           Mechaniczna pomarancza                                                                               28            28
2           Bracia Karamazow                                                                                     23            23
3           Wielki Gatsby                                                                                        13            13
4           Wilk stepowy                                                                                         20            20
5           Dzuma                                                                                                35            35

(5 row(s) affected)
*/
EXEC dbo.POKAZ_KSIAZKI_2
/*
id_ksiazki  tytul                                                                                                stan_bibl   BILANS
----------- ---------------------------------------------------------------------------------------------------- ----------- -----------
1           Mechaniczna pomarancza                                                                               30          30
2           Bracia Karamazow                                                                                     25          25
3           Wielki Gatsby                                                                                        15          15
4           Wilk stepowy                                                                                         20          20
5           Dzuma                                                                                                35          35

(5 row(s) affected)
*/

/* Brak roznic przy stanie_bibl i stanie_dostepnym wzgledem balansu pokazuje nam ze nasza biblioteka dziala tak jak powinna */