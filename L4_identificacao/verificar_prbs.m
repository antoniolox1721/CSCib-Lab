% Verifica que um ficheiro de ID nao tem voltas do potenciometro. Corre na pasta L4_identificacao.
ficheiros = {'dados_ID_prbs_1Hz_0.5.mat','dados_ID_prbs_2_5Hz_0.5.mat', ...
             'dados_ID_prbs_1Hz.mat','dados_ID_prbs_2_5Hz.mat'};   % ultimos 2 = antigos (maus)
Kp = 34.83516379; Ke = -5.775168632; off = -0.03729982383;
for i = 1:numel(ficheiros)
    D = load(ficheiros{i}, 'ScopeData'); S = D.ScopeData;   % [t u pot extensometro ...]
    t = S(:,1); pot = S(:,3); y = pot*Kp + (S(:,4)-off)*Ke;
    saltos = sum(abs(diff(pot)) > 5);        % salto > 5 V numa amostra (20 ms) = volta do pot (+-5,18 V -> -+5,18 V)
    fprintf('%-28s Ts=%.3f dur=%.2f pot=[%.2f %.2f] max|dpot|=%.2f V saltos=%d |pot|>=5.1V: %.1f%% y=[%.1f %.1f]\n', ...
        ficheiros{i}, mean(diff(t)), t(end), min(pot), max(pot), max(abs(diff(pot))), saltos, 100*mean(abs(pot)>=5.1), min(y), max(y));
    subplot(numel(ficheiros),1,i); plot(t,pot); ylim([-6 6]); grid on; title(ficheiros{i}, 'Interpreter','none'); ylabel('pot [V]');
end
