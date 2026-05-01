from unidecode import unidecode
import pandas as pd

def tratar_decimal(df,coluna):
    df[coluna] = df[coluna].apply(lambda x: str(x).replace(',', '0.') if str(x).startswith(',') else str(x).replace(',', '.'))
    return df[coluna]

def padronizar_coluna_clima(nome_original):
    nome_original = unidecode(nome_original).upper()
    
    # Mapeamento com as suas traduções em camelCase
    mapeamento = {
        # Datas e Horas
        'HORA (UTC)': 'hora',
        'HORA UTC': 'hora',
        'DATA (YYYY-MM-DD)': 'data',
        'DATA': 'data',
        
        # Pressão (Específicas primeiro)
        'PRESSAO ATMOSFERICA MAX': 'pressaoAtmosfericaMaxUltimaHora',
        'PRESSAO ATMOSFERICA MIN': 'pressaoAtmosfericaMinUltimaHora',
        'PRESSAO ATMOSFERICA AO NIVEL': 'pressaoAtmosferica',
        
        # Temperatura (Específicas primeiro)
        'TEMPERATURA ORVALHO MAX': 'temperaturaPontoOrvalhoMaxUltimaHora',
        'TEMPERATURA ORVALHO MIN': 'temperaturaPontoOrvalhoMinUltimaHora',
        'TEMPERATURA MAXIMA': 'temperaturaMaxUltimaHora',
        'TEMPERATURA MINIMA': 'temperaturaMinUltimaHora',
        'TEMPERATURA DO AR - BULBO SECO': 'temperaturaBulboSeco',
        'TEMPERATURA DO PONTO DE ORVALHO': 'temperaturaPontoOrvalho',
        
        # Umidade (Específicas primeiro)
        'UMIDADE REL. MAX': 'umidadeRelativaMaxUltimaHora',
        'UMIDADE REL. MIN': 'umidadeRelativaMinUltimaHora',
        'UMIDADE RELATIVA': 'umidadeRelativa',
        
        # Vento e Outros
        'VENTO, RAJADA': 'ventoRajadaMax',
        'VENTO, VELOCIDADE': 'ventoVelocidade',
        'VENTO, DIRECAO': 'ventoDirecaoGraus',
        'PRECIPITACAO': 'precipitacaoTotal',
        'RADIACAO': 'radiacaoGlobal'
    }

    for chave, nome_traduzido in mapeamento.items():
        if chave in nome_original:
            return nome_traduzido
            
    # Caso apareça algo novo, mantém um padrão camelCase básico
    return unidecode(nome_original).title().replace(' ', '').strip()

def padronizar_coluna_voo(nome_original):
    # nome_original = unidecode(nome_original).upper()
    
    # Mapeamento com as suas traduções em camelCase
    mapeamento = {
        'ICAO Empresa Aérea':'empresaAerea',
        'Número Voo':'numeroVoo',
        'Código Autorização (DI)':'codeAutorizacao',
        'Código Tipo Linha':'codeTipoLinha',
        'ICAO Aeródromo Origem':'aerodromoOrigem',
        'ICAO Aeródromo Destino':'aerodromoDestino',
        'Partida Prevista':'partidaPrevista',
        'Partida Real':'partidaReal',
        'Chegada Prevista':'chegadaPrevista',
        'Chegada Real':'chegadaReal',
        'Situação Voo':'situacaoVoo',
        'Código Justificativa':'codeJustificativa'
    }

    for chave, nome_traduzido in mapeamento.items():
        if chave in nome_original:
            return nome_traduzido
            
    # Caso apareça algo novo, mantém um padrão camelCase básico
    return unidecode(nome_original).title().replace(' ', '').strip()


def preencher_dados_vazios(df):
    num_cols = df.iloc[:,2:-1].columns
    for col in num_cols:
        df[col] = pd.to_numeric(df[col], errors='coerce')

    # Garante que os dados estejam ordenados por tempo para o preenchimento funcionar
    df = df.sort_values(by=['data','hora'], ascending=True)
    
    null_counts_dict = df.isna().sum().to_dict()
    filtered_null_counts_dict = {k: v for k, v in null_counts_dict.items() if v > 0}

    for col in filtered_null_counts_dict.keys():
        # 1. Preenche com o valor da hora anterior (até 4 horas de atraso)
        # O ffill (forward fill) propaga o último valor válido para o próximo
        df[col] = df[col].ffill(limit=4)
        
        mediana_24h = (
            df[col]
            .rolling(window=24, min_periods=1)
            .median()
            .shift(1)
        )
        
        # Preenche os nulos restantes com a média calculada
        df[col] = df[col].fillna(mediana_24h)
        
    return df


def shift_ultima_hora(df):
    for col in df.columns:
        if 'UltimaHora' in col:
            df[col] = df[col].shift(-1)
    return df