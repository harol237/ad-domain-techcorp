# Políticas de grupo y seguridad

## Restricciones de estación de trabajo

Creé una GPO (`GPO_Restriccions_Estacions`) que restringe el acceso al Panel de Control y bloquea la escritura y lectura en dispositivos de almacenamiento extraíble (USB), aplicada a la OU de departamentos. El equipo de sistemas (`GG_Sistemes`) queda excluido de esta restricción mediante un permiso explícito de **Denegar "Aplicar directiva de grupo"**, ya que necesita acceso administrativo completo a las estaciones.

![Configuración de las restricciones](../capturas/GPO%20Panel%20de%20Control%20+%20filtrado.png)
![Exclusión de GG_Sistemes](../capturas/GPO%20de%20unidad%20de%20red%20%28ILT%29.png)

**Comprobación en el cliente**, con un usuario afectado por la restricción:

![Panel de Control bloqueado](../capturas/Panel%20de%20Control%20bloqueado.png)
![Bloqueo de acceso a USB](../capturas/Efecto%20real%20del%20bloqueo%20USB.png)

## Política de contraseñas granular (PSO)

Las políticas de contraseña de un dominio son únicas por defecto (una sola Default Domain Policy para todos). Para exigir una seguridad reforzada solo al personal técnico, creé una **Password Settings Object (PSO)** aplicada específicamente a `GG_Sistemes`: contraseñas de 12 caracteres mínimo, historial de 10, caducidad a los 30 días y bloqueo de cuenta tras 3 intentos fallidos.

![PSO creada y asignada](../capturas/PSO%20creada.png)

## Mapeo de unidades de red con Item-Level Targeting

Usando **Group Policy Preferences** (no Directivas, que no permiten este nivel de filtrado), configuré dos unidades de red: una compartida para toda la organización (`S:`) y otra exclusiva para el equipo de sistemas (`T:`), filtrada mediante **Item-Level Targeting** — un filtro evaluado en el propio cliente, a nivel de elemento individual dentro de la GPO, a diferencia del filtrado de seguridad que afecta a la GPO completa.

**Comprobación en el cliente**, comparando el mismo Explorador de archivos con dos usuarios distintos:

![Usuario con acceso (GG_Sistemes)](../capturas/Unidad%20de%20red%20mapeada.png)
![Usuario sin acceso (filtrado por ILT)](../capturas/Unidad%20de%20red%20mapeada2.png)

## Bloqueo automático de pantalla

Configuré el protector de pantalla para activarse tras 10 minutos de inactividad, exigiendo contraseña para desbloquear la sesión — tres directivas de Windows separadas pero dependientes entre sí (activación, tiempo de espera y protección por contraseña).

## Diagnóstico de políticas aplicadas (RSOP)

Para verificar que el conjunto de políticas se aplica correctamente en el cliente, generé un informe **RSOP** (Resultant Set of Policy), que muestra todas las GPOs efectivas sobre el usuario y el equipo.

![Informe RSOP](../capturas/Informe%20RSOP1.png)
![Informe RSOP](../capturas/Informe%20RSOP2.png)
![Informe RSOP](../capturas/Informe%20RSOP3.png)
