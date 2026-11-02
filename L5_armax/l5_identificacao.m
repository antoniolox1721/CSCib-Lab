% NOTA 2026-10-19: versao de PREPARACAO (sem zona morta). O modelo final usa l5_armax_oficial.m / ../L7_revisao/l7_revisao.m (zona morta 0,25 V).
%% L5_IDENTIFICACAO.m
% -------------------------------------------------------------------
% L5 - Processamento de dados e identificacao ARMAX (guia, Sec. 4).
% NAO precisa da planta. Corre com a pasta atual do MATLAB = L5_armax.
%
% Cadeia (igual ao guia): ScopeData -> y = theta*Kp + (alpha-offset)*Ke
%   -> derivar+filtrar (remove o integrador do motor) -> detrend
%   -> armax(z,[na nb nc nk]) -> fit em dados_validacao.mat.
%
% Seccoes (Ctrl+Enter, por ordem):
%   0 configuracao e carregamento     3 varrimento de ordens (tabela p/ relatorio)
%   1 pre-processamento + verificacao 4 modelo escolhido, Fig. 12, residuos
%   2 efeito do polo do filtro (af)
% Toolboxes: System Identification (armax, polydata). Sem mais nada.
% -------------------------------------------------------------------

%% Seccao 0 - Configuracao
clear; clc; close all;

pasta_dados = fullfile(fileparts(pwd), 'L4_identificacao');
ficheiro_calibracao = fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat');
assert(exist(ficheiro_calibracao, 'file') == 2, 'Falta "%s".', ficheiro_calibracao);
C = load(ficheiro_calibracao, 'Kp', 'Ke', 'offset');
assert(all(isfield(C, {'Kp','Ke','offset'})) && all(isfinite([C.Kp C.Ke C.offset])), ...
    'Calibracao invalida: repete a calibracao.');
Kp = C.Kp; Ke = C.Ke; offset = C.offset;

% Ficheiros de identificacao (adiciona o PRBS repetido quando o gravares).
ficheiros_id = {'dados_ID_quadrada_1V.mat'};
% ficheiros_id = {'dados_ID_quadrada_1V.mat', 'dados_ID_prbs_repeticao.mat'};
ficheiro_val = 'dados_validacao.mat';          % so para validar, nunca para identificar

Ts            = 0.020;   % 50 Hz, fixo pelo guia
af            = 0.8;     % polo do filtro (guia); testa 0.5-0.9 na Seccao 2
n_descartar_s = 8;       % transitorio inicial a ignorar (guia: 5-10 s)
na_range = 2:6;  nb_range = 1:5;  nk = 1;      % nc = na
Afilt = [1 -af];  Bfilt = (1-af)*[1 -1];       % derivada + passa-baixo

fprintf('Kp = %.4f  Ke = %.4f  offset = %.5f  |  af = %.2f\n', Kp, Ke, offset, af);

%% Seccao 1 - Carregar e pre-processar (identificacao + validacao)
nomes = [ficheiros_id, {ficheiro_val}];
dados = struct('nome', {}, 't', {}, 'u', {}, 'yf', {}, 'y', {});
for k = 1:numel(nomes)
    f = fullfile(pasta_dados, nomes{k});
    assert(exist(f, 'file') == 2, 'Nao encontrei "%s".', f);
    L = load(f, 'ScopeData');
    assert(isfield(L, 'ScopeData') && size(L.ScopeData, 2) >= 4, '"%s": ScopeData invalido.', nomes{k});
    S = L.ScopeData;                             % [tempo u pot extensometro ...]
    assert(all(isfinite(S(:))), '"%s" tem NaN/Inf.', nomes{k});
    assert(abs(median(diff(S(:,1))) - Ts) < 1e-6, '"%s" nao foi gravado a 20 ms.', nomes{k});

    i = (round(n_descartar_s/Ts)+1):size(S, 1);
    frac_sat = mean(abs(S(i,3)) > 4.9);          % potenciometro perto do limite (+-5,18 V = +-180 graus)
    if frac_sat > 0.01
        warning('"%s": potenciometro no limite em %.0f%% das amostras -> o angulo deu a volta. Repete o ensaio.', ...
            nomes{k}, 100*frac_sat);
    end

    ytrend = S(i,3)*Kp + (S(i,4) - offset)*Ke;   % angulo total da ponta [graus]
    u  = detrend(S(i,2), 'constant');            % tira a media da excitacao
    yf = filter(Bfilt, Afilt, ytrend - ytrend(1));   % derivar + filtrar (sem transitorio inicial)
    yf = detrend(yf, 'constant');

    dados(k).nome = nomes{k};  dados(k).t = S(i,1) - S(i(1),1);
    dados(k).u = u;  dados(k).yf = yf;  dados(k).y = ytrend;
    fprintf('%-28s N=%d  y:[%.1f, %.1f] graus  std(u)=%.2f  std(yf)=%.3f\n', ...
        nomes{k}, numel(u), min(ytrend), max(ytrend), std(u), std(yf));
end
kv = numel(dados);                               % indice da validacao (o ultimo)

figure('Name', 'Dados pre-processados');
for k = 1:numel(dados)
    subplot(numel(dados), 2, 2*k-1); plot(dados(k).t, dados(k).u); grid on;
    ylabel('u [V]'); title(strrep(dados(k).nome, '_', '\_'));
    subplot(numel(dados), 2, 2*k);   plot(dados(k).t, dados(k).yf); grid on;
    ylabel('y_f [graus/amostra]'); xlabel('Tempo [s]');
end

%% Seccao 2 - Efeito do polo do filtro (para a pergunta do guia + relatorio)
% H(z) = (1-af)(1 - z^-1)/(1 - af z^-1): zero em z=1 (derivada), polo em af (passa-baixo).
afs = [0.5 0.65 0.8 0.9];
w = logspace(-2, log10(pi), 400);
figure('Name', 'Filtro: resposta em frequencia');
for a = afs
    H = (1-a)*(1 - exp(-1j*w)) ./ (1 - a*exp(-1j*w));
    semilogx(w/(2*pi*Ts), 20*log10(abs(H))); hold on;
end
grid on; xlabel('Frequencia [Hz]'); ylabel('|H| [dB]');
legend(arrayfun(@(a) sprintf('a_f = %.2f', a), afs, 'UniformOutput', false), 'Location', 'southwest');
title('Derivada + passa-baixo: quanto maior a_f, menor a banda');

figure('Name', 'Filtro: efeito nos dados');
k0 = 1;  yk = dados(k0).y;
for a = afs
    plot(dados(k0).t, filter((1-a)*[1 -1], [1 -a], yk - yk(1))); hold on;
end
grid on; xlabel('Tempo [s]'); ylabel('graus/amostra');
legend(arrayfun(@(a) sprintf('a_f = %.2f', a), afs, 'UniformOutput', false));
title('Saida derivada e filtrada para varios a_f');

%% Seccao 3 - Varrimento de ordens (na, nb, nc = na, nk)
% Uma tabela por ficheiro de identificacao, validada em dados_validacao.
% fit% = 100*(1 - ||yv - ysim|| / ||yv - media||), simulacao livre B/A (como o guia).
uv = dados(kv).u;  yv = dados(kv).yf;
m0 = 30;                                          % ignora o arranque da simulacao
resultados = struct();
for k = 1:numel(ficheiros_id)
    linhas = [];
    for na = na_range
        for nb = nb_range
            nc = na;
            try
                th = armax([dados(k).yf, dados(k).u], [na nb nc nk]);
                [den1, num1] = polydata(th);
                ysim = filter(num1, den1, uv);
                e = yv(m0:end) - ysim(m0:end);
                fit = 100*(1 - norm(e)/norm(yv(m0:end) - mean(yv(m0:end))));
                pmax = max(abs(roots(den1)));
                Nv = numel(e);  bic = Nv*log(mean(e.^2)) + (na+nb+nc)*log(Nv);
                linhas = [linhas; na nb nc nk fit pmax bic]; %#ok<AGROW>
            catch ME
                fprintf('  (ignorado na=%d nb=%d: %s)\n', na, nb, ME.message);
            end
        end
    end
    assert(~isempty(linhas), 'Nenhum modelo valido para %s.', ficheiros_id{k});
    T = array2table(linhas, 'VariableNames', {'na','nb','nc','nk','fit_pc','polo_max','BIC'});
    T.estavel = T.polo_max < 1;
    T = sortrows(T, 'fit_pc', 'descend');
    resultados(k).nome = ficheiros_id{k};  resultados(k).T = T;
    writetable(T, sprintf('tabela_ordens_%s.csv', erase(ficheiros_id{k}, '.mat')));
    fprintf('\n=== %s (validacao: %s) ===\n', ficheiros_id{k}, ficheiro_val);
    disp(T(1:min(12, height(T)), :));
end

%% Seccao 4 - Modelo escolhido, Fig. 12 e residuos
% Escolha AUTOMATICA sugerida: o modelo estavel mais simples a menos de 1 ponto
% do melhor fit. Escreve na_esc/nb_esc para forcar outra escolha (justifica-a!).
k_esc = 1;                                        % qual ficheiro de identificacao usar
T = resultados(k_esc).T;  Te = T(T.estavel, :);
melhor = Te.fit_pc(1);
cand = Te(Te.fit_pc >= melhor - 1, :);
[~, j] = min(cand.na + cand.nb + cand.nc);
na_esc = cand.na(j);  nb_esc = cand.nb(j);        % <-- forca aqui se quiseres: na_esc = 3; nb_esc = 2;
nc_esc = na_esc;
fprintf('Modelo escolhido: na=%d nb=%d nc=%d nk=%d (melhor fit estavel = %.1f%%)\n', ...
    na_esc, nb_esc, nc_esc, nk, melhor);

th = armax([dados(k_esc).yf, dados(k_esc).u], [na_esc nb_esc nc_esc nk])
[den1, num1] = polydata(th);
ysim = filter(num1, den1, uv);
e = yv(m0:end) - ysim(m0:end);
fit_esc = 100*(1 - norm(e)/norm(yv(m0:end) - mean(yv(m0:end))));
fprintf('Fit na validacao = %.2f %% | polos: %s\n', fit_esc, mat2str(roots(den1).', 3));

figure('Name', 'Fig. 12 - modelo vs dados derivados');
tv = dados(kv).t;
plot(tv, yv, 'b', tv, ysim, 'r--'); grid on;
xlabel('Tempo [s]'); ylabel('y_f [graus/amostra]');
legend('Validacao (derivada filtrada)', sprintf('Modelo ARMAX [%d %d %d %d]', na_esc, nb_esc, nc_esc, nk));
title(sprintf('Fit na validacao: %.1f %%', fit_esc));

figure('Name', 'Residuos');
subplot(2,1,1); plot(tv(m0:end), e); grid on; ylabel('residuo'); xlabel('Tempo [s]');
x = e - mean(e); lags = 0:25;
r = arrayfun(@(l) sum(x(1+l:end).*x(1:end-l)), lags) / sum(x.^2);   % autocorrelacao (sem toolbox)
subplot(2,1,2); stem(lags, r); grid on;
xlabel('atraso [amostras]'); ylabel('autocorrelacao');
hold on; plot(lags, 1.96/sqrt(numel(e))*ones(size(lags)), 'r--', lags, -1.96/sqrt(numel(e))*ones(size(lags)), 'r--');   % banda 95%

save('l5_resultados.mat', 'na_esc', 'nb_esc', 'nc_esc', 'nk', 'af', 'den1', 'num1', 'fit_esc', ...
    'resultados', 'Kp', 'Ke', 'offset', 'Ts', 'ficheiros_id', 'ficheiro_val');
fprintf('Gravado em l5_resultados.mat. Proximo passo (L6): conv(den1,[1 -1]) + tf2ss + validacao.\n');
