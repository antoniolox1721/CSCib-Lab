# L5 — Processamento de dados e identificação ARMAX

> **Estado (2026-10-19): concluído.** Este README é o checklist de preparação original; o PRBS foi repetido a 0,5 V (não a 0,7 V como aqui). Resultados finais, zona morta de 0,25 V e modelo atual: `Lab/L4_identificacao/Lab4.txt` e `Lab/L7_revisao/`. Os scripts `l5_armax_oficial.m` e `l5_armax_validacao05.m` já usam a zona morta; `l5_identificacao.m` e os `.py` são a versão de preparação (sem zona morta).

**Objetivo (guia, Sec. 4):** modelo ARMAX da planta + escolha de ordens **justificada**. Não precisa da planta.

## Antes da aula
- [ ] Definir a pasta atual do MATLAB = `Lab/L5_armax` e correr `l5_identificacao.m` secção a secção.
- [ ] **Repetir o PRBS** (o L4 falhou: o potenciómetro deu a volta). Se houver bancada antes do L5/L6: usar
      `sinal_prbs_repeticao.mat` (variável `sinal_prbs = [t u]`, 0,7 V, média ≈ 0, 2001 amostras, bit de 0,2 s)
      no bloco *From Workspace*, ficheiro `_20ms`, **barra centrada (pot ≈ 0 V)**, gravar 40 s,
      `view_io save` → `Lab/L4_identificacao/dados_ID_prbs_repeticao.mat`.
      Durante o ensaio o pot deve ficar dentro de ≈ ±3 V. Depois, no script, descomentar a 2.ª linha de `ficheiros_id`.
- [ ] Rever M3.1–M3.6 (estimação, RLS, processos estocásticos, máxima verosimilhança).

## Estado dos dados (validação de 29/09)
| Ficheiro | Uso |
|---|---|
| `dados_ID_quadrada_1V` | identificação ✅ |
| `dados_validacao` | só validação ✅ |
| `dados_ID_pequeno` / `_grande` | só relatório (zona morta / não linearidade) |
| `dados_ID_prbs_1Hz` / `_2_5Hz` | ❌ pot deu a volta → repetir |

## Na aula
1. Sec. 0–1: correr, confirmar que **não há avisos de saturação** e que `std(yf)` é semelhante nos dois ficheiros (≈ 1,6).
2. Sec. 2: escolher `af` (guia: 0,8) e guardar as duas figuras para o relatório.
3. Sec. 3: tabela `tabela_ordens_*.csv` (na, nb, nc, nk, fit %, polo máx, BIC) — **é a evidência da escolha de ordens**.
4. Sec. 4: modelo escolhido, Fig. 12 (modelo vs. dados derivados), resíduos. Gravar `l5_resultados.mat`.
5. Se sobrar tempo: repetir com o PRBS novo e comparar as tabelas.

## O que esperar (pré-visualização em Python, sem toolbox — `referencia_ordens.csv`)
Com a quadrada como identificação e `dados_validacao` como validação, `af = 0,8`:
fit ≈ 92–94 % para na = 3–6, nb = 3–5; **na = 3, nb = 4 → ≈ 93,9 %** (polo máx ≈ 0,79).
Ordens altas (na ≥ 5) quase não melhoram → argumento para um modelo baixo (motor + barra ⇒ poucos polos).
Os números oficiais saem do `armax` (usa ELS/PEM, podem diferir uns décimos).

## Perguntas do guia para o relatório (Q3)
- **Porque é que derivar aumenta o ruído?** A derivada tem ganho ∝ ω (|1−e^{−jω}| cresce até ω = π/Ts), logo amplifica alta frequência, onde há ruído e pouco sinal.
- **O que faz o filtro** `(1−af)(1−z⁻¹)/(1−af·z⁻¹)`? Zero em z = 1 (cancela o integrador do motor / tira a média) e polo em af (passa-baixo de 1.ª ordem; ganho unitário em altas frequências normalizado por (1−af)). Sec. 2 mostra o efeito de af.
- **Como se tratou o polo na origem?** Retirou-se antes de identificar (derivada) e volta-se a somar na L6 com `conv(den1,[1 -1])`.
- **Como escolher a ordem?** Trade-off fit vs. complexidade (tabela); a resposta final é o desempenho do controlador (L8+). Motor DC ⇒ 1–2 polos + integrador; barra flexível ⇒ 1.º modo (par complexo) ⇒ na ≈ 3–4 é plausível.
- **Frequência de amostragem:** 50 Hz, fixa; o modo da barra fica bem abaixo de 25 Hz.

## Ficheiros desta pasta
| Ficheiro | Para quê |
|---|---|
| `l5_identificacao.m` | script principal da aula |
| `previsao_python.py`, `referencia_ordens.csv` | pré-visualização sem toolbox |
| `gerar_prbs_repeticao.py`, `sinal_prbs_repeticao.mat/.csv` | PRBS novo para repetir o ensaio |
