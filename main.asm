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

    jal ler_elements

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
    beq $t1, $t2, cria_identidade

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

# ======================
# CRIAR MATRIZ IDENTIDADE
# ======================
cria_identidade:
    # Criar identidade na parte direita da matriz aumentada
    li $t1, 0              # linha
init_linha:
    beq $t1,$t0, print_matriz
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

# ======================
# PRINT DAS MATRIZES
# ======================
print_matriz:
    # Print do cabeçalho
    li $v0,4
    la $a0,txt_cabecalho
    syscall

    # Print matriz original
    li $v0,4
    la $a0, txt_orig_header
    syscall
    jal print_matriz_original

    # executar gauss-jordan
    jal gauss_jordan_aug

    # Print inversa
    li $v0,4
    la $a0, txt_inv_header
    syscall
    jal print_inverse

    j fim

# ======================
# PRINT MATRIZ
# ======================

# ======================
# IMPRIME MATRIZ ORIGINAL
# ======================
print_matriz_original:
    li $t1,0            # linha
print_row_orig:
    beq $t1,$t0, ret_print_orig
    li $t2,0            # coluna

print_orig_col2:
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
    j print_orig_col2

print_space_orig:
    li $v0,4
    la $a0,espaco
    syscall
    li $t2,0

    # imprimir espaço antes da inversa (colunas da parte inversa serão impressas depois)
    li $v0,4
    la $a0,espaco
    syscall

    li $v0,4
    la $a0,enter
    syscall
    addi $t1,$t1,1
    j print_row_orig

ret_print_orig:
    jr $ra


# ======================
# IMPRIME INVERSA (direita da augmentada)
# ======================
print_inverse:
    # $t0 = n ; $t1 = totalCols = 2*n
    sll $t1, $t0, 1
    # linha
    li $t2, 0
print_inv_row:
    beq $t2, $t0, ret_print_inv
    # coluna da inversa: col = n .. 2n-1
    li $t3, 0
print_inv_col:
    beq $t3, $t0, end_print_inv_cols
    la $t4, aug
    mul $t5, $t2, $t1    # row * totalCols
    add $t5, $t5, $t3
    add $t5, $t5, $t0    # + n to shift to right half
    sll $t5, $t5, 2
    add $t6, $t4, $t5
    l.s $f12, 0($t6)
    li $v0, 2
    syscall
    li $v0, 4
    la $a0, espaco
    syscall
    addi $t3, $t3, 1
    j print_inv_col

end_print_inv_cols:
    li $v0,4
    la $a0,enter
    syscall
    addi $t2, $t2, 1
    j print_inv_row

ret_print_inv:
    jr $ra


# ======================
# GAUSS-JORDAN NA MATRIZ AUMENTADA
# ======================
gauss_jordan_aug:
    # $t0 = n
    # $tcols = 2*n (usaremos $t1)
    sll $t1, $t0, 1      # t1 = 2*n

    li $t2, 0            # pivot row index
gj_outer2:
    beq $t2, $t0, gj_done2

    # carregar pivot = aug[t2][t2]
    la $t3, aug
    mul $t4, $t2, $t1    # row * totalCols
    add $t4, $t4, $t2    # + col (pivot col)
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f0, 0($t5)

    li.s $f1, 0.0
    c.eq.s $f0, $f1
    bc1f pivot_ok2

    # procurar linha abaixo com pivot não-zero
    addi $t6, $t2, 1
find_row2:
    bge $t6, $t0, singular_matrix
    la $t3, aug
    mul $t4, $t6, $t1
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f0, 0($t5)
    li.s $f1, 0.0
    c.eq.s $f0, $f1
    bc1t next_candidate2

    # swap linhas t2 <-> t6 (troca across t1 colunas)
    move $a0, $t2
    move $a1, $t6
    jal swap_rows_aug
    j after_swap2

next_candidate2:
    addi $t6, $t6, 1
    j find_row2

after_swap2:
    # recarregar pivot
    la $t3, aug
    mul $t4, $t2, $t1
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f0, 0($t5)

pivot_ok2:
    # fator = 1 / pivot
    li.s $f1, 1.0
    div.s $f2, $f1, $f0

    # dividir linha pivot por pivot (col 0..t1-1)
    li $t7, 0
div_row2:
    beq $t7, $t1, after_div2
    la $t3, aug
    mul $t4, $t2, $t1
    add $t4, $t4, $t7
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f3, 0($t5)
    mul.s $f3, $f3, $f2
    s.s $f3, 0($t5)
    addi $t7, $t7, 1
    j div_row2

after_div2:
    # eliminar outras linhas
    li $t8, 0
elim_rows2:
    beq $t8, $t0, next_pivot2
    beq $t8, $t2, skip_row2

    # fator = aug[t8][t2]
    la $t3, aug
    mul $t4, $t8, $t1
    add $t4, $t4, $t2
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f4, 0($t5)

    # para cada coluna c: aug[t8][c] -= fator * aug[t2][c]
    li $t9, 0
elim_cols2:
    beq $t9, $t1, end_cols2
    la $t3, aug
    mul $t4, $t8, $t1
    add $t4, $t4, $t9
    sll $t4, $t4, 2
    add $t5, $t3, $t4
    l.s $f5, 0($t5)

    # pivot row element
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
    j elim_cols2

end_cols2:
    addi $t8, $t8, 1
    j elim_rows2

skip_row2:
    addi $t8, $t8, 1
    j elim_rows2

next_pivot2:
    addi $t2, $t2, 1
    j gj_outer2

gj_done2:
    jr $ra

    


# Swap rows in augmented matrix: arguments in $a0 = r1, $a1 = r2
swap_rows_aug:
    # $t1 = total columns (2*n) ; recompute
    sll $t1, $t0, 1
    li $t4, 0
swap_loop_aug:
    beq $t4, $t1, swap_done_aug

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
    j swap_loop_aug

swap_done_aug:
    jr $ra

# ======================
# MATRIZ SINGULAR
# ======================
singular_matrix:
    li $v0,4
    la $a0,err_inv
    syscall

fim:
    li $v0,10
    syscall
