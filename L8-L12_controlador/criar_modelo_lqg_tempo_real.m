function criar_modelo_lqg_tempo_real()
%CRIAR_MODELO_LQG_TEMPO_REAL  Gera o diagrama Simulink de malha fechada (L10-L12).
%
% -------------------------------------------------------------------
% Constroi, por comandos (API do Simulink), um diagrama LQG de tempo
% real: referencia -> pre-filtro Nbar -> soma com -K*xhat -> Saida
% Analogica (motor); sensores -> Entradas Analogicas -> combinacao em y
% -> observador (bloco "Discrete State-Space") -> xhat -> realimentacao.
%
% Os blocos referenciam VARIAVEIS DO WORKSPACE (A_obs, B_obs, C_obs,
% D_obs, K, Nbar, Kp, Ke, offset) em vez de valores fixos, exatamente
% como o guiao pede na Seccao 4 ("terceiro script parameteriza um
% diagrama Simulink"). Usa "teste_tempo_real.m" para definir essas
% variaveis e abrir/correr este modelo - NAO abras este ficheiro
% diretamente sem correres primeiro esse script.
%
% AVISO IMPORTANTE (le antes de correr):
%   - So funciona no MATLAB/Simulink do laboratorio, com a toolbox
%     "Simulink Desktop Real-Time" e a placa NI ligada.
%   - Este script cria o ESQUELETO do diagrama. ABRE-O e confirma
%     manualmente a placa NI nos blocos de I/O, os canais, e sobretudo
%     que o valor final da saida analogica esta a 0 (seguranca).
%   - Confirma com um colega de dedo no interruptor do amplificador
%     antes de carregar em "play", como pede o guiao.
%   - Nunca comeces com R pequeno/ganhos altos sem teres validado a
%     simulacao em "projeto_controlador.m" primeiro.
% -------------------------------------------------------------------

    nome_modelo = 'lqg_tempo_real';
    Ts = evalin('base', 'Ts');

    if bdIsLoaded(nome_modelo)
        close_system(nome_modelo, 0);
    end
    if exist([nome_modelo '.mdl'], 'file') || exist([nome_modelo '.slx'], 'file')
        resposta = input(sprintf('Ja existe um modelo "%s". Substituir? (s/n): ', nome_modelo), 's');
        if ~strcmpi(resposta, 's')
            fprintf('Cancelado pelo utilizador.\n');
            return;
        end
    end

    new_system(nome_modelo);
    open_system(nome_modelo);

    %% Referencia e pre-filtro
    add_block('simulink/Sources/Step', [nome_modelo '/Referencia'], ...
        'Position', [30 40 60 70], 'Time', '1', 'After', '10', 'Before', '0');

    add_block('simulink/Math Operations/Gain', [nome_modelo '/Nbar'], ...
        'Position', [110 40 150 70], 'Gain', 'Nbar');

    add_block('simulink/Math Operations/Sum', [nome_modelo '/Soma_u'], ...
        'Position', [280 60 300 90], 'Inputs', '+-');

    %% Saida para o motor (com valores iniciais/finais a 0 - seguranca)
    add_block('sldrtlib/Analog Output', [nome_modelo '/Saida Analogica (motor)'], ...
        'Position', [360 60 460 90]);
    try
        set_param([nome_modelo '/Saida Analogica (motor)'], ...
            'OutputInitialValue', '0', 'OutputFinalValue', '0', 'SampleTime', num2str(Ts));
    catch ME
        warning(['Confirma manualmente o valor final da saida analogica = 0 (%s). ' ...
                 'Isto e critico por seguranca.'], ME.message);
    end

    %% Sensores -> y = Kp*thetae + Ke*(alphae - offset)
    add_block('sldrtlib/Analog Input', [nome_modelo '/Entrada Analogica (potenciometro)'], ...
        'Position', [30 160 130 190]);
    add_block('sldrtlib/Analog Input', [nome_modelo '/Entrada Analogica (extensometro)'], ...
        'Position', [30 220 130 250]);
    try
        set_param([nome_modelo '/Entrada Analogica (potenciometro)'], 'SampleTime', num2str(Ts));
        set_param([nome_modelo '/Entrada Analogica (extensometro)'], 'SampleTime', num2str(Ts));
    catch
    end

    add_block('simulink/Math Operations/Gain', [nome_modelo '/Ganho Kp'], ...
        'Position', [170 160 210 190], 'Gain', 'Kp');
    add_block('simulink/Math Operations/Sum', [nome_modelo '/Subtrai offset'], ...
        'Position', [170 220 210 250], 'Inputs', '+-');
    add_block('simulink/Sources/Constant', [nome_modelo '/offset'], ...
        'Position', [110 250 150 270], 'Value', 'offset');
    add_block('simulink/Math Operations/Gain', [nome_modelo '/Ganho Ke'], ...
        'Position', [250 220 290 250], 'Gain', 'Ke');
    add_block('simulink/Math Operations/Sum', [nome_modelo '/Soma_y'], ...
        'Position', [330 190 360 220], 'Inputs', '++');

    %% Observador (Kalman) - forma padrao: xhat(k+1) = Aobs*xhat + Bobs*[u;y]
    add_block('simulink/Signal Routing/Mux', [nome_modelo '/Mux_obs'], ...
        'Position', [420 130 440 240], 'Inputs', '2');
    add_block('simulink/Discrete/Discrete State-Space', [nome_modelo '/Observador'], ...
        'Position', [480 150 560 220]);
    set_param([nome_modelo '/Observador'], ...
        'A', 'A_obs', 'B', 'B_obs', 'C', 'C_obs', 'D', 'D_obs', 'SampleTime', num2str(Ts));

    add_block('simulink/Math Operations/Gain', [nome_modelo '/Ganho -K'], ...
        'Position', [610 150 650 180], 'Gain', '-K', 'Multiplication', 'Matrix(K*u)');

    %% Scope para registo dos resultados (guarda como "resultado_malha_fechada")
    add_block('simulink/Signal Routing/Mux', [nome_modelo '/Mux_registo'], ...
        'Position', [700 60 720 200], 'Inputs', '3');
    add_block('simulink/Sinks/Scope', [nome_modelo '/Scope'], ...
        'Position', [760 100 800 150]);
    scope_obj = get_param([nome_modelo '/Scope'], 'ScopeConfiguration');
    try
        scope_obj.DataLogging = true;
        scope_obj.DataLoggingVariableName = 'resultado_malha_fechada';
        scope_obj.DataLoggingSaveFormat = 'StructureWithTime';
    catch
        warning('Configura manualmente o logging do Scope: variavel "resultado_malha_fechada".');
    end

    %% Ligacoes
    add_line(nome_modelo, 'Referencia/1', 'Nbar/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Nbar/1', 'Soma_u/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Ganho -K/1', 'Soma_u/2', 'autorouting', 'on');
    add_line(nome_modelo, 'Soma_u/1', 'Saida Analogica (motor)/1', 'autorouting', 'on');

    add_line(nome_modelo, 'Entrada Analogica (potenciometro)/1', 'Ganho Kp/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Entrada Analogica (extensometro)/1', 'Subtrai offset/1', 'autorouting', 'on');
    add_line(nome_modelo, 'offset/1', 'Subtrai offset/2', 'autorouting', 'on');
    add_line(nome_modelo, 'Subtrai offset/1', 'Ganho Ke/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Ganho Kp/1', 'Soma_y/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Ganho Ke/1', 'Soma_y/2', 'autorouting', 'on');

    add_line(nome_modelo, 'Soma_u/1', 'Mux_obs/1', 'autorouting', 'on');   % u
    add_line(nome_modelo, 'Soma_y/1', 'Mux_obs/2', 'autorouting', 'on');  % y
    add_line(nome_modelo, 'Mux_obs/1', 'Observador/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Observador/1', 'Ganho -K/1', 'autorouting', 'on');

    add_line(nome_modelo, 'Soma_u/1', 'Mux_registo/1', 'autorouting', 'on');   % u aplicado
    add_line(nome_modelo, 'Soma_y/1', 'Mux_registo/2', 'autorouting', 'on');   % y medido
    add_line(nome_modelo, 'Referencia/1', 'Mux_registo/3', 'autorouting', 'on'); % referencia
    add_line(nome_modelo, 'Mux_registo/1', 'Scope/1', 'autorouting', 'on');

    %% Configuracao de tempo real
    set_param(nome_modelo, 'SolverType', 'Fixed-step');
    set_param(nome_modelo, 'FixedStep', num2str(Ts));
    try
        set_param(nome_modelo, 'SystemTargetFile', 'rtwin.tlc');
        set_param(nome_modelo, 'ProdHWDeviceType', 'Intel->x86-compatible');
    catch
        warning('Configura manualmente "Configuration Parameters" (Solver/Code Generation/Hardware).');
    end

    save_system(nome_modelo, fullfile(pwd, [nome_modelo '.mdl']));
    fprintf(['\nModelo base gravado em "%s.mdl".\n' ...
             'ABRE-O AGORA: confirma placas/canais de I/O e o valor final da saida a 0\n' ...
             'antes de sequer pensar em ligar o motor.\n'], nome_modelo);
end
