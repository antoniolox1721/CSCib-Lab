"""Double-check dos PRBS novos + identificacao ARMAX (ELS, sem toolbox). Reusa previsao_python.py.
Corre: python identificar_prbs.py   (precisa de numpy/scipy)"""
import numpy as np, scipy.io as s, scipy.signal as sg
from previsao_python import prep, armax_els, D, Kp, Ke, off, Ts

def fit(y, yp, n0=30): return 100*(1-np.linalg.norm(y[n0:]-yp[n0:])/np.linalg.norm(y[n0:]-y[n0:].mean()))
SETS = {'quadrada 1V': 'dados_ID_quadrada_1V', 'prbs 1Hz 0.5': 'dados_ID_prbs_1Hz_0.5',
        'prbs 2.5Hz 0.5': 'dados_ID_prbs_2_5Hz_0.5'}
VAL = 'dados_validacao'

print("== 1. Sanidade: resposta ao impulso estimada por FIR (u -> yf), cada ficheiro, deve ser coerente ==")
H = {}
for k, f in SETS.items():
    u, y = prep(f); n = 40
    U = np.array([np.r_[np.zeros(i), u[:len(u)-i]] for i in range(1, n+1)]).T       # nk=1
    h = np.linalg.lstsq(U[n:], y[n:], rcond=None)[0]; H[k] = h
    r = y[n:] - U[n:]@h
    print(f"{k:16s} std(u)={u.std():.3f} std(yf)={y.std():.3f} R2_FIR={100*(1-r.var()/y[n:].var()):.1f}%  h[1..6]={np.round(h[:6],2)}")
ks = list(H)
for i in range(len(ks)):
    for j in range(i+1, len(ks)):
        c = np.corrcoef(H[ks[i]][:15], H[ks[j]][:15])[0, 1]
        print(f"  corr(resposta impulso 15 amostras) {ks[i]} vs {ks[j]}: {c:.3f}")

print("\n== 2. Identificacao ARMAX: fit(%) na validacao (quadrada 0.6 Hz) e cruzada ==")
uv, yv = prep(VAL)
res = []
for k, f in SETS.items():
    u, y = prep(f)
    for na in range(2, 7):
        for nb in range(1, 6):
            A, B = armax_els(y, u, na, nb, na)
            pm = np.abs(np.roots(A)).max()
            fv = fit(yv, sg.lfilter(B, A, uv))
            others = [fit(prep(g)[1], sg.lfilter(B, A, prep(g)[0])) for kk, g in SETS.items() if kk != k]
            bic = (len(yv)-30)*np.log(np.mean((yv[30:]-sg.lfilter(B, A, uv)[30:])**2)) + (2*na+nb)*np.log(len(yv)-30)
            res.append((k, na, nb, fv, np.mean(others), pm, bic))
for k in SETS:
    r = sorted([x for x in res if x[0] == k and x[5] < 1], key=lambda x: -x[3])[:4]
    print(k); [print(f"   na={x[1]} nb={x[2]} fit_val={x[3]:6.2f}%  fit_cruzado(med)={x[4]:6.2f}%  max|polo|={x[5]:.3f}") for x in r]
