# Diseño y despliegue del dominio

## Preparación del servidor

Antes de instalar el rol de Active Directory, configuré una IP estática en el servidor y le asigné su nombre definitivo (**DC-TECHCORP**), paso necesario porque un controlador de dominio no puede cambiar de nombre ni de IP una vez promovido sin generar problemas graves de replicación y resolución DNS.

![IP fija y nombre del servidor](../capturas/IP%20fija%20+%20nombre%20del%20DC.png)

Instalé el rol **AD DS** (Active Directory Domain Services) y promoví el servidor a controlador de dominio, creando el bosque `techcorp.local` desde cero.

![Rol AD DS instalado](../capturas/Rol%20AD%20DS%20instalado.png)
![Dominio promovido](../capturas/Dominio%20promovido.png)

## Estructura de unidades organizativas (OUs) y delegación

Diseñé una estructura de OUs que refleja la organización departamental de la empresa, separando los departamentos (Sistemes, Desenvolupament, Suport_Tecnic) de los recursos compartidos (grupos de seguridad, carpetas).

![Estructura de OUs](../capturas/Estructura%20de%20OUs1.png)
![Estructura de OUs](../capturas/Estructura%20de%20OUs2.png)
![Estructura de OUs](../capturas/Estructura%20de%20OUs3.png)
![Estructura de OUs](../capturas/Estructura%20de%20OUs4.png)

Para cada OU departamental, delegué permisos administrativos limitados al grupo de soporte técnico correspondiente, usando `dsacls`. Esto permite una administración descentralizada sin dar privilegios de administrador de dominio completo.

![Delegación de permisos](../capturas/Delegaci%C3%B3n%20dsacls1.png)
![Delegación de permisos](../capturas/Delegaci%C3%B3n%20dsacls2.png)
![Delegación de permisos](../capturas/Delegaci%C3%B3n%20dsacls3.png)
![Delegación de permisos](../capturas/Delegaci%C3%B3n%20dsacls4.png)
![Delegación de permisos](../capturas/Delegaci%C3%B3n%20dsacls5.png)
![Delegación de permisos](../capturas/Delegaci%C3%B3n%20dsacls6.png)

El listado completo de la estructura de OUs generado por script está disponible en [`ou-structure.csv`](ou-structure.csv).

## Grupos de seguridad y modelo AGDLP

Apliqué el modelo **AGDLP** (Account → Global Group → Domain Local Group → Permission), el estándar de Microsoft para gestionar permisos a gran escala: los usuarios se agrupan en grupos globales por función, estos se anidan dentro de grupos de dominio local, y es a estos últimos a quienes se asignan los permisos sobre los recursos.

![Grupos de seguridad](../capturas/Grupos%20de%20seguridad1.png)
![Grupos de seguridad](../capturas/Grupos%20de%20seguridad2.png)
![Anidación de grupos (AGDLP)](../capturas/Anidaci%C3%B3n%20AGDLP.png)

## Gestión de usuarios

Creé un usuario individual de administración (`u_admin_helpdesk`) por línea de comandos, y automaticé la alta masiva del resto de la plantilla mediante un script PowerShell que lee los datos desde un CSV.

![Usuarios creados](../capturas/Usuarios%20creados.png)

El script valida si un usuario ya existe antes de crearlo, evitando errores al reejecutarse sobre un dominio ya poblado:

![Control de duplicados en el script](../capturas/Reejecuci%C3%B3n%20script%20duplicados.png)

El script y la plantilla CSV están disponibles en [`plantillas/`](../plantillas/), listos para reutilizar en otros despliegues.

## Consultas LDAP

Para validar la calidad de los datos cargados, usé un filtro LDAP combinado que localiza cuentas de usuario activas sin el atributo `title` relleno — útil para detectar fichas incompletas tras una alta masiva.

![Consulta LDAP filtrada](../capturas/Consulta%20LDAP%20filtrada.png)
