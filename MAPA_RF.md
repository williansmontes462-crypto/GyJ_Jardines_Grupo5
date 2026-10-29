# Mapa de cobertura inicial de requisitos funcionales

Esta tabla indica dónde se atiende cada grupo de RF en esta primera versión. Algunas funciones de control todavía necesitan reglas de negocio más específicas y validación con la empresa antes de considerarse terminadas para producción.

| Requisitos | Área de la aplicación | Cobertura inicial |
|---|---|---|
| RF001–RF004 | Usuarios y roles | Crear y modificar usuarios, cambiar rol y activar/desactivar con estado. |
| RF005 | Acceso | Inicio de sesión de demostración. |
| RF006–RF010 | Obras | Crear/modificar obra, estado, ingeniero a cargo y máquinas asignadas visibles. |
| RF011–RF020 | Máquinas | Datos de máquina, tipo, marca, modelo, código, obra, estado y consulta del historial contextual. |
| RF021–RF025 | Horas de uso | Registrar horas por fecha, consultar acumulado e historial por máquina. La alerta automática por umbral requiere definir umbrales por tipo/modelo. |
| RF026–RF035 | Mantenimiento | Programar mantenimiento, registrar tipo, fecha, responsable y observaciones; marcar realizado y consultar registros. |
| RF036–RF042 | Paradas | Registrar inicio y motivo, registrar fin, calcular duración y consultar paradas activas e historial. |
| RF043–RF050 | Repuestos | Registrar uso, cantidad, máquina, solicitar repuestos, consultar solicitudes y registrar compra cambiando estado a comprado. |

## Limitaciones conocidas

- El acceso usa usuario de demostración (`admin` / `1234`); no es autenticación segura de producción.
- La persistencia es local. Dos celulares no comparten datos todavía.
- Los umbrales de mantenimiento y los flujos de aprobación/compra deben definirse con la empresa.
- La aplicación es una primera versión funcional para validar pantallas y operaciones; la integración remota y las pruebas de campo quedan pendientes.
