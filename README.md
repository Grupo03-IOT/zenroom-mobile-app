# Zenroom · SenseWork

Aplicación móvil Flutter basada en los [mockups móviles de SenseWork](https://www.figma.com/design/xYSodRNszkA9kbobfyR6X2/SenseWork-%C2%B7-Applications-UX-UI-Design--TB1-?node-id=1-5&m=dev). El producto se llama **Zenroom** y SenseWork es la empresa.

## Abrir y ejecutar en Android Studio

Android Studio ya está instalado en este equipo junto con Flutter y el SDK de Android.

1. En Android Studio, elige **Open** y selecciona esta carpeta `zenroom`.
2. Instala o habilita los plugins **Flutter** y **Dart** si Android Studio los solicita.
3. Inicia un emulador Android o conecta un teléfono con depuración USB.
4. Elige el dispositivo y pulsa **Run**. La app inicia en **modo demo**, sin servidores.

En este equipo, configura **Gradle JDK** en Android Studio con JDK 17 (`C:\Users\Sandra\.jdks\ms-17.0.19`). El JDK 25 incluido con la instalación actual de Android Studio no funciona con la versión de Gradle de este proyecto.

También puedes ejecutar `flutter run` desde el terminal integrado de Android Studio. IntelliJ IDEA con los plugins Flutter y Dart funciona igualmente. Visual Studio solo se necesita si decides compilar el ejecutable de Windows; para Android no hace falta. El proyecto incluye fuentes iOS, pero compilar iOS requiere macOS y Xcode.

## Conexión con Cloud API

Zenroom sigue las mismas reglas de conexión que la aplicación web:

- La app consulta **Cloud API** en `/api/v1` con `Authorization: Bearer <token>`.
- Convierte las claves JSON `snake_case` de la API a propiedades Dart al leer y viceversa al escribir.
- **Edge API no recibe llamadas desde el teléfono**. El flujo es ESP32 → Edge API → Cloud API → Zenroom.
- Edge API usa su propia configuración `CLOUD_URL` y `CLOUD_TOKEN` para subir lecturas. Esas credenciales no van en la app.

Para conexión real, inicia Cloud API y cambia la configuración de ejecución a:

```bash
flutter run --dart-define=DEMO_MODE=false --dart-define=CLOUD_API_URL=http://10.0.2.2:8080
```

`10.0.2.2` apunta al equipo anfitrión desde el emulador Android. En un teléfono físico, usa la IP local del equipo donde se ejecuta Cloud API y asegúrate de que ambos dispositivos estén en la misma red. En producción usa una URL HTTPS accesible por el dispositivo. Para vista web local, la URL por defecto es `http://127.0.0.1:8080`; Cloud API debe permitir el origen del navegador mediante CORS.

El token de usuario se mantiene **solo en memoria** y se descarta al salir o reiniciar la app. No se guarda un token en texto plano en el dispositivo. La versión real exige un usuario existente; `POST /api/v1/users` crea cuentas con rol **MEMBER**. La asignación del rol **ADMIN** depende del backend.

## Pantallas y acciones

Miembro: acceso, registro, búsqueda y filtros de salas, condiciones actuales, historial de ruido, reporte de incomodidad y perfil.

Desde el selector ES/EN de acceso y registro, **Perfil → Idioma** para miembros o **Más → Idioma** para administradores se puede cambiar entre español e inglés. La app inicia en inglés (`en_US`), sin seguir el idioma del sistema; la elección entre inglés y español (`es_419`) se guarda en el dispositivo y se mantiene al reiniciarla.

Administrador: resumen, alertas, salas, locales, tipos de sala, umbrales, analítica, credenciales Edge, dispositivos, diagnóstico, reportes y miembros.

Las acciones siguientes usan rutas verificadas en [Cloud API](https://github.com/Grupo03-IOT/cloud-api):

| Acción | Ruta |
| --- | --- |
| Iniciar sesión y registrar miembro | `POST /api/v1/auth/login`, `POST /api/v1/users` |
| Salas y lecturas por período | `GET /api/v1/rooms`, `GET /api/v1/rooms/{id}/readings` |
| Locales y tipos de sala | `GET/POST /api/v1/sites`, `GET/POST /api/v1/sites/{id}/room-types` |
| Clasificar sala | `PATCH /api/v1/rooms/{id}` |
| Configurar umbrales | `GET /api/v1/room-types/{id}/thresholds`, `PUT /api/v1/room-types/{id}/thresholds/{metric}` |
| Analítica | `GET /api/v1/insights/rooms/{id}` |
| Crear credencial Edge | `POST /api/v1/credentials` (permisos `readings:write`, `thresholds:read`, `edges:heartbeat`, `alerts:write`) |
| Alertas y reconocimiento | `GET /api/v1/alerts?status=OPEN\|ACKNOWLEDGED\|CLOSED`, `GET /api/v1/alerts/{id}`, `PATCH /api/v1/alerts/{id}/acknowledge` |
| Reportes de incomodidad | `POST /api/v1/discomfort-reports`, `GET /api/v1/discomfort-reports`, `GET /api/v1/discomfort-reports/mine`, `GET /api/v1/discomfort-reports/summary` |

El historial se puede copiar como CSV. Las alertas se listan en las pestañas Activas, Atendidas y Cerradas; atender una alerta exige escribir la acción correctiva (de 3 a 500 caracteres) y el contador «requieren atención» del Resumen es el número de alertas abiertas. El miembro envía reportes de incomodidad (`NOISE`, `WARM`, `COLD`) y ve los suyos en **Perfil → Mis reportes**; el administrador ve en **Más → Reportes** el resumen por sala y cada reporte con la lectura de la sala en ese momento, sin el nombre de quien lo envió. Un mismo motivo en la misma sala solo se acepta una vez cada 10 minutos. En modo demo, alertas y reportes viven en memoria con las mismas reglas.

La API actual tampoco devuelve la relación sala–local ni la relación sala–tipo en `RoomResource`. Por eso el selector de local sirve para administrar tipos y umbrales, pero el directorio de salas no puede filtrarse por local con certeza. El estado de confort de la lista se calcula visualmente a partir de las últimas lecturas; para coincidir exactamente con las alertas del Edge, Cloud API tendría que exponer el estado calculado.

Los textos de Términos de servicio y Política de privacidad son marcadores hasta que SenseWork proporcione textos aprobados.

## Organización DDD

- `lib/features/identity`: sesión, autenticación y credenciales Edge.
- `lib/features/monitoring`: salas, locales, tipos y lecturas.
- `lib/features/alerting`: umbrales de confort.
- `lib/features/insights`: analítica de salas.
- `lib/core`: configuración, transporte HTTP y tema.
- `lib/app`: composición, estado y pantallas Flutter.

Los modelos de `domain` no hacen llamadas HTTP. Los adaptadores de `infrastructure` implementan los contratos del dominio. El modo demo usa un adaptador de monitoreo separado.

## Verificación

```bash
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

Al compilar, Flutter genera el APK de depuración en `build/app/outputs/flutter-apk/app-debug.apk`.

## Run locally

Demo mode (no servers, sample data in memory):

```bash
flutter pub get
flutter run
```

Against the production Cloud API (the base URL has no `/api/v1`; the app adds it):

```bash
flutter run --dart-define=DEMO_MODE=false   --dart-define=CLOUD_API_URL=https://cafecito-app.icywater-8ce04e92.northcentralus.azurecontainerapps.io
```

The Azure service can take about 30 seconds to answer the first request after being idle (`/actuator/health` returns `UP` once it is awake).

## Build the APK

```bash
flutter build apk --release --dart-define=DEMO_MODE=false   --dart-define=CLOUD_API_URL=https://cafecito-app.icywater-8ce04e92.northcentralus.azurecontainerapps.io
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. Release builds are signed with the debug key, which is enough for Firebase App Distribution and sideloading; no keystore is kept in the repository. Minimum Android version: 7.0 (API 24). Application id: `com.sensework.zenroom`.

## Download

The latest build is attached to the newest GitHub release: <https://github.com/Grupo03-IOT/zenroom-mobile-app/releases/latest>. Testers receive each release through Firebase App Distribution as an email invitation. To install the APK by hand, open it on the phone and allow installing apps from unknown sources when Android asks.
