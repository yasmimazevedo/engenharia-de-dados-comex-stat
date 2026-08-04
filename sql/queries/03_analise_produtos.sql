\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - PRINCIPAIS GRUPOS SH4 POR FLUXO E ANO
\echo ============================================================

WITH resumo_produtos AS (
    SELECT
        fato.fluxo,
        fato.ano,

        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    GROUP BY
        fato.fluxo,
        fato.ano,
        produto.codigo_sh4,
        produto.descricao_sh4
),

classificacao AS (
    SELECT
        fluxo,
        ano,
        codigo_sh4,
        descricao_sh4,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                ano
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_produtos
)

SELECT
    fluxo,
    ano,
    posicao,
    codigo_sh4,
    descricao_sh4,
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
\echo ANALISE 2 - PRINCIPAIS NCM DE 2026
\echo ============================================================

WITH resumo_ncm AS (
    SELECT
        fato.fluxo,
        produto.codigo_ncm,
        produto.descricao_ncm,
        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        produto.codigo_ncm,
        produto.descricao_ncm,
        produto.codigo_sh4,
        produto.descricao_sh4
),

classificacao AS (
    SELECT
        fluxo,
        codigo_ncm,
        descricao_ncm,
        codigo_sh4,
        descricao_sh4,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_ncm
)

SELECT
    fluxo,
    posicao,
    codigo_ncm,
    descricao_ncm,
    codigo_sh4,
    descricao_sh4,
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
    posicao;


\echo
\echo ============================================================
\echo ANALISE 3 - PRODUTOS QUE MAIS CONTRIBUIRAM PARA O CRESCIMENTO
\echo COMPARACAO ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao_produtos AS (
    SELECT
        fluxo,
        codigo_ncm,

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
        codigo_ncm
),

variacoes AS (
    SELECT
        fluxo,
        codigo_ncm,
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

    FROM comparacao_produtos
),

classificacao AS (
    SELECT
        fluxo,
        codigo_ncm,
        valor_2025_usd,
        valor_2026_usd,
        variacao_absoluta_usd,
        variacao_percentual,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                variacao_absoluta_usd DESC
        ) AS posicao_crescimento

    FROM variacoes
)

SELECT
    classificacao.fluxo,
    classificacao.posicao_crescimento AS posicao,

    produto.codigo_ncm,
    produto.descricao_ncm,
    produto.codigo_sh4,
    produto.descricao_sh4,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,
    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_produto AS produto
    ON produto.codigo_ncm
        = classificacao.codigo_ncm

WHERE classificacao.posicao_crescimento <= 10

ORDER BY
    classificacao.fluxo,
    classificacao.posicao_crescimento;


\echo
\echo ============================================================
\echo ANALISE 4 - PRODUTOS QUE MAIS CONTRIBUIRAM PARA A QUEDA
\echo COMPARACAO ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao_produtos AS (
    SELECT
        fluxo,
        codigo_ncm,

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
        codigo_ncm
),

variacoes AS (
    SELECT
        fluxo,
        codigo_ncm,
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

    FROM comparacao_produtos
),

classificacao AS (
    SELECT
        fluxo,
        codigo_ncm,
        valor_2025_usd,
        valor_2026_usd,
        variacao_absoluta_usd,
        variacao_percentual,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                variacao_absoluta_usd ASC
        ) AS posicao_queda

    FROM variacoes
)

SELECT
    classificacao.fluxo,
    classificacao.posicao_queda AS posicao,

    produto.codigo_ncm,
    produto.descricao_ncm,
    produto.codigo_sh4,
    produto.descricao_sh4,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,
    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_produto AS produto
    ON produto.codigo_ncm
        = classificacao.codigo_ncm

WHERE classificacao.posicao_queda <= 10

ORDER BY
    classificacao.fluxo,
    classificacao.posicao_queda;


\echo
\echo ============================================================
\echo ANALISE 5 - CONCENTRACAO NOS DEZ PRINCIPAIS PRODUTOS
\echo ============================================================

WITH resumo_produtos AS (
    SELECT
        fluxo,
        ano,
        codigo_ncm,

        SUM(
            valor_fob_usd
        ) AS valor_fob_total_usd

    FROM comex.fato_comex

    GROUP BY
        fluxo,
        ano,
        codigo_ncm
),

classificacao AS (
    SELECT
        fluxo,
        ano,
        codigo_ncm,
        valor_fob_total_usd,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                ano
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_produtos
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
    ) AS valor_top_10_usd,

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
\echo ANALISE DE PRODUTOS FINALIZADA
\echo ============================================================