# Despliegue y administración de un dominio Active Directory (TechCorp)

## Escenario

Este proyecto simula la infraestructura de TI de TechCorp, una empresa ficticia que necesitaba centralizar la gestión de identidades, reforzar la seguridad de sus estaciones de trabajo y garantizar la continuidad del servicio ante un fallo del servidor principal. A partir de ese planteamiento, diseñé y desplegué desde cero una infraestructura Active Directory completa: estructura organizativa delegada por departamento, automatización de la gestión de usuarios, políticas de seguridad granulares y un segundo controlador de dominio para alta disponibilidad.

## Arquitectura

![Topología de red](diagramas/topologia.png)

| Equipo | Rol | IP |
|---|---|---|
| DC-TECHCORP | Controlador de dominio principal, AD DS, DNS | 192.168.110.10 |
| DC-SECUNDARI | Controlador de dominio secundario (redundancia, roles FSMO distribuidos) | 192.168.110.11 |
| CL-STATION01 | Estación cliente Windows 11, miembro del dominio | 192.168.110.20 (IP estática) |

Red interna: 192.168.110.0/24

## Tecnologías

- Windows Server 2022 (x2, DC-TECHCORP y DC-SECUNDARI)
- Windows 11 (CL-STATION01)
- VirtualBox
- Active Directory Domain Services (AD DS)
- DNS integrado de Active Directory
- Directivas de grupo (GPO): restricciones, preferencias, PSO
- PowerShell (automatización y administración)

## Índice

- [Diseño y despliegue del dominio](#diseño-y-despliegue-del-dominio)
- [Políticas de grupo y seguridad](#políticas-de-grupo-y-seguridad)
- [Alta disponibilidad y recuperación](#alta-disponibilidad-y-recuperación)
- [Recursos](#recursos)

## Diseño y despliegue del dominio

### Preparación del servidor

Antes de instalar el rol de Active Directory, configuré una IP estática en el servidor y le asigné su nombre definitivo (DC-TECHCORP), paso necesario porque un controlador de dominio no puede cambiar de nombre ni de IP una vez promovido sin generar problemas graves de replicación y resolución DNS.

![IP fija y nombre del servidor](capturas/IP%20fija%20+%20nombre%20del%20DC.png)

Instalé el rol AD DS (Active Directory Domain Services) y promoví el servidor a controlador de dominio, creando el bosque techcorp.local desde cero.

![Rol AD DS instalado](capturas/Rol%20AD%20DS%20instalado.png)
![Dominio promovido](capturas/Dominio%20promovido.png)

### Estructura de unidades organizativas (OUs) y delegación

Diseñé una estructura de OUs que refleja la organización departamental de la empresa, separando los departamentos (Sistemes, Desenvolupament, Suport_Tecnic) de los recursos compartidos (grupos de seguridad, carpetas).

![Estructura de OUs](capturas/Estructura%20de%20OUs1.png)
![Estructura de OUs](capturas/Estructura%20de%20OUs2.png)
![Estructura de OUs](capturas/Estructura%20de%20OUs3.png)
![Estructura de OUs](capturas/Estructura%20de%20OUs4.png)

Para cada OU departamental, delegué permisos administrativos limitados al grupo de soporte técnico correspondiente, usando dsacls. Esto permite una administración descentralizada sin dar privilegios de administrador de dominio completo.

![Delegación de permisos](capturas/Delegaci%C3%B3n%20dsacls1.png)
![Delegación de permisos](capturas/Delegaci%C3%B3n%20dsacls2.png)
![Delegación de permisos](capturas/Delegaci%C3%B3n%20dsacls3.png)
![Delegación de permisos](capturas/Delegaci%C3%B3n%20dsacls4.png)
![Delegación de permisos](capturas/Delegaci%C3%B3n%20dsacls5.png)
![Delegación de permisos](capturas/Delegaci%C3%B3n%20dsacls6.png)

El listado completo de la estructura de OUs generado por script está disponible en [ou-structure.csv](docs/ou-structure.csv).

### Grupos de seguridad y modelo AGDLP

Apliqué el modelo AGDLP (Account, Global Group, Domain Local Group, Permission), el estándar de Microsoft para gestionar permisos a gran escala: los usuarios se agrupan primero en grupos globales según su función, estos grupos globales se anidan dentro de grupos de dominio local, y es a estos últimos a quienes se asignan finalmente los permisos sobre los recursos.

![Grupos de seguridad](capturas/Grupos%20de%20seguridad1.png)
![Grupos de seguridad](capturas/Grupos%20de%20seguridad2.png)
![Anidación de grupos (AGDLP)](capturas/Anidaci%C3%B3n%20AGDLP.png)

### Gestión de usuarios

Creé un usuario individual de administración (u_admin_helpdesk) por línea de comandos, y automaticé la alta masiva del resto de la plantilla mediante un script PowerShell que lee los datos desde un CSV.

![Usuarios creados](capturas/Usuarios%20creados.png)

El script valida si un usuario ya existe antes de crearlo, evitando errores al reejecutarse sobre un dominio ya poblado:

![Control de duplicados en el script](capturas/Reejecuci%C3%B3n%20script%20duplicados.png)

El script y la plantilla CSV están disponibles en [plantillas/](plantillas/), listos para reutilizar en otros despliegues.

### Consultas LDAP

Para validar la calidad de los datos cargados, usé un filtro LDAP combinado que localiza cuentas de usuario activas sin el atributo title relleno, útil para detectar fichas incompletas tras una alta masiva.

![Consulta LDAP filtrada](capturas/Consulta%20LDAP%20filtrada.png)

## Políticas de grupo y seguridad

### Restricciones de estación de trabajo

Creé una GPO (GPO_Restriccions_Estacions) que restringe el acceso al Panel de Control y bloquea la escritura y lectura en dispositivos de almacenamiento extraíble (USB), aplicada a la OU de departamentos. El equipo de sistemas (GG_Sistemes) queda excluido de esta restricción mediante un permiso explícito de Denegar "Aplicar directiva de grupo", ya que necesita acceso administrativo completo a las estaciones.

![Configuración de las restricciones](capturas/GPO%20Panel%20de%20Control%20+%20filtrado.png)
![Exclusión de GG_Sistemes](capturas/GPO%20de%20unidad%20de%20red%20%28ILT%29.png)

Comprobación en el cliente, con un usuario afectado por la restricción:

![Panel de Control bloqueado](capturas/Panel%20de%20Control%20bloqueado.png)
![Bloqueo de acceso a USB](capturas/Efecto%20real%20del%20bloqueo%20USB.png)

### Política de contraseñas granular (PSO)

Las políticas de contraseña de un dominio son únicas por defecto (una sola Default Domain Policy para todos). Para exigir una seguridad reforzada solo al personal técnico, creé una Password Settings Object (PSO) aplicada específicamente a GG_Sistemes: contraseñas de 12 caracteres mínimo, historial de 10, caducidad a los 30 días y bloqueo de cuenta tras 3 intentos fallidos.

![PSO creada y asignada](capturas/PSO%20creada.png)

### Mapeo de unidades de red con Item-Level Targeting

Usando Group Policy Preferences (no Directivas, que no permiten este nivel de filtrado), configuré dos unidades de red: una compartida para toda la organización (S:) y otra exclusiva para el equipo de sistemas (T:), filtrada mediante Item-Level Targeting, un filtro evaluado en el propio cliente, a nivel de elemento individual dentro de la GPO, a diferencia del filtrado de seguridad, que afecta a la GPO completa.

Comprobación en el cliente, comparando el mismo Explorador de archivos con dos usuarios distintos:

![Usuario con acceso (GG_Sistemes)](capturas/Unidad%20de%20red%20mapeada.png)
![Usuario sin acceso (filtrado por ILT)](capturas/Unidad%20de%20red%20mapeada2.png)

### Bloqueo automático de pantalla

Configuré el protector de pantalla para activarse tras 10 minutos de inactividad y exigir contraseña al desbloquear la sesión. Son tres directivas de Windows separadas pero dependientes entre sí (activación, tiempo de espera y protección por contraseña).

### Diagnóstico de políticas aplicadas (RSOP)

Para verificar que el conjunto de políticas se aplica correctamente en el cliente, generé un informe RSOP (Resultant Set of Policy), que muestra todas las GPOs efectivas sobre el usuario y el equipo.

![Informe RSOP](capturas/Informe%20RSOP1.png)
![Informe RSOP](capturas/Informe%20RSOP2.png)
![Informe RSOP](capturas/Informe%20RSOP3.png)

## Alta disponibilidad y recuperación

### Segundo controlador de dominio

Para eliminar el punto único de fallo que supone tener un solo controlador de dominio, promoví un segundo servidor (DC-SECUNDARI) dentro del mismo dominio. Esto proporciona redundancia: si uno de los dos servidores cae, el otro sigue ofreciendo autenticación, DNS y el resto de servicios de directorio sin interrupción.

![Segundo controlador de dominio visible](capturas/Segundo%20DC%20visible1.png)
![Segundo controlador de dominio visible](capturas/Segundo%20DC%20visible2.png)

Comprobé que la replicación entre ambos controladores funciona correctamente, condición indispensable para que el segundo DC sea realmente útil como respaldo.

![Replicación entre controladores](capturas/Replicaci%C3%B3n%20OK.png)

### Gestión y distribución de roles FSMO

Active Directory delega ciertas operaciones críticas (esquema, nomenclatura de dominio, RID, infraestructura y emulación de PDC) a roles únicos llamados FSMO, que por defecto recaen todos en el primer controlador. Transferí el rol de PDC Emulator a DC-SECUNDARI, distribuyendo así la carga y preparando el dominio para una recuperación más rápida en caso de fallo del servidor principal.

![Roles FSMO distribuidos](capturas/Roles%20FSMO.png)

### Papelera de reciclaje de Active Directory

Activé la Papelera de reciclaje de AD, una característica que permite restaurar objetos eliminados (usuarios, grupos, equipos) de forma íntegra, sin necesidad de recurrir a una restauración completa del System State.

![Papelera de reciclaje activada](capturas/Papelera%20de%20reciclaje%20activada.png)

Validé su funcionamiento eliminando un usuario de prueba y restaurándolo, comprobando que recupera el mismo objeto (mismo GUID) en lugar de crear uno nuevo.

![Objeto eliminado y restaurado](capturas/Objeto%20eliminado%20y%20restaurado1.png)
![Objeto eliminado y restaurado](capturas/Objeto%20eliminado%20y%20restaurado2.png)

### Auditoría

Configuré una política de auditoría para registrar eventos críticos de seguridad (creación y modificación de cuentas), generando un rastro verificable en el Visor de sucesos ante cualquier cambio sobre los objetos del dominio.

![Evento de auditoría registrado](capturas/Auditor%C3%ADa%20+%20evento%20registrado.png)

### Copia de seguridad del System State

Realicé una copia de seguridad del System State del controlador de dominio, que incluye la base de datos de Active Directory (NTDS), el registro y los archivos de arranque del sistema. Es la base de cualquier plan de recuperación ante desastres de un controlador de dominio.

![Backup del System State](capturas/Backup%20System%20State.png)

### Procedimiento de recuperación de emergencia (Seize de roles FSMO)

En caso de fallo permanente e irrecuperable del servidor principal, los roles FSMO que tuviera asignados pueden apropiarse (seize) desde el servidor superviviente, a diferencia de una transferencia normal, que requiere que ambos servidores estén operativos. Este procedimiento es la última opción: implica aceptar la pérdida de cualquier cambio no replicado antes de la caída, y exige retirar por completo el servidor fallido de la red una vez recuperado, reinstalándolo desde cero si fuera a reincorporarse, ya que dos titulares del mismo rol FSMO corrompen el directorio.

## Recursos

- [plantillas/](plantillas/): script de alta masiva de usuarios y plantilla CSV, reutilizables en otros despliegues.
- [gpo-backups/](gpo-backups/): copias de seguridad de las GPOs creadas.
- [docs/](docs/): versión del contenido anterior organizada en archivos independientes por bloque.
