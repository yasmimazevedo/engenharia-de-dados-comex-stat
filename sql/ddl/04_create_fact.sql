\set ON_ERROR_STOP on

\echo
\echo ============================================================
\echo CRIANDO A TABELA FATO COMEX
\echo ============================================================

BEGIN;


CREATE TABLE IF NOT EXISTS comex.fato_comex (
    id_fato BIGINT
        GENERATED ALWAYS AS IDENTITY
        PRIMARY KEY,

    fluxo VARCHAR(11) NOT NULL,

    data_referencia DATE NOT NULL,
    ano SMALLINT NOT NULL,
    mes SMALLINT NOT NULL,

    codigo_ncm VARCHAR(8) NOT NULL,
    codigo_unidade VARCHAR(10) NOT NULL,
    codigo_pais VARCHAR(10) NOT NULL,

    sigla_uf CHAR(2) NOT NULL,

    codigo_via VARCHAR(10) NOT NULL,
    codigo_urf VARCHAR(10) NOT NULL,

    quantidade_estatistica NUMERIC NOT NULL,
    peso_liquido_kg BIGINT NOT NULL,
    valor_fob_usd BIGINT NOT NULL,

    valor_frete_usd BIGINT,
    valor_seguro_usd BIGINT,
    valor_cif_usd BIGINT,

    arquivo_origem VARCHAR(30) NOT NULL,

    CONSTRAINT fk_fato_tempo
        FOREIGN KEY (
            data_referencia
        )
        REFERENCES comex.dim_tempo (
            data_referencia
        ),

    CONSTRAINT fk_fato_produto_unidade
        FOREIGN KEY (
            codigo_ncm,
            codigo_unidade
        )
        REFERENCES comex.dim_produto (
            codigo_ncm,
            codigo_unidade
        ),

    CONSTRAINT fk_fato_unidade
        FOREIGN KEY (
            codigo_unidade
        )
        REFERENCES comex.dim_unidade (
            codigo_unidade
        ),

    CONSTRAINT fk_fato_pais
        FOREIGN KEY (
            codigo_pais
        )
        REFERENCES comex.dim_pais (
            codigo_pais
        ),

    CONSTRAINT fk_fato_via
        FOREIGN KEY (
            codigo_via
        )
        REFERENCES comex.dim_via (
            codigo_via
        ),

    CONSTRAINT fk_fato_urf
        FOREIGN KEY (
            codigo_urf
        )
        REFERENCES comex.dim_urf (
            codigo_urf
        ),

    CONSTRAINT ck_fato_fluxo
        CHECK (
            fluxo IN (
                'EXPORTACAO',
                'IMPORTACAO'
            )
        ),

    CONSTRAINT ck_fato_ano
        CHECK (
            ano BETWEEN 2024 AND 2026
        ),

    CONSTRAINT ck_fato_mes
        CHECK (
            mes BETWEEN 1 AND 6
        ),

    CONSTRAINT ck_fato_uf
        CHECK (
            sigla_uf = 'MG'
        ),

    CONSTRAINT ck_fato_quantidade
        CHECK (
            quantidade_estatistica >= 0
        ),

    CONSTRAINT ck_fato_peso
        CHECK (
            peso_liquido_kg >= 0
        ),

    CONSTRAINT ck_fato_valor_fob
        CHECK (
            valor_fob_usd >= 0
        ),

    CONSTRAINT ck_fato_valor_frete
        CHECK (
            valor_frete_usd IS NULL
            OR valor_frete_usd >= 0
        ),

    CONSTRAINT ck_fato_valor_seguro
        CHECK (
            valor_seguro_usd IS NULL
            OR valor_seguro_usd >= 0
        ),

    CONSTRAINT ck_fato_valor_cif
        CHECK (
            valor_cif_usd IS NULL
            OR valor_cif_usd >= 0
        ),

    CONSTRAINT ck_fato_data_consistente
        CHECK (
            data_referencia = make_date(
                ano,
                mes,
                1
            )
        ),

    CONSTRAINT ck_fato_metricas_fluxo
        CHECK (
            (
                fluxo = 'EXPORTACAO'
                AND valor_frete_usd IS NULL
                AND valor_seguro_usd IS NULL
                AND valor_cif_usd IS NULL
            )
            OR
            (
                fluxo = 'IMPORTACAO'
                AND valor_frete_usd IS NOT NULL
                AND valor_seguro_usd IS NOT NULL
                AND valor_cif_usd IS NOT NULL
                AND valor_cif_usd = (
                    valor_fob_usd
                    + valor_frete_usd
                    + valor_seguro_usd
                )
            )
        ),

    CONSTRAINT ck_fato_arquivo_origem
        CHECK (
            arquivo_origem = (
                CASE
                    WHEN fluxo = 'EXPORTACAO'
                        THEN 'EXP_' || ano::TEXT || '.csv'
                    WHEN fluxo = 'IMPORTACAO'
                        THEN 'IMP_' || ano::TEXT || '.csv'
                END
            )
        )
);


COMMENT ON TABLE comex.fato_comex IS
    'Operações de exportação e importação de Minas Gerais no primeiro semestre de 2024 a 2026.';


COMMENT ON COLUMN comex.fato_comex.id_fato IS
    'Identificador técnico gerado pelo PostgreSQL.';


COMMENT ON COLUMN comex.fato_comex.valor_fob_usd IS
    'Valor FOB da operação em dólares americanos.';


COMMENT ON COLUMN comex.fato_comex.valor_cif_usd IS
    'Valor CIF aplicável somente às importações.';


COMMIT;