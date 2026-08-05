# Execução do projeto

## Pré-requisitos

- Python com ambiente virtual;
- dependências do `requirements.txt`;
- PostgreSQL;
- cliente `psql`;
- Power BI Desktop;
- Git.

## 1. Preparar o ambiente Python

No PowerShell, a partir da raiz do projeto:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
```

## 2. Baixar os arquivos

O script deve ser configurado para o fluxo e ano desejados.

```powershell
python .\src\ingestion\download_comex.py
```

Arquivos utilizados no projeto:

```text
EXP_2024.csv
EXP_2025.csv
EXP_2026.csv
IMP_2024.csv
IMP_2025.csv
IMP_2026.csv
```

## 3. Transformar e validar

```powershell
python .\src\transformation\filter_comex_mg.py
python .\src\validation\validate_interim.py
python .\src\transformation\build_dimensions.py
python .\src\validation\validate_dimensions.py
python .\src\validation\check_products_without_hierarchy.py
python .\src\transformation\build_fact_comex.py
```

## 4. Criar o banco e o modelo

Os scripts DDL devem ser executados na ordem numérica.

```text
sql/ddl/01_create_database.sql
sql/ddl/02_create_schema.sql
sql/ddl/03_create_dimensions.sql
sql/ddl/04_create_fact.sql
sql/ddl/05_load_data.sql
sql/ddl/06_create_indexes.sql
```

Exemplo:

```powershell
psql -X -U postgres -h localhost -p 5432 -f .\sql\ddl\01_create_database.sql

psql -X -U postgres -h localhost -p 5432 -d comex_stat_mg `
    -f .\sql\ddl\02_create_schema.sql
```

Repita o comando para os demais arquivos, mantendo o banco `comex_stat_mg`.

Para solicitar a senha no terminal, adicione `-W`.

## 5. Criar as views para o Power BI

```powershell
psql -X -U postgres -h localhost -p 5432 -d comex_stat_mg -W `
    -f .\sql\views\01_create_powerbi_views.sql
```

Se necessário, aplique a correção de codificação da dimensão de fluxo:

```powershell
psql -X -U postgres -h localhost -p 5432 -d comex_stat_mg -W `
    -f .\sql\views\02_fix_dim_fluxo_encoding.sql
```

## 6. Criar o usuário de leitura

```powershell
psql -X -U postgres -h localhost -p 5432 -d comex_stat_mg -W `
    -f .\sql\security\01_create_powerbi_user.sql
```

Não armazene senhas reais no Git.

## 7. Executar as análises SQL

```text
sql/queries/01_resumo_anual.sql
sql/queries/02_evolucao_mensal.sql
sql/queries/03_analise_produtos.sql
sql/queries/04_analise_paises.sql
sql/queries/05_analise_produto_pais.sql
sql/queries/06_analise_vias_urf.sql
sql/queries/07_analise_custos_importacao.sql
```

Exemplo:

```powershell
psql -X -U postgres -h localhost -p 5432 -d comex_stat_mg -W `
    -f .\sql\queries\01_resumo_anual.sql
```

## 8. Abrir o Power BI

Arquivo:

```text
powerbi/comex_stat_mg_dashboard.pbix
```

Servidor:

```text
localhost:5432
```

Banco:

```text
comex_stat_mg
```

Utilize o usuário de leitura criado para o Power BI.

## 9. Versionar mudanças

```powershell
git status
git add .
git commit -m "docs: adiciona documentação técnica do projeto"
git push origin main
```
