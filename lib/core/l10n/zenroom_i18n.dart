import 'package:flutter/widgets.dart';
import '../network/cloud_client.dart';

enum AppLanguage { english, spanish }

extension AppLanguageCode on AppLanguage {
  String get code => this == AppLanguage.spanish ? 'es' : 'en';
}

class ZenroomI18n extends InheritedWidget {
  const ZenroomI18n({super.key, required this.language, required super.child});

  final AppLanguage language;

  static AppLanguage languageOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ZenroomI18n>()?.language ??
      AppLanguage.english;

  @override
  bool updateShouldNotify(ZenroomI18n oldWidget) =>
      language != oldWidget.language;
}

String tr(BuildContext context, String source) =>
    translate(ZenroomI18n.languageOf(context), source);

String translate(AppLanguage language, String source) {
  if (language == AppLanguage.english) {
    return _esToEn[source] ?? source;
  }
  final exact = _enToEs[source];
  if (exact != null) return exact;

  final active = RegExp(r'^Active \((\d+)\)$').firstMatch(source);
  if (active != null) return 'Activas (${active.group(1)})';
  final sent = RegExp(r'^(\d+) sent$').firstMatch(source);
  if (sent != null) return '${sent.group(1)} enviados';
  final ofRooms = RegExp(r'^of (\d+)$').firstMatch(source);
  if (ofRooms != null) return 'de ${ofRooms.group(1)}';
  final updated = RegExp(r'^Updated (\d+) min ago$').firstMatch(source);
  if (updated != null) return 'Actualizado hace ${updated.group(1)} min';
  final minutes = RegExp(r'^(\d+) minutes detected$').firstMatch(source);
  if (minutes != null) return '${minutes.group(1)} min detectados';
  final classify = RegExp(r'^Classify (.+)$').firstMatch(source);
  if (classify != null) return 'Clasificar ${classify.group(1)}';
  final floor = RegExp(r'^Floor (\d+)(.*)$').firstMatch(source);
  if (floor != null) {
    final detail = floor
        .group(2)!
        .replaceAll('open area', 'área abierta')
        .replaceAll('meeting room', 'sala de reuniones')
        .replaceAll('call booth', 'cabina de llamadas')
        .replaceAll('focus room', 'sala de concentración')
        .replaceAll('study room', 'sala de estudio');
    return 'Piso ${floor.group(1)}$detail';
  }
  return source;
}

const _esToEn = <String, String>{
  invalidCredentialsMessage: 'Invalid email or password.',
  accountDisabledMessage:
      'This account is deactivated. Contact an administrator.',
  'Ingresa tu correo y contraseña.': 'Enter your email and password.',
  'Completa los campos, usa 8 caracteres y acepta los términos.':
      'Complete the fields, use at least 8 characters and accept the terms.',
  'Cuenta de demostración lista. Inicia sesión para explorar.':
      'Demo account ready. Sign in to explore.',
  'Cuenta creada como miembro. Inicia sesión.':
      'Member account created. Sign in.',
  'Completa los campos y usa al menos 8 caracteres.':
      'Complete the fields and use at least 8 characters.',
};

const _enToEs = <String, String>{
  'Welcome back': 'Bienvenido de nuevo',
  'Your spaces and comfort data are waiting.':
      'Tus espacios y datos de confort te esperan.',
  'Email address': 'Correo electrónico',
  'Demo role': 'Rol de demostración',
  'New to SenseWork?': '¿Eres nuevo en SenseWork?',
  'Sign up': 'Registrarse',
  'By continuing you accept the ': 'Al continuar aceptas los ',
  'SENSEWORK · REAL-TIME COMFORT · CONNECTED SPACES':
      'SENSEWORK · CONFORT EN TIEMPO REAL · ESPACIOS CONECTADOS',
  'Discover the comfort of each room before choosing.':
      'Descubre el confort de cada sala antes de elegirla.',
  'Prepare your administrator account to monitor your spaces.':
      'Prepara tu cuenta de administrador para monitorear tus espacios.',
  'First name': 'Nombre',
  'Last name': 'Apellido',
  'Your first name': 'Tu nombre',
  'Your last name': 'Tu apellido',
  'I manage a coworking space': 'Administro un coworking',
  'Monitor rooms, devices and alerts as an administrator.':
      'Monitorea salas, dispositivos y alertas como administrador.',
  'Administrator access requires backend approval.':
      'El acceso de administrador requiere autorización del backend.',
  'Already have an account?': '¿Ya tienes una cuenta?',
  'Show password': 'Mostrar contraseña',
  'Hide password': 'Ocultar contraseña',
  'Know how every room feels': 'Conoce cómo se siente cada sala',
  'Know how every room feels before your members complain.':
      'Conoce cómo se siente cada sala antes de que los miembros se quejen.',
  'Members and administrators sign in with the same account they use on the web.':
      'Miembros y administradores ingresan con la misma cuenta que usan en la web.',
  'by SenseWork': 'de SenseWork',
  'Email': 'Correo',
  'Password': 'Contraseña',
  'Explore as': 'Explorar como',
  'Member': 'Miembro',
  'Administrator': 'Administrador',
  'Sign in': 'Iniciar sesión',
  'Signing in…': 'Ingresando…',
  'New to Zenroom? ': '¿Nuevo en Zenroom? ',
  'Create an account': 'Crear una cuenta',
  'Forgot your password?': '¿Olvidaste tu contraseña?',
  'By signing in you accept the ': 'Al iniciar sesión aceptas los ',
  ' and the ': ' y la ',
  'Terms of Service': 'Términos del servicio',
  'Privacy Policy': 'Política de privacidad',
  'Create your account': 'Crea tu cuenta',
  'Cloud API creates new accounts as members. An administrator can assign elevated access.':
      'Cloud API crea las cuentas nuevas como miembros. Un administrador puede asignar acceso adicional.',
  'Full name': 'Nombre completo',
  'First and last name': 'Nombre y apellido',
  'Work email': 'Correo de trabajo',
  'At least 8 characters': 'Al menos 8 caracteres',
  'I accept the Terms of Service and Privacy Policy':
      'Acepto los Términos del servicio y la Política de privacidad',
  'Create account': 'Crear cuenta',
  'Creating…': 'Creando…',
  'Already have an account? Sign in': '¿Ya tienes una cuenta? Inicia sesión',
  'Rooms': 'Salas',
  'Room': 'Sala',
  'Report': 'Reportar',
  'Profile': 'Perfil',
  'Overview': 'Resumen',
  'Alerts': 'Alertas',
  'More': 'Más',
  'Search': 'Buscar',
  'Search a room': 'Buscar una sala',
  'Quiet': 'Silenciosa',
  'Cool': 'Fresca',
  'Free now': 'Libre ahora',
  'Floor 2': 'Piso 2',
  'Optimal': 'Óptima',
  'Moderate': 'Moderada',
  'Not recommended': 'No recomendada',
  'No data': 'Sin datos',
  'No recent data': 'Sin datos recientes',
  'No rooms match this search.': 'No hay salas que coincidan con la búsqueda.',
  'Comfort status is an estimate based on the latest values.':
      'El estado de confort se estima con las últimas lecturas.',
  'Noise': 'Ruido',
  'Temp.': 'Temp.',
  'Temperature': 'Temperatura',
  'Early temperature warning': 'Aviso temprano de temperatura',
  'min forecast': 'min de pronóstico',
  'Humidity': 'Humedad',
  'Presence': 'Presencia',
  'Free': 'Libre',
  'Occupied': 'Ocupada',
  'Usual noise by hour': 'Ruido habitual por hora',
  'dB(A) · usual level': 'dB(A) · nivel habitual',
  'History is unavailable.': 'El historial no está disponible.',
  'Not enough readings yet for a reliable hourly profile.':
      'Aún no hay lecturas suficientes para un perfil horario confiable.',
  'No recent data for this room.': 'No hay datos recientes de esta sala.',
  'Door light: green · Auto': 'Luz de puerta: verde · Auto',
  'Door light: amber · Auto': 'Luz de puerta: ámbar · Auto',
  'Door light: red · Auto': 'Luz de puerta: roja · Auto',
  'Door light: off · Auto': 'Luz de puerta: apagada · Auto',
  'Report discomfort': 'Reportar incomodidad',
  'Tell the site team what bothers you. We compare it with the reading of the room at that moment.':
      'Cuéntale al equipo de la sede qué te incomoda. Lo compararemos con la lectura de la sala en ese momento.',
  'Choose a room': 'Elige una sala',
  'What is the problem?': '¿Cuál es el problema?',
  'Too noisy': 'Demasiado ruido',
  'Too warm': 'Demasiado calor',
  'Too cold': 'Demasiado frío',
  'Comment (optional)': 'Comentario (opcional)',
  'Add details': 'Añade detalles',
  'Send report': 'Enviar reporte',
  'Site': 'Sede',
  'Notifications': 'Notificaciones',
  'Language': 'Idioma',
  'My reports': 'Mis reportes',
  'Sign out': 'Cerrar sesión',
  'On': 'Activadas',
  'No demo reports yet.': 'Aún no hay reportes de ejemplo.',
  'Notification preferences': 'Preferencias de notificaciones',
  'Report history': 'Historial de reportes',
  'Password reset': 'Restablecer contraseña',
  'Active': 'Activas',
  'Acknowledged': 'Atendidas',
  'Closed': 'Cerradas',
  'All rooms look calm.': 'Todas las salas están tranquilas.',
  'All calm in this view.': 'Todo está tranquilo en esta vista.',
  'Rooms needing attention': 'Salas que requieren atención',
  'monitored': 'monitoreadas',
  'need attention': 'requieren atención',
  'Conditions are moderate': 'Las condiciones son moderadas',
  'Noise above 60 dB(A)': 'Ruido superior a 60 dB(A)',
  'Noise above 50 dB(A)': 'Ruido superior a 50 dB(A)',
  'Thermal discomfort (PPD above 20 %)':
      'Incomodidad térmica (PPD superior a 20 %)',
  'Temperature above 25 °C': 'Temperatura superior a 25 °C',
  'Occupancy': 'Ocupación',
  'Opened': 'Abierta',
  'Duration': 'Duración',
  'Not yet': 'Todavía no',
  'Threshold 60': 'Umbral 60',
  'Max 67': 'Máx. 67',
  'Corrective action': 'Acción correctiva',
  'Describe what was done': 'Describe lo que se hizo',
  'Acknowledge and save': 'Atender y guardar',
  'Sites & rooms': 'Sedes y salas',
  'Room types': 'Tipos de sala',
  'Thresholds': 'Umbrales',
  'Edge credentials': 'Credenciales Edge',
  'Insights': 'Análisis',
  'Reports': 'Reportes',
  'Devices': 'Dispositivos',
  'Diagnostics': 'Diagnóstico',
  'Members': 'Miembros',
  'Address': 'Dirección',
  'Name': 'Nombre',
  'Code': 'Código',
  'Status': 'Estado',
  'Classification': 'Clasificación',
  'Add site': 'Añadir sede',
  'Add room': 'Añadir sala',
  'Add room type': 'Añadir tipo de sala',
  'Add type': 'Añadir tipo',
  'Classify room': 'Clasificar sala',
  'Manual room creation': 'Creación manual de sala',
  'Register your sites and classify each room by its use.':
      'Registra tus sedes y clasifica cada sala según su uso.',
  'Each type groups rooms with the same use and thresholds.':
      'Cada tipo agrupa salas con el mismo uso y los mismos umbrales.',
  'New types can have comfort thresholds.':
      'Los tipos nuevos pueden tener umbrales de confort.',
  'Comfort thresholds': 'Umbrales de confort',
  'An alert opens when a value stays above its level for the sustained time.':
      'Se abre una alerta cuando un valor supera su límite durante el tiempo indicado.',
  'Warning': 'Advertencia',
  'Critical': 'Crítico',
  'Sustained (min)': 'Duración (min)',
  'Save thresholds': 'Guardar umbrales',
  'Save': 'Guardar',
  'Saving…': 'Guardando…',
  'Cancel': 'Cancelar',
  'New credential': 'Nueva credencial',
  'Generate key': 'Generar clave',
  'Generating…': 'Generando…',
  'Node name': 'Nombre del nodo',
  'Copy key': 'Copiar clave',
  'Copy this key now. It is shown only once.':
      'Copia esta clave ahora. Solo se muestra una vez.',
  'Revoke credential': 'Revocar credencial',
  'Revoke': 'Revocar',
  'Period': 'Período',
  'Last 7 days': 'Últimos 7 días',
  'Last 30 days': 'Últimos 30 días',
  'Change per hour': 'Cambio por hora',
  'Indoor vs outdoor (r)': 'Interior frente a exterior (r)',
  'Noise vs occupied time (r)': 'Ruido frente a ocupación (r)',
  'Correlation': 'Correlación',
  'Samples': 'Muestras',
  'Noise anomalies': 'Anomalías de ruido',
  'Thermal drift': 'Variación térmica',
  'Historical reports': 'Reportes históricos',
  'Generate historical report': 'Generar reporte histórico',
  'Copy CSV': 'Copiar CSV',
  'Member report': 'Reporte de miembro',
  'Complaint': 'Incomodidad',
  'IoT devices of the site and their connection status.':
      'Dispositivos IoT de la sede y su estado de conexión.',
  'Connection': 'Conexión',
  'Online': 'En línea',
  'Online · demo': 'En línea · demo',
  'Last upload': 'Última carga',
  'Pending readings': 'Lecturas pendientes',
  'Lost batches': 'Lotes perdidos',
  'Identify device': 'Identificar dispositivo',
  'Identify': 'Identificar',
  'Register device': 'Registrar dispositivo',
  'Account active': 'Activa',
  'Account deactivated': 'Desactivada',
  'Credential active': 'Activa',
  'Credential revoked': 'Revocada',
  'Invitations by email are not available yet: accounts are created with a password from the sign-up form.': 'Las invitaciones por correo aún no están disponibles: las cuentas se crean con contraseña desde el registro.',
  'Never reported': 'Nunca ha reportado',
  'Offline': 'Desconectado',
  'Last seen': 'Última conexión',
  'Pending upload': 'Pendiente de subir',
  'Version': 'Versión',
  'Rooms reported': 'Salas reportadas',
  'Permissions': 'Permisos',
  'Revoked': 'Revocada',
  'Reactivate': 'Reactivar',
  'Admin': 'Administrador',
  'Deactivated': 'Desactivado',
  'Nothing to show yet.': 'Aún no hay nada que mostrar.',
  'No device has reported yet. Devices appear when their first reading arrives.': 'Ningún dispositivo ha reportado todavía. Aparecen al llegar su primera lectura.',
  'No Edge node has sent a heartbeat yet.': 'Ningún nodo Edge ha enviado su latido todavía.',
  'No credentials yet.': 'Aún no hay credenciales.',
  'Member invitations': 'Invitaciones a miembros',
  'Invite member': 'Invitar miembro',
  'Send invitation': 'Enviar invitación',
  'Deactivate member': 'Desactivar miembro',
  'Deactivate': 'Desactivar',
  'Role': 'Rol',
  'Yes': 'Sí',
  'No': 'No',
  'Unit': 'Unidad',
  'New': 'Nuevo',
  'Registered': 'Registrado',
  'Select site': 'Seleccionar sede',
  'No sites available.': 'No hay sedes disponibles.',
  'Select room': 'Seleccionar sala',
  'Floor': 'Piso',
  'Capacity': 'Capacidad',
  'Display name': 'Nombre visible',
  'Reliable': 'Confiable',
  'Preparing…': 'Preparando…',
  '1 min ago': 'Hace 1 min',
  'CSV copied to clipboard.': 'CSV copiado al portapapeles.',
  'Choose a site and complete both fields.':
      'Elige una sede y completa ambos campos.',
  'Choose a site from the selector on admin screens.':
      'Elige una sede desde el selector de las pantallas de administración.',
  'Create a room type first.': 'Primero crea un tipo de sala.',
  'Enter a node name.': 'Ingresa un nombre para el nodo.',
  'Credential created': 'Credencial creada',
  'Room classified.': 'Sala clasificada.',
  'Room type saved.': 'Tipo de sala guardado.',
  'Site saved.': 'Sede guardada.',
  'Thresholds saved.': 'Umbrales guardados.',
  'Demo thresholds updated for this screen.':
      'Umbrales de ejemplo actualizados en esta pantalla.',
  'Discomfort (PPD)': 'Incomodidad (PPD)',
  'Discomfort reports': 'Reportes de incomodidad',
  'Noise (LAeq)': 'Ruido (LAeq)',
  'Edge status · demo': 'Estado Edge · demo',
  'Cloud API does not expose a device directory or registration endpoint.':
      'Cloud API aún no ofrece un directorio ni registro de dispositivos.',
  'Cloud API does not expose edge diagnostics yet.':
      'Cloud API aún no ofrece diagnósticos Edge.',
  'Cloud API does not list or revoke existing credentials.':
      'Cloud API no lista ni revoca credenciales existentes.',
  'Cloud API does not list, invite or deactivate members.':
      'Cloud API no lista, invita ni desactiva miembros.',
  'Connection and data quality of the local edge node.':
      'Conexión y calidad de datos del nodo Edge local.',
  'Edge devices download new values so alerts continue working without internet.':
      'Los dispositivos Edge descargan valores nuevos para que las alertas sigan funcionando sin internet.',
  'Historical reports by room and discomfort reports sent by members.':
      'Reportes históricos por sala y reportes de incomodidad enviados por miembros.',
  'Keys that let the local edge node send room readings to the cloud.':
      'Claves que permiten al nodo Edge local enviar lecturas de salas a la nube.',
  'People of your coworking who can check rooms from the web or the mobile app.':
      'Personas del coworking que pueden consultar las salas desde la web o la app.',
  'Reading history can be copied as CSV. PDF export is not available.':
      'El historial de lecturas se puede copiar como CSV. La exportación a PDF no está disponible.',
  'The firmware code must match the code configured in the device.':
      'El código del firmware debe coincidir con el configurado en el dispositivo.',
  'The member receives an email to create a password.':
      'El miembro recibe un correo para crear su contraseña.',
  'Trends by room and their relation with the weather outside.':
      'Tendencias por sala y su relación con el clima exterior.',
  'Warning must be below critical and duration must be positive.':
      'El umbral de advertencia debe ser menor que el crítico y la duración debe ser positiva.',
  'No open alerts.': 'No hay alertas abiertas.',
  'No acknowledged alerts waiting to close.':
      'No hay alertas atendidas pendientes de cierre.',
  'No closed alerts yet.':
      'Aún no hay alertas cerradas.',
  'Sustained noise':
      'Ruido sostenido',
  'Thermal discomfort (PPD)':
      'Incomodidad térmica (PPD)',
  'Value':
      'Valor',
  'Acknowledge':
      'Atender',
  'Acknowledge alert':
      'Atender alerta',
  'Write the corrective action taken. It is saved with the alert.':
      'Escribe la acción correctiva realizada. Se guarda con la alerta.',
  'Alert acknowledged.':
      'Alerta atendida.',
  'Open alert':
      'Alerta abierta',
  'Acknowledged alert':
      'Alerta atendida',
  'Closed alert':
      'Alerta cerrada',
  'Closed at':
      'Cerrada',
  'The corrective action must have between 3 and 500 characters.':
      'La acción correctiva debe tener entre 3 y 500 caracteres.',
  'This alert is no longer open. Refresh the list.':
      'Esta alerta ya no está abierta. Actualiza la lista.',
  'Retry':
      'Reintentar',
  'Reports by room':
      'Reportes por sala',
  'No discomfort reports yet.':
      'Aún no hay reportes de incomodidad.',
  'Total':
      'Total',
  'Latest reports':
      'Últimos reportes',
  'No recent reading':
      'Sin lectura reciente',
  'Reason':
      'Motivo',
  'Sent':
      'Enviado',
  'Reading at that moment':
      'Lectura en ese momento',
  'Report sent. Thank you.':
      'Reporte enviado. Gracias.',
  'Sending…':
      'Enviando…',
  'You have not sent any report yet.':
      'Aún no has enviado ningún reporte.',
  'The comment can have up to 500 characters.':
      'El comentario puede tener hasta 500 caracteres.',
  'You already reported this in this room less than 10 minutes ago.':
      'Ya reportaste este motivo en esta sala hace menos de 10 minutos.',
  'This room no longer exists.':
      'Esta sala ya no existe.',
  'Create one key per edge node. It sends readings and alerts.':
      'Crea una clave por nodo Edge. Envía lecturas y alertas.',
  'Info':
      'Información',
  'This alert no longer exists.':
      'Esta alerta ya no existe.',
};
