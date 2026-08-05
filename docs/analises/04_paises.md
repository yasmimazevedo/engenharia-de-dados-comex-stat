# 04 — Análise de países

## Objetivo

Identificar os principais parceiros comerciais de Minas Gerais, distinguindo destinos das exportações e origens das importações.

Consulta relacionada:

[`sql/queries/04_analise_paises.sql`](../../sql/queries/04_analise_paises.sql)

## Indicadores

- valor FOB;
- peso líquido;
- participação no fluxo;
- número de produtos comercializados;
- valor médio por quilograma;
- variação anual.

## Achados principais

As análises do projeto mostraram a relevância de grandes parceiros como:

- China;
- Estados Unidos.

A importância de cada país deve ser avaliada separadamente para exportações e importações. Um país pode ser um destino relevante para produtos minerais ou agrícolas e, ao mesmo tempo, ter papel diferente como fornecedor de mercadorias importadas.

## Concentração geográfica

A análise de participação permite verificar se o comércio exterior depende de poucos parceiros ou se está distribuído entre vários mercados.

Uma participação elevada de poucos países pode representar:

- especialização comercial;
- relacionamento consolidado;
- exposição a mudanças de demanda, preços, câmbio ou política comercial nesses mercados.

O dado permite identificar concentração, mas não comprova risco ou impacto causal sem outras fontes.

## Comparação por valor e peso

Países líderes em valor FOB podem não ser os líderes em peso líquido. Isso ocorre quando a pauta comercial contém mercadorias de maior valor por unidade de peso.

A comparação conjunta entre país, produto e via de transporte ajuda a explicar essas diferenças.

## Perguntas respondidas

- Quais são os principais destinos das exportações?
- Quais são as principais origens das importações?
- A participação dos maiores parceiros aumentou ou diminuiu?
- Quais países compram produtos de maior valor por quilograma?
- A pauta comercial com cada país é diversificada ou concentrada?

## Uso no Power BI

Visuais recomendados:

- barras horizontais dos principais países;
- mapa, desde que os códigos e nomes estejam corretamente georreferenciados;
- matriz país × ano;
- gráfico de participação;
- filtro por fluxo e produto.

## Cuidado metodológico

Durante o projeto foi discutida a possibilidade de atribuir alterações ao aumento de tarifas nos Estados Unidos. Essa narrativa não foi adotada como conclusão, pois os dados do projeto, isoladamente, não fornecem evidência suficiente de causalidade.

Os valores e rankings detalhados devem ser consultados no SQL correspondente.
