# Pipeline ETL

## Escopo

O pipeline processa exportações e importações de Minas Gerais nos meses de janeiro a junho dos anos de 2024, 2025 e 2026.

## 1. Extração

Script principal:

```text
src/ingestion/download_comex.py
```

### Origem

Os arquivos são obtidos do repositório público de dados do Comex Stat.

Padrões utilizados:

```text
EXP_<ANO>.csv
IMP_<ANO>.csv
```

### Destinos

```text
data/raw/exportacao/
data/raw/importacao/
```

### Controles implementados

- consulta ao tamanho esperado no servidor;
- arquivo temporário com extensão `.part`;
- retomada por intervalo de bytes;
- múltiplas tentativas;
- espera entre tentativas;
- validação do tamanho final;
- preservação dos dados já recebidos em caso de falha.

A retomada foi importante para tratar interrupções como `ChunkedEncodingError` e reinicializações de conexão.

## 2. Transformação do recorte

Script:

```text
src/transformation/filter_comex_mg.py
```

### Regras

- filtrar a unidade federativa `MG`;
- manter somente os meses de 1 a 6;
- preservar exportações e importações em diretórios separados;
- processar os arquivos em chunks;
- detectar a codificação dos CSVs;
- padronizar os campos necessários ao modelo;
- contabilizar linhas lidas, mantidas e inválidas.

### Saídas

```text
data/interim/exportacao_mg/EXP_MG_<ANO>_01_06.csv
data/interim/importacao_mg/IMP_MG_<ANO>_01_06.csv
```

## 3. Validação da camada interim

Script:

```text
src/validation/validate_interim.py
```

### Verificações

- existência das colunas obrigatórias;
- ano e fluxo esperados;
- presença apenas de Minas Gerais;
- meses limitados ao intervalo de 1 a 6;
- tipos numéricos válidos;
- valores não negativos para medidas;
- total de linhas;
- total de valor FOB;
- total de peso líquido.

## 4. Construção das dimensões

Script:

```text
src/transformation/build_dimensions.py
```

### Arquivos de referência

```text
NCM.csv
NCM_SH.csv
NCM_UNIDADE.csv
PAIS.csv
VIA.csv
URF.csv
```

### Dimensões geradas

```text
dim_produto.csv
dim_pais.csv
dim_via.csv
dim_urf.csv
dim_unidade.csv
dim_tempo.csv
```

## 5. Validação da cobertura dimensional

Script:

```text
src/validation/validate_dimensions.py
```

O script verifica se todos os códigos usados nos arquivos da camada interim possuem correspondência nas dimensões.

O resultado final registrou:

```text
Total de linhas analisadas: 434.837
Total de correspondências ausentes: 0
```

## 6. Produtos sem hierarquia SH

Script:

```text
src/validation/check_products_without_hierarchy.py
```

Cinco NCMs do cadastro de referência não possuíam a hierarquia SH completa. A análise confirmou que nenhum deles aparece no recorte de Minas Gerais, portanto não houve impacto nas linhas processadas.

## 7. Construção da tabela fato

Script:

```text
src/transformation/build_fact_comex.py
```

Saída:

```text
data/processed/fato_comex/fato_comex.csv
```

Resultado:

```text
434.837 linhas
aproximadamente 38,46 MB
```

## Ordem recomendada

```powershell
python .\src\ingestion\download_comex.py
python .\src\transformation\filter_comex_mg.py
python .\src\validation\validate_interim.py
python .\src\transformation\build_dimensions.py
python .\src\validation\validate_dimensions.py
python .\src\validation\check_products_without_hierarchy.py
python .\src\transformation\build_fact_comex.py
```
