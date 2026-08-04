\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo CRIANDO A CAMADA DE VIEWS PARA O POWER BI
\echo ============================================================

SELECT
    current_database() AS banco_atual,
    current_user AS usuario_atual;


BEGIN;


\echo
\echo 1 DE 9 - CRIANDO O SCHEMA BI
\echo ============================================================

CREATE SCHEMA IF NOT EXISTS bi
AUTHORIZATION postgres;

COMMENT ON SCHEMA bi IS
'Camada de acesso e modelagem destinada ao Power BI.';


\echo
\echo 2 DE 9 - CRIANDO A VIEW DA FATO
\echo ============================================================

CREATE OR REPLACE VIEW bi.fato_comex AS

SELECT
    id_fato,

    fluxo,
    data_referencia,
    ano,
    mes,

    codigo_ncm,
    codigo_unidade,
    codigo_pais,
    sigla_uf,
    codigo_via,
    codigo_urf,

    quantidade_estatistica,
    peso_liquido_kg,

    valor_fob_usd,
    valor_frete_usd,
    valor_seguro_usd,

    COALESCE(
        valor_frete_usd,
        0
    )
    +
    COALESCE(
        valor_seguro_usd,
        0
    ) AS custo_logistico_importacao_usd,

    valor_cif_usd,

    arquivo_origem

FROM comex.fato_comex;


COMMENT ON VIEW bi.fato_comex IS
'Fato de comércio exterior preparada para consumo no Power BI.';


\echo
\echo 3 DE 9 - CRIANDO A DIMENSAO DE TEMPO
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_tempo AS

SELECT
    *

FROM comex.dim_tempo;


COMMENT ON VIEW bi.dim_tempo IS
'Dimensão de datas mensais utilizada pelo Power BI.';


\echo
\echo 4 DE 9 - CRIANDO A DIMENSAO DE PRODUTOS
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_produto AS

SELECT
    *

FROM comex.dim_produto;


COMMENT ON VIEW bi.dim_produto IS
'Dimensão de produtos contendo NCM e hierarquias do Sistema Harmonizado.';


\echo
\echo 5 DE 9 - CRIANDO A DIMENSAO DE PAISES
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_pais AS

SELECT
    *

FROM comex.dim_pais;


COMMENT ON VIEW bi.dim_pais IS
'Dimensão de países parceiros do comércio exterior.';


\echo
\echo 6 DE 9 - CRIANDO A DIMENSAO DE VIAS
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_via AS

SELECT
    *

FROM comex.dim_via;


COMMENT ON VIEW bi.dim_via IS
'Dimensão das vias de transporte utilizadas nas operações.';


\echo
\echo 7 DE 9 - CRIANDO A DIMENSAO DE URFS
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_urf AS

SELECT
    *

FROM comex.dim_urf;


COMMENT ON VIEW bi.dim_urf IS
'Dimensão das unidades aduaneiras responsáveis pelos despachos.';


\echo
\echo 8 DE 9 - CRIANDO A DIMENSAO DE UNIDADES
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_unidade AS

SELECT
    *

FROM comex.dim_unidade;


COMMENT ON VIEW bi.dim_unidade IS
'Dimensão das unidades estatísticas dos produtos.';


\echo
\echo 9 DE 9 - CRIANDO A DIMENSAO DE FLUXO
\echo ============================================================

CREATE OR REPLACE VIEW bi.dim_fluxo AS

SELECT
    fluxo,
    nome_fluxo,
    ordem_fluxo

FROM (
    VALUES
        (
            'EXPORTACAO'::TEXT,
            'Exportação'::TEXT,
            1
        ),
        (
            'IMPORTACAO'::TEXT,
            'Importação'::TEXT,
            2
        )
) AS dados (
    fluxo,
    nome_fluxo,
    ordem_fluxo
);


COMMENT ON VIEW bi.dim_fluxo IS
'Dimensão auxiliar para os fluxos de exportação e importação.';


COMMIT;


\echo
\echo ============================================================
\echo VIEWS DISPONIVEIS NO SCHEMA BI
\echo ============================================================

SELECT
    table_schema AS schema,
    table_name AS view

FROM information_schema.views

WHERE table_schema = 'bi'

ORDER BY
    table_name;


\echo
\echo ============================================================
\echo QUANTIDADE DE REGISTROS NAS VIEWS
\echo ============================================================

WITH contagens AS (
    SELECT
        1 AS ordem,
        'bi.fato_comex' AS objeto,
        COUNT(*) AS linhas
    FROM bi.fato_comex

    UNION ALL

    SELECT
        2,
        'bi.dim_tempo',
        COUNT(*)
    FROM bi.dim_tempo

    UNION ALL

    SELECT
        3,
        'bi.dim_produto',
        COUNT(*)
    FROM bi.dim_produto

    UNION ALL

    SELECT
        4,
        'bi.dim_pais',
        COUNT(*)
    FROM bi.dim_pais

    UNION ALL

    SELECT
        5,
        'bi.dim_via',
        COUNT(*)
    FROM bi.dim_via

    UNION ALL

    SELECT
        6,
        'bi.dim_urf',
        COUNT(*)
    FROM bi.dim_urf

    UNION ALL

    SELECT
        7,
        'bi.dim_unidade',
        COUNT(*)
    FROM bi.dim_unidade

    UNION ALL

    SELECT
        8,
        'bi.dim_fluxo',
        COUNT(*)
    FROM bi.dim_fluxo
)

SELECT
    objeto,
    linhas

FROM contagens

ORDER BY
    ordem;


\echo
\echo ============================================================
\echo VALIDACAO DOS TOTAIS DA VIEW FATO
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

    SUM(
        custo_logistico_importacao_usd
    ) AS custo_logistico_total_usd,

    SUM(
        valor_cif_usd
    ) AS valor_cif_total_usd

FROM bi.fato_comex

GROUP BY
    fluxo,
    ano

ORDER BY
    fluxo,
    ano;


\echo
\echo ============================================================
\echo CAMADA BI CRIADA COM SUCESSO
\echo ============================================================