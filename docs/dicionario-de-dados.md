# Dicionário de dados

Os tipos abaixo representam o tipo lógico esperado no modelo analítico.

## `comex.fato_comex`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `fluxo` | texto | `EXPORTACAO` ou `IMPORTACAO` |
| `data_referencia` | data | Primeiro dia do mês de referência |
| `ano` | inteiro | Ano da operação agregada |
| `mes` | inteiro | Número do mês |
| `codigo_ncm` | texto | Código NCM de oito dígitos |
| `codigo_unidade` | texto | Código da unidade estatística |
| `codigo_pais` | texto | Código do país parceiro |
| `sigla_uf` | texto | Unidade federativa; no recorte, `MG` |
| `codigo_via` | texto | Código da via de transporte |
| `codigo_urf` | texto | Código da unidade da Receita Federal |
| `quantidade_estatistica` | numérico | Quantidade na unidade estatística do produto |
| `peso_liquido_kg` | numérico | Peso líquido em quilogramas |
| `valor_fob_usd` | numérico | Valor FOB em dólares |
| `valor_frete_usd` | numérico, nulo | Frete das importações |
| `valor_seguro_usd` | numérico, nulo | Seguro das importações |
| `valor_cif_usd` | numérico, nulo | Valor CIF das importações |
| `arquivo_origem` | texto | Arquivo anual de origem |

## `comex.dim_produto`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `codigo_ncm` | texto | Chave da dimensão e código NCM |
| `descricao_ncm` | texto | Descrição da NCM em português |
| `codigo_sh6` | texto | Subposição do Sistema Harmonizado |
| `descricao_sh6` | texto | Descrição do SH6 |
| `codigo_sh4` | texto | Posição do Sistema Harmonizado |
| `descricao_sh4` | texto | Descrição do SH4 |
| `codigo_sh2` | texto | Capítulo do Sistema Harmonizado |
| `descricao_sh2` | texto | Descrição do SH2 |
| `codigo_secao` | texto | Código romano da seção |
| `descricao_secao` | texto | Descrição da seção |
| `codigo_unidade` | texto | Código da unidade estatística |
| `nome_unidade` | texto | Nome da unidade |
| `sigla_unidade` | texto | Sigla da unidade |

## `comex.dim_tempo`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `data_referencia` | data | Chave da dimensão |
| `ano` | inteiro | Ano |
| `mes` | inteiro | Número do mês |
| `nome_mes` | texto | Nome do mês em português |
| `trimestre` | inteiro | Trimestre |
| `semestre` | inteiro | Semestre |
| `ano_mes` | texto/data formatada | Identificação `AAAA-MM` |
| `ordem_ano_mes` | inteiro | Chave de ordenação cronológica `AAAAMM` |

## `comex.dim_pais`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `codigo_pais` | texto | Chave da dimensão |
| `codigo_iso_n3` | texto | Código ISO numérico |
| `codigo_iso_a3` | texto | Código ISO alfabético de três letras |
| `nome_pais` | texto | Nome do país em português |

## `comex.dim_via`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `codigo_via` | texto | Chave da dimensão |
| `nome_via` | texto | Descrição da via de transporte |

## `comex.dim_urf`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `codigo_urf` | texto | Chave da dimensão |
| `nome_urf` | texto | Nome da unidade da Receita Federal |

## `comex.dim_unidade`

| Coluna | Tipo lógico | Descrição |
|---|---|---|
| `codigo_unidade` | texto | Chave da dimensão |
| `nome_unidade` | texto | Nome da unidade estatística |
| `sigla_unidade` | texto | Sigla da unidade |

## Views do schema `bi`

O schema `bi` expõe:

```text
bi.fato_comex
bi.dim_tempo
bi.dim_produto
bi.dim_pais
bi.dim_via
bi.dim_urf
bi.dim_unidade
bi.dim_fluxo
```

A view `bi.fato_comex` também apresenta o campo calculado de custo logístico das importações, formado pela soma de frete e seguro.
