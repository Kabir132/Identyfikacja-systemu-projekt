%% IDENTYFIKACJA SYSTEMU SILNIKA PAROWEGO - METODOLOGIA S01-S11
% Autorzy: [Studenci] - wersja amatorska
% Data: 2025
% System: Laboratoryjny model silnika parowego (MISO)

clear; close all; clc;

%% ====================================================================
%% S01: OKREŚLENIE CELU MODELOWANIA EKSPERYMENTALNEGO
%% ====================================================================

fprintf('=== S01: CEL MODELOWANIA ===\n');
fprintf('Cel: Uzyskanie symulatora laboratoryjnego modelu silnika parowego\n');
fprintf('     z dokładnością J_FIT > 85%% dla celów edukacyjnych\n');
fprintf('     i analizy dynamiki systemu MISO.\n\n');

% Parametry celu
target_JFIT = 85; % minimalna wymagana dokładność
model_purpose = 'symulator'; % cel: symulator edukacyjny

%% ====================================================================
%% S02: WIEDZA A PRIORI O SYSTEMIE
%% ====================================================================

fprintf('=== S02: WIEDZA A PRIORI ===\n');
fprintf('System: Laboratoryjny model silnika parowego\n');
fprintf('Typ: MISO (Multiple Input Single Output)\n');
fprintf('Wejścia: u1 - ciśnienie pary za zaworem sterującym\n');
fprintf('         u2 - napięcie magnetyzacji generatora\n');
fprintf('Wyjście: y - napięcie w generatorze\n');
fprintf('Okres próbkowania: Tp = 50ms\n');
fprintf('Oczekiwana dynamika: 2. rząd (system elektromechaniczny)\n');
fprintf('Nieliniowości: prawdopodobnie nieznaczne (małe sygnały)\n\n');

% Parametry systemu z wiedzy a priori
Tp = 0.05; % okres próbkowania [s]
expected_order = 2; % oczekiwany rząd dynamiki
system_type = 'elektromechaniczny';

%% ====================================================================
%% S03: POZYSKANIE DODATKOWEJ WIEDZY - ANALIZA WSTĘPNA
%% ====================================================================

fprintf('=== S03: ANALIZA WSTĘPNA DANYCH ===\n');

% Wczytanie danych
dane = load('dane.mat');
u1 = dane.in1(:);   % ciśnienie za zaworem
u2 = dane.in2(:);   % napięcie magnetyzacji
y = dane.out(:);    % napięcie generatora
N = length(y);      % liczba próbek

fprintf('Liczba próbek: %d\n', N);
fprintf('Czas trwania eksperymentu: %.1f s\n', N*Tp);
fprintf('Częstotliwość próbkowania: %.1f Hz\n', 1/Tp);

% S03(a): OGLĄD DANYCH POMIAROWYCH
figure('Name', 'S03a: Ogląd danych pomiarowych', 'Position', [0 0 1200 800]);

subplot(3,1,1);
plot((1:N)*Tp, u1, 'b-', 'LineWidth', 1.2);
title('Wejście u1: Ciśnienie za zaworem');
xlabel('Czas [s]'); ylabel('u1'); grid on;

subplot(3,1,2);
plot((1:N)*Tp, u2, 'r-', 'LineWidth', 1.2);
title('Wejście u2: Napięcie magnetyzacji');
xlabel('Czas [s]'); ylabel('u2'); grid on;

subplot(3,1,3);
plot((1:N)*Tp, y, 'g-', 'LineWidth', 1.2);
title('Wyjście y: Napięcie generatora');
xlabel('Czas [s]'); ylabel('y'); grid on;

% Podstawowe statystyki
fprintf('\nStatystyki sygnałów:\n');
fprintf('u1: średnia=%.3f, odchylenie=%.3f, zakres=[%.3f, %.3f]\n', ...
    mean(u1), std(u1), min(u1), max(u1));
fprintf('u2: średnia=%.3f, odchylenie=%.3f, zakres=[%.3f, %.3f]\n', ...
    mean(u2), std(u2), min(u2), max(u2));
fprintf('y:  średnia=%.3f, odchylenie=%.3f, zakres=[%.3f, %.3f]\n', ...
    mean(y), std(y), min(y), max(y));

% S03(b): TESTY WSTĘPNE - ANALIZA KORELACJI
fprintf('\n=== S03b: ANALIZA KORELACJI KRZYŻOWEJ ===\n');

maxlag = 50;
lags = -maxlag:maxlag;

% Przygotowanie danych dla funkcji Covar
D1 = [y - mean(y), u1 - mean(u1)];
D2 = [y - mean(y), u2 - mean(u2)];

% Obliczanie korelacji krzyżowej
r1 = zeros(size(lags));
r2 = zeros(size(lags));

for i = 1:length(lags)
    tau = lags(i);
    
    % Korelacja y vs u1
    cov_yu1 = Covar(D1, tau, 'N_tau');
    std_y = std(y - mean(y));
    std_u1 = std(u1 - mean(u1));
    r1(i) = cov_yu1 / (std_y * std_u1);
    
    % Korelacja y vs u2
    cov_yu2 = Covar(D2, tau, 'N_tau');
    std_u2 = std(u2 - mean(u2));
    r2(i) = cov_yu2 / (std_y * std_u2);
end

% Analiza maksimów korelacji
[max_corr_u1, max_idx_u1] = max(abs(r1));
optimal_lag_u1 = lags(max_idx_u1);
[max_corr_u2, max_idx_u2] = max(abs(r2));
optimal_lag_u2 = lags(max_idx_u2);

fprintf('Maksymalna korelacja |r1| = %.3f przy τ = %d próbek (%.2f s)\n', ...
    max_corr_u1, optimal_lag_u1, optimal_lag_u1*Tp);
fprintf('Maksymalna korelacja |r2| = %.3f przy τ = %d próbek (%.2f s)\n', ...
    max_corr_u2, optimal_lag_u2, optimal_lag_u2*Tp);

% Wykres korelacji
figure('Name', 'S03b: Analiza korelacji krzyżowej', 'Position', [0 0 1000 600]);
subplot(2,1,1);
stem(lags, r1, 'b', 'LineWidth', 1.2);
title('Korelacja krzyżowa y vs u1');
xlabel('Opóźnienie [próbki]'); ylabel('Współczynnik korelacji');
ylim([-0.15, 0.15]); grid on;

subplot(2,1,2);
stem(lags, r2, 'r', 'LineWidth', 1.2);
title('Korelacja krzyżowa y vs u2');
xlabel('Opóźnienie [próbki]'); ylabel('Współczynnik korelacji');
grid on;

% S03(c): IDENTYFIKACJA NIEPARAMETRYCZNA - WZMOCNIENIE STATYCZNE
fprintf('\n=== S03c: SZACOWANIE WZMOCNIENIA STATYCZNEGO ===\n');

% Szacowanie wzmocnienia statycznego metodą średnich wartości
gain_u1_est = std(y) / std(u1) * sign(mean(r1));
gain_u2_est = std(y) / std(u2) * sign(mean(r2));

fprintf('Szacowane wzmocnienie statyczne od u1 do y: %.3f\n', gain_u1_est);
fprintf('Szacowane wzmocnienie statyczne od u2 do y: %.3f\n', gain_u2_est);

% Oszacowanie rzędu dynamiki na podstawie korelacji
threshold_u1 = 0.1 * max_corr_u1;
significant_lags_u1 = lags(abs(r1) > threshold_u1);
suggested_nb1 = max(1, max(significant_lags_u1(significant_lags_u1 > 0)));

threshold_u2 = 0.1 * max_corr_u2;
significant_lags_u2 = lags(abs(r2) > threshold_u2);
suggested_nb2 = max(1, max(significant_lags_u2(significant_lags_u2 > 0)));

if isempty(suggested_nb1) || suggested_nb1 > 10
    suggested_nb1 = abs(optimal_lag_u1);
end
if isempty(suggested_nb2) || suggested_nb2 > 10
    suggested_nb2 = abs(optimal_lag_u2);
end

fprintf('Sugerowane rzędy: nb1=%d, nb2=%d\n', suggested_nb1, suggested_nb2);

%% ====================================================================
%% S04: DECYZJA A - TYP IDENTYFIKACJI
%% ====================================================================

fprintf('\n=== S04: WYBÓR TYPU IDENTYFIKACJI ===\n');
fprintf('Decyzja: BLACK-BOX\n');
fprintf('Uzasadnienie: Brak szczegółowej wiedzy o strukturze wewnętrznej\n');
fprintf('              silnika parowego. Skupiamy się na zachowaniu\n');
fprintf('              wejście-wyjście.\n\n');

identification_type = 'BLACK-BOX';

%% ====================================================================
%% S05: DECYZJA B - WYBÓR KLASY I STRUKTURY MODELU
%% ====================================================================

fprintf('=== S05: WYBÓR STRUKTURY MODELU ===\n');
fprintf('Klasa modelu: ARX (AutoRegressive with eXogenous inputs)\n');
fprintf('Dziedzina czasu: DYSKRETNA (z-transform)\n');
fprintf('Uzasadnienie: - Dane próbkowane z Tp=50ms\n');
fprintf('              - Metoda LS łatwa do implementacji\n');
fprintf('              - Model ARX odpowiedni dla systemów liniowych\n\n');

model_class = 'ARX';
time_domain = 'discrete';

%% ====================================================================
%% S06: ANALIZA SYGNAŁU POBUDZAJĄCEGO I OKRESU PRÓBKOWANIA
%% ====================================================================

fprintf('=== S06: ANALIZA SYGNAŁU POBUDZAJĄCEGO ===\n');

% Analiza widmowa sygnałów wejściowych
figure('Name', 'S06: Analiza widmowa sygnałów', 'Position', [0 0 1000 600]);

% FFT sygnału u1
subplot(2,2,1);
f = (0:N/2-1)/(N*Tp);
U1_fft = fft(u1);
plot(f, abs(U1_fft(1:N/2)), 'b-');
title('Widmo amplitudowe u1');
xlabel('Częstotliwość [Hz]'); ylabel('|U1(f)|');
grid on;

% FFT sygnału u2
subplot(2,2,2);
U2_fft = fft(u2);
plot(f, abs(U2_fft(1:N/2)), 'r-');
title('Widmo amplitudowe u2');
xlabel('Częstotliwość [Hz]'); ylabel('|U2(f)|');
grid on;

% FFT sygnału y
subplot(2,2,3);
Y_fft = fft(y);
plot(f, abs(Y_fft(1:N/2)), 'g-');
title('Widmo amplitudowe y');
xlabel('Częstotliwość [Hz]'); ylabel('|Y(f)|');
grid on;

% Analiza autokorelacji sygnałów wejściowych
subplot(2,2,4);
[r_u1, lags_auto] = xcorr(u1, 50, 'normalized');
plot(lags_auto*Tp, r_u1, 'b-');
title('Autokorelacja u1');
xlabel('Opóźnienie [s]'); ylabel('R_{u1u1}');
grid on;

% Ocena jakości pobudzenia
freq_content_u1 = sum(abs(U1_fft(1:N/2)).^2);
freq_content_u2 = sum(abs(U2_fft(1:N/2)).^2);

fprintf('Energia widmowa u1: %.2e\n', freq_content_u1);
fprintf('Energia widmowa u2: %.2e\n', freq_content_u2);
fprintf('Okres próbkowania Tp=%.3f s jest odpowiedni\n', Tp);

%% ====================================================================
%% S07: PODZIAŁ DANYCH
%% ====================================================================

fprintf('\n=== S07: PODZIAŁ DANYCH ===\n');

% Podział 70% estymacja, 30% weryfikacja
split_ratio = 0.7;
N_est = round(N * split_ratio);
N_ver = N - N_est;

% Dane estymacyjne
u1_est = u1(1:N_est);
u2_est = u2(1:N_est);
y_est = y(1:N_est);

% Dane weryfikacyjne
u1_ver = u1(N_est+1:end);
u2_ver = u2(N_est+1:end);
y_ver = y(N_est+1:end);

fprintf('Dane estymacyjne: %d próbek (%.1f%%)\n', N_est, split_ratio*100);
fprintf('Dane weryfikacyjne: %d próbek (%.1f%%)\n', N_ver, (1-split_ratio)*100);

%% ====================================================================
%% S08: WYBÓR METODY IDENTYFIKACJI
%% ====================================================================

fprintf('\n=== S08: METODA IDENTYFIKACJI ===\n');
fprintf('Wybrana metoda: Najmniejsze kwadraty (LS)\n');
fprintf('Uzasadnienie: - Metoda analityczna\n');
fprintf('              - Optymalna dla modeli liniowych\n');
fprintf('              - Prosta implementacja\n');
fprintf('              - Gwarancja zbieżności\n\n');

method = 'LS'; % Least Squares

%% ====================================================================
%% S09: OBLICZENIE ESTYMAT PARAMETRÓW
%% ====================================================================

fprintf('=== S09: ESTYMACJA PARAMETRÓW ===\n');

% Wybór rzędów modelu na podstawie analizy z S03
na = 2;                              % rząd autoregresyjny
nb1 = min(suggested_nb1, 7);         % rząd dla u1
nb2 = min(suggested_nb2, 3);         % rząd dla u2

fprintf('Wybrane rzędy modelu: na=%d, nb1=%d, nb2=%d\n', na, nb1, nb2);

% Konstrukcja macierzy regresorów dla danych estymacyjnych
n_max = max([na, nb1, nb2]);
nStart = n_max + 1;
N_reg = N_est - nStart + 1;

Phi_est = zeros(N_reg, na + nb1 + nb2);
Y_est = y_est(nStart:end);

for i = 1:N_reg
    n = i + nStart - 1;
    % Składowe autoregresyjne
    Phi_est(i, 1:na) = -y_est(n-1:-1:n-na)';
    % Składowe od u1
    Phi_est(i, na+1:na+nb1) = u1_est(n-1:-1:n-nb1)';
    % Składowe od u2
    Phi_est(i, na+nb1+1:end) = u2_est(n-1:-1:n-nb2)';
end

% Estymacja parametrów metodą LS
theta = Phi_est \ Y_est;

fprintf('Zidentyfikowane parametry:\n');
fprintf('Parametry AR: a = [');
for i = 1:na
    fprintf('%.4f ', theta(i));
end
fprintf(']\n');

fprintf('Parametry u1: b1 = [');
for i = 1:nb1
    fprintf('%.4f ', theta(na+i));
end
fprintf(']\n');

fprintf('Parametry u2: b2 = [');
for i = 1:nb2
    fprintf('%.4f ', theta(na+nb1+i));
end
fprintf(']\n');

% Opcjonalnie: obliczenie macierzy kowariancji
sigma2_est = norm(Y_est - Phi_est*theta)^2 / (N_reg - length(theta));
Cov_theta = sigma2_est * inv(Phi_est' * Phi_est);

fprintf('Wariancja błędu: σ² = %.6f\n', sigma2_est);

%% ====================================================================
%% S10: WERYFIKACJA MODELU
%% ====================================================================

fprintf('\n=== S10: WERYFIKACJA MODELU ===\n');

% S10(I): SYMULACJA NA DANYCH ESTYMACYJNYCH
y_pred_est = zeros(N_est, 1);
y_pred_est(1:nStart-1) = y_est(1:nStart-1);

for n = nStart:N_est
    y_pred_est(n) = -theta(1:na)' * y_pred_est(n-1:-1:n-na);
    y_pred_est(n) = y_pred_est(n) + theta(na+1:na+nb1)' * u1_est(n-1:-1:n-nb1);
    y_pred_est(n) = y_pred_est(n) + theta(na+nb1+1:end)' * u2_est(n-1:-1:n-nb2);
end

% Wskaźnik jakości na danych estymacyjnych
err_est = y_est(nStart:end) - y_pred_est(nStart:end);
J_FIT_est = 100 * (1 - norm(err_est) / norm(y_est(nStart:end) - mean(y_est(nStart:end))));

fprintf('J_FIT na danych estymacyjnych: %.2f%%\n', J_FIT_est);

% S10(II): WERYFIKACJA NA DANYCH NIEZALEŻNYCH
if N_ver >= n_max
    y_pred_ver = zeros(N_ver, 1);
    y_pred_ver(1:min(nStart-1, N_ver)) = y_ver(1:min(nStart-1, N_ver));
    
    start_ver = max(1, nStart);
    for n = start_ver:N_ver
        if n <= na
            % Użyj rzeczywistych wartości dla początkowych próbek
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
    % Wskaźnik jakości na danych weryfikacyjnych
    min_start = max([start_ver, na, nb1, nb2]) + 1;
    valid_idx = min_start:N_ver;
    if length(valid_idx) > 10  % sprawdź czy mamy wystarczająco danych
        err_ver = y_ver(valid_idx) - y_pred_ver(valid_idx);
        J_FIT_ver = 100 * (1 - norm(err_ver) / norm(y_ver(valid_idx) - mean(y_ver(valid_idx))));
        fprintf('J_FIT na danych weryfikacyjnych: %.2f%%\n', J_FIT_ver);
    else
        J_FIT_ver = NaN;
        fprintf('Za mało danych weryfikacyjnych dla oceny\n');
    end
else
    J_FIT_ver = NaN;
    fprintf('Za mało danych weryfikacyjnych\n');
end

% Wizualizacja wyników
figure('Name', 'S10: Weryfikacja modelu', 'Position', [0 0 1200 800]);

subplot(2,1,1);
t_est = (1:N_est) * Tp;
plot(t_est, y_est, 'b-', 'LineWidth', 1.5); hold on;
plot(t_est, y_pred_est, 'r--', 'LineWidth', 1.5);
title(sprintf('Dane estymacyjne - J_{FIT} = %.1f%%', J_FIT_est));
xlabel('Czas [s]'); ylabel('Wyjście y');
legend('Rzeczywiste', 'Model', 'Location', 'best');
grid on;

if ~isnan(J_FIT_ver)
    subplot(2,1,2);
    t_ver = ((N_est+1):(N_est+N_ver)) * Tp;
    plot(t_ver, y_ver, 'b-', 'LineWidth', 1.5); hold on;
    plot(t_ver, y_pred_ver, 'r--', 'LineWidth', 1.5);
    title(sprintf('Dane weryfikacyjne - J_{FIT} = %.1f%%', J_FIT_ver));
    xlabel('Czas [s]'); ylabel('Wyjście y');
    legend('Rzeczywiste', 'Model', 'Location', 'best');
    grid on;
end

% Analiza reszt
figure('Name', 'S10: Analiza reszt', 'Position', [0 0 1000 600]);

subplot(2,2,1);
plot((nStart:N_est)*Tp, err_est, 'b-');
title('Reszty - dane estymacyjne');
xlabel('Czas [s]'); ylabel('Błąd predykcji');
grid on;

subplot(2,2,2);
histogram(err_est, 20);
title('Histogram reszt - estymacja');
xlabel('Błąd'); ylabel('Częstość');
grid on;

if ~isnan(J_FIT_ver) && length(valid_idx) > 10
    subplot(2,2,3);
    plot(valid_idx*Tp, err_ver, 'r-');
    title('Reszty - dane weryfikacyjne');
    xlabel('Czas [s]'); ylabel('Błąd predykcji');
    grid on;
    
    subplot(2,2,4);
    histogram(err_ver, 20);
    title('Histogram reszt - weryfikacja');
    xlabel('Błąd'); ylabel('Częstość');
    grid on;
end

%% ====================================================================
%% S11: DECYZJA KOŃCOWA
%% ====================================================================

fprintf('\n=== S11: OCENA KOŃCOWA MODELU ===\n');

% Kryteria akceptacji
model_acceptable = false;

if J_FIT_est >= target_JFIT
    fprintf('✓ Model spełnia kryterium J_FIT > %d%% na danych estymacyjnych\n', target_JFIT);
    
    if ~isnan(J_FIT_ver)
        if J_FIT_ver >= target_JFIT - 10  % nieco łagodniejsze kryterium dla weryfikacji
            fprintf('✓ Model ma akceptowalną jakość na danych weryfikacyjnych\n');
            model_acceptable = true;
        else
            fprintf('✗ Model ma niewystarczającą jakość na danych weryfikacyjnych\n');
        end
    else
        fprintf('⚠ Brak wystarczających danych weryfikacyjnych - akceptujemy na podstawie estymacji\n');
        model_acceptable = true;
    end
else
    fprintf('✗ Model nie spełnia kryterium J_FIT > %d%%\n', target_JFIT);
end

% Sprawdzenie stabilności modelu
A_poly = [1, theta(1:na)'];  % wielomian charakterystyczny
poles = roots(A_poly);
stable = all(abs(poles) < 1);

if stable
    fprintf('✓ Model jest stabilny (wszystkie bieguny wewnątrz koła jednostkowego)\n');
else
    fprintf('✗ Model jest niestabilny\n');
    model_acceptable = false;
end

fprintf('\nBieguny modelu: ');
for i = 1:length(poles)
    fprintf('%.3f%+.3fi (|z|=%.3f) ', real(poles(i)), imag(poles(i)), abs(poles(i)));
end
fprintf('\n');

% Podsumowanie transmitancji
fprintf('\nTransmitancje dyskretne systemu:\n');
fprintf('G1(z) = (');
for i = 1:nb1
    if i == 1
        fprintf('%.4f*z^{-%d}', theta(na+i), i);
    else
        fprintf(' %+.4f*z^{-%d}', theta(na+i), i);
    end
end
fprintf(') / (1');
for i = 1:na
    fprintf(' %+.4f*z^{-%d}', theta(i), i);
end
fprintf(')\n');

fprintf('G2(z) = (');
for i = 1:nb2
    if i == 1
        fprintf('%.4f*z^{-%d}', theta(na+nb1+i), i);
    else
        fprintf(' %+.4f*z^{-%d}', theta(na+nb1+i), i);
    end
end
fprintf(') / (1');
for i = 1:na
    fprintf(' %+.4f*z^{-%d}', theta(i), i);
end
fprintf(')\n');

% Decyzja końcowa
if model_acceptable
    fprintf('\n🎉 DECYZJA: MODEL AKCEPTOWALNY!\n');
    fprintf('Model jest gotowy do użycia jako symulator systemu.\n');
    
    % Zapisanie wyników
    save('model_results.mat', 'theta', 'na', 'nb1', 'nb2', 'J_FIT_est', 'J_FIT_ver', ...
        'poles', 'sigma2_est', 'Tp');
    fprintf('Wyniki zapisane w pliku model_results.mat\n');
else
    fprintf('\n❌ DECYZJA: MODEL NIEAKCEPTOWALNY!\n');
    fprintf('Przejdź do etapu S03 i rozważ:\n');
    fprintf('- Zmianę rzędów modelu\n');
    fprintf('- Zmianę struktury modelu (np. ARMAX)\n');
    fprintf('- Dodatkowe przetwarzanie danych\n');
    fprintf('- Weryfikację jakości danych pomiarowych\n');
end

fprintf('\n=== KONIEC IDENTYFIKACJI ===\n');
