%% L7_REVISAO.m - revisao da identificacao: polo do filtro (af), ordens, periodo de amostragem; modelo final + graficos de malha aberta.
% Todos os varrimentos usam a zona morta d_zm na entrada (ver l7_selecao_modelo.m).
% Mesma cadeia do l5_armax_oficial.m. Corre com a pasta atual = L7_revisao:  matlab -batch l7_revisao
% Nao toca em ../L4_identificacao/modelo_identificado.mat; grava l7_modelo_final.mat aqui.
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
assert(exist(fullfile(pasta, 'dados_validacao.mat'), 'file') == 2, 'faltam os dados em ../L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
assert(all(isfield(C, {'Kp','Ke','offset'})), 'calibracao_sensores.mat incompleto');
ids  = {'dados_ID_quadrada_1V', 'dados_ID_prbs_1Hz_0.5', 'dados_ID_prbs_2_5Hz_0.5'};
vals = {'dados_validacao', 'dados_ID_validacao_0_5'};          % 1 V/0.6 Hz e 0.5 V/0.6 Hz; so para validar
fitf = @(y, yp) 100*(1 - norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end))));
d_zm = 0.25;   % zona morta (V) estimada por validacao cruzada (l7_selecao_modelo.m / l7_refinar_d.m); 0 = sem zona morta
af_ref = 0.8;                                                  % dominio comum para comparar af's (ver nota abaixo)

%% 1. Varrimento de af x ordens (Ts = 0.02 s)
% Nota: o fit com af diferentes mede sinais filtrados diferentes (af maior = passa-baixo mais forte = mais facil).
% Para comparar justamente, preditor e validacao passam ainda por Gref/Gaf, ficando ambos filtrados com af_ref.
afs = [0.5 0.6 0.7 0.8 0.9 0.95]; ordens = [2 3; 3 3; 3 4; 4 4; 3 5];
T1 = [];
for af = afs
    [u, y] = carrega(pasta, ids, C, 0.02, 1, af, d_zm); [uv, yv] = carrega(pasta, vals, C, 0.02, 1, af, d_zm);
    d = merge(iddata(y{1},u{1},0.02), iddata(y{2},u{2},0.02), iddata(y{3},u{3},0.02));
    for o = ordens'
        th = armax(d, [o(1) o(2) o(1) 1]); p = max(abs(roots(th.A)));
        f = zeros(1,2); fc = zeros(1,2);
        for k = 1:2
            yp = sim(th, uv{k}); f(k) = fitf(yv{k}, yp);
            fc(k) = fitf(comum(yv{k}, af, af_ref), comum(yp, af, af_ref));
        end
        T1 = [T1; af o(1) o(2) f fc mean(fc) p];
    end
end
T1t = array2table(T1, 'VariableNames', {'af','na','nb','fit1V','fit05V','fit1V_comum','fit05V_comum','media_comum','maxpolo'});
disp(sortrows(T1t, 'media_comum', 'descend')); writetable(T1t, 'l7_varrimento_af_ordens.csv');

%% 2. Periodo de amostragem: Ts = 0.02 vs 0.04 s (dados decimados por 2; af^2 mantem o mesmo polo analogico)
T2 = [];
for dec = [1 2]
    Ts = 0.02*dec; af = 0.8^dec;
    [u, y] = carrega(pasta, ids, C, Ts, dec, af, d_zm); [uv, yv] = carrega(pasta, vals, C, Ts, dec, af, d_zm);
    d = merge(iddata(y{1},u{1},Ts), iddata(y{2},u{2},Ts), iddata(y{3},u{3},Ts));
    for o = [2 3; 3 4; 4 4]'
        th = armax(d, [o(1) o(2) o(1) 1]);
        T2 = [T2; Ts o(1) o(2) fitf(yv{1}, sim(th, uv{1})) fitf(yv{2}, sim(th, uv{2})) max(abs(roots(th.A)))];
    end
end
T2t = array2table(T2, 'VariableNames', {'Ts','na','nb','fit1V','fit05V','maxpolo'}); disp(T2t); writetable(T2t, 'l7_varrimento_Ts.csv');

%% 3. Modelo final (escolha no fim da aula - ver tabelas; por defeito o vencedor da media_comum com polo < 1)
% Modelo final: ARMAX(3,4,3,1), af = 0.8, zona morta d_zm na entrada, treinado nos 3 ficheiros de ID; os 2 de validacao ficam de fora.
% Escolha por validacao cruzada leave-one-experiment-out nos 5 registos (l7_selecao_modelo.m, l7_refinar_d.m).
af_f = 0.8; o_f = [3 4];
Ts = 0.02; [u, y] = carrega(pasta, ids, C, Ts, 1, af_f, d_zm); [uv, yv] = carrega(pasta, vals, C, Ts, 1, af_f, d_zm);
th = armax(merge(iddata(y{1},u{1},Ts), iddata(y{2},u{2},Ts), iddata(y{3},u{3},Ts)), [o_f(1) o_f(2) o_f(1) 1]);
[den1, num1] = polydata(th); [num, den] = eqtflength(num1, conv(den1, [1 -1]));   % reintroduz o integrador
[A, B, Cc, Dd] = tf2ss(num, den);
assert(rank(ctrb(A, B)) == size(A,1), 'modelo nao controlavel');
G = ss(A, B, Cc, Dd, Ts);
fprintf('\nFinal: ARMAX(%d,%d,%d,1) af=%.2f | fit 1V %.1f %% | fit 0.5V %.1f %%\n', o_f(1), o_f(2), o_f(1), af_f, fitf(yv{1}, sim(th, uv{1})), fitf(yv{2}, sim(th, uv{2})));
fprintf('polos malha aberta: '); disp(pole(G).'); fprintf('zeros: '); disp(tzero(G).');
save('l7_modelo_final.mat', 'A','B','Cc','Dd','Ts','num1','den1','th','af_f','o_f','d_zm','T1t','T2t');
% Alimenta o L8: ../L4_identificacao/modelo_identificado.mat (anterior guardado em modelo_identificado_merge3.mat)
controlavel = true; sys_identificado = G; deadzone_V = d_zm;   % o ganho do modelo e de u_eff = sign(u)*max(|u|-deadzone_V,0): compensar no tempo real (u_cmd = u_eff + deadzone_V*sign(u_eff))
save(fullfile(pasta, 'modelo_identificado.mat'), 'A','B','Cc','Dd','Ts','num1','den1','th','controlavel','sys_identificado','deadzone_V');

%% 4. Graficos de malha aberta (Q3)
f = figure('Visible','off','Position',[100 100 1200 400]);
subplot(1,3,1); pzmap(G); grid on; title('Polos e zeros (malha aberta)');
subplot(1,3,2); bode(G); grid on; title('Resposta em frequencia');
subplot(1,3,3); step(G, 6); grid on; title('Resposta ao degrau (1 V)');
exportgraphics(f, 'l7_malha_aberta.png', 'Resolution', 150);
f2 = figure('Visible','off','Position',[100 100 1000 600]);
for k = 1:2, subplot(2,1,k); plot(yv{k}); hold on; plot(sim(th, uv{k})); grid on; legend('medido (filtrado)','modelo'); title(vals{k}, 'Interpreter','none'); end
exportgraphics(f2, 'l7_validacao.png', 'Resolution', 150);

function [u, yf] = carrega(pasta, nomes, C, Ts, dec, af, d_zm)
    nd = round(8/Ts); Af = [1 -af]; Bf = (1-af)*[1 -1]; u = cell(1,numel(nomes)); yf = u;
    for k = 1:numel(nomes)
        S = load(fullfile(pasta, [nomes{k} '.mat']), 'ScopeData').ScopeData; S = S(1:dec:end, :); i = (nd+1):size(S,1);
        yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke; u{k} = detrend(sign(S(i,2)).*max(abs(S(i,2))-d_zm, 0), 'constant');   % zona morta de largura d (V) na entrada
        yf{k} = detrend(filter(Bf, Af, yt - yt(1)), 'constant');
    end
end
function z = comum(x, af, ref)                                   % leva um sinal filtrado com af para o dominio af_ref
    z = filter((1-ref)*[1 -af], (1-af)*[1 -ref], x);
end
