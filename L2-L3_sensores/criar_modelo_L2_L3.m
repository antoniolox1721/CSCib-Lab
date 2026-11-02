function criar_modelo_L2_L3()
%CRIAR_MODELO_L2_L3  Gera automaticamente o diagrama Simulink das sessoes L2-L3.
%
% -------------------------------------------------------------------
% Constroi, por comandos (API do Simulink), o diagrama da Figura 10 do
% guiao: gerador de sinal -> Saida Analogica (motor) e Entrada Analogica
% x2 (potenciometro + extensometro) -> Mux -> Scope, gravando para o
% workspace como "input".
%
% AVISO IMPORTANTE (le antes de correr):
%   - So funciona dentro do MATLAB/Simulink do posto de laboratorio,
%     com a toolbox "Simulink Desktop Real-Time" instalada e a placa
%     NI ligada. Nao vai funcionar num portatil sem essa toolbox.
%   - Este script cria o ESQUELETO do diagrama. Depois de o correr,
%     ABRE o modelo gerado e confirma visualmente:
%       * qual a placa NI selecionada no bloco "Saida Analogica" e nos
%         dois blocos "Entrada Analogica" (usa "Measurement & Automation"
%         para confirmar o nome da placa, Seccao 3.3 passo 9 do guiao);
%       * que o valor final ("OutputFinalValue") do bloco de saida
%         analogica esta a 0 - isto e critico por seguranca (se nao
%         estiver a 0, o motor pode continuar a rodar sem parar no fim
%         do ensaio).
%   - Nunca ligues a placa/motor sem um colega com o dedo perto do
%     interruptor do amplificador de potencia, como indicado no guiao.
% -------------------------------------------------------------------

    nome_modelo = 'io_sinais_L2_L3';
    Ts = 0.001;   % periodo de amostragem para o diagrama de teste (1 ms, guiao Seccao 3.2)

    if bdIsLoaded(nome_modelo)
        close_system(nome_modelo, 0);
    end
    if exist([nome_modelo '.mdl'], 'file') || exist([nome_modelo '.slx'], 'file')
        resposta = input(sprintf(['Ja existe um modelo "%s". Substituir? (s/n): '], nome_modelo), 's');
        if ~strcmpi(resposta, 's')
            fprintf('Cancelado pelo utilizador.\n');
            return;
        end
    end

    new_system(nome_modelo);
    open_system(nome_modelo);

    %% Blocos
    add_block('simulink/Sources/Signal Generator', [nome_modelo '/Gerador de Sinal'], ...
        'Position', [30 100 90 130]);
    set_param([nome_modelo '/Gerador de Sinal'], 'Amplitude', '2', 'Frequency', '2', 'Units', 'Hertz');

    add_block('sldrtlib/Analog Output', [nome_modelo '/Saida Analogica (motor)'], ...
        'Position', [180 40 280 80]);
    % Valores iniciais e finais a 0 por seguranca (ver aviso acima).
    try
        set_param([nome_modelo '/Saida Analogica (motor)'], ...
            'OutputInitialValue', '0', 'OutputFinalValue', '0', 'SampleTime', num2str(Ts));
    catch ME
        warning(['Nao consegui configurar todos os parametros do bloco de saida analogica ' ...
                 'automaticamente (%s). Confirma manualmente no bloco, sobretudo o valor final = 0.'], ME.message);
    end

    add_block('sldrtlib/Analog Input', [nome_modelo '/Entrada Analogica (potenciometro)'], ...
        'Position', [180 150 280 190]);
    add_block('sldrtlib/Analog Input', [nome_modelo '/Entrada Analogica (extensometro)'], ...
        'Position', [180 220 280 260]);
    try
        set_param([nome_modelo '/Entrada Analogica (potenciometro)'], 'SampleTime', num2str(Ts));
        set_param([nome_modelo '/Entrada Analogica (extensometro)'], 'SampleTime', num2str(Ts));
    catch ME
        warning('Confirma manualmente o "sample time" dos blocos de entrada analogica (%s).', ME.message);
    end

    add_block('simulink/Signal Routing/Mux', [nome_modelo '/Mux'], ...
        'Position', [340 90 360 220], 'Inputs', '3');

    add_block('simulink/Sinks/Scope', [nome_modelo '/Scope'], ...
        'Position', [420 130 460 180]);
    set_param([nome_modelo '/Scope'], 'NumInputPorts', '1');
    scope_obj = get_param([nome_modelo '/Scope'], 'ScopeConfiguration');
    try
        scope_obj.DataLogging = true;
        scope_obj.DataLoggingVariableName = 'input';
        scope_obj.DataLoggingSaveFormat = 'StructureWithTime';
        scope_obj.DataLoggingDecimateData = false;
    catch ME
        warning(['Nao consegui configurar o logging do Scope automaticamente (%s). ' ...
                 'Abre o Scope, separador "History", e escolhe "Save data to workspace", ' ...
                 'nome da variavel "input", formato "Structure with time".'], ME.message);
    end

    %% Ligacoes
    add_line(nome_modelo, 'Gerador de Sinal/1', 'Saida Analogica (motor)/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Gerador de Sinal/1', 'Mux/1', 'autorouting', 'on');
    add_line(nome_modelo, 'Entrada Analogica (potenciometro)/1', 'Mux/2', 'autorouting', 'on');
    add_line(nome_modelo, 'Entrada Analogica (extensometro)/1', 'Mux/3', 'autorouting', 'on');
    add_line(nome_modelo, 'Mux/1', 'Scope/1', 'autorouting', 'on');

    %% Configuracao para tempo real (guiao, Seccao 3.3, passo 10)
    set_param(nome_modelo, 'SolverType', 'Fixed-step');
    set_param(nome_modelo, 'FixedStep', num2str(Ts));
    try
        set_param(nome_modelo, 'SystemTargetFile', 'rtwin.tlc');
        set_param(nome_modelo, 'ProdHWDeviceType', 'Intel->x86-compatible');
    catch ME
        warning(['Nao consegui definir o "System Target File" / hardware automaticamente (%s). ' ...
                 'Configura manualmente em Simulation > Configuration Parameters, como no ' ...
                 'guiao (Seccao 3.3, passo 10).'], ME.message);
    end

    save_system(nome_modelo, fullfile(pwd, [nome_modelo '.mdl']));
    fprintf(['\nModelo base gravado em "%s.mdl".\n' ...
             'ABRE-O AGORA e confirma manualmente: placa NI correta nos 3 blocos de I/O,\n' ...
             'canais de entrada/saida, e o valor final da saida analogica a 0.\n'], nome_modelo);
end
