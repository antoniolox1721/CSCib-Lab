"""Gera o PRBS para REPETIR a aquisicao (bloco 'From Workspace').
MLS de 8 bits, bit = 10 amostras (0,2 s, banda ~[0 0.1]), 2001 amostras, media ~0.
Escolhe o deslocamento circular que minimiza a excursao do integrador do motor
(modelo simples: dtheta/dt = 77 graus/s por V, medido na quadrada) para o
potenciometro nao dar a volta (limite +-180 graus, ~+-5,15 V).
"""
import numpy as np, scipy.io as s, os
A = 0.7; N = 2001; BIT = 10; K = 77.0; Ts = 0.02
reg = [1]*8; m = []
for _ in range(255):                       # x^8+x^6+x^5+x^4+1 (maximo)
    m.append(reg[-1]); fb = reg[7] ^ reg[5] ^ reg[4] ^ reg[3]; reg = [fb] + reg[:-1]
m = 2*np.array(m)-1
best = None
for sh in range(255):
    b = np.roll(m, sh); u = A*np.repeat(b, BIT)[:N]
    th = np.cumsum(K*u*Ts); th -= th[0]
    ex = th.max()-th.min(); mu = abs(u.mean())
    sc = ex + 500*mu
    if best is None or sc < best[0]: best = (sc, sh, u, ex, mu)
_, sh, u, ex, mu = best
t = np.arange(N)*Ts
print(f'shift={sh}  media={u.mean():+.4f} V  excursao simulada={ex:.0f} graus (pico-a-pico)  max corrida={max(len(list(g)) for g in np.split(u, np.where(np.diff(u)!=0)[0]+1))*Ts:.1f} s')
d = os.path.dirname(__file__)
s.savemat(f'{d}/sinal_prbs_repeticao.mat', {'sinal_prbs': np.c_[t, u]})
np.savetxt(f'{d}/sinal_prbs_repeticao.csv', np.c_[t, u], delimiter=',', header='t,u', comments='')
