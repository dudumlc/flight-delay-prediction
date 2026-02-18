import os
import requests
from bs4 import BeautifulSoup
from urllib.parse import urljoin
import sqlite3
import pandas as pd

from src.utils import padronizar_coluna_voo

# Configurações
BASE_URL = "https://sistemas.anac.gov.br/dadosabertos/Voos%20e%20opera%C3%A7%C3%B5es%20a%C3%A9reas/Voo%20Regular%20Ativo%20%28VRA%29/"
EXTENSOES_ALVO = ['.csv']
DIRETORIO_DESTINO_ARQUIVOS = "arquivos_voos"


def salvar_no_sqlite(caminho_csv):
    # Garante que a pasta 'data' existe
    os.makedirs('data', exist_ok=True)
    caminho_db = os.path.join('data', 'database.db')
    
    conn = sqlite3.connect(caminho_db)
    
    try:
        # Nota: O VRA da ANAC geralmente usa sep=';' e encoding='latin-1'
        # low_memory=False evita avisos de tipos de dados mistos
        df = pd.read_csv(caminho_csv, skiprows=1, sep=';', low_memory=False)
        
        # APLICA A NOVA PADRONIZAÇÃO (Chama a função para cada coluna)
        df.columns = [padronizar_coluna_voo(c) for c in df.columns]

        # O pandas cria a tabela 'voos' se não existir (if_exists='append')
        df.to_sql('voos', conn, if_exists='append', index=False)
        
        print(f"    [SQLITE] {len(df)} linhas inseridas em {caminho_db}")
        
    except Exception as e:
        print(f"    [ERRO SQLITE] Falha ao processar {caminho_csv}: {e}")
    finally:
        conn.close()


def extrair_vra():
    print(f"--- Iniciando conexão com: {BASE_URL} ---")
    try:
        response = requests.get(BASE_URL, timeout=15)
        response.raise_for_status()
    except Exception as e:
        print(f"[ERRO] Falha ao acessar site da ANAC: {e}")
        return

    soup = BeautifulSoup(response.text, 'html.parser')
    links_ano = soup.find_all('a')
    print(f"[LOG] Encontrados {len(links_ano)} links na raiz.")

    for link_ano in links_ano:
        href_ano = link_ano.get('href')
        if not href_ano: continue
        
        # Limpa o nome da pasta (remove /) para validar se é ano
        pasta_ano = href_ano.strip('/')
        
        if pasta_ano.isdigit() and len(pasta_ano) == 4:
            print(f"\n[ANO] Entrando na pasta: {pasta_ano}")
            url_ano = urljoin(BASE_URL, href_ano)
            
            try:
                res_ano = requests.get(url_ano, timeout=15)
                soup_ano = BeautifulSoup(res_ano.text, 'html.parser')
                links_mes = soup_ano.find_all('a')
                
                for link_mes in links_mes:
                    href_mes = link_mes.get('href', '')
                    # Verifica se o link contém o padrão de meses (ex: "01%20-%20Janeiro")
                    if " - " in href_mes or "%20-%20" in href_mes:
                        print(f"  [MÊS] Acessando: {href_mes}")
                        url_mes = urljoin(url_ano, href_mes)
                        
                        res_mes = requests.get(url_mes, timeout=15)
                        soup_mes = BeautifulSoup(res_mes.text, 'html.parser')
                        
                        for link_arq in soup_mes.find_all('a'):
                            href_arq = link_arq.get('href', '')
                            if any(href_arq.lower().endswith(ext) for ext in EXTENSOES_ALVO):
                                
                                # Organização de pastas locais
                                pasta_final = os.path.join('data',DIRETORIO_DESTINO_ARQUIVOS, pasta_ano, href_mes.replace('%20', ' ').strip('/'))
                                os.makedirs(pasta_final, exist_ok=True)
                                
                                caminho_arquivo = os.path.join(pasta_final, href_arq)
                                url_final = urljoin(url_mes, href_arq)
                                
                                if not os.path.exists(caminho_arquivo):
                                    print(f"    [DOWNLOAD] Baixando: {href_arq}...")
                                    f_res = requests.get(url_final)
                                    with open(caminho_arquivo, 'wb') as f:
                                        f.write(f_res.content)
                                    print(f"    [OK] Salvo em: {caminho_arquivo}")

                                    # NOVA LINHA:
                                    if caminho_arquivo.lower().endswith('.csv'):
                                        salvar_no_sqlite(caminho_arquivo)


                                else:
                                    print(f"    [SKIP] Arquivo já existe: {href_arq}")
            except Exception as e:
                print(f"  [ERRO] Falha ao processar ano {pasta_ano}: {e}")

    print("\n--- Processo Finalizado ---")

if __name__ == "__main__":
    extrair_vra()
