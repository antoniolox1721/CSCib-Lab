%% L5_ARMAX_OFICIAL.m (com zona morta d_zm = 0,25 V na entrada; antes de 19 out era 0) - armax do MATLAB (System Identification Toolbox) com 3 experiencias em conjunto.
% Mesma cadeia do l5_identificacao.m. Corre com a pasta atual = L5_armax:  matlab -batch l5_armax_oficial
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
Ts = 0.02; af = 0.8; d_zm = 0.25;   % zona morta (V) na entrada, ver ../L7_revisao/l7_selecao_modelo.m
 nd = round(8/Ts); Af = [1 -af]; Bf = (1-af)*[1 -1];
ids = {'dados_ID_quadrada_1V.mat','dados_ID_prbs_1Hz_0.5.mat','dados_ID_prbs_2_5Hz_0.5.mat'};
prep = @(f) prep_ficheiro(fullfile(pasta, f), C, nd, Af, Bf, d_zm);
for k = 1:3, [u{k}, yf{k}] = prep(ids{k}); end
[uv, yfv] = prep('dados_validacao.mat');
fitf = @(y, yp) 100*(1 - norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end))));
dados3 = merge(iddata(yf{1},u{1},Ts), iddata(yf{2},u{2},Ts), iddata(yf{3},u{3},Ts));
fprintf('na nb | fit_val | leave-one-out (sem Q / sem P1 / sem P2) | max|polo|\n');
R = []; best = []; bfit = -Inf;
for na = 2:5, for nb = 2:5
    th = armax(dados3, [na nb na 1]);
    p = max(abs(roots(th.A))); if p >= 1, continue; end
    fv = fitf(yfv, sim(th, uv)); loo = zeros(1,3);
    for k = 1:3
        r = setdiff(1:3, k); d2 = merge(iddata(yf{r(1)},u{r(1)},Ts), iddata(yf{r(2)},u{r(2)},Ts));
        t2 = armax(d2, [na nb na 1]); loo(k) = fitf(yf{k}, sim(t2, u{k}));
    end
    R = [R; na nb fv loo p]; fprintf('%d  %d  | %6.2f | %6.2f %6.2f %6.2f | %.3f\n', na, nb, fv, loo, p);
    if fv > bfit, bfit = fv; best = th; end
end, end
th = armax(dados3, [3 4 3 1]);                       % ordem escolhida (a mesma do Python, para comparar)
yp = sim(th, uv); fv = fitf(yfv, yp); res = yfv(30:end) - yp(30:end);
r0 = res - mean(res); ac = xcorr(r0, 20, 'coeff'); ac = ac(22:end); n = numel(res);
Q = n*(n+2)*sum(ac.^2 ./ (n-(1:20)')); h = Q > chi2inv(0.95, 20); pv = 1 - chi2cdf(Q, 20);   % Ljung-Box manual (lbqtest precisa da Econometrics)
fprintf('\nARMAX(3,4,3,1) oficial: fit_val = %.2f %% | Ljung-Box h=%d p=%.3g\n', fv, h, pv);
[den1, num1] = polydata(th); fprintf('A = '); disp(den1); fprintf('B = '); disp(num1);
fprintf('polos (filtrado): '); disp(roots(den1).');
[num, den] = eqtflength(num1, conv(den1, [1 -1])); [A, B, Cc, Dd] = tf2ss(num, den);
fprintf('estados %d, rank ctrb %d\n', size(A,1), rank(ctrb(A, B)));
save('modelo_armax_oficial.mat', 'A','B','Cc','Dd','Ts','num1','den1','th','R','fv');

function [u, yf] = prep_ficheiro(f, C, nd, Af, Bf, d_zm)
    S = load(f, 'ScopeData').ScopeData; i = (nd+1):size(S,1);
    yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke; u = detrend(sign(S(i,2)).*max(abs(S(i,2))-d_zm, 0), 'constant');
    yf = detrend(filter(Bf, Af, yt - yt(1)), 'constant');
end
