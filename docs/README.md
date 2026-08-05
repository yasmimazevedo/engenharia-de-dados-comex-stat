# Documentação técnica — Comex Stat MG

Esta pasta reúne a documentação técnica do projeto de Engenharia de Dados desenvolvido para analisar o comércio exterior de Minas Gerais com dados públicos do Comex Stat.

## Documentos

| Documento | Conteúdo |
|---|---|
| [Arquitetura](arquitetura.md) | Visão geral da solução, camadas e fluxo dos dados |
| [Pipeline ETL](etl.md) | Extração, transformação, validações e geração das saídas |
| [Modelo dimensional](modelo-dimensional.md) | Tabela fato, dimensões, granularidade e relacionamentos |
| [Dicionário de dados](dicionario-de-dados.md) | Descrição das tabelas e colunas do modelo |
| [Qualidade dos dados](qualidade-dados.md) | Regras de validação e resultados obtidos |
| [Execução do projeto](execucao.md) | Ordem recomendada para executar o pipeline |
| [Power BI](powerbi.md) | Conexão, modelo, medidas e páginas do relatório |
| [Análises](analises/README.md) | Interpretação dos resultados produzidos pelas consultas SQL |

## Escopo analítico

- Unidade federativa: Minas Gerais (`MG`)
- Fluxos: exportação e importação
- Período comparado: janeiro a junho de 2024, 2025 e 2026
- Classificação de produtos: NCM e hierarquia do Sistema Harmonizado
- Indicadores principais: valor FOB, peso líquido, quantidade estatística, frete, seguro, valor CIF e custo logístico

## Fonte

Os dados são provenientes dos arquivos públicos anuais do Comex Stat, disponibilizados pelo Ministério do Desenvolvimento, Indústria, Comércio e Serviços.
