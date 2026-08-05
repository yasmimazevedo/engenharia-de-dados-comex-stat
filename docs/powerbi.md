# Power BI

## Fonte de dados

O relatório conecta-se ao PostgreSQL:

```text
Servidor: localhost:5432
Banco: comex_stat_mg
Schema de consumo: bi
```

O usuário do Power BI possui acesso somente leitura.

## Views importadas

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

## Modelo

A `fato_comex` é relacionada diretamente às sete dimensões.

Todos os relacionamentos são:

- ativos;
- um para muitos;
- com filtro em direção única;
- da dimensão para a fato.

Não deve existir relacionamento direto entre duas dimensões.

## Medidas principais

```DAX
Quantidade de Registros =
COUNTROWS(fato_comex)
```

```DAX
Valor FOB Total (USD) =
SUM(fato_comex[valor_fob_usd])
```

```DAX
Exportações FOB (USD) =
CALCULATE(
    [Valor FOB Total (USD)],
    dim_fluxo[fluxo] = "EXPORTACAO"
)
```

```DAX
Importações FOB (USD) =
CALCULATE(
    [Valor FOB Total (USD)],
    dim_fluxo[fluxo] = "IMPORTACAO"
)
```

```DAX
Saldo FOB (USD) =
[Exportações FOB (USD)]
-
[Importações FOB (USD)]
```

```DAX
Peso Líquido Total (kg) =
SUM(fato_comex[peso_liquido_kg])
```

```DAX
Valor Médio FOB por kg (USD) =
DIVIDE(
    [Valor FOB Total (USD)],
    [Peso Líquido Total (kg)]
)
```

```DAX
Custo Logístico Importação (USD) =
SUM(fato_comex[custo_logistico_importacao_usd])
```

```DAX
Valor CIF Importação (USD) =
SUM(fato_comex[valor_cif_usd])
```

```DAX
Custo Logístico sobre FOB (%) =
DIVIDE(
    [Custo Logístico Importação (USD)],
    [Importações FOB (USD)]
)
```

## Validação das medidas

Totais gerais esperados:

```text
Exportações: US$ 64.801.096.939
Importações: US$ 25.774.423.732
Saldo:       US$ 39.026.673.207
```

## Páginas do relatório

### Validação

Página técnica usada para conferir os totais anuais do modelo.

### Visão Geral

Status: em desenvolvimento.

Elementos definidos:

- filtro de ano;
- filtro de mês;
- cartão de exportações;
- cartão de importações;
- cartão de saldo;
- cartão de custo logístico;
- gráfico de evolução mensal;
- gráfico de comparação anual.

### Produtos

Planejada para apresentar:

- produtos mais exportados;
- produtos mais importados;
- participação no valor FOB;
- peso líquido;
- valor médio por quilograma;
- evolução dos principais produtos.

### Países e Parceiros

Planejada para apresentar:

- principais destinos das exportações;
- principais origens das importações;
- participação por país;
- evolução dos parceiros comerciais.

### Produto por País

Planejada para analisar combinações entre produtos e parceiros.

### Logística e Custos

Planejada para apresentar:

- vias de transporte;
- unidades da Receita Federal;
- frete;
- seguro;
- valor CIF;
- custo logístico sobre FOB.

### Metodologia

Planejada para documentar:

- fonte dos dados;
- período;
- conceitos de FOB e CIF;
- regras de cálculo;
- arquitetura e qualidade dos dados.

## Formatação

Os valores monetários são exibidos em dólares americanos.

Formato sugerido:

```text
"US$ " #,##0
```

O valor médio por quilograma utiliza quatro casas decimais.

Os campos de frete, seguro e CIF permanecem nulos para exportações, pois não se aplicam a esse fluxo.
