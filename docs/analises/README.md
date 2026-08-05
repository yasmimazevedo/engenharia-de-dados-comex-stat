# Análises — Comércio Exterior de Minas Gerais

Esta pasta reúne a interpretação dos resultados produzidos pelas consultas SQL do projeto.

## Escopo

- Unidade federativa: Minas Gerais
- Período: janeiro a junho de 2024, 2025 e 2026
- Fluxos: exportação e importação
- Fonte: arquivos públicos do Comex Stat
- Moeda: dólar dos Estados Unidos
- Classificação de produtos: NCM e Sistema Harmonizado

## Documentos

| Documento | Tema | Consulta relacionada |
|---|---|---|
| [01 — Resumo geral](01_resumo_geral.md) | Exportações, importações, saldo e valor médio | [`01_resumo_anual.sql`](../../sql/queries/01_resumo_anual.sql) |
| [02 — Evolução mensal](02_evolucao_mensal.md) | Comportamento mensal dos fluxos | [`02_evolucao_mensal.sql`](../../sql/queries/02_evolucao_mensal.sql) |
| [03 — Produtos](03_produtos.md) | Produtos exportados e importados | [`03_analise_produtos.sql`](../../sql/queries/03_analise_produtos.sql) |
| [04 — Países](04_paises.md) | Destinos e origens do comércio exterior | [`04_analise_paises.sql`](../../sql/queries/04_analise_paises.sql) |
| [05 — Produto × país](05_produto_pais.md) | Combinações entre mercadorias e parceiros | [`05_analise_produto_pais.sql`](../../sql/queries/05_analise_produto_pais.sql) |
| [06 — Logística](06_logistica.md) | Vias de transporte e unidades da Receita Federal | [`06_analise_vias_urf.sql`](../../sql/queries/06_analise_vias_urf.sql) |
| [07 — Custos de importação](07_custos_importacao.md) | Frete, seguro, CIF e custo logístico | [`07_analise_custos_importacao.sql`](../../sql/queries/07_analise_custos_importacao.sql) |

## Como interpretar os resultados

As comparações usam sempre o mesmo intervalo de meses. Dessa forma, janeiro a junho de cada ano é comparado com janeiro a junho dos demais anos.

Os resultados descrevem associações observadas nos dados. Eles não demonstram, isoladamente, causalidade econômica.

Os rankings detalhados devem ser reproduzidos pelas consultas SQL correspondentes. Esta documentação registra os principais achados e as regras de interpretação.
