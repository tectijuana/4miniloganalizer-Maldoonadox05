/*
Autor: Franciusco Eliud Maldonado Morales (Variante D)
Materia: Lemguajes de Interfaz / Ensamblador ARM64
Práctica: Mini Cloud Log Analyzer - Variante D
Fecha: 21 de Abril de 2026
Descripción:
    Lee códigos HTTP desde stdin (uno por línea).
    Detecta si ocurren TRES errores consecutivos (4xx o 5xx).
    Si se detectan, imprime una alerta. Si no, imprime que no hubo patrón.

LÓGICA GENERAL (pseudocódigo):
    consecutivos = 0       // cuántos errores seguidos llevamos
    detectado    = 0       // bandera: 1 si ya encontramos 3 seguidos

    para cada código leído:
        si código es 4xx o 5xx:
            consecutivos += 1
            si consecutivos >= 3:
                detectado = 1
        si código es 2xx:
            consecutivos = 0   // se rompe la racha, reiniciamos

    al terminar:
        si detectado == 1 → imprimir alerta
        si detectado == 0 → imprimir "sin patrón detectado"
*/

// ─── Constantes de syscalls Linux ARM64 ───────────────────────────────────────
.equ SYS_read,  63
.equ SYS_write, 64
.equ SYS_exit,  93
.equ STDIN_FD,   0
.equ STDOUT_FD,  1

// ─── Sección BSS: memoria sin inicializar ─────────────────────────────────────
.section .bss
    .align 4
buffer:  .skip 4096    // buffer de lectura desde stdin
num_buf: .skip 32      // buffer auxiliar para imprimir enteros

// ─── Sección DATA: mensajes de salida ─────────────────────────────────────────
.section .data
msg_titulo:    .asciz "=== Mini Cloud Log Analyzer - Variante D ===\n"
msg_alerta:    .asciz "[ALERTA] Se detectaron 3 errores consecutivos!\n"
msg_ok:        .asciz "[OK] No se detectaron 3 errores consecutivos.\n"
msg_newline:   .asciz "\n"

// ─── Sección TEXT: código ejecutable ──────────────────────────────────────────
.section .text
.global _start

_start:
    // ── Inicializar registros de estado ──────────────────────────────────────
    mov x19, #0     // consecutivos: cuántos errores seguidos llevamos
    mov x20, #0     // detectado:    1 si ya vimos 3 errores consecutivos

    // ── Estado del parser de números ─────────────────────────────────────────
    mov x22, #0     // numero_actual: dígitos acumulados del código actual
    mov x23, #0     // tiene_digitos: 1 si recibimos al menos un dígito

// ─────────────────────────────────────────────────────────────────────────────
// BUCLE PRINCIPAL: leer bloques desde stdin
// ─────────────────────────────────────────────────────────────────────────────
leer_bloque:
    // syscall read(STDIN_FD, buffer, 4096) → x0 = bytes leídos
    mov x0, #STDIN_FD
    adrp x1, buffer
    add  x1, x1, :lo12:buffer
    mov  x2, #4096
    mov  x8, #SYS_read
    svc  #0

    cmp x0, #0
    beq fin_lectura     // 0 bytes = EOF
    blt salida_error    // negativo = error de lectura

    mov x24, #0         // índice i = 0  (posición dentro del bloque)
    mov x25, x0         // total de bytes en este bloque

// ─────────────────────────────────────────────────────────────────────────────
// PROCESAR BYTE A BYTE dentro del bloque leído
// ─────────────────────────────────────────────────────────────────────────────
procesar_byte:
    cmp x24, x25
    b.ge leer_bloque            // agotamos el bloque, pedir más

    adrp x1, buffer
    add  x1, x1, :lo12:buffer
    ldrb w26, [x1, x24]         // w26 = byte actual
    add  x24, x24, #1           // avanzar índice

    // ¿Es salto de línea '\n' (ASCII 10)?
    cmp w26, #10
    b.eq fin_numero

    // ¿Es dígito '0'..'9' (ASCII 48..57)?
    cmp w26, #'0'
    b.lt procesar_byte          // menor que '0' → ignorar
    cmp w26, #'9'
    b.gt procesar_byte          // mayor que '9' → ignorar

    // Acumular dígito: numero_actual = numero_actual * 10 + (byte - '0')
    mov  x27, #10
    mul  x22, x22, x27
    sub  w26, w26, #'0'         // convertir ASCII → valor numérico
    uxtw x26, w26               // extender a 64 bits sin signo
    add  x22, x22, x26
    mov  x23, #1                // marcar que tenemos al menos un dígito
    b    procesar_byte

// ─────────────────────────────────────────────────────────────────────────────
// FIN DE NÚMERO: llegó '\n' o EOF, clasificar el código acumulado
// ─────────────────────────────────────────────────────────────────────────────
fin_numero:
    cbz x23, reiniciar_numero   // sin dígitos = línea vacía, ignorar

    mov x0, x22                 // pasar el código a la función clasificadora
    bl  clasificar_codigo

reiniciar_numero:
    mov x22, #0                 // limpiar acumulador
    mov x23, #0                 // limpiar bandera de dígitos
    b   procesar_byte

// ─────────────────────────────────────────────────────────────────────────────
// FIN DE LECTURA (EOF): procesar número pendiente si no hubo '\n' final
// ─────────────────────────────────────────────────────────────────────────────
fin_lectura:
    cbz x23, imprimir_reporte   // sin dígitos pendientes → ir al reporte
    mov x0, x22
    bl  clasificar_codigo

// ─────────────────────────────────────────────────────────────────────────────
// IMPRIMIR REPORTE FINAL
// ─────────────────────────────────────────────────────────────────────────────
imprimir_reporte:
    // Imprimir título
    adrp x0, msg_titulo
    add  x0, x0, :lo12:msg_titulo
    bl   write_cstr

    // Decidir mensaje según la bandera "detectado"
    cbnz x20, imprimir_alerta   // x20 != 0 → hubo 3 consecutivos

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

// =============================================================================
// FUNCIÓN: clasificar_codigo
// Entrada:  x0 = código HTTP leído
// Efecto:   actualiza x19 (consecutivos) y x20 (detectado)
// Sin valor de retorno.
// =============================================================================
clasificar_codigo:
    // ── ¿Es error 4xx? (400 ≤ código ≤ 499) ─────────────────────────────────
    cmp x0, #400
    b.lt revisar_5xx            // menor que 400 → revisar si es 5xx o 2xx
    cmp x0, #499
    b.gt revisar_5xx            // mayor que 499 → revisar si es 5xx
    b   es_error                // está en rango 4xx → es error

revisar_5xx:
    // ── ¿Es error 5xx? (500 ≤ código ≤ 599) ─────────────────────────────────
    cmp x0, #500
    b.lt es_exito               // menor que 500 → no es 5xx; tratar como éxito/reset
    cmp x0, #599
    b.gt es_exito               // mayor que 599 → fuera de rango; reset por seguridad
    b   es_error                // está en rango 5xx → es error

// ─── El código es un ERROR (4xx o 5xx) ───────────────────────────────────────
es_error:
    add x19, x19, #1            // incrementar contador de errores consecutivos

    // ¿Llegamos a 3 o más errores seguidos?
    cmp x19, #3
    b.lt clasificar_fin         // todavía no llegamos a 3
    mov x20, #1                 // ¡DETECTADO! activar bandera
    b   clasificar_fin

// ─── El código es un ÉXITO (2xx) u otro → reiniciar racha ───────────────────
es_exito:
    mov x19, #0                 // romper racha: reiniciar contador consecutivo

clasificar_fin:
    ret

// =============================================================================
// FUNCIÓN: write_cstr
// Entrada:  x0 = puntero a string terminado en '\0'
// Imprime la cadena completa usando syscall write.
// =============================================================================
write_cstr:
    mov x9,  x0     // guardar puntero al inicio
    mov x10, #0     // longitud = 0

wc_len_loop:
    ldrb w11, [x9, x10]         // leer byte en posición actual
    cbz  w11, wc_len_done       // si es '\0' → fin de cadena
    add  x10, x10, #1
    b    wc_len_loop

wc_len_done:
    mov x1, x9                  // puntero al buffer
    mov x2, x10                 // longitud
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret

// =============================================================================
// FUNCIÓN: print_uint
// Entrada:  x0 = entero sin signo
// Convierte a ASCII decimal e imprime. (Disponible si se necesita depuración)
// =============================================================================
print_uint:
    cbnz x0, pu_convertir
    adrp x1, num_buf
    add  x1, x1, :lo12:num_buf
    mov  w2, #'0'
    strb w2, [x1]
    mov  x0, #STDOUT_FD
    mov  x2, #1
    mov  x8, #SYS_write
    svc  #0
    ret

pu_convertir:
    adrp x12, num_buf
    add  x12, x12, :lo12:num_buf
    add  x12, x12, #31
    mov  w13, #0
    strb w13, [x12]

    mov x14, #10
    mov x15, #0

pu_loop:
    udiv x16, x0,  x14
    msub x17, x16, x14, x0
    add  x17, x17, #'0'
    sub  x12, x12, #1
    strb w17, [x12]
    add  x15, x15, #1
    mov  x0,  x16
    cbnz x0, pu_loop

    mov x1, x12
    mov x2, x15
    mov x0, #STDOUT_FD
    mov x8, #SYS_write
    svc #0
    ret
