import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
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
                      child: _stat(
                        context,
                        'alerts',
                        'Alerts',
                        '${attention.length}',
                        'need attention',
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
                                  room.status == RoomStatus.bad
                                      ? 'Noise above 60 dB(A)'
                                      : 'Conditions are moderate',
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
  String filter = 'Active';
  @override
  Widget build(BuildContext context) {
    final alerts = AppConfig.demoMode
        ? widget.controller.rooms
              .where(
                (room) =>
                    room.status == RoomStatus.bad ||
                    room.status == RoomStatus.moderate,
              )
              .toList()
        : <Room>[];
    final shown = alerts
        .where(
          (room) => filter == 'Closed'
              ? false
              : filter == 'Acknowledged'
              ? widget.controller.demoAcknowledged.contains(room.id)
              : !widget.controller.demoAcknowledged.contains(room.id),
        )
        .toList();
    return ListView(
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
                    for (final name in ['Active', 'Acknowledged', 'Closed'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: LText(
                            name == 'Active'
                                ? 'Active (${alerts.length - widget.controller.demoAcknowledged.length})'
                                : name,
                          ),
                          selected: filter == name,
                          onSelected: (_) => setState(() => filter = name),
                          selectedColor: ZenColors.blue,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            color: filter == name
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
              if (!AppConfig.demoMode)
                const ZenCard(
                  child: LText(
                    'Cloud API does not provide an alert listing endpoint yet.',
                    style: TextStyle(color: ZenColors.muted),
                  ),
                )
              else if (shown.isEmpty)
                const ZenCard(
                  child: LText(
                    'All calm in this view.',
                    style: TextStyle(color: ZenColors.muted),
                  ),
                )
              else
                ...shown.map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: ZenCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AlertDetailScreen(
                            controller: widget.controller,
                            room: room,
                            onAcknowledge: () {
                              setState(
                                () => widget.controller.demoAcknowledged.add(
                                  room.id,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                LText(
                                  room.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                LText(
                                  room.status == RoomStatus.bad
                                      ? 'Noise (LAeq) · since 10:34'
                                      : 'Temperature · since 10:12',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: ZenColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          StatusPill(room.status, compact: true),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AlertDetailScreen extends StatefulWidget {
  const AlertDetailScreen({
    super.key,
    required this.controller,
    required this.room,
    required this.onAcknowledge,
  });
  final Room room;
  final AppController controller;
  final VoidCallback onAcknowledge;
  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final action = TextEditingController();
  @override
  void dispose() {
    action.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: ZenBottomNav(controller: widget.controller),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: ListView(
            children: [
              ScreenHeader(
                title: widget.room.name,
                back: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(widget.room.status),
                    const SizedBox(height: 14),
                    const ZenCard(
                      child: Column(
                        children: [
                          _DetailRow('Opened', '10:34'),
                          _DetailRow('Duration', '7 min'),
                          _DetailRow('Acknowledged', 'Not yet'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ZenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              LText(
                                'dB(A)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ZenColors.muted,
                                ),
                              ),
                              SizedBox(width: 12),
                              SizedBox(
                                width: 16,
                                child: Divider(
                                  thickness: 2,
                                  color: ZenColors.red,
                                ),
                              ),
                              SizedBox(width: 8),
                              LText(
                                'Threshold 60',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ZenColors.muted,
                                ),
                              ),
                              Spacer(),
                              LText(
                                'Max 67',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ZenColors.navy,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 14, color: ZenColors.border),
                          SizedBox(
                            height: 145,
                            child: CustomPaint(
                              size: const Size(double.infinity, 145),
                              painter: _AlertChartPainter(),
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              LText(
                                '10:12',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ZenColors.muted,
                                ),
                              ),
                              LText(
                                '10:41',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: ZenColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const FormLabel('Corrective action'),
                    TextField(
                      controller: action,
                      decoration: InputDecoration(
                        hintText: tr(context, 'Describe what was done'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        widget.onAcknowledge();
                        showNotice(
                          context,
                          'Demo acknowledgement saved locally.',
                        );
                        Navigator.pop(context);
                      },
                      child: const LText('Acknowledge and save'),
                    ),
                  ],
                ),
              ),
            ],
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
        LText(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _AlertChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = ZenColors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final threshold = Paint()
      ..color = ZenColors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final grid = Paint()
      ..color = const Color(0xFFDDE7EF)
      ..strokeWidth = 1;
    final values = [
      0.2,
      0.24,
      0.34,
      0.35,
      0.45,
      0.51,
      0.56,
      0.62,
      0.68,
      0.63,
      0.72,
      0.77,
      0.68,
      0.75,
      0.82,
    ];
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height * (1 - values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFDCEAF4), Color(0xFFE8F2F8)],
        ).createShader(Offset.zero & size),
    );
    for (final level in [0.2, 0.5, 0.8]) {
      final y = size.height * level;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final thresholdY = size.height * .50;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(
        Offset(x, thresholdY),
        Offset((x + 6).clamp(0, size.width), thresholdY),
        threshold,
      );
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
