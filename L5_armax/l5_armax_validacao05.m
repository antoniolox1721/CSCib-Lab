%% (com zona morta d_zm = 0,25 V) Validacao com dados_ID_validacao_0_5.mat (quadrada 0,5 V, 0,6 Hz) + re-estimacao. Correr com pasta = L5_armax.
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
Ts = 0.02; af = 0.8; nd = 400; d_zm = 0.25; Af = [1 -af]; Bf = (1-af)*[1 -1];   % d_zm: zona morta (V) na entrada, ver ../L7_revisao/l7_selecao_modelo.m
nomes = {'dados_ID_quadrada_1V.mat','dados_ID_prbs_1Hz_0.5.mat','dados_ID_prbs_2_5Hz_0.5.mat','dados_validacao.mat','dados_ID_validacao_0_5.mat'};
for k = 1:5
    S = load(fullfile(pasta, nomes{k}), 'ScopeData').ScopeData; i = (nd+1):size(S,1);
    yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke; u{k} = detrend(sign(S(i,2)).*max(abs(S(i,2))-d_zm,0),'constant');
    yf{k} = detrend(filter(Bf,Af,yt-yt(1)),'constant');
end
fitf = @(y,yp) 100*(1-norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end))));
D = @(idx) mergeid(yf, u, Ts, idx);
treino = [1 2 3];
fprintf('== Treino Q+P1+P2; fit em val(1V,0.6Hz) | val(0.5V,0.6Hz) | media | max|polo|\n');
R = [];
for na = 2:5, for nb = 2:5
    th = armax(D(treino), [na nb na 1]); p = max(abs(roots(th.A))); if p >= 1, continue; end
    f4 = fitf(yf{4}, sim(th,u{4})); f5 = fitf(yf{5}, sim(th,u{5}));
    R = [R; na nb f4 f5 (f4+f5)/2 p]; fprintf('%d %d | %6.2f | %6.2f | %6.2f | %.3f\n', na, nb, f4, f5, (f4+f5)/2, p);
end, end
[~,ib] = max(R(:,5)); na = R(ib,1); nb = R(ib,2);
fprintf('\nMelhor media nas 2 validacoes: na=%d nb=%d\n', na, nb);
th0 = armax(D(treino), [3 4 3 1]);
fprintf('Modelo anterior (3,4,3,1): val1V %.2f | val0.5V %.2f\n', fitf(yf{4},sim(th0,u{4})), fitf(yf{5},sim(th0,u{5})));
% Re-estimacao: treino com Q+P1+P2+val0.5 ; valida no val(1V) (continua fora do treino)
fprintf('\n== Re-estimacao incluindo val0.5 no treino (val 1V continua de fora)\n');
R2 = [];
for na = 2:5, for nb = 2:5
    th = armax(D([1 2 3 5]), [na nb na 1]); p = max(abs(roots(th.A))); if p >= 1, continue; end
    f4 = fitf(yf{4}, sim(th,u{4})); loo = zeros(1,4);
    for k = 1:4, r = setdiff([1 2 3 5], k); t2 = armax(D(r), [na nb na 1]); kk = [1 2 3 5]; loo(k) = fitf(yf{kk(k)}, sim(t2,u{kk(k)})); end
    R2 = [R2; na nb f4 mean(loo) p]; fprintf('%d %d | val1V %6.2f | LOO medio %6.2f (Q %.1f P1 %.1f P2 %.1f V05 %.1f) | %.3f\n', na, nb, f4, mean(loo), loo, p);
end, end
save('validacao05_resultados.mat','R','R2');

function d = mergeid(yf, u, Ts, idx)
    c = cell(1,numel(idx));
    for j = 1:numel(idx), c{j} = iddata(yf{idx(j)}, u{idx(j)}, Ts); end
    d = merge(c{:});
end
