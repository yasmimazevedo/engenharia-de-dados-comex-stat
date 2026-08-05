# 01 — Resumo geral

## Objetivo

Comparar o desempenho agregado das exportações e importações de Minas Gerais no primeiro semestre de 2024, 2025 e 2026.

Consulta relacionada:

[`sql/queries/01_resumo_anual.sql`](../../sql/queries/01_resumo_anual.sql)

## Resultados consolidados

| Fluxo | Ano | Registros | Valor FOB (USD) | Peso líquido (kg) | FOB médio por kg (USD) |
|---|---:|---:|---:|---:|---:|
| Exportação | 2024 | 38.523 | 20.911.352.174 | 99.649.819.621 | 0,2098 |
| Exportação | 2025 | 40.949 | 21.968.821.625 | 96.114.357.063 | 0,2286 |
| Exportação | 2026 | 40.884 | 21.920.923.140 | 91.660.659.745 | 0,2392 |
| Importação | 2024 | 95.144 | 7.529.883.730 | 6.047.223.169 | 1,2452 |
| Importação | 2025 | 103.594 | 8.603.498.628 | 6.572.579.902 | 1,3090 |
| Importação | 2026 | 115.743 | 9.641.041.374 | 6.420.656.814 | 1,5016 |

## Saldo comercial FOB

| Ano | Exportações (USD) | Importações (USD) | Saldo FOB (USD) |
|---:|---:|---:|---:|
| 2024 | 20.911.352.174 | 7.529.883.730 | 13.381.468.444 |
| 2025 | 21.968.821.625 | 8.603.498.628 | 13.365.322.997 |
| 2026 | 21.920.923.140 | 9.641.041.374 | 12.279.881.766 |

## Variações anuais

### Exportações

- 2025 contra 2024: valor FOB cresceu **5,06%**.
- 2025 contra 2024: peso líquido caiu **3,55%**.
- 2026 contra 2025: valor FOB caiu **0,22%**.
- 2026 contra 2025: peso líquido caiu **4,63%**.

### Importações

- 2025 contra 2024: valor FOB cresceu **14,26%**.
- 2025 contra 2024: peso líquido cresceu **8,69%**.
- 2026 contra 2025: valor FOB cresceu **12,06%**.
- 2026 contra 2025: peso líquido caiu **2,31%**.

## Principais interpretações

### Superávit permanece positivo

Minas Gerais apresentou saldo FOB positivo nos três períodos. Entretanto, o superávit caiu de aproximadamente US$ 13,38 bilhões em 2024 para US$ 12,28 bilhões em 2026.

A redução ocorreu principalmente porque as importações cresceram mais rapidamente do que as exportações.

### Exportações com menor peso e maior valor médio

O peso líquido exportado diminuiu nos dois intervalos anuais, enquanto o valor FOB médio por quilograma aumentou de US$ 0,2098 para US$ 0,2392.

Isso indica que o valor exportado foi sustentado mesmo com redução do volume físico agregado. O resultado pode refletir mudanças de preços, composição da pauta ou participação de mercadorias de maior valor por peso.

### Importações com aumento do valor por quilograma

O valor médio FOB por quilograma das importações aumentou de US$ 1,2452 em 2024 para US$ 1,5016 em 2026.

Em 2026, o valor importado cresceu, apesar da redução do peso líquido em relação a 2025. Esse comportamento sugere aumento do valor unitário agregado ou mudança na composição das mercadorias importadas.

## Cuidados metodológicos

O valor médio por quilograma foi calculado como:

```text
soma do valor FOB / soma do peso líquido
```

Não foi utilizada a média simples do valor por quilograma de cada linha.

Os resultados representam somente janeiro a junho de cada ano.
