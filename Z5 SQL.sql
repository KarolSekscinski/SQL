/*Z5 Karol Sekœciñski GR4 319093 */


/*
Z5.1 - Pokazaæ miasta wraz ze œredni¹ aktualna
pensj¹ w nich z firm tam siê mieszcz¹cych
U¿ywaj¹c UNION, rozwa¿yæ opcjê ALL
jak nie ma etatów to 0 pokazujemy
(czyli musimy obs³u¿yæ miasta bez etatów AKT firm)
*/
SELECT m.id_miasta, m.nazwa, X.suma_zarobkow AS [srednia zarobkow]
	FROM MIASTA m
	join (SELECT mW.id_miasta, AVG(ew.pensja) AS suma_zarobkow 
			FROM etaty eW
			join FIRMY f ON (eW.id_firmy = f.nazwa_skr)
			join MIASTA mW ON (mW.id_miasta = f.id_miasta)
			WHERE eW.DO IS NULL
			GROUP BY mW.id_miasta
		) X ON (X.id_miasta = m.id_miasta)
	
UNION ALL
SELECT m.id_miasta, m.nazwa, CONVERT(money, 0) AS XX
	FROM MIASTA m 
	WHERE NOT EXISTS (SELECT 1 FROM etaty eW 
	join FIRMY f ON (eW.id_firmy = f.nazwa_skr)
	join MIASTA mW ON (mW.id_miasta = f.id_miasta)
	WHERE mW.id_miasta = m.id_miasta AND eW.do is null)
	ORDER BY 1, 2
	

/*
id_miasta   nazwa                                              srednia zarobkow
----------- -------------------------------------------------- ---------------------
1           WARSZAWA                                           6000,00
2           PLOCK                                              0,00
3           RADOM                                              9500,00
4           SIERPC                                             7416,6666
5           OSTROLEKA                                          7500,00
6           WYSZKOW                                            3600,00
7           BIALYSTOK                                          4250,00
8           SUWALKI                                            0,00
9           SOKOLKA                                            5500,00
10          KRYNKI                                             10000,00
11          SUPRASL                                            0,00
12          BIALOWIEZA                                         0,00

(12 row(s) affected)
*/

/*
Z5.2 - to samo co w Z5.1
Ale z wykorzystaniem LEFT OUTER
pokazuje kazdy osobe oddzielnie

musi chyba pokazywac kazda osobe oddzielnie
*/

SELECT m.id_miasta, m.nazwa, ISNULL(X.suma_zarobkow, 0) AS [srednia zarobkow]
	FROM MIASTA m
	left outer
	join (SELECT mW.id_miasta, AVG(ew.pensja) AS suma_zarobkow 
			FROM etaty eW
			join FIRMY f ON (eW.id_firmy = f.nazwa_skr)
			join MIASTA mW ON (mW.id_miasta = f.id_miasta)
			WHERE EW.DO IS NULL
			GROUP BY mW.id_miasta
		) X ON (X.id_miasta = m.id_miasta)
	
/*
id_miasta   nazwa                                              srednia zarobkow
----------- -------------------------------------------------- ---------------------
1           WARSZAWA                                           6000,00
2           PLOCK                                              0,00
3           RADOM                                              9500,00
4           SIERPC                                             7416,6666
5           OSTROLEKA                                          7500,00
6           WYSZKOW                                            3600,00
7           BIALYSTOK                                          4250,00
8           SUWALKI                                            0,00
9           SOKOLKA                                            5500,00
10          KRYNKI                                             10000,00
11          SUPRASL                                            0,00
12          BIALOWIEZA                                         0,00

(12 row(s) affected)
*/


/*
Z5.3 Napisaæ procedurê pokazuj¹c¹ œredni¹ pensjê w
osób z miasta - parametr procedure @id_miasta
*/
GO

CREATE PROCEDURE dbo.P2 (@id_miasta int )
AS
	SELECT m.id_miasta, m.nazwa, ISNULL(X.suma_zarobkow, 0) AS [srednia zarobkow]
	FROM MIASTA m
	left outer
	join (SELECT mW.id_miasta, AVG(ew.pensja) AS suma_zarobkow 
			FROM etaty eW
			join FIRMY f ON (eW.id_firmy = f.nazwa_skr)
			join MIASTA mW ON (mW.id_miasta = f.id_miasta)
			WHERE EW.DO IS NULL
			GROUP BY mW.id_miasta
		) X ON (X.id_miasta = m.id_miasta)
	WHERE m.id_miasta = @id_miasta 
	ORDER BY m.id_miasta, m.nazwa
	
GO
EXEC P2 @id_miasta = 3

/*
Command(s) completed successfully.
*/

/*
EXEC P2 @id_miasta = 1
id_miasta   nazwa                                              srednia zarobkow
----------- -------------------------------------------------- ---------------------
1           WARSZAWA                                           6000,00

(1 row(s) affected)
EXEC P2 @id_miasta = 2
id_miasta   nazwa                                              srednia zarobkow
----------- -------------------------------------------------- ---------------------
2           PLOCK                                              0,00

(1 row(s) affected)
EXEC P2 @id_miasta = 3
id_miasta   nazwa                                              srednia zarobkow
----------- -------------------------------------------------- ---------------------
3           RADOM                                              9500,00

(1 row(s) affected)
*/









