.equ SYS_read,  63
.equ SYS_write, 64
.equ SYS_exit,  93
.equ STDIN_FD,   0
.equ STDOUT_FD,  1

.section .bss
    .align 4
buffer:  .skip 4096
num_buf: .skip 32

.section .data
msg_titulo:    .asciz "=== Mini Cloud Log Analyzer - Variante D ===\n"
msg_alerta:    .asciz "[ALERTA] Se detectaron 3 errores consecutivos!\n"
msg_ok:        .asciz "[OK] No se detectaron 3 errores consecutivos.\n"
msg_newline:   .asciz "\n"

.section .text
.global _start

_start:
    mov x19, #0
    mov x20, #0
    mov x22, #0
    mov x23, #0

leer_bloque:
    mov x0, #STDIN_FD
    adrp x1, buffer
    add  x1, x1, :lo12:buffer
    mov  x2, #4096
    mov  x8, #SYS_read
    svc  #0
    cmp x0, #0
    beq fin_lectura
    blt salida_error
    mov x24, #0
    mov x25, x0

procesar_byte:
    cmp x24, x25
    b.ge leer_bloque
    adrp x1, buffer
    add  x1, x1, :lo12:buffer
    ldrb w26, [x1, x24]
    add  x24, x24, #1
    cmp w26, #10
    b.eq fin_numero
    cmp w26, #'0'
    b.lt procesar_byte
    cmp w26, #'9'
    b.gt procesar_byte
    mov  x27, #10
    mul  x22, x22, x27
    sub  w26, w26, #'0'
    uxtw x26, w26
    add  x22, x22, x26
    mov  x23, #1
    b    procesar_byte

fin_numero:
    cbz x23, reiniciar_numero
    mov x0, x22
    bl  clasificar_codigo

reiniciar_numero:
    mov x22, #0
    mov x23, #0
    b   procesar_byte

fin_lectura:
    cbz x23, imprimir_reporte
    mov x0, x22
    bl  clasificar_codigo

imprimir_reporte:
    adrp x0, msg_titulo
    add  x0, x0, :lo12:msg_titulo
    bl   write_cstr
    cbnz x20, imprimir_alerta

imprimir_ok:
    adrp x0, msg_ok
    add  x0, x0, :lo12:msg_ok
    bl   write_cstr
    b    salida_ok

imprimir_alerta:
    adrp x0, msg_alerta
    add  x0, x0, :lo12:msg_alerta
    bl   write_cstr

salida_ok:
    mov x0, #0
    mov x8, #SYS_exit
    svc #0

salida_error:
    mov x0, #1
    mov x8, #SYS_exit
    svc #0

clasificar_codigo:
    cmp x0, #400
    b.lt revisar_5xx
    cmp x0, #499
    b.gt revisar_5xx
    b   es_error

revisar_5xx:
    cmp x0, #500
    b.lt es_exito
    cmp x0, #599
    b.gt es_exito
    b   es_error

es_error:
    add x19, x19, #1
    cmp x19, #3
    b.lt clasificar_fin
    mov x20, #1
    b   clasificar_fin

es_exito:
    mov x19, #0

clasificar_fin:
    ret

write_cstr:
    mov x9,  x0
    mov x10, #0
wc_len_loop:
    ldrb w11, [x9, x10]
    cbz  w11, wc_len_done
    add  x10, x10, #1
    b    wc_len_loop
wc_len_done:
    mov x1, x9
    mov x2, x10
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret
