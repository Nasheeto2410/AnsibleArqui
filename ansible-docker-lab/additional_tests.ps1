# Script de Pruebas Adicionales para Análisis Completo
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("validation", "security", "scalability", "all", "help")]
    [string]$TestType
)

$ErrorActionPreference = "Continue"

function Write-TestHeader($title) {
    Write-Host "`n=== $title ===" -ForegroundColor Cyan
    Write-Host "Fecha: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
}

function Test-ValidationAndDryRun {
    Write-TestHeader "Pruebas de Validación y Dry-Run"
    
    $wslProjectDir = "/mnt/c/Users/jilop/OneDrive - Universidad Adolfo Ibanez/Documents/Universidad/Segundo Ciclo/Tercer Semestre SC/Arquitectura de Sistemas/AnsibleArqui/ansible-docker-lab"
    
    Write-Host "[INFO] Ejecutando playbook con errores en modo dry-run (--check)..." -ForegroundColor Yellow
    $checkOutput = wsl --distribution Ubuntu bash -c "cd '$wslProjectDir' && ansible-playbook -i inventory_password.ini site_with_errors.yml --check"
    
    Write-Host "[INFO] Ejecutando playbook con errores en modo real..." -ForegroundColor Yellow
    $realOutput = wsl --distribution Ubuntu bash -c "cd '$wslProjectDir' && ansible-playbook -i inventory_password.ini site_with_errors.yml"
    
    # Guardar resultados
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $reportPath = "validation_test_results_$timestamp.txt"
    
    @"
================================
RESULTADOS DE PRUEBAS DE VALIDACIÓN
Fecha: $(Get-Date)
================================

PRUEBA DRY-RUN (--check):
----------------------
$checkOutput

PRUEBA REAL (con errores):
----------------------
$realOutput

ANÁLISIS:
----------------------
- Verificar si --check detectó los errores antes de ejecución
- Revisar si ignore_errors: yes permitió continuar la ejecución
- Evaluar si los errores fueron manejados apropiadamente

"@ | Out-File -FilePath $reportPath -Encoding UTF8
    
    Write-Host "[OK] Resultados guardados en: $reportPath" -ForegroundColor Green
}

function Test-SecurityCredentials {
    Write-TestHeader "Análisis de Seguridad de Credenciales"
    
    Write-Host "[INFO] Analizando credenciales en inventario..." -ForegroundColor Yellow
    
    # Buscar credenciales en texto plano
    $inventoryContent = Get-Content "inventory_password.ini" -Raw
    $hasPlainCredentials = $inventoryContent -match "ansible_password="
    
    Write-Host "[INFO] Creando ejemplo de cifrado con ansible-vault..." -ForegroundColor Yellow
    $vaultExample = @"
# Ejemplo de credencial cifrada con ansible-vault:
# ansible-vault encrypt_string 'root' --name 'admin_password'

admin_password: !vault |
          `$ANSIBLE_VAULT;1.1;AES256
          66386439653762373064316463370439323562633637363635303031613761656662636637376361
          3836666365626462323364663130646562643431316464330a313230633664653761376637643037
          34636533653030306537363665643838303535613632386534376264646532623665663037356139
          3264653435646630320a663061393761623536653763366661343762623062313834326636353532
          3264
"@
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $securityReport = "security_analysis_$timestamp.txt"
    
    @"
================================
ANÁLISIS DE SEGURIDAD
Fecha: $(Get-Date)
================================

CREDENCIALES EN TEXTO PLANO:
----------------------
Encontradas: $hasPlainCredentials
Ubicación: inventory_password.ini
Contenido: ansible_password=root

RIESGOS IDENTIFICADOS:
----------------------
1. Credenciales expuestas en archivos de configuración
2. Sin cifrado de variables sensibles
3. Sin uso de ansible-vault

EJEMPLO DE MEJORA:
----------------------
$vaultExample

RECOMENDACIONES:
----------------------
1. Usar ansible-vault para cifrar credenciales
2. Implementar SSH con claves públicas/privadas
3. Usar variables de entorno para datos sensibles
4. Separar credenciales del código fuente

"@ | Out-File -FilePath $securityReport -Encoding UTF8
    
    Write-Host "[OK] Análisis de seguridad guardado en: $securityReport" -ForegroundColor Green
}

function Test-Scalability {
    Write-TestHeader "Pruebas de Escalabilidad"
    
    $wslProjectDir = "/mnt/c/Users/jilop/OneDrive - Universidad Adolfo Ibanez/Documents/Universidad/Segundo Ciclo/Tercer Semestre SC/Arquitectura de Sistemas/AnsibleArqui/ansible-docker-lab"
    
    Write-Host "[INFO] Ejecutando pruebas de escalabilidad..." -ForegroundColor Yellow
    $startTime = Get-Date
    $scalabilityOutput = wsl --distribution Ubuntu bash -c "cd '$wslProjectDir' && ansible-playbook -i inventory_password.ini site_scalability.yml"
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Write-Host "[INFO] Analizando estructura de inventario actual..." -ForegroundColor Yellow
    $inventoryLines = (Get-Content "inventory_password.ini").Count
    $nodeCount = (Get-Content "inventory_password.ini" | Where-Object { $_ -match "node\d+" }).Count
    
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $scalabilityReport = "scalability_test_results_$timestamp.txt"
    
    @"
================================
RESULTADOS DE PRUEBAS DE ESCALABILIDAD
Fecha: $(Get-Date)
================================

MÉTRICAS DE ESCALABILIDAD:
----------------------
Nodos actuales: $nodeCount
Líneas en inventario: $inventoryLines
Duración de prueba: $duration segundos

SALIDA DE PRUEBA:
----------------------
$scalabilityOutput

ANÁLISIS DE ESCALABILIDAD:
----------------------
1. Facilidad para añadir nuevos nodos: Manual (cada nodo requiere entrada individual)
2. Reutilización de código: Limitada (playbooks específicos)
3. Gestión de inventario: Estática (archivo plano)

LIMITACIONES IDENTIFICADAS:
----------------------
1. Inventario no dinámico
2. Sin roles reutilizables
3. Configuración manual por nodo
4. Sin auto-descubrimiento de infraestructura

RECOMENDACIONES:
----------------------
1. Implementar inventario dinámico
2. Crear roles modulares y reutilizables
3. Usar group_vars para configuración por grupos
4. Implementar auto-scaling con herramientas cloud

"@ | Out-File -FilePath $scalabilityReport -Encoding UTF8
    
    Write-Host "[OK] Resultados de escalabilidad guardados en: $scalabilityReport" -ForegroundColor Green
}

function Show-Help {
    Write-Host @"

=== Script de Pruebas Adicionales ===

USO:
  .\additional_tests.ps1 -TestType {validation|security|scalability|all|help}

TIPOS DE PRUEBA:
  validation   - Pruebas de validación y dry-run
  security     - Análisis de seguridad de credenciales
  scalability  - Pruebas de escalabilidad
  all          - Ejecuta todas las pruebas
  help         - Muestra esta ayuda

EJEMPLOS:
  .\additional_tests.ps1 -TestType validation
  .\additional_tests.ps1 -TestType all

PRERREQUISITOS:
  - Docker containers ejecutándose
  - WSL/Ubuntu con Ansible configurado
  - Inventario configurado

"@ -ForegroundColor Green
}

# Verificar que Docker esté ejecutándose
try {
    docker ps | Out-Null
} catch {
    Write-Host "[ERROR] Docker no está ejecutándose. Inicia Docker Desktop primero." -ForegroundColor Red
    exit 1
}

# Ejecutar pruebas según el tipo solicitado
switch ($TestType) {
    "validation" { Test-ValidationAndDryRun }
    "security" { Test-SecurityCredentials }
    "scalability" { Test-Scalability }
    "all" { 
        Test-ValidationAndDryRun
        Test-SecurityCredentials
        Test-Scalability
        Write-Host "`n[INFO] Todas las pruebas completadas. Revisar archivos de reporte generados." -ForegroundColor Green
    }
    "help" { Show-Help }
}
