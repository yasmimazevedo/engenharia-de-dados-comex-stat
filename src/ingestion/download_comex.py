import time
from pathlib import Path

import truststore

# Deve ser executado antes da importação do requests.
# Assim, o Requests utiliza a loja de certificados do Windows.
truststore.inject_into_ssl()

import requests


URL_ARQUIVO = (
    "https://balanca.economia.gov.br/"
    "balanca/bd/comexstat-bd/ncm/IMP_2026.csv"
)

NOME_ARQUIVO = "IMP_2026.csv"

TAMANHO_BLOCO = 1024 * 1024  # 1 MB

MAXIMO_TENTATIVAS = 60

ESPERA_ENTRE_TENTATIVAS = 5


def obter_raiz_projeto() -> Path:
    """
    Retorna a pasta principal do projeto.
    """

    return Path(__file__).resolve().parents[2]


def formatar_tamanho(quantidade_bytes: int) -> str:
    """
    Converte bytes para megabytes.
    """

    megabytes = quantidade_bytes / (1024 * 1024)

    return f"{megabytes:,.2f} MB"


def obter_tamanho_remoto() -> int:
    """
    Consulta o tamanho total do arquivo no servidor.

    A requisição HEAD busca apenas os cabeçalhos,
    sem baixar o conteúdo completo.
    """

    with requests.head(
        URL_ARQUIVO,
        allow_redirects=True,
        timeout=(30, 60),
        headers={
            "User-Agent": (
                "engenharia-de-dados-comex-stat/1.0"
            )
        },
    ) as resposta:

        resposta.raise_for_status()

        tamanho = resposta.headers.get("Content-Length")

        if tamanho is None:
            raise RuntimeError(
                "O servidor não informou o tamanho do arquivo."
            )

        return int(tamanho)


def baixar_arquivo() -> Path:
    """
    Baixa o arquivo e retoma transferências interrompidas.
    """

    raiz_projeto = obter_raiz_projeto()

    pasta_destino = (
        raiz_projeto
        / "data"
        / "raw"
        / "importacao"
    )

    pasta_destino.mkdir(
        parents=True,
        exist_ok=True,
    )

    caminho_final = pasta_destino / NOME_ARQUIVO

    caminho_temporario = (
        pasta_destino
        / f"{NOME_ARQUIVO}.part"
    )

    print("Consultando o tamanho do arquivo no servidor...")

    tamanho_total = obter_tamanho_remoto()

    print(
        "Tamanho esperado:",
        formatar_tamanho(tamanho_total),
    )

    if caminho_final.exists():
        tamanho_final = caminho_final.stat().st_size

        if tamanho_final == tamanho_total:
            print("\nO arquivo completo já existe:")
            print(caminho_final)

            return caminho_final

        raise RuntimeError(
            "Existe um arquivo final com tamanho diferente "
            "do informado pelo servidor."
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
            caminho_temporario.replace(caminho_final)

            print("\nDownload concluído!")
            print("Arquivo salvo em:")
            print(caminho_final)

            return caminho_final

        if bytes_existentes > tamanho_total:
            raise RuntimeError(
                "O arquivo parcial é maior que o arquivo "
                "informado pelo servidor."
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
                "Retomando o download a partir do byte:",
                bytes_existentes,
            )
        else:
            print("Iniciando um novo download.")

        try:
            with requests.get(
                URL_ARQUIVO,
                stream=True,
                timeout=(30, 300),
                headers=cabecalhos,
            ) as resposta:

                # Quando solicitamos uma continuação,
                # esperamos o código 206 Partial Content.
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
                        "a continuação do download."
                    )

                bytes_baixados = bytes_existentes

                with caminho_temporario.open(
                    mode=modo_abertura
                ) as arquivo_destino:

                    for bloco in resposta.iter_content(
                        chunk_size=TAMANHO_BLOCO
                    ):
                        if not bloco:
                            continue

                        arquivo_destino.write(bloco)

                        bytes_baixados += len(bloco)

                        percentual = (
                            bytes_baixados
                            / tamanho_total
                            * 100
                        )

                        mensagem = (
                            f"\rBaixados "
                            f"{formatar_tamanho(bytes_baixados)} "
                            f"de "
                            f"{formatar_tamanho(tamanho_total)} "
                            f"({percentual:.1f}%)"
                        )

                        print(
                            mensagem,
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
                    "\n\nDownload concluído "
                    "com sucesso!"
                )

                print("Arquivo salvo em:")
                print(caminho_final)

                return caminho_final

            print(
                "\nA transferência terminou antes "
                "do tamanho esperado."
            )

            print(
                "O conteúdo parcial será preservado."
            )

        except requests.exceptions.SSLError as erro:
            raise RuntimeError(
                "O Python não conseguiu validar "
                "o certificado SSL, mesmo usando "
                "a loja de certificados do Windows."
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
                "\nA conexão foi interrompida "
                "durante a transferência."
            )

            print(
                "Dados preservados:",
                formatar_tamanho(tamanho_preservado),
            )

            print(
                "Tipo do erro:",
                type(erro).__name__,
            )

        except requests.exceptions.HTTPError as erro:
            raise RuntimeError(
                f"O servidor retornou um erro HTTP: "
                f"{erro}"
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
        "O download não foi concluído após "
        "o número máximo de tentativas."
    )


def main() -> None:
    """
    Executa a ingestão.
    """

    try:
        baixar_arquivo()

    except (
        RuntimeError,
        OSError,
    ) as erro:
        print("\nA ingestão não foi concluída.")
        print("Motivo:", erro)


if __name__ == "__main__":
    main()