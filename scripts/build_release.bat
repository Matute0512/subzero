@echo off
REM Script de compilación oficial para Google Play Store
REM Inyecta de forma segura las claves de producción desde secrets.json

if not exist secrets.json (
    echo [AVISO] No se encontro 'secrets.json'. Se compilara con IDs de prueba oficiales de Google.
    flutter build appbundle --release
) else (
    echo [INFO] Compilando App Bundle (AAB) con claves de produccion...
    flutter build appbundle --release --dart-define-from-file=secrets.json
)

