import csv
import sys
from collections import defaultdict
from datetime import date
from decimal import Decimal, InvalidOperation
from pathlib import Path


TOTAL_LINHAS_ESPERADO = 434_837

LIMITE_EXEMPLOS_ERROS = 10


COLUNAS_ESPERADAS = [
    "fluxo",
    "data_referencia",
    "ano",
    "mes",
    "codigo_ncm",
    "codigo_unidade",
    "codigo_pais",
    "sigla_uf",
    "codigo_via",
    "codigo_urf",
    "quantidade_estatistica",
    "peso_liquido_kg",
    "valor_fob_usd",
    "valor_frete_usd",
    "valor_seguro_usd",
    "valor_cif_usd",
    "arquivo_origem",
]


TOTAIS_ESPERADOS = {
    ("EXPORTACAO", 2024): {
        "linhas": 38_523,
        "valor_fob_usd": 20_911_352_174,
        "peso_liquido_kg": 99_649_819_621,
    },
    ("IMPORTACAO", 2024): {
        "linhas": 95_144,
        "valor_fob_usd": 7_529_883_730,
        "peso_liquido_kg": 6_047_223_169,
    },
    ("EXPORTACAO", 2025): {
        "linhas": 40_949,
        "valor_fob_usd": 21_968_821_625,
        "peso_liquido_kg": 96_114_357_063,
    },
    ("IMPORTACAO", 2025): {
        "linhas": 103_594,
        "valor_fob_usd": 8_603_498_628,
        "peso_liquido_kg": 6_572_579_902,
    },
    ("EXPORTACAO", 2026): {
        "linhas": 40_884,
        "valor_fob_usd": 21_920_923_140,
        "peso_liquido_kg": 91_660_659_745,
    },
    ("IMPORTACAO", 2026): {
        "linhas": 115_743,
        "valor_fob_usd": 9_641_041_374,
        "peso_liquido_kg": 6_420_656_814,
    },
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


def converter_inteiro_nao_negativo(
    valor: str,
    nome_coluna: str,
) -> int:
    """
    Converte um texto em inteiro e verifica
    se o número não é negativo.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        raise ValueError(
            f"{nome_coluna} está vazio."
        )

    try:
        numero = int(valor_limpo)

    except ValueError as erro:
        raise ValueError(
            f"{nome_coluna} não contém um inteiro válido: "
            f"{valor_limpo}"
        ) from erro

    if numero < 0:
        raise ValueError(
            f"{nome_coluna} possui valor negativo: "
            f"{numero}"
        )

    return numero


def converter_decimal_nao_negativo(
    valor: str,
    nome_coluna: str,
) -> Decimal:
    """
    Converte um texto em Decimal e verifica
    se o valor não é negativo.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        raise ValueError(
            f"{nome_coluna} está vazio."
        )

    try:
        numero = Decimal(
            valor_limpo.replace(",", ".")
        )

    except InvalidOperation as erro:
        raise ValueError(
            f"{nome_coluna} não contém um número válido: "
            f"{valor_limpo}"
        ) from erro

    if numero < 0:
        raise ValueError(
            f"{nome_coluna} possui valor negativo: "
            f"{valor_limpo}"
        )

    return numero


def verificar_codigo_obrigatorio(
    linha: dict[str, str],
    nome_coluna: str,
) -> str:
    """
    Verifica se um código obrigatório está preenchido.

    O código permanece como texto para preservar
    possíveis zeros à esquerda.
    """

    valor = linha.get(
        nome_coluna,
        "",
    ).strip()

    if valor == "":
        raise ValueError(
            f"{nome_coluna} está vazio."
        )

    return valor


def validar_data_referencia(
    valor: str,
    ano: int,
    mes: int,
) -> None:
    """
    Verifica se a data possui formato válido, utiliza
    o primeiro dia do mês e corresponde ao ano e mês
    armazenados na linha.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        raise ValueError(
            "data_referencia está vazia."
        )

    try:
        data_convertida = date.fromisoformat(
            valor_limpo
        )

    except ValueError as erro:
        raise ValueError(
            "data_referencia possui formato inválido: "
            f"{valor_limpo}"
        ) from erro

    if data_convertida.day != 1:
        raise ValueError(
            "data_referencia deveria utilizar o "
            f"primeiro dia do mês: {valor_limpo}"
        )

    if data_convertida.year != ano:
        raise ValueError(
            "O ano de data_referencia não corresponde "
            f"à coluna ano: {valor_limpo}"
        )

    if data_convertida.month != mes:
        raise ValueError(
            "O mês de data_referencia não corresponde "
            f"à coluna mes: {valor_limpo}"
        )


def validar_arquivo_origem(
    arquivo_origem: str,
    fluxo: str,
    ano: int,
) -> None:
    """
    Confirma se o nome do arquivo de origem combina
    com o fluxo e o ano da linha.
    """

    prefixo = (
        "EXP"
        if fluxo == "EXPORTACAO"
        else "IMP"
    )

    arquivo_esperado = (
        f"{prefixo}_{ano}.csv"
    )

    if arquivo_origem != arquivo_esperado:
        raise ValueError(
            "arquivo_origem deveria ser "
            f"{arquivo_esperado}, mas é "
            f"{arquivo_origem}."
        )


def validar_metricas_importacao(
    linha: dict[str, str],
    valor_fob_usd: int,
) -> None:
    """
    Verifica frete, seguro e CIF de uma linha
    de importação.
    """

    valor_frete_usd = (
        converter_inteiro_nao_negativo(
            linha.get(
                "valor_frete_usd",
                "",
            ),
            "valor_frete_usd",
        )
    )

    valor_seguro_usd = (
        converter_inteiro_nao_negativo(
            linha.get(
                "valor_seguro_usd",
                "",
            ),
            "valor_seguro_usd",
        )
    )

    valor_cif_usd = (
        converter_inteiro_nao_negativo(
            linha.get(
                "valor_cif_usd",
                "",
            ),
            "valor_cif_usd",
        )
    )

    valor_cif_calculado = (
        valor_fob_usd
        + valor_frete_usd
        + valor_seguro_usd
    )

    if valor_cif_usd != valor_cif_calculado:
        raise ValueError(
            "valor_cif_usd não corresponde à soma "
            "de FOB, frete e seguro. "
            f"Informado: {valor_cif_usd}. "
            f"Calculado: {valor_cif_calculado}."
        )


def validar_metricas_exportacao(
    linha: dict[str, str],
) -> None:
    """
    Verifica se campos exclusivos de importação
    estão vazios nas exportações.
    """

    colunas_exclusivas_importacao = (
        "valor_frete_usd",
        "valor_seguro_usd",
        "valor_cif_usd",
    )

    for coluna in colunas_exclusivas_importacao:
        valor = linha.get(
            coluna,
            "",
        ).strip()

        if valor != "":
            raise ValueError(
                f"{coluna} deveria estar vazio "
                "em uma exportação."
            )


def validar_linha(
    linha: dict[str, str],
) -> tuple[str, int, int, int]:
    """
    Valida uma linha e retorna os valores usados
    para calcular o resumo da tabela fato.
    """

    fluxo = linha.get(
        "fluxo",
        "",
    ).strip().upper()

    if fluxo not in {
        "EXPORTACAO",
        "IMPORTACAO",
    }:
        raise ValueError(
            f"fluxo inválido: {fluxo}"
        )

    ano = converter_inteiro_nao_negativo(
        linha.get(
            "ano",
            "",
        ),
        "ano",
    )

    if ano not in {
        2024,
        2025,
        2026,
    }:
        raise ValueError(
            f"ano fora do período analisado: {ano}"
        )

    mes = converter_inteiro_nao_negativo(
        linha.get(
            "mes",
            "",
        ),
        "mes",
    )

    if mes < 1 or mes > 6:
        raise ValueError(
            f"mês fora do período analisado: {mes}"
        )

    validar_data_referencia(
        valor=linha.get(
            "data_referencia",
            "",
        ),
        ano=ano,
        mes=mes,
    )

    verificar_codigo_obrigatorio(
        linha,
        "codigo_ncm",
    )

    verificar_codigo_obrigatorio(
        linha,
        "codigo_unidade",
    )

    verificar_codigo_obrigatorio(
        linha,
        "codigo_pais",
    )

    verificar_codigo_obrigatorio(
        linha,
        "codigo_via",
    )

    verificar_codigo_obrigatorio(
        linha,
        "codigo_urf",
    )

    sigla_uf = linha.get(
        "sigla_uf",
        "",
    ).strip().upper()

    if sigla_uf != "MG":
        raise ValueError(
            f"sigla_uf deveria ser MG, mas é "
            f"{sigla_uf}."
        )

    converter_decimal_nao_negativo(
        linha.get(
            "quantidade_estatistica",
            "",
        ),
        "quantidade_estatistica",
    )

    peso_liquido_kg = (
        converter_inteiro_nao_negativo(
            linha.get(
                "peso_liquido_kg",
                "",
            ),
            "peso_liquido_kg",
        )
    )

    valor_fob_usd = (
        converter_inteiro_nao_negativo(
            linha.get(
                "valor_fob_usd",
                "",
            ),
            "valor_fob_usd",
        )
    )

    arquivo_origem = linha.get(
        "arquivo_origem",
        "",
    ).strip()

    validar_arquivo_origem(
        arquivo_origem=arquivo_origem,
        fluxo=fluxo,
        ano=ano,
    )

    if fluxo == "EXPORTACAO":
        validar_metricas_exportacao(
            linha=linha
        )

    else:
        validar_metricas_importacao(
            linha=linha,
            valor_fob_usd=valor_fob_usd,
        )

    return (
        fluxo,
        ano,
        valor_fob_usd,
        peso_liquido_kg,
    )


def validar_cabecalho(
    leitor: csv.DictReader,
) -> None:
    """
    Verifica se o cabeçalho corresponde à estrutura
    esperada da tabela fato.
    """

    if leitor.fieldnames is None:
        raise ValueError(
            "A fato_comex não possui cabeçalho."
        )

    leitor.fieldnames = [
        coluna.strip()
        for coluna in leitor.fieldnames
    ]

    colunas_encontradas = set(
        leitor.fieldnames
    )

    colunas_ausentes = (
        set(COLUNAS_ESPERADAS)
        - colunas_encontradas
    )

    colunas_extras = (
        colunas_encontradas
        - set(COLUNAS_ESPERADAS)
    )

    if colunas_ausentes:
        raise ValueError(
            "Colunas ausentes na fato_comex: "
            f"{sorted(colunas_ausentes)}"
        )

    if colunas_extras:
        raise ValueError(
            "Colunas inesperadas na fato_comex: "
            f"{sorted(colunas_extras)}"
        )


def comparar_resumo(
    resumo_encontrado: dict,
) -> list[str]:
    """
    Compara os totais encontrados com os valores
    já validados na camada interim.
    """

    erros = []

    for chave, esperado in TOTAIS_ESPERADOS.items():
        encontrado = resumo_encontrado.get(
            chave,
            {
                "linhas": 0,
                "valor_fob_usd": 0,
                "peso_liquido_kg": 0,
            },
        )

        fluxo, ano = chave

        for metrica in (
            "linhas",
            "valor_fob_usd",
            "peso_liquido_kg",
        ):
            valor_esperado = esperado[
                metrica
            ]

            valor_encontrado = encontrado[
                metrica
            ]

            if valor_encontrado != valor_esperado:
                erros.append(
                    f"{fluxo} {ano}: {metrica} deveria "
                    f"ser {valor_esperado}, mas é "
                    f"{valor_encontrado}."
                )

    chaves_inesperadas = (
        set(resumo_encontrado)
        - set(TOTAIS_ESPERADOS)
    )

    for fluxo, ano in sorted(
        chaves_inesperadas
    ):
        erros.append(
            "Foi encontrada uma combinação inesperada: "
            f"{fluxo} {ano}."
        )

    return erros


def exibir_resumo(
    resumo: dict,
) -> None:
    """
    Exibe os totais encontrados na tabela fato.
    """

    print("\n" + "=" * 90)
    print("RESUMO ENCONTRADO NA FATO COMEX")
    print("=" * 90)

    for chave in sorted(
        resumo,
        key=lambda item: (
            item[1],
            item[0],
        ),
    ):
        fluxo, ano = chave

        resultado = resumo[chave]

        print(
            f"{fluxo:<11} | "
            f"{ano} | "
            f"linhas: "
            f"{formatar_inteiro(resultado['linhas']):>10} | "
            f"FOB: "
            f"{formatar_inteiro(resultado['valor_fob_usd']):>18} | "
            f"KG: "
            f"{formatar_inteiro(resultado['peso_liquido_kg']):>18}"
        )


def validar_fato_comex(
    caminho: Path,
) -> bool:
    """
    Executa todas as validações da tabela fato.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho}"
        )

    resumo = defaultdict(
        lambda: {
            "linhas": 0,
            "valor_fob_usd": 0,
            "peso_liquido_kg": 0,
        }
    )

    total_linhas = 0
    total_linhas_invalidas = 0
    exemplos_erros = []

    print("=" * 70)
    print("VALIDANDO A FATO COMEX")
    print("=" * 70)

    print("Arquivo:")
    print(caminho)

    with caminho.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo:

        leitor = csv.DictReader(
            arquivo,
            delimiter=";",
        )

        validar_cabecalho(
            leitor=leitor
        )

        for numero_linha, linha in enumerate(
            leitor,
            start=2,
        ):
            total_linhas += 1

            try:
                (
                    fluxo,
                    ano,
                    valor_fob_usd,
                    peso_liquido_kg,
                ) = validar_linha(
                    linha=linha
                )

                chave = (
                    fluxo,
                    ano,
                )

                resumo[chave]["linhas"] += 1

                resumo[chave][
                    "valor_fob_usd"
                ] += valor_fob_usd

                resumo[chave][
                    "peso_liquido_kg"
                ] += peso_liquido_kg

            except (
                ValueError,
                TypeError,
            ) as erro:
                total_linhas_invalidas += 1

                if (
                    len(exemplos_erros)
                    < LIMITE_EXEMPLOS_ERROS
                ):
                    exemplos_erros.append(
                        f"Linha {numero_linha}: {erro}"
                    )

            if (
                total_linhas % 100_000
                == 0
            ):
                print(
                    "Linhas verificadas:",
                    formatar_inteiro(
                        total_linhas
                    ),
                )

    exibir_resumo(
        resumo=resumo
    )

    erros_resumo = comparar_resumo(
        resumo_encontrado=resumo
    )

    print("\n" + "=" * 70)
    print("RESULTADO DA VALIDAÇÃO")
    print("=" * 70)

    print(
        "Total de linhas encontradas:",
        formatar_inteiro(
            total_linhas
        ),
    )

    print(
        "Total de linhas esperado:",
        formatar_inteiro(
            TOTAL_LINHAS_ESPERADO
        ),
    )

    print(
        "Linhas inválidas:",
        formatar_inteiro(
            total_linhas_invalidas
        ),
    )

    validacao_aprovada = True

    if total_linhas != TOTAL_LINHAS_ESPERADO:
        validacao_aprovada = False

        print(
            "\nErro: a quantidade total de linhas "
            "não corresponde ao esperado."
        )

    if total_linhas_invalidas > 0:
        validacao_aprovada = False

        print(
            "\nExemplos de linhas inválidas:"
        )

        for exemplo in exemplos_erros:
            print(
                "-",
                exemplo,
            )

    if erros_resumo:
        validacao_aprovada = False

        print(
            "\nDiferenças encontradas nos totais:"
        )

        for erro in erros_resumo:
            print(
                "-",
                erro,
            )

    if validacao_aprovada:
        print(
            "\nFATO COMEX APROVADA!"
        )

        print(
            "A quantidade de linhas, os totais, "
            "as datas e as regras dos dois fluxos "
            "estão corretos."
        )

    else:
        print(
            "\nFATO COMEX REPROVADA."
        )

        print(
            "Os problemas precisam ser corrigidos "
            "antes da carga no PostgreSQL."
        )

    return validacao_aprovada


def main() -> None:
    """
    Localiza e valida a fato_comex.
    """

    raiz_projeto = obter_raiz_projeto()

    caminho_fato = (
        raiz_projeto
        / "data"
        / "processed"
        / "fato_comex"
        / "fato_comex.csv"
    )

    try:
        validacao_aprovada = validar_fato_comex(
            caminho=caminho_fato
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

        sys.exit(1)

    if not validacao_aprovada:
        sys.exit(1)


if __name__ == "__main__":
    main()