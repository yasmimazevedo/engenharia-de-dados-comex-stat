\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo CORRIGINDO A CODIFICACAO DA DIMENSAO DE FLUXO
\echo ============================================================

SELECT
    current_database() AS banco_atual,
    current_user AS usuario_atual;


BEGIN;


CREATE OR REPLACE VIEW bi.dim_fluxo AS

SELECT
    fluxo,
    nome_fluxo,
    ordem_fluxo

FROM (
    VALUES
        (
            'EXPORTACAO'::TEXT,
            U&'Exporta\00E7\00E3o'::TEXT,
            1
        ),
        (
            'IMPORTACAO'::TEXT,
            U&'Importa\00E7\00E3o'::TEXT,
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
\echo VALIDANDO O TEXTO CORRIGIDO
\echo ============================================================

SELECT
    fluxo,
    nome_fluxo,
    ordem_fluxo

FROM bi.dim_fluxo

ORDER BY
    ordem_fluxo;


\echo
\echo ============================================================
\echo CODIFICACAO CORRIGIDA COM SUCESSO
\echo ============================================================