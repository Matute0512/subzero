# Script de compilación oficial para Google Play Store
# Inyecta de forma segura las claves de producción desde secrets.json

Write-Host "Verificando secrets.json..." -ForegroundColor Cyan
if (-not (Test-Path "secrets.json")) {
    Write-Warning "AVISO: No se encontró 'secrets.json'. Se compilará con IDs de prueba oficiales de Google."
    flutter build appbundle --release
} else {
    Write-Host "Compilando App Bundle (AAB) con claves de producción..." -ForegroundColor Green
    flutter build appbundle --release --dart-define-from-file=secrets.json
}

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✓ Bundle generado con éxito en:" -ForegroundColor Green
    Write-Host "  build\app\outputs\bundle\release\app-release.aab`n" -ForegroundColor Yellow
} else {
    Write-Host "`n✗ Error al generar el bundle." -ForegroundColor Red
}

