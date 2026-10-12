# Alta disponibilidad y recuperación

## Segundo controlador de dominio

Para eliminar el punto único de fallo que supone tener un solo controlador de dominio, promoví un segundo servidor (**DC-SECUNDARI**) dentro del mismo dominio. Esto proporciona redundancia: si uno de los dos servidores cae, el otro sigue ofreciendo autenticación, DNS y el resto de servicios de directorio sin interrupción.

![Segundo controlador de dominio visible](../capturas/Segundo%20DC%20visible1.png)
![Segundo controlador de dominio visible](../capturas/Segundo%20DC%20visible2.png)

Comprobé que la replicación entre ambos controladores funciona correctamente, condición indispensable para que el segundo DC sea realmente útil como respaldo.

![Replicación entre controladores](../capturas/Replicaci%C3%B3n%20OK.png)

## Gestión y distribución de roles FSMO

Active Directory delega ciertas operaciones críticas (esquema, nomenclatura de dominio, RID, infraestructura y emulación de PDC) a roles únicos llamados **FSMO**, que por defecto recaen todos en el primer controlador. Transferí el rol de **PDC Emulator** a DC-SECUNDARI, distribuyendo así la carga y preparando el dominio para una recuperación más rápida en caso de fallo del servidor principal.

![Roles FSMO distribuidos](../capturas/Roles%20FSMO.png)

## Papelera de reciclaje de Active Directory

Activé la **Papelera de reciclaje de AD**, una característica que permite restaurar objetos eliminados (usuarios, grupos, equipos) de forma íntegra, sin necesidad de recurrir a una restauración completa del System State.

![Papelera de reciclaje activada](../capturas/Papelera%20de%20reciclaje%20activada.png)

Validé su funcionamiento eliminando un usuario de prueba y restaurándolo, comprobando que recupera el mismo objeto (mismo GUID) en lugar de crear uno nuevo.

![Objeto eliminado y restaurado](../capturas/Objeto%20eliminado%20y%20restaurado1.png)
![Objeto eliminado y restaurado](../capturas/Objeto%20eliminado%20y%20restaurado2.png)

## Auditoría

Configuré una política de auditoría para registrar eventos críticos de seguridad (creación y modificación de cuentas), generando un rastro verificable en el Visor de sucesos ante cualquier cambio sobre los objetos del dominio.

![Evento de auditoría registrado](../capturas/Auditor%C3%ADa%20+%20evento%20registrado.png)

## Copia de seguridad del System State

Realicé una copia de seguridad del **System State** del controlador de dominio, que incluye la base de datos de Active Directory (NTDS), el registro y los archivos de arranque del sistema — la base de cualquier plan de recuperación ante desastres de un controlador de dominio.

![Backup del System State](../capturas/Backup%20System%20State.png)

## Procedimiento de recuperación de emergencia (Seize de roles FSMO)

En caso de fallo permanente e irrecuperable del servidor principal, los roles FSMO que tuviera asignados pueden **apropiarse** (*seize*) desde el servidor superviviente, a diferencia de una transferencia normal, que requiere que ambos servidores estén operativos. Este procedimiento es la última opción: implica aceptar la pérdida de cualquier cambio no replicado antes de la caída, y exige retirar por completo el servidor fallido de la red una vez recuperado, reinstalándolo desde cero si fuera a reincorporarse, ya que dos titulares del mismo rol FSMO corrompen el directorio.
