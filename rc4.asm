# ELC1011 - Trabalho 1 - Criptografia RC4
# Gustavo Teixeira e Luiza Manoelle
#  Tools > Keyboard and Display MMIO Simulator > Connect to MIPS (p digitar a senha)

.data
S:          .space 256
senha:      .space 128
entrada:    .space 260
saida:      .space 260
buffer:     .space 1024

msg_titulo:        .asciiz "=== Criptografia RC4 ===\n1) Criptografar\n2) Descriptografar\n"
msg_opcao:         .asciiz "Opcao: "
msg_invalida:      .asciiz "Opcao invalida.\n"
msg_ent_claro:     .asciiz "Arquivo de entrada (texto claro): "
msg_ent_cifrado:   .asciiz "Arquivo de entrada (texto cifrado): "
msg_sai_cifrado:   .asciiz "Arquivo de saida (texto cifrado): "
msg_sai_decifrado: .asciiz "Arquivo de saida (texto decifrado): "
msg_senha:         .asciiz "Senha (digite na caixa KEYBOARD do MMIO): "
msg_senha_vazia:   .asciiz "Senha vazia.\n"
msg_erro_ler:      .asciiz "Erro ao ler o arquivo de entrada.\n"
msg_erro_criar:    .asciiz "Erro ao criar o arquivo de saida.\n"
msg_concluido:     .asciiz "Concluido!\n"

.text
main:

# printf("=== Criptografia RC4 ===\n");
# printf("1) Criptografar\n2) Descriptografar\n");
        addi $v0, $zero, 4          # 4 = imprimir texto
        la   $a0, msg_titulo
        syscall

# ler_linha("Opcao: ", op, sizeof op);
        addi $v0, $zero, 4
        la   $a0, msg_opcao
        syscall
        addi $v0, $zero, 5          # 5 = ler numero
        syscall
        add  $s6, $v0, $zero        # guarda a opcao em $s6

# if (op[0] != '1' && op[0] != '2') { printf("Opcao invalida.\n"); return 1; }
        addi $t0, $zero, 1
        beq  $s6, $t0, opcao_ok     # se for 1, ta certo
        addi $t0, $zero, 2
        beq  $s6, $t0, opcao_ok     # se for 2, ta certo
        addi $v0, $zero, 4          # senao, avisa e sai
        la   $a0, msg_invalida
        syscall
        j    fim
opcao_ok:

# ler_linha(cifrar ? "Arquivo de entrada (texto claro): "
#                  : "Arquivo de entrada (texto cifrado): ", entrada, sizeof entrada);
        addi $t0, $zero, 1
        bne  $s6, $t0, ent_else     # se nao for criptografar, vai pro else
        la   $a0, msg_ent_claro
        j    ent_fim
ent_else:
        la   $a0, msg_ent_cifrado
ent_fim:
        addi $v0, $zero, 4
        syscall
        addi $v0, $zero, 8          # 8 = ler texto
        la   $a0, entrada
        addi $a1, $zero, 260
        syscall

# buf[strcspn(buf, "\r\n")] = '\0';
#   o MARS guarda o Enter no fim do nome, entao trocamos ele por 0
        la   $t0, entrada
tira_enter_ent:
        lbu  $t1, 0($t0)            # pega um caractere
        beq  $t1, $zero, tira_enter_ent_fim
        addi $t2, $zero, 10         # 10 = Enter
        beq  $t1, $t2, achou_enter_ent
        addi $t0, $t0, 1            # vai pro proximo
        j    tira_enter_ent
achou_enter_ent:
        sb   $zero, 0($t0)          # troca o Enter por 0
tira_enter_ent_fim:

# ler_linha(cifrar ? "Arquivo de saida (texto cifrado): "
#                  : "Arquivo de saida (texto decifrado): ", saida, sizeof saida);
        addi $t0, $zero, 1
        bne  $s6, $t0, sai_else
        la   $a0, msg_sai_cifrado
        j    sai_fim
sai_else:
        la   $a0, msg_sai_decifrado
sai_fim:
        addi $v0, $zero, 4
        syscall
        addi $v0, $zero, 8
        la   $a0, saida
        addi $a1, $zero, 260
        syscall

# buf[strcspn(buf, "\r\n")] = '\0';
        la   $t0, saida
tira_enter_sai:
        lbu  $t1, 0($t0)
        beq  $t1, $zero, tira_enter_sai_fim
        addi $t2, $zero, 10
        beq  $t1, $t2, achou_enter_sai
        addi $t0, $t0, 1
        j    tira_enter_sai
achou_enter_sai:
        sb   $zero, 0($t0)
tira_enter_sai_fim:

# printf("%s", prompt);      (inicio do ler_senha)
        addi $v0, $zero, 4
        la   $a0, msg_senha
        syscall

# int n = 0;
        add  $s3, $zero, $zero      # n = 0 (tamanho da senha)
        la   $t0, senha             # onde vai a proxima letra
        lui  $t1, 0xFFFF            # endereco do teclado MMIO

# while ((c = ler_char_sem_eco()) != '\r' && c != '\n' && c != EOF) {
le_tecla:
espera_tecla:
        lw   $t2, 0($t1)            # ve se tem tecla apertada
        andi $t2, $t2, 1
        beq  $t2, $zero, espera_tecla   # ainda nao, espera
        lw   $t3, 4($t1)            # pega a tecla
        addi $t4, $zero, 10
        beq  $t3, $t4, fim_senha    # apertou Enter, acabou

#   } else if (c >= 32 && c < 127 && n < max - 1) {
        slti $t4, $t3, 32
        bne  $t4, $zero, le_tecla   # tecla especial, ignora
        slti $t4, $t3, 127
        beq  $t4, $zero, le_tecla   # tecla especial, ignora
        slti $t4, $s3, 127
        beq  $t4, $zero, le_tecla   # senha cheia, ignora

#       buf[n++] = (char)c;
        sb   $t3, 0($t0)            # guarda a letra
        addi $t0, $t0, 1
        addi $s3, $s3, 1            # n++

#       putchar('*');
        addi $v0, $zero, 11         # 11 = imprimir um caractere
        addi $a0, $zero, 42         # 42 = '*'
        syscall
        j    le_tecla
#   }
# }
fim_senha:

# buf[n] = '\0';
        sb   $zero, 0($t0)

# putchar('\n');
        addi $v0, $zero, 11
        addi $a0, $zero, 10
        syscall

# if (ler_senha("Senha: ", senha, sizeof senha) == 0) { printf("Senha vazia.\n"); return 1; }
        bne  $s3, $zero, senha_ok
        addi $v0, $zero, 4
        la   $a0, msg_senha_vazia
        syscall
        j    fim
senha_ok:

# FILE *f = fopen(nome, "rb");
# if (!dados) { printf("Erro ao ler '%s'.\n", entrada); return 1; }
        addi $v0, $zero, 13         # 13 = abrir arquivo
        la   $a0, entrada
        add  $a1, $zero, $zero      # 0 = para ler
        add  $a2, $zero, $zero
        syscall
        add  $s4, $v0, $zero        # $s4 = arquivo de entrada
        slt  $t0, $s4, $zero        # deu numero negativo? entao deu erro
        beq  $t0, $zero, abriu_entrada
        addi $v0, $zero, 4
        la   $a0, msg_erro_ler
        syscall
        j    fim
abriu_entrada:

# f = fopen(saida, "wb");
# if (!f) { printf("Erro ao criar '%s'.\n", saida); free(dados); return 1; }
        addi $v0, $zero, 13
        la   $a0, saida
        addi $a1, $zero, 1          # 1 = para escrever
        add  $a2, $zero, $zero
        syscall
        add  $s5, $v0, $zero        # $s5 = arquivo de saida
        slt  $t0, $s5, $zero
        beq  $t0, $zero, abriu_saida
        addi $v0, $zero, 4
        la   $a0, msg_erro_criar
        syscall
        addi $v0, $zero, 16         # fecha a entrada antes de sair
        add  $a0, $s4, $zero
        syscall
        j    fim
abriu_saida:

#   (S e um vetor de bytes: S[i] fica em S + i, sem multiplicar por 4)
        la   $s0, S

# for (i = 0; i < 256; i++) S[i] = (u8)i;
        add  $s1, $zero, $zero      # i = 0
ksa_preenche:
        slti $t0, $s1, 256
        beq  $t0, $zero, ksa_preenche_fim
        add  $t1, $s0, $s1          # endereco de S[i]
        sb   $s1, 0($t1)            # S[i] = i
        addi $s1, $s1, 1            # i++
        j    ksa_preenche
ksa_preenche_fim:

# int i, j = 0;
        add  $s2, $zero, $zero      # j = 0
        la   $t8, senha
        add  $t6, $zero, $zero      # k = 0, posicao na senha (faz o i % tam_chave)

# for (i = 0; i < 256; i++) {
        add  $s1, $zero, $zero      # i = 0
ksa_loop:
        slti $t0, $s1, 256
        beq  $t0, $zero, ksa_fim

#   j = (j + S[i] + chave[i % tam_chave]) & 255;
        add  $t1, $s0, $s1
        lbu  $t2, 0($t1)            # pega S[i]
        add  $t9, $t8, $t6
        lbu  $t3, 0($t9)            # pega a letra da senha
        add  $s2, $s2, $t2
        add  $s2, $s2, $t3
        andi $s2, $s2, 255          # & 255

#   t = S[i]; S[i] = S[j]; S[j] = t;
        add  $t4, $s0, $s2
        lbu  $t5, 0($t4)            # pega S[j]
        sb   $t5, 0($t1)            # S[i] recebe S[j]
        sb   $t2, 0($t4)            # S[j] recebe o S[i] antigo

#   (passa pra proxima letra da senha; no fim da senha, volta pro comeco)
        addi $t6, $t6, 1
        bne  $t6, $s3, k_ok
        add  $t6, $zero, $zero
k_ok:
        addi $s1, $s1, 1            # i++
        j    ksa_loop
# }
ksa_fim:

# i = j = 0;
        add  $s1, $zero, $zero
        add  $s2, $zero, $zero

#   (le o arquivo de 1024 em 1024 bytes, porque aqui nao tem malloc)
le_bloco:
        addi $v0, $zero, 14         # 14 = ler arquivo
        add  $a0, $s4, $zero
        la   $a1, buffer
        addi $a2, $zero, 1024
        syscall
        add  $s7, $v0, $zero        # $s7 = quantos bytes vieram
        slt  $t0, $zero, $s7
        beq  $t0, $zero, arquivo_fim    # nao veio nada, acabou o arquivo
        la   $t8, buffer

# for (k = 0; k < n; k++) {
        add  $t6, $zero, $zero      # k = 0
prga_loop:
        slt  $t0, $t6, $s7
        beq  $t0, $zero, prga_fim

#   i = (i + 1) & 255;
        addi $s1, $s1, 1
        andi $s1, $s1, 255

#   j = (j + S[i]) & 255;
        add  $t1, $s0, $s1
        lbu  $t2, 0($t1)            # pega S[i]
        add  $s2, $s2, $t2
        andi $s2, $s2, 255

#   t = S[i]; S[i] = S[j]; S[j] = t;
        add  $t4, $s0, $s2
        lbu  $t5, 0($t4)            # pega S[j]
        sb   $t5, 0($t1)
        sb   $t2, 0($t4)

#   dados[k] ^= S[(S[i] + S[j]) & 255];
        add  $t3, $t5, $t2          # S[i] + S[j]  (ja trocados)
        andi $t3, $t3, 255
        add  $t3, $s0, $t3
        lbu  $t3, 0($t3)            # pega o byte da chave
        add  $t9, $t8, $t6
        lbu  $t7, 0($t9)            # pega dados[k]
        xor  $t7, $t7, $t3          # embaralha
        sb   $t7, 0($t9)            # guarda de volta

        addi $t6, $t6, 1            # k++
        j    prga_loop
# }
prga_fim:

# fwrite(dados, 1, n, f);
        addi $v0, $zero, 15         # 15 = escrever no arquivo
        add  $a0, $s5, $zero
        la   $a1, buffer
        add  $a2, $s7, $zero
        syscall
        j    le_bloco               # volta pra ler o proximo pedaco

arquivo_fim:

# fclose(f);
        addi $v0, $zero, 16         # 16 = fechar arquivo
        add  $a0, $s4, $zero
        syscall
        addi $v0, $zero, 16
        add  $a0, $s5, $zero
        syscall

# printf("Concluido: %s -> %s (%ld bytes)\n", entrada, saida, n);
        addi $v0, $zero, 4
        la   $a0, msg_concluido
        syscall

# return 0;
fim:
        addi $v0, $zero, 10         # 10 = encerrar
        syscall
