import time
from pathlib import Path

import truststore

# Usa os certificados confiáveis do Windows.
# Deve acontecer antes da importação do requests.
truststore.inject_into_ssl()

import requests


BASE_URL = (
    "https://balanca.economia.gov.br/"
    "balanca/bd/tabelas"
)

TABELAS = (
    "NCM.csv",
    "NCM_SH.csv",
    "NCM_UNIDADE.csv",
    "PAIS.csv",
    "VIA.csv",
    "URF.csv",
)

TAMANHO_BLOCO = 1024 * 1024  # 1 MB

MAXIMO_TENTATIVAS = 20

ESPERA_ENTRE_TENTATIVAS = 5


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_tamanho(quantidade_bytes: int) -> str:
    """
    Converte bytes para uma apresentação em MB.
    """

    megabytes = quantidade_bytes / (1024 * 1024)

    return f"{megabytes:,.2f} MB"


def obter_tamanho_remoto(url: str) -> int:
    """
    Consulta o tamanho do arquivo no servidor
    sem baixar seu conteúdo.
    """

    with requests.head(
        url,
        allow_redirects=True,
        timeout=(30, 60),
        headers={
            "User-Agent": (
                "engenharia-de-dados-comex-stat/1.0"
            )
        },
    ) as resposta:

        resposta.raise_for_status()

        tamanho = resposta.headers.get(
            "Content-Length"
        )

        if tamanho is None:
            raise RuntimeError(
                "O servidor não informou "
                "o tamanho do arquivo."
            )

        return int(tamanho)


def baixar_tabela(
    nome_arquivo: str,
    pasta_destino: Path,
) -> Path:
    """
    Baixa uma tabela de referência.

    Caso a conexão caia, o arquivo parcial é
    preservado e o download continua depois.
    """

    url = f"{BASE_URL}/{nome_arquivo}"

    caminho_final = (
        pasta_destino
        / nome_arquivo
    )

    caminho_temporario = (
        pasta_destino
        / f"{nome_arquivo}.part"
    )

    print("\n" + "=" * 70)
    print(f"Tabela: {nome_arquivo}")
    print(f"Endereço: {url}")
    print("=" * 70)

    tamanho_total = obter_tamanho_remoto(
        url=url
    )

    print(
        "Tamanho esperado:",
        formatar_tamanho(tamanho_total),
    )

    if caminho_final.exists():
        tamanho_local = (
            caminho_final.stat().st_size
        )

        if tamanho_local == tamanho_total:
            print(
                "O arquivo completo já existe "
                "e não será baixado novamente."
            )

            return caminho_final

        raise RuntimeError(
            f"O arquivo {nome_arquivo} já existe, "
            "mas seu tamanho não corresponde "
            "ao tamanho informado pelo servidor."
        )

    for tentativa in range(
        1,
        MAXIMO_TENTATIVAS + 1,
    ):
        bytes_existentes = 0

        if caminho_temporario.exists():
            bytes_existentes = (
                caminho_temporario.stat().st_size
            )

        if bytes_existentes == tamanho_total:
            caminho_temporario.replace(
                caminho_final
            )

            print("Download concluído!")

            return caminho_final

        if bytes_existentes > tamanho_total:
            raise RuntimeError(
                f"O arquivo parcial {nome_arquivo} "
                "é maior que o arquivo remoto."
            )

        print(
            f"\nTentativa {tentativa}/"
            f"{MAXIMO_TENTATIVAS}"
        )

        print(
            "Já armazenado:",
            formatar_tamanho(bytes_existentes),
        )

        cabecalhos = {
            "User-Agent": (
                "engenharia-de-dados-comex-stat/1.0"
            )
        }

        modo_abertura = "wb"

        if bytes_existentes > 0:
            cabecalhos["Range"] = (
                f"bytes={bytes_existentes}-"
            )

            modo_abertura = "ab"

            print(
                "Retomando a partir do byte:",
                bytes_existentes,
            )

        try:
            with requests.get(
                url,
                stream=True,
                timeout=(30, 300),
                headers=cabecalhos,
            ) as resposta:

                if (
                    bytes_existentes > 0
                    and resposta.status_code == 200
                ):
                    print(
                        "O servidor ignorou a retomada."
                    )

                    print(
                        "O arquivo parcial será reiniciado."
                    )

                    caminho_temporario.unlink(
                        missing_ok=True
                    )

                    continue

                resposta.raise_for_status()

                if (
                    bytes_existentes > 0
                    and resposta.status_code != 206
                ):
                    raise RuntimeError(
                        "O servidor não confirmou "
                        "a retomada do arquivo."
                    )

                bytes_baixados = (
                    bytes_existentes
                )

                with caminho_temporario.open(
                    mode=modo_abertura
                ) as arquivo_destino:

                    for bloco in resposta.iter_content(
                        chunk_size=TAMANHO_BLOCO
                    ):
                        if not bloco:
                            continue

                        arquivo_destino.write(
                            bloco
                        )

                        bytes_baixados += len(
                            bloco
                        )

                        percentual = (
                            bytes_baixados
                            / tamanho_total
                            * 100
                        )

                        print(
                            (
                                f"\rBaixados "
                                f"{formatar_tamanho(bytes_baixados)} "
                                f"de "
                                f"{formatar_tamanho(tamanho_total)} "
                                f"({percentual:.1f}%)"
                            ),
                            end="",
                            flush=True,
                        )

            tamanho_atual = (
                caminho_temporario.stat().st_size
            )

            if tamanho_atual == tamanho_total:
                caminho_temporario.replace(
                    caminho_final
                )

                print(
                    "\nDownload concluído "
                    "com sucesso!"
                )

                return caminho_final

            print(
                "\nA transferência terminou antes "
                "do tamanho esperado."
            )

        except requests.exceptions.SSLError as erro:
            raise RuntimeError(
                "O Python não conseguiu validar "
                "o certificado SSL."
            ) from erro

        except (
            requests.exceptions.Timeout,
            requests.exceptions.ConnectionError,
            requests.exceptions.ChunkedEncodingError,
        ) as erro:
            tamanho_preservado = 0

            if caminho_temporario.exists():
                tamanho_preservado = (
                    caminho_temporario.stat().st_size
                )

            print(
                "\nA conexão foi interrompida."
            )

            print(
                "Dados preservados:",
                formatar_tamanho(
                    tamanho_preservado
                ),
            )

            print(
                "Tipo do erro:",
                type(erro).__name__,
            )

        except requests.exceptions.HTTPError as erro:
            raise RuntimeError(
                f"Erro HTTP ao baixar "
                f"{nome_arquivo}: {erro}"
            ) from erro

        if tentativa < MAXIMO_TENTATIVAS:
            print(
                f"Nova tentativa em "
                f"{ESPERA_ENTRE_TENTATIVAS} segundos."
            )

            time.sleep(
                ESPERA_ENTRE_TENTATIVAS
            )

    raise RuntimeError(
        f"O download de {nome_arquivo} "
        "não foi concluído."
    )


def main() -> None:
    """
    Baixa todas as tabelas de referência.
    """

    raiz_projeto = obter_raiz_projeto()

    pasta_destino = (
        raiz_projeto
        / "data"
        / "raw"
        / "reference"
    )

    pasta_destino.mkdir(
        parents=True,
        exist_ok=True,
    )

    arquivos_baixados = []

    try:
        for nome_arquivo in TABELAS:
            caminho = baixar_tabela(
                nome_arquivo=nome_arquivo,
                pasta_destino=pasta_destino,
            )

            arquivos_baixados.append(
                caminho
            )

    except (
        RuntimeError,
        OSError,
    ) as erro:
        print(
            "\nO download das tabelas "
            "não foi concluído."
        )

        print("Motivo:", erro)

        return

    print("\n" + "=" * 70)
    print("TABELAS DE REFERÊNCIA DISPONÍVEIS")
    print("=" * 70)

    for caminho in arquivos_baixados:
        print(
            f"{caminho.name:<20} | "
            f"{formatar_tamanho(caminho.stat().st_size)}"
        )

    print(
        "\nTodas as tabelas foram baixadas "
        "com sucesso."
    )


if __name__ == "__main__":
    main()