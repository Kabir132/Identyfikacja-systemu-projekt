%% IDENTYFIKACJA SILNIKA PAROWEGO - WERSJA STUDENCKA
% Autor: Student 3 roku Automatyki i Robotyki
% 
% OPIS:
% - System: MISO (2 wejścia, 1 wyjście)
% - Model: ARX
% - Metoda identyfikacji: Least Squares
% - Cel: FIT > 85%

clear; clc; close all;

%% 1. Wczytanie danych
disp('Identyfikacja silnika parowego - wersja studencka')
disp('Wczytywanie danych...')
load('dane.mat');

% Sprawdzamy co jest w pliku
disp('Znalezione zmienne:')
who

%% 2. Przypisanie danych
% Sprawdzenie dostępnych zmiennych i znalezienie sygnałów wejścia/wyjścia
vars = who;
disp('Szukanie zmiennych wejścia i wyjścia...')

% Ręczne przypisanie
if exist('in1', 'var') && exist('in2', 'var') && exist('out', 'var')
    u1_data = in1;
    u2_data = in2;
    y_data = out;
    disp('Znaleziono zmienne: in1, in2, out')
elseif exist('u1', 'var') && exist('u2', 'var') && exist('y', 'var')
    u1_data = u1;
    u2_data = u2;
    y_data = y;
    disp('Znaleziono zmienne: u1, u2, y')
else
    % Znajdź zmienne numeryczne
    numeric_vars = {};
    for i = 1:length(vars)
        var_name = vars{i};
        var_data = eval(var_name);
        if isnumeric(var_data) && ~isempty(var_data)
            numeric_vars{end+1} = var_name;
        end
    end
    
    % Przypisz pierwsze 3 zmienne numeryczne jako u1, u2, y
    if length(numeric_vars) >= 3
        u1_data = eval(numeric_vars{1});
        u2_data = eval(numeric_vars{2});
        y_data = eval(numeric_vars{3});
        disp(['Przypisano zmienne: ' numeric_vars{1} ', ' numeric_vars{2} ', ' numeric_vars{3}])
    else
        error('Za mało zmiennych numerycznych w pliku danych');
    end
end

% Konwersja do wektorów kolumnowych
u1 = u1_data(:);  % Ciśnienie pary za zaworem
u2 = u2_data(:);  % Napięcie magnetyzacji generatora
y = y_data(:);    % Napięcie w generatorze (wyjście)

% Dopasowanie długości wektorów
N = min([length(u1), length(u2), length(y)]);
u1 = u1(1:N);
u2 = u2(1:N);
y = y(1:N);

disp(['Długość sygnałów: ' num2str(N) ' próbek'])

%% 3. Przygotowanie danych
% Usunięcie średniej
u1 = u1 - mean(u1);
u2 = u2 - mean(u2);
y = y - mean(y);

%% 4. Wizualizacja danych pomiarowych
Tp = 0.05;  % Okres próbkowania [s]
t = (0:N-1) * Tp;  % Wektor czasu

figure(1);
subplot(3,1,1);
plot(t, u1);
title('Wejście 1: Ciśnienie pary za zaworem');
grid on;

subplot(3,1,2);
plot(t, u2);
title('Wejście 2: Napięcie magnetyzacji');
grid on;

subplot(3,1,3);
plot(t, y);
title('Wyjście: Napięcie w generatorze');
xlabel('Czas [s]');
grid on;

%% 5. Identyfikacja modelu ARX
% Parametry modelu (można je zmienić)
na = 2;     % Rząd części autoregresyjnej
nb1 = 2;    % Rząd dla pierwszego wejścia
nb2 = 2;    % Rząd dla drugiego wejścia
nk1 = 1;    % Opóźnienie dla pierwszego wejścia
nk2 = 1;    % Opóźnienie dla drugiego wejścia

disp(['Identyfikacja modelu ARX(' num2str(na) ',[' num2str(nb1) ',' num2str(nb2) ...
    '],[' num2str(nk1) ',' num2str(nk2) '])']);

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

% Wyodrębnienie współczynników modelu
a_coeffs = theta(1:na);
b1_coeffs = theta(na+1:na+nb1);
b2_coeffs = theta(na+nb1+1:end);

% Sprawdzenie stabilności modelu
if na > 0
    A_poly = [1; a_coeffs];  % Wielomian A(z^-1)
    roots_A = roots(A_poly);
    stable = all(abs(roots_A) < 1);
else
    roots_A = [];
    stable = true;  % Model bez części AR jest zawsze stabilny
end

%% 6. Wyświetlenie wyników
disp('Wyniki identyfikacji:')
disp(['FIT = ' num2str(fit_percent, '%.2f') '%'])
disp(['MSE = ' num2str(mse, '%.4e')])
disp(['RMSE = ' num2str(rmse, '%.4f')])

if stable
    disp('Model jest stabilny')
else
    disp('Model jest niestabilny!')
end

% Wyświetlenie równania modelu
fprintf('\nRównanie modelu ARX:\n');
fprintf('y(k)');
for i = 1:na
    fprintf(' + %.4f*y(k-%d)', a_coeffs(i), i);
end
fprintf(' = ');
for i = 1:nb1
    fprintf('%.4f*u1(k-%d)', b1_coeffs(i), nk1+i-1);
    if i < nb1 || nb2 > 0
        fprintf(' + ');
    end
end
for i = 1:nb2
    fprintf('%.4f*u2(k-%d)', b2_coeffs(i), nk2+i-1);
    if i < nb2
        fprintf(' + ');
    end
end
fprintf('\n\n');

%% 7. Wizualizacja wyników
% Upewnienie się, że wszystkie wektory mają właściwą długość
t = (0:N-1) * Tp;  % Upewnij się, że wektor czasu ma odpowiednią długość

% Wizualizacja porównania modelu z danymi rzeczywistymi
figure(2);
subplot(2,1,1);
plot(t, y, 'b', 'LineWidth', 1); hold on;
plot(t, y_model, 'r', 'LineWidth', 1);
grid on;
title(['Porównanie modelu z danymi (FIT = ' num2str(fit_percent, '%.2f') '%)']);
legend('Dane rzeczywiste', 'Model ARX');
ylabel('Amplituda');
xlabel('Czas [s]');

subplot(2,1,2);
plot(t, e, 'k', 'LineWidth', 1);
grid on;
title('Reszty modelu');
ylabel('Amplituda błędu');
xlabel('Czas [s]');

% Analiza rozkładu reszt
figure(3);
histogram(e(start_idx:end_idx), 30);  % Używamy tylko reszt z zakresu efektywnych danych
title('Histogram reszt');
grid on;
xlabel('Wartość błędu');
ylabel('Liczba wystąpień');

% Analiza biegunów
if ~isempty(roots_A)
    figure(4);
    % Rysowanie koła jednostkowego
    angle = linspace(0, 2*pi, 100);  % Zmieniono nazwę zmiennej, aby nie kolidowała z wektorem czasu t
    circle_x = cos(angle);
    circle_y = sin(angle);
    plot(circle_x, circle_y, 'k--', 'LineWidth', 1.5); hold on;
    plot([-1.5, 1.5], [0, 0], 'k:', [0, 0], [-1.5, 1.5], 'k:');  % Osie
    
    % Rysowanie biegunów
    plot(real(roots_A), imag(roots_A), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    
    grid on;
    axis equal;
    axis([-1.5 1.5 -1.5 1.5]);
    title('Bieguny modelu');
    xlabel('Część rzeczywista');
    ylabel('Część urojona');
end

%% 8. Sprawdzenie celu
if fit_percent >= 85
    disp('CEL OSIĄGNIĘTY! FIT > 85%')
else
    disp('CEL NIEOSIĄGNIĘTY. Spróbuj innych parametrów modelu.')
end

% Zapisanie modelu
save('model_arx_student.mat', 'na', 'nb1', 'nb2', 'nk1', 'nk2', 'theta', 'fit_percent');
disp('Zapisano model do pliku model_arx_student.mat')
