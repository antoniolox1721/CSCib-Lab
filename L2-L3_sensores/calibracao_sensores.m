%% CALIBRACAO_SENSORES.m
% -------------------------------------------------------------------
% Calibracao dos sensores da barra flexivel (Trabalho de Laboratorio,
% Controlo de Sistemas Ciber-Fisicos - Parte I, sessoes L2-L3).
%
% Este script calcula:
%   Kp     [graus/V] - constante do transdutor de posicao angular do veio
%   Ke     [graus/V] - constante do transdutor de deflexao da barra
%   offset [V]       - desvio ("bias") do extensometro para deflexao nula
%
% O script esta dividido em seccoes (%%). Corre cada seccao com
% Ctrl+Enter, uma de cada vez, na ordem em que aparecem. No final de
% cada seccao os resultados sao gravados em disco, para nao se perder
% trabalho caso o MATLAB feche ou a ligacao ao hardware falhe a meio.
%
% IMPORTANTE: guarda este ficheiro e os .mat que ele produz no disco
% local (nesta pasta) e faz copia regular para a pen USB no final da
% sessao - nao trabalhes diretamente a partir da pen.
% -------------------------------------------------------------------

%% Seccao 0 - Configuracao inicial
clear; clc; close all;

% Caminho para os ficheiros auxiliares fornecidos (zero_pot.m,
% zero_use_for_calibration.m, view_io.m, etc.). Ajusta se necessario.
pasta_lab = pwd;   % estes scripts vivem na propria pasta do L2-L3
if exist(pasta_lab, 'dir')
    addpath(pasta_lab);
else
    warning('Pasta do Lab2 nao encontrada em "%s". Ajusta a variavel pasta_lab.', pasta_lab);
end

ficheiro_calibracao = fullfile(pwd, 'calibracao_sensores.mat');
fprintf('Os resultados desta calibracao serao gravados em:\n  %s\n', ficheiro_calibracao);

%% Seccao 1 - Zero do potenciometro (passo fisico, sem calculo numerico)
% -------------------------------------------------------------------
% Corre a funcao fornecida "zero_pot" e segue as instrucoes no ecra:
% roda manualmente a barra flexivel ate a marca de "direcao zero" e
% confirma quando o potenciometro estiver a ler aproximadamente 0 V.
%
%   >> zero_pot
%
% Este passo define mecanicamente onde theta = 0 graus. Nao produz
% nenhuma variavel numerica para usar mais tarde: e apenas o alinhamento
% fisico do veio do motor com a direcao de referencia.
%
% Depois de correr "zero_pot", confirma aqui que a leitura do
% potenciometro esta perto de zero (ajusta o nome da variavel conforme
% o que tiveres no workspace depois do zero_pot).
% -------------------------------------------------------------------

fprintf(['\n>>> Passo manual: corre "zero_pot" agora, se ainda nao o fizeste,\n' ...
         '    e confirma visualmente que a leitura do potenciometro fica perto de 0 V.\n\n']);

%% Seccao 2 - Calibracao do potenciometro (Kp) - metodo do sinal em dente-de-serra
% -------------------------------------------------------------------
% Metodo i) do guiao (Seccao 3.5, passo 18): aplica um degrau de 1 V ao
% motor e deixa-o rodar continuamente. O sinal do potenciometro (theta_e)
% forma um dente-de-serra, porque o valor medido repete-se a cada volta
% completa do veio (360 graus). A amplitude pico-a-pico de UMA rampa
% (sem contar com o salto de reset) corresponde exatamente a 360 graus,
% seja qual for a velocidade de rotacao.
%
% Carrega os dados gravados com "view_io save" (ficheiro
% ScopeData_<pc>_<data>.mat, variavel "ScopeData", array Nx6 com colunas
% [tempo, ref, potenciometro, extensometro, ...]). Se em vez disso
% tiveres gravado a partir do teu proprio modelo Simulink (variavel
% "input", estrutura com time/signals.values), muda o troço de carga
% abaixo para usar esse formato.
% -------------------------------------------------------------------

% --- Ajusta o nome do ficheiro .mat gravado com "view_io save" ---
ficheiro_dados_kp = fullfile(pasta_lab, 'ScopeData_PC0712_260921_142044.mat');   % <-- muda para o teu ficheiro

if exist(ficheiro_dados_kp, 'file')
    S = load(ficheiro_dados_kp);
    t_kp   = S.ScopeData(:,1);
    thetae = S.ScopeData(:,3);   % coluna 3 = potenciometro (ver view_io.m: [tempo ref pot extensometro])

    % Deteta as rampas do dente-de-serra: um "reset" acontece quando o
    % sinal desce (ou sobe) mais do que metade da gama do sensor entre
    % duas amostras consecutivas.
    dtheta = diff(thetae);
    limiar_reset = 0.5 * (max(thetae) - min(thetae));
    idx_reset = find(abs(dtheta) > limiar_reset);

    amplitudes_pico_a_pico = [];
    idx_inicio = 1;
    for k = 1:length(idx_reset)
        idx_fim = idx_reset(k);
        segmento = thetae(idx_inicio:idx_fim);
        if numel(segmento) > 5   % ignora segmentos demasiado curtos (ruido)
            amplitudes_pico_a_pico(end+1) = max(segmento) - min(segmento); %#ok<SAGROW>
        end
        idx_inicio = idx_fim + 1;
    end

    if isempty(amplitudes_pico_a_pico)
        error(['Nao foi possivel detetar nenhuma rampa completa no sinal do ' ...
               'potenciometro. Verifica se o motor rodou pelo menos uma volta completa.']);
    end

    % Usa a mediana, nao a media: a 1a rampa inclui o transitorio de
    % arranque do degrau e costuma ficar mais curta que as restantes
    % (confirmado nos dados reais: 3.97 V vs ~10.33 V nas rampas seguintes).
    % A mediana ignora esse outlier sem ser preciso descartar manualmente
    % a 1a rampa.
    amplitude_media = median(amplitudes_pico_a_pico);
    Kp = 360 / amplitude_media;   % [graus/V]

    fprintf('Numero de rampas detetadas: %d\n', numel(amplitudes_pico_a_pico));
    fprintf('Amplitude pico-a-pico (mediana) de uma rampa: %.4f V\n', amplitude_media);
    fprintf('Kp estimado = %.4f graus/V\n', Kp);

    figure('Name', 'Calibracao do potenciometro (Kp)');
    plot(t_kp, thetae, 'LineWidth', 1.2);
    xlabel('Tempo [s]');
    ylabel('Tensao do potenciometro, \theta_e [V]');
    title('Sinal em dente-de-serra usado para calcular K_p');
    grid on;

    % Verificacao de plausibilidade
    if Kp <= 0 || ~isfinite(Kp)
        warning('Kp com valor suspeito (%.4f). Confirma os dados antes de continuar.', Kp);
    end

    save(ficheiro_calibracao, 'Kp', 't_kp', 'thetae', 'amplitudes_pico_a_pico');
    fprintf('Kp gravado em "%s".\n', ficheiro_calibracao);
else
    warning(['Ficheiro "%s" nao encontrado. Grava primeiro os dados do ensaio ' ...
             'do potenciometro (variavel "input") a partir do Simulink.'], ficheiro_dados_kp);
end

%% Seccao 2b (alternativa) - Calibracao do potenciometro por rotacao manual conhecida
% -------------------------------------------------------------------
% Metodo ii) do guiao: roda a caixa manualmente por incrementos de
% angulo conhecidos e regista a tensao correspondente. Usa esta seccao
% em vez da 2 se tiveres seguido este metodo. Preenche os vetores
% "angulos_graus" e "tensoes_V" com os teus dados.
% -------------------------------------------------------------------

usar_metodo_manual = false;   % muda para true se usares este metodo

if usar_metodo_manual
    angulos_graus = [];   % <-- preenche com os angulos impostos (graus)
    tensoes_V     = [];   % <-- preenche com as tensoes lidas (V)

    if isempty(angulos_graus) || isempty(tensoes_V)
        error('Preenche os vetores angulos_graus e tensoes_V antes de correr esta seccao.');
    end

    p = polyfit(tensoes_V, angulos_graus, 1);
    Kp = p(1);
    offset_theta = p(2);

    yfit = polyval(p, tensoes_V);
    ss_res = sum((angulos_graus - yfit).^2);
    ss_tot = sum((angulos_graus - mean(angulos_graus)).^2);
    R2_Kp = 1 - ss_res/ss_tot;

    figure('Name', 'Calibracao do potenciometro (Kp) - metodo manual');
    plot(tensoes_V, angulos_graus, 'o', tensoes_V, yfit, '-');
    xlabel('Tensao do potenciometro, \theta_e [V]');
    ylabel('Angulo imposto, \theta [graus]');
    title(sprintf('Ajuste linear: K_p = %.4f graus/V, R^2 = %.4f', Kp, R2_Kp));
    legend('Pontos experimentais', 'Reta ajustada', 'Location', 'best');
    grid on;

    fprintf('Kp estimado (metodo manual) = %.4f graus/V (offset = %.4f graus, R2 = %.4f)\n', ...
        Kp, offset_theta, R2_Kp);

    save(ficheiro_calibracao, 'Kp', 'offset_theta', 'angulos_graus', 'tensoes_V', 'R2_Kp', '-append');
    fprintf('Kp (metodo manual) gravado em "%s".\n', ficheiro_calibracao);
end

%% Seccao 3 - Zero do extensometro (offset do sinal de deflexao)
% -------------------------------------------------------------------
% O extensometro (ponte de Wheatstone) nao pode ser posto fisicamente a
% zero como o potenciometro: tem sempre um pequeno desvio ("bias").
% Este desvio e calculado a partir de uma gravacao feita com a barra
% em repouso, sem deflexao.
%
% Passos (fora deste script, no Simulink/MATLAB):
%   1) Com a barra montada e sem deflexao, adquire um pequeno registo do
%      sinal do extensometro (por ex. correndo o modelo de zero ou o
%      "view_record_pci6221_20ms.mdl" durante alguns segundos).
%   2) Confirma que os dados ficam disponiveis no workspace como
%      "ScopeData".
%   3) Corre:
%        >> zero_use_for_calibration
%      Isto cria no workspace base as variaveis:
%        strain_gauge_offset            (o "offset" que procuramos, em V)
%        strain_gauge_gain_after_offset (sempre 1, ignorar)
% -------------------------------------------------------------------

ficheiro_offset = fullfile(pasta_lab, 'Data_Lab2_3', 'strain_gauge_offset.mat');

if evalin('base', 'exist(''strain_gauge_offset'', ''var'')')
    offset = evalin('base', 'strain_gauge_offset');
    fprintf('offset do extensometro (strain_gauge_offset, workspace) = %.6f V\n', offset);
elseif exist(ficheiro_offset, 'file')
    % "zero_use_for_calibration" ja foi corrido nesta sessao de lab e o
    % resultado ficou gravado em disco (nao esta no workspace atual).
    O = load(ficheiro_offset, 'strain_gauge_offset');
    offset = O.strain_gauge_offset;
    fprintf('offset do extensometro (strain_gauge_offset, ficheiro) = %.6f V\n', offset);
end

if exist('offset', 'var')
    save(ficheiro_calibracao, 'offset', '-append');
    fprintf('offset gravado em "%s".\n', ficheiro_calibracao);
else
    warning(['Variavel "strain_gauge_offset" nao encontrada no workspace nem em "%s". ' ...
             'Corre "zero_use_for_calibration" antes desta seccao.'], ficheiro_offset);
end

%% Seccao 4 - Calibracao da deflexao da barra (Ke) com o pente
% -------------------------------------------------------------------
% Usa o pente de calibracao (Figuras 6 e 7 do guiao): desvia a barra por
% incrementos conhecidos de 1/4 polegada (1 polegada = 2.54 cm) e regista
% a tensao correspondente do extensometro para cada posicao.
%
% Preenche os vetores abaixo com os teus dados experimentais:
%   n_slots     - numero de ranhuras desviadas (negativo = outro lado)
%   comprimento_barra_m - comprimento L da barra, em metros
%   tensoes_alphae_V    - tensao medida pelo extensometro, em V
% -------------------------------------------------------------------

n_slots              = [];   % <-- preenche, ex.: -4:4
comprimento_barra_m  = 0.30; % <-- confirma o valor real de L
tensoes_alphae_V     = [];   % <-- preenche, mesma dimensao que n_slots

if isempty(n_slots) || isempty(tensoes_alphae_V)
    warning('Preenche n_slots e tensoes_alphae_V com os dados do pente antes de continuar.');
else
    if ~exist('offset', 'var')
        error('Corre primeiro a Seccao 3 para obter o "offset" do extensometro.');
    end

    polegada_m = 0.0254;
    D_m = n_slots * (1/4) * polegada_m;              % deflexao linear, em metros
    alpha_rad = D_m / comprimento_barra_m;            % aproximacao de angulo pequeno
    alpha_graus = alpha_rad * 180/pi;                 % conversao para graus

    tensoes_corrigidas = tensoes_alphae_V(:) - offset;% remove o bias do sensor

    p = polyfit(tensoes_corrigidas, alpha_graus(:), 1);
    Ke = p(1);              % [graus/V]
    intercept_residual = p(2);  % devia ser proximo de 0 se o offset estiver bem calculado

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

    fprintf('Ke estimado = %.4f graus/V (R2 = %.4f)\n', Ke, R2_Ke);
    if abs(intercept_residual) > 0.5
        warning(['O termo independente do ajuste (%.4f graus) nao esta perto de zero. ' ...
                 'Confirma se o "offset" da Seccao 3 foi bem calculado.'], intercept_residual);
    end
    if R2_Ke < 0.98
        warning('R^2 baixo (%.4f) no ajuste de Ke. Revê os dados do pente.', R2_Ke);
    end

    save(ficheiro_calibracao, 'Ke', 'n_slots', 'comprimento_barra_m', ...
        'tensoes_alphae_V', 'alpha_graus', 'R2_Ke', '-append');
    fprintf('Ke gravado em "%s".\n', ficheiro_calibracao);
end

%% Seccao 5 - Resumo final e verificacao de integridade
% -------------------------------------------------------------------
% Confere que todas as constantes necessarias existem e sao validas
% antes de avancar para o script de identificacao do modelo.
% -------------------------------------------------------------------

variaveis_necessarias = {'Kp', 'Ke', 'offset'};
tudo_ok = true;

for i = 1:numel(variaveis_necessarias)
    nome = variaveis_necessarias{i};
    if ~exist(nome, 'var')
        fprintf('[EM FALTA] %s ainda nao foi calculado.\n', nome);
        tudo_ok = false;
    elseif ~isfinite(eval(nome))
        fprintf('[INVALIDO] %s = %g nao e um valor finito.\n', nome, eval(nome));
        tudo_ok = false;
    else
        fprintf('[OK] %s = %g\n', nome, eval(nome));
    end
end

if tudo_ok
    fprintf('\nCalibracao completa e valida. Constantes gravadas em "%s".\n', ficheiro_calibracao);
    fprintf('Podes avancar para "identificacao_modelo.m".\n');
else
    fprintf('\nCalibracao incompleta - corre as seccoes em falta antes de avancar.\n');
end
