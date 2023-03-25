/*Z2 Karol Sek�ci�ski GR4 319093 */

/*1.Pokaza� dane podstawowe firmy, w jakim mie�cie si� znajduje i w jakim to jest wojew�dztwie*/

SELECT f.id_miasta AS [ID]
,		LEFT(f.nazwa, 15) AS [Nazwa_firmy]
,		LEFT(f.kod_pocztowy,6) AS [Kod_pocztowy_firmy]
,		LEFT(m.kod_woj, 10) AS [WOJEWODZTWO]
,		LEFT(m.nazwa,15) AS [MIASTO]
FROM FIRMY f
		join MIASTA m on (m.id_miasta = f.id_miasta)
		join WOJ w on (w.kod_woj = m.kod_woj)

/*
ID          Nazwa_firmy     Kod_pocztowy_firmy WOJEWODZTWO MIASTO
----------- --------------- ------------------ ----------- ---------------
8           FIRMA ZERO      01234              POD         SUWALKI
6           BALFA           12345              MAZ         WYSZKOW
1           ABETA           23456              MAZ         WARSZAWA
7           GAMMA           34567              POD         BIALYSTOK
3           ZETA            45678              MAZ         RADOM
9           BETAF           56789              POD         SOKOLKA
5           FIRMA SZOSTA    67890              MAZ         OSTROLEKA
10          FIRMA SIODMAA   78901              POD         KRYNKI
4           FIRMA OSMA      89012              MAZ         SIERPC
4           BETAK           90123              MAZ         SIERPC

(10 row(s) affected)
*/

/*2.Pokaza� wszystkie firmy o nazwie na liter� X i ostatniej literze nazwiska Y lub Z
(je�eli nie macie takowych to wybierzcie takie warunki - inn� liter� pocz�tkow� i inne 2 ko�cowe)
kt�re maj� pensje pomi�dzy 3000 a 5000 na stanowisku Prezes
(te� mo�ecie zmieni� je�eli macie g�ownie inne zakresy czy nie ma takiego stanowiska)

(wystarcz� dane z tabel etaty, firmy, osoby , miasta) aby pokaza� dane etatu, firmy i osoby na tym etacie)
*/
SELECT e.id_firmy AS [ID_FIRMY]
,			f.nazwa AS [Nazwa_firmy]			
,			e.pensja AS [PENSJA]
,			o.imie AS [imie]
,			o.nazwisko AS [nazwisko]
,			e.stanowisko AS [stanowisko]

FROM ETATY e
		join FIRMY f on (e.id_firmy = f.nazwa_skr) and (e.pensja >= 3000 and e.pensja <= 5000 and e.stanowisko = N'PREZES')
		join OSOBY o on (e.id_osoby = o.id_osoby)
		join MIASTA mO on (mO.id_miasta = o.id_miasta)
		join MIASTA mF on (mF.id_miasta = f.id_miasta)
WHERE f.nazwa LIKE N'B%a' OR f.nazwa LIKE N'B%k'

/*
ID_FIRMY Nazwa_firmy                                        PENSJA                imie                                               nazwisko                                           stanowisko
-------- -------------------------------------------------- --------------------- -------------------------------------------------- -------------------------------------------------- --------------------------------------------------
FIRMA1   BALFA                                              4200,00               JAN                                                NOWAK                                              PREZES
FIRMA9   BETAK                                              3500,00               KLAUDIA                                            BEC                                                PREZES

(2 row(s) affected)
*/


/*
3.Pokaza� firm� o najd�u�szej nazwie w bazie
(najpierw szukamy MAX z LEN(nazwa) a potem pokazujemy te FIRMY z tak� d�ugo�ci� nazwy)
*/
SELECT	MAX(LEN(f.nazwa)) AS [NAJDLUZSZA_NAZWA]
INTO #TT
FROM FIRMY f

SELECT * 
FROM FIRMY f
	join #TT t on (t.[NAJDLUZSZA_NAZWA] = (LEN(f.nazwa)))

/*
nazwa_skr id_miasta   nazwa                                              kod_pocztowy ulica                                              NAJDLUZSZA_NAZWA
--------- ----------- -------------------------------------------------- ------------ -------------------------------------------------- ----------------
FIRMA7    10          FIRMA SIODMAA                                      78901        SIENNA                                             13

(1 row(s) affected)
*/


/*4.Policzy� liczb� firm w mie�cie o nazwie (tu daj� Wam wyb�r - w kt�rym mie�cie macie najwi�cej)
(zapytanie powinno pokaza� kolumn� [liczba firm w xx])
*/


SELECT COUNT(f.id_miasta) AS [Liczba_firm_w_Sierpcu]
FROM MIASTA m
	join FIRMY f on ((f.id_miasta = m.id_miasta) and (m.nazwa = N'SIERPC')) /*Tam jest najwiecej firm*/
/* 
Liczba_firm_w_Sierpcu
---------------------
2

(1 row(s) affected)
*/