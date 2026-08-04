\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - VERIFICACAO GERAL DOS DADOS
\echo ============================================================

SELECT
    COUNT(*) AS total_linhas,

    COUNT(
        DISTINCT codigo_ncm
    ) AS produtos_distintos,

    COUNT(
        DISTINCT codigo_pais
    ) AS paises_distintos,

    COUNT(
        DISTINCT codigo_via
    ) AS vias_distintas,

    MIN(
        data_referencia
    ) AS primeira_data,

    MAX(
        data_referencia
    ) AS ultima_data

FROM comex.fato_comex;


\echo
\echo ============================================================
\echo ANALISE 2 - RESUMO POR FLUXO E ANO
\echo ============================================================

SELECT
    fluxo,
    ano,

    COUNT(*) AS quantidade_registros,

    SUM(
        valor_fob_usd
    ) AS valor_fob_total_usd,

    SUM(
        peso_liquido_kg
    ) AS peso_liquido_total_kg,

    ROUND(
        SUM(
            valor_fob_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                peso_liquido_kg
            ),
            0
        ),
        4
    ) AS valor_medio_usd_kg

FROM comex.fato_comex

GROUP BY
    fluxo,
    ano

ORDER BY
    ano,
    fluxo;


\echo
\echo ============================================================
\echo ANALISE 3 - SALDO ENTRE EXPORTACOES E IMPORTACOES
\echo ============================================================

SELECT
    ano,

    SUM(
        CASE
            WHEN fluxo = 'EXPORTACAO'
                THEN valor_fob_usd
            ELSE 0
        END
    ) AS exportacoes_usd,

    SUM(
        CASE
            WHEN fluxo = 'IMPORTACAO'
                THEN valor_fob_usd
            ELSE 0
        END
    ) AS importacoes_usd,

    SUM(
        CASE
            WHEN fluxo = 'EXPORTACAO'
                THEN valor_fob_usd
            ELSE -valor_fob_usd
        END
    ) AS saldo_usd

FROM comex.fato_comex

GROUP BY
    ano

ORDER BY
    ano;


\echo
\echo ============================================================
\echo ANALISE 4 - VARIACAO EM RELACAO AO ANO ANTERIOR
\echo ============================================================

WITH resumo_anual AS (
    SELECT
        fluxo,
        ano,

        SUM(
            valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex

    GROUP BY
        fluxo,
        ano
),

comparacao AS (
    SELECT
        fluxo,
        ano,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        LAG(
            valor_fob_total_usd
        ) OVER (
            PARTITION BY fluxo
            ORDER BY ano
        ) AS valor_fob_ano_anterior,

        LAG(
            peso_liquido_total_kg
        ) OVER (
            PARTITION BY fluxo
            ORDER BY ano
        ) AS peso_ano_anterior

    FROM resumo_anual
)

SELECT
    fluxo,
    ano,
    valor_fob_total_usd,

    ROUND(
        (
            valor_fob_total_usd::NUMERIC
            /
            NULLIF(
                valor_fob_ano_anterior,
                0
            )
            - 1
        ) * 100,
        2
    ) AS variacao_valor_fob_percentual,

    peso_liquido_total_kg,

    ROUND(
        (
            peso_liquido_total_kg::NUMERIC
            /
            NULLIF(
                peso_ano_anterior,
                0
            )
            - 1
        ) * 100,
        2
    ) AS variacao_peso_percentual

FROM comparacao

ORDER BY
    fluxo,
    ano;


\echo
\echo ============================================================
\echo ANALISE ANUAL FINALIZADA
\echo ============================================================