# Script para configurar SSH automáticamente en los contenedores
# Ejecutar desde PowerShell

Write-Host "Configurando SSH en los contenedores..." -ForegroundColor Yellow

# Leer la clave pública
$publicKey = Get-Content "$env:USERPROFILE\.ssh\ansible_id_rsa.pub" -ErrorAction SilentlyContinue

if (-not $publicKey) {
    Write-Host "Error: No se encontró la clave SSH. Ejecuta primero el setup." -ForegroundColor Red
    exit 1
}

Write-Host "Clave SSH encontrada: $($publicKey.Substring(0,50))..." -ForegroundColor Green

# Configurar cada nodo
$nodes = @("node1", "node2", "node3")

foreach ($node in $nodes) {
    Write-Host "Configurando SSH en $node..." -ForegroundColor Cyan
    
    # Crear directorio .ssh
    docker exec $node mkdir -p /root/.ssh
    
    # Copiar clave pública
    docker exec $node sh -c "echo '$publicKey' > /root/.ssh/authorized_keys"
    
    # Establecer permisos correctos
    docker exec $node chmod 700 /root/.ssh
    docker exec $node chmod 600 /root/.ssh/authorized_keys
    
    Write-Host "✅ $node configurado" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Configuración SSH completada!" -ForegroundColor Green
Write-Host "Ahora puedes ejecutar: .\stress_test_simple.ps1 -Action test" -ForegroundColor Yellow
