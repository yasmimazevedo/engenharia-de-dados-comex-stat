\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo CRIANDO INDICES ANALITICOS
\echo ============================================================

SELECT
    current_database() AS banco_atual,
    current_user AS usuario_atual;


BEGIN;


\echo
\echo 1 DE 5 - INDICE DE FLUXO E PERIODO

CREATE INDEX IF NOT EXISTS
    idx_fato_comex_fluxo_periodo
ON comex.fato_comex (
    fluxo,
    data_referencia
);


\echo
\echo 2 DE 5 - INDICE DE PRODUTO, FLUXO E PERIODO

CREATE INDEX IF NOT EXISTS
    idx_fato_comex_produto_periodo
ON comex.fato_comex (
    codigo_ncm,
    fluxo,
    data_referencia
);


\echo
\echo 3 DE 5 - INDICE DE PAIS, FLUXO E PERIODO

CREATE INDEX IF NOT EXISTS
    idx_fato_comex_pais_periodo
ON comex.fato_comex (
    codigo_pais,
    fluxo,
    data_referencia
);


\echo
\echo 4 DE 5 - INDICE DE VIA

CREATE INDEX IF NOT EXISTS
    idx_fato_comex_via
ON comex.fato_comex (
    codigo_via
);


\echo
\echo 5 DE 5 - INDICE DE URF

CREATE INDEX IF NOT EXISTS
    idx_fato_comex_urf
ON comex.fato_comex (
    codigo_urf
);


COMMIT;


\echo
\echo ============================================================
\echo ATUALIZANDO ESTATISTICAS
\echo ============================================================

ANALYZE comex.fato_comex;


\echo
\echo ============================================================
\echo INDICES DA FATO COMEX
\echo ============================================================

SELECT
    indexname AS nome_indice,
    indexdef AS definicao
FROM pg_indexes
WHERE schemaname = 'comex'
  AND tablename = 'fato_comex'
ORDER BY
    indexname;


\echo
\echo ============================================================
\echo TAMANHO DA TABELA E DOS INDICES
\echo ============================================================

SELECT
    pg_size_pretty(
        pg_relation_size(
            'comex.fato_comex'
        )
    ) AS tamanho_dados,

    pg_size_pretty(
        pg_indexes_size(
            'comex.fato_comex'
        )
    ) AS tamanho_indices,

    pg_size_pretty(
        pg_total_relation_size(
            'comex.fato_comex'
        )
    ) AS tamanho_total;


\echo
\echo ============================================================
\echo INDICES CRIADOS COM SUCESSO
\echo ============================================================