"""ARMAX (ELS) com varias experiencias em conjunto; escolha de ordem por validacao + leave-one-out.
Saida: tabela e modelo final. Corre: python identificar_conjunto.py"""
import numpy as np, scipy.signal as sg
from previsao_python import prep
def fit(y, yp, n0=30): return 100*(1-np.linalg.norm(y[n0:]-yp[n0:])/np.linalg.norm(y[n0:]-y[n0:].mean()))
def armax_multi(exps, na, nb, nc, nk=1, it=15):
    n0 = max(na, nb+nk-1, nc); es = [np.zeros(len(y)) for y, u in exps]
    for _ in range(it):
        Rs, ys = [], []
        for (y, u), e in zip(exps, es):
            N = len(y)
            R = [np.r_[np.zeros(i), -y[:N-i]] for i in range(1, na+1)] + [np.r_[np.zeros(nk+i), u[:N-nk-i]] for i in range(nb)] \
              + [np.r_[np.zeros(i), e[:N-i]] for i in range(1, nc+1)]
            Rs.append(np.array(R).T[n0:]); ys.append(y[n0:])
        th = np.linalg.lstsq(np.vstack(Rs), np.concatenate(ys), rcond=None)[0]
        es = [y - np.array([np.r_[np.zeros(i), -y[:len(y)-i]] for i in range(1, na+1)] + [np.r_[np.zeros(nk+i), u[:len(y)-nk-i]] for i in range(nb)] + [np.r_[np.zeros(i), e[:len(y)-i]] for i in range(1, nc+1)]).T @ th
              for (y, u), e in zip(exps, es)]
    return np.r_[1, th[:na]], np.r_[np.zeros(nk), th[na:na+nb]], np.r_[1, th[na+nb:]]
if __name__ == '__main__':
    F = {'Q': 'dados_ID_quadrada_1V', 'P1': 'dados_ID_prbs_1Hz_0.5', 'P2': 'dados_ID_prbs_2_5Hz_0.5'}
    X = {k: tuple(reversed(prep(f))) for k, f in F.items()}          # (y,u)
    uv, yv = prep('dados_validacao')
    print("na nb | fit_val(quad.6Hz) | leave-one-out: sem Q / sem P1 / sem P2 (teste no ficheiro de fora) | max|polo|")
    rows = []
    for na in range(2, 6):
        for nb in range(2, 6):
            A, B, C = armax_multi(list(X.values()), na, nb, na)
            if np.abs(np.roots(A)).max() >= 1: continue
            fv = fit(yv, sg.lfilter(B, A, uv)); loo = []
            for k in X:
                A2, B2, _ = armax_multi([v for kk, v in X.items() if kk != k], na, nb, na)
                y, u = X[k]; loo.append(fit(y, sg.lfilter(B2, A2, u)) if np.abs(np.roots(A2)).max() < 1 else np.nan)
            rows.append((na, nb, fv, loo, np.abs(np.roots(A)).max()))
            print(f"{na}  {nb}  | {fv:6.2f} | {loo[0]:6.2f} {loo[1]:6.2f} {loo[2]:6.2f} | {rows[-1][4]:.3f}")
