\set ON_ERROR_STOP on
\pset pager off
\timing on

\echo
\echo ============================================================
\echo CRIANDO O USUARIO SOMENTE LEITURA DO POWER BI
\echo ============================================================

SELECT
    current_database() AS banco_atual,
    current_user AS usuario_atual;


\echo
\echo ============================================================
\echo 1 DE 6 - CRIANDO A ROLE POWERBI_READER
\echo ============================================================

DO
$$
BEGIN
    IF NOT EXISTS (
        SELECT
            1

        FROM pg_roles

        WHERE rolname = 'powerbi_reader'
    ) THEN

        CREATE ROLE powerbi_reader
        WITH
            LOGIN
            NOSUPERUSER
            NOCREATEDB
            NOCREATEROLE
            NOINHERIT
            NOREPLICATION;

        RAISE NOTICE
            'Role powerbi_reader criada com sucesso.';

    ELSE

        RAISE NOTICE
            'A role powerbi_reader ja existe.';

    END IF;
END;
$$;


\echo
\echo ============================================================
\echo 2 DE 6 - GARANTINDO AS RESTRICOES DA ROLE
\echo ============================================================

ALTER ROLE powerbi_reader
WITH
    LOGIN
    NOSUPERUSER
    NOCREATEDB
    NOCREATEROLE
    NOINHERIT
    NOREPLICATION;


\echo
\echo ============================================================
\echo 3 DE 6 - PERMITINDO CONEXAO AO BANCO
\echo ============================================================

GRANT CONNECT
ON DATABASE comex_stat_mg
TO powerbi_reader;


\echo
\echo ============================================================
\echo 4 DE 6 - PERMITINDO ACESSO AO SCHEMA BI
\echo ============================================================

GRANT USAGE
ON SCHEMA bi
TO powerbi_reader;

REVOKE CREATE
ON SCHEMA bi
FROM powerbi_reader;


\echo
\echo ============================================================
\echo 5 DE 6 - CONCEDENDO SOMENTE LEITURA NAS VIEWS
\echo ============================================================

GRANT SELECT
ON ALL TABLES IN SCHEMA bi
TO powerbi_reader;

REVOKE
    INSERT,
    UPDATE,
    DELETE,
    TRUNCATE,
    REFERENCES,
    TRIGGER
ON ALL TABLES IN SCHEMA bi
FROM powerbi_reader;


\echo
\echo ============================================================
\echo 6 DE 6 - CONFIGURANDO VIEWS FUTURAS
\echo ============================================================

ALTER DEFAULT PRIVILEGES
FOR ROLE postgres
IN SCHEMA bi

GRANT SELECT
ON TABLES
TO powerbi_reader;


\echo
\echo ============================================================
\echo CONFIGURANDO O SCHEMA PADRAO
\echo ============================================================

ALTER ROLE powerbi_reader
IN DATABASE comex_stat_mg

SET search_path = bi, pg_catalog;


\echo
\echo ============================================================
\echo VALIDACAO DA ROLE
\echo ============================================================

SELECT
    rolname AS usuario,
    rolcanlogin AS permite_login,
    rolsuper AS superusuario,
    rolcreatedb AS pode_criar_banco,
    rolcreaterole AS pode_criar_role,
    rolreplication AS permite_replicacao

FROM pg_roles

WHERE rolname = 'powerbi_reader';


\echo
\echo ============================================================
\echo VALIDACAO DAS PERMISSOES
\echo ============================================================

SELECT
    has_database_privilege(
        'powerbi_reader',
        'comex_stat_mg',
        'CONNECT'
    ) AS pode_conectar,

    has_schema_privilege(
        'powerbi_reader',
        'bi',
        'USAGE'
    ) AS pode_acessar_schema_bi,

    has_schema_privilege(
        'powerbi_reader',
        'bi',
        'CREATE'
    ) AS pode_criar_no_schema_bi,

    has_table_privilege(
        'powerbi_reader',
        'bi.fato_comex',
        'SELECT'
    ) AS pode_consultar_fato,

    has_table_privilege(
        'powerbi_reader',
        'bi.fato_comex',
        'INSERT'
    ) AS pode_inserir_na_fato,

    has_table_privilege(
        'powerbi_reader',
        'bi.fato_comex',
        'UPDATE'
    ) AS pode_alterar_a_fato,

    has_table_privilege(
        'powerbi_reader',
        'bi.fato_comex',
        'DELETE'
    ) AS pode_excluir_da_fato;


\echo
\echo ============================================================
\echo USUARIO POWERBI_READER CONFIGURADO COM SUCESSO
\echo ============================================================