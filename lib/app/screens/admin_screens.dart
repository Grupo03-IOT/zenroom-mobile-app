import 'package:flutter/material.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../../features/alerting/domain/alert.dart';
import '../../features/monitoring/domain/room.dart';
import '../app_controller.dart';
import '../widgets/language_menu_tile.dart';
import '../widgets/zen_widgets.dart';
import 'home_shell.dart';
import 'legal_screen.dart';
import 'member_screens.dart';
import 'admin_features.dart';

class AdminOverviewScreen extends StatelessWidget {
  const AdminOverviewScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final rooms = controller.rooms;
    final optimal = rooms
        .where((room) => room.status == RoomStatus.optimal)
        .length;
    final attention = rooms
        .where(
          (room) =>
              room.status == RoomStatus.moderate ||
              room.status == RoomStatus.bad,
        )
        .toList();
    final occupied = rooms.where((room) => !room.isFree).length;
    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: ListView(
        children: [
          ScreenHeader(
            title: 'Overview',
            trailing: SitePicker(controller: controller),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        context,
                        'rooms',
                        'Rooms',
                        '${rooms.length}',
                        'monitored',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _stat(
                        context,
                        'overview',
                        'Optimal',
                        '$optimal',
                        'of ${rooms.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        key: const ValueKey('overview-open-alerts'),
                        onTap: () => controller.selectTab(1),
                        child: _stat(
                          context,
                          'alerts',
                          'Alerts',
                          '${controller.openAlerts ?? '—'}',
                          'need attention',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _stat(
                        context,
                        'presence',
                        'Occupied',
                        '$occupied',
                        'of ${rooms.length}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ZenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZenSectionTitle('Rooms needing attention'),
                      if (attention.isEmpty)
                        const LText(
                          'All rooms look calm.',
                          style: TextStyle(color: ZenColors.muted),
                        )
                      else
                        ...attention
                            .take(4)
                            .map(
                              (room) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: LText(
                                  room.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: LText(
                                  room.attentionReason ??
                                      'Conditions are moderate',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ZenColors.muted,
                                  ),
                                ),
                                trailing: StatusPill(
                                  room.status,
                                  compact: true,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoomDetailScreen(
                                      controller: controller,
                                      room: room,
                                      admin: true,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(RoomStatus.optimal, compact: true),
                    StatusPill(RoomStatus.moderate, compact: true),
                    StatusPill(RoomStatus.bad, compact: true),
                  ],
                ),
                if (controller.loadError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: LText(
                      controller.loadError!,
                      style: const TextStyle(color: ZenColors.red),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String icon,
    String label,
    String count,
    String suffix,
  ) => ZenCard(
    child: SizedBox(
      height: 48,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ZenIcon(icon, size: 15),
              const SizedBox(width: 6),
              LText(
                label,
                style: const TextStyle(fontSize: 12, color: ZenColors.muted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: count,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                    color: ZenColors.navy,
                  ),
                ),
                TextSpan(
                  text: ' ${tr(context, suffix)}',
                  style: const TextStyle(fontSize: 11, color: ZenColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AdminAlertsScreen extends StatefulWidget {
  const AdminAlertsScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<AdminAlertsScreen> {
  AlertStatus filter = AlertStatus.open;
  int generation = 0;

  Future<void> _reload() async {
    setState(() => generation++);
    await widget.controller.refreshAlertCount();
  }

  String _chipLabel(AlertStatus status) => switch (status) {
    AlertStatus.open =>
      widget.controller.openAlerts == null
          ? 'Active'
          : 'Active (${widget.controller.openAlerts})',
    AlertStatus.acknowledged => 'Acknowledged',
    AlertStatus.closed => 'Closed',
  };

  String get _emptyText => switch (filter) {
    AlertStatus.open => 'No open alerts.',
    AlertStatus.acknowledged => 'No acknowledged alerts waiting to close.',
    AlertStatus.closed => 'No closed alerts yet.',
  };

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _reload,
    child: ListView(
      key: const ValueKey('alerts-screen'),
      children: [
        ScreenHeader(
          title: 'Alerts',
          trailing: SitePicker(controller: widget.controller),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final status in AlertStatus.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: ValueKey('alerts-tab-${status.code}'),
                          label: LText(_chipLabel(status)),
                          selected: filter == status,
                          onSelected: (_) => setState(() => filter = status),
                          selectedColor: ZenColors.blue,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: filter == status
                                ? Colors.white
                                : ZenColors.blue,
                          ),
                          side: const BorderSide(color: ZenColors.border),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              LiveList<Alert>(
                key: ValueKey('alerts-list-${filter.code}-$generation'),
                empty: _emptyText,
                load: () => widget.controller.alerts.alerts(
                  widget.controller.token,
                  status: filter,
                ),
                itemBuilder: (context, alert, reload) => _AlertSummary(
                  controller: widget.controller,
                  alert: alert,
                  onChanged: _reload,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

String _roomName(AppController controller, Alert alert) {
  final match = controller.rooms.where((room) => room.id == alert.roomId);
  if (match.isNotEmpty) return match.first.name;
  return alert.roomCode.isEmpty ? '—' : alert.roomCode;
}

String _ruleLabel(Alert alert) => switch (alert.rule) {
  'sustained_noise' => 'Sustained noise',
  'thermal_discomfort' => 'Thermal discomfort (PPD)',
  _ => alert.rule,
};

String _alertValue(Alert alert) {
  final value = alert.value;
  if (value == null) return '—';
  return alert.isNoise
      ? '${value.toStringAsFixed(1)} dB(A)'
      : '${value.toStringAsFixed(1)} %';
}

String _minutes(Duration? duration) =>
    duration == null ? '—' : '${duration.inMinutes} min';

class _AlertSummary extends StatelessWidget {
  const _AlertSummary({
    required this.controller,
    required this.alert,
    required this.onChanged,
  });
  final AppController controller;
  final Alert alert;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) => InkWell(
    key: ValueKey('alert-card-${alert.id}'),
    onTap: () async {
      final changed = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AlertDetailScreen(controller: controller, alert: alert),
        ),
      );
      if (changed == true) await onChanged();
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LText(
                _roomName(controller, alert),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            _SeverityPill(alert.severity),
          ],
        ),
        const SizedBox(height: 4),
        LText(
          _ruleLabel(alert),
          style: const TextStyle(fontSize: 12, color: ZenColors.muted),
        ),
        const SizedBox(height: 8),
        _DetailRow('Value', _alertValue(alert)),
        _DetailRow('Opened', formatLocalDateTime(alert.openedAt)),
        if (alert.correctiveAction != null) ...[
          const SizedBox(height: 6),
          const LText(
            'Corrective action',
            style: TextStyle(fontSize: 12, color: ZenColors.muted),
          ),
          const SizedBox(height: 2),
          LText(alert.correctiveAction!, style: const TextStyle(fontSize: 13)),
          _DetailRow('Acknowledged by', alert.acknowledgedByName ?? '—'),
        ],
        if (alert.isOpen)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              key: ValueKey('alert-acknowledge-${alert.id}'),
              onPressed: () async {
                final updated = await showAcknowledgeDialog(
                  context,
                  controller,
                  alert,
                );
                if (updated != null) await onChanged();
              },
              child: const LText('Acknowledge'),
            ),
          ),
      ],
    ),
  );
}

class _SeverityPill extends StatelessWidget {
  const _SeverityPill(this.severity);
  final String severity;
  @override
  Widget build(BuildContext context) {
    final (label, fg, bg) = switch (severity.toLowerCase()) {
      'critical' => ('Critical', ZenColors.red, ZenColors.paleRed),
      'info' => ('Info', ZenColors.blue, ZenColors.paleBlue),
      _ => ('Warning', ZenColors.amber, ZenColors.paleAmber),
    };
    return Container(
      key: ValueKey('alert-severity-${severity.toLowerCase()}'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: LText(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

/// Pide la accion correctiva (3 a 500 caracteres) y reconoce la alerta.
/// Devuelve la alerta actualizada, o null si se cancelo.
Future<Alert?> showAcknowledgeDialog(
  BuildContext context,
  AppController controller,
  Alert alert,
) async {
  final result = await showDialog<Alert>(
    context: context,
    builder: (_) => _AcknowledgeDialog(controller: controller, alert: alert),
  );
  if (result != null && context.mounted) {
    showNotice(context, 'Alert acknowledged.');
  }
  return result;
}

class _AcknowledgeDialog extends StatefulWidget {
  const _AcknowledgeDialog({required this.controller, required this.alert});
  final AppController controller;
  final Alert alert;
  @override
  State<_AcknowledgeDialog> createState() => _AcknowledgeDialogState();
}

OutlineInputBorder _actionBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(6)),
      borderSide: BorderSide(color: color, width: width),
    );

class _AcknowledgeDialogState extends State<_AcknowledgeDialog> {
  final text = TextEditingController();
  String? error;
  bool busy = false;

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final invalid = CorrectiveAction.validate(text.text);
    if (invalid != null) {
      setState(() => error = invalid);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final updated = await widget.controller.acknowledgeAlert(
        widget.alert.id,
        text.text,
      );
      if (mounted) Navigator.pop(context, updated);
    } catch (failure) {
      if (mounted) {
        setState(() {
          busy = false;
          error = failure.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const LText('Acknowledge alert'),
    scrollable: true,
    content: Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const LText(
            'Write the corrective action taken. It is saved with the alert.',
            style: TextStyle(color: ZenColors.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('acknowledge-action-input'),
            controller: text,
            autofocus: true,
            minLines: 3,
            maxLines: 4,
            maxLength: CorrectiveAction.maxLength,
            scrollPadding: const EdgeInsets.all(48),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: _actionBorder(ZenColors.muted),
              enabledBorder: _actionBorder(ZenColors.muted),
              focusedBorder: _actionBorder(ZenColors.blue, width: 1.5),
              errorBorder: _actionBorder(ZenColors.red),
              focusedErrorBorder: _actionBorder(ZenColors.red, width: 1.5),
              hintText: tr(context, 'Describe what was done'),
              errorText: error == null ? null : tr(context, error!),
              errorMaxLines: 3,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        key: const ValueKey('acknowledge-cancel'),
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const LText('Cancel'),
      ),
      ElevatedButton(
        key: const ValueKey('acknowledge-submit'),
        onPressed: busy ? null : _submit,
        child: LText(busy ? 'Saving…' : 'Acknowledge and save'),
      ),
    ],
  );
}

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.controller,
    required this.alert,
  });
  final Alert alert;
  final AppController controller;
  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  late Alert alert = widget.alert;
  bool changed = false;

  String get _statusLabel => switch (alert.status) {
    AlertStatus.open => 'Open alert',
    AlertStatus.acknowledged => 'Acknowledged alert',
    AlertStatus.closed => 'Closed alert',
  };

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: false,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) Navigator.pop(context, changed);
    },
    child: Scaffold(
      bottomNavigationBar: ZenBottomNav(controller: widget.controller),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              key: const ValueKey('alert-detail'),
              children: [
                ScreenHeader(
                  title: _roomName(widget.controller, alert),
                  back: () => Navigator.pop(context, changed),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          _SeverityPill(alert.severity),
                          const SizedBox(width: 8),
                          LText(
                            _ruleLabel(alert),
                            style: const TextStyle(
                              fontSize: 13,
                              color: ZenColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ZenCard(
                        child: Column(
                          children: [
                            _DetailRow('Status', _statusLabel),
                            _DetailRow('Value', _alertValue(alert)),
                            _DetailRow(
                              'Opened',
                              formatLocalDateTime(alert.openedAt),
                            ),
                            _DetailRow(
                              'Duration',
                              _minutes(alert.durationAt(DateTime.now())),
                            ),
                            _DetailRow(
                              'Acknowledged',
                              alert.acknowledgedAt == null
                                  ? 'Not yet'
                                  : formatLocalDateTime(alert.acknowledgedAt),
                            ),
                            if (alert.closedAt != null)
                              _DetailRow(
                                'Closed at',
                                '${formatLocalDateTime(alert.closedAt)}'
                                    '${alert.closedBy == 'AUTO' ? ' · auto' : ''}',
                              ),
                          ],
                        ),
                      ),
                      if (alert.message.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ZenCard(
                          child: LText(
                            alert.message,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                      if (alert.correctiveAction != null) ...[
                        const SizedBox(height: 14),
                        const ZenSectionTitle('Corrective action'),
                        ZenCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LText(
                                alert.correctiveAction!,
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                'Acknowledged by',
                                alert.acknowledgedByName ?? '—',
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (alert.isOpen) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          key: const ValueKey('alert-detail-acknowledge'),
                          onPressed: () async {
                            final updated = await showAcknowledgeDialog(
                              context,
                              widget.controller,
                              alert,
                            );
                            if (updated != null && mounted) {
                              setState(() {
                                alert = updated;
                                changed = true;
                              });
                            }
                          },
                          child: const LText('Acknowledge'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        LText(
          label,
          style: const TextStyle(color: ZenColors.muted, fontSize: 13),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: LText(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

class AdminMoreScreen extends StatelessWidget {
  const AdminMoreScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final entries = <(String, String)>[
      ('devices', 'Devices'),
      ('diagnostics', 'Diagnostics'),
      ('shield', 'Edge credentials'),
      ('thresholds', 'Thresholds'),
      ('overview', 'Insights'),
      ('reports', 'Reports'),
      ('members', 'Members'),
      ('rooms', 'Sites & rooms'),
      ('thresholds', 'Room types'),
      ('person', 'Profile'),
      ('legal', 'Terms of Service'),
      ('shield', 'Privacy Policy'),
    ];
    return ListView(
      children: [
        ScreenHeader(
          title: 'More',
          trailing: SitePicker(controller: controller),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              ZenCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    LanguageMenuTile(
                      controller: controller,
                      iconColor: ZenColors.muted,
                    ),
                    ...entries.map(
                      (item) => ListTile(
                        leading: ZenIcon(
                          item.$1,
                          size: 20,
                          color: ZenColors.muted,
                        ),
                        title: LText(
                          item.$2,
                          style: const TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: 17,
                          color: ZenColors.muted,
                        ),
                        shape: const Border(
                          bottom: BorderSide(color: ZenColors.border),
                        ),
                        onTap: () {
                          if (item.$2 == 'Terms of Service' ||
                              item.$2 == 'Privacy Policy') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LegalScreen(
                                  title: item.$2,
                                  controller: controller,
                                ),
                              ),
                            );
                          } else if (item.$2 == 'Profile') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => Scaffold(
                                  appBar: AppBar(title: const LText('Profile')),
                                  body: ProfileScreen(controller: controller),
                                ),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AdminFeatureScreen(
                                  controller: controller,
                                  title: item.$2,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ZenOutlineButton(
                label: 'Sign out',
                icon: Icons.logout,
                onPressed: controller.signOut,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
