import csv
from collections import Counter
from pathlib import Path


ANOS = (
    2024,
    2025,
    2026,
)

PRODUTOS_SEM_HIERARQUIA = {
    "38273900",
    "81093900",
    "97053100",
    "81126100",
    "85492100",
}


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_inteiro(valor: int) -> str:
    """
    Formata um número inteiro usando ponto
    como separador de milhares.
    """

    return f"{valor:,}".replace(",", ".")


def converter_inteiro(valor: str) -> int:
    """
    Converte um texto numérico em inteiro.

    Valores vazios são considerados zero.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        return 0

    return int(valor_limpo)


def montar_arquivos_interim(
    raiz_projeto: Path,
) -> list[Path]:
    """
    Retorna os caminhos dos seis arquivos
    da camada interim.
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


def analisar_arquivo(
    caminho: Path,
    resultado_geral: dict,
) -> None:
    """
    Procura os produtos sem hierarquia em um
    arquivo da camada interim.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho}"
        )

    ocorrencias_arquivo = Counter()

    print("\n" + "=" * 70)
    print(f"Analisando: {caminho.name}")
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

        colunas_obrigatorias = {
            "CO_NCM",
            "FLUXO",
            "CO_ANO",
            "CO_MES",
            "VL_FOB",
            "KG_LIQUIDO",
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
            codigo_ncm = linha.get(
                "CO_NCM",
                "",
            ).strip()

            if codigo_ncm not in PRODUTOS_SEM_HIERARQUIA:
                continue

            ocorrencias_arquivo[codigo_ncm] += 1

            resultado = resultado_geral[codigo_ncm]

            resultado["linhas"] += 1

            resultado["valor_fob"] += converter_inteiro(
                linha.get(
                    "VL_FOB",
                    "",
                )
            )

            resultado["peso_liquido"] += converter_inteiro(
                linha.get(
                    "KG_LIQUIDO",
                    "",
                )
            )

            chave_periodo = (
                linha.get(
                    "FLUXO",
                    "",
                ).strip(),
                linha.get(
                    "CO_ANO",
                    "",
                ).strip(),
                linha.get(
                    "CO_MES",
                    "",
                ).strip(),
            )

            resultado["periodos"][chave_periodo] += 1

    if not ocorrencias_arquivo:
        print(
            "Nenhum dos cinco produtos aparece "
            "neste arquivo."
        )

        return

    print("Produtos encontrados:")

    for codigo, quantidade in ocorrencias_arquivo.items():
        print(
            f"- NCM {codigo}: "
            f"{formatar_inteiro(quantidade)} linhas"
        )


def exibir_resumo(
    resultado_geral: dict,
) -> None:
    """
    Exibe o resultado consolidado da procura.
    """

    print("\n" + "=" * 80)
    print("RESUMO DOS PRODUTOS SEM HIERARQUIA")
    print("=" * 80)

    total_linhas_afetadas = 0

    for codigo_ncm in sorted(
        PRODUTOS_SEM_HIERARQUIA
    ):
        resultado = resultado_geral[
            codigo_ncm
        ]

        print(f"\nNCM: {codigo_ncm}")

        if resultado["linhas"] == 0:
            print(
                "Situação: não aparece no recorte "
                "de Minas Gerais."
            )

            continue

        total_linhas_afetadas += (
            resultado["linhas"]
        )

        print(
            "Linhas encontradas:",
            formatar_inteiro(
                resultado["linhas"]
            ),
        )

        print(
            "Valor FOB total:",
            formatar_inteiro(
                resultado["valor_fob"]
            ),
        )

        print(
            "Peso líquido total:",
            formatar_inteiro(
                resultado["peso_liquido"]
            ),
        )

        print("Ocorrências por período:")

        for chave, quantidade in sorted(
            resultado["periodos"].items()
        ):
            fluxo, ano, mes = chave

            print(
                f"  {fluxo} | "
                f"{ano}-{int(mes):02d} | "
                f"{formatar_inteiro(quantidade)} linhas"
            )

    print("\n" + "-" * 80)

    print(
        "Total de linhas afetadas:",
        formatar_inteiro(
            total_linhas_afetadas
        ),
    )

    if total_linhas_afetadas == 0:
        print(
            "Os cinco produtos não afetam "
            "o conjunto analisado."
        )

    else:
        print(
            "Existem registros desses produtos. "
            "A hierarquia ausente deverá ser tratada "
            "antes da carga final."
        )


def main() -> None:
    """
    Executa a busca pelos produtos sem hierarquia.
    """

    raiz_projeto = obter_raiz_projeto()

    resultado_geral = {
        codigo_ncm: {
            "linhas": 0,
            "valor_fob": 0,
            "peso_liquido": 0,
            "periodos": Counter(),
        }
        for codigo_ncm
        in PRODUTOS_SEM_HIERARQUIA
    }

    try:
        arquivos = montar_arquivos_interim(
            raiz_projeto
        )

        for caminho in arquivos:
            analisar_arquivo(
                caminho=caminho,
                resultado_geral=resultado_geral,
            )

        exibir_resumo(
            resultado_geral
        )

    except (
        FileNotFoundError,
        ValueError,
        UnicodeError,
        csv.Error,
        OSError,
    ) as erro:
        print("\nA verificação não foi concluída.")
        print("Motivo:", erro)


if __name__ == "__main__":
    main()