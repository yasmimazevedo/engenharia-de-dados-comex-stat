\set ON_ERROR_STOP on

\echo
\echo ============================================================
\echo CRIANDO O BANCO COMEX STAT MG
\echo ============================================================

SELECT format(
    'CREATE DATABASE %I',
    'comex_stat_mg'
)
WHERE NOT EXISTS (
    SELECT 1
    FROM pg_database
    WHERE datname = 'comex_stat_mg'
)
\gexec

\connect comex_stat_mg

COMMENT ON DATABASE comex_stat_mg IS
    'Banco analítico do comércio exterior de Minas Gerais, primeiro semestre de 2024 a 2026.';

\ir 02_create_schema.sql
\ir 03_create_dimensions.sql
\ir 04_create_fact.sql

\echo
\echo ============================================================
\echo MODELO CRIADO COM SUCESSO
\echo ============================================================

SELECT
    current_database() AS banco_atual,
    current_user AS usuario_atual,
    version() AS versao_postgresql;

\dt comex.*