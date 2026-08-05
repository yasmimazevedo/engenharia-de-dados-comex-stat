# 03 — Análise de produtos

## Objetivo

Identificar os produtos com maior participação nas exportações e importações de Minas Gerais e avaliar valor, peso e valor médio por quilograma.

Consulta relacionada:

[`sql/queries/03_analise_produtos.sql`](../../sql/queries/03_analise_produtos.sql)

## Dimensão utilizada

A análise utiliza a `dim_produto`, que contém:

- código NCM;
- descrição da NCM;
- SH6;
- SH4;
- SH2;
- seção;
- unidade estatística.

## Indicadores

- valor FOB;
- peso líquido;
- quantidade estatística;
- participação no fluxo;
- valor médio FOB por quilograma;
- variação entre anos.

## Achados principais

As análises realizadas ao longo do projeto indicaram forte relevância de produtos tradicionais da pauta mineira, incluindo:

- minérios de ferro;
- café;
- soja;
- ouro.

Esses produtos possuem perfis diferentes. Minérios e produtos agrícolas tendem a apresentar grande peso físico, enquanto mercadorias como ouro podem apresentar valor elevado com peso relativamente baixo.

Por isso, rankings por valor FOB e por peso líquido não devem ser tratados como equivalentes.

## Valor por quilograma

O indicador FOB por quilograma ajuda a distinguir:

- produtos de grande volume e menor valor unitário;
- produtos de menor volume e maior valor unitário.

O aumento do valor médio agregado das exportações, acompanhado pela redução do peso total, reforça a importância de analisar a composição da pauta, e não apenas o total financeiro.

## Níveis de análise

### NCM

Maior detalhamento, com oito dígitos.

### SH6

Permite agrupar NCMs semelhantes em uma classificação internacional de seis dígitos.

### SH4 e SH2

Facilitam uma visão mais executiva por posição e capítulo.

## Perguntas respondidas

- Quais produtos geram maior valor FOB?
- Quais produtos concentram maior peso?
- Quais mercadorias possuem maior valor por quilograma?
- A pauta ficou mais ou menos concentrada?
- Quais produtos explicam a diferença entre crescimento do valor e queda do peso?
- Os principais produtos mantiveram posição entre 2024 e 2026?

## Uso no Power BI

Visuais recomendados:

- barras horizontais com os principais produtos por valor FOB;
- matriz com NCM, descrição, valor, peso e valor por kg;
- gráfico de participação;
- linha de evolução dos produtos selecionados;
- alternância entre exportação e importação.

## Cuidados

O valor por quilograma não deve ser usado como medida de rentabilidade.

A quantidade estatística utiliza unidades diferentes conforme o produto. Por isso, somar quantidades estatísticas de produtos com unidades distintas pode gerar interpretação incorreta.

Os rankings e participações exatos devem ser reproduzidos pela consulta SQL.
