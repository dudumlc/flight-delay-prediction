import os
import requests
import sqlite3
import pandas as pd
import io
import zipfile
from bs4 import BeautifulSoup
from unidecode import unidecode

from src.utils import tratar_decimal, padronizar_coluna_clima

# --- CONFIGURAÇÕES ---
URL_INMET = "https://portal.inmet.gov.br/dadoshistoricos"
DB_PATH = os.path.join('data', 'database.db')
PREFIXO_ARQUIVO_ALVO = "PAMPULHA"


def processar_zip_inmet(url_zip, ano):
    try:
        print(f"  [INMET] Baixando ZIP de {ano}...")
        r = requests.get(url_zip, timeout=60) # Aumentado timeout para arquivos grandes
        r.raise_for_status()

        with zipfile.ZipFile(io.BytesIO(r.content)) as z:
            lista_arquivos = z.namelist()
            arquivo_alvo = next((f for f in lista_arquivos if PREFIXO_ARQUIVO_ALVO in f), None)
            
            if arquivo_alvo:
                print(f"    [ACHOU] Extraindo: {arquivo_alvo}")
                with z.open(arquivo_alvo) as f:
                    # O INMET usa latin-1 e ;
                    df = pd.read_csv(f, sep=';', encoding='latin-1', skiprows=8)
                    
                    # --- PADRONIZAÇÃO DE COLUNAS ---
                    # 1. Remove colunas vazias (comum no final dos CSVs do INMET)
                    df = df.dropna(axis=1, how='all')
                    
                    # APLICA A NOVA PADRONIZAÇÃO (Chama a função para cada coluna)
                    df.columns = [padronizar_coluna_clima(c) for c in df.columns]
                    
                    df['anoRef'] = ano

                    for col in df.columns:
                        df[col] = tratar_decimal(df, col)
                    
                    with sqlite3.connect(DB_PATH) as conn:
                        
                        df.to_sql('clima_inmet', conn, if_exists='append', index=False)
                    
                    print(f"    [SQLITE] {len(df)} linhas inseridas com sucesso.")
            else:
                print(f"    [AVISO] Estação não encontrada no ZIP de {ano}.")

    except Exception as e:
        print(f"    [ERRO] Falha no ano {ano}: {e}")


def extrair_dados_inmet():
    print(f"\n--- Iniciando Extração INMET ---")
    try:
        # Nota: O portal do INMET às vezes bloqueia requests sem User-Agent
        headers = {'User-Agent': 'Mozilla/5.0'}
        response = requests.get(URL_INMET, headers=headers, timeout=20)
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Encontra todos os links que terminam em .zip
        links = soup.find_all('a', href=True)
        zips_encontrados = [l['href'] for l in links if l['href'].endswith('.zip')]
        
        print(f"[LOG] Encontrados {len(zips_encontrados)} arquivos anuais.")

        for url_zip in zips_encontrados:
            # Extrai o ano do nome do arquivo (ex: 2023.zip -> 2023)
            ano = url_zip.split('/')[-1].replace('.zip', '')    
            processar_zip_inmet(url_zip, ano)

    except Exception as e:
        print(f"[ERRO CRÍTICO INMET] {e}")

if __name__ == "__main__":
    # Garante pasta de dados
    os.makedirs('data', exist_ok=True)
    
    # Inicia a automação
    extrair_dados_inmet()
