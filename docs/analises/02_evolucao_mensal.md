# 02 — Evolução mensal

## Objetivo

Analisar como os valores de exportação e importação se distribuem entre janeiro e junho e identificar oscilações dentro de cada primeiro semestre.

Consulta relacionada:

[`sql/queries/02_evolucao_mensal.sql`](../../sql/queries/02_evolucao_mensal.sql)

## Indicadores utilizados

- valor FOB mensal;
- peso líquido mensal;
- quantidade de registros;
- valor médio FOB por quilograma;
- saldo FOB mensal;
- variação em relação ao mês anterior, quando aplicável.

## Estrutura da análise

A consulta organiza os resultados por:

```text
fluxo
ano
mês
```

Essa estrutura permite comparar:

- janeiro de 2024 com janeiro de 2025 e janeiro de 2026;
- a trajetória de janeiro a junho dentro de cada ano;
- a diferença mensal entre exportações e importações.

## Interpretação recomendada

A análise mensal deve considerar que o comércio exterior pode apresentar concentração de embarques, sazonalidade de produtos, alterações de preços e mudanças no calendário operacional.

Uma alta ou queda em um único mês não deve ser interpretada isoladamente como tendência estrutural.

## Relação com os resultados anuais

Os totais mensais devem fechar exatamente os valores anuais documentados em [`01_resumo_geral.md`](01_resumo_geral.md).

Totais esperados:

| Ano | Exportações FOB (USD) | Importações FOB (USD) |
|---:|---:|---:|
| 2024 | 20.911.352.174 | 7.529.883.730 |
| 2025 | 21.968.821.625 | 8.603.498.628 |
| 2026 | 21.920.923.140 | 9.641.041.374 |

## Uso no Power BI

Visual recomendado:

- gráfico de linhas;
- eixo X: `ano_mes`;
- eixo Y: valor FOB;
- legenda: fluxo;
- filtros: ano e mês.

O campo `ano_mes` deve ser ordenado por `ordem_ano_mes`, evitando ordenação alfabética incorreta.

## Perguntas respondidas

- Em quais meses o valor FOB foi mais elevado?
- Exportações e importações seguiram o mesmo padrão mensal?
- O crescimento anual das importações foi distribuído ao longo dos meses ou concentrado?
- O saldo comercial apresentou deterioração em meses específicos?
- O valor médio por quilograma variou ao longo do semestre?

## Observação

Os valores mensais detalhados devem ser obtidos diretamente pela consulta SQL. Esta documentação não registra rankings mensais sem o resultado tabular completo, evitando preencher números não verificados.
