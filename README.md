# ✈️ Previsão de Atrasos — Aeroporto de Confins (SBCF)

Classificador binário para prever se um voo saindo do Aeroporto Internacional de Confins (BH) atrasará **30 minutos ou mais**, com predição realizada **1 hora antes da partida prevista**.

---

## Problema

Passageiros raramente sabem com antecedência se seu voo vai atrasar. A ANAC disponibiliza dados históricos de todos os voos registrados no Brasil, o que abre a possibilidade de treinar um modelo preditivo baseado em padrões de atraso.

O desafio central é fazer uma predição útil com **apenas 1 hora de antecedência**, sem acesso a informações operacionais em tempo real (status de gate, rotação de aeronave, etc.).

**Definição do target:** `flagAtraso = 1` se `partidaReal - partidaPrevista > 30 minutos`.

---

## Dados

| Fonte | Descrição | Período |
|-------|-----------|---------|
| ANAC | Dados de voos (origem, destino, CIA, horários previstos e reais) | 2022 – atual |
| INMET | Dados climáticos horários da estação da Pampulha | 2022 – atual |

**Limitações relevantes:**
- Sem ID de aeronave → impossível montar cadeia de rotação (principal causa de atraso em cascata)
- Dados climáticos da Pampulha, não de Confins — estações distantes ~15km, com possível divergência em eventos convectivos locais
- Dataset desbalanceado: apenas **7,8% de voos atrasados**

---

## Feature Engineering

Features construídas em DuckDB, organizadas em quatro feature stores:

### `fs_atrasos`
Histórico de atrasos nas janelas de **3h, 12h e 24h** anteriores à partida prevista, segmentado por:
- Total no aeroporto
- Mesma rota (origem + destino)
- Mesmo destino
- Mesma companhia
- Companhia + rota

Inclui **ratios de aceleração** (ex: `atrasos3h / atrasos24h`) para capturar deterioração recente, e **percentuais** (atrasos / voos totais na janela).

### `fs_cancelamentos`
Mesma estrutura da `fs_atrasos`, mas para cancelamentos. Cancelamentos em cascata frequentemente precedem atrasos generalizados.

### `fs_clima`
Agregações de variáveis meteorológicas (temperatura, pressão, umidade, vento, precipitação) nas janelas de 3h, 12h e 24h — com média, máximo e desvio padrão.

### `fs_operacional`
Características do voo em si: tipo (doméstico/internacional/cargueiro), duração prevista, densidade de voos da CIA e do aeroporto no entorno temporal (±15min, ±30min, ±1h, ±2h), flag de primeiro voo do dia.

### `fs_temporal`
Hora de partida, dia da semana, mês, período do dia, semana do ano, flag de alta temporada (dezembro, janeiro, julho).

**Cuidado com data leakage:** todas as features foram construídas garantindo que apenas informações disponíveis até 1 hora antes da partida prevista fossem utilizadas — incluindo filtro `ts_real <= ts_previsto - 1h` para atrasos de voos anteriores.

---

## Modelagem

**Modelo:** CatBoostClassifier

**Divisão dos dados:**
- Treino: 70%
- Validação: 15% (early stopping)
- Teste: 15%
- Stratify em todas as divisões para manter proporção do target

**Tratamento do desbalanceamento:** `scale_pos_weight = 8` (~1/taxa de positivos)

**Hiperparâmetros principais:**
```python
CatBoostClassifier(
    iterations=1000,
    learning_rate=0.05,
    depth=6,
    l2_leaf_reg=5,
    eval_metric='Recall',
    early_stopping_rounds=50,
    scale_pos_weight=8,
    cat_features=['partidaPeriodoDia', 'aerodromoDestino', 'empresaAerea', 'numeroVoo']
)
```

---

## Resultados

| Métrica | Valor |
|---------|-------|
| ROC AUC | 0.711 |
| Recall | 0.411 |
| Precision | 0.201 |
| Accuracy | 0.826 |

> **Nota:** Accuracy é enganosa com dados desbalanceados — um modelo que sempre prevê "sem atraso" acertaria 92,2% dos casos.

**Top features por importância:**

| Feature | Importância | Interpretação |
|---------|------------|---------------|
| `pct_atrasosCia24h` | 6.73 | Taxa histórica de atraso da CIA nas últimas 24h |
| `numeroVoo` | 4.77 | Número do voo (risco de memorização) |
| `partidaHoraMinutoDecimal` | 4.75 | Horário da partida |
| `empresaAerea` | 2.60 | Companhia aérea |
| `voosConfinsIntervalo2h` | 2.46 | Congestionamento do aeroporto |
| `atrasos12h` | 2.33 | Atrasos recentes no aeroporto |

---

## Diagnóstico e Limitações

**Onde está o gargalo:** qualidade do sinal, não o modelo.

O feature importance revela que `numeroVoo` (2ª feature mais importante) indica memorização de padrões de voos específicos — o que fragiliza generalização. Features de atraso recente, que deveriam ser o sinal mais valioso, aparecem com importância relativamente baixa.

**Teto estimado com os dados atuais:** ROC AUC entre 0.72–0.76. Para superar isso seriam necessários:
- ID de aeronave (para reconstruir cadeia de rotação)
- Dados METAR/REDEMET de Confins (clima local, não Pampulha)

**O modelo captura bem:**
- Dias sistematicamente ruins para uma CIA
- Congestionamento geral do aeroporto
- Padrões temporais (horário de pico, sazonalidade)

**O modelo não consegue capturar:**
- Atrasos por rotação de aeronave
- Problemas operacionais pontuais (embarque, documentação)
- Condições no aeroporto de origem do voo anterior

---

## Próximos Passos (se continuado)

- [ ] Substituir dados climáticos da Pampulha por dados de Confins (METAR)
- [ ] Criar feature `pct_atrasosCia_hoje` — taxa de atraso da CIA no dia corrente até o momento da previsão
- [ ] Encoding cíclico do horário (`sin`/`cos`) em substituição a `partidaHora` + `partidaHoraMinutoDecimal`
- [ ] Avaliar remoção de `numeroVoo` para reduzir memorização
- [ ] Threshold sweep sistemático via curva precision-recall

---

## Estrutura do Repositório

```
├── data/               # Banco de dados SQLite (anac_vra.db) - [Ignorado no Git]
├── src/                # Módulos de lógica
│   ├── anac_crawler.py # Busca e parsing do site da ANAC
│   ├── inmet_crawler.py# Extração e filtro de ZIPs do INMET
│   ├── database.py     # Gerenciamento de conexão e checagem de duplicidade
│   └── utils.py        # Funções de limpeza e padronização
├── main_anac.py        # Orquestrador para dados de voos
├── main_inmet.py       # Orquestrador para dados climáticos
├── .gitignore
└── requirements.txt
```

---

## Reprodução

1. Clone o repositório:
```bash
git clone https://github.com/dudumlc/flight-delay-prediction
cd flight-delay-prediction
```

2. Crie e ative um ambiente virtual (Windows):
```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

3. Instale dependências:
```bash
pip install -r requirements.txt
```

4. Executar os orquestradores:
- Dados ANAC:
```bash
python main_anac.py
```
- Dados INMET:
```bash
python main_inmet.py
```

## Observações

- O diretório `data/` contém o banco SQLite e deve estar no .gitignore.
- Ajuste paths e configurações em `src/*` conforme necessário para credenciais ou proxies.

## Contato

Repositório original: https://github.com/dudumlc/flight-delay-prediction
