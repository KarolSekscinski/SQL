/*Z4 Karol Sekœciñski GR4 319093 */

/*
Z4.1 - poazaæ firmy z województwa o kodzie X, w których nigdy
nie pracowa³y / nie pracuja osoby mieszkaj¹ce w woj o tym samym kodzie
(lub innym - jakie dane lepsze)

czyli jezeli jaikolwiek etat spe³niaj¹cy warunek powy¿ej to osoby nie pokazujemy

Czyli jak FIRMA PW ma 2 etaty i jeden
osoby mieszkaj¹cej w woj o kodzie X
a drugi etat osoby mieszkaj¹cej w woj Y
to takiej osoby NIE POKOZUJEMY !!!
A nie, ¿e poka¿emy jeden etat a drugi nie

*/
SELECT *
	FROM FIRMY f
	join MIASTA m ON m.id_miasta = f.id_miasta
	WHERE not exists 
	( SELECT 1
		FROM ETATY e
		join OSOBY o on o.id_osoby = e.id_osoby
		join MIASTA m1 on m1.id_miasta = o.id_miasta
		where e.id_firmy = f.nazwa_skr and m1.kod_woj like N'LUB%')
	and m.kod_woj like N'LUB%'
/*
nazwa_skr id_miasta   nazwa                                              kod_pocztowy ulica                                              id_miasta   nazwa                                              kod_woj
--------- ----------- -------------------------------------------------- ------------ -------------------------------------------------- ----------- -------------------------------------------------- -------

(0 row(s) affected)
*/

/*
Z4.2 - pokazaæ liczbê mieszkañców w miastach
ale tylko w tych maj¹cych wiecej jak jednego mieszkañca
*/
SELECT m.kod_woj, COUNT(DISTINCT o.id_osoby) AS liczba_os
	FROM miasta m 
	join osoby o ON (o.id_miasta = m.id_miasta)
	GROUP BY m.kod_woj
	HAVING COUNT(DISTINCT o.id_osoby) > 1
	ORDER BY 2 DESC
/*
kod_woj liczba_os
------- -----------
MAZ     8
POD     7

(2 row(s) affected)
*/
/*
Z4,3 - pokazaæ sredni¹ pensjê w województwach
ale tylko tych posiadaj¹cych wiêcej jak jednego mieszkañca
*/

SELECT w.kod_woj, AVG(e.pensja) AS [srednia pensja]
	FROM WOJ w 
	
	join MIASTA m ON (w.kod_woj = m.kod_woj)
	join osoby o ON (o.id_miasta = m.id_miasta)
	join ETATY e ON (e.id_osoby = o.id_osoby)
	GROUP BY w.kod_woj
	HAVING COUNT( distinct o.id_osoby) > 1
	ORDER BY 2 DESC
/*
kod_woj srednia pensja
------- ---------------------
MAZ     7063,6363
POD     6611,1111

(2 row(s) affected)
*/


/*
1 wariant -> etaty -> osoby -> miasta (srednia z osób mieszkaj¹cych w danym kod_woj)
teraz z³aczamy wynik tego zapytania z osoby->miasta (grupowane po kod_woj z HAVING)
2 wariant -> (srednia z firm o danym kod_woj) a liczba mieszkañców z OSOBY
(czyli srednia wyliczana z tabel Etaty -> Firmy -> Miasta) -> do tab #tymcz
(³aczymy tabelê #tymczas z osoby -> miasta z grupowaniem poprzez kod_woj)
*/
