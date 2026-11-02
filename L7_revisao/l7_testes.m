%% L7_TESTES.m - testes de verificacao (so dados reais): dados, calibracao, modelo, validacao independente, resposta em frequencia.
% Corre com a pasta atual = L7_revisao:  matlab -batch l7_testes   (corre l7_revisao.m antes se mudares o modelo)
clear; clc; ok = 0; function chk(c, msg), if ~c, error('FALHOU: %s', msg); else, fprintf('  ok  %s\n', msg); end, end
L4 = fullfile(fileparts(pwd), 'L4_identificacao'); L3 = fullfile(fileparts(pwd), 'L2-L3_sensores');
C = load(fullfile(L3, 'calibracao_sensores.mat')); M = load('l7_modelo_final.mat'); S4 = load(fullfile(L4, 'modelo_identificado.mat'));
ids = {'dados_ID_quadrada_1V','dados_ID_prbs_1Hz_0.5','dados_ID_prbs_2_5Hz_0.5'}; vals = {'dados_validacao','dados_ID_validacao_0_5'};
ld = @(n) load(fullfile(L4, [n '.mat']), 'ScopeData').ScopeData;
fprintf('\n[1] Dados\n');
for n = [ids vals]
    S = ld(n{1}); t = S(:,1); chk(all(isfinite(S(:))) && abs(median(diff(t))-0.02)<1e-9 && max(abs(diff(t)-0.02))<1e-6, [n{1} ': sem NaN, Ts = 0.02 s exato']);
    chk(max(abs(diff(S(:,3))))<5 && max(abs(S(:,3)))<5.1, [n{1} ': potenciometro sem voltas/saturacao']);
end
G = ld('dados_ID_grande'); chk(sum(abs(diff(G(:,3)))>5) > 10, 'dados_ID_grande: pot da voltas (confirma que so serve para relatorio)');
fprintf('\n[2] Calibracao\n');
Kp_ind = 360/(max(G(:,3))-min(G(:,3))); chk(abs(C.Kp-Kp_ind)/Kp_ind < 0.005, sprintf('Kp guardado %.3f vs independente (span do pot em dados_ID_grande) %.3f, dif < 0.5%%', C.Kp, Kp_ind));
D = C.n_slots(:)*0.25*0.0254; a = rad2deg(D/C.comprimento_barra_m); chk(max(abs(a-C.alpha_graus(:)))<1e-6, 'alpha[graus] = D/L*180/pi reproduzido');
p = polyfit(C.tensoes_alphae_V(:)-C.offset, a, 1); chk(abs(p(1)-C.Ke)<1e-6, sprintf('Ke = %.4f reproduzido por polyfit', p(1)));
r = corrcoef(C.tensoes_alphae_V(:), a); chk(r(1,2)^2 > 0.999, sprintf('R2 do pente = %.4f', r(1,2)^2));
for f = {'ScopeData_Ke_esquerda','ScopeData_Ke_direita'}   % leituras do registo = patamares (>= 1.5 s) dos ficheiros em bruto
    Xr = load(fullfile(L3, [f{1} '.mat'])).ScopeData(:,4); w = 50; xs = movmedian(Xr, w); est = (movmax(xs,w)-movmin(xs,w)) < 0.02;
    d = diff([0; est; 0]); a0 = find(d==1); b0 = find(d==-1)-1; k = (b0-a0)*0.02 >= 1.5; a0 = a0(k); b0 = b0(k); pl = arrayfun(@(q) median(Xr(a0(q):b0(q))), 1:numel(a0));
    chk(numel(pl) == 8, [f{1} ': 8 patamares detetados']);
    chk(all(arrayfun(@(q) min(abs(C.tensoes_alphae_V - q)) < 0.015, pl)), [f{1} ': cada patamar coincide (<0.015 V) com uma leitura do registo']);
end
rest = cellfun(@(n) median_ext(ld(n)), [ids vals]); chk(all(abs(rest-C.offset) < 0.03), sprintf('extensometro em repouso na barra montada (%.3f..%.3f V) = offset %.3f V (+-0.03)', min(rest), max(rest), C.offset));
S = ld('dados_validacao'); S = S(401:end,:); u = S(:,2); th = S(:,3)*C.Kp; al = (S(:,4)-C.offset)*C.Ke; b = ones(1,5)/5;
v = gradient(filter(b,1,th),0.02); acc = gradient(filter(b,1,v),0.02);
chk(corr(u,v) > 0.5, 'sinal: u positivo -> pot sobe (Kp > 0)'); chk(corr(detrend(filter(b,1,al)),acc) < -0.3, 'sinal: alpha oposto a aceleracao (y = theta + alpha, Ke < 0)');
txt = fileread('l7_revisao.m'); li = regexp(txt, 'ids\s*=\s*\{[^}]*\}', 'match', 'once'); chk(~contains(li, 'validacao') && contains(li, 'prbs_1Hz_0.5'), 'ficheiros de validacao nao entram no treino (lista ids de l7_revisao.m)');
fprintf('\n[3] Modelo\n');
chk(isequal(S4.A, M.A) && isequal(S4.B, M.B) && isequal(S4.Cc, M.Cc) && S4.Dd == 0 && S4.Ts == 0.02, 'modelo_identificado.mat (usado no L8) = l7_modelo_final.mat');
chk(S4.deadzone_V == M.d_zm && M.d_zm == 0.25, sprintf('zona morta guardada = %.2f V', M.d_zm));
chk(rank(ctrb(M.A,M.B)) == 4 && rank(obsv(M.A,M.Cc)) == 4, 'controlavel e observavel (rank 4)');
e = eig(M.A); [~,i1] = min(abs(e-1)); chk(abs(e(i1)-1) < 1e-8 && all(abs(e([1:end]~=i1)) < 1), sprintf('polos: 1 (integrador) e %s dentro do circulo unitario', mat2str(round(abs(e([1:end]~=i1)).',3))));
[~, den] = deal(M.num1, conv(M.den1,[1 -1])); chk(max(abs(M.A(1,:) + den(2:5))) < 1e-9 && max(abs(M.Cc - M.num1(2:5))) < 1e-9, 'A(1,:) = -den(2:5) e C = num(2:5) (forma de tf2ss)');
u = randn(500,1); chk(max(abs(lsim(ss(M.A,M.B,M.Cc,M.Dd,M.Ts),u) - cumsum(filter(M.num1,M.den1,u)))) < 1e-8, 'lsim(A,B,C,D) = soma acumulada do ARMAX');
fprintf('\n[4] Validacao independente (filter do guia, em vez de sim; dados nao usados no treino)\n');
nd = 400; af = M.af_f; Af = [1 -af]; Bf = (1-af)*[1 -1]; fitf = @(y,yp) 100*(1-norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end)))); fv = zeros(1,2);
for k = 1:2
    S = ld(vals{k}); i = (nd+1):size(S,1); yt = S(i,3)*C.Kp + (S(i,4)-C.offset)*C.Ke; ue = sign(S(i,2)).*max(abs(S(i,2))-M.d_zm,0);
    yf = detrend(filter(Bf,Af,yt-yt(1)),'constant'); fv(k) = fitf(yf, filter(M.num1, M.den1, detrend(ue,'constant')));
end
chk(fv(1) > 88 && fv(2) > 80, sprintf('fit validacao: %.1f %% (1 V), %.1f %% (0.5 V) [filter(num1,den1,u)]', fv));
T = readtable('l7_refinar_d.csv'); j = T.ordens=="[3 4]" & abs(T.d_V-0.25)<1e-9; chk(T.fit_filt_medio(j) > 80 && T.desvio_ganho_medio(j) < 0.05, sprintf('validacao cruzada (leave-one-out nos 5 registos), d=0.25: fit medio %.1f %%, pior %.1f %%, desvio de ganho %.3f', T.fit_filt_medio(j), T.fit_filt_pior(j), T.desvio_ganho_medio(j)));
fprintf('\n[5] Resposta em frequencia: modelo vs estimativa nao parametrica dos dados (spa)\n');
w = 2*pi*(0.5:0.25:5); err = [];
for n = ids(2:3)
    S = ld(n{1}); i = (nd+1):size(S,1); yt = S(i,3)*C.Kp+(S(i,4)-C.offset)*C.Ke; ue = detrend(sign(S(i,2)).*max(abs(S(i,2))-M.d_zm,0),'constant'); yf = detrend(filter(Bf,Af,yt-yt(1)),'constant');
    g = spa(iddata(yf,ue,0.02), 60, w); Gs = squeeze(freqresp(g, w)); Gm = squeeze(freqresp(M.th, w)); e = 20*log10(abs(Gs)./abs(Gm)); err(end+1) = median(abs(e)); fprintf('      %s: mediana |erro| de modulo = %.1f dB (0.5-5 Hz)\n', n{1}, err(end));
end
chk(all(err < 6), 'modelo concorda com a estimativa espectral dos dados PRBS (< 6 dB)');
fprintf('\n[6] Residuos e incerteza\n');
S = ld(vals{1}); i = (nd+1):size(S,1); yt = S(i,3)*C.Kp+(S(i,4)-C.offset)*C.Ke; ue = detrend(sign(S(i,2)).*max(abs(S(i,2))-M.d_zm,0),'constant'); yf = detrend(filter(Bf,Af,yt-yt(1)),'constant');
yp = filter(M.num1,M.den1,ue); res = yf(30:end) - yp(30:end); r0 = res-mean(res); ac = xcorr(r0,20,'coeff'); ac = ac(22:end); n = numel(res); Q = n*(n+2)*sum(ac.^2./(n-(1:20)')); fprintf('      Ljung-Box (erro de simulacao, val 1 V): Q = %.0f (limite 95%% = %.1f) -> %s\n', Q, chi2inv(0.95,20), ternary(Q>chi2inv(0.95,20),'residuos NAO brancos (esperado: erro de simulacao + nao linearidade)','brancos'));
try   % incerteza dos parametros -> fraccao de amostras Monte-Carlo com zero fora do circulo unitario / polo instavel
    p0 = getpvec(M.th); Cv = getcov(M.th); Lc = chol((Cv+Cv')/2 + 1e-14*eye(numel(p0)), 'lower'); N = 300; fo = 0; inst = 0;
    for q = 1:N, t2 = setpvec(M.th, p0 + Lc*randn(size(p0))); zz = zero(t2); fo = fo + any(abs(zz) > 1); inst = inst + (max(abs(pole(t2))) >= 1); end
    fprintf('      Monte-Carlo (%d amostras da covariancia dos parametros): zero fora do circulo unitario em %.0f %%, modelo instavel em %.0f %%\n', N, 100*fo/N, 100*inst/N);
catch ME, fprintf('      (incerteza nao disponivel: %s)\n', ME.message); end
fprintf('\nTODOS OS TESTES PASSARAM\n');
function s = ternary(c,a,b), if c, s = a; else, s = b; end, end
function m = median_ext(S), m = median(S(1:75,4)); end
