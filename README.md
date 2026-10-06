# Trabalho 1 — Criptografia RC4 (versão em C)

Versão em C do programa pedido em ELC1011 (originalmente em assembly MIPS/MARS). Serve para entender o fluxo antes de portar para assembly.

## Compilar e executar

```bash
gcc -Wall -o cripto cripto.c
./cripto        # no Windows: cripto.exe
```

## Como usar

O programa pergunta, nesta ordem:

1. **Opção**: `1` criptografar ou `2` descriptografar.
2. **Arquivo de entrada** (texto claro ao criptografar, cifrado ao descriptografar).
3. **Arquivo de saída**.
4. **Senha**: cada caractere digitado aparece como `*`. Backspace funciona.

Exemplo de teste pedido pelo professor (chave `ELC1011`):

| Passo | Opção | Entrada | Saída |
|---|---|---|---|
| Criptografar | 1 | `texto1.txt` | `secreto1.rc4` |
| Criptografar | 1 | `texto2.txt` | `secreto2.rc4` |
| Descriptografar | 2 | `secreto1.rc4` | `teste1.txt` |
| Descriptografar | 2 | `secreto2.rc4` | `teste2.txt` |

Depois compare `teste1.txt` com `texto1.txt` (e o 2 com o 2); devem ser idênticos.

## Como o RC4 funciona

RC4 é uma **cifra de fluxo**: gera uma sequência pseudoaleatória de bytes (*keystream*) a partir da chave e faz **XOR** dela com os dados.

```
cifrado = claro  XOR keystream
claro   = cifrado XOR keystream
```

Como XOR é inverso de si mesmo, **a mesma função cifra e decifra**. A opção do menu só muda os nomes dos arquivos. Com senha errada o programa não avisa: ele gera lixo.

São duas etapas, ambas na função `rc4()` de [cripto.c](cripto.c):

### 1. KSA (Key Scheduling Algorithm)
Cria um vetor `S` de 256 bytes com `0..255` e o embaralha usando a chave:

```
para i de 0 a 255: S[i] = i
j = 0
para i de 0 a 255:
    j = (j + S[i] + chave[i mod tamanho_chave]) mod 256
    troca S[i] com S[j]
```

### 2. PRGA (Pseudo-Random Generation Algorithm)
Para cada byte do arquivo:

```
i = (i + 1) mod 256
j = (j + S[i]) mod 256
troca S[i] com S[j]
K = S[(S[i] + S[j]) mod 256]
byte_saida = byte_entrada XOR K
```

## Estrutura do código

| Função | O que faz |
|---|---|
| `ler_char_sem_eco()` | Lê uma tecla sem mostrá-la (`_getch` no Windows, `termios` no Linux/macOS). |
| `ler_senha()` | Lê a senha mostrando `*` e tratando backspace. |
| `rc4()` | KSA + PRGA; modifica o buffer no lugar. |
| `ler_arquivo()` | Carrega o arquivo inteiro em memória (modo binário). |
| `main()` | Menu, pedidos de nomes e senha, chama `rc4()` e grava a saída. |

## Observações

- Arquivos são tratados como binário (`rb`/`wb`), então o tamanho de saída é igual ao de entrada.
- Senha: até 127 caracteres ASCII imprimíveis; senha vazia é recusada.
- RC4 hoje é considerado inseguro; aqui é só para fins didáticos.
- Para a entrega em MIPS, o `S[256]` vira um vetor em `.data` (ou `.space 256`) e o loop de leitura de senha usa a syscall de leitura de caractere do MARS (que não faz eco, então você imprime o `*` manualmente).
