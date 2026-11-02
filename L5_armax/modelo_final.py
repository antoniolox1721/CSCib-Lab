"""Modelo final: ARMAX(3,4,3,1) em conjunto (quadrada + 2 PRBS) -> reintroduz integrador -> espaco de estados.
Grava ../L4_identificacao/modelo_identificado.mat (A,B,Cc,Dd,Ts,controlavel) como o identificacao_modelo.m."""
import numpy as np, scipy.signal as sg, scipy.io as s, os
from identificar_conjunto import armax_multi, fit
from previsao_python import prep, Ts
F = ['dados_ID_quadrada_1V', 'dados_ID_prbs_1Hz_0.5', 'dados_ID_prbs_2_5Hz_0.5']
na, nb = 3, 4
A, B, C = armax_multi([tuple(reversed(prep(f))) for f in F], na, nb, na)
uv, yv = prep('dados_validacao'); yp = sg.lfilter(B, A, uv)
res = yv[30:] - yp[30:]; ac = np.correlate(res-res.mean(), res-res.mean(), 'full')[len(res)-1:]; ac /= ac[0]
Q = len(res)*(len(res)+2)*np.sum(ac[1:21]**2/(len(res)-np.arange(1, 21)))      # Ljung-Box 20 lags
print("A =", np.round(A, 4), "\nB =", np.round(B, 4), "\nC =", np.round(C, 4))
print("polos (filtrado):", np.round(np.roots(A), 3), "max|polo| = %.3f" % np.abs(np.roots(A)).max())
print("fit validacao %.2f %% | MSE %.4g | Ljung-Box Q(20)=%.1f (crit. 5%% = 31.4) | |ac| max lag1-20 %.2f (limite 95%% = %.2f)" % (fit(yv, yp), np.mean(res**2), Q, np.abs(ac[1:21]).max(), 1.96/np.sqrt(len(res))))
den = np.convolve(A, [1, -1]); num = B                                                  # B ja inclui o atraso nk (len = nk+nb = len(den)): G = B(z^-1)/(A(z^-1)(1-z^-1))
Ass, Bss, Css, Dss = sg.tf2ss(num, den)
n = Ass.shape[0]; ctrb = np.hstack([np.linalg.matrix_power(Ass, i) @ Bss for i in range(n)])
rk = np.linalg.matrix_rank(ctrb); print("estados %d, rank ctrb %d, polos malha aberta:" % (n, rk), np.round(np.roots(den), 3))
out = os.path.join('..', 'L4_identificacao', 'modelo_identificado.mat')
assert not os.path.exists(out), "ja existe " + out
s.savemat(out, dict(A=Ass, B=Bss, Cc=Css, Dd=Dss, Ts=Ts, controlavel=float(rk == n), num1=B, den1=A, sse_validacao=np.mean(res**2),
                    fonte='ARMAX(3,4,3,1) ELS conjunto quadrada1V+prbs1Hz0.5+prbs2.5Hz0.5, af=0.8, validado em dados_validacao'))
print("gravado", out)
