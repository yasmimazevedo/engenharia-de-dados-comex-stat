# 07 — Custos de importação

## Objetivo

Analisar frete, seguro, valor CIF e custo logístico das importações de Minas Gerais.

Consulta relacionada:

[`sql/queries/07_analise_custos_importacao.sql`](../../sql/queries/07_analise_custos_importacao.sql)

## Conceitos

### Valor FOB

Valor da mercadoria no ponto de embarque, sem incorporar frete e seguro internacional.

### Valor CIF

Valor composto por:

```text
FOB + frete + seguro
```

### Custo logístico de importação

Neste projeto:

```text
frete + seguro
```

Essa medida não representa o custo logístico total da empresa, pois não inclui tributos, armazenagem, transporte interno, despesas portuárias ou outros custos.

## Resultados

| Ano | FOB de importação (USD) | Custo logístico (USD) | CIF (USD) | Custo sobre FOB |
|---:|---:|---:|---:|---:|
| 2024 | 7.529.883.730 | 367.946.701 | 7.897.830.431 | 4,89% |
| 2025 | 8.603.498.628 | 426.138.588 | 9.029.637.216 | 4,95% |
| 2026 | 9.641.041.374 | 408.547.692 | 10.049.589.066 | 4,24% |

## Interpretação

### Crescimento do valor importado

O valor FOB das importações cresceu em 2025 e novamente em 2026.

### Custo logístico nominal

O custo de frete e seguro aumentou de aproximadamente US$ 367,95 milhões em 2024 para US$ 426,14 milhões em 2025.

Em 2026, caiu para aproximadamente US$ 408,55 milhões, apesar do crescimento do valor FOB importado.

### Redução proporcional em 2026

A relação entre custo logístico e FOB caiu para **4,24%** em 2026, depois de **4,95%** em 2025.

Isso significa que frete e seguro cresceram menos do que o valor das mercadorias, ou diminuíram em termos nominais no agregado. O dado não permite concluir, isoladamente, que houve ganho de eficiência operacional.

## Perguntas respondidas

- Quanto foi gasto com frete e seguro?
- Qual foi o valor CIF das importações?
- O custo logístico cresceu na mesma proporção do FOB?
- Quais produtos, países e vias concentram os maiores custos?
- A participação do custo logístico mudou entre os anos?

## Uso no Power BI

Indicadores recomendados:

- importações FOB;
- custo logístico;
- valor CIF;
- custo logístico sobre FOB.

Visuais recomendados:

- colunas por ano;
- linha do percentual sobre FOB;
- detalhamento por produto;
- detalhamento por país;
- detalhamento por via de transporte.

## Cuidados metodológicos

Frete, seguro e CIF são aplicáveis às importações. Nas exportações, esses campos permanecem nulos.

A porcentagem deve ser calculada com os totais agregados:

```text
soma de frete e seguro / soma do FOB de importação
```

Não deve ser usada a média simples das porcentagens de cada registro.
