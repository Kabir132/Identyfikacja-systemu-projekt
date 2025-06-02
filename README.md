# Szczegółowy Opis Metodologii Identyfikacji Systemu S01-S11

## Identyfikacja Laboratoryjnego Modelu Silnika Parowego

### Wprowadzenie

Niniejszy dokument zawiera szczegółowy opis działania i wnioskowania z kompletnej implementacji metodologii identyfikacji systemu według standardu S01-S11 dla laboratoryjnego modelu silnika parowego. Skrypt implementuje pełną procedurę identyfikacji systemu MISO (Multiple Input Single Output) w środowisku MATLAB.

---

## **S01: OKREŚLENIE CELU MODELOWANIA EKSPERYMENTALNEGO**

### Cel i założenia:

- **Główny cel**: Uzyskanie symulatora laboratoryjnego modelu silnika parowego
- **Kryterium jakości**: J_FIT > 85% (wskaźnik dopasowania modelu)
- **Przeznaczenie**: Cele edukacyjne i analiza dynamiki systemu MISO
- **Typ zastosowania**: Symulator do nauki teorii sterowania

### Wnioskowanie S01:

Etap ten ustala jasne ramy projektu identyfikacji. Kryterium 85% jest wysokie ale osiągalne dla systemu liniowego. Cel edukacyjny oznacza, że model musi być interpretowalny i zrozumiały, co uzasadnia wybór modelu ARX.

---

## **S02: WIEDZA A PRIORI O SYSTEMIE**

### Charakterystyka systemu:

```
System: Laboratoryjny model silnika parowego
Typ: MISO (Multiple Input Single Output)
Wejścia:
  - u1: ciśnienie pary za zaworem sterującym
  - u2: napięcie magnetyzacji generatora
Wyjście:
  - y: napięcie w generatorze
Parametry czasowe:
  - Okres próbkowania: Tp = 50ms (20 Hz)
  - Oczekiwana dynamika: 2. rząd (system elektromechaniczny)
```

### Wnioskowanie S02:

- **Fizyka systemu**: Elektromechaniczny charakter sugeruje dynamikę 2. rzędu
- **Próbkowanie**: 20 Hz jest odpowiednie dla systemów mechanicznych (zazwyczaj < 5 Hz)
- **Nieliniowości**: Prawdopodobnie nieznaczne przy małych sygnałach
- **MISO**: Dwa niezależne wejścia wpływają na jedno wyjście

---

## **S03: POZYSKANIE DODATKOWEJ WIEDZY - ANALIZA WSTĘPNA**

### S03(a): Ogląd danych pomiarowych

#### Implementacja:

```matlab
% Wczytanie danych z pliku .mat
dane = load('dane.mat');
u1 = dane.in1(:);   % ciśnienie za zaworem
u2 = dane.in2(:);   % napięcie magnetyzacji
y = dane.out(:);    % napięcie generatora
N = length(y);      % liczba próbek
```

#### Wizualizacja:

- **Wykres czasowy u1**: Przebieg ciśnienia pary za zaworem
- **Wykres czasowy u2**: Przebieg napięcia magnetyzacji generatora
- **Wykres czasowy y**: Przebieg napięcia wyjściowego generatora

#### Statystyki podstawowe:

Dla każdego sygnału obliczane są:

- Wartość średnia (poziom pracy)
- Odchylenie standardowe (amplituda zmian)
- Zakres wartości (min, max)

### S03(b): Analiza korelacji krzyżowej

#### Metodologia obliczania:

```matlab
% Przygotowanie danych (usunięcie składowej stałej)
D1 = [y - mean(y), u1 - mean(u1)];
D2 = [y - mean(y), u2 - mean(u2)];

% Obliczanie korelacji przy różnych opóźnieniach τ
for i = 1:length(lags)
    tau = lags(i);

    % Korelacja y vs u1
    cov_yu1 = Covar(D1, tau, 'N_tau');
    r1(i) = cov_yu1 / (std_y * std_u1);

    % Korelacja y vs u2
    cov_yu2 = Covar(D2, tau, 'N_tau');
    r2(i) = cov_yu2 / (std_y * std_u2);
end
```

#### Analiza wyników korelacji:

1. **Maksima korelacji**: Określają opóźnienia transportowe systemu
2. **Kształt korelacji**: Wskazuje na dynamikę systemu
3. **Szerokość piku**: Informuje o stałych czasowych

#### Wnioskowanie z korelacji:

- **optimal_lag_u1**: Opóźnienie transportowe od u1 do y
- **optimal_lag_u2**: Opóźnienie transportowe od u2 do y
- **max_corr_u1/u2**: Siła wpływu poszczególnych wejść

### S03(c): Szacowanie wzmocnienia statycznego

#### Metoda:

```matlab
% Wzmocnienie jako stosunek odchyleń standardowych z uwzględnieniem znaku
gain_u1_est = std(y) / std(u1) * sign(mean(r1));
gain_u2_est = std(y) / std(u2) * sign(mean(r2));
```

#### Szacowanie rzędów modelu:

```matlab
% Próg znaczności (10% maksimum)
threshold_u1 = 0.1 * max_corr_u1;
significant_lags_u1 = lags(abs(r1) > threshold_u1);
suggested_nb1 = max(1, max(significant_lags_u1(significant_lags_u1 > 0)));
```

### Wnioskowanie S03:

- **Jakość danych**: Statystyki pokazują czy dane są odpowiednie
- **Dynamika**: Korelacje ujawniają rzędy i opóźnienia
- **Wzmocnienia**: Pierwsze oszacowanie parametrów statycznych
- **Struktura modelu**: Sugerowane rzędy nb1, nb2

---

## **S04: DECYZJA A - TYP IDENTYFIKACJI**

### Wybór: BLACK-BOX

#### Uzasadnienie:

- Brak szczegółowej wiedzy o strukturze wewnętrznej silnika parowego
- Skupienie na zachowaniu wejście-wyjście
- Wystarczająca dokładność dla celów symulacyjnych
- Prostota implementacji i interpretacji

### Wnioskowanie S04:

Decyzja BLACK-BOX jest uzasadniona celami projektu. Dla symulatora edukacyjnego ważniejsze jest dobre odwzorowanie dynamiki niż zrozumienie fizyki wewnętrznej.

---

## **S05: DECYZJA B - WYBÓR KLASY I STRUKTURY MODELU**

### Wybór: Model ARX w dziedzinie dyskretnej

#### Uzasadnienie:

- **Dane próbkowane**: Tp = 50ms → dziedzina dyskretna naturalna
- **Metoda LS**: Łatwa implementacja algorytmu najmniejszych kwadratów
- **Liniowość**: Model ARX odpowiedni dla systemów liniowych
- **Prostota**: Łatwy w analizie i implementacji

#### Struktura modelu ARX:

```
A(z^-1) * y(n) = B1(z^-1) * u1(n) + B2(z^-1) * u2(n) + e(n)

gdzie:
A(z^-1) = 1 + a1*z^-1 + a2*z^-2 + ... + ana*z^-na
B1(z^-1) = b11*z^-1 + b12*z^-2 + ... + b1nb1*z^-nb1
B2(z^-1) = b21*z^-1 + b22*z^-2 + ... + b2nb2*z^-nb2
```

### Wnioskowanie S05:

Model ARX to kompromis między prostotą a dokładnością. Dla systemu MISO elektromechanicznego jest to odpowiedni wybór.

---

## **S06: ANALIZA SYGNAŁU POBUDZAJĄCEGO I OKRESU PRÓBKOWANIA**

### Analiza widmowa sygnałów:

#### FFT wszystkich sygnałów:

```matlab
f = (0:N/2-1)/(N*Tp);  % wektor częstotliwości
U1_fft = fft(u1);      % widmo u1
U2_fft = fft(u2);      % widmo u2
Y_fft = fft(y);        % widmo y
```

#### Analiza autokorelacji:

```matlab
[r_u1, lags_auto] = xcorr(u1, 50, 'normalized');
```

#### Ocena jakości pobudzenia:

```matlab
freq_content_u1 = sum(abs(U1_fft(1:N/2)).^2);  % energia widmowa u1
freq_content_u2 = sum(abs(U2_fft(1:N/2)).^2);  % energia widmowa u2
```

### Wnioskowanie S06:

- **Szerokość widma**: Sprawdza czy sygnały pobudzają odpowiedni zakres częstotliwości
- **Autokorelacja**: Ocenia "białość" sygnału pobudzającego
- **Tp**: Potwierdza odpowiedność okresu próbkowania względem dynamiki systemu

---

## **S07: PODZIAŁ DANYCH**

### Strategia podziału:

```matlab
split_ratio = 0.7;              % 70% na estymację
N_est = round(N * split_ratio); % liczba próbek estymacyjnych
N_ver = N - N_est;              % liczba próbek weryfikacyjnych

% Podział chronologiczny (nie losowy!)
u1_est = u1(1:N_est);           % dane estymacyjne u1
u2_est = u2(1:N_est);           % dane estymacyjne u2
y_est = y(1:N_est);             % dane estymacyjne y

u1_ver = u1(N_est+1:end);       % dane weryfikacyjne u1
u2_ver = u2(N_est+1:end);       % dane weryfikacyjne u2
y_ver = y(N_est+1:end);         % dane weryfikacyjne y
```

### Wnioskowanie S07:

- **Podział chronologiczny**: Zachowuje właściwości czasowe sygnałów
- **Proporcja 70/30**: Standard w uczeniu maszynowym
- **Niezależność**: Dane weryfikacyjne nie są używane w estymacji

---

## **S08: WYBÓR METODY IDENTYFIKACJI**

### Wybór: Metoda najmniejszych kwadratów (LS)

#### Uzasadnienie:

- **Analityczne rozwiązanie**: θ = (ΦᵀΦ)⁻¹ΦᵀY
- **Optimalność**: Minimalizuje błąd średniokwadratowy dla modeli liniowych
- **Prostota implementacji**: Jeden krok obliczeniowy
- **Gwarancja zbieżności**: Zawsze daje rozwiązanie (jeśli Φ ma pełny rząd)

### Wnioskowanie S08:

LS to naturalna metoda dla modeli ARX. Daje optymalne oszacowanie w sensie minimum wariancji (przy założeniu białego szumu).

---

## **S09: OBLICZENIE ESTYMAT PARAMETRÓW**

### Wybór rzędów modelu:

```matlab
na = 2;                         % rząd autoregresyjny (z wiedzy a priori)
nb1 = min(suggested_nb1, 7);    % rząd dla u1 (z analizy korelacji)
nb2 = min(suggested_nb2, 3);    % rząd dla u2 (z analizy korelacji)
```

### Konstrukcja macierzy regresorów:

```matlab
% Określenie początku obliczeń
n_max = max([na, nb1, nb2]);
nStart = n_max + 1;
N_reg = N_est - nStart + 1;

% Macierz regresorów Φ i wektor wyjść Y
Phi_est = zeros(N_reg, na + nb1 + nb2);
Y_est = y_est(nStart:end);

for i = 1:N_reg
    n = i + nStart - 1;
    % Składowe autoregresyjne (przeszłe wyjścia)
    Phi_est(i, 1:na) = -y_est(n-1:-1:n-na)';
    % Składowe od u1 (przeszłe wejścia u1)
    Phi_est(i, na+1:na+nb1) = u1_est(n-1:-1:n-nb1)';
    % Składowe od u2 (przeszłe wejścia u2)
    Phi_est(i, na+nb1+1:end) = u2_est(n-1:-1:n-nb2)';
end
```

### Rozwiązanie LS:

```matlab
theta = Phi_est \ Y_est;  % Rozwiązanie układu równań liniowych
```

### Struktura wektora parametrów θ:

```
θ = [a1, a2, ..., ana, b11, b12, ..., b1nb1, b21, b22, ..., b2nb2]ᵀ

gdzie:
- a1, a2, ..., ana      : parametry autoregresyjne
- b11, b12, ..., b1nb1  : parametry wejścia u1
- b21, b22, ..., b2nb2  : parametry wejścia u2
```

### Obliczenie macierzy kowariancji:

```matlab
sigma2_est = norm(Y_est - Phi_est*theta)^2 / (N_reg - length(theta));
Cov_theta = sigma2_est * inv(Phi_est' * Phi_est);
```

### Wnioskowanie S09:

- **Macierz Φ**: Zawiera wszystkie przeszłe wartości wejść i wyjść
- **Układ równań**: Y = Φθ + e → rozwiązywany względem θ
- **Estymator LS**: θ̂ = (ΦᵀΦ)⁻¹ΦᵀY
- **Wariancja**: σ² szacuje moc szumu pomiarowego

---

## **S10: WERYFIKACJA MODELU**

### S10(I): Symulacja na danych estymacyjnych

#### Algorytm symulacji:

```matlab
y_pred_est = zeros(N_est, 1);
y_pred_est(1:nStart-1) = y_est(1:nStart-1);  % warunki początkowe

for n = nStart:N_est
    % Składowe autoregresyjne (z predykowanych wartości!)
    y_pred_est(n) = -theta(1:na)' * y_pred_est(n-1:-1:n-na);
    % Składowe od u1 (z rzeczywistych wartości)
    y_pred_est(n) = y_pred_est(n) + theta(na+1:na+nb1)' * u1_est(n-1:-1:n-nb1);
    % Składowe od u2 (z rzeczywistych wartości)
    y_pred_est(n) = y_pred_est(n) + theta(na+nb1+1:end)' * u2_est(n-1:-1:n-nb2);
end
```

#### Wskaźnik jakości J_FIT:

```matlab
err_est = y_est(nStart:end) - y_pred_est(nStart:end);
J_FIT_est = 100 * (1 - norm(err_est) / norm(y_est(nStart:end) - mean(y_est(nStart:end))));
```

**Interpretacja J_FIT:**

- J_FIT = 100% → model idealny
- J_FIT = 0% → model nie lepszy niż wartość średnia
- J_FIT < 0% → model gorszy niż wartość średnia

### S10(II): Weryfikacja na danych niezależnych

#### Symulacja weryfikacyjna:

```matlab
for n = start_ver:N_ver
    if n <= na
        % Specjalne traktowanie początkowych próbek
        y_past = [y_pred_ver(n-1:-1:1); zeros(na-(n-1), 1)];
        y_past = y_past(1:na);
    else
        y_past = y_pred_ver(n-1:-1:n-na);
    end

    y_pred_ver(n) = -theta(1:na)' * y_past;

    if n > nb1
        y_pred_ver(n) = y_pred_ver(n) + theta(na+1:na+nb1)' * u1_ver(n-1:-1:n-nb1);
    end
    if n > nb2
        y_pred_ver(n) = y_pred_ver(n) + theta(na+nb1+1:end)' * u2_ver(n-1:-1:n-nb2);
    end
end
```

### Analiza reszt:

#### Wykresy diagnostyczne:

1. **Reszty w czasie**: Sprawdza stacjonarność błędów
2. **Histogram reszt**: Sprawdza normalność rozkładu błędów
3. **Porównanie J_FIT**: Estymacja vs weryfikacja

### Wnioskowanie S10:

- **Symulacja wolna**: Używa tylko predykowanych wyjść → test prawdziwej jakości modelu
- **Dane niezależne**: Prawdziwy test generalizacji modelu
- **Analiza reszt**: Sprawdza założenia statystyczne

---

## **S11: DECYZJA KOŃCOWA**

### Kryteria akceptacji:

#### 1. Kryterium jakości:

```matlab
if J_FIT_est >= target_JFIT  % >= 85%
    if J_FIT_ver >= target_JFIT - 10  % >= 75% (nieco łagodniejsze)
        model_acceptable = true;
    end
end
```

#### 2. Kryterium stabilności:

```matlab
A_poly = [1, theta(1:na)'];  % wielomian charakterystyczny A(z)
poles = roots(A_poly);       % bieguny systemu
stable = all(abs(poles) < 1); % wszystkie bieguny w kole jednostkowym
```

### Analiza biegunów:

- **|z| < 1**: biegun stabilny
- **|z| = 1**: biegun graniczny (oscylacje stałe)
- **|z| > 1**: biegun niestabilny (rozbieżność)

### Transmitancje systemu:

#### Transmitancja G1(z) (od u1 do y):

```
G1(z) = B1(z⁻¹)/A(z⁻¹) = (b11·z⁻¹ + b12·z⁻² + ... + b1nb1·z⁻ⁿᵇ¹)/(1 + a1·z⁻¹ + a2·z⁻² + ... + ana·z⁻ⁿᵃ)
```

#### Transmitancja G2(z) (od u2 do y):

```
G2(z) = B2(z⁻¹)/A(z⁻¹) = (b21·z⁻¹ + b22·z⁻² + ... + b2nb2·z⁻ⁿᵇ²)/(1 + a1·z⁻¹ + a2·z⁻² + ... + ana·z⁻ⁿᵃ)
```

### Zapisanie wyników:

```matlab
save('model_results.mat', 'theta', 'na', 'nb1', 'nb2', 'J_FIT_est', 'J_FIT_ver', ...
     'poles', 'sigma2_est', 'Tp');
```

### Możliwe decyzje:

#### ✅ MODEL AKCEPTOWALNY:

- J_FIT ≥ 85% na danych estymacyjnych
- J_FIT ≥ 75% na danych weryfikacyjnych
- Wszystkie bieguny stabilne
- Model gotowy jako symulator

#### ❌ MODEL NIEAKCEPTOWALNY:

**Możliwe przyczyny i działania:**

1. **Niska jakość**: Zmiana rzędów modelu (na, nb1, nb2)
2. **Niestabilność**: Zmiana struktury na ARMAX/OE
3. **Przeuczenie**: Więcej danych weryfikacyjnych
4. **Złe dane**: Weryfikacja jakości pomiarów

### Wnioskowanie S11:

- **Kryteria obiektywne**: Jasne progi akceptacji
- **Analiza stabilności**: Kluczowa dla bezpieczeństwa zastosowań
- **Interpretacja fizyczna**: Transmitancje łączą model z fizyką systemu
- **Dokumentacja**: Pełne zapisanie wyników dla przyszłych analiz

---

## **PODSUMOWANIE METODOLOGII**

### Zalety implementacji S01-S11:

1. **Systematyczność**: Każdy krok logicznie wynika z poprzedniego
2. **Obiektywność**: Kryteria liczbowe zamiast subiektywnych ocen
3. **Kompleksowość**: Pełna ścieżka od danych do gotowego modelu
4. **Weryfikowalność**: Możliwość powtórzenia i walidacji wyników
5. **Edukacyjność**: Jasne zrozumienie każdego etapu procesu

### Kluczowe decyzje projektowe:

1. **BLACK-BOX + ARX**: Kompromis prostota-dokładność
2. **Dziedzina dyskretna**: Naturalna dla danych próbkowanych
3. **Metoda LS**: Optymalna dla modeli liniowych
4. **Podział 70/30**: Standard walidacji krzyżowej
5. **Kryteria 85%/75%**: Realistyczne progi jakości

### Ograniczenia metodologii:

1. **Liniowość**: ARX nie radzi sobie z silnymi nieliniowościami
2. **Stacjonarność**: Założenie stałych parametrów w czasie
3. **Biały szum**: Założenie nieskorelowanych błędów
4. **Ręczny wybór rzędów**: Brak automatycznej optymalizacji struktury

### Możliwe rozszerzenia:

1. **Walidacja krzyżowa**: Wielokrotny podział danych
2. **Kryteria informacyjne**: AIC/BIC do wyboru rzędów
3. **Analiza wrażliwości**: Wpływ zaburzeń parametrów
4. **Modele adaptacyjne**: Śledzenie zmian parametrów

---

## **WNIOSKI KOŃCOWE**

Przedstawiona implementacja metodologii S01-S11 stanowi kompletny, profesjonalny przykład identyfikacji systemu. Kod jest dobrze udokumentowany, strukturalnie przejrzysty i implementuje najlepsze praktyki inżynierii systemów.

Metodologia jest szczególnie wartościowa w celach edukacyjnych, ponieważ:

- Każdy krok jest uzasadniony teorią
- Wyniki są wizualizowane i interpretowane
- Kryteria akceptacji są jasno zdefiniowane
- Kod może być łatwo modyfikowany i rozszerzany

System silnika parowego okazuje się dobrym przykładem zastosowania, łącząc theory z praktyką i pokazując pełny cykl życia projektu identyfikacji systemu.
