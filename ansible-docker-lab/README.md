# 🧪 Laboratorio de Pruebas de Estrés - Ansible con Docker

Entorno completo de testing de Ansible usando contenedores Docker como nodos simulados. Este laboratorio permite evaluar el rendimiento de Ansible bajo diferentes configuraciones de paralelismo y cargas de trabajo.

## 📋 Prerrequisitos

### Software Requerido
- **Docker Desktop** instalado y ejecutándose
- **WSL2 con Ubuntu** (requerido para Ansible y SSH)
- **PowerShell** (para scripts de automatización)

### Configuración Inicial (Una sola vez)

#### 1. Instalar WSL2 con Ubuntu
```powershell
# En PowerShell como Administrador
wsl --install Ubuntu
# Reiniciar el sistema cuando se solicite
```

#### 2. Configurar Ubuntu/WSL
```bash
# Entrar a WSL
wsl

# Actualizar el sistema
sudo apt update && sudo apt upgrade -y

# Instalar Ansible y dependencias
sudo apt install -y ansible sshpass openssh-client

# Verificar instalación
ansible --version
```

## 🚀 Ejecución del Laboratorio

### Opción 1: Automatizada (Recomendada)
```powershell
# Navegar al directorio del laboratorio
cd "c:\Users\jilop\OneDrive - Universidad Adolfo Ibanez\Documents\Universidad\Segundo Ciclo\Tercer Semestre SC\Arquitectura de Sistemas\AnsibleArqui\ansible-docker-lab" () mi caso

# Ejecutar pruebas completas automáticamente
.\stress_test_simple.ps1
```

### Opción 2: Por pasos
```powershell
# 1. Configurar entorno Docker
.\stress_test_simple.ps1 -Action setup

# 2. Ejecutar pruebas de rendimiento
.\stress_test_simple.ps1 -Action test

# 3. Limpiar recursos (opcional)
.\stress_test_simple.ps1 -Action clean
```

## 🔧 Qué hace el laboratorio

### Proceso Automatizado
1. **Construcción de imagen Docker**: Ubuntu con SSH habilitado
2. **Creación de contenedores**: 3 nodos simulados (node1, node2, node3)
3. **Configuración SSH**: Generación y distribución automática de claves
4. **Pruebas de rendimiento**: Ejecución con diferentes niveles de paralelismo
5. **Generación de reportes**: Análisis automático de resultados

### Configuraciones de Prueba
- **Serial** (--forks=1): Ejecución secuencial, tarea por tarea
- **Paralelo limitado** (--forks=3): Paralelismo óptimo para 3 nodos
- **Paralelo alto** (--forks=10): Sobrecarga de paralelismo

## 🔐 Configuración SSH Automática

El laboratorio utiliza WSL/Ubuntu para manejar SSH de forma nativa:

```bash
# El script automáticamente:
# 1. Genera claves SSH en WSL
# 2. Distribuye claves usando sshpass
# 3. Configura inventory con conexiones por clave
# 4. Verifica conectividad con ansible ping
```

### Manual (si es necesario)
```bash
# Entrar a WSL
wsl

# Verificar claves SSH
ls ~/.ssh/

# Probar conectividad manual
ssh -i ~/.ssh/ansible_id_rsa -p 2222 root@localhost
```

## 📊 Resultados y Análisis

### Archivos Generados
- **`stress_test_results.txt`**: Resultados detallados con tiempos de ejecución
- **`INFORME_MODERNIZACION_ANSIBLE.md`**: Reporte académico completo
- **Archivos adicionales**: Pruebas de escalabilidad, seguridad y validación

### Métricas Evaluadas
- **Tiempo total de ejecución** por configuración de forks
- **Tiempo por tarea individual**
- **Eficiencia del paralelismo**
- **Overhead de configuración**

### Resultados Típicos Esperados
```
Configuración Serial (--forks=1):
├── Tiempo total: ~60-90 segundos
├── Ejecución secuencial tarea por tarea
└── Uso mínimo de recursos

Configuración Paralela (--forks=3):
├── Tiempo total: ~20-30 segundos
├── Paralelismo óptimo para 3 nodos
└── Mejora significativa del rendimiento

Configuración Alta Concurrencia (--forks=10):
├── Tiempo total: Similar a forks=3
├── Sin mejora adicional (limitado por nodos)
└── Overhead de gestión de hilos
```

## ⚙️ Personalización

### Modificar Número de Nodos
Edita `stress_test_simple.ps1`:
```powershell
# Añadir más contenedores
docker run -d --rm --name node4 --network ansible-net -p 2225:22 ubuntu-ssh
docker run -d --rm --name node5 --network ansible-net -p 2226:22 ubuntu-ssh
```

### Modificar Tareas de Prueba
Edita `site.yml` para incluir cargas más intensivas:
```yaml
- name: Tarea CPU intensiva
  command: stress --cpu 2 --timeout 10s
  
- name: Tarea I/O intensiva
  command: dd if=/dev/zero of=/tmp/test bs=1M count=100
```

### Configurar Diferentes Niveles de Paralelismo
El script incluye por defecto: 1, 3, 10 forks. Puedes modificar estos valores según tus necesidades.

## 🧹 Limpieza

Para limpiar todos los recursos después de las pruebas:
```powershell
# Automática
.\stress_test_simple.ps1 -Action clean

# Manual (si es necesario)
docker stop node1 node2 node3 2>$null
docker rm node1 node2 node3 2>$null
docker network rm ansible-net 2>$null
docker rmi ubuntu-ssh 2>$null
```

## � Estructura del Proyecto

```
ansible-docker-lab/
├── Dockerfile                           # Imagen Ubuntu con SSH
├── stress_test_simple.ps1              # Script principal (usar este)
├── site.yml                            # Playbook principal de pruebas
├── inventory.ini                       # Inventario con claves SSH
├── inventory_password.ini               # Inventario con contraseñas (backup)
├── INFORME_MODERNIZACION_ANSIBLE.md    # Reporte académico completo
├── stress_test_results.txt             # Resultados de las pruebas
└── README.md                           # Esta documentación
```

### Archivos Adicionales (Opcionales)
- `additional_tests.ps1`: Pruebas adicionales avanzadas
- `site_scalability.yml`, `site_with_errors.yml`: Playbooks específicos
- Varios archivos de resultados de pruebas previas

## 📋 Para tu Informe Académico

El archivo **`INFORME_MODERNIZACION_ANSIBLE.md`** contiene:

✅ **Introducción y objetivos**  
✅ **Marco teórico sobre automatización**  
✅ **Metodología de testing**  
✅ **Arquitectura del laboratorio**  
✅ **Análisis de resultados**  
✅ **Diagramas PlantUML**  
✅ **Patrones de código**  
✅ **Conclusiones y recomendaciones**  
✅ **Impacto en el negocio**

Este reporte está listo para incluir en tu trabajo académico.

## 🆘 Troubleshooting

### Error: "ansible: command not found"
```bash
# En WSL/Ubuntu
sudo apt update && sudo apt install ansible
ansible --version
```

### Error: "docker: command not found" en PowerShell
- Verificar que Docker Desktop esté ejecutándose
- Reiniciar PowerShell después de instalar Docker
- Verificar PATH de Docker: `docker --version`

### Error: "WSL command not found"
```powershell
# Instalar WSL2
wsl --install Ubuntu
# Reiniciar el sistema
```

### Error: SSH connection refused
```powershell
# Verificar contenedores activos
docker ps

# Verificar servicios SSH en contenedores
docker exec node1 service ssh status
```

### Error: Permission denied (publickey)
```bash
# En WSL, verificar claves SSH
ls -la ~/.ssh/
cat ~/.ssh/ansible_id_rsa.pub

# Regenerar claves si es necesario
ssh-keygen -t rsa -b 2048 -f ~/.ssh/ansible_id_rsa -N ""
```

### Error: "No module named 'ansible'"
```bash
# En WSL/Ubuntu
sudo apt update
sudo apt install python3-pip
pip3 install ansible
```

### Contenedores no responden
```powershell
# Reiniciar todo el entorno
.\stress_test_simple.ps1 -Action clean
.\stress_test_simple.ps1 -Action setup
```

## 🎯 Casos de Uso Académicos

### Para Proyectos de Arquitectura de Sistemas
- Análisis de rendimiento de herramientas de automatización
- Comparación de estrategias de paralelización
- Evaluación de overhead en sistemas distribuidos

### Para Investigación en DevOps
- Métricas de eficiencia en pipelines CI/CD
- Optimización de configuraciones de despliegue
- Análisis de escalabilidad horizontal

### Para Estudios de Infraestructura
- Simulación de entornos multi-nodo
- Testing de configuraciones de red
- Validación de políticas de seguridad

## 📚 Referencias y Recursos

### Documentación Oficial
- [Ansible Documentation](https://docs.ansible.com/)
- [Docker Desktop for Windows](https://docs.docker.com/desktop/windows/)
- [WSL2 Installation Guide](https://docs.microsoft.com/en-us/windows/wsl/install)

### Recursos Académicos
- [Ansible Performance Tuning](https://docs.ansible.com/ansible/latest/user_guide/playbooks_strategies.html)
- [Container Orchestration Patterns](https://kubernetes.io/docs/concepts/)
- [Infrastructure as Code Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices/)

### Herramientas Relacionadas
- [PlantUML](https://plantuml.com/) - Para diagramas de arquitectura
- [Grafana](https://grafana.com/) - Para monitoreo avanzado
- [Prometheus](https://prometheus.io/) - Para métricas de sistema

---

## 📞 Soporte

Si encuentras problemas o tienes preguntas:

1. **Verifica los prerequisitos**: WSL2, Docker Desktop, Ubuntu en WSL
2. **Revisa la sección Troubleshooting** de este README
3. **Consulta los logs**: Los scripts muestran información detallada de errores
4. **Ejecuta paso a paso**: Usa las opciones `-Action setup` y `-Action test` por separado

---

**¡Éxito en tu laboratorio de Ansible! 🚀**  
*Última actualización: Diciembre 2024*
