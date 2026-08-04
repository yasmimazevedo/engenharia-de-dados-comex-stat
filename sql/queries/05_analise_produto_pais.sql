\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - PRINCIPAIS COMBINACOES PRODUTO E PAIS EM 2026
\echo ============================================================

WITH resumo_pares AS (
    SELECT
        fato.fluxo,

        pais.codigo_pais,
        pais.nome_pais,

        produto.codigo_sh4,
        produto.descricao_sh4,

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

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        pais.codigo_pais,
        pais.nome_pais,
        produto.codigo_sh4,
        produto.descricao_sh4
),

classificacao AS (
    SELECT
        fluxo,
        codigo_pais,
        nome_pais,
        codigo_sh4,
        descricao_sh4,
        valor_fob_total_usd,
        peso_liquido_total_kg,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                valor_fob_total_usd DESC
        ) AS posicao

    FROM resumo_pares
)

SELECT
    fluxo,
    posicao,

    nome_pais,

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
\echo ANALISE 2 - PRINCIPAIS PRODUTOS DOS CINCO MAIORES PAISES
\echo EM 2026
\echo ============================================================

WITH totais_paises AS (
    SELECT
        fluxo,
        codigo_pais,

        SUM(
            valor_fob_usd
        ) AS valor_total_pais_usd

    FROM comex.fato_comex

    WHERE ano = 2026

    GROUP BY
        fluxo,
        codigo_pais
),

paises_classificados AS (
    SELECT
        fluxo,
        codigo_pais,
        valor_total_pais_usd,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                valor_total_pais_usd DESC
        ) AS posicao_pais

    FROM totais_paises
),

resumo_produtos AS (
    SELECT
        fato.fluxo,
        fato.codigo_pais,

        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_produto_usd

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        fato.codigo_pais,
        produto.codigo_sh4,
        produto.descricao_sh4
),

produtos_classificados AS (
    SELECT
        resumo.fluxo,
        resumo.codigo_pais,
        resumo.codigo_sh4,
        resumo.descricao_sh4,
        resumo.valor_produto_usd,

        ROW_NUMBER() OVER (
            PARTITION BY
                resumo.fluxo,
                resumo.codigo_pais
            ORDER BY
                resumo.valor_produto_usd DESC
        ) AS posicao_produto

    FROM resumo_produtos AS resumo
)

SELECT
    paises_classificados.fluxo,

    paises_classificados.posicao_pais,

    pais.nome_pais,

    produtos_classificados.posicao_produto,

    produtos_classificados.codigo_sh4,
    produtos_classificados.descricao_sh4,

    produtos_classificados.valor_produto_usd,

    ROUND(
        produtos_classificados.valor_produto_usd::NUMERIC
        /
        NULLIF(
            paises_classificados.valor_total_pais_usd,
            0
        )
        * 100,
        2
    ) AS participacao_no_pais_percentual

FROM paises_classificados

INNER JOIN produtos_classificados
    ON produtos_classificados.fluxo
        = paises_classificados.fluxo
    AND produtos_classificados.codigo_pais
        = paises_classificados.codigo_pais

INNER JOIN comex.dim_pais AS pais
    ON pais.codigo_pais
        = paises_classificados.codigo_pais

WHERE
    paises_classificados.posicao_pais <= 5
    AND produtos_classificados.posicao_produto <= 5

ORDER BY
    paises_classificados.fluxo,
    paises_classificados.posicao_pais,
    produtos_classificados.posicao_produto;


\echo
\echo ============================================================
\echo ANALISE 3 - PRINCIPAIS PAISES DOS CINCO MAIORES PRODUTOS
\echo EM 2026
\echo ============================================================

WITH totais_produtos AS (
    SELECT
        fato.fluxo,
        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_total_produto_usd

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        produto.codigo_sh4,
        produto.descricao_sh4
),

produtos_classificados AS (
    SELECT
        fluxo,
        codigo_sh4,
        descricao_sh4,
        valor_total_produto_usd,

        ROW_NUMBER() OVER (
            PARTITION BY fluxo
            ORDER BY
                valor_total_produto_usd DESC
        ) AS posicao_produto

    FROM totais_produtos
),

resumo_paises AS (
    SELECT
        fato.fluxo,

        produto.codigo_sh4,

        pais.codigo_pais,
        pais.nome_pais,

        SUM(
            fato.valor_fob_usd
        ) AS valor_pais_usd

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    INNER JOIN comex.dim_pais AS pais
        ON pais.codigo_pais
            = fato.codigo_pais

    WHERE fato.ano = 2026

    GROUP BY
        fato.fluxo,
        produto.codigo_sh4,
        pais.codigo_pais,
        pais.nome_pais
),

paises_classificados AS (
    SELECT
        fluxo,
        codigo_sh4,
        codigo_pais,
        nome_pais,
        valor_pais_usd,

        ROW_NUMBER() OVER (
            PARTITION BY
                fluxo,
                codigo_sh4
            ORDER BY
                valor_pais_usd DESC
        ) AS posicao_pais

    FROM resumo_paises
)

SELECT
    produtos_classificados.fluxo,

    produtos_classificados.posicao_produto,

    produtos_classificados.codigo_sh4,
    produtos_classificados.descricao_sh4,

    paises_classificados.posicao_pais,
    paises_classificados.nome_pais,
    paises_classificados.valor_pais_usd,

    ROUND(
        paises_classificados.valor_pais_usd::NUMERIC
        /
        NULLIF(
            produtos_classificados.valor_total_produto_usd,
            0
        )
        * 100,
        2
    ) AS participacao_no_produto_percentual

FROM produtos_classificados

INNER JOIN paises_classificados
    ON paises_classificados.fluxo
        = produtos_classificados.fluxo
    AND paises_classificados.codigo_sh4
        = produtos_classificados.codigo_sh4

WHERE
    produtos_classificados.posicao_produto <= 5
    AND paises_classificados.posicao_pais <= 5

ORDER BY
    produtos_classificados.fluxo,
    produtos_classificados.posicao_produto,
    paises_classificados.posicao_pais;


\echo
\echo ============================================================
\echo ANALISE 4 - COMBINACOES PRODUTO E PAIS QUE MAIS CRESCERAM
\echo ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao AS (
    SELECT
        fato.fluxo,
        fato.codigo_pais,

        produto.codigo_sh4,

        SUM(
            CASE
                WHEN fato.ano = 2025
                    THEN fato.valor_fob_usd
                ELSE 0
            END
        ) AS valor_2025_usd,

        SUM(
            CASE
                WHEN fato.ano = 2026
                    THEN fato.valor_fob_usd
                ELSE 0
            END
        ) AS valor_2026_usd

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano IN (
        2025,
        2026
    )

    GROUP BY
        fato.fluxo,
        fato.codigo_pais,
        produto.codigo_sh4
),

variacoes AS (
    SELECT
        fluxo,
        codigo_pais,
        codigo_sh4,

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
        codigo_pais,
        codigo_sh4,
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

    pais.nome_pais,

    produto.codigo_sh4,
    produto.descricao_sh4,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,

    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_pais AS pais
    ON pais.codigo_pais
        = classificacao.codigo_pais

INNER JOIN (
    SELECT DISTINCT
        codigo_sh4,
        descricao_sh4
    FROM comex.dim_produto
) AS produto
    ON produto.codigo_sh4
        = classificacao.codigo_sh4

WHERE classificacao.posicao <= 15

ORDER BY
    classificacao.fluxo,
    classificacao.posicao;


\echo
\echo ============================================================
\echo ANALISE 5 - COMBINACOES PRODUTO E PAIS QUE MAIS CAIRAM
\echo ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao AS (
    SELECT
        fato.fluxo,
        fato.codigo_pais,

        produto.codigo_sh4,

        SUM(
            CASE
                WHEN fato.ano = 2025
                    THEN fato.valor_fob_usd
                ELSE 0
            END
        ) AS valor_2025_usd,

        SUM(
            CASE
                WHEN fato.ano = 2026
                    THEN fato.valor_fob_usd
                ELSE 0
            END
        ) AS valor_2026_usd

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE fato.ano IN (
        2025,
        2026
    )

    GROUP BY
        fato.fluxo,
        fato.codigo_pais,
        produto.codigo_sh4
),

variacoes AS (
    SELECT
        fluxo,
        codigo_pais,
        codigo_sh4,

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
        codigo_pais,
        codigo_sh4,
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

    pais.nome_pais,

    produto.codigo_sh4,
    produto.descricao_sh4,

    classificacao.valor_2025_usd,
    classificacao.valor_2026_usd,

    classificacao.variacao_absoluta_usd,
    classificacao.variacao_percentual

FROM classificacao

INNER JOIN comex.dim_pais AS pais
    ON pais.codigo_pais
        = classificacao.codigo_pais

INNER JOIN (
    SELECT DISTINCT
        codigo_sh4,
        descricao_sh4
    FROM comex.dim_produto
) AS produto
    ON produto.codigo_sh4
        = classificacao.codigo_sh4

WHERE classificacao.posicao <= 15

ORDER BY
    classificacao.fluxo,
    classificacao.posicao;


\echo
\echo ============================================================
\echo ANALISE PRODUTO E PAIS FINALIZADA
\echo ============================================================