\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - EVOLUCAO MENSAL POR FLUXO
\echo ============================================================

SELECT
    fato.fluxo,
    tempo.ano,
    tempo.mes,
    tempo.nome_mes,
    tempo.ano_mes,

    COUNT(*) AS quantidade_registros,

    SUM(
        fato.valor_fob_usd
    ) AS valor_fob_total_usd,

    SUM(
        fato.peso_liquido_kg
    ) AS peso_liquido_total_kg,

    ROUND(
        SUM(
            fato.valor_fob_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                fato.peso_liquido_kg
            ),
            0
        ),
        4
    ) AS valor_medio_usd_kg

FROM comex.fato_comex AS fato

INNER JOIN comex.dim_tempo AS tempo
    ON tempo.data_referencia
        = fato.data_referencia

GROUP BY
    fato.fluxo,
    tempo.ano,
    tempo.mes,
    tempo.nome_mes,
    tempo.ano_mes,
    tempo.ordem_ano_mes

ORDER BY
    fato.fluxo,
    tempo.ordem_ano_mes;


\echo
\echo ============================================================
\echo ANALISE 2 - SALDO FOB MENSAL
\echo ============================================================

SELECT
    tempo.ano,
    tempo.mes,
    tempo.nome_mes,
    tempo.ano_mes,

    SUM(
        CASE
            WHEN fato.fluxo = 'EXPORTACAO'
                THEN fato.valor_fob_usd
            ELSE 0
        END
    ) AS exportacoes_usd,

    SUM(
        CASE
            WHEN fato.fluxo = 'IMPORTACAO'
                THEN fato.valor_fob_usd
            ELSE 0
        END
    ) AS importacoes_usd,

    SUM(
        CASE
            WHEN fato.fluxo = 'EXPORTACAO'
                THEN fato.valor_fob_usd
            ELSE -fato.valor_fob_usd
        END
    ) AS saldo_usd

FROM comex.fato_comex AS fato

INNER JOIN comex.dim_tempo AS tempo
    ON tempo.data_referencia
        = fato.data_referencia

GROUP BY
    tempo.ano,
    tempo.mes,
    tempo.nome_mes,
    tempo.ano_mes,
    tempo.ordem_ano_mes

ORDER BY
    tempo.ordem_ano_mes;


\echo
\echo ============================================================
\echo ANALISE 3 - COMPARACAO DO MESMO MES ENTRE ANOS
\echo ============================================================

WITH resumo_mensal AS (
    SELECT
        fluxo,
        ano,
        mes,

        SUM(
            valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex

    GROUP BY
        fluxo,
        ano,
        mes
),

comparacao AS (
    SELECT
        fluxo,
        ano,
        mes,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        LAG(
            valor_fob_total_usd
        ) OVER (
            PARTITION BY
                fluxo,
                mes
            ORDER BY
                ano
        ) AS valor_fob_ano_anterior,

        LAG(
            peso_liquido_total_kg
        ) OVER (
            PARTITION BY
                fluxo,
                mes
            ORDER BY
                ano
        ) AS peso_ano_anterior

    FROM resumo_mensal
)

SELECT
    comparacao.fluxo,
    comparacao.ano,
    comparacao.mes,
    tempo.nome_mes,

    comparacao.valor_fob_total_usd,

    ROUND(
        (
            comparacao.valor_fob_total_usd::NUMERIC
            /
            NULLIF(
                comparacao.valor_fob_ano_anterior,
                0
            )
            - 1
        ) * 100,
        2
    ) AS variacao_fob_percentual,

    comparacao.peso_liquido_total_kg,

    ROUND(
        (
            comparacao.peso_liquido_total_kg::NUMERIC
            /
            NULLIF(
                comparacao.peso_ano_anterior,
                0
            )
            - 1
        ) * 100,
        2
    ) AS variacao_peso_percentual

FROM comparacao

INNER JOIN comex.dim_tempo AS tempo
    ON tempo.ano = comparacao.ano
    AND tempo.mes = comparacao.mes

ORDER BY
    comparacao.fluxo,
    comparacao.mes,
    comparacao.ano;


\echo
\echo ============================================================
\echo ANALISE 4 - MAIOR E MENOR MES DE CADA FLUXO
\echo ============================================================

WITH resumo_mensal AS (
    SELECT
        fluxo,
        data_referencia,

        SUM(
            valor_fob_usd
        ) AS valor_fob_total_usd

    FROM comex.fato_comex

    GROUP BY
        fluxo,
        data_referencia
),

classificacao AS (
    SELECT
        fluxo,
        data_referencia,
        valor_fob_total_usd,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY valor_fob_total_usd DESC
        ) AS posicao_maior,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY valor_fob_total_usd ASC
        ) AS posicao_menor

    FROM resumo_mensal
)

SELECT
    classificacao.fluxo,

    CASE
        WHEN classificacao.posicao_maior = 1
            THEN 'MAIOR VALOR'
        WHEN classificacao.posicao_menor = 1
            THEN 'MENOR VALOR'
    END AS classificacao,

    classificacao.data_referencia,
    tempo.nome_mes,
    tempo.ano,

    classificacao.valor_fob_total_usd

FROM classificacao

INNER JOIN comex.dim_tempo AS tempo
    ON tempo.data_referencia
        = classificacao.data_referencia

WHERE
    classificacao.posicao_maior = 1
    OR classificacao.posicao_menor = 1

ORDER BY
    classificacao.fluxo,
    classificacao.valor_fob_total_usd DESC;


\echo
\echo ============================================================
\echo ANALISE MENSAL FINALIZADA
\echo ============================================================