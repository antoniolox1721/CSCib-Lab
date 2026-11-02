%% L7_AUDITORIA_DADOS.m - verificacao independente dos dados reais (so leitura; nada e alterado).
% Para cada ficheiro: Ts, duracao, NaN, ganhos de calibracao aplicados, voltas do pot, saturacao, frequencia/amplitude de u.
% Corre com a pasta atual = L7_revisao:  matlab -batch l7_auditoria_dados
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
nm = {'dados_ID_quadrada_1V','dados_ID_prbs_1Hz_0.5','dados_ID_prbs_2_5Hz_0.5','dados_validacao','dados_ID_validacao_0_5','dados_ID_grande','dados_ID_pequeno'};
T = table();
for k = 1:numel(nm)
    S = load(fullfile(pasta, [nm{k} '.mat']), 'ScopeData').ScopeData; t = S(:,1); u = S(:,2); th = S(:,3); al = S(:,4);
    dt = diff(t); i8 = round(8/0.02)+1:size(S,1);
    y = th*C.Kp + (al-C.offset)*C.Ke;
    cruz = sum(diff(sign(u(u~=0))) ~= 0);                    % comutacoes de u
    T = [T; table(string(nm{k}), size(S,1), size(S,2), median(dt), max(abs(dt-0.02)), t(end)-t(1), any(~isfinite(S(:))), ...
        max(abs(u)), cruz/(t(end)-t(1))/2, min(th), max(th), sum(abs(diff(th))>5), min(al), max(al), ...
        mean(abs(th)>5.1)*100, mean(abs(al)>9.9)*100, min(y(i8)), max(y(i8)), std(y(i8)), ...
        'VariableNames', {'ficheiro','N','colunas','Ts','max_desvio_Ts','dur_s','NaN','max_u','freq_Hz','pot_min','pot_max','voltas_pot','ext_min','ext_max','pct_pot_sat','pct_ext_sat','y_min','y_max','y_std'})]; %#ok<AGROW>
end
disp(T(:, {'ficheiro','N','Ts','max_desvio_Ts','dur_s','NaN','max_u','freq_Hz','voltas_pot','pct_pot_sat'}));
disp(T(:, {'ficheiro','pot_min','pot_max','ext_min','ext_max','y_min','y_max','y_std'}));
writetable(T, 'l7_auditoria_dados.csv');
% Regras de aceitacao para ficheiros de treino/validacao (grande/pequeno sao so relatorio)
uso = nm(1:5);
for k = 1:5
    r = T(k,:); assert(abs(r.Ts-0.02)<1e-6 && r.max_desvio_Ts<1e-3, '%s: Ts irregular', nm{k});
    assert(~r.NaN, '%s: NaN', nm{k}); assert(r.voltas_pot==0, '%s: pot deu a volta', nm{k}); assert(r.pct_pot_sat==0, '%s: pot saturado', nm{k});
    fprintf('OK  %s\n', nm{k});
end
