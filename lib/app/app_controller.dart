import 'package:flutter/foundation.dart';
import '../core/config/app_config.dart';
import '../core/l10n/zenroom_i18n.dart';
import '../core/network/cloud_client.dart';
import '../features/alerting/domain/alert.dart';
import '../features/alerting/domain/alert_repository.dart';
import '../features/alerting/infrastructure/cloud_alert_repository.dart';
import '../features/alerting/infrastructure/cloud_threshold_repository.dart';
import '../features/alerting/infrastructure/demo_alert_repository.dart';
import '../features/identity/domain/session.dart';
import '../features/identity/infrastructure/cloud_identity_repository.dart';
import '../features/insights/infrastructure/cloud_insights_repository.dart';
import '../features/monitoring/domain/discomfort_report.dart';
import '../features/monitoring/domain/monitoring_repository.dart';
import '../features/monitoring/domain/room.dart';
import '../features/monitoring/infrastructure/cloud_discomfort_repository.dart';
import '../features/monitoring/infrastructure/cloud_fleet_repository.dart';
import '../features/monitoring/infrastructure/cloud_monitoring_repository.dart';
import '../features/monitoring/infrastructure/demo_discomfort_repository.dart';
import '../features/monitoring/infrastructure/demo_monitoring_repository.dart';

class AppController extends ChangeNotifier {
  AppController({AlertRepository? alerts, DiscomfortRepository? discomfort}) {
    final client = CloudClient();
    identity = CloudIdentityRepository(client);
    monitoring = AppConfig.demoMode
        ? DemoMonitoringRepository()
        : CloudMonitoringRepository(client);
    thresholds = CloudThresholdRepository(client);
    insights = CloudInsightsRepository(client);
    fleet = CloudFleetRepository(client);
    this.alerts =
        alerts ??
        (AppConfig.demoMode
            ? DemoAlertRepository()
            : CloudAlertRepository(client));
    this.discomfort =
        discomfort ??
        (AppConfig.demoMode
            ? DemoDiscomfortRepository()
            : CloudDiscomfortRepository(client));
  }
  late final CloudIdentityRepository identity;
  late final MonitoringRepository monitoring;
  late final CloudThresholdRepository thresholds;
  late final CloudInsightsRepository insights;
  late final CloudFleetRepository fleet;
  late final AlertRepository alerts;
  late final DiscomfortRepository discomfort;

  Session? session;
  List<Room> rooms = [];
  List<Site> sites = [];
  Site? selectedSite;
  bool loading = false;
  String? loadError;
  int tab = 0;

  /// Alertas en estado OPEN (solo administradores); null si no se pudo consultar.
  int? openAlerts;

  /// Reportes enviados por el miembro; null si no se pudo consultar.
  int? myReportCount;
  final ValueNotifier<AppLanguage> languageNotifier = ValueNotifier(
    AppLanguage.spanish,
  );

  bool get signedIn => session != null && !session!.isExpired;
  bool get admin => session?.role == UserRole.admin;
  String get token => session?.token ?? '';
  List<Room> get visibleRooms {
    final site = selectedSite;
    if (site == null || !rooms.any((room) => room.siteId != null)) {
      return rooms;
    }
    return rooms.where((room) => room.siteId == site.id).toList();
  }

  AppLanguage get language => languageNotifier.value;

  void setLanguage(AppLanguage value) {
    if (languageNotifier.value == value) return;
    languageNotifier.value = value;
    notifyListeners();
  }

  @override
  void dispose() {
    languageNotifier.dispose();
    super.dispose();
  }

  Future<void> signIn(
    String email,
    String password, {
    UserRole demoRole = UserRole.member,
  }) async {
    if (AppConfig.demoMode) {
      session = Session(
        token: 'demo',
        email: email.isEmpty ? 'demo@sensework.test' : email,
        name: demoRole == UserRole.admin ? 'Sandra Admin' : 'Camila Rivas',
        role: demoRole,
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
    } else {
      session = await identity.signIn(email, password);
    }
    tab = 0;
    notifyListeners();
    await refresh();
  }

  Future<void> refresh() async {
    if (!signedIn) return;
    loading = true;
    loadError = null;
    notifyListeners();
    try {
      final loadedRooms = await monitoring.rooms(token);
      final loadedSites = await monitoring.sites(token);
      rooms = loadedRooms;
      sites = loadedSites;
      await _refreshCounters();
      if (sites.isEmpty) {
        selectedSite = null;
      } else {
        final selectedId = selectedSite?.id;
        selectedSite = sites.firstWhere(
          (site) => site.id == selectedId,
          orElse: () => sites.first,
        );
      }
    } catch (error) {
      loadError = error.toString();
      if (error is CloudException && error.statusCode == 401) signOut();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Los contadores no bloquean la carga de salas si su endpoint falla.
  Future<void> _refreshCounters() async {
    if (admin) {
      try {
        openAlerts = (await alerts.alerts(
          token,
          status: AlertStatus.open,
        )).length;
      } catch (_) {
        openAlerts = null;
      }
    } else {
      try {
        myReportCount = (await discomfort.mine(token)).length;
      } catch (_) {
        myReportCount = null;
      }
    }
  }

  Future<void> refreshAlertCount() async {
    await _refreshCounters();
    notifyListeners();
  }

  Future<Alert> acknowledgeAlert(String id, String correctiveAction) async {
    final alert = await alerts.acknowledge(token, id, correctiveAction);
    await refreshAlertCount();
    return alert;
  }

  Future<DiscomfortReport> fileReport({
    required String roomId,
    required DiscomfortCategory category,
    String? comment,
  }) async {
    final report = await discomfort.file(
      token,
      roomId: roomId,
      category: category,
      comment: comment,
    );
    myReportCount = (myReportCount ?? 0) + 1;
    notifyListeners();
    return report;
  }

  void selectSite(Site site) {
    selectedSite = site;
    notifyListeners();
  }

  void selectTab(int index) {
    tab = index;
    notifyListeners();
  }

  void signOut() {
    session = null;
    rooms = [];
    sites = [];
    selectedSite = null;
    openAlerts = null;
    myReportCount = null;
    tab = 0;
    notifyListeners();
  }
}
