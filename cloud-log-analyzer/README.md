# Práctica 4.2 - Mini Cloud Log Analyzer
## Variante D: Detección de 3 errores consecutivos

## Descripción
Este programa lee códigos HTTP desde stdin y detecta si ocurren
tres errores consecutivos (4xx o 5xx). Si se detectan, imprime
una alerta. Si no, imprime que no hubo patrón.

## Lógica utilizada
- Se usa un contador x19 para errores consecutivos
- Si el código es 4xx o 5xx: se incrementa el contador
- Si el código es 2xx: se reinicia el contador a 0
- Si el contador llega a 3: se activa la bandera x20 = 1
- Al terminar la lectura se imprime el resultado

## Registros ARM64 utilizados
- x19: contador de errores consecutivos
- x20: bandera de detección (1 = detectado)
- x22: número actual acumulado
- x23: indica si hay dígitos acumulados

## Compilación
make

## Ejecución
cat data/logs_D.txt | ./analyzer

## Evidencia de ejecución
=== Mini Cloud Log Analyzer - Variante D ===
[ALERTA] Se detectaron 3 errores consecutivos!

## Prueba con 1000 datos

Se genero un archivo logs_D.txt con 1000 codigos HTTP aleatorios
usando los siguientes codigos reales:

1xx: 100, 101, 102, 103
2xx: 200, 201, 202, 203, 204, 205, 206, 207, 208, 226
3xx: 300, 301, 302, 303, 304, 305, 307, 308
4xx: 400, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410,
     411, 412, 413, 414, 415, 416, 417, 418, 421, 422, 423,
     424, 425, 426, 428, 429, 431, 451
5xx: 500, 501, 502, 503, 504, 505, 506, 507, 508, 510, 511

Resultado con 1000 datos:
=== Mini Cloud Log Analyzer - Variante D ===
[ALERTA] Se detectaron 3 errores consecutivos!

Grabacion asciinema: evidencia.cast
