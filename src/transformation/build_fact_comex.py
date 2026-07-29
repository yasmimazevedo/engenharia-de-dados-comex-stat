import csv
from collections import defaultdict
from decimal import Decimal, InvalidOperation
from pathlib import Path


ANOS = (
    2024,
    2025,
    2026,
)

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

COLUNAS_SAIDA = [
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

INTERVALO_PROGRESSO = 100_000


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_inteiro(valor: int) -> str:
    """
    Formata um inteiro usando ponto como
    separador de milhares.
    """

    return f"{valor:,}".replace(",", ".")


def limpar_codigo(valor: str) -> str:
    """
    Remove espaços sem converter códigos para números.

    Isso preserva possíveis zeros à esquerda.
    """

    return valor.strip()


def converter_inteiro_nao_negativo(
    valor: str,
    nome_coluna: str,
) -> int:
    """
    Converte um texto para inteiro e impede
    valores negativos.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        raise ValueError(
            f"A coluna {nome_coluna} está vazia."
        )

    try:
        numero = int(valor_limpo)

    except ValueError as erro:
        raise ValueError(
            f"A coluna {nome_coluna} não contém "
            f"um inteiro válido: {valor_limpo}"
        ) from erro

    if numero < 0:
        raise ValueError(
            f"A coluna {nome_coluna} possui "
            f"valor negativo: {numero}"
        )

    return numero


def converter_inteiro_opcional(
    valor: str,
    nome_coluna: str,
) -> int:
    """
    Converte uma coluna opcional para inteiro.

    Valor vazio é considerado zero.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        return 0

    return converter_inteiro_nao_negativo(
        valor=valor_limpo,
        nome_coluna=nome_coluna,
    )


def normalizar_decimal_nao_negativo(
    valor: str,
    nome_coluna: str,
) -> str:
    """
    Valida uma quantidade numérica e devolve
    uma representação textual padronizada.

    A quantidade estatística pode não representar
    apenas unidades inteiras.
    """

    valor_limpo = valor.strip()

    if valor_limpo == "":
        raise ValueError(
            f"A coluna {nome_coluna} está vazia."
        )

    valor_normalizado = valor_limpo.replace(
        ",",
        ".",
    )

    try:
        numero = Decimal(
            valor_normalizado
        )

    except InvalidOperation as erro:
        raise ValueError(
            f"A coluna {nome_coluna} não contém "
            f"um número válido: {valor_limpo}"
        ) from erro

    if numero < 0:
        raise ValueError(
            f"A coluna {nome_coluna} possui "
            f"valor negativo: {valor_limpo}"
        )

    return format(
        numero,
        "f",
    )


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


def validar_cabecalho(
    leitor: csv.DictReader,
    caminho: Path,
) -> None:
    """
    Verifica se o arquivo possui todas as colunas
    necessárias para construir a tabela fato.
    """

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
        COLUNAS_OBRIGATORIAS
        - colunas_encontradas
    )

    if colunas_ausentes:
        raise ValueError(
            f"Colunas ausentes em {caminho.name}: "
            f"{sorted(colunas_ausentes)}"
        )


def transformar_linha(
    linha: dict[str, str],
    caminho: Path,
    numero_linha: int,
) -> dict[str, str | int]:
    """
    Padroniza uma linha da camada interim para
    o formato da fato_comex.
    """

    try:
        fluxo = (
            linha["FLUXO"]
            .strip()
            .upper()
        )

        if fluxo not in {
            "EXPORTACAO",
            "IMPORTACAO",
        }:
            raise ValueError(
                f"Fluxo inválido: {fluxo}"
            )

        ano = converter_inteiro_nao_negativo(
            linha["CO_ANO"],
            "CO_ANO",
        )

        mes = converter_inteiro_nao_negativo(
            linha["CO_MES"],
            "CO_MES",
        )

        if mes < 1 or mes > 12:
            raise ValueError(
                f"Mês inválido: {mes}"
            )

        data_referencia = (
            f"{ano}-{mes:02d}-01"
        )

        codigo_ncm = limpar_codigo(
            linha["CO_NCM"]
        )

        codigo_unidade = limpar_codigo(
            linha["CO_UNID"]
        )

        codigo_pais = limpar_codigo(
            linha["CO_PAIS"]
        )

        sigla_uf = (
            linha["SG_UF_NCM"]
            .strip()
            .upper()
        )

        codigo_via = limpar_codigo(
            linha["CO_VIA"]
        )

        codigo_urf = limpar_codigo(
            linha["CO_URF"]
        )

        quantidade_estatistica = (
            normalizar_decimal_nao_negativo(
                linha["QT_ESTAT"],
                "QT_ESTAT",
            )
        )

        peso_liquido_kg = (
            converter_inteiro_nao_negativo(
                linha["KG_LIQUIDO"],
                "KG_LIQUIDO",
            )
        )

        valor_fob_usd = (
            converter_inteiro_nao_negativo(
                linha["VL_FOB"],
                "VL_FOB",
            )
        )

        valor_frete_usd = ""
        valor_seguro_usd = ""
        valor_cif_usd = ""

        if fluxo == "IMPORTACAO":
            valor_frete = (
                converter_inteiro_opcional(
                    linha.get(
                        "VL_FRETE",
                        "",
                    ),
                    "VL_FRETE",
                )
            )

            valor_seguro = (
                converter_inteiro_opcional(
                    linha.get(
                        "VL_SEGURO",
                        "",
                    ),
                    "VL_SEGURO",
                )
            )

            valor_cif = (
                valor_fob_usd
                + valor_frete
                + valor_seguro
            )

            valor_frete_usd = valor_frete
            valor_seguro_usd = valor_seguro
            valor_cif_usd = valor_cif

        arquivo_origem = (
            linha["ARQUIVO_ORIGEM"]
            .strip()
        )

        return {
            "fluxo": fluxo,
            "data_referencia": data_referencia,
            "ano": ano,
            "mes": mes,
            "codigo_ncm": codigo_ncm,
            "codigo_unidade": codigo_unidade,
            "codigo_pais": codigo_pais,
            "sigla_uf": sigla_uf,
            "codigo_via": codigo_via,
            "codigo_urf": codigo_urf,
            "quantidade_estatistica": (
                quantidade_estatistica
            ),
            "peso_liquido_kg": peso_liquido_kg,
            "valor_fob_usd": valor_fob_usd,
            "valor_frete_usd": valor_frete_usd,
            "valor_seguro_usd": valor_seguro_usd,
            "valor_cif_usd": valor_cif_usd,
            "arquivo_origem": arquivo_origem,
        }

    except (
        KeyError,
        ValueError,
        TypeError,
    ) as erro:
        raise ValueError(
            f"Erro em {caminho.name}, "
            f"linha {numero_linha}: {erro}"
        ) from erro


def processar_arquivo(
    caminho: Path,
    escritor: csv.DictWriter,
    resumo: dict,
) -> int:
    """
    Lê um arquivo interim e acrescenta suas linhas
    padronizadas ao arquivo fato.
    """

    if not caminho.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho}"
        )

    total_arquivo = 0

    print("\n" + "=" * 70)
    print(f"Processando: {caminho.name}")
    print("=" * 70)

    with caminho.open(
        mode="r",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo_entrada:

        leitor = csv.DictReader(
            arquivo_entrada,
            delimiter=";",
        )

        validar_cabecalho(
            leitor=leitor,
            caminho=caminho,
        )

        for numero_linha, linha in enumerate(
            leitor,
            start=2,
        ):
            linha_transformada = transformar_linha(
                linha=linha,
                caminho=caminho,
                numero_linha=numero_linha,
            )

            escritor.writerow(
                linha_transformada
            )

            fluxo = str(
                linha_transformada["fluxo"]
            )

            ano = int(
                linha_transformada["ano"]
            )

            chave_resumo = (
                fluxo,
                ano,
            )

            resumo[chave_resumo]["linhas"] += 1

            resumo[chave_resumo][
                "valor_fob_usd"
            ] += int(
                linha_transformada[
                    "valor_fob_usd"
                ]
            )

            resumo[chave_resumo][
                "peso_liquido_kg"
            ] += int(
                linha_transformada[
                    "peso_liquido_kg"
                ]
            )

            total_arquivo += 1

            if (
                total_arquivo
                % INTERVALO_PROGRESSO
                == 0
            ):
                print(
                    "Linhas processadas neste arquivo:",
                    formatar_inteiro(
                        total_arquivo
                    ),
                )

    print(
        "Arquivo concluído. Linhas adicionadas:",
        formatar_inteiro(
            total_arquivo
        ),
    )

    return total_arquivo


def construir_fato_comex(
    raiz_projeto: Path,
) -> Path:
    """
    Consolida os seis arquivos interim em
    uma única tabela fato.
    """

    pasta_saida = (
        raiz_projeto
        / "data"
        / "processed"
        / "fato_comex"
    )

    pasta_saida.mkdir(
        parents=True,
        exist_ok=True,
    )

    caminho_saida = (
        pasta_saida
        / "fato_comex.csv"
    )

    caminho_saida.unlink(
        missing_ok=True
    )

    arquivos_interim = montar_arquivos_interim(
        raiz_projeto
    )

    resumo = defaultdict(
        lambda: {
            "linhas": 0,
            "valor_fob_usd": 0,
            "peso_liquido_kg": 0,
        }
    )

    total_geral = 0

    with caminho_saida.open(
        mode="w",
        encoding="utf-8-sig",
        newline="",
    ) as arquivo_saida:

        escritor = csv.DictWriter(
            arquivo_saida,
            fieldnames=COLUNAS_SAIDA,
            delimiter=";",
            lineterminator="\n",
        )

        escritor.writeheader()

        for caminho in arquivos_interim:
            total_arquivo = processar_arquivo(
                caminho=caminho,
                escritor=escritor,
                resumo=resumo,
            )

            total_geral += total_arquivo

    tamanho_mb = (
        caminho_saida.stat().st_size
        / (1024 * 1024)
    )

    print("\n" + "=" * 90)
    print("RESUMO DA FATO COMEX")
    print("=" * 90)

    for chave in sorted(
        resumo.keys(),
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

    print("\nTotal de linhas:")
    print(
        formatar_inteiro(
            total_geral
        )
    )

    print("Tamanho do arquivo:")
    print(
        f"{tamanho_mb:.2f} MB"
    )

    print("Arquivo criado em:")
    print(
        caminho_saida
    )

    return caminho_saida


def main() -> None:
    """
    Executa a construção da tabela fato.
    """

    raiz_projeto = obter_raiz_projeto()

    try:
        construir_fato_comex(
            raiz_projeto=raiz_projeto
        )

    except (
        FileNotFoundError,
        ValueError,
        UnicodeError,
        InvalidOperation,
        csv.Error,
        OSError,
    ) as erro:
        print(
            "\nA construção da fato_comex "
            "não foi concluída."
        )

        print(
            "Motivo:",
            erro,
        )

        return

    print(
        "\nA fato_comex foi construída "
        "com sucesso."
    )


if __name__ == "__main__":
    main()