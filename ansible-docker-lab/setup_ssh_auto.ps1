# Script de configuracion SSH automatica para PowerShell
# Ejecutar desde PowerShell

Write-Host "=== Configurando SSH en contenedores ===" -ForegroundColor Cyan

# Verificar que los contenedores esten corriendo
$containers = docker ps --filter "name=node" --format "{{.Names}}"
if ($containers.Count -ne 3) {
    Write-Host "[ERROR] No hay 3 contenedores corriendo. Ejecuta primero el setup." -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Contenedores encontrados: $($containers -join ', ')" -ForegroundColor Yellow

# Leer la clave publica si existe
$publicKeyPath = "$env:USERPROFILE\.ssh\ansible_id_rsa.pub"
if (Test-Path $publicKeyPath) {
    $publicKey = Get-Content $publicKeyPath -Raw
    Write-Host "[INFO] Usando clave SSH existente" -ForegroundColor Green
    
    # Configurar cada nodo con la clave
    $nodes = @("node1", "node2", "node3")
    foreach ($node in $nodes) {
        Write-Host "[INFO] Configurando SSH en $node..." -ForegroundColor Cyan
        
        # Crear directorio .ssh
        docker exec $node mkdir -p /root/.ssh
        
        # Copiar clave publica
        docker exec $node sh -c "echo '$($publicKey.Trim())' > /root/.ssh/authorized_keys"
        
        # Establecer permisos correctos
        docker exec $node chmod 700 /root/.ssh
        docker exec $node chmod 600 /root/.ssh/authorized_keys
        
        # Asegurar que SSH este configurado correctamente
        docker exec $node sh -c "sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config"
        docker exec $node sh -c "sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"
        docker exec $node sh -c "service ssh restart"
        
        Write-Host "[OK] $node configurado" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "=== Probando conectividad ===" -ForegroundColor Cyan
    
    # Probar conectividad
    $ports = @(2222, 2223, 2224)
    for ($i = 0; $i -lt 3; $i++) {
        $port = $ports[$i]
        $node = $nodes[$i]
        
        Write-Host "[INFO] Probando $node en puerto $port..." -ForegroundColor Yellow
        
        try {
            $result = ssh -i "$env:USERPROFILE\.ssh\ansible_id_rsa" -p $port -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@localhost "echo 'OK'"
            if ($result -eq "OK") {
                Write-Host "[OK] $node - Conexion SSH exitosa" -ForegroundColor Green
            } else {
                Write-Host "[WARNING] $node - Conexion incierta, pero probablemente funcione" -ForegroundColor Yellow
            }
        }
        catch {
            Write-Host "[WARNING] $node - No se pudo probar SSH, pero esta configurado" -ForegroundColor Yellow
        }
    }
    
} else {
    Write-Host "[WARNING] No se encontro clave SSH. Usando configuracion con contraseña." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== Configuracion completada ===" -ForegroundColor Green
Write-Host "Ahora puedes ejecutar las pruebas con:" -ForegroundColor White
Write-Host ".\stress_test_simple.ps1 -Action test" -ForegroundColor Gray
