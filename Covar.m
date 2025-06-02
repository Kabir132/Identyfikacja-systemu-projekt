function C = Covar(D, tau, method)
%oblicza wartość funkcji kowariancji 'c(tau)' dla sygnałów zawartych w D i
%przesunięcia czasowego równego 'tau'
%parametry wejściowe: D - macierz składająca się z 2 kolumn (y(n), u(n));
% tau - dana wartość przesunięcia sygnałów (liczba próbek przesunięcia);

Y = D(:,1);
U = D(:,2);

N = size(Y,1);
Yp = zeros(N,1);

MU = (1/N)*sum(U);
MY = (1/N)*sum(Y);

Ud = U;% - MU*ones(N,1);              %odjęcie wartowci średnich
Yd = Y;% - MY*ones(N,1);

if (tau>=0)
    Yp(1:(N-tau)) = Yd((1+tau):N);
else
    Yp((1-tau):N) = Yd(1:(N+tau));
end

switch method
    case 'N'
        CYU = (1/N) * (Ud' * Yp);
    case 'N_tau'
        CYU = (1/(N - abs(tau))) * (Ud' * Yp);
    otherwise
        error('Wybierz ''N'' lub ''N_tau''.');
end

C = CYU;