\set ON_ERROR_STOP on

\echo
\echo ============================================================
\echo CRIANDO AS TABELAS DE DIMENSAO
\echo ============================================================

BEGIN;


CREATE TABLE IF NOT EXISTS comex.dim_unidade (
    codigo_unidade VARCHAR(10) PRIMARY KEY,
    nome_unidade TEXT NOT NULL,
    sigla_unidade VARCHAR(20) NOT NULL
);

COMMENT ON TABLE comex.dim_unidade IS
    'Unidades estatísticas utilizadas na classificação NCM.';


CREATE TABLE IF NOT EXISTS comex.dim_produto (
    codigo_ncm VARCHAR(8) PRIMARY KEY,
    descricao_ncm TEXT NOT NULL,

    codigo_sh6 VARCHAR(6),
    descricao_sh6 TEXT,

    codigo_sh4 VARCHAR(4),
    descricao_sh4 TEXT,

    codigo_sh2 VARCHAR(2),
    descricao_sh2 TEXT,

    codigo_secao VARCHAR(10),
    descricao_secao TEXT,

    codigo_unidade VARCHAR(10) NOT NULL,
    nome_unidade TEXT NOT NULL,
    sigla_unidade VARCHAR(20) NOT NULL,

    CONSTRAINT fk_dim_produto_unidade
        FOREIGN KEY (codigo_unidade)
        REFERENCES comex.dim_unidade (
            codigo_unidade
        ),

    CONSTRAINT uq_dim_produto_ncm_unidade
        UNIQUE (
            codigo_ncm,
            codigo_unidade
        )
);

COMMENT ON TABLE comex.dim_produto IS
    'Produtos NCM e sua hierarquia SH2, SH4, SH6 e seção.';


CREATE TABLE IF NOT EXISTS comex.dim_pais (
    codigo_pais VARCHAR(10) PRIMARY KEY,
    codigo_iso_n3 VARCHAR(10),
    codigo_iso_a3 VARCHAR(10),
    nome_pais TEXT NOT NULL
);

COMMENT ON TABLE comex.dim_pais IS
    'Países e códigos especiais utilizados pelo Comex Stat.';


CREATE TABLE IF NOT EXISTS comex.dim_via (
    codigo_via VARCHAR(10) PRIMARY KEY,
    nome_via TEXT NOT NULL
);

COMMENT ON TABLE comex.dim_via IS
    'Vias utilizadas no transporte das mercadorias.';


CREATE TABLE IF NOT EXISTS comex.dim_urf (
    codigo_urf VARCHAR(10) PRIMARY KEY,
    nome_urf TEXT NOT NULL
);

COMMENT ON TABLE comex.dim_urf IS
    'Unidades da Receita Federal relacionadas às operações.';


CREATE TABLE IF NOT EXISTS comex.dim_tempo (
    data_referencia DATE PRIMARY KEY,

    ano SMALLINT NOT NULL,
    mes SMALLINT NOT NULL,
    nome_mes VARCHAR(20) NOT NULL,

    trimestre SMALLINT NOT NULL,
    semestre SMALLINT NOT NULL,

    ano_mes VARCHAR(7) NOT NULL,
    ordem_ano_mes INTEGER NOT NULL,

    CONSTRAINT uq_dim_tempo_ano_mes
        UNIQUE (
            ano,
            mes
        ),

    CONSTRAINT uq_dim_tempo_ano_mes_texto
        UNIQUE (
            ano_mes
        ),

    CONSTRAINT uq_dim_tempo_ordem
        UNIQUE (
            ordem_ano_mes
        ),

    CONSTRAINT ck_dim_tempo_ano
        CHECK (
            ano BETWEEN 2024 AND 2026
        ),

    CONSTRAINT ck_dim_tempo_mes
        CHECK (
            mes BETWEEN 1 AND 6
        ),

    CONSTRAINT ck_dim_tempo_trimestre
        CHECK (
            trimestre BETWEEN 1 AND 4
        ),

    CONSTRAINT ck_dim_tempo_semestre
        CHECK (
            semestre IN (1, 2)
        ),

    CONSTRAINT ck_dim_tempo_data_consistente
        CHECK (
            data_referencia = make_date(
                ano,
                mes,
                1
            )
        )
);

COMMENT ON TABLE comex.dim_tempo IS
    'Meses analisados no primeiro semestre de 2024, 2025 e 2026.';


COMMIT;