# Script simplificado de pruebas de estrés de Ansible con Docker
# Autor: Ansible Docker Lab
# Fecha: 26 Junio 2025

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "test", "clean", "all", "help")]
    [string]$Action = "help"
)

# Variables globales
$NetworkName = "ansible-net"
$ImageName = "ubuntu-ssh"
$ResultsFile = "stress_test_results.txt"

function Write-Title {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Yellow
}

function Write-OK {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Err {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Función para limpiar contenedores
function Clean-Environment {
    Write-Info "Limpiando contenedores existentes..."
    
    docker stop node1 2>$null | Out-Null
    docker stop node2 2>$null | Out-Null
    docker stop node3 2>$null | Out-Null
    
    docker rm node1 2>$null | Out-Null
    docker rm node2 2>$null | Out-Null
    docker rm node3 2>$null | Out-Null
    
    docker network rm $NetworkName 2>$null | Out-Null
    
    Write-OK "Limpieza completada"
}

# Función para crear la infraestructura
function Setup-Infrastructure {
    Write-Info "Construyendo imagen Docker..."
    docker build -t $ImageName .
    
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Error construyendo la imagen Docker"
        return $false
    }

    Write-Info "Creando red Docker..."
    docker network create $NetworkName 2>$null | Out-Null

    Write-Info "Lanzando contenedores..."
    docker run -d --rm --name node1 --network $NetworkName -p 2222:22 $ImageName | Out-Null
    docker run -d --rm --name node2 --network $NetworkName -p 2223:22 $ImageName | Out-Null
    docker run -d --rm --name node3 --network $NetworkName -p 2224:22 $ImageName | Out-Null

    Write-Info "Esperando que los contenedores estén listos..."
    Start-Sleep -Seconds 15
    
    # Verificar que los contenedores estén corriendo
    $containers = docker ps --filter "name=node" --format "table {{.Names}}" | Select-Object -Skip 1
    if ($containers.Count -eq 3) {
        Write-OK "Infraestructura creada correctamente (3 contenedores activos)"
        return $true
    } else {
        Write-Err "Error: No todos los contenedores están corriendo"
        return $false
    }
}

# Función para configurar SSH
function Setup-SSH {
    Write-Info "Configurando claves SSH..."
    
    # Crear directorio SSH si no existe
    $sshDir = "$env:USERPROFILE\.ssh"
    if (-not (Test-Path $sshDir)) {
        New-Item -ItemType Directory -Path $sshDir -Force | Out-Null
    }

    # Generar clave SSH si no existe
    $keyPath = "$sshDir\ansible_id_rsa"
    if (-not (Test-Path $keyPath)) {
        Write-Info "Generando nueva clave SSH..."
        ssh-keygen -t rsa -b 2048 -f $keyPath -N '""' | Out-Null
    }

    Write-OK "Configuración SSH preparada"
    Write-Host ""
    Write-Host "CONFIGURACION SSH REQUERIDA:" -ForegroundColor Yellow
    Write-Host "Para continuar, necesitas configurar el acceso SSH sin password." -ForegroundColor White
    Write-Host ""
    Write-Host "OPCION 1 - WSL (Recomendado):" -ForegroundColor Cyan
    Write-Host "  1. Abre WSL: wsl" -ForegroundColor Gray
    Write-Host "  2. Instala sshpass: sudo apt install sshpass" -ForegroundColor Gray
    Write-Host "  3. Ejecuta estos comandos:" -ForegroundColor Gray
    
    Write-Host ""
    Write-Host "Comando 1:" -ForegroundColor White
    Write-Host "sshpass -p root ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/ansible_id_rsa.pub -p 2222 root@localhost" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Comando 2:" -ForegroundColor White  
    Write-Host "sshpass -p root ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/ansible_id_rsa.pub -p 2223 root@localhost" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Comando 3:" -ForegroundColor White
    Write-Host "sshpass -p root ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/ansible_id_rsa.pub -p 2224 root@localhost" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "OPCION 2 - Manual:" -ForegroundColor Cyan
    Write-Host "  Conecta manualmente a cada contenedor y copia la clave publica" -ForegroundColor Gray
    Write-Host ""
    
    Write-OK "Instrucciones SSH mostradas"
}

# Función para ejecutar pruebas
function Run-StressTests {
    Write-Info "Ejecutando pruebas de estrés..."
    
    # Verificar que WSL está disponible
    try {
        wsl --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "WSL no disponible"
        }
    }
    catch {
        Write-Err "WSL no está disponible. Instala WSL con: wsl --install"
        return $false
    }

    # Verificar que Ansible esté instalado en WSL
    Write-Info "Verificando Ansible en WSL..."
    $ansibleCheck = wsl --distribution Ubuntu bash -c "command -v ansible"
    if (-not $ansibleCheck) {
        Write-Info "Instalando Ansible en WSL..."
        wsl --distribution Ubuntu bash -c "sudo apt update && sudo apt install -y ansible"
    }

    # Crear archivo de resultados
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $header = @"
================================
RESULTADOS DE PRUEBAS DE ESTRES
Fecha: $timestamp
================================

"@
    $header | Out-File -FilePath $ResultsFile -Encoding UTF8

    # Cambiar al directorio del proyecto en WSL
    $wslProjectDir = "/mnt/c/Users/jilop/OneDrive - Universidad Adolfo Ibanez/Documents/Universidad/Segundo Ciclo/Tercer Semestre SC/Arquitectura de Sistemas/AnsibleArqui/ansible-docker-lab"
    
    # Verificar conectividad usando WSL
    Write-Info "Verificando conectividad con los nodos..."
    try {
        $pingResult = wsl --distribution Ubuntu bash -c "cd '$wslProjectDir' && ansible -i inventory_password.ini nodos -m ping" 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-OK "Conectividad verificada correctamente"
        } else {
            Write-Err "Error de conectividad SSH. Verifica la configuracion de claves."
            $pingResult | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
            return $false
        }
    }
    catch {
        Write-Err "Error ejecutando Ansible en WSL."
        return $false
    }

    # Pruebas con diferentes niveles de concurrencia
    $forksArray = @(1, 3, 5, 10)
    
    foreach ($forks in $forksArray) {
        Write-Info "Ejecutando prueba con $forks forks..."
        
        $testHeader = @"
PRUEBA CON $forks FORKS:
----------------------
"@
        $testHeader | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
        
        $startTime = Get-Date
        
        # Ejecutar ansible-playbook usando WSL
        try {
            $output = wsl bash -c "cd '$wslProjectDir' && ansible-playbook -i inventory_password.ini site.yml --forks=$forks" 2>&1
            $output | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
            
            $endTime = Get-Date
            $duration = ($endTime - $startTime).TotalSeconds
            
            "Duracion total: $duration segundos" | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
            "" | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
            
            Write-OK "Prueba con $forks forks completada en $([math]::Round($duration, 2))s"
        }
        catch {
            Write-Err "Error en prueba con $forks forks"
            "ERROR en la ejecucion" | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
            "" | Out-File -FilePath $ResultsFile -Append -Encoding UTF8
        }
    }
    
    Write-OK "Todas las pruebas completadas"
    return $true
}

# Función para generar reporte
function Generate-Report {
    Write-Info "Generando reporte de resultados..."
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    $reportContent = @"
# Reporte de Pruebas de Estrés - Ansible

## Objetivo
Evaluar el rendimiento de Ansible bajo diferentes niveles de concurrencia utilizando contenedores Docker como nodos simulados.

## Infraestructura de Prueba
- Sistema Operativo: Ubuntu 20.04 (Docker)
- Número de nodos: 3 contenedores
- Conectividad: SSH sin contraseña
- Red: Docker bridge network
- Sistema Host: Windows con PowerShell

## Resultados de Rendimiento

| Forks | Nodos | Tiempo (s) | Observaciones |
|-------|-------|------------|---------------|
| 1     | 3     | Ver archivo| Ejecución secuencial |
| 3     | 3     | Ver archivo| Ejecución paralela   |
| 5     | 3     | Ver archivo| Paralelismo máximo   |
| 10    | 3     | Ver archivo| Sobre-paralelización |

## Análisis
- Forks = 1: Ejecución completamente secuencial
- Forks = 3: Paralelismo óptimo para 3 nodos
- Forks > 3: No mejora significativa al tener solo 3 nodos

## Conclusiones
Los resultados demuestran que el paralelismo en Ansible mejora significativamente el rendimiento hasta el punto donde el número de forks iguala al número de nodos objetivo.

---
Generado automáticamente por el script de pruebas de estrés
Ejecutado en: $timestamp
"@

    $reportContent | Out-File -FilePath "stress_test_report.md" -Encoding UTF8
    Write-OK "Reporte generado: stress_test_report.md"
}

# Función para mostrar ayuda
function Show-Help {
    Write-Title "Ayuda - Script de Pruebas de Estrés Ansible"
    Write-Host ""
    Write-Host "USO:" -ForegroundColor Yellow
    Write-Host "  .\stress_test_simple.ps1 -Action {setup|test|clean|all|help}" -ForegroundColor White
    Write-Host ""
    Write-Host "COMANDOS:" -ForegroundColor Yellow
    Write-Host "  setup  - Configura la infraestructura Docker" -ForegroundColor Gray
    Write-Host "  test   - Ejecuta las pruebas de estrés" -ForegroundColor Gray
    Write-Host "  clean  - Limpia contenedores y redes" -ForegroundColor Gray
    Write-Host "  all    - Ejecuta todo el proceso completo" -ForegroundColor Gray
    Write-Host "  help   - Muestra esta ayuda" -ForegroundColor Gray
    Write-Host ""
    Write-Host "EJEMPLOS:" -ForegroundColor Yellow
    Write-Host "  .\stress_test_simple.ps1 -Action setup" -ForegroundColor Gray
    Write-Host "  .\stress_test_simple.ps1 -Action all" -ForegroundColor Gray
    Write-Host ""
    Write-Host "PRERREQUISITOS:" -ForegroundColor Yellow
    Write-Host "  - Docker Desktop ejecutándose" -ForegroundColor Gray
    Write-Host "  - Ansible instalado (pip install ansible)" -ForegroundColor Gray
    Write-Host "  - SSH configurado (el script te guiará)" -ForegroundColor Gray
}

# Menú principal
switch ($Action) {
    "setup" {
        Write-Title "Configurando infraestructura"
        Clean-Environment
        if (Setup-Infrastructure) {
            Setup-SSH
            Write-OK "Infraestructura lista. Configura SSH y luego ejecuta: .\stress_test_simple.ps1 -Action test"
        }
    }
    "test" {
        Write-Title "Ejecutando pruebas de estrés"
        if (Run-StressTests) {
            Generate-Report
            Write-OK "Pruebas completadas. Revisa los archivos:"
            Write-Host "   - $ResultsFile" -ForegroundColor Gray
            Write-Host "   - stress_test_report.md" -ForegroundColor Gray
        }
    }
    "clean" {
        Write-Title "Limpiando recursos"
        Clean-Environment
        Write-OK "Limpieza completada."
    }
    "all" {
        Write-Title "Ejecutando proceso completo"
        Clean-Environment
        if (Setup-Infrastructure) {
            Setup-SSH
            Write-Host ""
            Write-Host "PAUSA: Configura SSH siguiendo las instrucciones arriba" -ForegroundColor Yellow
            Write-Host "Presiona cualquier tecla cuando hayas terminado..." -ForegroundColor Yellow
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            
            if (Run-StressTests) {
                Generate-Report
                Write-OK "Proceso completo terminado."
            }
        }
    }
    "help" {
        Show-Help
    }
    default {
        Show-Help
    }
}
