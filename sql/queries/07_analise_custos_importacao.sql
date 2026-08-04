\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo ANALISE 1 - VALIDACAO DOS VALORES DE IMPORTACAO
\echo ============================================================

SELECT
    COUNT(*) AS total_registros_importacao,

    COUNT(*) FILTER (
        WHERE valor_frete_usd IS NULL
    ) AS registros_com_frete_nulo,

    COUNT(*) FILTER (
        WHERE valor_seguro_usd IS NULL
    ) AS registros_com_seguro_nulo,

    COUNT(*) FILTER (
        WHERE valor_cif_usd IS NULL
    ) AS registros_com_cif_nulo,

    COUNT(*) FILTER (
        WHERE valor_frete_usd < 0
           OR valor_seguro_usd < 0
           OR valor_cif_usd < 0
    ) AS registros_com_valor_negativo,

    COUNT(*) FILTER (
        WHERE valor_cif_usd
            <> valor_fob_usd
             + valor_frete_usd
             + valor_seguro_usd
    ) AS divergencias_formula_cif,

    COALESCE(
        SUM(
            valor_cif_usd
            - (
                valor_fob_usd
                + valor_frete_usd
                + valor_seguro_usd
            )
        ),
        0
    ) AS diferenca_total_usd

FROM comex.fato_comex

WHERE fluxo = 'IMPORTACAO';


\echo
\echo ============================================================
\echo ANALISE 2 - CUSTOS DE IMPORTACAO POR ANO
\echo ============================================================

SELECT
    ano,

    COUNT(*) AS quantidade_registros,

    SUM(
        valor_fob_usd
    ) AS valor_fob_total_usd,

    SUM(
        valor_frete_usd
    ) AS valor_frete_total_usd,

    SUM(
        valor_seguro_usd
    ) AS valor_seguro_total_usd,

    SUM(
        valor_frete_usd
        + valor_seguro_usd
    ) AS custo_logistico_total_usd,

    SUM(
        valor_cif_usd
    ) AS valor_cif_total_usd,

    ROUND(
        SUM(
            valor_frete_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                valor_fob_usd
            ),
            0
        )
        * 100,
        2
    ) AS frete_sobre_fob_percentual,

    ROUND(
        SUM(
            valor_seguro_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                valor_fob_usd
            ),
            0
        )
        * 100,
        4
    ) AS seguro_sobre_fob_percentual,

    ROUND(
        SUM(
            valor_frete_usd
            + valor_seguro_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                valor_fob_usd
            ),
            0
        )
        * 100,
        2
    ) AS acrescimo_cif_percentual,

    ROUND(
        SUM(
            valor_frete_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                peso_liquido_kg
            ),
            0
        ),
        4
    ) AS frete_medio_usd_kg

FROM comex.fato_comex

WHERE fluxo = 'IMPORTACAO'

GROUP BY
    ano

ORDER BY
    ano;


\echo
\echo ============================================================
\echo ANALISE 3 - EVOLUCAO MENSAL DOS CUSTOS DE IMPORTACAO
\echo ============================================================

SELECT
    tempo.ano,
    tempo.mes,
    tempo.nome_mes,
    tempo.ano_mes,

    SUM(
        fato.valor_fob_usd
    ) AS valor_fob_total_usd,

    SUM(
        fato.valor_frete_usd
    ) AS valor_frete_total_usd,

    SUM(
        fato.valor_seguro_usd
    ) AS valor_seguro_total_usd,

    SUM(
        fato.valor_frete_usd
        + fato.valor_seguro_usd
    ) AS custo_logistico_total_usd,

    SUM(
        fato.valor_cif_usd
    ) AS valor_cif_total_usd,

    ROUND(
        SUM(
            fato.valor_frete_usd
            + fato.valor_seguro_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                fato.valor_fob_usd
            ),
            0
        )
        * 100,
        2
    ) AS custo_sobre_fob_percentual,

    ROUND(
        SUM(
            fato.valor_frete_usd
        )::NUMERIC
        /
        NULLIF(
            SUM(
                fato.peso_liquido_kg
            ),
            0
        ),
        4
    ) AS frete_medio_usd_kg

FROM comex.fato_comex AS fato

INNER JOIN comex.dim_tempo AS tempo
    ON tempo.data_referencia
        = fato.data_referencia

WHERE fato.fluxo = 'IMPORTACAO'

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
\echo ANALISE 4 - CUSTOS POR VIA DE TRANSPORTE EM 2026
\echo ============================================================

WITH resumo_vias AS (
    SELECT
        via.codigo_via,
        via.nome_via,

        COUNT(*) AS quantidade_registros,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.valor_frete_usd
        ) AS valor_frete_total_usd,

        SUM(
            fato.valor_seguro_usd
        ) AS valor_seguro_total_usd,

        SUM(
            fato.valor_frete_usd
            + fato.valor_seguro_usd
        ) AS custo_logistico_total_usd,

        SUM(
            fato.valor_cif_usd
        ) AS valor_cif_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_via AS via
        ON via.codigo_via
            = fato.codigo_via

    WHERE
        fato.fluxo = 'IMPORTACAO'
        AND fato.ano = 2026

    GROUP BY
        via.codigo_via,
        via.nome_via
),

totais AS (
    SELECT
        SUM(
            valor_cif_total_usd
        ) AS valor_cif_geral_usd

    FROM resumo_vias
)

SELECT
    resumo.codigo_via,
    resumo.nome_via,
    resumo.quantidade_registros,

    resumo.valor_fob_total_usd,
    resumo.valor_frete_total_usd,
    resumo.valor_seguro_total_usd,
    resumo.custo_logistico_total_usd,
    resumo.valor_cif_total_usd,

    ROUND(
        resumo.custo_logistico_total_usd::NUMERIC
        /
        NULLIF(
            resumo.valor_fob_total_usd,
            0
        )
        * 100,
        2
    ) AS custo_sobre_fob_percentual,

    ROUND(
        resumo.valor_frete_total_usd::NUMERIC
        /
        NULLIF(
            resumo.peso_liquido_total_kg,
            0
        ),
        4
    ) AS frete_medio_usd_kg,

    ROUND(
        resumo.valor_cif_total_usd::NUMERIC
        /
        NULLIF(
            totais.valor_cif_geral_usd,
            0
        )
        * 100,
        2
    ) AS participacao_cif_percentual

FROM resumo_vias AS resumo

CROSS JOIN totais

ORDER BY
    resumo.valor_cif_total_usd DESC;


\echo
\echo ============================================================
\echo ANALISE 5 - PAISES COM MAIORES CUSTOS LOGISTICOS EM 2026
\echo ============================================================

WITH resumo_paises AS (
    SELECT
        pais.codigo_pais,
        pais.nome_pais,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.valor_frete_usd
        ) AS valor_frete_total_usd,

        SUM(
            fato.valor_seguro_usd
        ) AS valor_seguro_total_usd,

        SUM(
            fato.valor_frete_usd
            + fato.valor_seguro_usd
        ) AS custo_logistico_total_usd,

        SUM(
            fato.valor_cif_usd
        ) AS valor_cif_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_pais AS pais
        ON pais.codigo_pais
            = fato.codigo_pais

    WHERE
        fato.fluxo = 'IMPORTACAO'
        AND fato.ano = 2026

    GROUP BY
        pais.codigo_pais,
        pais.nome_pais
),

classificacao AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY
                custo_logistico_total_usd DESC
        ) AS posicao

    FROM resumo_paises
)

SELECT
    posicao,
    codigo_pais,
    nome_pais,

    valor_fob_total_usd,
    valor_frete_total_usd,
    valor_seguro_total_usd,
    custo_logistico_total_usd,
    valor_cif_total_usd,

    ROUND(
        custo_logistico_total_usd::NUMERIC
        /
        NULLIF(
            valor_fob_total_usd,
            0
        )
        * 100,
        2
    ) AS custo_sobre_fob_percentual,

    ROUND(
        valor_frete_total_usd::NUMERIC
        /
        NULLIF(
            peso_liquido_total_kg,
            0
        ),
        4
    ) AS frete_medio_usd_kg

FROM classificacao

WHERE posicao <= 15

ORDER BY
    posicao;


\echo
\echo ============================================================
\echo ANALISE 6 - PRODUTOS COM MAIORES CUSTOS LOGISTICOS EM 2026
\echo ============================================================

WITH resumo_produtos AS (
    SELECT
        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.valor_frete_usd
        ) AS valor_frete_total_usd,

        SUM(
            fato.valor_seguro_usd
        ) AS valor_seguro_total_usd,

        SUM(
            fato.valor_frete_usd
            + fato.valor_seguro_usd
        ) AS custo_logistico_total_usd,

        SUM(
            fato.valor_cif_usd
        ) AS valor_cif_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE
        fato.fluxo = 'IMPORTACAO'
        AND fato.ano = 2026

    GROUP BY
        produto.codigo_sh4,
        produto.descricao_sh4
),

classificacao AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY
                custo_logistico_total_usd DESC
        ) AS posicao

    FROM resumo_produtos
)

SELECT
    posicao,
    codigo_sh4,
    descricao_sh4,

    valor_fob_total_usd,
    valor_frete_total_usd,
    valor_seguro_total_usd,
    custo_logistico_total_usd,
    valor_cif_total_usd,

    ROUND(
        custo_logistico_total_usd::NUMERIC
        /
        NULLIF(
            valor_fob_total_usd,
            0
        )
        * 100,
        2
    ) AS custo_sobre_fob_percentual,

    ROUND(
        valor_frete_total_usd::NUMERIC
        /
        NULLIF(
            peso_liquido_total_kg,
            0
        ),
        4
    ) AS frete_medio_usd_kg

FROM classificacao

WHERE posicao <= 20

ORDER BY
    posicao;


\echo
\echo ============================================================
\echo ANALISE 7 - MAIORES CUSTOS RELATIVOS POR PRODUTO EM 2026
\echo SOMENTE PRODUTOS COM FOB DE PELO MENOS US$ 10 MILHOES
\echo ============================================================

WITH resumo_produtos AS (
    SELECT
        produto.codigo_sh4,
        produto.descricao_sh4,

        SUM(
            fato.valor_fob_usd
        ) AS valor_fob_total_usd,

        SUM(
            fato.valor_frete_usd
        ) AS valor_frete_total_usd,

        SUM(
            fato.valor_seguro_usd
        ) AS valor_seguro_total_usd,

        SUM(
            fato.valor_frete_usd
            + fato.valor_seguro_usd
        ) AS custo_logistico_total_usd,

        SUM(
            fato.valor_cif_usd
        ) AS valor_cif_total_usd,

        SUM(
            fato.peso_liquido_kg
        ) AS peso_liquido_total_kg

    FROM comex.fato_comex AS fato

    INNER JOIN comex.dim_produto AS produto
        ON produto.codigo_ncm
            = fato.codigo_ncm

    WHERE
        fato.fluxo = 'IMPORTACAO'
        AND fato.ano = 2026

    GROUP BY
        produto.codigo_sh4,
        produto.descricao_sh4
),

produtos_filtrados AS (
    SELECT
        *,

        ROUND(
            custo_logistico_total_usd::NUMERIC
            /
            NULLIF(
                valor_fob_total_usd,
                0
            )
            * 100,
            2
        ) AS custo_sobre_fob_percentual,

        ROUND(
            valor_frete_total_usd::NUMERIC
            /
            NULLIF(
                peso_liquido_total_kg,
                0
            ),
            4
        ) AS frete_medio_usd_kg

    FROM resumo_produtos

    WHERE valor_fob_total_usd >= 10000000
),

classificacao AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            ORDER BY
                custo_sobre_fob_percentual DESC
        ) AS posicao

    FROM produtos_filtrados
)

SELECT
    posicao,
    codigo_sh4,
    descricao_sh4,

    valor_fob_total_usd,
    valor_frete_total_usd,
    valor_seguro_total_usd,
    custo_logistico_total_usd,
    valor_cif_total_usd,

    custo_sobre_fob_percentual,
    frete_medio_usd_kg

FROM classificacao

WHERE posicao <= 15

ORDER BY
    posicao;


\echo
\echo ============================================================
\echo ANALISE 8 - VARIACAO DO CUSTO LOGISTICO POR VIA
\echo ENTRE 2025 E 2026
\echo ============================================================

WITH comparacao AS (
    SELECT
        codigo_via,

        SUM(
            CASE
                WHEN ano = 2025
                    THEN valor_frete_usd
                       + valor_seguro_usd
                ELSE 0
            END
        ) AS custo_2025_usd,

        SUM(
            CASE
                WHEN ano = 2026
                    THEN valor_frete_usd
                       + valor_seguro_usd
                ELSE 0
            END
        ) AS custo_2026_usd

    FROM comex.fato_comex

    WHERE
        fluxo = 'IMPORTACAO'
        AND ano IN (
            2025,
            2026
        )

    GROUP BY
        codigo_via
)

SELECT
    via.codigo_via,
    via.nome_via,

    comparacao.custo_2025_usd,
    comparacao.custo_2026_usd,

    (
        comparacao.custo_2026_usd
        - comparacao.custo_2025_usd
    ) AS variacao_absoluta_usd,

    ROUND(
        (
            comparacao.custo_2026_usd::NUMERIC
            /
            NULLIF(
                comparacao.custo_2025_usd,
                0
            )
            - 1
        )
        * 100,
        2
    ) AS variacao_percentual

FROM comparacao

INNER JOIN comex.dim_via AS via
    ON via.codigo_via
        = comparacao.codigo_via

ORDER BY
    variacao_absoluta_usd DESC;


\echo
\echo ============================================================
\echo ANALISE DE CUSTOS DE IMPORTACAO FINALIZADA
\echo ============================================================