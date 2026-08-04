\set ON_ERROR_STOP on
\timing on

\echo
\echo ============================================================
\echo CARREGANDO OS DADOS NO POSTGRESQL
\echo ============================================================

SELECT
    current_database() AS banco_atual,
    current_user AS usuario_atual;

BEGIN;

\echo
\echo Limpando as tabelas para uma nova carga...

TRUNCATE TABLE
    comex.fato_comex,
    comex.dim_produto,
    comex.dim_pais,
    comex.dim_via,
    comex.dim_urf,
    comex.dim_unidade,
    comex.dim_tempo
RESTART IDENTITY;


\echo
\echo ============================================================
\echo 1 DE 7 - CARREGANDO DIM_UNIDADE
\echo ============================================================

\copy comex.dim_unidade (codigo_unidade, nome_unidade, sigla_unidade) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/dimensions/dim_unidade.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


\echo
\echo ============================================================
\echo 2 DE 7 - CARREGANDO DIM_PRODUTO
\echo ============================================================

\copy comex.dim_produto (codigo_ncm, descricao_ncm, codigo_sh6, descricao_sh6, codigo_sh4, descricao_sh4, codigo_sh2, descricao_sh2, codigo_secao, descricao_secao, codigo_unidade, nome_unidade, sigla_unidade) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/dimensions/dim_produto.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


\echo
\echo ============================================================
\echo 3 DE 7 - CARREGANDO DIM_PAIS
\echo ============================================================

\copy comex.dim_pais (codigo_pais, codigo_iso_n3, codigo_iso_a3, nome_pais) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/dimensions/dim_pais.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


\echo
\echo ============================================================
\echo 4 DE 7 - CARREGANDO DIM_VIA
\echo ============================================================

\copy comex.dim_via (codigo_via, nome_via) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/dimensions/dim_via.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


\echo
\echo ============================================================
\echo 5 DE 7 - CARREGANDO DIM_URF
\echo ============================================================

\copy comex.dim_urf (codigo_urf, nome_urf) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/dimensions/dim_urf.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


\echo
\echo ============================================================
\echo 6 DE 7 - CARREGANDO DIM_TEMPO
\echo ============================================================

\copy comex.dim_tempo (data_referencia, ano, mes, nome_mes, trimestre, semestre, ano_mes, ordem_ano_mes) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/dimensions/dim_tempo.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


\echo
\echo ============================================================
\echo 7 DE 7 - CARREGANDO FATO_COMEX
\echo ============================================================

\copy comex.fato_comex (fluxo, data_referencia, ano, mes, codigo_ncm, codigo_unidade, codigo_pais, sigla_uf, codigo_via, codigo_urf, quantidade_estatistica, peso_liquido_kg, valor_fob_usd, valor_frete_usd, valor_seguro_usd, valor_cif_usd, arquivo_origem) FROM 'C:/Users/yasmi/OneDrive/Documentos/Projetos/engenharia-de-dados-comex-stat/data/processed/fato_comex/fato_comex.csv' WITH (FORMAT csv, HEADER true, DELIMITER ';', ENCODING 'UTF8')


COMMIT;


\echo
\echo ============================================================
\echo ATUALIZANDO ESTATISTICAS DO POSTGRESQL
\echo ============================================================

ANALYZE comex.dim_unidade;
ANALYZE comex.dim_produto;
ANALYZE comex.dim_pais;
ANALYZE comex.dim_via;
ANALYZE comex.dim_urf;
ANALYZE comex.dim_tempo;
ANALYZE comex.fato_comex;


\echo
\echo ============================================================
\echo QUANTIDADE DE REGISTROS POR TABELA
\echo ============================================================

SELECT
    tabela,
    linhas
FROM (
    SELECT
        1 AS ordem,
        'dim_unidade' AS tabela,
        COUNT(*) AS linhas
    FROM comex.dim_unidade

    UNION ALL

    SELECT
        2,
        'dim_produto',
        COUNT(*)
    FROM comex.dim_produto

    UNION ALL

    SELECT
        3,
        'dim_pais',
        COUNT(*)
    FROM comex.dim_pais

    UNION ALL

    SELECT
        4,
        'dim_via',
        COUNT(*)
    FROM comex.dim_via

    UNION ALL

    SELECT
        5,
        'dim_urf',
        COUNT(*)
    FROM comex.dim_urf

    UNION ALL

    SELECT
        6,
        'dim_tempo',
        COUNT(*)
    FROM comex.dim_tempo

    UNION ALL

    SELECT
        7,
        'fato_comex',
        COUNT(*)
    FROM comex.fato_comex
) AS contagens
ORDER BY
    ordem;


\echo
\echo ============================================================
\echo VALIDACAO DOS TOTAIS DA FATO
\echo ============================================================

WITH totais_esperados (
    fluxo,
    ano,
    linhas_esperadas,
    fob_esperado,
    peso_esperado
) AS (
    VALUES
        (
            'EXPORTACAO',
            2024,
            38523::BIGINT,
            20911352174::NUMERIC,
            99649819621::NUMERIC
        ),
        (
            'IMPORTACAO',
            2024,
            95144::BIGINT,
            7529883730::NUMERIC,
            6047223169::NUMERIC
        ),
        (
            'EXPORTACAO',
            2025,
            40949::BIGINT,
            21968821625::NUMERIC,
            96114357063::NUMERIC
        ),
        (
            'IMPORTACAO',
            2025,
            103594::BIGINT,
            8603498628::NUMERIC,
            6572579902::NUMERIC
        ),
        (
            'EXPORTACAO',
            2026,
            40884::BIGINT,
            21920923140::NUMERIC,
            91660659745::NUMERIC
        ),
        (
            'IMPORTACAO',
            2026,
            115743::BIGINT,
            9641041374::NUMERIC,
            6420656814::NUMERIC
        )
),
totais_encontrados AS (
    SELECT
        fluxo,
        ano,
        COUNT(*) AS linhas_encontradas,
        SUM(
            valor_fob_usd
        ) AS fob_encontrado,
        SUM(
            peso_liquido_kg
        ) AS peso_encontrado
    FROM comex.fato_comex
    GROUP BY
        fluxo,
        ano
)
SELECT
    esperado.fluxo,
    esperado.ano,

    encontrado.linhas_encontradas,
    esperado.linhas_esperadas,

    encontrado.fob_encontrado,
    esperado.fob_esperado,

    encontrado.peso_encontrado,
    esperado.peso_esperado,

    CASE
        WHEN
            encontrado.linhas_encontradas
                = esperado.linhas_esperadas
            AND encontrado.fob_encontrado
                = esperado.fob_esperado
            AND encontrado.peso_encontrado
                = esperado.peso_esperado
        THEN 'APROVADO'
        ELSE 'DIVERGENTE'
    END AS resultado
FROM totais_esperados AS esperado
LEFT JOIN totais_encontrados AS encontrado
    ON encontrado.fluxo = esperado.fluxo
    AND encontrado.ano = esperado.ano
ORDER BY
    esperado.ano,
    esperado.fluxo;


\echo
\echo ============================================================
\echo RESUMO GERAL
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
    COUNT(
        DISTINCT codigo_urf
    ) AS urfs_distintas,
    MIN(
        data_referencia
    ) AS primeira_data,
    MAX(
        data_referencia
    ) AS ultima_data
FROM comex.fato_comex;


\echo
\echo ============================================================
\echo CARGA FINALIZADA
\echo ============================================================