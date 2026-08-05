# 06 — Análise logística

## Objetivo

Avaliar as vias de transporte e as unidades da Receita Federal associadas aos fluxos comerciais de Minas Gerais.

Consulta relacionada:

[`sql/queries/06_analise_vias_urf.sql`](../../sql/queries/06_analise_vias_urf.sql)

## Dimensões utilizadas

- `dim_via`;
- `dim_urf`;
- `dim_tempo`;
- `dim_fluxo`.

## Indicadores

- valor FOB;
- peso líquido;
- quantidade de registros;
- participação por via;
- participação por URF;
- valor médio por quilograma.

## Achados principais

### Predomínio da via marítima

A via marítima aparece como principal meio de transporte no comércio exterior analisado, especialmente em operações com grande volume físico.

Esse resultado é coerente com a presença de mercadorias minerais e agrícolas na pauta.

### Crescimento relativo da via aérea

A via aérea ganhou relevância no período analisado.

Esse movimento deve ser interpretado junto ao tipo de produto, pois o transporte aéreo tende a estar associado a mercadorias de menor peso e maior valor. O ouro foi identificado como exemplo importante dessa diferença de perfil.

### Unidade da Receita Federal de Santos

A URF de Santos apareceu como principal unidade associada ao valor movimentado no recorte.

A URF representa o local administrativo do despacho aduaneiro. Ela não deve ser interpretada automaticamente como origem ou destino físico final da mercadoria.

## Relação entre valor e peso

A participação de uma via pode ser muito diferente quando calculada por:

- valor FOB;
- peso líquido;
- quantidade de registros.

A via marítima pode dominar o peso, enquanto a via aérea pode apresentar participação proporcionalmente maior no valor.

## Perguntas respondidas

- Qual via concentra maior valor FOB?
- Qual via concentra maior peso?
- Quais vias ganharam participação?
- Quais URFs são mais relevantes?
- Produtos de alto valor por quilograma utilizam vias diferentes?
- A estrutura logística varia entre exportação e importação?

## Uso no Power BI

Visuais recomendados:

- barras por via de transporte;
- participação percentual por fluxo;
- matriz via × ano;
- ranking de URFs;
- gráfico de dispersão entre peso e valor;
- detalhamento por produto.

## Cuidados

A via de transporte e a URF não permitem reconstruir toda a rota logística.

Os dados não incluem, por si só, custos internos de transporte, tempo de trânsito ou origem municipal.
