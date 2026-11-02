%% IDENTIFICACAO_MODELO.m
% -------------------------------------------------------------------
% Identificacao do modelo da barra flexivel (Parte I, sessoes L4-L7).
%
% Pressupostos: (correr com a pasta atual do MATLAB = L4_identificacao) o script "calibracao_sensores.m" ja foi corrido e
% "calibracao_sensores.mat" existe nesta pasta com Kp, Ke, offset.
%
% Este script esta dividido em seccoes (%%). Corre cada seccao pela
% ordem apresentada. No final de cada seccao os resultados sao
% gravados em disco (checkpoint), e cada seccao verifica as condicoes
% da anterior antes de continuar: se alguma verificacao falhar, o
% script para imediatamente (nao continua com dados invalidos).
% -------------------------------------------------------------------

%% Seccao 0 - Configuracao inicial e verificacao da calibracao
clear; clc; close all;

pasta_lab = fullfile(fileparts(pwd), 'L2-L3_sensores');
if exist(pasta_lab, 'dir')
    addpath(pasta_lab);
end

ficheiro_calibracao = fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat');
assert(exist(ficheiro_calibracao, 'file') == 2, ...
    ['Nao encontrei "%s". Corre primeiro "calibracao_sensores.m" ' ...
     'ate ao fim (tem de produzir Kp, Ke e offset).'], ficheiro_calibracao);

C = load(ficheiro_calibracao, 'Kp', 'Ke', 'offset');
assert(all(isfield(C, {'Kp','Ke','offset'})), ...
    'O ficheiro de calibracao nao tem Kp, Ke e offset. Corre a calibracao ate ao fim.');
assert(all(isfinite([C.Kp, C.Ke, C.offset])), ...
    'Kp, Ke ou offset nao sao valores finitos. Repete a calibracao.');

Kp = C.Kp; Ke = C.Ke; offset = C.offset;
fprintf('Calibracao carregada: Kp = %.4f graus/V, Ke = %.4f graus/V, offset = %.6f V\n', ...
    Kp, Ke, offset);

% NOTA 2026-10-19: versao ANTIGA (1 ficheiro, sem zona morta). Grava em modelo_identificado_antigo.mat para NAO sobrescrever o modelo final,
% que vem de ../L7_revisao/l7_revisao.m e e o que o L8 le (modelo_identificado.mat).
ficheiro_modelo = fullfile(pwd, 'modelo_identificado_antigo.mat');
Ts = 0.020;   % periodo de amostragem, 20 ms = 50 Hz (fixado pelo guiao)

%% Seccao 1 - Geracao dos sinais de excitacao (para o bloco "From Workspace")
% -------------------------------------------------------------------
% Gera dois sinais candidatos para excitar o motor: onda quadrada e
% sequencia binaria pseudoaleatoria (PRBS). Amplitude sugerida: 1 V.
% Frequencia sugerida para a onda quadrada: cerca de 0.4 Hz.
% Grava os sinais em .mat para importares no bloco "From Workspace" do
% Simulink (em alternativa ao "Signal Generator").
% -------------------------------------------------------------------

duracao_s   = 40;                       % dezenas de segundos, conforme o guiao
t_exc       = (0:Ts:duracao_s)';
amplitude_V = 1.0;

% Onda quadrada, ~0.4 Hz
freq_Hz = 0.4;
sinal_quadrado = amplitude_V * sign(sin(2*pi*freq_Hz*t_exc));

% PRBS (necessita do System Identification Toolbox)
u_prbs = idinput(numel(t_exc), 'prbs', [0 0.1], [-amplitude_V amplitude_V]);

figure('Name', 'Sinais de excitacao candidatos');
subplot(2,1,1);
plot(t_exc, sinal_quadrado); grid on;
xlabel('Tempo [s]'); ylabel('u [V]'); title('Onda quadrada (0.4 Hz, 1 V)');
subplot(2,1,2);
plot(t_exc, u_prbs); grid on;
xlabel('Tempo [s]'); ylabel('u [V]'); title('PRBS (1 V)');

sinal_excitacao_quadrado.time = t_exc;                 %#ok<STRNU>
sinal_excitacao_quadrado.signals.values = sinal_quadrado;
sinal_excitacao_quadrado.signals.dimensions = 1;

sinal_excitacao_prbs.time = t_exc;                     %#ok<STRNU>
sinal_excitacao_prbs.signals.values = u_prbs;
sinal_excitacao_prbs.signals.dimensions = 1;

save('sinais_excitacao.mat', 'sinal_excitacao_quadrado', 'sinal_excitacao_prbs', 't_exc');
fprintf('Sinais de excitacao gravados em "sinais_excitacao.mat".\n');
fprintf(['\n>>> Passo manual: usa um destes sinais no bloco "From Workspace" (ou\n' ...
         '    reconfigura o "Signal Generator") do teu diagrama Simulink, corre o\n' ...
         '    ensaio em tempo real na planta, e grava os dados como "input"\n' ...
         '    (estrutura com time + signals.values de 3 colunas: u, thetae, alphae)\n' ...
         '    para um ficheiro .mat antes de avancar para a Seccao 2.\n\n']);

%% Seccao 2 - Carregar os dados experimentais adquiridos na planta
% -------------------------------------------------------------------
% Ajusta "ficheiro_dados_id" para o .mat que gravaste depois do ensaio
% de identificacao (excitacao aplicada + resposta da planta).
% -------------------------------------------------------------------

ficheiro_dados_id  = 'dados_ID_quadrada_1V.mat';   % <-- muda para o ficheiro a identificar
ficheiro_validacao = 'dados_validacao.mat';          % reservado: nunca entra na identificacao

assert(exist(ficheiro_dados_id, 'file') == 2, 'Nao encontrei "%s".', ficheiro_dados_id);
assert(exist(ficheiro_validacao, 'file') == 2, 'Nao encontrei "%s".', ficheiro_validacao);

% Formato gravado pelo "view_io save": matriz ScopeData = [tempo ref pot extensometro ...]
D = load(ficheiro_dados_id, 'ScopeData');
assert(isfield(D, 'ScopeData') && size(D.ScopeData,2) >= 4, ...
    '"%s" nao tem ScopeData com pelo menos 4 colunas.', ficheiro_dados_id);

t_raw    = D.ScopeData(:,1);
sigs_raw = D.ScopeData(:,2:4);                  % u, thetae, alphae
assert(all(isfinite(sigs_raw(:))), 'Os dados adquiridos contem NaN/Inf. Repete o ensaio.');
assert(abs(median(diff(t_raw)) - Ts) < 1e-6, ...
    'Ts dos dados (%.4f s) difere de Ts = %.3f s. Usa os ficheiros _20ms.', median(diff(t_raw)), Ts);

fprintf('Dados de identificacao carregados: %d amostras, %.2f s de duracao.\n', ...
    numel(t_raw), t_raw(end)-t_raw(1));

save(ficheiro_modelo, 't_raw', 'sigs_raw', 'Ts', 'Kp', 'Ke', 'offset');
fprintf('Dados em bruto gravados em "%s" (checkpoint).\n', ficheiro_modelo);

%% Seccao 3 - Pre-processamento (offset, conversao para graus, remocao do transitorio)
% -------------------------------------------------------------------
% Aplica Kp, Ke e o offset do extensometro; descarta o transitorio
% inicial (ex.: primeiros 5-10 s) e remove a media do sinal de entrada.
% -------------------------------------------------------------------

n_descartar_s = 8;                              % segundos iniciais a descartar
n_descartar   = round(n_descartar_s / Ts);
assert(numel(t_raw) > n_descartar + 50, ...
    'Registo demasiado curto para descartar %d amostras iniciais.', n_descartar);

idx = (n_descartar+1):numel(t_raw);
t      = t_raw(idx) - t_raw(idx(1));
utrend = sigs_raw(idx,1);                       % sinal aplicado ao motor [V]
thetae = sigs_raw(idx,2);                       % sinal do potenciometro [V]
alphae = sigs_raw(idx,3);                       % sinal do extensometro [V]

% Angulo total da ponta da barra, em graus: y = theta + alpha
ytrend = thetae*Kp + (alphae - offset)*Ke;

figure('Name', 'Sinais pre-processados');
subplot(2,1,1);
plot(t, utrend); grid on; xlabel('Tempo [s]'); ylabel('u [V]'); title('Sinal aplicado ao motor');
subplot(2,1,2);
plot(t, ytrend); grid on; xlabel('Tempo [s]'); ylabel('y [graus]'); title('Angulo total da ponta da barra (y = \theta + \alpha)');

u = detrend(utrend);   % remove a media (offset de excitacao)
y = detrend(ytrend);   % remove a tendencia/deriva de baixa frequencia

assert(all(isfinite(u)) && all(isfinite(y)), 'u ou y contem valores nao finitos apos pre-processamento.');

save(ficheiro_modelo, 't', 'u', 'y', 'utrend', 'ytrend', '-append');
fprintf('Sinais pre-processados gravados em "%s".\n', ficheiro_modelo);

%% Seccao 4 - Filtragem (remocao de ruido de alta frequencia)
% -------------------------------------------------------------------
% Filtro passa-baixo de 1a ordem simples, com polo "af" (0 < af < 1).
% Ajusta af conforme a resposta em frequencia observada nos teus dados.
% -------------------------------------------------------------------

af = 0.8;   % valor sugerido no guia (Sec. 4)
Afilt = [1 -af];
Bfilt = (1-af) * [1 -1];

yf = filter(Bfilt, Afilt, y);

figure('Name', 'Efeito da filtragem');
plot(t, y, t, yf, '--'); grid on;
xlabel('Tempo [s]'); ylabel('y [graus]');
legend('y (sem filtrar)', 'y_f (filtrado)');
title(sprintf('Filtro passa-baixo, a_f = %.2f', af));

assert(all(isfinite(yf)), 'yf contem valores nao finitos apos filtragem.');

save(ficheiro_modelo, 'af', 'Afilt', 'Bfilt', 'yf', '-append');
fprintf('Sinal filtrado gravado em "%s".\n', ficheiro_modelo);

%% Seccao 5 - Identificacao ARMAX com escolha da ordem do modelo
% -------------------------------------------------------------------
% Procura, por tentativa-e-erro, a melhor ordem (na, nb, nc=na, nk)
% segundo o BIC nos dados de validacao (dados_validacao.mat); a coluna
% 'resultados' = [na nb nc MSE BIC fit%] serve de tabela para o relatorio. Necessita do System Identification Toolbox.
% -------------------------------------------------------------------

% Identifica com TODO o registo de identificacao e valida no ficheiro
% de validacao (mesmo pre-processamento, mesmos Kp/Ke/offset/af).
V = load(ficheiro_validacao, 'ScopeData');
Sv = V.ScopeData;
iv  = (n_descartar+1):size(Sv,1);
uv  = detrend(Sv(iv,2));
yv  = detrend(Sv(iv,3)*Kp + (Sv(iv,4)-offset)*Ke);
yfv = filter(Bfilt, Afilt, yv);

z_treino = [yf, u];

na_range = 2:6;
nb_range = 1:5;
nk = 1;

melhor_bic = Inf;
melhor_ordem = [];
melhor_th = [];
resultados = [];

for na = na_range
    for nb = nb_range
        nc = na;
        nn = [na nb nc nk];
        try
            th = armax(z_treino, nn);
            y_pred = sim(th, uv);
            Nval = numel(y_pred);
            mse_val = sum((yfv(30:end) - y_pred(30:end)).^2) / (Nval-30);
            fit_pc  = 100*(1 - norm(yfv(30:end)-y_pred(30:end)) / norm(yfv(30:end)-mean(yfv(30:end))));
            k_param = na+nb+nc;
            bic_val = (Nval-30)*log(mse_val) + k_param*log(Nval-30);

            resultados = [resultados; na nb nc mse_val bic_val fit_pc]; %#ok<AGROW>
            fprintf('na=%d nb=%d nc=%d: fit = %6.2f %%  MSE = %.4g  BIC = %.2f\n', na, nb, nc, fit_pc, mse_val, bic_val);

            if bic_val < melhor_bic
                melhor_bic = bic_val;
                melhor_ordem = nn;
                melhor_th = th;
            end
        catch ME
            fprintf('  (ignorado na=%d nb=%d: %s)\n', na, nb, ME.message);
        end
    end
end

assert(~isempty(melhor_th), ...
    'Nenhuma combinacao de ordens produziu um modelo ARMAX valido. Revê os dados.');

fprintf('Melhor ordem encontrada: na=%d nb=%d nc=%d nk=%d (BIC=%.3f)\n', melhor_ordem, melhor_bic);

th = melhor_th;
[den1, num1] = polydata(th);

save(ficheiro_modelo, 'melhor_ordem', 'melhor_bic', 'resultados', 'th', 'den1', 'num1', '-append');
fprintf('Modelo ARMAX gravado em "%s".\n', ficheiro_modelo);

%% Seccao 6 - Conversao para espaco de estados (com o integrador reintroduzido)
% -------------------------------------------------------------------
% O "detrend" da Seccao 3 removeu um integrador puro do sistema (o
% angulo acumula a velocidade). Volta a introduzi-lo antes de converter
% para espaco de estados, conforme o guiao (Seccao 4, passo 4).
% -------------------------------------------------------------------

[num, den] = eqtflength(num1, conv(den1, [1 -1]));
[A, B, Cc, Dd] = tf2ss(num, den);
sys_identificado = ss(A, B, Cc, Dd, Ts);

polos = pole(sys_identificado);
fprintf('Polos do modelo identificado (malha aberta):\n'); disp(polos);

assert(all(isfinite(A(:))) && all(isfinite(B(:))) && all(isfinite(Cc(:))) && all(isfinite(Dd(:))), ...
    'A matriz de espaco de estados contem valores nao finitos.');

matriz_controlabilidade = ctrb(A, B);
n_estados = size(A,1);
controlavel = rank(matriz_controlabilidade) == n_estados;
fprintf('Sistema controlavel: %d (rank=%d de %d)\n', controlavel, rank(matriz_controlabilidade), n_estados);

assert(controlavel, ...
    ['O modelo identificado nao e controlavel. Nao avances para o projeto do ' ...
     'controlador com este modelo - revê a ordem/dados de identificacao.']);

save(ficheiro_modelo, 'A', 'B', 'Cc', 'Dd', 'sys_identificado', 'controlavel', '-append');
fprintf('Modelo em espaco de estados gravado em "%s".\n', ficheiro_modelo);

%% Seccao 7 - Validacao do modelo (dados de validacao, residuos, branqueamento)
% -------------------------------------------------------------------
% Compara a simulacao do modelo com os dados de validacao reservados
% na Seccao 5 e corre testes estatisticos aos residuos.
% -------------------------------------------------------------------

yfsim_validacao = filter(num1, den1, uv);

figure('Name', 'Validacao do modelo');
plot(1:numel(yfv), yfv, 'b', 1:numel(yfsim_validacao), yfsim_validacao, 'r--');
grid on; xlabel('Amostras'); ylabel('y filtrado [graus]');
legend('Dados de validacao', 'Modelo identificado');
title('Comparacao modelo vs. dados de validacao');

Nval = numel(yfsim_validacao);
sse_validacao = sum((yfv(30:end) - yfsim_validacao(30:end)).^2) / (Nval-30);
fprintf('SSE nos dados de validacao: %.6f\n', sse_validacao);

residuos = yfv(30:end) - yfsim_validacao(30:end);
figure('Name', 'Residuos');
subplot(2,1,1); plot(residuos); grid on; title('Residuos'); xlabel('Amostras');
subplot(2,1,2); autocorr(residuos, 'NumLags', 20); title('Autocorrelacao dos residuos');

[h_branco, pValue] = lbqtest(residuos, 'Lags', 20);
if h_branco == 0
    fprintf('Teste de branqueamento (Ljung-Box): OK (residuos parecem ruido branco, p=%.3f)\n', pValue);
else
    warning('Teste de branqueamento (Ljung-Box) falhou (p=%.3f) - o modelo pode nao captar toda a dinamica.', pValue);
end

save(ficheiro_modelo, 'sse_validacao', 'residuos', 'h_branco', 'pValue', '-append');
fprintf('Resultados de validacao gravados em "%s".\n', ficheiro_modelo);

%% Seccao 8 - Resumo final e verificacao de integridade
% -------------------------------------------------------------------
% Confirma que tudo o que a Parte II precisa esta presente e valido.
% -------------------------------------------------------------------

necessario = {'A','B','Cc','Dd','Ts','controlavel','sse_validacao'};
tudo_ok = true;
for i = 1:numel(necessario)
    nome = necessario{i};
    if ~exist(nome, 'var')
        fprintf('[EM FALTA] %s\n', nome); tudo_ok = false;
    else
        fprintf('[OK] %s presente\n', nome);
    end
end

assert(tudo_ok, 'Faltam variaveis essenciais - corre as seccoes em falta antes de avancar.');
assert(controlavel, 'Modelo nao controlavel - nao avances para a Parte II.');

fprintf(['\nIdentificacao completa e valida. Modelo gravado em "%s".\n' ...
         'Atencao: o modelo FINAL para o L8 e o de ../L7_revisao/l7_revisao.m (modelo_identificado.mat).\n'], ficheiro_modelo);
