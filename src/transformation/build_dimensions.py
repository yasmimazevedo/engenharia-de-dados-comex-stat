import csv
from datetime import date
from pathlib import Path


MESES = {
    1: "Janeiro",
    2: "Fevereiro",
    3: "Março",
    4: "Abril",
    5: "Maio",
    6: "Junho",
    7: "Julho",
    8: "Agosto",
    9: "Setembro",
    10: "Outubro",
    11: "Novembro",
    12: "Dezembro",
}

ANOS_ANALISADOS = (
    2024,
    2025,
    2026,
)

MES_INICIAL = 1
MES_FINAL = 6


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def detectar_codificacao(caminho: Path) -> str:
    """
    Tenta ler o arquivo como UTF-8.

    Caso o arquivo não seja UTF-8, utiliza latin-1.
    """

    try:
        with caminho.open(
            mode="r",
            encoding="utf-8-sig",
        ) as arquivo:
            arquivo.read(10_000)

        return "utf-8-sig"

    except UnicodeDecodeError:
        return "latin-1"


def carregar_csv(
    caminho: Path,
    colunas_obrigatorias: set[str],
) -> list[dict[str, str]]:
    """
    Carrega uma tabela de referência.

    Todos os valores permanecem como texto para
    preservar códigos e possíveis zeros à esquerda.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho}"
        )

    codificacao = detectar_codificacao(
        caminho
    )

    print(
        f"Lendo {caminho.name} "
        f"com codificação {codificacao}..."
    )

    registros = []

    with caminho.open(
        mode="r",
        encoding=codificacao,
        newline="",
    ) as arquivo:

        leitor = csv.DictReader(
            arquivo,
            delimiter=";",
        )

        if leitor.fieldnames is None:
            raise ValueError(
                f"O arquivo {caminho.name} "
                "não possui cabeçalho."
            )

        leitor.fieldnames = [
            coluna.strip()
            for coluna in leitor.fieldnames
        ]

        colunas_encontradas = set(
            leitor.fieldnames
        )

        colunas_ausentes = (
            colunas_obrigatorias
            - colunas_encontradas
        )

        if colunas_ausentes:
            raise ValueError(
                f"Colunas ausentes em {caminho.name}: "
                f"{sorted(colunas_ausentes)}"
            )

        for linha in leitor:
            linha_limpa = {
                chave.strip(): (
                    valor.strip()
                    if valor is not None
                    else ""
                )
                for chave, valor in linha.items()
                if chave is not None
            }

            registros.append(
                linha_limpa
            )

    print(
        f"Registros carregados: {len(registros):,}"
        .replace(",", ".")
    )

    return registros


def salvar_csv(
    caminho: Path,
    colunas: list[str],
    registros: list[dict[str, str]],
) -> None:
    """
    Salva uma dimensão em UTF-8 com separador ;
    """

    caminho.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with caminho.open(
        mode="w",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo:

        escritor = csv.DictWriter(
            arquivo,
            fieldnames=colunas,
            delimiter=";",
            lineterminator="\n",
        )

        escritor.writeheader()
        escritor.writerows(registros)

    print(
        f"Dimensão criada: {caminho.name} "
        f"({len(registros):,} registros)"
        .replace(",", ".")
    )


def construir_dim_produto(
    pasta_referencia: Path,
    pasta_saida: Path,
) -> dict:
    """
    Une NCM, hierarquia SH e unidade estatística.
    """

    registros_ncm = carregar_csv(
        pasta_referencia / "NCM.csv",
        {
            "CO_NCM",
            "CO_UNID",
            "CO_SH6",
            "NO_NCM_POR",
        },
    )

    registros_sh = carregar_csv(
        pasta_referencia / "NCM_SH.csv",
        {
            "CO_SH6",
            "NO_SH6_POR",
            "CO_SH4",
            "NO_SH4_POR",
            "CO_SH2",
            "NO_SH2_POR",
            "CO_NCM_SECROM",
            "NO_SEC_POR",
        },
    )

    registros_unidade = carregar_csv(
        pasta_referencia / "NCM_UNIDADE.csv",
        {
            "CO_UNID",
            "NO_UNID",
            "SG_UNID",
        },
    )

    indice_sh = {
        linha["CO_SH6"]: linha
        for linha in registros_sh
        if linha["CO_SH6"]
    }

    indice_unidade = {
        linha["CO_UNID"]: linha
        for linha in registros_unidade
        if linha["CO_UNID"]
    }

    produtos = []
    codigos_vistos = set()

    produtos_sem_hierarquia = 0
    produtos_sem_unidade = 0

    for linha in registros_ncm:
        codigo_ncm = linha["CO_NCM"]

        if (
            not codigo_ncm
            or codigo_ncm in codigos_vistos
        ):
            continue

        codigos_vistos.add(
            codigo_ncm
        )

        hierarquia = indice_sh.get(
            linha["CO_SH6"],
            {},
        )

        unidade = indice_unidade.get(
            linha["CO_UNID"],
            {},
        )

        if not hierarquia:
            produtos_sem_hierarquia += 1

        if not unidade:
            produtos_sem_unidade += 1

        produtos.append(
            {
                "codigo_ncm": codigo_ncm,
                "descricao_ncm": linha["NO_NCM_POR"],
                "codigo_sh6": linha["CO_SH6"],
                "descricao_sh6": hierarquia.get(
                    "NO_SH6_POR",
                    "",
                ),
                "codigo_sh4": hierarquia.get(
                    "CO_SH4",
                    "",
                ),
                "descricao_sh4": hierarquia.get(
                    "NO_SH4_POR",
                    "",
                ),
                "codigo_sh2": hierarquia.get(
                    "CO_SH2",
                    "",
                ),
                "descricao_sh2": hierarquia.get(
                    "NO_SH2_POR",
                    "",
                ),
                "codigo_secao": hierarquia.get(
                    "CO_NCM_SECROM",
                    "",
                ),
                "descricao_secao": hierarquia.get(
                    "NO_SEC_POR",
                    "",
                ),
                "codigo_unidade": linha["CO_UNID"],
                "nome_unidade": unidade.get(
                    "NO_UNID",
                    "",
                ),
                "sigla_unidade": unidade.get(
                    "SG_UNID",
                    "",
                ),
            }
        )

    caminho_saida = (
        pasta_saida
        / "dim_produto.csv"
    )

    salvar_csv(
        caminho=caminho_saida,
        colunas=[
            "codigo_ncm",
            "descricao_ncm",
            "codigo_sh6",
            "descricao_sh6",
            "codigo_sh4",
            "descricao_sh4",
            "codigo_sh2",
            "descricao_sh2",
            "codigo_secao",
            "descricao_secao",
            "codigo_unidade",
            "nome_unidade",
            "sigla_unidade",
        ],
        registros=produtos,
    )

    return {
        "dimensao": caminho_saida.name,
        "registros": len(produtos),
        "sem_hierarquia": produtos_sem_hierarquia,
        "sem_unidade": produtos_sem_unidade,
    }


def construir_dimensao_simples(
    caminho_entrada: Path,
    caminho_saida: Path,
    colunas_obrigatorias: set[str],
    mapeamento_colunas: dict[str, str],
    coluna_chave: str,
) -> dict:
    """
    Cria uma dimensão simples e remove códigos
    duplicados.
    """

    registros_origem = carregar_csv(
        caminho=caminho_entrada,
        colunas_obrigatorias=colunas_obrigatorias,
    )

    registros_saida = []
    codigos_vistos = set()

    for linha in registros_origem:
        codigo = linha.get(
            coluna_chave,
            "",
        )

        if (
            not codigo
            or codigo in codigos_vistos
        ):
            continue

        codigos_vistos.add(
            codigo
        )

        registro_saida = {
            nome_saida: linha.get(
                nome_origem,
                "",
            )
            for nome_saida, nome_origem
            in mapeamento_colunas.items()
        }

        registros_saida.append(
            registro_saida
        )

    salvar_csv(
        caminho=caminho_saida,
        colunas=list(
            mapeamento_colunas.keys()
        ),
        registros=registros_saida,
    )

    return {
        "dimensao": caminho_saida.name,
        "registros": len(registros_saida),
        "sem_hierarquia": 0,
        "sem_unidade": 0,
    }


def construir_dim_tempo(
    pasta_saida: Path,
) -> dict:
    """
    Cria a dimensão de tempo do período analisado.
    """

    registros = []

    for ano in ANOS_ANALISADOS:
        for mes in range(
            MES_INICIAL,
            MES_FINAL + 1,
        ):
            data_referencia = date(
                ano,
                mes,
                1,
            )

            trimestre = (
                (mes - 1) // 3
            ) + 1

            registros.append(
                {
                    "data_referencia": (
                        data_referencia.isoformat()
                    ),
                    "ano": str(ano),
                    "mes": str(mes),
                    "nome_mes": MESES[mes],
                    "trimestre": str(trimestre),
                    "semestre": (
                        "1"
                        if mes <= 6
                        else "2"
                    ),
                    "ano_mes": (
                        f"{ano}-{mes:02d}"
                    ),
                    "ordem_ano_mes": (
                        f"{ano}{mes:02d}"
                    ),
                }
            )

    caminho_saida = (
        pasta_saida
        / "dim_tempo.csv"
    )

    salvar_csv(
        caminho=caminho_saida,
        colunas=[
            "data_referencia",
            "ano",
            "mes",
            "nome_mes",
            "trimestre",
            "semestre",
            "ano_mes",
            "ordem_ano_mes",
        ],
        registros=registros,
    )

    return {
        "dimensao": caminho_saida.name,
        "registros": len(registros),
        "sem_hierarquia": 0,
        "sem_unidade": 0,
    }


def exibir_resumo(
    resultados: list[dict],
) -> None:
    """
    Exibe o resumo das dimensões criadas.
    """

    print("\n" + "=" * 70)
    print("RESUMO DAS DIMENSÕES")
    print("=" * 70)

    for resultado in resultados:
        print(
            f"{resultado['dimensao']:<20} | "
            f"registros: "
            f"{resultado['registros']:>8,}"
            .replace(",", ".")
        )

        if (
            resultado["sem_hierarquia"] > 0
            or resultado["sem_unidade"] > 0
        ):
            print(
                "  Sem hierarquia:",
                resultado["sem_hierarquia"],
            )

            print(
                "  Sem unidade:",
                resultado["sem_unidade"],
            )


def main() -> None:
    """
    Constrói as dimensões analíticas.
    """

    raiz_projeto = obter_raiz_projeto()

    pasta_referencia = (
        raiz_projeto
        / "data"
        / "raw"
        / "reference"
    )

    pasta_saida = (
        raiz_projeto
        / "data"
        / "processed"
        / "dimensions"
    )

    resultados = []

    try:
        resultados.append(
            construir_dim_produto(
                pasta_referencia=pasta_referencia,
                pasta_saida=pasta_saida,
            )
        )

        resultados.append(
            construir_dimensao_simples(
                caminho_entrada=(
                    pasta_referencia
                    / "PAIS.csv"
                ),
                caminho_saida=(
                    pasta_saida
                    / "dim_pais.csv"
                ),
                colunas_obrigatorias={
                    "CO_PAIS",
                    "CO_PAIS_ISON3",
                    "CO_PAIS_ISOA3",
                    "NO_PAIS",
                },
                mapeamento_colunas={
                    "codigo_pais": "CO_PAIS",
                    "codigo_iso_n3": "CO_PAIS_ISON3",
                    "codigo_iso_a3": "CO_PAIS_ISOA3",
                    "nome_pais": "NO_PAIS",
                },
                coluna_chave="CO_PAIS",
            )
        )

        resultados.append(
            construir_dimensao_simples(
                caminho_entrada=(
                    pasta_referencia
                    / "VIA.csv"
                ),
                caminho_saida=(
                    pasta_saida
                    / "dim_via.csv"
                ),
                colunas_obrigatorias={
                    "CO_VIA",
                    "NO_VIA",
                },
                mapeamento_colunas={
                    "codigo_via": "CO_VIA",
                    "nome_via": "NO_VIA",
                },
                coluna_chave="CO_VIA",
            )
        )

        resultados.append(
            construir_dimensao_simples(
                caminho_entrada=(
                    pasta_referencia
                    / "URF.csv"
                ),
                caminho_saida=(
                    pasta_saida
                    / "dim_urf.csv"
                ),
                colunas_obrigatorias={
                    "CO_URF",
                    "NO_URF",
                },
                mapeamento_colunas={
                    "codigo_urf": "CO_URF",
                    "nome_urf": "NO_URF",
                },
                coluna_chave="CO_URF",
            )
        )

        resultados.append(
            construir_dimensao_simples(
                caminho_entrada=(
                    pasta_referencia
                    / "NCM_UNIDADE.csv"
                ),
                caminho_saida=(
                    pasta_saida
                    / "dim_unidade.csv"
                ),
                colunas_obrigatorias={
                    "CO_UNID",
                    "NO_UNID",
                    "SG_UNID",
                },
                mapeamento_colunas={
                    "codigo_unidade": "CO_UNID",
                    "nome_unidade": "NO_UNID",
                    "sigla_unidade": "SG_UNID",
                },
                coluna_chave="CO_UNID",
            )
        )

        resultados.append(
            construir_dim_tempo(
                pasta_saida=pasta_saida
            )
        )

    except (
        FileNotFoundError,
        ValueError,
        UnicodeError,
        csv.Error,
        OSError,
    ) as erro:
        print(
            "\nA construção das dimensões "
            "não foi concluída."
        )

        print("Motivo:", erro)

        return

    exibir_resumo(
        resultados
    )

    print(
        "\nTodas as dimensões foram "
        "construídas com sucesso."
    )


if __name__ == "__main__":
    main()