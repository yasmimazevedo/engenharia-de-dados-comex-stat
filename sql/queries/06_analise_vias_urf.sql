\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - PRINCIPAIS VIAS POR FLUXO E ANO
\echo ============================================================

WITH resumo_vias AS (
    SELECT
        fato.fluxo,
        fato.ano,

        via.codigo_via,
        via.nome_via,

        COUNT(*) AS quantidade_registros,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_via AS via
        ON via.codigo_via
            = fato.codigo_via

    GROUP BY
        fato.fluxo,
        fato.ano,
        via.codigo_via,
        via.nome_via
),

classificacao AS (
    SELECT
        fluxo,
        ano,
        codigo_via,
        nome_via,
        quantidade_registros,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        SUM(
            valor_fob_total_usd
        ) OVER (
            PARTITION BY
                fluxo,
                ano
        ) AS valor_total_fluxo_usd,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                ano
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_vias
)

SELECT
    fluxo,
    ano,
    posicao,

    codigo_via,
    nome_via,

    quantidade_registros,
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
    ) AS valor_medio_usd_kg,

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
    ano,
    posicao;


\echo
\echo ============================================================
\echo ANALISE 2 - PRINCIPAIS URFS EM 2026
\echo ============================================================

WITH resumo_urfs AS (
    SELECT
        fato.fluxo,

        urf.codigo_urf,
        urf.nome_urf,

        COUNT(*) AS quantidade_registros,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_urf AS urf
        ON urf.codigo_urf
            = fato.codigo_urf

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        urf.codigo_urf,
        urf.nome_urf
),

classificacao AS (
    SELECT
        fluxo,
        codigo_urf,
        nome_urf,
        quantidade_registros,
        valor_fob_total_usd,
        peso_liquido_total_kg,

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

    FROM resumo_urfs
)

SELECT
    fluxo,
    posicao,

    codigo_urf,
    nome_urf,

    quantidade_registros,
    valor_fob_total_usd,
    peso_liquido_total_kg,

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

WHERE posicao <= 15

ORDER BY
    fluxo,
    posicao;


\echo
\echo ============================================================
\echo ANALISE 3 - PRINCIPAIS COMBINACOES PRODUTO E VIA EM 2026
\echo ============================================================

WITH resumo_produto_via AS (
    SELECT
        fato.fluxo,

        via.codigo_via,
        via.nome_via,

        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_via AS via
        ON via.codigo_via
            = fato.codigo_via

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        via.codigo_via,
        via.nome_via,
        produto.codigo_sh4,
        produto.descricao_sh4
),

classificacao AS (
    SELECT
        fluxo,
        codigo_via,
        nome_via,
        codigo_sh4,
        descricao_sh4,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_produto_via
)

SELECT
    fluxo,
    posicao,

    nome_via,

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

WHERE posicao <= 20

ORDER BY
    fluxo,
    posicao;


\echo
\echo ============================================================
\echo ANALISE 4 - PRINCIPAIS COMBINACOES PAIS E VIA EM 2026
\echo ============================================================

WITH resumo_pais_via AS (
    SELECT
        fato.fluxo,

        pais.codigo_pais,
        pais.nome_pais,

        via.codigo_via,
        via.nome_via,

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

    INNER JOIN comex.dim_via AS via
        ON via.codigo_via
            = fato.codigo_via

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        pais.codigo_pais,
        pais.nome_pais,
        via.codigo_via,
        via.nome_via
),

classificacao AS (
    SELECT
        fluxo,
        codigo_pais,
        nome_pais,
        codigo_via,
        nome_via,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_pais_via
)

SELECT
    fluxo,
    posicao,

    nome_pais,
    nome_via,

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

WHERE posicao <= 20

ORDER BY
    fluxo,
    posicao;


\echo
\echo ============================================================
\echo ANALISE 5 - VIAS QUE MAIS CRESCERAM ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao AS (
    SELECT
        fluxo,
        codigo_via,

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
        codigo_via
),

variacoes AS (
    SELECT
        fluxo,
        codigo_via,
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

    FROM comparacao
),

classificacao AS (
    SELECT
        fluxo,
        codigo_via,
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

    via.codigo_via,
    via.nome_via,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,
    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_via AS via
    ON via.codigo_via
        = classificacao.codigo_via

WHERE
    classificacao.posicao <= 10
    AND classificacao.variacao_absoluta_usd > 0

ORDER BY
    classificacao.fluxo,
    classificacao.posicao;


\echo
\echo ============================================================
\echo ANALISE 6 - VIAS QUE MAIS CAIRAM ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao AS (
    SELECT
        fluxo,
        codigo_via,

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
        codigo_via
),

variacoes AS (
    SELECT
        fluxo,
        codigo_via,
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

    FROM comparacao
),

classificacao AS (
    SELECT
        fluxo,
        codigo_via,
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

    via.codigo_via,
    via.nome_via,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,
    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_via AS via
    ON via.codigo_via
        = classificacao.codigo_via

WHERE
    classificacao.posicao <= 10
    AND classificacao.variacao_absoluta_usd < 0

ORDER BY
    classificacao.fluxo,
    classificacao.posicao;


\echo
\echo ============================================================
\echo ANALISE 7 - CONCENTRACAO NAS CINCO PRINCIPAIS URFS
\echo ============================================================

WITH resumo_urfs AS (
    SELECT
        fluxo,
        ano,
        codigo_urf,

        SUM(
            valor_fob_usd
        ) AS valor_fob_total_usd

    FROM comex.fato_comex

    GROUP BY
        fluxo,
        ano,
        codigo_urf
),

classificacao AS (
    SELECT
        fluxo,
        ano,
        codigo_urf,
        valor_fob_total_usd,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                ano
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_urfs
)

SELECT
    fluxo,
    ano,

    COUNT(*) AS quantidade_urfs_utilizadas,

    SUM(
        valor_fob_total_usd
    ) AS valor_fob_total_usd,

    SUM(
        valor_fob_total_usd
    ) FILTER (
        WHERE posicao <= 5
    ) AS valor_top_5_urfs_usd,

    ROUND(
        (
            SUM(
                valor_fob_total_usd
            ) FILTER (
                WHERE posicao <= 5
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
    ) AS participacao_top_5_percentual

FROM classificacao

GROUP BY
    fluxo,
    ano

ORDER BY
    fluxo,
    ano;


\echo
\echo ============================================================
\echo ANALISE DE VIAS E URFS FINALIZADA
\echo ============================================================