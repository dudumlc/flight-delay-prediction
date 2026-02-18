# Pipeline de Dados: Aviação (ANAC) vs Clima (INMET)

Automatiza o processo de ETL (Extração, Transformação e Carga) de dados de voos da **ANAC (Voo Regular Ativo - VRA)** e dados meteorológicos horários do **INMET (Instituto Nacional de Meteorologia)**, consolidando-os em um banco de dados SQLite unificado.

## Funcionalidades

- Extração automatizada de portais ANAC e INMET.
- Download e descompactação em memória (io.BytesIO) — sem arquivos temporários no disco.
- Padronização de schema (camelCase) e unificação de colunas que mudaram ao longo do tempo.
- Conversão de codificação latin-1 → utf-8.
- Limpeza de acentuação e caracteres especiais com `unidecode`.
- Normalização de decimais (`,` → `.`) para compatibilidade com SQL.
- Retentativas (retries) em downloads instáveis e verificação de duplicidade para idempotência.

## Estrutura do projeto

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

## Tecnologias

- Python 3.10+
- pandas
- BeautifulSoup4
- requests
- sqlite3 (builtin)
- unidecode

## Como executar

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
