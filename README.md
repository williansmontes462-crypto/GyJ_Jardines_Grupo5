# MANTEN — Guía del proyecto y continuidad segura

> **Lee este archivo completo antes de modificar el proyecto.** Está escrito para una persona o una IA que necesite continuar el desarrollo sin borrar, reemplazar ni romper lo que ya existe.

## 1. Resumen del proyecto

**MANTEN** es una aplicación móvil para llevar el control de maquinaria utilizada en obras de mantenimiento de áreas verdes. Su objetivo es centralizar el registro de obras, máquinas, horas de uso, mantenimientos, paradas de máquinas y repuestos necesarios o utilizados.

- **Plataforma prevista:** aplicación móvil Android, desarrollada con Flutter y Dart.
- **Editor:** Visual Studio Code.
- **Diseño:** interfaz mobile-first, fondo gris muy claro, azul como color principal, tarjetas blancas, bordes redondeados, navegación inferior y componentes Material 3.
- **Persistencia actual:** almacenamiento local mediante `shared_preferences`; no existe servidor ni sincronización entre teléfonos.
- **Estado de esta entrega:** primera base funcional/prototipo con formularios, listas, navegación y operaciones locales. No debe considerarse aún lista para uso real en la empresa.
- **Fecha de esta guía:** 26 de octubre de 2026.

### Problema de negocio que debe conservarse

La empresa necesita mejorar el control de mantenimiento de las máquinas y de sus repuestos. El seguimiento actual se hace parcialmente a mano y de forma descentralizada por los responsables de cada obra. Es importante registrar las horas de uso, el mantenimiento y, especialmente, las fechas y duración de las paradas de cada máquina.

**Flujo de negocio central:**

`Obra → máquina asignada → horas de uso → mantenimiento / parada → repuesto utilizado o requerido → solicitud / compra → historial por máquina`

No conviertas el alcance principal en un sistema genérico de almacén, inventario de productos o facturación: esos no son los problemas aceptados para este proyecto. La compra de repuestos se considera asociada a una máquina y a una necesidad de mantenimiento.

## 2. Diseño de referencia

El diseño se creó tomando como orientación los pantallazos móviles de MANTEN. El archivo de diseño de Figma es:

- [MANTEN — 200 pantallazos por flujo y RF](https://www.figma.com/design/jd6gFY7w84IM4lf3zjf0Il)

### Reglas visuales que no se deben romper

1. **Mantener primero la experiencia móvil.** No convertir los diseños en un dashboard de escritorio ni eliminar la navegación inferior.
2. Conservar el sistema visual azul, el fondo claro, las tarjetas blancas, los bordes redondeados, los espacios amplios y los textos legibles.
3. Mantener español en textos, estados, validaciones y botones.
4. Reutilizar los componentes y estilos que ya existen antes de crear otros equivalentes.
5. No usar una imagen plana del diseño como reemplazo de la interfaz. La pantalla debe seguir siendo código Flutter con controles editables y funcionales.
6. Evitar agregar pantallas o funcionalidades que no estén conectadas con el control de obras, máquinas, horas, mantenimiento, paradas, repuestos o administración.

Colores definidos en `lib/main.dart`:

| Constante | Valor | Uso |
|---|---|---|
| `navy` | `#163B6D` | Azul oscuro para elementos de apoyo |
| `primaryBlue` | `#1976D2` | Color principal, botones y AppBar |
| `paleBackground` | `#F4F7FB` | Fondo general |
| `ink` | `#203247` | Texto principal |
| `mutedInk` | `#617083` | Texto secundario |
| `borderColor` | `#DDE5EF` | Bordes de tarjetas e inputs |

## 3. Lo que ya está implementado

La interfaz, la lógica de los formularios y el almacenamiento local se encuentran principalmente en `lib/main.dart`.

| Área | Funciones presentes en esta versión |
|---|---|
| Inicio de sesión | Formulario de usuario y contraseña; solo acepta usuarios activos de la lista local y usa contraseña fija de demostración. |
| Dashboard | Contadores de obras, máquinas, máquinas detenidas/en mantenimiento, mantenimientos programados y solicitudes de repuestos pendientes; accesos rápidos. |
| Obras | Registrar y modificar obra, código, nombre, ingeniero a cargo y estado; muestra cuántas máquinas están asignadas. |
| Máquinas | Registrar y modificar código, nombre, tipo, marca, modelo, obra y estado; muestra horas acumuladas. |
| Horas de uso | Registrar máquina, fecha, horas trabajadas y observaciones; suma las horas al acumulado de la máquina e incluye historial. Valida que las horas sean mayores que 0 y no superen 24 por registro. |
| Mantenimiento | Programar un mantenimiento con máquina, tipo, fecha, responsable, observaciones y estado; se puede marcar como realizado. Si la máquina estaba `En mantenimiento`, marcar el mantenimiento como realizado la cambia a `Operativa`. |
| Paradas | Registrar inicio de parada con máquina y motivo; la fecha/hora inicial se asigna automáticamente. Registrar fin también usa la hora actual, calcula la duración y puede cambiar la máquina de `Detenida` a `Operativa`. |
| Repuestos | Dos pestañas: solicitudes de repuestos y uso de repuestos. Se puede registrar una solicitud, registrar un repuesto usado y marcar una solicitud como `Comprado`. |
| Usuarios y roles | Crear y modificar usuarios, elegir rol y estado activo/inactivo. Los roles se muestran, pero todavía no controlan los permisos de las pantallas. |
| Guardado local | Los cambios se guardan en el almacenamiento del dispositivo y sobreviven al cierre y reapertura de la app, siempre que no se borren los datos de la aplicación. |

### Datos de demostración

Cuando una tabla local está vacía, la inicialización agrega datos de ejemplo para permitir probar la interfaz. Entre ellos hay obras `OB-001`, `OB-002`, `OB-003` y máquinas `EX-01`, `CT-02`, `PD-03`.

Estos datos son ficticios, solo de demostración; no son información confirmada de la empresa.

## 4. Cómo está organizado el código

```text
MANTEN_Flutter_VSCode/
├── lib/
│   └── main.dart              # App, tema, almacenamiento, pantallas y formularios actuales
├── .vscode/
│   └── launch.json            # Configuración de ejecución en VS Code
├── pubspec.yaml               # Dependencias y versión de Dart requerida
├── analysis_options.yaml      # Reglas de análisis estático
├── preparar_proyecto.bat      # Genera plataformas Android/Web y descarga dependencias
├── MAPA_RF.md                 # Mapa de cobertura inicial de RF001–RF050
└── README.md                  # Esta guía de proyecto y continuidad
```

### Estructura interna principal de `lib/main.dart`

- `MantenApp` y `_MantenAppState`: tema principal, carga inicial, estado de sesión y navegación inicial.
- `MantenStore`: almacenamiento local, carga inicial, altas, modificaciones y consultas a los registros.
- `LoginScreen`: pantalla de inicio de sesión de demostración.
- `HomeShell`: barra superior, navegación inferior y acceso a secciones.
- `DashboardPage`: resumen y accesos rápidos.
- `WorksPage`: gestión de obras.
- `MachinesPage`: gestión de máquinas.
- `HoursPage`: registro e historial de horas.
- `MaintenancePage`: programación y estado de mantenimiento.
- `DowntimePage`: inicio/fin e historial de paradas.
- `PartsPage`: solicitudes y usos de repuestos.
- `AdminPage`: usuarios y roles.
- `RecordDialog`, `FormFieldSpec` y `FieldType`: diálogo reutilizable para formularios.
- `SectionHeading`, `MetricCard`, `QuickAction`, `MenuTile`, `StatusPill` y `EmptyState`: componentes visuales reutilizables.

**Nota de arquitectura:** actualmente varias secciones conviven en un solo archivo. Esto no es ideal para una aplicación grande, pero no se debe dividir todo de golpe. Primero debe preservarse el comportamiento; después se puede modularizar por etapas, compilando y probando cada paso.

## 5. Almacenamiento y modelo de datos

La clase `MantenStore` usa `SharedPreferencesAsync` y JSON. Cada lista se guarda con la clave `manten_<nombreTabla>`.

**No cambies los nombres de las tablas ni las claves persistidas sin una migración compatible.** Los registros guardados en versiones anteriores deben seguir siendo legibles.

| Tabla local | Campos usados actualmente |
|---|---|
| `users` | `id`, `name`, `username`, `role`, `active` |
| `works` | `id`, `code`, `name`, `engineer`, `status` |
| `machines` | `id`, `code`, `name`, `type`, `brand`, `model`, `workId`, `status`, `hours` |
| `hours` | `id`, `machineId`, `date`, `value`, `notes` |
| `maintenance` | `id`, `machineId`, `type`, `date`, `status`, `responsible`, `observations`, y opcionalmente `completedDate` |
| `downtimes` | `id`, `machineId`, `start`, `end`, `reason`; `end` puede ser `null` mientras la parada está activa |
| `partUses` | `id`, `machineId`, `part`, `quantity`, `date`, `notes` |
| `requests` | `id`, `machineId`, `part`, `quantity`, `requester`, `date`, `status`, y opcionalmente `purchaseDate` |

### API interna de `MantenStore`

- `initialize()`: carga las claves locales e inserta datos demo si una tabla está vacía.
- `rows(table)`: devuelve la lista de una tabla.
- `add(table, row)`: agrega un registro y genera un ID si no se proporcionó.
- `update(table, id, changes)`: actualiza un registro sin cambiar su ID.
- `remove(table, id)`: elimina un registro local.
- `machineById(id)` y `workById(id)`: buscan registros por ID.
- `machineName(id)` y `workName(id)`: devuelven nombres legibles para relacionar registros.

El almacenamiento no es una base de datos relacional. Los vínculos se hacen mediante campos como `machineId` y `workId`, por lo que el código debe comprobar que esas referencias aún existan antes de mostrar o modificar registros.

### Precaución con los datos demo

`initialize()` inserta ejemplos cuando cada tabla está vacía y luego vuelve a guardar las tablas. Si en el futuro se agrega una función para borrar todos los datos o se limpia una tabla a propósito, al siguiente inicio podrían aparecer de nuevo los ejemplos. No cambies ese comportamiento sin definir antes una estrategia clara de instalación, datos demo y migraciones.

## 6. Acceso de demostración y seguridad

Credenciales disponibles en esta versión:

- Usuario: `admin` — contraseña de demostración: `1234`.
- Usuario: `operador` — contraseña de demostración: `1234`.

La validación actual compara el nombre de usuario con `users` y permite ingresar si el usuario está activo y la contraseña escrita es `1234`. **No se guardan contraseñas individuales reales ni se aplican permisos por rol.** Crear un usuario desde administración no configura una contraseña particular.

Por lo tanto:

- No utilizar esta autenticación en producción.
- No guardar secretos, contraseñas reales, claves API ni credenciales de servidores dentro del repositorio.
- Antes del uso real, implementar autenticación segura y autorización en una API/backend.
- No afirmar que los roles restringen funciones hasta que existan comprobaciones efectivas.

## 7. Cómo abrir y ejecutar el proyecto

### Requisitos

- Flutter SDK compatible con `pubspec.yaml` (`environment: sdk: >=3.5.0 <4.0.0`).
- Visual Studio Code con extensiones **Flutter** y **Dart**.
- Para Android: Android Studio/Android SDK y un emulador o teléfono con depuración USB.
- Para Web: Chrome instalado.

### Preparación en Windows

1. Descomprime la carpeta y abre `MANTEN_Flutter_VSCode` en VS Code.
2. Ejecuta en la terminal:

   ```powershell
   flutter doctor -v
   ```

3. Genera los archivos de plataforma y recupera las dependencias. Se puede ejecutar `preparar_proyecto.bat` o introducir:

   ```powershell
   flutter create --platforms=android,web .
   flutter pub get
   ```

4. Para ejecutar en Chrome:

   ```powershell
   flutter run -d chrome
   ```

5. Para Android:

   ```powershell
   flutter devices
   flutter run
   ```

### Comprobaciones antes de entregar un cambio

Ejecutar, como mínimo:

```powershell
flutter pub get
flutter analyze
flutter test
```

`flutter test` solo ejecutará pruebas si existen archivos de prueba; por ahora la carpeta `test/` no forma parte de esta entrega. Añadir pruebas automatizadas es una tarea pendiente. Si un comando no se pudo ejecutar, hay que informar que no fue verificado; no afirmar que el proyecto compila si no se comprobó.

## 8. Pendientes y limitaciones conocidas

Estos son los siguientes pasos de desarrollo sugeridos, no funcionalidades que ya existan:

1. **Validar la versión actual:** correr `flutter pub get`, `flutter analyze` y probar las pantallas en emulador/teléfono.
2. **Añadir pruebas automatizadas** para cálculos de horas, duración de paradas, alta/modificación y validaciones.
3. **Separar por módulos con cautela:** por ejemplo `models/`, `data/`, `screens/` y `widgets/`, manteniendo las mismas funciones, las claves de almacenamiento y la apariencia. Hacerlo paso a paso.
4. **Refinar reglas de negocio:** definir con la empresa los umbrales por máquina/tipo para avisos de mantenimiento y las reglas de parada/estado.
5. **Validar formularios:** formatos de fechas, números, códigos duplicados, horas acumuladas y estados incompatibles.
6. **Revisar transiciones de estado:** por ejemplo, una parada finalizada cambia la máquina de `Detenida` a `Operativa` de forma automática; confirmar que eso sea correcto para todos los casos reales.
7. **Conectar una API/base de datos remota** solo cuando se decida la tecnología y se acuerde el esquema, autenticación y política de sincronización. PostgreSQL/Supabase se puede evaluar, pero todavía no está configurado.
8. **Aplicar permisos reales por rol** en la aplicación y, sobre todo, en el backend cuando exista.
9. **Mejorar la gestión histórica:** edición/eliminación controlada de registros, reportes, auditoría y notificaciones, si se confirman como necesidades.
10. **Probar el manejo de datos existentes** antes de cualquier cambio en la persistencia para no perder registros locales.

## 9. Instrucciones obligatorias para la próxima persona o IA

**Para continuar sin arruinar el trabajo existente:**

1. Lee este `README.md`, `MAPA_RF.md` y revisa `lib/main.dart` antes de editar.
2. Identifica qué pantalla, RF o regla se solicita modificar. No reformatees ni reescribas todo el archivo para hacer un cambio pequeño.
3. Antes de editar, resume brevemente qué vas a modificar y qué partes vas a conservar.
4. Conserva el diseño móvil, la navegación inferior, los colores, los textos en español y los componentes reutilizables existentes.
5. Conserva las tablas `users`, `works`, `machines`, `hours`, `maintenance`, `downtimes`, `partUses`, `requests` y sus claves `manten_<tabla>`. Si hace falta cambiar el modelo, añade una migración o lectura compatible; no borres los datos guardados.
6. Usa los métodos de `MantenStore` en lugar de crear un segundo mecanismo de persistencia sin necesidad. Si se sustituye el almacenamiento por un repositorio/API, realiza la transición por etapas y mantén una interfaz clara entre UI y datos.
7. No simules que una operación está conectada a un servidor. Actualmente todo se almacena localmente.
8. No inventes políticas del negocio ni añadas facturación/almacén genérico. Si una regla no está confirmada, deja la cuestión documentada.
9. Después del cambio, corre `flutter analyze` y las pruebas disponibles. Si no puedes correrlos, deja constancia explícita.
10. Al terminar, actualiza este README y `MAPA_RF.md` si cambió la cobertura, las dependencias, el almacenamiento, el flujo o las instrucciones para ejecutar.
11. No elimines archivos, pantallas, datos de ejemplo ni funciones existentes sin una necesidad explícita y una explicación previa.
12. Si una refactorización grande resulta necesaria, divídela en etapas pequeñas y comprobables en lugar de reemplazar todo `main.dart` de una sola vez.

### Prompt de continuidad para una IA

Puedes copiar este texto al iniciar una futura sesión:

> Continúa el proyecto MANTEN. Lee primero `README.md` y `MAPA_RF.md`, y revisa la implementación existente en `lib/main.dart`. No reemplaces ni reescribas todo el proyecto. Conserva la experiencia móvil, el diseño azul, la navegación inferior, las funciones existentes y la persistencia local compatible con las claves `manten_<tabla>`. Haz el cambio solicitado en el área más pequeña posible; no elimines datos, pantallas ni funcionalidades. Si necesitas cambiar el modelo de datos, explica la migración para conservar los registros actuales. No inventes reglas de negocio; documenta las que falten validar con la empresa. Ejecuta `flutter analyze` y pruebas disponibles y reporta exactamente qué se verificó y qué queda pendiente. Actualiza la documentación si cambió el comportamiento.

## 10. Referencia de cobertura de requisitos funcionales

El archivo `MAPA_RF.md` resume la cobertura inicial de los RF001–RF050. Como guía general:

- RF001–RF004: usuarios y roles.
- RF005: acceso.
- RF006–RF010: obras.
- RF011–RF020: máquinas.
- RF021–RF025: horas y necesidad de mantenimiento por umbral.
- RF026–RF035: mantenimiento.
- RF036–RF042: paradas.
- RF043–RF050: repuestos y compras asociadas.

La cobertura actual es **inicial**, no una afirmación de que todos los requisitos estén totalmente implementados o aprobados por la empresa. Compara las acciones reales del código con la lista de requisitos y los casos de prueba antes de cerrar una tarea.
