# 05 — Análise produto × país

## Objetivo

Analisar quais produtos são comercializados com cada parceiro e identificar combinações relevantes entre mercadoria e país.

Consulta relacionada:

[`sql/queries/05_analise_produto_pais.sql`](../../sql/queries/05_analise_produto_pais.sql)

## Por que cruzar produto e país

Uma análise apenas por produto mostra o que Minas Gerais comercializa. Uma análise apenas por país mostra com quem o estado comercializa.

O cruzamento produto × país responde:

- quais produtos explicam a relevância de cada parceiro;
- quais mercados concentram as vendas de determinados produtos;
- quais países fornecem mercadorias específicas;
- como mudanças em um produto afetam a relação com um parceiro.

## Indicadores

- valor FOB da combinação;
- peso líquido;
- participação do produto dentro do país;
- participação do país dentro do produto;
- valor médio por quilograma;
- evolução anual.

## Interpretação

Combinações com grande valor FOB podem resultar de:

- alto volume físico;
- preço elevado;
- concentração de embarques;
- participação de produtos de alto valor por peso.

Por exemplo, produtos minerais, agrícolas e metais preciosos devem ser comparados com cautela, pois possuem características físicas e econômicas muito diferentes.

## Concentração

A análise permite calcular duas formas de concentração:

### Concentração do produto por país

Mostra quanto das exportações ou importações de determinado produto depende de um parceiro.

### Concentração do país por produto

Mostra quanto da relação comercial com determinado país depende de um grupo pequeno de produtos.

Essas duas perspectivas não são equivalentes.

## Perguntas respondidas

- Qual produto mais contribui para o comércio com cada parceiro?
- Quais países concentram a demanda de um produto?
- Quais combinações cresceram ou perderam participação?
- Há parceiros com pauta mais diversificada?
- O aumento do valor por quilograma está associado a produtos e países específicos?

## Uso no Power BI

Visuais recomendados:

- matriz com país nas linhas e produto nas colunas;
- tabela detalhada com formatação condicional;
- árvore de decomposição;
- barras com hierarquia país → produto;
- filtros por fluxo, ano, NCM e nível SH.

## Observação

Os rankings exatos devem ser extraídos da consulta SQL. O documento evita registrar combinações sem os resultados completos e validados.
