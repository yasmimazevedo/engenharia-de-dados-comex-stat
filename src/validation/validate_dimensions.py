import csv
from collections import Counter
from pathlib import Path


ANOS = (
    2024,
    2025,
    2026,
)

LIMITE_EXEMPLOS = 10


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_inteiro(valor: int) -> str:
    """
    Formata um número com ponto como
    separador de milhares.
    """

    return f"{valor:,}".replace(",", ".")


def normalizar_numero_texto(valor: str) -> str:
    """
    Normaliza números armazenados como texto.

    Exemplos:
    "01"   -> "1"
    "004"  -> "4"
    "2024" -> "2024"
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        return ""

    return str(int(valor_limpo))


def carregar_chaves(
    caminho: Path,
    coluna_chave: str,
) -> set[str]:
    """
    Carrega os códigos únicos de uma dimensão.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Dimensão não encontrada: {caminho}"
        )

    chaves = set()

    with caminho.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo:

        leitor = csv.DictReader(
            arquivo,
            delimiter=";",
        )

        if leitor.fieldnames is None:
            raise ValueError(
                f"{caminho.name} não possui cabeçalho."
            )

        leitor.fieldnames = [
            coluna.strip()
            for coluna in leitor.fieldnames
        ]

        if coluna_chave not in leitor.fieldnames:
            raise ValueError(
                f"A coluna {coluna_chave} não existe "
                f"em {caminho.name}."
            )

        for linha in leitor:
            codigo = (
                linha.get(
                    coluna_chave,
                    "",
                )
                .strip()
            )

            if codigo:
                chaves.add(codigo)

    print(
        f"{caminho.name:<20} | "
        f"chaves carregadas: "
        f"{formatar_inteiro(len(chaves))}"
    )

    return chaves


def carregar_chaves_tempo(
    caminho: Path,
) -> set[tuple[str, str]]:
    """
    Carrega os pares de ano e mês da dimensão tempo.

    Ano e mês são normalizados para evitar diferenças
    como "04" e "4".
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Dimensão não encontrada: {caminho}"
        )

    chaves = set()

    with caminho.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo:

        leitor = csv.DictReader(
            arquivo,
            delimiter=";",
        )

        if leitor.fieldnames is None:
            raise ValueError(
                f"{caminho.name} não possui cabeçalho."
            )

        leitor.fieldnames = [
            coluna.strip()
            for coluna in leitor.fieldnames
        ]

        colunas_obrigatorias = {
            "ano",
            "mes",
        }

        colunas_ausentes = (
            colunas_obrigatorias
            - set(leitor.fieldnames)
        )

        if colunas_ausentes:
            raise ValueError(
                f"Colunas ausentes em {caminho.name}: "
                f"{sorted(colunas_ausentes)}"
            )

        for linha in leitor:
            ano = normalizar_numero_texto(
                linha.get(
                    "ano",
                    "",
                )
            )

            mes = normalizar_numero_texto(
                linha.get(
                    "mes",
                    "",
                )
            )

            if ano and mes:
                chaves.add(
                    (
                        ano,
                        mes,
                    )
                )

    print(
        f"{caminho.name:<20} | "
        f"chaves carregadas: "
        f"{formatar_inteiro(len(chaves))}"
    )

    return chaves


def montar_arquivos_interim(
    raiz_projeto: Path,
) -> list[Path]:
    """
    Monta a lista dos seis arquivos intermediários.
    """

    arquivos = []

    for ano in ANOS:
        arquivos.append(
            raiz_projeto
            / "data"
            / "interim"
            / "exportacao_mg"
            / f"EXP_MG_{ano}_01_06.csv"
        )

        arquivos.append(
            raiz_projeto
            / "data"
            / "interim"
            / "importacao_mg"
            / f"IMP_MG_{ano}_01_06.csv"
        )

    return arquivos


def validar_arquivo(
    caminho: Path,
    dimensoes: dict,
) -> dict:
    """
    Verifica se todos os códigos do arquivo possuem
    correspondência nas dimensões.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho}"
        )

    faltantes = {
        "produto": Counter(),
        "pais": Counter(),
        "via": Counter(),
        "urf": Counter(),
        "unidade": Counter(),
        "tempo": Counter(),
    }

    total_linhas = 0

    print("\n" + "=" * 70)
    print(f"Validando cobertura: {caminho.name}")
    print("=" * 70)

    with caminho.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo:

        leitor = csv.DictReader(
            arquivo,
            delimiter=";",
        )

        if leitor.fieldnames is None:
            raise ValueError(
                f"{caminho.name} não possui cabeçalho."
            )

        leitor.fieldnames = [
            coluna.strip()
            for coluna in leitor.fieldnames
        ]

        colunas_obrigatorias = {
            "CO_NCM",
            "CO_PAIS",
            "CO_VIA",
            "CO_URF",
            "CO_UNID",
            "CO_ANO",
            "CO_MES",
        }

        colunas_ausentes = (
            colunas_obrigatorias
            - set(leitor.fieldnames)
        )

        if colunas_ausentes:
            raise ValueError(
                f"Colunas ausentes em {caminho.name}: "
                f"{sorted(colunas_ausentes)}"
            )

        for linha in leitor:
            total_linhas += 1

            codigo_ncm = linha.get(
                "CO_NCM",
                "",
            ).strip()

            codigo_pais = linha.get(
                "CO_PAIS",
                "",
            ).strip()

            codigo_via = linha.get(
                "CO_VIA",
                "",
            ).strip()

            codigo_urf = linha.get(
                "CO_URF",
                "",
            ).strip()

            codigo_unidade = linha.get(
                "CO_UNID",
                "",
            ).strip()

            ano = normalizar_numero_texto(
                linha.get(
                    "CO_ANO",
                    "",
                )
            )

            mes = normalizar_numero_texto(
                linha.get(
                    "CO_MES",
                    "",
                )
            )

            if codigo_ncm not in dimensoes["produto"]:
                faltantes["produto"][codigo_ncm] += 1

            if codigo_pais not in dimensoes["pais"]:
                faltantes["pais"][codigo_pais] += 1

            if codigo_via not in dimensoes["via"]:
                faltantes["via"][codigo_via] += 1

            if codigo_urf not in dimensoes["urf"]:
                faltantes["urf"][codigo_urf] += 1

            if codigo_unidade not in dimensoes["unidade"]:
                faltantes["unidade"][codigo_unidade] += 1

            if (
                ano,
                mes,
            ) not in dimensoes["tempo"]:

                chave_tempo = (
                    f"{ano}-{int(mes):02d}"
                    if ano and mes
                    else "<tempo vazio>"
                )

                faltantes["tempo"][
                    chave_tempo
                ] += 1

    total_problemas = sum(
        sum(contador.values())
        for contador in faltantes.values()
    )

    print(
        "Linhas analisadas:",
        formatar_inteiro(total_linhas),
    )

    if total_problemas == 0:
        print(
            "Resultado: todos os códigos possuem "
            "correspondência."
        )

    else:
        print(
            "Resultado: foram encontradas "
            "correspondências ausentes."
        )

        for nome_dimensao, contador in faltantes.items():
            if not contador:
                continue

            print(
                f"\nDimensão com problema: "
                f"{nome_dimensao}"
            )

            print(
                "Códigos distintos ausentes:",
                formatar_inteiro(
                    len(contador)
                ),
            )

            print(
                "Linhas afetadas:",
                formatar_inteiro(
                    sum(contador.values())
                ),
            )

            print("Exemplos:")

            for codigo, quantidade in contador.most_common(
                LIMITE_EXEMPLOS
            ):
                codigo_exibicao = (
                    codigo
                    if codigo
                    else "<vazio>"
                )

                print(
                    f"  {codigo_exibicao}: "
                    f"{formatar_inteiro(quantidade)} linhas"
                )

    return {
        "arquivo": caminho.name,
        "linhas": total_linhas,
        "faltantes": faltantes,
        "total_problemas": total_problemas,
    }


def listar_produtos_sem_hierarquia(
    caminho_dim_produto: Path,
) -> None:
    """
    Mostra produtos da dimensão que não receberam
    descrição de hierarquia SH.
    """

    produtos = []

    with caminho_dim_produto.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo:

        leitor = csv.DictReader(
            arquivo,
            delimiter=";",
        )

        if leitor.fieldnames is None:
            raise ValueError(
                f"{caminho_dim_produto.name} "
                "não possui cabeçalho."
            )

        for linha in leitor:
            codigo_sh6 = linha.get(
                "codigo_sh6",
                "",
            ).strip()

            descricao_sh6 = linha.get(
                "descricao_sh6",
                "",
            ).strip()

            if codigo_sh6 and not descricao_sh6:
                produtos.append(
                    {
                        "codigo_ncm": linha.get(
                            "codigo_ncm",
                            "",
                        ).strip(),
                        "descricao_ncm": linha.get(
                            "descricao_ncm",
                            "",
                        ).strip(),
                        "codigo_sh6": codigo_sh6,
                    }
                )

    print("\n" + "=" * 70)
    print("PRODUTOS SEM HIERARQUIA SH")
    print("=" * 70)

    if not produtos:
        print(
            "Nenhum produto sem hierarquia "
            "foi encontrado."
        )

        return

    print(
        "Quantidade:",
        formatar_inteiro(len(produtos)),
    )

    for produto in produtos:
        print(
            f"\nNCM: {produto['codigo_ncm']}"
        )

        print(
            f"SH6: {produto['codigo_sh6']}"
        )

        print(
            f"Descrição: "
            f"{produto['descricao_ncm']}"
        )


def exibir_resumo(
    resultados: list[dict],
) -> None:
    """
    Exibe o resultado consolidado da validação.
    """

    print("\n" + "=" * 80)
    print("RESUMO DA COBERTURA DAS DIMENSÕES")
    print("=" * 80)

    total_linhas = 0
    total_problemas = 0

    for resultado in resultados:
        total_linhas += resultado["linhas"]

        total_problemas += (
            resultado["total_problemas"]
        )

        situacao = (
            "APROVADO"
            if resultado["total_problemas"] == 0
            else "REPROVADO"
        )

        print(
            f"{resultado['arquivo']:<30} | "
            f"linhas: "
            f"{formatar_inteiro(resultado['linhas']):>10} | "
            f"{situacao}"
        )

    print("\nTotal de linhas analisadas:")
    print(
        formatar_inteiro(total_linhas)
    )

    print(
        "Total de correspondências ausentes:"
    )

    print(
        formatar_inteiro(total_problemas)
    )

    if total_problemas == 0:
        print(
            "\nTodas as dimensões cobrem os códigos "
            "presentes na camada interim."
        )

    else:
        print(
            "\nExistem códigos sem correspondência. "
            "Eles deverão ser tratados antes da carga."
        )


def main() -> None:
    """
    Executa a validação de cobertura das dimensões.
    """

    raiz_projeto = obter_raiz_projeto()

    pasta_dimensoes = (
        raiz_projeto
        / "data"
        / "processed"
        / "dimensions"
    )

    try:
        print("=" * 70)
        print("CARREGANDO CHAVES DAS DIMENSÕES")
        print("=" * 70)

        dimensoes = {
            "produto": carregar_chaves(
                pasta_dimensoes
                / "dim_produto.csv",
                "codigo_ncm",
            ),
            "pais": carregar_chaves(
                pasta_dimensoes
                / "dim_pais.csv",
                "codigo_pais",
            ),
            "via": carregar_chaves(
                pasta_dimensoes
                / "dim_via.csv",
                "codigo_via",
            ),
            "urf": carregar_chaves(
                pasta_dimensoes
                / "dim_urf.csv",
                "codigo_urf",
            ),
            "unidade": carregar_chaves(
                pasta_dimensoes
                / "dim_unidade.csv",
                "codigo_unidade",
            ),
            "tempo": carregar_chaves_tempo(
                pasta_dimensoes
                / "dim_tempo.csv"
            ),
        }

        resultados = []

        arquivos_interim = montar_arquivos_interim(
            raiz_projeto
        )

        for caminho in arquivos_interim:
            resultado = validar_arquivo(
                caminho=caminho,
                dimensoes=dimensoes,
            )

            resultados.append(
                resultado
            )

        exibir_resumo(
            resultados
        )

        listar_produtos_sem_hierarquia(
            pasta_dimensoes
            / "dim_produto.csv"
        )

    except (
        FileNotFoundError,
        ValueError,
        UnicodeError,
        csv.Error,
        OSError,
    ) as erro:
        print(
            "\nA validação não foi concluída."
        )

        print(
            "Motivo:",
            erro,
        )


if __name__ == "__main__":
    main()