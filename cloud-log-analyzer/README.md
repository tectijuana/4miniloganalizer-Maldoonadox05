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
