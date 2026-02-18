from unidecode import unidecode

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