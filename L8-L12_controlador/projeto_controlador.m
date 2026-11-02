%% PROJETO_CONTROLADOR.m
% -------------------------------------------------------------------
% Projeto do controlador LQG (Parte II, sessoes L8-L10, parte offline
% que corre so em MATLAB, sem tocar na planta real).
%
% Pressuposto: "L7_revisao/l7_revisao.m" (modelo final; antes "identificacao_modelo.m") ja foi corrido e
% "../L4_identificacao/modelo_identificado.mat" existe, com A, B, Cc, Dd, Ts validos e
% o sistema confirmado como controlavel.
%
% Dividido em seccoes (%%); cada seccao verifica as condicoes da
% anterior e PARA imediatamente (assert/error) se algo for invalido -
% nunca continua a trabalhar com um resultado que falhou uma verificacao.
% -------------------------------------------------------------------

%% Seccao 0 - Configuracao inicial e carregamento do modelo identificado
clear; clc; close all;

ficheiro_modelo = fullfile(fileparts(pwd), 'L4_identificacao', 'modelo_identificado.mat');
assert(exist(ficheiro_modelo, 'file') == 2, ...
    ['Nao encontrei "%s". Corre primeiro "l7_revisao.m" ' ...
     'na pasta L7_revisao ate ao fim.'], ficheiro_modelo);

M = load(ficheiro_modelo, 'A', 'B', 'Cc', 'Dd', 'Ts', 'controlavel');
assert(all(isfield(M, {'A','B','Cc','Dd','Ts','controlavel'})), ...
    'O ficheiro de modelo nao tem todas as variaveis necessarias (A,B,Cc,Dd,Ts,controlavel).');
assert(logical(M.controlavel), ...
    'O modelo identificado nao e controlavel - nao e possivel projetar um controlador LQ.');

A = M.A; B = M.B; Cc = M.Cc; Dd = M.Dd; Ts = M.Ts;
Z = load(ficheiro_modelo); deadzone_V = 0; if isfield(Z, 'deadzone_V'), deadzone_V = Z.deadzone_V; end
if deadzone_V > 0
    fprintf(['\n>>> ATENCAO: o modelo foi identificado com uma zona morta de %.2f V na entrada (u_eff = sign(u)*max(|u|-%.2f,0)).\n' ...
             '    O ganho de B e o de u_eff. No tempo real o comando ao motor deve compensar: u_motor = u + %.2f*sign(u),\n' ...
             '    senao a planta ignora comandos |u| < %.2f V. Esta compensacao NAO esta no modelo Simulink gerado por\n' ...
             '    criar_modelo_lqg_tempo_real.m (nao testado na planta) - acrescenta-a antes de correr o tempo real.\n\n'], deadzone_V, deadzone_V, deadzone_V, deadzone_V);
end
n = size(A,1);
fprintf('Modelo carregado: %d estados, Ts = %.3f s.\n', n, Ts);

ficheiro_controlador = fullfile(pwd, 'controlador_lqg.mat');

%% Seccao 1 - Projeto LQ (dlqr) e "root-square locus" em R
% -------------------------------------------------------------------
% Q pondera o erro de estado; R pondera o esforco de controlo. Aqui
% variamos R (escalar, ja que ha uma entrada) e observamos o lugar
% geometrico das raizes em malha fechada (guiao, Seccao 5.1 / L8).
% -------------------------------------------------------------------

Q = Cc' * Cc;                 % pondera diretamente a saida (angulo da ponta)
R_valores = logspace(-4, 2, 60);

polos_malha_fechada = zeros(numel(R_valores), n);
for i = 1:numel(R_valores)
    Ki = dlqr(A, B, Q, R_valores(i));
    polos_malha_fechada(i,:) = eig(A - B*Ki).';
end

figure('Name', 'Lugar geometrico das raizes em R (LQ)');
plot(real(polos_malha_fechada), imag(polos_malha_fechada), '.'); hold on;
theta_circ = linspace(0, 2*pi, 200);
plot(cos(theta_circ), sin(theta_circ), 'k--');
axis equal; grid on;
xlabel('Parte real'); ylabel('Parte imaginaria');
title('Polos em malha fechada (LQ) ao variar R - circulo unitario a tracejado');

% --- Escolhe aqui o valor de R (ajusta apos observares o grafico) ---
R = 1;   % <-- muda conforme a analise do "root-square locus"
assert(isscalar(R) && R > 0, 'R tem de ser um escalar positivo.');

K = dlqr(A, B, Q, R);
polos_K = eig(A - B*K);
fprintf('K = '); disp(K);
fprintf('Polos em malha fechada com este R:\n'); disp(polos_K);

assert(all(abs(polos_K) < 1), ...
    'Os polos em malha fechada com este R nao estao todos dentro do circulo unitario - escolhe outro R.');

save(ficheiro_controlador, 'Q', 'R', 'K', 'polos_K', 'R_valores', 'polos_malha_fechada');
fprintf('Ganho K gravado em "%s".\n', ficheiro_controlador);

%% Seccao 2 - Filtro de Kalman (dlqe)
% -------------------------------------------------------------------
% Rw: covariancia do ruido de processo (entra por B); Rv: covariancia
% do ruido de medida. Ajusta conforme o ruido observado nos teus dados
% (guiao, Seccao 5.2 / L9).
% -------------------------------------------------------------------

G = B;                 % o ruido de processo entra pelo mesmo canal que o comando
Rw = 1;                % <-- ajusta: intensidade do ruido de processo
Rv = 1e-2;             % <-- ajusta: variancia do ruido de medida (sensor)

assert(Rw > 0 && Rv > 0, 'Rw e Rv tem de ser positivos.');

[Mk, ~, ~] = dlqe(A, G, Cc, Rw, Rv);
L = A*Mk;              % dlqe devolve o ganho do estimador "corrente" (Mk); o observador usado aqui e no tempo real e de PREDICAO (xhat+ = A*xhat + B*u + L*(y - C*xhat)), logo L = A*Mk
polos_L = eig(A - L*Cc);
fprintf('L = '); disp(L);
fprintf('Polos do observador (A - L*C):\n'); disp(polos_L);

assert(all(abs(polos_L) < 1), ...
    'Os polos do observador nao estao todos dentro do circulo unitario - ajusta Rw/Rv.');

save(ficheiro_controlador, 'G', 'Rw', 'Rv', 'L', 'polos_L', '-append');
fprintf('Ganho do observador L gravado em "%s".\n', ficheiro_controlador);

%% Seccao 3 - Recuperacao da malha (LTR)
% -------------------------------------------------------------------
% Aumenta a intensidade do ruido de processo na direcao de B (Rw = q*B*B')
% para que o filtro de Kalman "recupere" o ganho de malha do LQ de
% estado completo, quando q -> Infinito (guiao, Seccao 5.3 / L9).
% -------------------------------------------------------------------

valores_q = logspace(0, 6, 25);
L_por_q = cell(numel(valores_q), 1);
for i = 1:numel(valores_q)
    Rw_q = valores_q(i) * (B*B') + 1e-8*eye(n);   % termo pequeno para evitar singularidade
    [Mq, ~, ~] = dlqe(A, eye(n), Cc, Rw_q, Rv); L_por_q{i} = A*Mq;   % predicao: L = A*M
end

% --- Escolhe aqui o valor de q (compromisso entre recuperacao e ruido) ---
q_escolhido = valores_q(end-5);   % <-- ajusta apos observares o compromisso
idx_q = find(valores_q == q_escolhido, 1);
assert(~isempty(idx_q), 'q_escolhido tem de ser um dos valores em valores_q.');

Rw_ltr = q_escolhido * (B*B') + 1e-8*eye(n);
[Mltr, ~, ~] = dlqe(A, eye(n), Cc, Rw_ltr, Rv); L_ltr = A*Mltr;   % predicao: L = A*M
polos_L_ltr = eig(A - L_ltr*Cc);

assert(all(abs(polos_L_ltr) < 1), ...
    'Os polos do observador (LTR) nao estao todos dentro do circulo unitario - reduz q_escolhido.');

fprintf('LTR: q = %.3g, L = '); disp(L_ltr);

save(ficheiro_controlador, 'valores_q', 'q_escolhido', 'Rw_ltr', 'L_ltr', 'polos_L_ltr', '-append');
fprintf('Resultado da LTR gravado em "%s".\n', ficheiro_controlador);

% Usa L_ltr como observador final (comenta esta linha se preferires o L da Seccao 2)
L = L_ltr; %#ok<NASGU>
save(ficheiro_controlador, 'L', '-append');

%% Seccao 4 - Estrutura LQG + pre-filtro para seguimento de referencia
% -------------------------------------------------------------------
% Calcula o ganho estatico Nbar tal que, em regime estacionario, a
% saida siga a referencia sem erro (guiao, Seccao 5.4).
% -------------------------------------------------------------------

ganho_dc = Cc * ((eye(n) - (A - B*K)) \ B);
assert(abs(ganho_dc) > 1e-9, 'Ganho DC do sistema em malha fechada e quase nulo - Nbar indefinido.');
Nbar = 1/ganho_dc;

assert(isfinite(Nbar), 'Nbar nao e finito.');
fprintf('Nbar = %.4f\n', Nbar);

save(ficheiro_controlador, 'Nbar', '-append');
fprintf('Nbar gravado em "%s".\n', ficheiro_controlador);

%% Seccao 5 - Simulacao em malha fechada (validacao antes do tempo real)
% -------------------------------------------------------------------
% Simula a resposta a um degrau de referencia usando o modelo
% identificado e o controlador LQG completo (K, L, Nbar), em MATLAB,
% antes de arriscar a planta real.
% -------------------------------------------------------------------

Tsim = 5;                       % segundos
t_sim = (0:Ts:Tsim)';
r = 10 * ones(size(t_sim));     % referencia: degrau de 10 graus

x  = zeros(n,1);
xhat = zeros(n,1);
y_sim = zeros(size(t_sim));
u_sim = zeros(size(t_sim));

for k = 1:numel(t_sim)
    y_k = Cc*x + Dd*0;
    y_sim(k) = y_k;

    u_k = -K*xhat + Nbar*r(k);
    u_sim(k) = u_k;

    xhat = A*xhat + B*u_k + L*(y_k - Cc*xhat);
    x    = A*x + B*u_k;
end

figure('Name', 'Simulacao em malha fechada (LQG)');
subplot(2,1,1);
plot(t_sim, r, '--', t_sim, y_sim); grid on;
xlabel('Tempo [s]'); ylabel('y [graus]');
legend('Referencia', 'Saida simulada'); title('Resposta ao degrau (simulada)');
subplot(2,1,2);
plot(t_sim, u_sim); grid on;
xlabel('Tempo [s]'); ylabel('u [V]'); title('Comando aplicado (simulado)');

assert(all(isfinite(y_sim)) && all(isfinite(u_sim)), ...
    'A simulacao em malha fechada divergiu (NaN/Inf). Revê K, L, Nbar antes de ir para o tempo real.');
assert(max(abs(u_sim)) < 10, ...
    'O comando simulado excede 10 V - fora da gama do D/A. Revê Q/R antes do tempo real.');

erro_regime = abs(y_sim(end) - r(end));
fprintf('Erro em regime estacionario (simulado): %.4f graus\n', erro_regime);

save(ficheiro_controlador, 't_sim', 'r', 'y_sim', 'u_sim', 'erro_regime', '-append');
fprintf('Resultados da simulacao gravados em "%s".\n', ficheiro_controlador);

%% Seccao 6 - Resumo final e verificacao de integridade
% -------------------------------------------------------------------
necessario = {'A','B','Cc','Dd','Ts','K','L','Nbar'};
tudo_ok = true;
for i = 1:numel(necessario)
    nome = necessario{i};
    if ~exist(nome, 'var')
        fprintf('[EM FALTA] %s\n', nome); tudo_ok = false;
    else
        fprintf('[OK] %s presente\n', nome);
    end
end

assert(tudo_ok, 'Faltam variaveis essenciais do controlador - corre as seccoes em falta.');
assert(all(abs(eig(A-B*K)) < 1), 'Malha fechada de estado (A-BK) instavel.');
assert(all(abs(eig(A-L*Cc)) < 1), 'Observador (A-LC) instavel.');
assert(max(abs(u_sim)) < 10, 'Comando simulado fora da gama do D/A.');

fprintf(['\nProjeto do controlador completo e validado em simulacao. Gravado em "%s".\n' ...
         'Podes avancar para "teste_tempo_real.m" (so depois de reveres os avisos de seguranca do guiao).\n'], ...
         ficheiro_controlador);
