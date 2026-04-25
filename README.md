# PREVISÃO DE ATRASO DE VOOS

Projeto que utiliza dados dados de voos da **ANAC (Voo Regular Ativo - VRA)** e dados meteorológicos horários do **INMET (Instituto Nacional de Meteorologia)** para tentar antecipar a probabilidade de um voo atraso no mínimo 30 minutos (tempo determinado pela ANAC para considerar um voo atrasado) com 1 hora de antecedência da da partida prevista inicial. 

## Funcionalidades

- Extração automatizada de portais ANAC e INMET utilizando **Python**.
- Organização da arquitetura Medalhão.
- Utilização de **SQL** para criação de todas as features stores.
- Comparação entre modelosd de ML, como **XGBoost, Catboost e Random Forest**.

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
