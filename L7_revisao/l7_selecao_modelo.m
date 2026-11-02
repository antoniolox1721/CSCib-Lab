%% L7_SELECAO_MODELO.m - selecao do modelo por validacao cruzada "leave-one-experiment-out" sobre os 5 registos reais.
% Para cada candidato (estrutura, ordens, zona morta d no sinal u): treina nos outros 4 registos (merge) e testa no que ficou de fora,
% repetido para cada um dos 5. Metricas: fit no sinal derivado+filtrado e fit de posicao (soma acumulada, tendencia linear removida).
% Nao usa dados simulados. Corre com a pasta atual = L7_revisao:  matlab -batch l7_selecao_modelo   (demora ~10-20 min)
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
nm = {'dados_ID_quadrada_1V','dados_ID_prbs_1Hz_0.5','dados_ID_prbs_2_5Hz_0.5','dados_validacao','dados_ID_validacao_0_5'};
amp = [1 0.5 0.5 1 0.5]; Ts = 0.02; af = 0.8;
raw = cellfun(@(f) load(fullfile(pasta, [f '.mat']), 'ScopeData').ScopeData, nm, 'UniformOutput', false);
cand = {};   % {tipo, ordens, d}
ds = 0:0.05:0.4;
for d = ds, for o = [2 2; 3 3; 3 4; 4 4]', cand(end+1,:) = {'armax', o', d}; end, end %#ok<SAGROW>
for d = ds, for o = [3 3; 4 4]', cand(end+1,:) = {'oe', o', d}; end, end
for d = ds, for n = [3 4], cand(end+1,:) = {'n4sid', n, d}; end, end
R = zeros(size(cand,1), 5*3);   % por registo de teste: fit filtrado, fit posicao, ganho medido/modelo
mp = zeros(size(cand,1), 1); nf = zeros(size(cand,1), 1);
for c = 1:size(cand,1)
    [tipo, o, d] = cand{c,:}; [u, y] = prepara(raw, C, af, d, Ts);
    for h = 1:5
        tr = setdiff(1:5, h); D = merge(iddata(y{tr(1)},u{tr(1)},Ts), iddata(y{tr(2)},u{tr(2)},Ts), iddata(y{tr(3)},u{tr(3)},Ts), iddata(y{tr(4)},u{tr(4)},Ts));
        try
            switch tipo
                case 'armax', th = armax(D, [o(1) o(2) o(1) 1]);
                case 'oe',    th = oe(D, [o(1) o(2) 1]);
                case 'n4sid', th = n4sid(D, o(1));
            end
            p = max(abs(pole(th))); yp = sim(th, u{h}); if p >= 1 || any(~isfinite(yp)), nf(c) = nf(c)+1; R(c,3*h-2:3*h) = NaN; continue; end
            mp(c) = max(mp(c), p); R(c,3*h-2:3*h) = [fitf(y{h}, yp), fitpos(y{h}, yp), (yp'*y{h})/(yp'*yp)];
        catch, nf(c) = nf(c)+1; R(c,3*h-2:3*h) = NaN;
        end
    end
    fprintf('%3d/%d %-6s %s d=%.1f | filt %s | pos %s | falhas %d\n', c, size(cand,1), tipo, mat2str(o'), d, mat2str(round(R(c,1:3:15),0)), mat2str(round(R(c,2:3:15),0)), nf(c));
end
F = R(:,1:3:15); P = R(:,2:3:15); G = R(:,3:3:15);
T = table(string(cand(:,1)), cellfun(@(x) mat2str(x(:)'), cand(:,2), 'UniformOutput', false), cell2mat(cand(:,3)), mean(F,2), min(F,[],2), mean(P,2), min(P,[],2), mean(abs(G-1),2), nf, mp, ...
    'VariableNames', {'tipo','ordens','d_V','fit_filt_medio','fit_filt_pior','fit_pos_medio','fit_pos_pior','desvio_ganho_medio','folds_falhados','max_polo'});
T = [T array2table(F, 'VariableNames', {'f_Q1V','f_P1','f_P2','f_V1','f_V05'}) array2table(P, 'VariableNames', {'p_Q1V','p_P1','p_P2','p_V1','p_V05'}) array2table(G, 'VariableNames', {'g_Q1V','g_P1','g_P2','g_V1','g_V05'})];
T = sortrows(T, 'fit_pos_medio', 'descend', 'MissingPlacement', 'last'); writetable(T, 'l7_selecao_modelo.csv'); save('l7_selecao_modelo.mat', 'T', 'cand', 'R');
disp(T(1:12, {'tipo','ordens','d_V','fit_filt_medio','fit_filt_pior','fit_pos_medio','fit_pos_pior','desvio_ganho_medio','folds_falhados','max_polo'}));

function [u, yf] = prepara(raw, C, af, d, Ts)
    nd = round(8/Ts); Af = [1 -af]; Bf = (1-af)*[1 -1]; u = cell(1,numel(raw)); yf = u;
    for k = 1:numel(raw)
        S = raw{k}; i = (nd+1):size(S,1); yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke;
        ue = sign(S(i,2)).*max(abs(S(i,2))-d, 0);                    % zona morta de largura d (V) no sinal de entrada
        u{k} = detrend(ue, 'constant'); yf{k} = detrend(filter(Bf, Af, yt - yt(1)), 'constant');
    end
end
function f = fitf(y, yp), f = 100*(1 - norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end)))); end
function f = fitpos(y, yp)                                              % soma acumulada = posicao filtrada (menos tendencia linear)
    a = detrend(cumsum(y)); b = detrend(cumsum(yp)); f = 100*(1 - norm(a-b)/norm(a-mean(a)));
end
