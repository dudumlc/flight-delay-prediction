import sqlite3
import pandas as pd
import os

class ANACDatabase:
    def __init__(self, db_path=os.path.join('data', 'anac_vra.db')):
        os.makedirs(os.path.dirname(db_path), exist_ok=True)
        self.db_path = db_path

    def salvar_csv(self, caminho_csv):
        try:
            # VRA usa ; e latin-1. low_memory evita avisos de tipos mistos
            df = pd.read_csv(caminho_csv, sep=';', encoding='latin-1', low_memory=False)
            
            with sqlite3.connect(self.db_path) as conn:
                # Se a tabela não existe, o pandas cria. Se existe, adiciona.
                df.to_sql('voos', conn, if_exists='append', index=False)
            
            return len(df)
        except Exception as e:
            print(f"      [ERRO DATABASE] {e}")
            return 0
