%% VERIFICAR_KE_KP.m - consistencia de Ke/Kp/offset: ajuste livre do pente, declive por metade, sinais (u->theta_dot, alpha vs theta_ddot).
% Corre com a pasta atual = L2-L3_sensores:  matlab -batch verificar_Ke_Kp
C=load('calibracao_sensores.mat'); n=C.n_slots(:); V=C.tensoes_alphae_V(:); a=C.alpha_graus(:);
p=polyfit(V,a,1); fprintf('fit livre a=%.4f*V%+.4f  (V p/ alpha=0: %.4f; V slot0: %.4f; offset L3: %.4f; dif: %.3f V = %.2f graus)\n',p,-p(2)/p(1),V(n==0),C.offset,V(n==0)-C.offset,(V(n==0)-C.offset)*C.Ke);
r=a-polyval(p,V); fprintf('residuos graus: %s | max %.2f\n',mat2str(r',2),max(abs(r)));
% declive por metade (linearidade)
pa=polyfit(V(n>=0),a(n>=0),1); pb=polyfit(V(n<=0),a(n<=0),1); fprintf('declive +slots %.3f | -slots %.3f\n',pa(1),pb(1));
% sinais: u->theta e theta''->alpha
pasta='../L4_identificacao/'; for f={'dados_validacao','dados_ID_quadrada_1V'}
 S=load([pasta f{1} '.mat'],'ScopeData').ScopeData; S=S(401:end,:); u=S(:,2); th=S(:,3)*C.Kp; al=(S(:,4)-C.offset)*C.Ke;
 b=ones(1,5)/5; ths=filter(b,1,th); v=gradient(ths,0.02); acc=gradient(filter(b,1,v),0.02); als=detrend(filter(b,1,al));
 fprintf('%s: corr(u,theta_dot)=%+.2f | corr(alpha,theta_ddot)=%+.2f | std theta=%.1f alpha=%.2f graus | alpha pico-a-pico %.1f\n',f{1},corr(u,v),corr(als,acc),std(th),std(al),max(al)-min(al));
end
