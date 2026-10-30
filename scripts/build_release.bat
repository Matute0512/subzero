@echo off
REM Script de compilación oficial para Google Play Store
REM Inyecta de forma segura las claves de producción desde secrets.json y ofusca el binario Dart

if not exist secrets.json (
    echo [AVISO] No se encontro 'secrets.json'. Se compilara con IDs de prueba oficiales de Google.
    flutter build appbundle --release --obfuscate --split-debug-info=build/app/outputs/symbols
) else (
    echo [INFO] Compilando App Bundle (AAB) con claves de produccion y ofuscacion...
    flutter build appbundle --release --dart-define-from-file=secrets.json --obfuscate --split-debug-info=build/app/outputs/symbols
)
