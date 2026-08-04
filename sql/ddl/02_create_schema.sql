\set ON_ERROR_STOP on

\echo
\echo ============================================================
\echo CRIANDO O SCHEMA COMEX
\echo ============================================================

BEGIN;

CREATE SCHEMA IF NOT EXISTS comex;

COMMENT ON SCHEMA comex IS
    'Schema analítico do projeto Comex Stat Minas Gerais.';

COMMIT;