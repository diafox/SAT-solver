# Riešiteľ SAT pomocou DPLL algoritmu 
(dokumentácia)

## 1.	Zadanie
V jazyku Haskell naprogramujte riešiteľa SAT – splniteľnosti booleovských formulí.

## 2.	Zvolený algoritmus
Zistiť, či formula s n premennými je splniteľná je relatívne jednoduché preskúmanie všetkých 2^n možných úplných ohodnotení. Pre moje riešenie som zvolila DPLL algoritmus, ktorý efektivitu programu vylepšuje o elimináciu niekoľkých ohodnotení, ktoré sú triviálne nesplňujúce. 
DPLL algoritmus slúži na rozhodovanie splniteľnosti výrokovej formule pomocou prehľadávania za použitia back-trackingu. Názov nesie podľa jeho tvorcov – Davison, Putnam, Logemann, Loveland. 
Algoritmus na začiatku zistí, či je vstupná CNF formula triviálne nesplniteľná, a teda či neobsahuje prázdnu klauzulu alebo spor. Potom vyberie premennú a aplikuje algoritmus rekurzívne na podformulu získanú z pôvodnej formuly dosadením hodnoty True alebo False do premennej. Keď zistí, že formula je splniteľná, vráti splňujúce ohodnotenie spätným chodom rekurzie, inak aplikuje algo-ritmus na formulu získanú dosadením druhej hodnoty. Ak neuspeje, formulu prehlási za nesplniteľnú. 

## 3.	Štruktúra programu 
Pre reprezentáciu výrokov sme vytvorili dátový typ `Formula`, ktorý môže mať podobu premennej, konštanty, konjunkcie, disjunkcie alebo negácie iných formulí. Pre repre-zentáciu ohodnotení máme dátový typ `BoolValue`, ktorý môže byť `Positive` (ohodnote-nie True), `Negative` (ohodnotenie False) alebo `Combined` v prípade, že sa premenná vyskytuje v oboch ohodnoteniach.
Prvý krok programu zabezpečuje prevod vstupnej formule do konjunktívnej normálnej formy (CNF), ktorá má tvar konjunkcie klauzulí, kde klauzulu definujeme ako disjunkciu literálov, a teda používa iba operácie AND, OR a NOT. Používa De Morganove pravidlo pre odstránenie negácii a distribučné pravidlo pre tzv. roznásobenie zátvoriek. 
Následne program vyhľadá prvú nezabranú premennú, a teda premennú bez ohodnotenia. V nasledujúcej funkcii vyskúša premennej priradiť hodnotu true alebo false.
V ďalšom kroku aplikujeme vylepšenia. Najprv pravidlo unipolárneho literálu a teda elimináciu literálov s jedným ohodnotením. Potom pravidlo jednotkového literálu, kde vyhadzujeme osamotené literály z klauzulí. 
V poslednom kroku aplikujeme úpravy na vstupný výraz, ktorý následne zjednodušíme, aby bol spracovateľný DPLL algoritmom. Ten používa prehľadávanie s využitím back-trackingu.

## 4.	Alternatívne riešenie
Problém by sa dal riešiť spomínanou „hrubou silou“ a teda prehľadaním všetkých 2^n možností bez použitia akýchkoľvek vylepšení.

## 5.	Vstupné a výstupné dáta
Vstupné dáta sú v dátovom formáte Formula, ktorý má tvár _Operácia (Výraz) (Výraz)_. Testovacie vstupné dáta sa nachádzajú na konci programu v sekcii Sada testovacích príkladov. 
Výstup má tvar hodnoty True alebo False, podľa toho či je daná formula splniteľná alebo nie.

## 6.	Záver
Myslím si, že pri správnom rozdelení problému do viacerých podproblémov a predbežnom naplánovaní jednotlivých funkcii by s vypracovaním zadania nemal byť problém. Dlhšiu dobu mi trvalo študovanie DPLL algoritmu, hlavne kým som pochopila, že ide o v celku jednoduché prehľadávanie len sú použité nejaké špeciálne efektívne metódy na jeho zrýchlenie. Nižšie prikladám aj zdroje, z ktorých som čerpala.

## 7.	Zdroje 
- HRNČIAR, Maroš. DPLL algoritmus a výrokové důkazy. 2012. Bakalářská práce. Univerzita Karlova, Matematicko-fyzikální fakulta, Katedra algebry. Vedoucí práce Krajíček, Jan.
- Sanchit Batra, Atri Rudra: Satisfiability and SAT solvers [online], Algorithms and Complexity course, University at Buffalo, 2018. 
Dostupné z: https://www.cse.buffalo.edu/~erdem/cse331/support/sat-solver/index.html
- prednášky Petra Gregora: Výroková a predikátová logika, ZS 2021/22, KTIML MFF UK
- wikipedia 
