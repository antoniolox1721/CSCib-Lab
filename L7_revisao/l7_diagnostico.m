%% L7_DIAGNOSTICO.m - (1) fit em posicao (nao no sinal derivado+filtrado); (2) residuos vs sinal de u (zona morta/folga).
% Usa o modelo de l7_modelo_final.mat. Corre com a pasta atual = L7_revisao:  matlab -batch l7_diagnostico
clear; clc;
pasta = fullfile(fileparts(pwd), 'L4_identificacao');
C = load(fullfile(fileparts(pwd), 'L2-L3_sensores', 'calibracao_sensores.mat'), 'Kp', 'Ke', 'offset');
M = load('l7_modelo_final.mat', 'th', 'af_f', 'd_zm');
Ts = 0.02; af = M.af_f; nd = round(8/Ts); Af = [1 -af]; Bf = (1-af)*[1 -1];
vals = {'dados_validacao', 'dados_ID_validacao_0_5'};
fitf = @(y, yp) 100*(1 - norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end))));
f = figure('Visible','off','Position',[100 100 1100 800]);
for k = 1:2
    S = load(fullfile(pasta, [vals{k} '.mat']), 'ScopeData').ScopeData; i = (nd+1):size(S,1);
    yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke; u = detrend(sign(S(i,2)).*max(abs(S(i,2))-M.d_zm, 0), 'constant');
    yf = detrend(filter(Bf, Af, yt - yt(1)), 'constant'); yp = sim(M.th, u);
    % 1) posicao: yf = (1-q^-1) * posicao filtrada  =>  posicao filtrada = soma acumulada de yf (integrador reposto)
    pm = filter((1-af), Af, yt - yt(1));            % posicao medida, so passa-baixo (sem derivar)
    pp = cumsum(yp);                                % posicao do modelo
    pm0 = pm - mean(pm); pp0 = pp - mean(pp);       % so a media e removida (constante de integracao desconhecida)
    fprintf('\n== %s\n', vals{k});
    fprintf('fit sinal derivado+filtrado (o das tabelas): %6.1f %%\n', fitf(yf, yp));
    fprintf('fit posicao (cumsum, so media removida)    : %6.1f %%\n', fitf(pm0, pp0));
    fprintf('deriva da posicao do modelo vs medida (graus no fim): %.1f vs %.1f\n', pp(end)-pp(1), pm(end)-pm(1));
    % 2) zona morta / folga: ganho planta/modelo por sinal de u, e erro logo apos cada comutacao
    res = yf - yp; pos = u > 0; neg = u < 0;
    g = @(m) (yp(m)'*yf(m)) / (yp(m)'*yp(m));       % declive LS de medido sobre modelo
    fprintf('ganho medido/modelo: u>0 %.2f | u<0 %.2f | global %.2f\n', g(pos), g(neg), g(pos|neg));
    fprintf('residuo medio: u>0 %+.3f | u<0 %+.3f   (rms %.3f)\n', mean(res(pos)), mean(res(neg)), rms(res));
    sw = find(diff(sign(u)) ~= 0) + 1; near = false(size(u));
    for s = sw', near(s:min(s+15, end)) = true; end % 0.3 s apos cada comutacao
    fprintf('rms residuo: logo apos comutacao %.3f | resto %.3f | rms do sinal medido %.3f\n', rms(res(near)), rms(res(~near)), rms(yf));
    subplot(2,2,2*k-1); plot(pm0); hold on; plot(pp0); grid on; legend('medido','modelo'); title([vals{k} ' - posicao'], 'Interpreter','none');
    subplot(2,2,2*k); plot(res); hold on; plot(u*std(res), 'k:'); grid on; title('residuo (derivado+filtrado) e sinal de u');
end
exportgraphics(f, 'l7_diagnostico.png', 'Resolution', 150);
