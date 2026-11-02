%% CALIBRAR_KE_PENTE.m
% -------------------------------------------------------------------
% Recolha guiada dos dados do pente de calibracao para o Ke (Sessao L3,
% ver Lab4.txt e guia Sec. 2.2/3.5 passo 19), com ajuste por minimos
% quadrados no final. Companheiro interativo da Seccao 4 de
% "calibracao_sensores.m": em vez de colares os vetores n_slots /
% tensoes_alphae_V a mao, corre este script UMA VEZ e ele pergunta-te
% a posicao do pente a cada volta, le o ScopeData da aquisicao de 2s,
% e tira a mediana da tensao do extensometro por ti.
%
% Pre-requisito: secoes 0-3 de "calibracao_sensores.m" ja correram
% (precisamos do "offset" do extensometro em calibracao_sensores.mat).
%
% Fluxo a cada posicao do pente:
%   1) Move fisicamente o pente para a ranhura n (ex.: +7 .. -7).
%   2) Corre a aquisicao Simulink de ~2s (view_io('acquire') ou o
%      ficheiro "_20ms" conforme o setup da bancada) para que
%      "ScopeData" fique no workspace base.
%   3) Volta ao MATLAB e prime Enter neste script: ele le o ScopeData,
%      tira a mediana da coluna do extensometro, e guarda a leitura.
%   4) Repete para outra ranhura, ou escreve "fim" para terminar.
%
% No fim, ajusta Ke por minimos quadrados (mesma formula do guia e da
% Seccao 4 de calibracao_sensores.m: alpha[graus] = (D/L)*180/pi,
% alpha = Ke*(alphae-offset)) e grava tudo em "calibracao_sensores.mat"
% (append), para "identificacao_modelo.m" continuar a funcionar.
% Tambem exporta um CSV com as mesmas colunas da folha "Registo Ke" do
% Excel do pente, para copiares/comparares com o que la esta.
% -------------------------------------------------------------------

%% Seccao 0 - Configuracao inicial
clear; clc; close all;

pasta_lab = pwd;   % estes scripts vivem na propria pasta do L2-L3
if exist(pasta_lab, 'dir')
    addpath(pasta_lab);
else
    warning('Pasta do Lab2_3 nao encontrada em "%s". Ajusta a variavel pasta_lab.', pasta_lab);
end

ficheiro_calibracao = fullfile(pwd, 'calibracao_sensores.mat');
assert(exist(ficheiro_calibracao, 'file') == 2, ...
    ['Nao encontrei "%s". Corre primeiro as Seccoes 0-3 de ' ...
     '"calibracao_sensores.m" (precisamos do offset do extensometro).'], ficheiro_calibracao);

O = load(ficheiro_calibracao, 'offset');
assert(isfield(O, 'offset') && isfinite(O.offset), ...
    'Falta um "offset" valido em "%s". Corre a Seccao 3 de "calibracao_sensores.m".', ficheiro_calibracao);
offset = O.offset;
fprintf('offset do extensometro carregado = %.6f V\n', offset);

comprimento_barra_m = 0.30;   % <-- confirma o valor real de L (guia Sec. 2.1)
resp = input(sprintf('Comprimento da barra L = %.3f m. Prime Enter para aceitar, ou escreve outro valor: ', ...
    comprimento_barra_m), 's');
if ~isempty(resp)
    comprimento_barra_m = str2double(resp);
    assert(isfinite(comprimento_barra_m) && comprimento_barra_m > 0, 'L invalido.');
end

polegada_m = 0.0254;

%% Seccao 1 - Recolha interativa das posicoes do pente
% -------------------------------------------------------------------
% Guarda ate 3 ensaios por ranhura (mesmas colunas da folha "Registo
% Ke": Ensaio 1/2/3 + media), tal como o pente pode oscilar um pouco
% de ensaio para ensaio (guia Sec. 2.2, "pequenas flutuacoes aleatorias").
% Uma unica leitura por posicao tambem e valida (fica so a Ensaio 1).
% -------------------------------------------------------------------

leituras = containers.Map('KeyType', 'double', 'ValueType', 'any');   % n -> [v1 v2 v3]

fprintf(['\n=== Calibracao do pente (Ke) ===\n' ...
    'Para cada ranhura: move o pente, corre a aquisicao de 2s, e volta aqui.\n' ...
    'Escreve "fim" quando tiveres ranhuras suficientes (pelo menos 3, idealmente ' ...
    'toda a gama disponivel, ex. +7 a -7).\n\n']);

while true
    n_str = input('Numero da ranhura n (positivo/negativo/0), ou "fim": ', 's');
    if strcmpi(strtrim(n_str), 'fim')
        break
    end
    n = str2double(n_str);
    if ~isfinite(n)
        fprintf('  -> nao percebi "%s", tenta outra vez.\n', n_str);
        continue
    end

    if isKey(leituras, n)
        fprintf('  (ja ha leituras para n=%g, vou acrescentar mais ensaios)\n', n);
        vals = leituras(n);
    else
        vals = [];
    end

    n_ensaios = input('  Quantos ensaios nesta ranhura (Enter = 1, max 3): ', 's');
    if isempty(n_ensaios)
        n_ensaios = 1;
    else
        n_ensaios = round(str2double(n_ensaios));
    end
    n_ensaios = max(1, min(3, n_ensaios));

    for e = 1:n_ensaios
        input(sprintf('  Ensaio %d/%d: corre agora a aquisicao de ~2s na bancada e prime Enter aqui quando terminar...', ...
            e, n_ensaios));
        v = ler_mediana_extensometro();
        if isnan(v)
            fprintf('  -> nao consegui ler ScopeData, ensaio descartado.\n');
            continue
        end
        vals(end+1) = v; %#ok<AGROW>
        fprintf('  -> mediana tensao extensometro = %.5f V\n', v);
    end

    if numel(vals) > 3
        vals = vals(end-2:end);   % mantem so os 3 mais recentes, como a folha "Registo Ke"
    end
    leituras(n) = vals;
end

assert(leituras.Count >= 3, ...
    'Precisas de pelo menos 3 ranhuras diferentes para ajustar Ke. Corre o script outra vez.');

%% Seccao 2 - Ajuste de Ke por minimos quadrados
% -------------------------------------------------------------------
% Mesma formula do guia (Sec. 2.1-2.2) e da Seccao 4 de
% "calibracao_sensores.m": D = n*(1/4)*polegada; alpha[rad] = D/L;
% alpha[graus] = alpha[rad]*180/pi; ajusta alpha = Ke*(alphae-offset).
% -------------------------------------------------------------------

n_slots = sort(cell2mat(keys(leituras)));
n_ensaios_max = 3;
tabela = nan(numel(n_slots), n_ensaios_max);
tensoes_alphae_V = nan(size(n_slots));

for i = 1:numel(n_slots)
    vals = leituras(n_slots(i));
    tabela(i, 1:numel(vals)) = vals;
    tensoes_alphae_V(i) = mean(vals);
end

D_m = n_slots * (1/4) * polegada_m;
alpha_rad = D_m / comprimento_barra_m;
alpha_graus = alpha_rad * 180/pi;

tensoes_corrigidas = tensoes_alphae_V(:) - offset;
p = polyfit(tensoes_corrigidas, alpha_graus(:), 1);
Ke = p(1);
intercept_residual = p(2);

yfit = polyval(p, tensoes_corrigidas);
ss_res = sum((alpha_graus(:) - yfit).^2);
ss_tot = sum((alpha_graus(:) - mean(alpha_graus)).^2);
R2_Ke = 1 - ss_res/ss_tot;

figure('Name', 'Calibracao da deflexao da barra (Ke)');
plot(tensoes_corrigidas, alpha_graus, 'o', tensoes_corrigidas, yfit, '-');
xlabel('Tensao do extensometro corrigida, \alpha_e - offset [V]');
ylabel('Deflexao angular, \alpha [graus]');
title(sprintf('Ajuste linear: K_e = %.4f graus/V, R^2 = %.4f', Ke, R2_Ke));
legend('Pontos experimentais (pente)', 'Reta ajustada', 'Location', 'best');
grid on;

fprintf('\nKe estimado = %.4f graus/V (R2 = %.4f)\n', Ke, R2_Ke);
if abs(intercept_residual) > 0.5
    warning(['O termo independente do ajuste (%.4f graus) nao esta perto de zero. ' ...
             'Confirma se o "offset" foi bem calculado.'], intercept_residual);
end
if R2_Ke < 0.98
    warning('R^2 baixo (%.4f) no ajuste de Ke. Revê os dados do pente.', R2_Ke);
end

save(ficheiro_calibracao, 'Ke', 'n_slots', 'comprimento_barra_m', ...
    'tensoes_alphae_V', 'tabela', 'alpha_graus', 'R2_Ke', '-append');
fprintf('Ke gravado em "%s".\n', ficheiro_calibracao);

%% Seccao 3 - Exporta CSV no formato da folha "Registo Ke"
% -------------------------------------------------------------------
% Mesmas colunas da folha do Excel ja aberta (Ranhura n, D [pol],
% D [cm], Ensaio 1/2/3 [V], Media [V]) para copiares/conferires.
% -------------------------------------------------------------------

D_pol = n_slots * (1/4);
nome_csv = sprintf('registo_Ke_%s.csv', datestr(now, 'yymmdd_HHMM'));
fid = fopen(nome_csv, 'w');
fprintf(fid, 'Ranhura n,D [pol],D [cm],Ensaio 1 alphae [V],Ensaio 2 alphae [V],Ensaio 3 alphae [V],Media alphae [V]\n');
for i = 1:numel(n_slots)
    fprintf(fid, '%g,%g,%g,%s,%s,%s,%.5f\n', n_slots(i), D_pol(i), D_m(i)*100, ...
        fmt_ou_vazio(tabela(i,1)), fmt_ou_vazio(tabela(i,2)), fmt_ou_vazio(tabela(i,3)), ...
        tensoes_alphae_V(i));
end
fclose(fid);
fprintf('Tabela exportada para "%s" (mesmo formato da folha "Registo Ke").\n', nome_csv);


% ---------------------------------------------------------------------
function v = ler_mediana_extensometro()
% Le ScopeData do workspace base e devolve a mediana da coluna do
% extensometro (coluna 4, convencao [tempo ref pot extensometro] usada
% em todo o codigo do laboratorio - ver view_io.m e
% zero_use_for_calibration.m).
v = NaN;
if ~evalin('base', 'exist(''ScopeData'', ''var'')')
    return
end
ScopeData = evalin('base', 'ScopeData');
if isstruct(ScopeData)
    dados = ScopeData.signals.values;
else
    dados = ScopeData;
end
if size(dados, 2) < 4
    return
end
v = median(dados(:,4));
end

function s = fmt_ou_vazio(x)
if isnan(x)
    s = '';
else
    s = sprintf('%.5f', x);
end
end
