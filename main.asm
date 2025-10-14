.data
txt_n:      .asciiz "Insira o tamanho da matriz (n x n): "
txt_num:    .asciiz "Insira os numeros da matriz: \n"

err_n:      .asciiz "Erro! O valor inserido deve estar entre 2 e 10 \n"

espaco:     .asciiz " "
enter:      .asciiz "\n"

TAM_MAT:    .word 10    # Tamanho máximo da matriz

matriz:     .space 400

.text
.globl main

main:

ler_n:
    # Tamanho da matriz
    li $v0, 4       # print txt_n
    la $a0, txt_n
    syscall

    la $a0, enter   # libera buffer
    syscall

    li $v0, 5       # leitura de n
    syscall
    add $t0, $v0, $zero     #t0 = n

    # Verifica Erro
    li $t1, 2
    blt $t0, $t1, erro_num      # t0 < 2

    li $t1, 10
    bgt $t0, $t1, erro_num      # t0 > 10

    j ler_elem

erro_num:
    li $v0, 4       # print do erro
    la $a0, err_n
    syscall

    la $a0, enter   # libera buffer
    syscall

    j ler_n

ler_elem:
    # Elementos da matriz
    li $v0, 4       # print txt_num
    la $a0, txt_num
    syscall

    la $a0, enter   # libera buffer
    syscall

    add $t2, $zero, $zero       # t2 é o contador
    mul $t1, $t0, $t0           # t1 = total de Elementos



loop_leitura:
    beq $t2, $t1, print_matriz

    li $v0, 6       # Lê o número
    syscall
    mov.s $f2, $f0

    la $t3, matriz
    mul $t4, $t2, 4     # deslocamento
    add $t5, $t3, $t4
    s.s $f2, 0($t5)      # Armazena número

    addi $t2, $t2, 1        # Aumenta o contador
    j loop_leitura

# print da matriz
print_matriz:
    li $t5, 0       # t5 = linha

# print das linhas
print_linha:
    beq $t5, $t0, fim       # print completo

    li $t6, 0       # t6 = coluna

print_coluna:
    beq $t6, $t0, prox_linha        # terminou a linha atual

    #índice
    mul $t7, $t5, $t0   
    add $t7, $t7, $t6   # t7 = (t5*t0) + t6
    mul $t8, $t7, 4
    la $t9, matriz
    add $t9, $t9, $t8
    l.s $f12, 0($t9)

    # print num float
    li $v0, 2
    syscall

    # print do espaço
    li $v0, 4
    la $a0, espaco
    syscall

    addi $t6, $t6, 1
    j print_coluna

prox_linha:
    li $v0, 4
    la $a0, enter
    syscall
    addi $t5, $t5, 1
    j print_linha

fim:
    li $v0, 10
    syscall