/*Z3 Karol Sek�ci�ski GR4 319093 */

/* 
Z3.1 - policzy� liczb� firm w ka�dym mie�cie (zapytanie z grupowaniem)
Najlepiej wynik zapami�ta� w tabeli tymczasowej
*/


SELECT COUNT(DISTINCT f.nazwa_skr) AS [Liczba firm]
, LEFT(m.nazwa, 20) AS [Miasto]
INTO #RR
FROM FIRMY f, Miasta m 
WHERE f.id_miasta = m.id_miasta

GROUP BY m.nazwa

/*
Liczba firm Miasto
----------- --------------------
1           BIALYSTOK
1           KRYNKI
1           OSTROLEKA
1           RADOM
2           SIERPC
1           SOKOLKA
1           SUWALKI
1           WARSZAWA
1           WYSZKOW

(9 row(s) affected)
*/


/*
Z3.2 - korzystaj�c z wyniku Z3,1 - pokaza�, kt�re miasto ma najwi�ksz� liczb� firm
(zapytanie z fa - analogiczne do zada� z Z2)
*/


DECLARE @max int
SELECT @max = MAX(r.[Liczba firm])
    FROM #RR r

SELECT r.Miasto
, r.[Liczba firm] 
    FROM #RR r
    WHERE (r.[Liczba firm] = @max)

/*
Miasto               Liczba firm
-------------------- -----------
SIERPC               2

(1 row(s) affected)
*/

/*
Z3.3 Pokaza� liczb� os�b w ka�dym z wojew�dztw (czyli grupowanie po kod_woj)
*/
SELECT COUNT(DISTINCT o.id_osoby) AS [Liczba osob]
, LEFT(w.nazwa,20) AS [WOJ]
FROM WOJ w
join MIASTA m on (w.kod_woj = m.kod_woj)
join OSOBY o on (m.id_miasta = o.id_miasta)
GROUP BY w.kod_woj, w.nazwa

/*
Liczba osob WOJ
----------- --------------------
8           MAZOWIECKIE
7           PODLASKIE

(2 row(s) affected)
*/



/*
Z3.4 Pokaza� wojew�dztwa w kt�rych nie ma �adnej osoby
(jak nie ma WOJ w kt�rym nie ma MIAST w kt�rych nie ma os�b
to prosze doda� ze 2 takie WOJ i ze miasta w tych WOJ)
*/

SELECT w.nazwa AS [WOJ bez osob]

FROM WOJ w

WHERE NOT EXISTS
(SELECT 1 FROM MIASTA m, OSOBY o WHERE (m.id_miasta = o.id_miasta) AND (m.kod_woj = w.kod_woj))

/*
WOJ bez osob
--------------------------------------------------
POMORSKIE

(1 row(s) affected)
*/
/*
(suma z3.3 i z3.4 powinna da� nam pe�n� list� wojew�dztw -
woj gdzie sa osoby i gdzie ich nie ma to razem powinny byc wszystkie

*/

SELECT * FROM WOJ
/*
kod_woj nazwa
------- --------------------------------------------------
MAZ     MAZOWIECKIE
POD     PODLASKIE
POM     POMORSKIE

(3 row(s) affected)
*/
