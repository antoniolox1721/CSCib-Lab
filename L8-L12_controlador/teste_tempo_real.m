%% TESTE_TEMPO_REAL.m
% -------------------------------------------------------------------
% Parametriza e corre o diagrama Simulink de malha fechada (L10-L12).
%
% Pressupostos: "l7_revisao.m" (L7_revisao) e "projeto_controlador.m" ja
% foram corridos com sucesso e produziram, respetivamente,
% "../modelo_identificado.mat" e "controlador_lqg.mat".
%
% Este script:
%   1) carrega o modelo e o controlador,
%   2) constroi as matrizes do observador em forma padrao,
%   3) coloca tudo no workspace base (o diagrama Simulink le estas
%      variaveis pelo nome),
%   4) gera o diagrama (se ainda nao existir),
%   5) PARA e pede confirmacao explicita antes de sequer abrir o
%      modelo, e de novo antes de o correr - por seguranca.
% -------------------------------------------------------------------

%% Seccao 0 - Configuracao e carregamento
clear; clc; close all;

pasta_lab = fullfile(fileparts(pwd), 'L2-L3_sensores');
if exist(pasta_lab, 'dir')
    addpath(pasta_lab);
end

ficheiro_modelo = fullfile(fileparts(pwd), 'L4_identificacao', 'modelo_identificado.mat');
ficheiro_controlador = fullfile(pwd, 'controlador_lqg.mat');

assert(exist(ficheiro_modelo, 'file') == 2, 'Falta "%s" - corre "l7_revisao.m" (L7_revisao).', ficheiro_modelo);
assert(exist(ficheiro_controlador, 'file') == 2, 'Falta "%s" - corre "projeto_controlador.m".', ficheiro_controlador);

M = load(ficheiro_modelo, 'A','B','Cc','Dd','Ts','Kp','Ke','offset');
Ctl = load(ficheiro_controlador, 'K','L','Nbar');

campos_M = {'A','B','Cc','Dd','Ts','Kp','Ke','offset'};
campos_C = {'K','L','Nbar'};
assert(all(isfield(M, campos_M)), 'Ficheiro do modelo incompleto.');
assert(all(isfield(Ctl, campos_C)), 'Ficheiro do controlador incompleto.');

A = M.A; B = M.B; Cc = M.Cc; Dd = M.Dd; Ts = M.Ts;
Kp = M.Kp; Ke = M.Ke; offset = M.offset; %#ok<NASGU>
K = Ctl.K; L = Ctl.L; Nbar = Ctl.Nbar; %#ok<NASGU>

n = size(A,1);
assert(all(abs(eig(A-B*K)) < 1), 'Malha fechada de estado instavel - nao avances.');
assert(all(abs(eig(A-L*Cc)) < 1), 'Observador instavel - nao avances.');

fprintf('Modelo e controlador carregados e validados (%d estados).\n', n);

%% Seccao 1 - Construir as matrizes do observador em forma padrao
% -------------------------------------------------------------------
% xhat(k+1) = A*xhat(k) + B*u(k) + L*(y(k) - C*xhat(k) - D*u(k))
%           = (A - L*C)*xhat(k) + [ (B - L*D) , L ] * [u(k); y(k)]
% -------------------------------------------------------------------

A_obs = A - L*Cc;
B_obs = [B - L*Dd, L];
C_obs = eye(n);
D_obs = zeros(n, size(B_obs,2));

assert(all(isfinite(A_obs(:))) && all(isfinite(B_obs(:))), 'Matrizes do observador invalidas.');
assert(all(abs(eig(A_obs)) < 1), 'A_obs instavel - nao avances para o tempo real.');

assignin('base', 'A_obs', A_obs);
assignin('base', 'B_obs', B_obs);
assignin('base', 'C_obs', C_obs);
assignin('base', 'D_obs', D_obs);
assignin('base', 'K', K);
assignin('base', 'Nbar', Nbar);
assignin('base', 'Kp', Kp);
assignin('base', 'Ke', Ke);
assignin('base', 'offset', offset);
assignin('base', 'Ts', Ts);

fprintf('Variaveis do observador colocadas no workspace base.\n');

%% Seccao 2 - Gerar (ou reutilizar) o diagrama Simulink de tempo real
nome_modelo = 'lqg_tempo_real';
if ~(exist([nome_modelo '.mdl'], 'file') || exist([nome_modelo '.slx'], 'file'))
    fprintf('Modelo "%s" nao encontrado - a gerar automaticamente...\n', nome_modelo);
    criar_modelo_lqg_tempo_real();
else
    fprintf('Modelo "%s" ja existe - a reutilizar.\n', nome_modelo);
end

%% Seccao 3 - Confirmacao de seguranca antes de abrir/correr
% -------------------------------------------------------------------
% NAO remover estas confirmacoes. O guiao exige: (1) distancia de
% seguranca da barra, (2) um colega com o dedo perto do interruptor do
% amplificador de potencia, (3) o valor final da saida analogica a 0.
% -------------------------------------------------------------------

fprintf(['\n=== VERIFICACOES DE SEGURANCA (guiao, pag. 2) ===\n' ...
         '  [ ] Todos a distancia de seguranca da barra flexivel?\n' ...
         '  [ ] Um colega com o dedo perto do interruptor do amplificador?\n' ...
         '  [ ] Confirmaste no bloco "Saida Analogica" que o valor final = 0?\n' ...
         '  [ ] O docente/monitor deu autorizacao para o ensaio?\n\n']);

resposta = input('Confirmas TODOS os pontos acima? Escreve "sim" para continuar: ', 's');
assert(strcmpi(resposta, 'sim'), 'Ensaio cancelado - confirma as condicoes de seguranca antes de repetir.');

open_system(nome_modelo);
fprintf(['\nO modelo esta aberto. Corre a simulacao manualmente a partir do Simulink\n' ...
         '(modo "External"), com o dedo pronto para parar. Este script nao carrega\n' ...
         'automaticamente em "play" - essa decisao e sempre manual, por seguranca.\n']);

%% Seccao 4 - Depois do ensaio: gravar e validar os resultados
% -------------------------------------------------------------------
% Corre esta seccao DEPOIS de teres corrido o ensaio no Simulink e de
% a variavel "resultado_malha_fechada" existir no workspace base.
% -------------------------------------------------------------------

if evalin('base', 'exist(''resultado_malha_fechada'', ''var'')')
    resultado_malha_fechada = evalin('base', 'resultado_malha_fechada'); %#ok<NASGU>

    t_res = resultado_malha_fechada.time;
    u_res = resultado_malha_fechada.signals.values;

    assert(all(isfinite(u_res(:))), 'Resultados do ensaio contem NaN/Inf - repete o ensaio.');

    figure('Name', 'Resultado do ensaio em tempo real');
    plot(t_res, u_res(:,1)); grid on;
    xlabel('Tempo [s]'); ylabel('u [V]'); title('Comando aplicado ao motor (ensaio real)');

    ficheiro_resultado = fullfile(pwd, 'resultado_malha_fechada.mat');
    save(ficheiro_resultado, 'resultado_malha_fechada', 't_res', 'u_res');
    fprintf('Resultados do ensaio real gravados em "%s".\n', ficheiro_resultado);
else
    fprintf(['\nAinda nao ha "resultado_malha_fechada" no workspace - corre o ensaio no\n' ...
             'Simulink e depois volta a correr esta seccao.\n']);
end
