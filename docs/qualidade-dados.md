# Qualidade dos dados

## Objetivo

As validações foram implementadas para garantir que o recorte analítico seja consistente antes da carga no PostgreSQL e do consumo pelo Power BI.

## Validações da camada interim

Foram verificados:

- fluxo e ano do arquivo;
- unidade federativa;
- intervalo de meses;
- presença das colunas obrigatórias;
- conversão dos campos numéricos;
- ausência de valores negativos indevidos;
- total de linhas;
- total de valor FOB;
- total de peso líquido.

## Totais aprovados

| Fluxo | Ano | Linhas | Valor FOB (USD) | Peso líquido (kg) |
|---|---:|---:|---:|---:|
| Exportação | 2024 | 38.523 | 20.911.352.174 | 99.649.819.621 |
| Importação | 2024 | 95.144 | 7.529.883.730 | 6.047.223.169 |
| Exportação | 2025 | 40.949 | 21.968.821.625 | 96.114.357.063 |
| Importação | 2025 | 103.594 | 8.603.498.628 | 6.572.579.902 |
| Exportação | 2026 | 40.884 | 21.920.923.140 | 91.660.659.745 |
| Importação | 2026 | 115.743 | 9.641.041.374 | 6.420.656.814 |

## Cobertura das dimensões

A validação de chaves analisou 434.837 linhas e não encontrou códigos sem correspondência nas dimensões.

```text
Total de correspondências ausentes: 0
```

## Hierarquia de produtos

Cinco NCMs do arquivo de referência estavam sem correspondência completa na hierarquia SH:

```text
38273900
81093900
81126100
85492100
97053100
```

Nenhum desses produtos apareceu no recorte analisado. Portanto, o conjunto final não teve linhas afetadas.

## Validação após carga

A carga no PostgreSQL foi validada comparando:

- quantidade de registros;
- soma do valor FOB;
- soma do peso líquido;
- fluxo;
- ano.

Todos os seis grupos de fluxo e ano foram aprovados.

## Validação da camada BI

As views do schema `bi` preservaram os totais da tabela fato:

| Fluxo | Ano | Registros | FOB (USD) |
|---|---:|---:|---:|
| Exportação | 2024 | 38.523 | 20.911.352.174 |
| Exportação | 2025 | 40.949 | 21.968.821.625 |
| Exportação | 2026 | 40.884 | 21.920.923.140 |
| Importação | 2024 | 95.144 | 7.529.883.730 |
| Importação | 2025 | 103.594 | 8.603.498.628 |
| Importação | 2026 | 115.743 | 9.641.041.374 |

## Regras importantes

- códigos permanecem como texto;
- zeros à esquerda devem ser preservados;
- `null` em frete, seguro e CIF nas exportações é esperado;
- custo logístico de exportação não deve ser interpretado como dado observado;
- valor médio por quilograma deve ser calculado como soma do FOB dividida pela soma do peso, e não como média simples das linhas.
