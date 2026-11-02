%% L7_VALIDACAO_ANINHADA.m - teste de sobreajuste da zona morta: d escolhido SO com os 3 ficheiros de ID (leave-one-out entre eles),
% depois o modelo e avaliado nos 2 ficheiros reservados, que nao participam na escolha de d nem no treino.
% Corre com a pasta atual = L7_revisao:  matlab -batch l7_validacao_aninhada
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
nm = {'dados_ID_quadrada_1V','dados_ID_prbs_1Hz_0.5','dados_ID_prbs_2_5Hz_0.5','dados_validacao','dados_ID_validacao_0_5'};
raw = cellfun(@(f) load(fullfile(pasta, [f '.mat']), 'ScopeData').ScopeData, nm, 'UniformOutput', false);
ds = [0 0.1 0.15 0.2 0.22 0.24 0.25 0.26 0.28 0.3 0.35]; Ts = 0.02; af = 0.8;
cv = zeros(numel(ds), 1); gdev = zeros(numel(ds), 1);
for i = 1:numel(ds)
    [u, y] = prepara(raw, C, af, ds(i)); f = zeros(1,3); g = zeros(1,3);
    for h = 1:3                                           % leave-one-out SO entre os 3 ficheiros de ID
        tr = setdiff(1:3, h); th = armax(merge(iddata(y{tr(1)},u{tr(1)},Ts), iddata(y{tr(2)},u{tr(2)},Ts)), [3 4 3 1]); yp = sim(th, u{h});
        f(h) = fitf(y{h}, yp); g(h) = (yp'*y{h})/(yp'*yp);
    end
    cv(i) = mean(f); gdev(i) = mean(abs(g-1)); fprintf('d = %.2f | CV so com ID: fit medio %.1f %% | desvio de ganho %.3f\n', ds(i), cv(i), gdev(i));
end
[~, ib] = max(cv); d_cv = ds(ib); fprintf('\nd escolhido SO com os ficheiros de ID (maximo do fit CV): %.2f V\n', d_cv);
for d = unique([0 d_cv 0.25])
    [u, y] = prepara(raw, C, af, d); th = armax(merge(iddata(y{1},u{1},Ts), iddata(y{2},u{2},Ts), iddata(y{3},u{3},Ts)), [3 4 3 1]);
    r = arrayfun(@(k) fitf(y{k}, sim(th, u{k})), 4:5); gg = arrayfun(@(k) (sim(th,u{k})'*y{k})/(sim(th,u{k})'*sim(th,u{k})), 4:5);
    fprintf('d = %.2f -> ficheiros reservados: 1 V %.1f %% | 0.5 V %.1f %% | ganho medido/modelo %.2f / %.2f\n', d, r, gg);
end
function [u, yf] = prepara(raw, C, af, d)
    nd = 400; Af = [1 -af]; Bf = (1-af)*[1 -1]; u = cell(1,numel(raw)); yf = u;
    for k = 1:numel(raw)
        S = raw{k}; i = (nd+1):size(S,1); yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke;
        u{k} = detrend(sign(S(i,2)).*max(abs(S(i,2))-d, 0), 'constant'); yf{k} = detrend(filter(Bf, Af, yt - yt(1)), 'constant');
    end
end
function f = fitf(y, yp), f = 100*(1 - norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end)))); end
