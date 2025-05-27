# Sprawozdanie z Ćwiczenia: Identyfikacja Modelu Silnika Parowego

**Autor:** Student Automatyki i Robotyki  
**Data:** 27.05.2025  
**Temat:** Identyfikacja parametryczna modelu silnika parowego metodą najmniejszych kwadratów

## Spis Treści

1. [Wstęp i cel ćwiczenia](#1-wstęp-i-cel-ćwiczenia)
2. [Opis obiektu](#2-opis-obiektu)
   - 2.1 [Zasada działania silnika parowego](#21-zasada-działania-silnika-parowego)
3. [Przygotowanie danych pomiarowych](#3-przygotowanie-danych-pomiarowych)
   - 3.1 [Preprocessing danych](#31-preprocessing-danych)
   - 3.2 [Wizualizacja danych pomiarowych](#32-wizualizacja-danych-pomiarowych)
4. [Struktura modelu ARX](#4-struktura-modelu-arx)
   - 4.1 [Równanie modelu](#41-równanie-modelu)
   - 4.2 [Interpretacja parametrów modelu ARX](#42-interpretacja-parametrów-modelu-arx)
   - 4.3 [Parametry struktury](#43-parametry-struktury)
   - 4.4 [Szczegółowe objaśnienie notacji ARX(2,[2,2],[1,1])](#44-szczegółowe-objaśnienie-notacji-arx222111)
     - 4.4.1 [Rozbicie notacji](#441-rozbicie-notacji)
     - 4.4.2 [Przekład na równanie różnicowe](#442-przekład-na-równanie-różnicowe)
     - 4.4.3 [Interpretacja fizyczna dla silnika parowego](#443-interpretacja-fizyczna-dla-silnika-parowego)
     - 4.4.4 [Liczba parametrów do identyfikacji](#444-liczba-parametrów-do-identyfikacji)
     - 4.4.5 [Przykłady innych struktur ARX](#445-przykłady-innych-struktur-arx)
5. [Identyfikacja parametrów metodą najmniejszych kwadratów](#5-identyfikacja-parametrów-metodą-najmniejszych-kwadratów)
   - 5.1 [Sformułowanie problemu](#51-sformułowanie-problemu)
     - 5.1.1 [Szczegółowe wyjaśnienie wektorów](#511-szczegółowe-wyjaśnienie-wektorów)
6. [Walidacja i ocena jakości modelu](#6-walidacja-i-ocena-jakości-modelu)
   - 6.1 [Miary dopasowania modelu](#61-miary-dopasowania-modelu)
   - 6.2 [Obliczenie sygnału wyjściowego modelu](#62-obliczenie-sygnału-wyjściowego-modelu)
   - 6.3 [Wyniki walidacji](#63-wyniki-walidacji)
   - 6.4 [Porównanie modelu z danymi rzeczywistymi](#64-porównanie-modelu-z-danymi-rzeczywistymi)
   - 6.5 [Analiza reszt](#65-analiza-reszt)
7. [Analiza stabilności modelu](#7-analiza-stabilności-modelu)
   - 7.1 [Stabilność systemu dyskretnego](#71-stabilność-systemu-dyskretnego)
   - 7.2 [Położenie biegunów](#72-położenie-biegunów)
   - 7.3 [Ocena stabilności](#73-ocena-stabilności)
   - 7.4 [Transmitancje modelu](#74-transmitancje-modelu)
8. [Wnioski](#8-wnioski)
   - 8.1 [Ograniczenia metody](#81-ograniczenia-metody)
   - 8.2 [Możliwe ulepszenia](#82-możliwe-ulepszenia)
9. [Literatura](#9-literatura)
10. [Dodatek A: Implementacja w MATLAB](#dodatek-a-implementacja-w-matlab)
11. [Dodatek B: Zagadnienia do samodzielnego rozwiązania](#dodatek-b-zagadnienia-do-samodzielnego-rozwiązania)

---

## 1. Wstęp i cel ćwiczenia

Celem ćwiczenia jest identyfikacja parametryczna modelu silnika parowego przy użyciu struktury ARX (AutoRegressive with eXogenous inputs) i metody najmniejszych kwadratów. Badany układ jest typu MISO (Multiple Input Single Output) z dwoma wejściami i jednym wyjściem.

Główne założenia projektowe:

- Identyfikacja laboratoryjnego modelu silnika parowego
- Wykorzystanie dyskretnego modelu ARX
- Zastosowanie metody najmniejszych kwadratów (LS)
- Osiągnięcie wskaźnika dopasowania FIT > 85%

Identyfikacja systemów stanowi kluczowy element w inżynierii sterowania, pozwalający na matematyczny opis zachowania systemu na podstawie danych pomiarowych. Pozwala to na projektowanie układów sterowania oraz przeprowadzanie symulacji bez konieczności opierania się wyłącznie na modelu fizycznym obiektu.

**Odniesienia do materiałów kursu:**

- Podstawy analizy sygnałów i ich właściwości omówione są w **IdScw1.pdf** (sekcja: "Podstawowa analiza sygnałów")
- Metody pozyskiwania wiedzy wstępnej o systemie opisane w **IdScw2.pdf** (sekcja: "Pozyskiwanie wiedzy wstępnej o systemie")

## 2. Opis obiektu

Badanym obiektem jest laboratoryjny model silnika parowego, który charakteryzuje się następującymi parametrami:

- **Okres próbkowania:** Tp = 50ms
- **Wejścia:**
  - u1: ciśnienie pary za zaworem
  - u2: napięcie magnetyzacji generatora
- **Wyjście:**
  - y: napięcie w generatorze

Układ jest typu MISO (Multiple Input Single Output), co oznacza, że posiada dwa wejścia sterujące i jedno wyjście.

### 2.1 Zasada działania silnika parowego

Silnik parowy to urządzenie, które przekształca energię cieplną pary wodnej w energię mechaniczną ruchu obrotowego. W modelu laboratoryjnym, para o określonym ciśnieniu (wejście u1) jest dostarczana do cylindra silnika, powodując ruch tłoka. Ruch ten jest następnie przekształcany w ruch obrotowy wału, który napędza generator elektryczny.

Generator z kolei jest kontrolowany przez napięcie magnetyzacji (wejście u2), które wpływa na charakterystykę generowania napięcia wyjściowego (wyjście y). Zmiana napięcia magnetyzacji pozwala na regulację poziomu napięcia wyjściowego przy danej prędkości obrotowej wału.

## 3. Przygotowanie danych pomiarowych

Dane pomiarowe zostały dostarczone w pliku `dane.mat` i zawierały zbiór sygnałów wejściowych i wyjściowych zarejestrowanych podczas eksperymentów z modelem silnika parowego.

### 3.1 Preprocessing danych

W ramach przygotowania danych wykonano następujące czynności:

1. **Wczytanie danych** z pliku `dane.mat`:

   ```matlab
   load('dane.mat');
   ```

2. **Identyfikacja sygnałów wejściowych i wyjściowych**:

   ```matlab
   u1 = in1;  % Ciśnienie pary za zaworem
   u2 = in2;  % Napięcie magnetyzacji generatora
   y = out;   % Napięcie w generatorze (wyjście)
   ```

3. **Konwersja danych do formatów wektorów kolumnowych**:

   ```matlab
   u1 = u1(:);
   u2 = u2(:);
   y = y(:);
   ```

4. **Dopasowanie długości wszystkich sygnałów** do minimalnej wspólnej długości:

   ```matlab
   N = min([length(u1), length(u2), length(y)]);
   u1 = u1(1:N);
   u2 = u2(1:N);
   y = y(1:N);
   ```

5. **Usunięcie wartości średnich** z sygnałów w celu lepszej identyfikacji dynamiki układu:

   ```matlab
   u1 = u1 - mean(u1);
   u2 = u2 - mean(u2);
   y = y - mean(y);
   ```

   Ten krok jest istotny, ponieważ usunięcie składowych stałych pozwala na lepszą identyfikację dynamiki systemu, eliminując wpływ przesunięć DC, które mogłyby zniekształcić model.

### 3.2 Wizualizacja danych pomiarowych

Poniżej przedstawiono wykresy przebiegu czasowego sygnałów wejściowych i wyjściowego:

![Rys. 1: Dane pomiarowe](./dane_pomiarowe-eps-converted-to.pdf)

_Rys. 1 Przebiegi czasowe sygnałów: u1 (ciśnienie pary), u2 (napięcie magnetyzacji) oraz y (napięcie w generatorze)_

Analiza wizualna danych pozwala na wstępną ocenę charakteru dynamiki systemu oraz może ujawnić pewne korelacje między sygnałami wejściowymi a wyjściem. Zauważmy, że:

- Sygnały wejściowe (u1, u2) zawierają zróżnicowane pobudzenia, które są istotne dla poprawnej identyfikacji.
- Wyjście systemu (y) wykazuje dynamiczną odpowiedź na zmiany sygnałów wejściowych.
- Widoczne są opóźnienia między zmianami wejść a odpowiedzią wyjścia, co wskazuje na obecność opóźnień transportowych w systemie.

**Materiały źródłowe:**

- Teoria analizy sygnałów w dziedzinie czasu: **IdScw1.pdf** (równanie 1: definicja procesu stochastycznego)
- Metody nieparametryczne analizy odpowiedzi czasowych: **IdScw2.pdf** (sekcja 1: "Identyfikacja poprzez analizę odpowiedzi czasowych")

## 4. Struktura modelu ARX

Do identyfikacji systemu wybrano model ARX (AutoRegressive with eXogenous inputs) o następującej strukturze:

**Podstawy teoretyczne:**

- Modele parametryczne typu ARX opisane w **IdScw3.pdf** (sekcja: "Wsadowa parametryczna identyfikacja systemów")
- Struktury regresyjne systemów dynamicznych w **IdScw4.pdf** (równanie 1: postać regresyjna)

### 4.1 Równanie modelu

Ogólna postać równania różnicowego modelu ARX dla systemu MISO ma postać:

$$A(q^{-1})y(k) = B_1(q^{-1})u_1(k-nk_1) + B_2(q^{-1})u_2(k-nk_2) + e(k)$$

gdzie:

- $q^{-1}$ - operator opóźnienia (tzn. $q^{-1}y(k) = y(k-1)$)
- $A(q^{-1}) = 1 + a_1q^{-1} + a_2q^{-2} + \ldots + a_{na}q^{-na}$ - wielomian autoregresyjny
- $B_1(q^{-1}) = b_{10} + b_{11}q^{-1} + \ldots + b_{1,nb1-1}q^{-(nb1-1)}$ - wielomian dla pierwszego wejścia
- $B_2(q^{-1}) = b_{20} + b_{21}q^{-1} + \ldots + b_{2,nb2-1}q^{-(nb2-1)}$ - wielomian dla drugiego wejścia
- $e(k)$ - biały szum (błąd modelowania)
- $nk_1, nk_2$ - opóźnienia transportowe dla poszczególnych wejść

Możemy również zapisać równanie modelu w postaci rozwiniętej:

$$y(k) + a_1y(k-1) + a_2y(k-2) + \ldots + a_{na}y(k-na) = $$
$$b*{10}u_1(k-nk_1) + b*{11}u*1(k-nk_1-1) + \ldots + b*{1,nb1-1}u*1(k-nk_1-nb1+1) + $$
$$b*{20}u*2(k-nk_2) + b*{21}u*2(k-nk_2-1) + \ldots + b*{2,nb2-1}u_2(k-nk_2-nb2+1) + e(k)$$

### 4.2 Interpretacja parametrów modelu ARX

W modelu ARX, parametry mają następującą interpretację:

1. **Parametry wielomianu A**: $a_1, a_2, \ldots, a_{na}$

   - Opisują wpływ przeszłych wartości wyjścia na aktualną wartość wyjścia
   - Określają "pamięć" systemu i jego naturalne moduł dynamiki
   - Bieguny modelu są określone przez pierwiastki wielomianu A, co determinuje stabilność systemu

2. **Parametry wielomianów B1 i B2**: $b_{10}, b_{11}, \ldots, b_{1,nb1-1}$ oraz $b_{20}, b_{21}, \ldots, b_{2,nb2-1}$

   - Opisują wpływ przeszłych wartości wejść na aktualną wartość wyjścia
   - Określają wzmocnienie i dynamikę odpowiedzi systemu na poszczególne wejścia

3. **Opóźnienia transportowe** $nk_1$ i $nk_2$:
   - Reprezentują czas potrzebny na zaobserwowanie wpływu zmiany wejścia na wyjście
   - Wynikają z fizycznych właściwości układu (np. czasu propagacji sygnału)

### 4.3 Parametry struktury

Dla naszej implementacji przyjęto następujące parametry struktury:

- na = 2 - rząd części autoregresyjnej
- nb1 = 2 - rząd dla pierwszego wejścia
- nb2 = 2 - rząd dla drugiego wejścia
- nk1 = 1 - opóźnienie dla pierwszego wejścia
- nk2 = 1 - opóźnienie dla drugiego wejścia

Oznacza to, że identyfikujemy model ARX(2,[2,2],[1,1]), który można zapisać w postaci:

$$y(k) + a_1y(k-1) + a_2y(k-2) = b_{10}u_1(k-1) + b_{11}u_1(k-2) + b_{20}u_2(k-1) + b_{21}u_2(k-2) + e(k)$$

### 4.3.1 Szczegółowe uzasadnienie wyboru parametrów ARX(2,[2,2],[1,1])

Wybór konkretnych wartości parametrów struktury modelu ARX dla silnika parowego nie jest przypadkowy, lecz wynika z dogłębnej analizy fizycznych właściwości systemu oraz matematycznych aspektów identyfikacji. Poniżej przedstawiono szczegółowe uzasadnienie dla każdego parametru.

#### A) Rząd części autoregresyjnej: na = 2

**Uzasadnienie fizyczne:**

Silnik parowy jako system termomechaniczny charakteryzuje się dwoma głównymi rodzajami inercji:

1. **Inercja mechaniczna** - wynikająca z masy wirnika generatora, wału napędowego oraz elementów ruchomych tłoka. Ta bezwładność mechaniczna powoduje, że zmiany prędkości obrotowej nie zachodzą natychmiastowo, lecz z pewną stałą czasową.

2. **Inercja termodynamiczna** - związana z pojemnością cieplną cylindra, czasem wymiany ciepła między parą a ściankami cylindra oraz dynamiką przepływu pary przez zawory. Proces termodynamiczny ma swoją charakterystyczną dynamikę, która wpływa na opóźnienia w systemie.

Napięcie generatora jest bezpośrednio proporcjonalne do prędkości obrotowej wału, która z kolei zależy od historii sił działających na układ. Wartość na=2 oznacza, że obecne wyjście systemu zależy od dwóch poprzednich wartości wyjścia, co matematycznie modeluje tę naturalną "pamięć" systemu fizycznego.

**Uzasadnienie matematyczne:**

- Większość systemów fizycznych drugiego rzędu może być skutecznie opisana przez część autoregresyjną drugiego rzędu AR(2)
- na=1 byłoby zbyt uproszczone - opisywałoby tylko system pierwszego rzędu z jednym biegunem, co nie oddaje złożoności dinamiki silnika parowego
- na=3 lub wyższe wartości mogłyby prowadzić do **overfittingu**, szczególnie przy ograniczonych danych pomiarowych, oraz zwiększyłyby ryzyko niestabilności numerycznej
- na=2 stanowi **optymalny kompromis** między złożonością modelu a jego zdolnością do uogólniania

#### B) Rzędy wejść: nb1 = nb2 = 2

**Uzasadnienie fizyczne dla u1 (ciśnienie pary za zaworem):**

Wpływ ciśnienia pary na napięcie generatora nie jest natychmiastowy i przebiega w następujących etapach:

1. **Zmiana ciśnienia** → **przyspieszenie tłoka** → **zmiana momentu obrotowego** → **zmiana prędkości obrotowej** → **zmiana napięcia generatora**

Każdy z tych etapów ma swoją charakterystyczną stałą czasową. Wartość nb1=2 pozwala na modelowanie tej **przejściowej charakterystyki termodynamicznej**, uwzględniając wpływ "historii" ciśnienia na obecne wyjście. Uwzględnia to zarówno bezpośredni wpływ obecnego ciśnienia, jak i efekty inercyjne wynikające z poprzednich stanów.

**Uzasadnienie fizyczne dla u2 (napięcie magnetyzacji generatora):**

Magnetyzacja generatora ma swoją charakterystyczną dynamikę elektromagnetyczną:

1. **Indukcyjność cewek magnetyzujących** - pole magnetyczne nie ustala się natychmiastowo po zmianie napięcia magnetyzacji
2. **Prądy wirowe** w rdzeniu ferromagnetycznym powodują opóźnienia w ustalaniu się pola magnetycznego
3. **Histereza magnetyczna** - poprzednie stany magnesowania wpływają na obecną charakterystykę generatora

Wartość nb2=2 modeluje tę **elektromagnetyczną inercję generatora**, uwzględniając wpływ poprzednich stanów magnesowania na obecne napięcie wyjściowe.

**Uzasadnienie matematyczne:**

- nb=1 modelowałoby tylko **natychmiastowy wpływ** wejścia, co byłoby zbyt uproszczone dla systemów z dynamiką drugiego rzędu
- nb=2 umożliwia modelowanie **dynamiki drugiego rzędu** dla każdego kanału wejściowego, co jest adekwatne dla większości systemów fizycznych
- nb=3 lub więcej **zwiększyłoby liczbę parametrów** bez znaczącego poprawienia dokładności, zwiększając jednocześnie ryzyko overfittingu

#### C) Opóźnienia transportowe: nk1 = nk2 = 1

**Uzasadnienie fizyczne:**

W każdym systemie fizycznym istnieje **minimalny czas propagacji sygnału** między przyczyną a skutkiem:

1. **Opóźnienie termodynamiczne** (dla u1): czas potrzebny na to, aby zmiana ciśnienia pary przełożyła się na obserwowalną zmianę napięcia generatora. Obejmuje to czas reakcji mechanizmu tłokowego oraz czas potrzebny na zmianę prędkości obrotowej.

2. **Opóźnienie elektromagnetyczne** (dla u2): czas potrzebny na to, aby zmiana napięcia magnetyzacji przełożyła się na zmianę pola magnetycznego i w konsekwencji na zmianę napięcia wyjściowego generatora.

W badanym systemie z okresem próbkowania Tp = 50ms, opóźnienia nk1 = nk2 = 1 odpowiadają **realistycznemu czasowi reakcji** systemu równemu jednemu okresowi próbkowania.

**Uzasadnienie praktyczne:**

- nk=0 oznaczałoby **natychmiastową reakcję** systemu, co jest niefizyczne dla systemów rzeczywistych
- nk=1 odpowiada **okresowi próbkowania** (50ms), co jest rozsądnym przypuszczeniem dla opóźnienia w systemie termomechanicznym
- nk=2 lub więcej **wydłużyłoby opóźnienie** ponad to, co jest fizycznie uzasadnione dla tego typu systemu

#### D) Obliczenie maksymalnego opóźnienia

Maksymalne opóźnienie w systemie jest określone wzorem:

$$max\_delay = max([na, nb_1+nk_1-1, nb_2+nk_2-1])$$

Dla naszych parametrów:

- Część autoregresyjna: na = 2
- Pierwsze wejście: nb1+nk1-1 = 2+1-1 = 2
- Drugie wejście: nb2+nk2-1 = 2+1-1 = 2

Zatem: max_delay = max([2, 2, 2]) = 2

To oznacza, że **identyfikacja może rozpocząć się od próbki k = 3**, ponieważ:

- Do obliczenia y(3) potrzebujemy: y(1), y(2), u1(1), u1(2), u2(1), u2(2)
- start_idx = max_delay + 1 = 3

#### E) Analiza kompromisów

**Zalety wybranej struktury ARX(2,[2,2],[1,1]):**

✅ **6 parametrów** do identyfikacji (na+nb1+nb2 = 2+2+2) - liczba zarządzalna numerycznie  
✅ **Wystarczająco złożona** do modelowania dynamiki drugiego rzędu  
✅ **Fizycznie uzasadniona** dla systemów termomechanicznych  
✅ **Sprawdzona w praktyce** dla podobnych aplikacji przemysłowych  
✅ **Dobra stabilność numeryczna** przy estymacji metodą najmniejszych kwadratów  
✅ **Unika overfittingu** przy typowych ilościach danych pomiarowych

**Porównanie z alternatywnymi strukturami:**

| Struktura          | Parametry | Zalety                       | Wady                         |
| ------------------ | --------- | ---------------------------- | ---------------------------- |
| ARX(1,[1,1],[1,1]) | 3         | Prostota, szybkość           | Za proste, gorsza dokładność |
| ARX(3,[2,2],[1,1]) | 7         | Więcej "pamięci"             | Ryzyko overfittingu          |
| ARX(2,[3,3],[1,1]) | 8         | Dłuższa odpowiedź na wejścia | Za dużo parametrów           |
| ARX(2,[2,2],[2,2]) | 6         | Ta sama liczba parametrów    | Za duże opóźnienia           |

**Podsumowanie:**

Wybór struktury ARX(2,[2,2],[1,1]) dla identyfikacji silnika parowego stanowi **optymalny kompromis** między:

- Złożonością modelu a liczbą parametrów
- Dokładnością odwzorowania dynamiki a stabilnością numeryczną
- Uzasadnieniem fizycznym a praktycznością implementacji
- Zdolnością do modelowania a ryzykiem overfittingu

Zastosowanie tego konkretnego modelu ARX wynika z analizy dynamiki badanego układu i jest kompromisem między złożonością modelu a jego zdolnością do odwzorowania zachowania systemu.

### 4.4 Szczegółowe objaśnienie notacji ARX(2,[2,2],[1,1])

Notacja **ARX(2,[2,2],[1,1])** to standardowy sposób zapisu struktury modelu ARX w identyfikacji systemów. Każda liczba w tej notacji ma konkretne znaczenie i bezpośrednio przekłada się na postać równania różnicowego modelu.

#### 4.4.1 Rozbicie notacji

Notacja **ARX(na, [nb1, nb2], [nk1, nk2])** składa się z trzech głównych komponentów:

**1. Pierwszy parametr (na = 2)** - **Rząd części autoregresyjnej**

- Określa liczbę przeszłych wartości wyjścia używanych w modelu
- `na = 2` oznacza, że model uwzględnia: $y(k-1)$ i $y(k-2)$
- Odpowiada wielomianowi: $A(q^{-1}) = 1 + a_1q^{-1} + a_2q^{-2}$
- W równaniu różnicowym daje składniki: $a_1y(k-1) + a_2y(k-2)$

**2. Drugi parametr ([nb1, nb2] = [2,2])** - **Rzędy wielomianów wejściowych**

- `nb1 = 2`: liczba przeszłych wartości pierwszego wejścia $u_1$
- `nb2 = 2`: liczba przeszłych wartości drugiego wejścia $u_2$
- Dla każdego wejścia uwzględniane są 2 próbki historyczne
- Odpowiada wielomianom:
  - $B_1(q^{-1}) = b_{10} + b_{11}q^{-1}$ (dla $u_1$)
  - $B_2(q^{-1}) = b_{20} + b_{21}q^{-1}$ (dla $u_2$)

**3. Trzeci parametr ([nk1, nk2] = [1,1])** - **Opóźnienia transportowe**

- `nk1 = 1`: minimalne opóźnienie dla pierwszego wejścia $u_1$
- `nk2 = 1`: minimalne opóźnienie dla drugiego wejścia $u_2$
- Oznacza, że wpływ zmian wejść obserwujemy z opóźnieniem 1 próbki (50ms)
- W równaniu: $u_1$ zaczyna działać od $u_1(k-1)$, a $u_2$ od $u_2(k-1)$

#### 4.4.2 Przekład na równanie różnicowe

Notacja **ARX(2,[2,2],[1,1])** przekłada się bezpośrednio na równanie różnicowe:

$$y(k) + a_1y(k-1) + a_2y(k-2) = b_{10}u_1(k-1) + b_{11}u_1(k-2) + b_{20}u_2(k-1) + b_{21}u_2(k-2) + e(k)$$

gdzie:

- **Część autoregresyjna**: $a_1y(k-1) + a_2y(k-2)$ (2 składniki, bo na=2)
- **Pierwszy kanał wejściowy**: $b_{10}u_1(k-1) + b_{11}u_1(k-2)$ (2 składniki z opóźnieniem od 1, bo nb1=2, nk1=1)
- **Drugi kanał wejściowy**: $b_{20}u_2(k-1) + b_{21}u_2(k-2)$ (2 składniki z opóźnieniem od 1, bo nb2=2, nk2=1)

#### 4.4.3 Interpretacja fizyczna dla silnika parowego

W kontekście **silnika parowego**, wybrana struktura ARX(2,[2,2],[1,1]) ma następujące uzasadnienie fizyczne:

**na = 2 (część autoregresyjna):**

- Silnik parowy ma **inercję mechaniczną i termiczną**
- Obecna wartość napięcia generatora zależy od dwóch poprzednich wartości
- Uwzględnia naturalną "pamięć" systemu wynikającą z bezwładności obrotowej

**nb1 = nb2 = 2 (rzędy wejść):**

- **Ciśnienie pary** ($u_1$): wpływa przez 2 próbki z powodu inercji termodynamicznej
- **Napięcie magnetyzacji** ($u_2$): wpływa przez 2 próbki z powodu inercji elektromagnetycznej
- Uwzględnia przejściowe charakterystyki układu

**nk1 = nk2 = 1 (opóźnienia):**

- **Czas propagacji sygnału** w systemie wynosi co najmniej 1 próbkę (50ms)
- Fizyczny czas reakcji między zmianą wejścia a obserwowalną zmianą wyjścia
- Uwzględnia czas potrzebny na przekształcenie energii w systemie

#### 4.4.4 Liczba parametrów do identyfikacji

Model ARX(2,[2,2],[1,1]) wymaga identyfikacji **6 parametrów**:

- $a_1, a_2$ (2 parametry autoregresyjne)
- $b_{10}, b_{11}$ (2 parametry dla pierwszego wejścia)
- $b_{20}, b_{21}$ (2 parametry dla drugiego wejścia)

Ogólnie: **liczba parametrów = na + nb1 + nb2 = 2 + 2 + 2 = 6**

#### 4.4.5 Przykłady innych struktur ARX

Dla porównania, inne popularne struktury i ich znaczenie:

- **ARX(1,[1,1],[1,1])**: 3 parametry, model najprostszy
- **ARX(3,[2,2],[1,1])**: 7 parametrów, więcej "pamięci" autoregresyjnej
- **ARX(2,[3,3],[1,1])**: 8 parametrów, dłuższa odpowiedź na wejścia
- **ARX(2,[2,2],[2,2])**: 6 parametrów, większe opóźnienia transportowe

Wybór struktury ARX(2,[2,2],[1,1]) dla silnika parowego jest **kompromisem** między:

- **Złożonością modelu** (liczba parametrów)
- **Zdolnością odwzorowania dynamiki** systemu
- **Stabilnością numeryczną** identyfikacji
- **Interpretowalnością fizyczną** parametrów

## 5. Identyfikacja parametrów metodą najmniejszych kwadratów

### 5.1 Sformułowanie problemu

Metoda najmniejszych kwadratów pozwala na znalezienie parametrów modelu poprzez minimalizację sumy kwadratów błędów między wyjściem modelu a rzeczywistymi pomiarami.

**Podstawy teoretyczne metody LS:**

- Metoda najmniejszych kwadratów (LS) szczegółowo opisana w **IdScw3.pdf** (sekcja 1: "Identyfikacja systemu statycznego metodą LS", równanie 1)
- Wsadowa parametryczna identyfikacja systemów w **IdScw3.pdf** (wprowadzenie do ćwiczenia C3)

Problem można sprowadzić do postaci macierzowej:

$$Y = \Phi\theta + e$$

gdzie:

- $Y$ - wektor obserwacji wyjścia $[y(start\_idx), y(start\_idx+1), ..., y(end\_idx)]^T$
- $\Phi$ - macierz regresorów (objaśniana poniżej)
- $\theta$ - wektor poszukiwanych parametrów $[a_1, a_2, ..., a_{na}, b_{10}, b_{11}, ..., b_{1,nb1-1}, b_{20}, b_{21}, ..., b_{2,nb2-1}]^T$
- $e$ - wektor błędów (reszt)

Kryterium jakości, które minimalizujemy ma postać:

$$J(\theta) = \sum_{t=start\_idx}^{end\_idx} e(t)^2 = e^T e = (Y - \Phi\theta)^T(Y - \Phi\theta)$$

#### 5.1.1 Szczegółowe wyjaśnienie wektorów

Aby w pełni zrozumieć metodę najmniejszych kwadratów, szczegółowo przeanalizujmy każdy z wektorów w równaniu $Y = \Phi\theta + e$:

##### A) Wektor obserwacji wyjścia Y

Wektor $Y$ zawiera **rzeczywiste pomiary wyjścia systemu** dla wszystkich chwil czasowych, dla których mamy kompletne dane historyczne:

$$
Y = \begin{bmatrix}
y(start\_idx) \\
y(start\_idx + 1) \\
y(start\_idx + 2) \\
\vdots \\
y(end\_idx)
\end{bmatrix}
$$

**Charakterystyka:**

- **Rozmiar**: $N_{eff} \times 1$, gdzie $N_{eff} = end\_idx - start\_idx + 1$
- **Zawartość**: Rzeczywiste wartości napięcia w generatorze (wyjście systemu)
- **start_idx**: Pierwsza chwila, dla której mamy wszystkie potrzebne dane historyczne
- **end_idx**: Ostatnia dostępna próbka danych

**Dlaczego nie zaczynamy od próbki 1?**

- Potrzebujemy danych historycznych: $y(k-1), y(k-2), u_1(k-1), u_1(k-2), u_2(k-1), u_2(k-2)$
- Dla modelu ARX(2,[2,2],[1,1]) pierwszy kompletny zestaw danych mamy dopiero w chwili $k = 3$
- Dlatego $start\_idx = max\_delay + 1 = 2 + 1 = 3$

**Przykład dla naszego modelu:**

```matlab
start_idx = 3;  % Pierwsza chwila z kompletnymi danymi
end_idx = N;    % Ostatnia próbka
Y_obs = y(start_idx:end_idx);  % Wektor obserwacji
```

##### B) Wektor poszukiwanych parametrów θ

Wektor $\theta$ zawiera **wszystkie nieznane parametry modelu ARX**, które chcemy wyznaczyć:

$$
\theta = \begin{bmatrix}
a_1 \\
a_2 \\
b_{10} \\
b_{11} \\
b_{20} \\
b_{21}
\end{bmatrix}
$$

**Interpretacja fizyczna parametrów:**

1. **Parametry autoregresyjne** $[a_1, a_2]$:

   - $a_1$: Wpływ wyjścia sprzed 1 próbki na aktualne wyjście
   - $a_2$: Wpływ wyjścia sprzed 2 próbek na aktualne wyjście
   - Opisują "pamięć" systemu i jego naturalną dynamikę

2. **Parametry pierwszego wejścia** $[b_{10}, b_{11}]$:

   - $b_{10}$: Bezpośredni wpływ ciśnienia pary z opóźnieniem 1 próbki
   - $b_{11}$: Wpływ ciśnienia pary z opóźnieniem 2 próbek
   - Opisują jak ciśnienie pary wpływa na napięcie generatora

3. **Parametry drugiego wejścia** $[b_{20}, b_{21}]$:
   - $b_{20}$: Bezpośredni wpływ napięcia magnetyzacji z opóźnieniem 1 próbki
   - $b_{21}$: Wpływ napięcia magnetyzacji z opóźnieniem 2 próbek
   - Opisują jak napięcie magnetyzacji wpływa na napięcie generatora

**Rozmiar**: $n_{params} \times 1 = (na + nb_1 + nb_2) \times 1 = 6 \times 1$

**To jest to, co szukamy!** - Celem identyfikacji jest znalezienie optymalnych wartości tych parametrów.

##### C) Wektor błędów (reszt) e

Wektor $e$ reprezentuje **różnicę między rzeczywistym wyjściem a przewidywaniami modelu**:

$$
e = Y - \Phi\theta = \begin{bmatrix}
y(start\_idx) - \hat{y}(start\_idx) \\
y(start\_idx + 1) - \hat{y}(start\_idx + 1) \\
\vdots \\
y(end\_idx) - \hat{y}(end\_idx)
\end{bmatrix}
$$

gdzie $\hat{y}(k)$ to przewidywanie modelu dla chwili $k$.

**Charakterystyka błędów:**

1. **Interpretacja fizyczna**:

   - $e(k) > 0$: Model przewiduje za niską wartość wyjścia
   - $e(k) < 0$: Model przewiduje za wysoką wartość wyjścia
   - $e(k) = 0$: Model idealnie przewiduje wyjście (rzadkie!)

2. **Właściwości idealnych reszt**:

   - **Średnia**: $E[e(k)] = 0$ (błędy nie powinny być systematyczne)
   - **Wariancja**: $Var[e(k)] = \sigma^2$ (stała wariancja)
   - **Autokorelacja**: $E[e(k)e(k+\tau)] = 0$ dla $\tau \neq 0$ (białym szum)
   - **Rozkład**: Idealnie normalny

3. **Co oznaczają duże błędy?**:
   - Model źle dopasowany do danych
   - Niewłaściwa struktura modelu (za mały rząd)
   - Nieliniowości w systemie
   - Zakłócenia w pomiarach

**Rozmiar**: $N_{eff} \times 1$ (taki sam jak wektor $Y$)

##### D) Związek między wektorami

Fundamentalne równanie identyfikacji:

$$\underbrace{Y}_{N_{eff} \times 1} = \underbrace{\Phi}_{N_{eff} \times n_{params}} \underbrace{\theta}_{n_{params} \times 1} + \underbrace{e}_{N_{eff} \times 1}$$

**Interpretacja macierzowa:**

- Każdy wiersz tego równania odpowiada jednej chwili czasowej
- Każda kolumna $\Phi$ odpowiada jednemu parametrowi
- Iloczyn $\Phi\theta$ daje przewidywania modelu $\hat{Y}$

**Przykład dla jednego wiersza (chwila k):**
$$y(k) = [-y(k-1), -y(k-2), u_1(k-1), u_1(k-2), u_2(k-1), u_2(k-2)] \begin{bmatrix} a_1 \\ a_2 \\ b_{10} \\ b_{11} \\ b_{20} \\ b_{21} \end{bmatrix} + e(k)$$

##### E) Implementacja w MATLAB

```matlab
% Definicja wektorów
Y_obs = y(start_idx:end_idx);           % Wektor obserwacji wyjścia
theta = zeros(n_params, 1);             % Wektor parametrów (początkowo nieznany)
e = zeros(N_eff, 1);                    % Wektor błędów (początkowo nieznany)

% Po estymacji parametrów:
theta = (Phi' * Phi) \ (Phi' * Y_obs);  % Rozwiązanie metodą najmniejszych kwadratów
y_model = Phi * theta;                  % Przewidywania modelu
e = Y_obs - y_model;                    % Obliczenie reszt
```

##### F) Praktyczny przykład numeryczny

Załóżmy, że mamy następujące dane dla pierwszych kilku próbek:

**Dane wejściowe i wyjściowe:**

```
k:     1    2    3    4    5    6
y(k):  0.1  0.3  0.8  1.2  1.0  0.7
u1(k): 0.5  1.0  1.5  1.2  0.8  0.5
u2(k): 0.2  0.4  0.6  0.5  0.3  0.2
```

**Dla start_idx = 3, end_idx = 6:**

**Wektor obserwacji Y:**
$$Y = \begin{bmatrix} 0.8 \\ 1.2 \\ 1.0 \\ 0.7 \end{bmatrix}$$
_(wyjścia dla k = 3, 4, 5, 6)_

**Macierz regresorów Φ:**

$$
\Phi = \begin{bmatrix}
-0.3 & -0.1 & 1.0 & 0.5 & 0.4 & 0.2 \\
-0.8 & -0.3 & 1.5 & 1.0 & 0.6 & 0.4 \\
-1.2 & -0.8 & 1.2 & 1.5 & 0.5 & 0.6 \\
-1.0 & -1.2 & 0.8 & 1.2 & 0.3 & 0.5
\end{bmatrix}
$$

gdzie kolumny odpowiadają: $[-y(k-1), -y(k-2), u_1(k-1), u_1(k-2), u_2(k-1), u_2(k-2)]$

**Wektor parametrów θ** (przykładowe wartości po identyfikacji):
$$\theta = \begin{bmatrix} -0.2 \\ 0.1 \\ 0.5 \\ 0.3 \\ 0.4 \\ 0.1 \end{bmatrix}$$
_(parametry: $a_1, a_2, b_{10}, b*{11}, b*{20}, b*{21}$)*

**Przewidywania modelu:**
$$\hat{Y} = \Phi \theta = \begin{bmatrix} 0.75 \\ 1.25 \\ 0.95 \\ 0.72 \end{bmatrix}$$

**Wektor błędów:**
$$e = Y - \hat{Y} = \begin{bmatrix} 0.05 \\ -0.05 \\ 0.05 \\ -0.02 \end{bmatrix}$$

**Interpretacja:**

- Błędy są małe (dobry model)
- Błędy oscylują wokół zera (brak systematycznych błędów)
- Model dobrze przewiduje zachowanie systemu

## 6. Walidacja i ocena jakości modelu

### 6.1 Miary dopasowania modelu

Do oceny jakości zidentyfikowanego modelu wykorzystano następujące wskaźniki:

- **FIT** - procentowy wskaźnik dopasowania modelu do danych, obliczany jako:

  $$FIT = \left(1 - \frac{\|y - \hat{y}\|}{\|y - \bar{y}\|}\right) \cdot 100\%$$

  gdzie:

  - $y$ - wektor rzeczywistych wartości wyjścia
  - $\hat{y}$ - wektor przewidywanych wartości wyjścia (model)
  - $\bar{y}$ - średnia wartość wyjścia
  - $\|\cdot\|$ - norma Euklidesowa wektora

  FIT = 100% oznacza idealne dopasowanie modelu do danych, natomiast FIT = 0% oznacza, że model działa nie lepiej niż średnia wartość.

- **MSE** (Mean Squared Error) - średni błąd kwadratowy:

  $$MSE = \frac{1}{N_{eff}} \sum_{t=start\_idx}^{end\_idx} (y(t) - \hat{y}(t))^2 = \frac{1}{N_{eff}} \sum_{t=start\_idx}^{end\_idx} e(t)^2$$

  MSE mierzy średnią kwadratów błędów między rzeczywistym wyjściem a przewidywaniami modelu. Niższe wartości MSE wskazują na lepsze dopasowanie modelu.

- **RMSE** (Root Mean Squared Error) - pierwiastek ze średniego błędu kwadratowego:

  $$RMSE = \sqrt{MSE} = \sqrt{\frac{1}{N_{eff}} \sum_{t=start\_idx}^{end\_idx} e(t)^2}$$

  RMSE ma tę zaletę, że jest wyrażony w tych samych jednostkach co sygnał wyjściowy, co ułatwia interpretację.

### 6.2 Obliczenie sygnału wyjściowego modelu

Na podstawie zidentyfikowanych parametrów $\hat{\theta}$ możemy obliczyć przewidywane wyjście modelu $\hat{y}(t)$ dla wszystkich chwil czasowych:

```matlab
% Obliczenie przewidywanego wyjścia modelu
y_model = zeros(N, 1);
y_model(1:max_delay) = y(1:max_delay);  % Warunki początkowe

% Dla części efektywnej danych możemy użyć macierzy regresorów
y_model(start_idx:end_idx) = Phi * theta;

% Obliczenie reszt
e = y - y_model;
```

Dla danych efektywnych (t = start_idx, ..., end_idx) wykorzystujemy macierz regresorów $\Phi$ i wektor parametrów $\hat{\theta}$. Dla początkowych próbek (t = 1, ..., max_delay), gdzie nie mamy wystarczających danych historycznych, używamy rzeczywistych wartości wyjścia jako warunków początkowych.

### 6.3 Wyniki walidacji

Uzyskane wskaźniki jakości modelu:

- FIT = (wartość zostanie uzupełniona po uruchomieniu skryptu) %
- MSE = (wartość zostanie uzupełniona po uruchomieniu skryptu)
- RMSE = (wartość zostanie uzupełniona po uruchomieniu skryptu)

### 6.4 Porównanie modelu z danymi rzeczywistymi

Poniżej przedstawiono porównanie wyjścia modelu z rzeczywistymi danymi pomiarowymi:

![Rys. 2: Porównanie modelu z danymi](porownanie_modelu.png)

_Rys. 2 Porównanie wyjścia modelu ARX z danymi rzeczywistymi oraz reszty modelu_

Analiza wizualna porównania modelu z danymi pozwala na:

1. Ocenę ogólnego dopasowania modelu do danych rzeczywistych
2. Identyfikację obszarów, gdzie model ma największe trudności z dopasowaniem
3. Wykrycie systematycznych błędów, które mogłyby wskazywać na nieprawidłową strukturę modelu

### 6.5 Analiza reszt

Dla poprawnie zidentyfikowanego modelu, reszty (błędy) powinny mieć charakter białego szumu o rozkładzie normalnym. Oznacza to, że:

1. Wartość oczekiwana reszt powinna być bliska zeru: $E[e(t)] \approx 0$
2. Reszty powinny być nieskorelowane w czasie: $E[e(t)e(t+\tau)] \approx 0$ dla $\tau \neq 0$
3. Wariancja reszt powinna być stała: $Var[e(t)] = \sigma^2$
4. Rozkład reszt powinien przypominać rozkład normalny

Jeśli te warunki nie są spełnione, może to wskazywać na:

- Niedopasowanie struktury modelu (np. zbyt niski rząd)
- Nieuwzględnienie ważnych zmiennych wejściowych
- Nieliniowości w systemie, których liniowy model ARX nie jest w stanie uchwycić

![Rys. 3: Histogram reszt](histogram_reszt.png)

_Rys. 3 Histogram reszt modelu_

Histogram reszt pozwala na wizualną ocenę, czy reszty mają rozkład zbliżony do rozkładu normalnego. Zbliżenie histogramu do kształtu dzwonu (rozkładu Gaussa) wskazuje na poprawność założeń modelu.

## 7. Analiza stabilności modelu

### 7.1 Stabilność systemu dyskretnego

System dyskretny opisany równaniem różnicowym jest stabilny BIBO (Bounded Input, Bounded Output) wtedy i tylko wtedy, gdy wszystkie bieguny jego transmitancji leżą wewnątrz koła jednostkowego na płaszczyźnie zespolonej, czyli gdy:

$$|z_i| < 1 \quad \forall i$$

gdzie $z_i$ są pierwiastkami równania charakterystycznego $A(z) = 0$.

### 7.2 Położenie biegunów

Stabilność modelu dyskretnego określa się na podstawie położenia biegunów - model jest stabilny, jeśli wszystkie bieguny leżą wewnątrz koła jednostkowego na płaszczyźnie zespolonej.

Dla modelu ARX równanie charakterystyczne ma postać:

$$A(z) = 1 + a_1z^{-1} + a_2z^{-2} + ... + a_{na}z^{-na} = 0$$

Aby znaleźć pierwiastki, przekształcamy równanie do postaci wielomianu:

$$z^{na} + a_1z^{na-1} + a_2z^{na-2} + ... + a_{na} = 0$$

Implementacja w MATLAB:

```matlab
% Sprawdzenie stabilności modelu
if na > 0
    A_poly = [1; a_coeffs];  % Wielomian A(z^-1)
    roots_A = roots(A_poly);
    stable = all(abs(roots_A) < 1);
else
    roots_A = [];
    stable = true;  % Model bez części AR jest zawsze stabilny
end
```

![Rys. 4: Bieguny modelu](bieguny_modelu.png)

_Rys. 4 Położenie biegunów modelu na płaszczyźnie zespolonej_

Analiza położenia biegunów na płaszczyźnie zespolonej dostarcza informacji o dynamice systemu:

1. **Bieguny rzeczywiste**:

   - Biegun rzeczywisty bliski +1: wolna dodatnia odpowiedź wykładnicza
   - Biegun rzeczywisty bliski -1: wolna oscylacyjna odpowiedź
   - Biegun rzeczywisty bliski 0: szybka odpowiedź wykładnicza

2. **Bieguny zespolone**:
   - Moduł bieguna określa szybkość zaniku odpowiedzi (im bliżej środka koła, tym szybszy zanik)
   - Argument bieguna określa częstotliwość oscylacji

### 7.3 Ocena stabilności

W wyniku analizy stwierdzono, że model jest (stabilny/niestabilny) - informacja zostanie uzupełniona po uruchomieniu skryptu.

### 7.4 Transmitancje modelu

Na podstawie zidentyfikowanych parametrów możemy wyznaczyć transmitancje dyskretne od poszczególnych wejść do wyjścia:

$$G_1(z^{-1}) = \frac{B_1(z^{-1})}{A(z^{-1})} = \frac{b_{10} + b_{11}z^{-1}}{1 + a_1z^{-1} + a_2z^{-2}}z^{-nk_1}$$

$$G_2(z^{-1}) = \frac{B_2(z^{-1})}{A(z^{-1})} = \frac{b_{20} + b_{21}z^{-1}}{1 + a_1z^{-1} + a_2z^{-2}}z^{-nk_2}$$

Transmitancje te opisują dynamikę systemu w dziedzinie dyskretnej i mogą być użyte do projektowania układów sterowania oraz do przeprowadzania symulacji.

## 8. Wnioski

Przeprowadzone ćwiczenie pozwoliło na identyfikację parametryczną modelu silnika parowego przy użyciu struktury ARX i metody najmniejszych kwadratów.

Główne wnioski:

1. Zidentyfikowany model ARX(2,[2,2],[1,1]) (osiągnął/nie osiągnął) założony cel dopasowania FIT > 85%.
2. Model wykazuje (dobrą/słabą) zgodność z danymi pomiarowymi.
3. Analiza reszt wskazuje na (odpowiedni/nieodpowiedni) dobór struktury modelu.
4. Zidentyfikowany model jest (stabilny/niestabilny), co świadczy o (poprawności/niepoprawności) identyfikacji.

### 8.1 Ograniczenia metody

Metoda identyfikacji z wykorzystaniem modelu ARX ma pewne ograniczenia:

1. **Założenie liniowości** - model ARX jest z założenia liniowy, więc nie będzie dobrze odwzorowywał nieliniowych zależności w systemie.
2. **Stacjonarność systemu** - metoda zakłada, że system jest stacjonarny (jego parametry nie zmieniają się w czasie).
3. **Struktura szumu** - model ARX zakłada, że szum wchodzi bezpośrednio do równania wyjścia, co może nie odpowiadać rzeczywistej strukturze zakłóceń w systemie.

### 8.2 Możliwe ulepszenia

Możliwe ulepszenia procedury identyfikacji obejmują:

1. **Testowanie różnych struktur modelu** - eksperymentowanie z różnymi wartościami parametrów na, nb1, nb2, nk1, nk2 w celu znalezienia optymalnej struktury.
2. **Zastosowanie bardziej zaawansowanych struktur** - np. modeli ARMAX, OE (Output Error), BJ (Box-Jenkins), które mogą lepiej modelować strukturę zakłóceń.
3. **Identyfikacja nieliniowa** - w przypadku, gdy model liniowy jest niewystarczający, można rozważyć metody identyfikacji nieliniowej, np. modele Hammerstaina-Wienera.
4. **Walidacja krzyżowa** - podział danych na zbiór uczący i testowy w celu lepszej oceny zdolności generalizacyjnych modelu.

## 9. Literatura

### 9.1 Mapa referencji do materiałów kursu

Poniżej przedstawiono szczegółowe mapowanie tematów omówionych w sprawozdaniu do odpowiednich materiałów dydaktycznych kursu:

#### **IdScw1.pdf - "Podstawowa analiza sygnałów"**

**Główne tematy:**

- Analiza sygnałów deterministycznych i losowych w dziedzinie czasu i częstotliwości
- Definicja procesów stochastycznych czasu dyskretnego
- Analiza korelacyjna i widmowa jako metody nieparametryczne

**Kluczowe równania i pojęcia:**

- **Równanie (1)**: Definicja procesu stochastycznego `{X(n)}n∈N={X(0),X(1),X(2),...}`
- Próbkowanie sygnałów: `x(nTp)` gdzie `Tp` to okres próbkowania
- Sekwencje skończone: `{x(n)}N−1 n=0`

**Zastosowanie w sprawozdaniu:**

- Sekcja 1: Podstawy analizy sygnałów w identyfikacji systemów
- Sekcja 3.2: Wizualizacja danych pomiarowych w dziedzinie czasu

#### **IdScw2.pdf - "Pozyskiwanie wiedzy wstępnej o systemie"**

**Główne tematy:**

- Deterministyczne i nieparametryczne metody identyfikacji
- Analiza odpowiedzi czasowych (odpowiedź skokowa, impulsowa)
- Charakterystyki Bodego
- Ocena rzędu i charakteru dynamiki systemu

**Kluczowe pojęcia:**

- **Sekcja 1**: "Identyfikacja poprzez analizę odpowiedzi czasowych"
- Sekwencje próbek odpowiedzi: `{h(nTp)}N−1 n=0`
- Transmitancja operatorowa `G(s)`
- Aproksymacja dynamiki systemów wysokiego rzędu

**Zastosowanie w sprawozdaniu:**

- Sekcja 3.2: Analiza wizualna danych pomiarowych
- Wstępna ocena charakteru dynamiki silnika parowego

#### **IdScw3.pdf - "Wsadowa parametryczna identyfikacja systemów"**

**Główne tematy:**

- Metoda najmniejszych kwadratów (LS)
- Metoda zmiennych instrumentalnych (IV)
- Modele typu GREY-BOX
- Identyfikacja systemów statycznych i dynamicznych

**Kluczowe równania:**

- **Równanie (1)**: Model systemu statycznego `y=fo(u,po) +v`
- Wektor parametrów: `po= [p1o p2o ... pdpo]T`
- Kryterium najmniejszych kwadratów
- Struktura modeli parametrycznych

**Zastosowanie w sprawozdaniu:**

- Sekcja 4: Struktura modelu ARX
- Sekcja 5: Identyfikacja parametrów metodą najmniejszych kwadratów
- Podstawy teoretyczne metody LS

#### **IdScw4.pdf - "Rekursywna parametryczna identyfikacja systemów"**

**Główne tematy:**

- Rekursywne wersje metod LS i IV (RLS, RIV)
- Algorytmy w czasie rzeczywistym
- Sterowanie adaptacyjne
- Diagnostyka uszkodzeń

**Kluczowe równania:**

- **Równanie (1)**: Postać regresyjna `y(n) =Go(q−1,po)u(n) +v*(n)⇒y(n) =φT(n)po+v(n)`
- Systemy dynamiczne czasu dyskretnego
- Iteracyjne algorytmy estymacji

**Zastosowanie w sprawozdaniu:**

- Sekcja 4.1: Równanie modelu ARX w postaci regresyjnej
- Sekcja 5: Sformułowanie macierzowe problemu identyfikacji
- Koncepcja wektora regresorów `φ(n)`

#### **Szczegółowa mapa tematów:**

| **Temat w sprawozdaniu**          | **Plik PDF**           | **Lokalizacja**        | **Opis**                               |
| --------------------------------- | ---------------------- | ---------------------- | -------------------------------------- |
| Definicja procesu stochastycznego | IdScw1.pdf             | Równanie (1)           | Podstawy matematyczne analizy sygnałów |
| Analiza odpowiedzi czasowych      | IdScw2.pdf             | Sekcja 1               | Metody deterministyczne identyfikacji  |
| Analiza korelacyjna               | IdScw1.pdf, IdScw2.pdf | Całość                 | Nieparametryczne metody identyfikacji  |
| Metoda najmniejszych kwadratów    | IdScw3.pdf             | Sekcja 1, równanie (1) | Podstawy teoretyczne LS                |
| Model parametryczny               | IdScw3.pdf             | Wprowadzenie           | Struktury GREY-BOX                     |
| Postać regresyjna                 | IdScw4.pdf             | Równanie (1)           | Matematyczne sformułowanie modelu ARX  |
| Wsadowa identyfikacja             | IdScw3.pdf             | Tytuł ćwiczenia        | Wykorzystanie całego wsadu danych      |
| Systemy MISO                      | IdScw3.pdf, IdScw4.pdf | Przykłady              | Systemy wielowejściowe                 |
| Stabilność systemów               | IdScw2.pdf             | Charakterystyki        | Ocena właściwości dynamicznych         |
| Transmitancje operatorowe         | IdScw2.pdf             | Sekcja 1               | Opis dynamiki w dziedzinie s           |

### 9.2 Bibliografia

1. Söderström T., Stoica P.: _System Identification_. Prentice Hall, 1989.
2. Ljung L.: _System Identification: Theory for the User_. Prentice Hall, 1999.
3. Norton J.P.: _An Introduction to Identification_. Academic Press, 1986.
4. Materiały dydaktyczne z przedmiotu "Identyfikacja systemów": IdScw1.pdf, IdScw2.pdf, IdScw3.pdf, IdScw4.pdf.
5. Isermann R., Münchhof M.: _Identification of Dynamic Systems: An Introduction with Applications_. Springer, 2011.
6. Nelles O.: _Nonlinear System Identification: From Classical Approaches to Neural Networks and Fuzzy Models_. Springer, 2001.

## Dodatek A: Implementacja w MATLAB

Poniżej zamieszczono kluczowe fragmenty implementacji w MATLAB, które realizują identyfikację modelu ARX metodą najmniejszych kwadratów:

```matlab
%% 5. Identyfikacja modelu ARX
% Parametry modelu
na = 2;     % Rząd części autoregresyjnej
nb1 = 2;    % Rząd dla pierwszego wejścia
nb2 = 2;    % Rząd dla drugiego wejścia
nk1 = 1;    % Opóźnienie dla pierwszego wejścia
nk2 = 1;    % Opóźnienie dla drugiego wejścia

% Obliczenie maksymalnego opóźnienia
max_delay = max([na, nb1+nk1-1, nb2+nk2-1]);

% Ustalenie indeksów dla efektywnych danych
start_idx = max_delay + 1;
end_idx = N;
N_eff = end_idx - start_idx + 1;

% Liczba parametrów modelu
n_params = na + nb1 + nb2;

% Inicjalizacja macierzy regresorów i wektora obserwacji
Phi = zeros(N_eff, n_params);
Y_obs = y(start_idx:end_idx);

% Budowa macierzy regresorów
for i = 1:N_eff
    t = start_idx + i - 1;
    row = [];

    % Część autoregresyjna [-y(t-1), -y(t-2), ..., -y(t-na)]
    for j = 1:na
        row = [row, -y(t-j)];
    end

    % Część dla wejścia u1
    for j = 0:nb1-1
        row = [row, u1(t-nk1-j)];
    end

    % Część dla wejścia u2
    for j = 0:nb2-1
        row = [row, u2(t-nk2-j)];
    end

    Phi(i, :) = row;
end

% Estymacja parametrów metodą najmniejszych kwadratów
theta = (Phi' * Phi) \ (Phi' * Y_obs);

% Obliczenie przewidywanego wyjścia modelu
y_model = zeros(N, 1);
y_model(1:max_delay) = y(1:max_delay);  % Warunki początkowe
y_model(start_idx:end_idx) = Phi * theta;

% Obliczenie reszt
e = y - y_model;

% Obliczenie wskaźników jakości
mse = mean(e(start_idx:end_idx).^2);
rmse = sqrt(mse);
fit_percent = (1 - norm(e(start_idx:end_idx)) / norm(Y_obs - mean(Y_obs))) * 100;
```

## Dodatek B: Zagadnienia do samodzielnego rozwiązania

1. Jak zmieniłby się wskaźnik dopasowania FIT, gdybyśmy zwiększyli rząd części autoregresyjnej (na) do 3?
2. Jakie wartości parametrów na, nb1, nb2, nk1, nk2 byłyby optymalne dla badanego silnika parowego?
3. Jak można by zmodyfikować metodę estymacji, aby uwzględnić różne wagi dla różnych części danych pomiarowych?
4. Jakie inne metody identyfikacji (poza ARX i metodą najmniejszych kwadratów) mogłyby być wykorzystane do identyfikacji badanego układu?
5. Jak wpływa okres próbkowania Tp na jakość identyfikacji i na stabilność zidentyfikowanego modelu?
