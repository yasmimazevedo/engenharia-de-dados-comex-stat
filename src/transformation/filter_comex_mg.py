import csv
from pathlib import Path


# Recorte geográfico e temporal do projeto.
UF_DESEJADA = "MG"
MES_INICIAL = 1
MES_FINAL = 6

# Anos que serão processados.
ANOS = (
    2024,
    2025,
    2026,
)

# Exibe o progresso a cada 500 mil linhas.
INTERVALO_PROGRESSO = 500_000

# Colunas que precisam existir nos arquivos.
COLUNAS_OBRIGATORIAS = {
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


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_inteiro(valor: int) -> str:
    """
    Formata números inteiros usando ponto
    como separador de milhar.
    """

    return f"{valor:,}".replace(",", ".")


def detectar_codificacao(caminho: Path) -> str:
    """
    Verifica se o arquivo começa com a marca BOM
    utilizada por arquivos UTF-8.

    Caso não exista BOM, utiliza latin-1.
    """

    with caminho.open("rb") as arquivo:
        primeiros_bytes = arquivo.read(3)

    if primeiros_bytes == b"\xef\xbb\xbf":
        return "utf-8-sig"

    return "latin-1"


def montar_configuracoes(
    raiz_projeto: Path,
) -> list[dict]:
    """
    Monta os caminhos dos seis arquivos que
    serão processados.
    """

    configuracoes = []

    for ano in ANOS:
        configuracoes.append(
            {
                "fluxo": "EXPORTACAO",
                "ano": ano,
                "entrada": (
                    raiz_projeto
                    / "data"
                    / "raw"
                    / "exportacao"
                    / f"EXP_{ano}.csv"
                ),
                "saida": (
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
                "entrada": (
                    raiz_projeto
                    / "data"
                    / "raw"
                    / "importacao"
                    / f"IMP_{ano}.csv"
                ),
                "saida": (
                    raiz_projeto
                    / "data"
                    / "interim"
                    / "importacao_mg"
                    / f"IMP_MG_{ano}_01_06.csv"
                ),
            }
        )

    return configuracoes


def transformar_arquivo(
    fluxo: str,
    ano: int,
    caminho_entrada: Path,
    caminho_saida: Path,
) -> dict:
    """
    Lê o CSV linha por linha.

    Mantém somente:
    - registros de Minas Gerais;
    - meses de janeiro a junho.
    """

    if not caminho_entrada.exists():
        raise FileNotFoundError(
            f"Arquivo não encontrado: {caminho_entrada}"
        )

    caminho_saida.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    # Remove um resultado anterior para impedir
    # que uma nova execução duplique os dados.
    caminho_saida.unlink(
        missing_ok=True
    )

    codificacao = detectar_codificacao(
        caminho_entrada
    )

    total_linhas_lidas = 0
    total_linhas_mantidas = 0
    total_linhas_invalidas = 0

    print("\n" + "=" * 70)
    print(f"Processando: {caminho_entrada.name}")
    print(f"Fluxo: {fluxo}")
    print(f"Ano: {ano}")
    print(f"Codificação detectada: {codificacao}")
    print(f"Destino: {caminho_saida}")
    print("=" * 70)

    with caminho_entrada.open(
        mode="r",
        encoding=codificacao,
        newline="",
    ) as arquivo_entrada:

        leitor = csv.DictReader(
            arquivo_entrada,
            delimiter=";",
        )

        if leitor.fieldnames is None:
            raise ValueError(
                f"O arquivo {caminho_entrada.name} "
                "não possui cabeçalho."
            )

        # Remove eventuais espaços nos nomes
        # das colunas.
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
                "Colunas obrigatórias ausentes em "
                f"{caminho_entrada.name}: "
                f"{sorted(colunas_ausentes)}"
            )

        colunas_saida = [
            "FLUXO",
            "ARQUIVO_ORIGEM",
            *leitor.fieldnames,
        ]

        with caminho_saida.open(
            mode="w",
            encoding="utf-8-sig",
            newline="",
        ) as arquivo_saida:

            escritor = csv.DictWriter(
                arquivo_saida,
                fieldnames=colunas_saida,
                delimiter=";",
                lineterminator="\n",
                extrasaction="ignore",
            )

            escritor.writeheader()

            for linha in leitor:
                total_linhas_lidas += 1

                uf = (
                    linha.get(
                        "SG_UF_NCM",
                        "",
                    )
                    .strip()
                    .upper()
                )

                mes_texto = (
                    linha.get(
                        "CO_MES",
                        "",
                    )
                    .strip()
                )

                try:
                    mes = int(mes_texto)

                except ValueError:
                    total_linhas_invalidas += 1
                    continue

                registro_desejado = (
                    uf == UF_DESEJADA
                    and MES_INICIAL
                    <= mes
                    <= MES_FINAL
                )

                if registro_desejado:
                    linha_saida = {
                        "FLUXO": fluxo,
                        "ARQUIVO_ORIGEM": (
                            caminho_entrada.name
                        ),
                    }

                    linha_saida.update(linha)

                    escritor.writerow(
                        linha_saida
                    )

                    total_linhas_mantidas += 1

                if (
                    total_linhas_lidas
                    % INTERVALO_PROGRESSO
                    == 0
                ):
                    print(
                        "Linhas lidas: "
                        f"{formatar_inteiro(total_linhas_lidas)}"
                        " | Mantidas: "
                        f"{formatar_inteiro(total_linhas_mantidas)}"
                    )

    if total_linhas_mantidas == 0:
        caminho_saida.unlink(
            missing_ok=True
        )

        raise ValueError(
            "Nenhum registro de MG entre janeiro "
            f"e junho foi encontrado em "
            f"{caminho_entrada.name}."
        )

    tamanho_saida_mb = (
        caminho_saida.stat().st_size
        / (1024 * 1024)
    )

    print("\nTransformação concluída!")
    print(
        "Linhas lidas: "
        f"{formatar_inteiro(total_linhas_lidas)}"
    )
    print(
        "Linhas mantidas: "
        f"{formatar_inteiro(total_linhas_mantidas)}"
    )
    print(
        "Linhas inválidas: "
        f"{formatar_inteiro(total_linhas_invalidas)}"
    )
    print(
        f"Tamanho do resultado: "
        f"{tamanho_saida_mb:.2f} MB"
    )

    return {
        "fluxo": fluxo,
        "ano": ano,
        "arquivo": caminho_saida.name,
        "linhas_lidas": total_linhas_lidas,
        "linhas_mantidas": total_linhas_mantidas,
        "linhas_invalidas": total_linhas_invalidas,
        "tamanho_mb": tamanho_saida_mb,
    }


def exibir_resumo(
    resumos: list[dict],
) -> None:
    """
    Exibe o resumo dos seis arquivos processados.
    """

    print("\n" + "=" * 70)
    print("RESUMO GERAL DA TRANSFORMAÇÃO")
    print("=" * 70)

    for resumo in resumos:
        print(
            f"{resumo['fluxo']:<11} | "
            f"{resumo['ano']} | "
            f"mantidas: "
            f"{formatar_inteiro(resumo['linhas_mantidas']):>10} | "
            f"tamanho: "
            f"{resumo['tamanho_mb']:>7.2f} MB"
        )


def main() -> None:
    """
    Executa a transformação dos seis arquivos.
    """

    raiz_projeto = obter_raiz_projeto()

    configuracoes = montar_configuracoes(
        raiz_projeto
    )

    resumos = []

    try:
        for configuracao in configuracoes:
            resumo = transformar_arquivo(
                fluxo=configuracao["fluxo"],
                ano=configuracao["ano"],
                caminho_entrada=configuracao["entrada"],
                caminho_saida=configuracao["saida"],
            )

            resumos.append(resumo)

    except (
        FileNotFoundError,
        ValueError,
        UnicodeError,
        csv.Error,
        OSError,
    ) as erro:
        print("\nA transformação não foi concluída.")
        print("Motivo:", erro)

        return

    exibir_resumo(resumos)

    print(
        "\nTodos os arquivos foram processados "
        "com sucesso."
    )


if __name__ == "__main__":
    main()