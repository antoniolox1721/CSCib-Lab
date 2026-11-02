"""Pre-visualizacao do L5 em Python (sem toolboxes): mesma cadeia que o guia.
detrend/derivar+filtrar -> ARMAX (minimos quadrados estendidos) -> fit em dados_validacao.
Serve so para saber o que esperar; os numeros oficiais saem do armax do MATLAB.
"""
import numpy as np, scipy.io as s, scipy.signal as sg, csv, os
D = os.path.join(os.path.dirname(__file__), '..')
c = s.loadmat(f'{D}/L2-L3_sensores/calibracao_sensores.mat')
Kp, Ke, off = (float(np.ravel(c[k])[0]) for k in ('Kp', 'Ke', 'offset'))
Ts, af, descartar = 0.02, 0.8, 400          # 8 s

def prep(f, af=af):
    S = s.loadmat(f'{D}/L4_identificacao/{f}.mat')['ScopeData'][descartar:]
    u = sg.detrend(S[:, 1], type='constant')
    y = sg.detrend(S[:, 2]*Kp + (S[:, 3]-off)*Ke, type='linear')
    return u, sg.lfilter((1-af)*np.array([1., -1.]), [1., -af], y)

def armax_els(y, u, na, nb, nc, nk=1, it=15):
    """ARMAX A(q)y = B(q)u + C(q)e, A,C monicos, B com nb termos e atraso nk."""
    N = len(y); e = np.zeros(N); n0 = max(na, nb+nk-1, nc)
    for _ in range(it):
        R = [np.r_[np.zeros(i), -y[:N-i]] for i in range(1, na+1)]
        R += [np.r_[np.zeros(nk+i), u[:N-nk-i]] for i in range(nb)]
        R += [np.r_[np.zeros(i), e[:N-i]] for i in range(1, nc+1)]
        R = np.array(R).T
        th = np.linalg.lstsq(R[n0:], y[n0:], rcond=None)[0]
        e = y - R@th
    return np.r_[1, th[:na]], np.r_[np.zeros(nk), th[na:na+nb]]      # A, B

if __name__ == '__main__':
    u, y = prep('dados_ID_quadrada_1V'); uv, yv = prep('dados_validacao')
    rows = []
    for na in range(2, 7):
        for nb in range(1, 6):
            A, B = armax_els(y, u, na, nb, na)
            yp = sg.lfilter(B, A, uv)
            m = slice(30, None)
            fit = 100*(1-np.linalg.norm(yv[m]-yp[m])/np.linalg.norm(yv[m]-yv[m].mean()))
            pm = np.abs(np.roots(A)).max()
            rows.append((na, nb, na, round(fit, 2) if np.isfinite(fit) else -999, round(pm, 3), 'estavel' if pm < 1 else 'INSTAVEL'))
    rows.sort(key=lambda r: (r[5] != 'estavel', -r[3]))
    with open(os.path.join(os.path.dirname(__file__), 'referencia_ordens.csv'), 'w', newline='') as fh:
        w = csv.writer(fh); w.writerow(['na', 'nb', 'nc', 'fit_val_%', 'max|polo|', 'estabilidade']); w.writerows(rows)
    print('na nb nc  fit_val%  max|polo|'); [print(*r) for r in rows[:12]]
    print('...pior:', rows[-1])
