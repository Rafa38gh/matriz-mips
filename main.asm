.data
txt_n:              .asciiz "Insira o tamanho da matriz (n x n): "
txt_num:            .asciiz "Insira os numeros da matriz (valores reais): \n"
txt_cabecalho:      .asciiz "\nMatriz:\n"
txt_orig_header:    .asciiz "\n--- Matriz Original ---\n"
txt_inv_header:     .asciiz "\n--- Matriz Inversa (A^-1) ---\n"
err_n:              .asciiz "Erro! O valor inserido deve estar entre 2 e 10 \n"
err_inv:            .asciiz "Matriz singular: sem inversa.\n"
espaco:             .asciiz " "
enter:              .asciiz "\n"


# Matrizes
orig:         .space 400
aug:          .space 800

# Variáveis temporárias
pivot_val:    .float 0.0
fator_val:    .float 0.0
    
.text
.globl main
main:
    # Ler n
    li $v0, 4
    la $a0, txt_n
    syscall

    la $a0, enter   # Limpa o buffer
    syscall

    li $v0, 5
    syscall
    move $t0, $v0       # $t0 = n

    li $t1, 2
    blt $t0, $t1, erro_n
    li $t1, 10
    bgt $t0, $t1, erro_n

    # Ler matriz
    jal ler_elements
    jal cria_identidade
    
    # Print do cabeçalho
    li $v0, 4
    la $a0, txt_cabecalho
    syscall

    # Print matriz original
    li $v0,4
    la $a0, txt_orig_header
    syscall
    jal print_matriz_original

    # executar gauss-jordan
    jal gauss_jordan

    # Print inversa
    li $v0,4
    la $a0, txt_inv_header
    syscall
    jal print_inversa

    j fim

erro_n:
    li $v0, 4
    la $a0, err_n
    syscall
    j main

# ======================
# LER ELEMENTOS
# ======================
ler_elements:
    li $v0, 4
    la $a0, txt_num
    syscall

    move $t1, $zero           # index
    mul $t2, $t0, $t0         # t2 = total elementos

ler_loop:   # $f0 = valor lido, $t1 = index, $t0 = n, $t7 = linha, $t8 = coluna
    beq $t1, $t2, ret_leitura

    li $v0, 6            # ler float, valor em $f0
    syscall           

    # calcular linha
    move $t6, $t1
    div $t6, $t0
    mflo $t7              # linha = $t7
    mfhi $t8              # coluna = $t8

    # armazenar na matriz original
    la $t3, orig
    mul $t4, $t7, $t0     # $t4 = (linha * n) + col
    add $t4, $t4, $t8     
    sll $t4, $t4, 2       # byte offset
    add $t5, $t3, $t4
    s.s $f0, 0($t5)

    # armazenar na parte esquerda da aumentada
    la $t3, aug
    mul $t9, $t7, $t0     # $t9 = (linha * n)
    add $t9, $t9, $t9     # t9 = linha * 2n

    add $t9, $t9, $t8     
    sll $t9, $t9, 2       # byte offset
    add $t9, $t3, $t9
    s.s $f0, 0($t9)

    addi $t1, $t1, 1
    j ler_loop

ret_leitura:
    jr $ra

# ======================
# CRIAR MATRIZ IDENTIDADE
# ======================
cria_identidade:
    # Criar identidade na parte direita da matriz aumentada
    li $t1, 0              # linha
init_linha:
    beq $t1,$t0, ret_identidade
    li $t2, 0             # coluna
init_col:
    beq $t2, $t0, prox_linha
    # endereço para aug[row][n + col]
    la $t3, aug
    sll $t6, $t0, 1         # $t6 = 2*n
    mul $t4, $t1, $t6       # linha * (2*n)
    add $t4, $t4, $t0       # pula as colunas da esquerda
    add $t4, $t4, $t2       # índice da coluna
    sll $t4, $t4, 2         # byte offset
    add $t5, $t3, $t4

    beq $t1,$t2, diagonal   # diagonal
    li.s $f1, 0.0           # fora da diagonal = 0.0
    s.s $f1, 0($t5)
    j prox_col

diagonal:                   
    li.s $f1, 1.0
    s.s $f1,0($t5)

prox_col:              
    addi $t2,$t2,1
    j init_col

prox_linha:
    addi $t1,$t1,1
    j init_linha

ret_identidade:
    jr $ra


# ======================
# IMPRIME MATRIZ ORIGINAL
# ======================
print_matriz_original:
    li $t1, 0            # linha
print_linha_orig:
    beq $t1, $t0, ret_print_orig
    li $t2,0            # coluna

print_orig_col:
    beq $t2,$t0, print_space_orig
    la $t3, orig
    mul $t4,$t1,$t0
    add $t4,$t4,$t2
    sll $t4,$t4,2
    add $t5,$t3,$t4
    l.s $f12,0($t5)
    li $v0,2
    syscall
    li $v0,4
    la $a0,espaco
    syscall
    addi $t2,$t2,1
    j print_orig_col

print_space_orig:
    li $v0, 4
    la $a0, espaco
    syscall
    li $t2, 0

    # imprimir espaço antes da inversa
    li $v0, 4
    la $a0, espaco
    syscall

    li $v0, 4
    la $a0, enter
    syscall
    addi $t1, $t1, 1
    j print_linha_orig

ret_print_orig:
    jr $ra


# ======================
# IMPRIME INVERSA
# ======================
print_inversa:
    # $t0 = n, $t1 = 2*n
    sll $t1, $t0, 1
    li $t2, 0           # linha

print_inv_linha:
    beq $t2, $t0, ret_print_inv
    li $t3, 0           # coluna

print_inv_col:
    beq $t3, $t0, end_print_inv_cols
    la $t4, aug
    mul $t5, $t2, $t1    # linha * colunas
    add $t5, $t5, $t3
    add $t5, $t5, $t0    # pega a parte direita da matriz
    sll $t5, $t5, 2      # byte offset
    add $t6, $t4, $t5
    l.s $f12, 0($t6)
    li $v0, 2           # print float
    syscall
    li $v0, 4           # print espaço
    la $a0, espaco
    syscall
    addi $t3, $t3, 1    # coluna + 1 
    j print_inv_col

end_print_inv_cols:
    li $v0,4
    la $a0,enter
    syscall
    addi $t2, $t2, 1
    j print_inv_linha

ret_print_inv:
    jr $ra


# ======================
# GAUSS-JORDAN
# ======================
gauss_jordan:
    # $t0 = n, $t1 = 2*n
    sll $t1, $t0, 1      # t1 = 2*n

    li $t2, 0            # índice da linha do pivot
gj_fora:
    beq $t2, $t0, ret_gj

    # carregar pivot = aug[t2][t2]
    la $t3, aug
    mul $t4, $t2, $t1    # posição da linha do pivot
    add $t4, $t4, $t2    # + col pivot
    sll $t4, $t4, 2      # byte offset
    add $t5, $t3, $t4
    l.s $f0, 0($t5)

    li.s $f1, 0.0       # compara pivot com 0
    c.eq.s $f0, $f1
    bc1f pivot_ok       # pivot != 0, continuar

    # Pegar linha abaixo (pivot = 0)
    addi $t6, $t2, 1
procura_linha:                      # procura linha com valor != 0
    bge $t6, $t0, matriz_singular   # sem linha válida
    la $t3, aug
    mul $t4, $t6, $t1
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f0, 0($t5)
    li.s $f1, 0.0
    c.eq.s $f0, $f1
    bc1t gj_prox_linha

    # troca linhas $t2 com $t6
    move $a0, $t2
    move $a1, $t6
    jal troca_linhas                # troca linha para uma válida
    j recarrega_pivot

gj_prox_linha:
    addi $t6, $t6, 1
    j procura_linha

recarrega_pivot:
    # recarregar pivot
    la $t3, aug
    mul $t4, $t2, $t1       # posição da linha do pivot
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f0, 0($t5)

pivot_ok:                   # calcula a inversa do pivot
    # fator = 1 / pivot
    li.s $f1, 1.0
    div.s $f2, $f1, $f0

    # dividir linha pivot
    li $t7, 0
div_linha_pivot:
    beq $t7, $t1, fim_div
    la $t3, aug
    mul $t4, $t2, $t1
    add $t4, $t4, $t7
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f3, 0($t5)
    mul.s $f3, $f3, $f2
    s.s $f3, 0($t5)
    addi $t7, $t7, 1
    j div_linha_pivot

fim_div:
    # eliminar outras linhas
    li $t8, 0
elim_linhas:
    beq $t8, $t0, prox_pivot
    beq $t8, $t2, pular_linha

    # fator = aug[t8][t2]
    la $t3, aug
    mul $t4, $t8, $t1
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f4, 0($t5)

    # para cada coluna c: aug[t8][c] -= fator * aug[t2][c]
    li $t9, 0
elim_colunas:
    beq $t9, $t1, fim_cols
    la $t3, aug
    mul $t4, $t8, $t1
    add $t4, $t4, $t9
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f5, 0($t5)

    la $t3, aug
    mul $t4, $t2, $t1
    add $t4, $t4, $t9
    sll $t4, $t4, 2
    add $t6, $t3, $t4
    l.s $f6, 0($t6)

    mul.s $f7, $f4, $f6
    sub.s $f5, $f5, $f7
    s.s $f5, 0($t5)

    addi $t9, $t9, 1
    j elim_colunas

fim_cols:
    addi $t8, $t8, 1
    j elim_linhas

pular_linha:
    addi $t8, $t8, 1
    j elim_linhas

prox_pivot:
    addi $t2, $t2, 1
    j gj_fora

ret_gj:
    jr $ra


troca_linhas:                           # $a0 = linha1, $a1 = linha2
    # $t1 = total de colunas (2*n)
    sll $t1, $t0, 1
    li $t4, 0
troca_loop:
    beq $t4, $t1, ret_troca_linhas

    la $t5, aug
    mul $t6, $a0, $t1
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t7, $t5, $t6
    l.s $f0, 0($t7)

    la $t5, aug
    mul $t6, $a1, $t1
    add $t6, $t6, $t4
    sll $t6, $t6, 2
    add $t8, $t5, $t6
    l.s $f1, 0($t8)

    s.s $f1, 0($t7)
    s.s $f0, 0($t8)

    addi $t4, $t4, 1
    j troca_loop

ret_troca_linhas:
    jr $ra

# ======================
# MATRIZ SINGULAR
# ======================
matriz_singular:
    li $v0,4
    la $a0,err_inv
    syscall

fim:
    li $v0,10
    syscall
