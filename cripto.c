/*
 * ELC1011 - Trabalho 1: Criptografia RC4
 * Versao em C (para estudo) do programa pedido em assembly MIPS.
 *
 * Fluxo: menu (1 criptografar / 2 descriptografar) -> nome do arquivo de
 * entrada -> nome do arquivo de saida -> senha (ecoada como '*') -> processa.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <conio.h>
#else
#include <termios.h>
#include <unistd.h>
#endif

typedef unsigned char u8;

/* ------------------------------------------------------------------ */
/* Entrada de senha com asteriscos                                     */
/* ------------------------------------------------------------------ */
static int ler_char_sem_eco(void) {
#ifdef _WIN32
    return _getch();
#else
    struct termios antigo, novo;
    int c;
    tcgetattr(STDIN_FILENO, &antigo);
    novo = antigo;
    novo.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &novo);
    c = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &antigo);
    return c;
#endif
}

static int ler_senha(const char *prompt, char *buf, int max) {
    int n = 0, c;
    printf("%s", prompt);
    fflush(stdout);
    while ((c = ler_char_sem_eco()) != '\r' && c != '\n' && c != EOF) {
        if ((c == 8 || c == 127) && n > 0) { /* backspace */
            n--;
            printf("\b \b");
        } else if (c >= 32 && c < 127 && n < max - 1) {
            buf[n++] = (char)c;
            putchar('*');
        }
        fflush(stdout);
    }
    buf[n] = '\0';
    putchar('\n');
    return n;
}

/* ------------------------------------------------------------------ */
/* RC4                                                                 */
/* ------------------------------------------------------------------ */
/* Gera o keystream e faz XOR com os dados. A mesma funcao cifra e decifra. */
static void rc4(const u8 *chave, int tam_chave, u8 *dados, long n) {
    u8 S[256], t;
    int i, j = 0;
    long k;

    /* KSA: embaralha S usando a chave */
    for (i = 0; i < 256; i++) S[i] = (u8)i;
    for (i = 0; i < 256; i++) {
        j = (j + S[i] + chave[i % tam_chave]) & 255;
        t = S[i]; S[i] = S[j]; S[j] = t;
    }

    /* PRGA: gera um byte de keystream por byte de dado */
    i = j = 0;
    for (k = 0; k < n; k++) {
        i = (i + 1) & 255;
        j = (j + S[i]) & 255;
        t = S[i]; S[i] = S[j]; S[j] = t;
        dados[k] ^= S[(S[i] + S[j]) & 255];
    }
}

/* ------------------------------------------------------------------ */
/* Arquivos e programa principal                                       */
/* ------------------------------------------------------------------ */
static u8 *ler_arquivo(const char *nome, long *n) {
    FILE *f = fopen(nome, "rb");
    u8 *buf;
    if (!f) return NULL;
    fseek(f, 0, SEEK_END);
    *n = ftell(f);
    fseek(f, 0, SEEK_SET);
    buf = malloc(*n + 1);
    if (buf && fread(buf, 1, *n, f) != (size_t)*n) { free(buf); buf = NULL; }
    fclose(f);
    return buf;
}

static void ler_linha(const char *prompt, char *buf, int max) {
    printf("%s", prompt);
    if (!fgets(buf, max, stdin)) buf[0] = '\0';
    buf[strcspn(buf, "\r\n")] = '\0';
}

int main(void) {
    char entrada[260], saida[260], senha[128], op[16];
    u8 *dados;
    long n;
    int cifrar;
    FILE *f;

    printf("=== Criptografia RC4 ===\n");
    printf("1) Criptografar\n2) Descriptografar\n");
    ler_linha("Opcao: ", op, sizeof op);
    if (op[0] != '1' && op[0] != '2') { printf("Opcao invalida.\n"); return 1; }
    cifrar = (op[0] == '1');

    ler_linha(cifrar ? "Arquivo de entrada (texto claro): "
                     : "Arquivo de entrada (texto cifrado): ", entrada, sizeof entrada);
    ler_linha(cifrar ? "Arquivo de saida (texto cifrado): "
                     : "Arquivo de saida (texto decifrado): ", saida, sizeof saida);
    if (ler_senha("Senha: ", senha, sizeof senha) == 0) {
        printf("Senha vazia.\n");
        return 1;
    }

    dados = ler_arquivo(entrada, &n);
    if (!dados) { printf("Erro ao ler '%s'.\n", entrada); return 1; }

    rc4((const u8 *)senha, (int)strlen(senha), dados, n);

    f = fopen(saida, "wb");
    if (!f) { printf("Erro ao criar '%s'.\n", saida); free(dados); return 1; }
    fwrite(dados, 1, n, f);
    fclose(f);
    free(dados);
    printf("Concluido: %s -> %s (%ld bytes)\n", entrada, saida, n);
    return 0;
}
