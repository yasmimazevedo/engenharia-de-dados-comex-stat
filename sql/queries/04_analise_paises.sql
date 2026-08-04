\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - PRINCIPAIS PAISES POR FLUXO E ANO
\echo ============================================================

WITH resumo_paises AS (
    SELECT
        fato.fluxo,
        fato.ano,

        pais.codigo_pais,
        pais.nome_pais,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_pais AS pais
        ON pais.codigo_pais
            = fato.codigo_pais

    GROUP BY
        fato.fluxo,
        fato.ano,
        pais.codigo_pais,
        pais.nome_pais
),

classificacao AS (
    SELECT
        fluxo,
        ano,
        codigo_pais,
        nome_pais,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                ano
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_paises
)

SELECT
    fluxo,
    ano,
    posicao,
    codigo_pais,
    nome_pais,
    valor_fob_total_usd,
    peso_liquido_total_kg,

    ROUND(
        valor_fob_total_usd::NUMERIC
        /
        NULLIF(
            peso_liquido_total_kg,
            0
        ),
        4
    ) AS valor_medio_usd_kg

FROM classificacao

WHERE posicao <= 10

ORDER BY
    fluxo,
    ano,
    posicao;


\echo
\echo ============================================================
\echo ANALISE 2 - PARTICIPACAO DOS PRINCIPAIS PAISES EM 2026
\echo ============================================================

WITH resumo_paises AS (
    SELECT
        fato.fluxo,

        pais.codigo_pais,
        pais.nome_pais,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_pais AS pais
        ON pais.codigo_pais
            = fato.codigo_pais

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        pais.codigo_pais,
        pais.nome_pais
),

classificacao AS (
    SELECT
        fluxo,
        codigo_pais,
        nome_pais,
        valor_fob_total_usd,

        SUM(
            valor_fob_total_usd
        ) OVER (
            PARTITION BY fluxo
        ) AS valor_total_fluxo_usd,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_paises
)

SELECT
    fluxo,
    posicao,
    codigo_pais,
    nome_pais,
    valor_fob_total_usd,

    ROUND(
        valor_fob_total_usd::NUMERIC
        /
        NULLIF(
            valor_total_fluxo_usd,
            0
        )
        * 100,
        2
    ) AS participacao_percentual

FROM classificacao

WHERE posicao <= 10

ORDER BY
    fluxo,
    posicao;


\echo
\echo ============================================================
\echo ANALISE 3 - PAISES QUE MAIS CONTRIBUIRAM PARA O CRESCIMENTO
\echo COMPARACAO ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao_paises AS (
    SELECT
        fluxo,
        codigo_pais,

        SUM(
            CASE
                WHEN ano = 2025
                    THEN valor_fob_usd
                ELSE 0
            END
        ) AS valor_2025_usd,

        SUM(
            CASE
                WHEN ano = 2026
                    THEN valor_fob_usd
                ELSE 0
            END
        ) AS valor_2026_usd

    FROM comex.fato_comex

    WHERE ano IN (
        2025,
        2026
    )

    GROUP BY
        fluxo,
        codigo_pais
),

variacoes AS (
    SELECT
        fluxo,
        codigo_pais,
        valor_2025_usd,
        valor_2026_usd,

        (
            valor_2026_usd
            - valor_2025_usd
        ) AS variacao_absoluta_usd,

        ROUND(
            (
                valor_2026_usd::NUMERIC
                /
                NULLIF(
                    valor_2025_usd,
                    0
                )
                - 1
            ) * 100,
            2
        ) AS variacao_percentual

    FROM comparacao_paises
),

classificacao AS (
    SELECT
        fluxo,
        codigo_pais,
        valor_2025_usd,
        valor_2026_usd,
        variacao_absoluta_usd,
        variacao_percentual,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                variacao_absoluta_usd DESC
        ) AS posicao

    FROM variacoes
)

SELECT
    classificacao.fluxo,
    classificacao.posicao,

    pais.codigo_pais,
    pais.nome_pais,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,
    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_pais AS pais
    ON pais.codigo_pais
        = classificacao.codigo_pais

WHERE classificacao.posicao <= 10

ORDER BY
    classificacao.fluxo,
    classificacao.posicao;


\echo
\echo ============================================================
\echo ANALISE 4 - PAISES QUE MAIS CONTRIBUIRAM PARA A QUEDA
\echo COMPARACAO ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao_paises AS (
    SELECT
        fluxo,
        codigo_pais,

        SUM(
            CASE
                WHEN ano = 2025
                    THEN valor_fob_usd
                ELSE 0
            END
        ) AS valor_2025_usd,

        SUM(
            CASE
                WHEN ano = 2026
                    THEN valor_fob_usd
                ELSE 0
            END
        ) AS valor_2026_usd

    FROM comex.fato_comex

    WHERE ano IN (
        2025,
        2026
    )

    GROUP BY
        fluxo,
        codigo_pais
),

variacoes AS (
    SELECT
        fluxo,
        codigo_pais,
        valor_2025_usd,
        valor_2026_usd,

        (
            valor_2026_usd
            - valor_2025_usd
        ) AS variacao_absoluta_usd,

        ROUND(
            (
                valor_2026_usd::NUMERIC
                /
                NULLIF(
                    valor_2025_usd,
                    0
                )
                - 1
            ) * 100,
            2
        ) AS variacao_percentual

    FROM comparacao_paises
),

classificacao AS (
    SELECT
        fluxo,
        codigo_pais,
        valor_2025_usd,
        valor_2026_usd,
        variacao_absoluta_usd,
        variacao_percentual,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                variacao_absoluta_usd ASC
        ) AS posicao

    FROM variacoes
)

SELECT
    classificacao.fluxo,
    classificacao.posicao,

    pais.codigo_pais,
    pais.nome_pais,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,
    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_pais AS pais
    ON pais.codigo_pais
        = classificacao.codigo_pais

WHERE classificacao.posicao <= 10

ORDER BY
    classificacao.fluxo,
    classificacao.posicao;


\echo
\echo ============================================================
\echo ANALISE 5 - CONCENTRACAO NOS DEZ PRINCIPAIS PAISES
\echo ============================================================

WITH resumo_paises AS (
    SELECT
        fluxo,
        ano,
        codigo_pais,

        SUM(
            valor_fob_usd
        ) AS valor_fob_total_usd

    FROM comex.fato_comex

    GROUP BY
        fluxo,
        ano,
        codigo_pais
),

classificacao AS (
    SELECT
        fluxo,
        ano,
        codigo_pais,
        valor_fob_total_usd,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                ano
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_paises
)

SELECT
    fluxo,
    ano,

    SUM(
        valor_fob_total_usd
    ) AS valor_fob_total_usd,

    SUM(
        valor_fob_total_usd
    ) FILTER (
        WHERE posicao <= 10
    ) AS valor_top_10_paises_usd,

    ROUND(
        (
            SUM(
                valor_fob_total_usd
            ) FILTER (
                WHERE posicao <= 10
            )
        )::NUMERIC
        /
        NULLIF(
            SUM(
                valor_fob_total_usd
            ),
            0
        )
        * 100,
        2
    ) AS participacao_top_10_percentual

FROM classificacao

GROUP BY
    fluxo,
    ano

ORDER BY
    fluxo,
    ano;


\echo
\echo ============================================================
\echo ANALISE DE PAISES FINALIZADA
\echo ============================================================