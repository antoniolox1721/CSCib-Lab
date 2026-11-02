%% L7_TREINO_INDIVIDUAL.m (SEM zona morta, d = 0; historico: mostra a dependencia da amplitude que levou a modelar a zona morta) - ARMAX(3,4,3,1) treinado em cada ficheiro de ID sozinho vs merge das 3; valida nas 2 validacoes (1 V e 0,5 V).
% Corre com a pasta atual = L7_revisao:  matlab -batch l7_treino_individual
% (a coluna "pos" usa cumsum do sinal derivado+filtrado; diferente do fit de posicao de l7_diagnostico.m)
C=load('../L2-L3_sensores/calibracao_sensores.mat','Kp','Ke','offset'); Ts=0.02; af=0.8; Af=[1 -af]; Bf=(1-af)*[1 -1]; nd=400;
nm={'dados_ID_quadrada_1V','dados_ID_prbs_1Hz_0.5','dados_ID_prbs_2_5Hz_0.5','dados_validacao','dados_ID_validacao_0_5'};
for k=1:5, S=load(['../L4_identificacao/' nm{k} '.mat'],'ScopeData').ScopeData; S=S(nd+1:end,:); yt=S(:,3)*C.Kp+(S(:,4)-C.offset)*C.Ke; u{k}=detrend(S(:,2),'constant'); yf{k}=detrend(filter(Bf,Af,yt-yt(1)),'constant'); end
fitf=@(y,yp) 100*(1-norm(y(30:end)-yp(30:end))/norm(y(30:end)-mean(y(30:end))));
pos=@(y,yp) fitf(cumsum(y)-mean(cumsum(y)), cumsum(yp)-mean(cumsum(yp)));  % cumsum(yf) ~ posicao filtrada
mk=@(i) merge(iddata(yf{i(1)},u{i(1)},Ts),iddata(yf{i(end)},u{i(end)},Ts));
cfg={'so quadrada 1V',{1};'so PRBS 1Hz',{2};'so PRBS 2.5Hz',{3};'merge das 3',{1,2,3}};
fprintf('%-16s | val1V filt/pos | val0.5V filt/pos | max|polo| | polos\n','treino');
for c=1:4
  idx=cfg{c,2}{1}; if c<4, d=iddata(yf{idx},u{idx},Ts); else d=merge(iddata(yf{1},u{1},Ts),iddata(yf{2},u{2},Ts),iddata(yf{3},u{3},Ts)); end
  th=armax(d,[3 4 3 1]); p=roots(th.A); r=zeros(1,4);
  for v=1:2, yp=sim(th,u{3+v}); r(2*v-1)=fitf(yf{3+v},yp); r(2*v)=pos(yf{3+v},yp); end
  g=@(v) (sim(th,u{v})'*yf{v})/(sim(th,u{v})'*sim(th,u{v}));
  fprintf('%-16s | %5.1f / %5.1f | %5.1f / %5.1f | %.3f | %s | ganho1V %.2f 0.5V %.2f\n',cfg{c,1},r,max(abs(p)),mat2str(round(p.',3)),g(4),g(5));
end
