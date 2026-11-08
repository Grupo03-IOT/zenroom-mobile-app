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

class MemberRoomsScreen extends StatefulWidget {
  const MemberRoomsScreen({
    super.key,
    required this.controller,
    this.admin = false,
  });
  final AppController controller;
  final bool admin;
  @override
  State<MemberRoomsScreen> createState() => _MemberRoomsScreenState();
}

class _MemberRoomsScreenState extends State<MemberRoomsScreen> {
  String query = '';
  String filter = ''; // sin filtro al abrir: el miembro ve todas las salas
  @override
  Widget build(BuildContext context) {
    final rooms = widget.controller.visibleRooms.where((room) {
      final matchesQuery = room.name.toLowerCase().contains(
        query.toLowerCase(),
      );
      final matchesFilter = switch (filter) {
        'Quiet' => (room.latest?.noise ?? 100) < 50,
        'Cool' => (room.latest?.temperature ?? 999) < 24,
        'Free now' => room.isFree,
        'Floor 2' => room.floor.contains('2'),
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          ScreenHeader(
            title: 'Rooms',
            trailing: SitePicker(controller: widget.controller),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FormLabel('Search'),
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, size: 19),
                    hintText: tr(context, 'Search a room'),
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['Quiet', 'Cool', 'Free now', 'Floor 2']
                        .map(
                          (name) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: LText(name),
                              selected: filter == name,
                              onSelected: (_) => setState(() => filter = filter == name ? '' : name),
                              selectedColor: ZenColors.paleBlue,
                              side: const BorderSide(color: ZenColors.border),
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 14),
                const Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusPill(RoomStatus.optimal, compact: true),
                    StatusPill(RoomStatus.moderate, compact: true),
                    StatusPill(RoomStatus.bad, compact: true),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.controller.loading && rooms.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (widget.controller.loadError != null)
                  ZenCard(
                    child: LText(
                      widget.controller.loadError!,
                      style: const TextStyle(color: ZenColors.red),
                    ),
                  )
                else if (rooms.isEmpty)
                  const ZenCard(
                    child: LText(
                      'No rooms match this search.',
                      style: TextStyle(color: ZenColors.muted),
                    ),
                  )
                else
                  ...rooms.map(
                    (room) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: RoomCard(
                        room: room,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoomDetailScreen(
                              controller: widget.controller,
                              room: room,
                              admin: widget.admin,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (!AppConfig.demoMode)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: LText(
                      'Comfort status is an estimate based on the latest values.',
                      style: TextStyle(fontSize: 11, color: ZenColors.muted),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class RoomCard extends StatelessWidget {
  const RoomCard({super.key, required this.room, this.onTap});
  final Room room;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ZenCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LText(
                    room.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  LText(
                    room.floor.isEmpty ? room.code : room.floor,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            StatusPill(room.status, compact: true),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _reading(
              'noise',
              'Noise',
              room.latest?.noise == null
                  ? '—'
                  : '${room.latest!.noise!.round()} dB',
            ),
            const SizedBox(width: 17),
            _reading(
              'temp',
              'Temp.',
              room.latest?.temperature == null
                  ? '—'
                  : '${room.latest!.temperature!.toStringAsFixed(1)} °C',
            ),
            const SizedBox(width: 17),
            _reading(
              'presence',
              'Presence',
              room.latest == null
                  ? '—'
                  : room.isFree
                  ? 'Free'
                  : 'Occupied',
            ),
          ],
        ),
        if ((room.latest?.forecast?.probability ?? 0) >= 0.85) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1D6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${tr(context, 'Early temperature warning')}: '
              '${(room.latest!.forecast!.probability * 100).round()}% · '
              '${room.latest!.forecast!.horizonMin} ${tr(context, 'min forecast')}',
              style: const TextStyle(
                color: Color(0xFF795400),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _reading(String icon, String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          ZenIcon(icon, size: 13),
          const SizedBox(width: 3),
          LText(
            label,
            style: const TextStyle(fontSize: 10, color: ZenColors.muted),
          ),
        ],
      ),
      LText(
        value,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: ZenColors.navy,
        ),
      ),
    ],
  );
}

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({
    super.key,
    required this.controller,
    required this.room,
    this.admin = false,
  });
  final AppController controller;
  final Room room;
  final bool admin;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final profile = controller.insights.hourlyProfile(
      controller.token,
      room.id,
      now,
    );
    return Scaffold(
      bottomNavigationBar: ZenBottomNav(controller: controller),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                ScreenHeader(
                  title: room.name,
                  back: () => Navigator.pop(context),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusPill(room.status, compact: true),
                          const SizedBox(width: 10),
                          LText(
                            room.latest?.timestamp == null
                                ? 'No recent data'
                                : 'Updated ${now.difference(room.latest!.timestamp!).inMinutes.clamp(0, 999)} min ago',
                            style: const TextStyle(
                              fontSize: 12,
                              color: ZenColors.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTile(
                              icon: 'noise',
                              label: 'Noise',
                              value:
                                  room.latest?.noise?.round().toString() ?? '—',
                              unit: 'dB(A)',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricTile(
                              icon: 'temp',
                              label: 'Temperature',
                              value:
                                  room.latest?.temperature?.toStringAsFixed(
                                    1,
                                  ) ??
                                  '—',
                              unit: '°C',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MetricTile(
                              icon: 'temp',
                              label: 'Humidity',
                              value:
                                  room.latest?.humidity?.round().toString() ??
                                  '—',
                              unit: '%',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricTile(
                              icon: 'presence',
                              label: 'Presence',
                              value: room.latest == null
                                  ? '—'
                                  : room.isFree
                                  ? 'Free'
                                  : 'Occupied',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<Map<String, dynamic>>>(
                        future: profile,
                        builder: (context, snapshot) => ZenCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const ZenSectionTitle('Usual noise by hour'),
                              const LText(
                                'dB(A) · usual level',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ZenColors.muted,
                                ),
                              ),
                              const SizedBox(height: 12),
                              if (snapshot.hasError)
                                const LText(
                                  'History is unavailable.',
                                  style: TextStyle(color: ZenColors.muted),
                                )
                              else if (!snapshot.hasData)
                                const Center(child: CircularProgressIndicator())
                              else if (snapshot.data!.isEmpty)
                                const LText(
                                  'Not enough readings yet for a reliable hourly profile.',
                                  style: TextStyle(color: ZenColors.muted),
                                )
                              else
                                SizedBox(
                                  height: 160,
                                  child: SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: snapshot.data!.map((slot) {
                                      final noise = (slot['avgLaeq'] as num).toDouble();
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 6),
                                        child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Container(
                                            width: 22,
                                            height: 50 + noise.clamp(0, 70),
                                            decoration: BoxDecoration(
                                              color: noise >= 50
                                                  ? const Color(0xFFF5A322)
                                                  : ZenColors.navy,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          LText(
                                            '${(slot['hour'] as num).toInt().toString().padLeft(2, '0')} h',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: ZenColors.muted,
                                            ),
                                          ),
                                          LText(
                                            noise.round().toString(),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ));
                                    }).toList(),
                                  ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 18,
                            color: Color(0xFFF5A322),
                          ),
                          const SizedBox(width: 7),
                          LText(
                            switch (room.status) {
                              RoomStatus.optimal => 'Door light: green · Auto',
                              RoomStatus.moderate => 'Door light: amber · Auto',
                              RoomStatus.bad => 'Door light: red · Auto',
                              RoomStatus.noData => 'Door light: off · Auto',
                            },
                            style: const TextStyle(color: ZenColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (!admin)
                        ZenOutlineButton(
                          label: 'Report discomfort',
                          icon: Icons.campaign_outlined,
                          onPressed: () {
                            Navigator.pop(context);
                            controller.selectTab(1);
                          },
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
}

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  String? roomId;
  String problem = 'Too noisy';
  final comment = TextEditingController();
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.controller.visibleRooms;
    final selected = rooms.any((room) => room.id == roomId)
        ? roomId
        : rooms.isEmpty
        ? null
        : rooms.first.id;
    final selectedName = selected == null
        ? 'Choose a room'
        : rooms.firstWhere((room) => room.id == selected).name;
    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: [
        const ScreenHeader(title: 'Report discomfort'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LText(
                'Tell the site team what bothers you. We compare it with the reading of the room at that moment.',
                style: TextStyle(color: ZenColors.muted),
              ),
              const SizedBox(height: 16),
              const FormLabel('Room'),
              LayoutBuilder(
                builder: (context, constraints) => PopupMenuButton<String>(
                  tooltip: tr(context, 'Select room'),
                  enabled: rooms.isNotEmpty,
                  initialValue: selected,
                  position: PopupMenuPosition.under,
                  offset: const Offset(0, 4),
                  menuPadding: const EdgeInsets.symmetric(vertical: 4),
                  constraints: BoxConstraints(
                    minWidth: constraints.maxWidth,
                    maxWidth: constraints.maxWidth,
                    maxHeight: 220,
                  ),
                  color: Colors.white,
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: ZenColors.border),
                  ),
                  onSelected: (value) => setState(() => roomId = value),
                  itemBuilder: (_) => rooms
                      .map(
                        (room) => PopupMenuItem(
                          value: room.id,
                          height: 42,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: LText(
                            room.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: ZenColors.navy,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  child: Container(
                    width: constraints.maxWidth,
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: ZenColors.blue),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: LText(
                            selectedName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: ZenColors.navy,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_drop_down,
                          color: ZenColors.muted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const ZenSectionTitle('What is the problem?'),
              ...['Too noisy', 'Too warm', 'Too cold'].map(
                (name) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Semantics(
                    button: true,
                    selected: problem == name,
                    label: name,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => setState(() => problem = name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          color: problem == name
                              ? const Color(0xFFE8F3FA)
                              : Colors.white,
                          border: Border.all(
                            color: problem == name
                                ? ZenColors.blue
                                : ZenColors.border,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              problem == name
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: problem == name
                                  ? ZenColors.blue
                                  : ZenColors.border,
                              size: 20,
                            ),
                            const SizedBox(width: 15),
                            ZenIcon(
                              name == 'Too noisy' ? 'noise' : 'temp',
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            LText(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const FormLabel('Comment (optional)'),
              TextField(
                controller: comment,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: tr(context, 'Add details'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.campaign_outlined, size: 18),
                onPressed: selected == null
                    ? null
                    : () {
                        if (!AppConfig.demoMode) {
                          showUnavailable(context, 'Discomfort reports');
                          return;
                        }
                        widget.controller.demoReports.add(problem);
                        showNotice(context, 'Demo report saved locally.');
                        widget.controller.selectTab(0);
                      },
                label: const LText('Send report'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(bottom: 20),
    children: [
      const ScreenHeader(title: 'Profile'),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFF7FC1E6),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(
                      controller.session?.name ?? '',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    LText(
                      controller.session?.email ?? '',
                      style: const TextStyle(
                        color: ZenColors.muted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ZenCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _menu(
                    context,
                    'site',
                    'Site',
                    controller.selectedSite?.name ?? '—',
                    () => showModalBottomSheet<void>(
                      context: context,
                      builder: (sheetContext) => SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(title: LText('Select site')),
                            if (controller.sites.isEmpty)
                              const ListTile(
                                title: LText('No sites available.'),
                              ),
                            for (final site in controller.sites)
                              ListTile(
                                title: Text(site.name),
                                trailing: controller.selectedSite?.id == site.id
                                    ? const Icon(
                                        Icons.check,
                                        color: ZenColors.blue,
                                      )
                                    : null,
                                onTap: () {
                                  controller.selectSite(site);
                                  Navigator.pop(sheetContext);
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _menu(
                    context,
                    'alerts',
                    'Notifications',
                    'On',
                    () => showUnavailable(context, 'Notification preferences'),
                  ),
                  LanguageMenuTile(controller: controller),
                  _menu(
                    context,
                    'report',
                    'My reports',
                    '${controller.demoReports.length} sent',
                    () => AppConfig.demoMode
                        ? showNotice(
                            context,
                            controller.demoReports.isEmpty
                                ? 'No demo reports yet.'
                                : controller.demoReports.join(', '),
                          )
                        : showUnavailable(context, 'Report history'),
                  ),
                  _menu(
                    context,
                    'legal',
                    'Terms of Service',
                    '',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalScreen(
                          title: 'Terms of Service',
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
                  _menu(
                    context,
                    'shield',
                    'Privacy Policy',
                    '',
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LegalScreen(
                          title: 'Privacy Policy',
                          controller: controller,
                        ),
                      ),
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
  Widget _menu(
    BuildContext context,
    String icon,
    String title,
    String value,
    VoidCallback onTap,
  ) => ListTile(
    leading: ZenIcon(icon, size: 20),
    title: LText(title),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (value.isNotEmpty)
          LText(
            value,
            style: const TextStyle(color: ZenColors.muted, fontSize: 12),
          ),
        const SizedBox(width: 5),
        const Icon(Icons.chevron_right, size: 18),
      ],
    ),
    onTap: onTap,
    shape: const Border(bottom: BorderSide(color: ZenColors.border)),
  );
}
