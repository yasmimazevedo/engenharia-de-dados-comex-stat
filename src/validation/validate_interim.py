import csv
from pathlib import Path


ANOS = (
    2024,
    2025,
    2026,
)

UF_ESPERADA = "MG"

MESES_ESPERADOS = {
    1,
    2,
    3,
    4,
    5,
    6,
}

COLUNAS_OBRIGATORIAS = {
    "FLUXO",
    "ARQUIVO_ORIGEM",
    "CO_ANO",
    "CO_MES",
    "CO_NCM",
    "CO_UNID",
    "CO_PAIS",
    "SG_UF_NCM",
    "CO_VIA",
    "CO_URF",
    "QT_ESTAT",
    "KG_LIQUIDO",
    "VL_FOB",
}

LIMITE_EXEMPLOS_ERROS = 5


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_inteiro(valor: int) -> str:
    """
    Formata um número inteiro com separador
    de milhares no padrão brasileiro.
    """

    return f"{valor:,}".replace(",", ".")


def montar_configuracoes(
    raiz_projeto: Path,
) -> list[dict]:
    """
    Monta as configurações dos seis arquivos
    intermediários.
    """

    configuracoes = []

    for ano in ANOS:
        configuracoes.append(
            {
                "fluxo": "EXPORTACAO",
                "ano": ano,
                "arquivo_origem": f"EXP_{ano}.csv",
                "caminho": (
                    raiz_projeto
                    / "data"
                    / "interim"
                    / "exportacao_mg"
                    / f"EXP_MG_{ano}_01_06.csv"
                ),
            }
        )

        configuracoes.append(
            {
                "fluxo": "IMPORTACAO",
                "ano": ano,
                "arquivo_origem": f"IMP_{ano}.csv",
                "caminho": (
                    raiz_projeto
                    / "data"
                    / "interim"
                    / "importacao_mg"
                    / f"IMP_MG_{ano}_01_06.csv"
                ),
            }
        )

    return configuracoes


def converter_inteiro_nao_negativo(
    valor: str,
    nome_coluna: str,
) -> int:
    """
    Converte um valor textual em inteiro e verifica
    se ele não é negativo.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        raise ValueError(
            f"{nome_coluna} está vazio."
        )

    numero = int(valor_limpo)

    if numero < 0:
        raise ValueError(
            f"{nome_coluna} possui valor negativo: {numero}."
        )

    return numero


def validar_arquivo(
    fluxo_esperado: str,
    ano_esperado: int,
    arquivo_origem_esperado: str,
    caminho: Path,
) -> dict:
    """
    Valida um arquivo da camada interim.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho}"
        )

    total_linhas = 0
    total_erros = 0

    meses_encontrados = set()

    total_valor_fob = 0
    total_peso_liquido = 0

    exemplos_erros = []

    print("\n" + "=" * 70)
    print(f"Validando: {caminho.name}")
    print(f"Fluxo esperado: {fluxo_esperado}")
    print(f"Ano esperado: {ano_esperado}")
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
                f"O arquivo {caminho.name} não possui cabeçalho."
            )

        leitor.fieldnames = [
            coluna.strip()
            for coluna in leitor.fieldnames
        ]

        colunas_encontradas = set(
            leitor.fieldnames
        )

        colunas_ausentes = (
            COLUNAS_OBRIGATORIAS
            - colunas_encontradas
        )

        if colunas_ausentes:
            raise ValueError(
                "Colunas obrigatórias ausentes: "
                f"{sorted(colunas_ausentes)}"
            )

        for numero_linha, linha in enumerate(
            leitor,
            start=2,
        ):
            total_linhas += 1

            try:
                fluxo = (
                    linha["FLUXO"]
                    .strip()
                    .upper()
                )

                if fluxo != fluxo_esperado:
                    raise ValueError(
                        f"FLUXO deveria ser "
                        f"{fluxo_esperado}, mas é {fluxo}."
                    )

                arquivo_origem = (
                    linha["ARQUIVO_ORIGEM"]
                    .strip()
                )

                if (
                    arquivo_origem
                    != arquivo_origem_esperado
                ):
                    raise ValueError(
                        "ARQUIVO_ORIGEM deveria ser "
                        f"{arquivo_origem_esperado}, "
                        f"mas é {arquivo_origem}."
                    )

                ano = int(
                    linha["CO_ANO"].strip()
                )

                if ano != ano_esperado:
                    raise ValueError(
                        f"CO_ANO deveria ser "
                        f"{ano_esperado}, mas é {ano}."
                    )

                mes = int(
                    linha["CO_MES"].strip()
                )

                if mes not in MESES_ESPERADOS:
                    raise ValueError(
                        f"CO_MES fora do intervalo: {mes}."
                    )

                meses_encontrados.add(mes)

                uf = (
                    linha["SG_UF_NCM"]
                    .strip()
                    .upper()
                )

                if uf != UF_ESPERADA:
                    raise ValueError(
                        f"SG_UF_NCM deveria ser MG, "
                        f"mas é {uf}."
                    )

                valor_fob = (
                    converter_inteiro_nao_negativo(
                        linha["VL_FOB"],
                        "VL_FOB",
                    )
                )

                peso_liquido = (
                    converter_inteiro_nao_negativo(
                        linha["KG_LIQUIDO"],
                        "KG_LIQUIDO",
                    )
                )

                total_valor_fob += valor_fob
                total_peso_liquido += peso_liquido

            except (
                ValueError,
                TypeError,
            ) as erro:
                total_erros += 1

                if (
                    len(exemplos_erros)
                    < LIMITE_EXEMPLOS_ERROS
                ):
                    exemplos_erros.append(
                        f"Linha {numero_linha}: {erro}"
                    )

    if total_linhas == 0:
        raise ValueError(
            f"O arquivo {caminho.name} está vazio."
        )

    meses_ausentes = (
        MESES_ESPERADOS
        - meses_encontrados
    )

    if meses_ausentes:
        total_erros += 1

        exemplos_erros.append(
            "Meses ausentes no arquivo: "
            f"{sorted(meses_ausentes)}"
        )

    if total_erros > 0:
        print("\nArquivo reprovado na validação.")
        print(
            "Quantidade de problemas encontrados:",
            total_erros,
        )

        for exemplo in exemplos_erros:
            print("-", exemplo)

        raise ValueError(
            f"O arquivo {caminho.name} possui "
            "problemas de qualidade."
        )

    print("\nArquivo aprovado!")
    print(
        "Linhas:",
        formatar_inteiro(total_linhas),
    )
    print(
        "Meses encontrados:",
        sorted(meses_encontrados),
    )
    print(
        "Valor FOB total:",
        formatar_inteiro(total_valor_fob),
    )
    print(
        "Peso líquido total:",
        formatar_inteiro(total_peso_liquido),
    )

    return {
        "fluxo": fluxo_esperado,
        "ano": ano_esperado,
        "arquivo": caminho.name,
        "linhas": total_linhas,
        "valor_fob": total_valor_fob,
        "peso_liquido": total_peso_liquido,
    }


def exibir_resumo(
    resultados: list[dict],
) -> None:
    """
    Exibe o resumo geral da validação.
    """

    print("\n" + "=" * 90)
    print("RESUMO GERAL DA VALIDAÇÃO")
    print("=" * 90)

    for resultado in resultados:
        print(
            f"{resultado['fluxo']:<11} | "
            f"{resultado['ano']} | "
            f"linhas: "
            f"{formatar_inteiro(resultado['linhas']):>10} | "
            f"FOB: "
            f"{formatar_inteiro(resultado['valor_fob']):>18} | "
            f"KG: "
            f"{formatar_inteiro(resultado['peso_liquido']):>18}"
        )


def main() -> None:
    """
    Executa a validação dos seis arquivos.
    """

    raiz_projeto = obter_raiz_projeto()

    configuracoes = montar_configuracoes(
        raiz_projeto
    )

    resultados = []

    try:
        for configuracao in configuracoes:
            resultado = validar_arquivo(
                fluxo_esperado=configuracao["fluxo"],
                ano_esperado=configuracao["ano"],
                arquivo_origem_esperado=(
                    configuracao["arquivo_origem"]
                ),
                caminho=configuracao["caminho"],
            )

            resultados.append(resultado)

    except (
        FileNotFoundError,
        ValueError,
        UnicodeError,
        csv.Error,
        OSError,
    ) as erro:
        print("\nA validação não foi concluída.")
        print("Motivo:", erro)

        return

    exibir_resumo(resultados)

    print(
        "\nTodos os arquivos foram aprovados "
        "na validação."
    )


if __name__ == "__main__":
    main()