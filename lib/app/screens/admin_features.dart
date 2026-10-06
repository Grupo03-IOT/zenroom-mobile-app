import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../../features/alerting/domain/threshold.dart' as alerting;
import '../../features/monitoring/domain/room.dart';
import '../app_controller.dart';
import '../widgets/zen_widgets.dart';
import 'home_shell.dart';

class AdminFeatureScreen extends StatelessWidget {
  const AdminFeatureScreen({
    super.key,
    required this.controller,
    required this.title,
  });
  final AppController controller;
  final String title;
  @override
  Widget build(BuildContext context) {
    final content = switch (title) {
      'Sites & rooms' => SitesRoomsContent(controller: controller),
      'Room types' => RoomTypesContent(controller: controller),
      'Thresholds' => ThresholdsContent(controller: controller),
      'Edge credentials' => CredentialsContent(controller: controller),
      'Insights' => InsightsContent(controller: controller),
      'Reports' => ReportsContent(controller: controller),
      'Devices' => DevicesContent(controller: controller),
      'Diagnostics' => DiagnosticsContent(controller: controller),
      'Members' => MembersContent(controller: controller),
      _ => const SizedBox.shrink(),
    };
    return Scaffold(
      bottomNavigationBar: ZenBottomNav(controller: controller),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: ListView(
              children: [
                ScreenHeader(title: title, back: () => Navigator.pop(context)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: content,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SitesRoomsContent extends StatefulWidget {
  const SitesRoomsContent({super.key, required this.controller});
  final AppController controller;
  @override
  State<SitesRoomsContent> createState() => _SitesRoomsContentState();
}

class _SitesRoomsContentState extends State<SitesRoomsContent> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LText(
          'Register your sites and classify each room by its use.',
          style: TextStyle(color: ZenColors.muted),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ...c.sites.map(
                (site) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: LText(site.name),
                    selected: c.selectedSite?.id == site.id,
                    onSelected: (_) => setState(() => c.selectSite(site)),
                    selectedColor: ZenColors.paleBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      AdminFeatureScreen(controller: c, title: 'Room types'),
                ),
              ),
              icon: const Icon(Icons.tune, size: 16),
              label: const LText('Room types'),
            ),
            OutlinedButton.icon(
              onPressed: () => _addSite(context),
              icon: const Icon(Icons.add, size: 16),
              label: const LText('Add site'),
            ),
            ElevatedButton.icon(
              onPressed: () => showUnavailable(context, 'Manual room creation'),
              icon: const Icon(Icons.add, size: 16),
              label: const LText('Add room'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (c.rooms.any((room) => !room.classified))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ZenColors.paleAmber,
              borderRadius: BorderRadius.circular(8),
            ),
            child: LText(
              '${c.rooms.where((room) => !room.classified).length} rooms have no type yet, so no thresholds apply to them.',
              style: const TextStyle(color: ZenColors.amber, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        ...c.rooms.map(
          (room) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ZenCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LText(
                    room.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _pair('Code', room.code),
                  _pair('Floor', room.floor),
                  _pair('Capacity', room.capacity?.toString() ?? '—'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const LText(
                        'Classification',
                        style: TextStyle(color: ZenColors.muted, fontSize: 12),
                      ),
                      room.classified
                          ? const StatusPill(RoomStatus.optimal, compact: true)
                          : TextButton(
                              onPressed: () => _classify(context, room),
                              child: const LText('Classify room'),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addSite(BuildContext context) async {
    final code = TextEditingController(),
        name = TextEditingController(),
        address = TextEditingController();
    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const LText('Add site'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: code,
              decoration: InputDecoration(labelText: tr(context, 'Code')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: name,
              decoration: InputDecoration(labelText: tr(context, 'Name')),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: address,
              decoration: InputDecoration(labelText: tr(context, 'Address')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const LText('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const LText('Save'),
          ),
        ],
      ),
    );
    if (save != true || code.text.trim().isEmpty || name.text.trim().isEmpty)
      return;
    try {
      await widget.controller.monitoring.createSite(widget.controller.token, {
        'code': code.text.trim(),
        'name': name.text.trim(),
        'address': address.text.trim(),
        'timezone': 'America/Lima',
      });
      await widget.controller.refresh();
      if (context.mounted) showNotice(context, 'Site saved.');
    } catch (error) {
      if (context.mounted) showNotice(context, error.toString());
    }
  }

  Future<void> _classify(BuildContext context, Room room) async {
    final site = widget.controller.selectedSite;
    if (site == null) return;
    try {
      final types = await widget.controller.monitoring.roomTypes(
        widget.controller.token,
        site.id,
      );
      if (!context.mounted) return;
      if (types.isEmpty) {
        showNotice(context, 'Create a room type first.');
        return;
      }
      final typeId = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: LText('Classify ${room.name}'),
          children: types
              .map(
                (type) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, type.id),
                  child: LText(type.name),
                ),
              )
              .toList(),
        ),
      );
      if (typeId == null) return;
      await widget.controller.monitoring.classifyRoom(
        widget.controller.token,
        room.id,
        typeId,
      );
      await widget.controller.refresh();
      if (context.mounted) showNotice(context, 'Room classified.');
    } catch (error) {
      if (context.mounted) showNotice(context, error.toString());
    }
  }
}

class RoomTypesContent extends StatefulWidget {
  const RoomTypesContent({super.key, required this.controller});
  final AppController controller;
  @override
  State<RoomTypesContent> createState() => _RoomTypesContentState();
}

class _RoomTypesContentState extends State<RoomTypesContent> {
  final code = TextEditingController(), name = TextEditingController();
  late Future<List<RoomType>> types;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    types = widget.controller.selectedSite == null
        ? Future.value([])
        : widget.controller.monitoring.roomTypes(
            widget.controller.token,
            widget.controller.selectedSite!.id,
          );
  }

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final site = widget.controller.selectedSite;
    if (site == null || code.text.trim().isEmpty || name.text.trim().isEmpty) {
      showNotice(context, 'Choose a site and complete both fields.');
      return;
    }
    try {
      await widget.controller.monitoring.createRoomType(
        widget.controller.token,
        site.id,
        {
          'code': code.text.trim(),
          'displayName': name.text.trim(),
          'description': '',
        },
      );
      code.clear();
      name.clear();
      setState(_load);
      if (mounted) showNotice(context, 'Room type saved.');
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LText(
        'Each type groups rooms with the same use and thresholds.',
        style: TextStyle(color: ZenColors.muted),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<RoomType>>(
        future: types,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return ZenCard(child: LText(snapshot.error.toString()));
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          return Column(
            children: snapshot.data!
                .map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ZenCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LText(
                            type.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          _pair('Code', type.code),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ThresholdEditorScreen(
                                    controller: widget.controller,
                                    type: type,
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.tune, size: 17),
                              label: const LText('Thresholds'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
      ZenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZenSectionTitle('Add room type'),
            const LText(
              'New types can have comfort thresholds.',
              style: TextStyle(color: ZenColors.muted),
            ),
            const SizedBox(height: 12),
            const FormLabel('Code'),
            TextField(
              controller: code,
              decoration: const InputDecoration(hintText: 'e.g. phone-booth'),
            ),
            const SizedBox(height: 12),
            const FormLabel('Display name'),
            TextField(
              controller: name,
              decoration: const InputDecoration(hintText: 'e.g. Phone booth'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: _add, child: const LText('Add type')),
          ],
        ),
      ),
    ],
  );
}

class ThresholdsContent extends StatefulWidget {
  const ThresholdsContent({super.key, required this.controller});
  final AppController controller;
  @override
  State<ThresholdsContent> createState() => _ThresholdsContentState();
}

class _ThresholdsContentState extends State<ThresholdsContent> {
  late Future<List<RoomType>> types;
  @override
  void initState() {
    super.initState();
    types = widget.controller.selectedSite == null
        ? Future.value([])
        : widget.controller.monitoring.roomTypes(
            widget.controller.token,
            widget.controller.selectedSite!.id,
          );
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LText(
        'An alert opens when a value stays above its level for the sustained time.',
        style: TextStyle(color: ZenColors.muted),
      ),
      const SizedBox(height: 14),
      FutureBuilder<List<RoomType>>(
        future: types,
        builder: (context, snapshot) {
          if (snapshot.hasError)
            return ZenCard(child: LText(snapshot.error.toString()));
          if (!snapshot.hasData) return const CircularProgressIndicator();
          if (snapshot.data!.isEmpty)
            return const ZenCard(child: LText('Create a room type first.'));
          return Column(
            children: snapshot.data!
                .map(
                  (type) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ZenCard(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ThresholdEditorScreen(
                            controller: widget.controller,
                            type: type,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: LText(type.name)),
                          const Icon(
                            Icons.chevron_right,
                            color: ZenColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    ],
  );
}

class ThresholdEditorScreen extends StatefulWidget {
  const ThresholdEditorScreen({
    super.key,
    required this.controller,
    required this.type,
  });
  final AppController controller;
  final RoomType type;
  @override
  State<ThresholdEditorScreen> createState() => _ThresholdEditorScreenState();
}

class _ThresholdEditorScreenState extends State<ThresholdEditorScreen> {
  final rows = <String, List<TextEditingController>>{};
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final defaults = {
      'laeq': [50, 60, 5],
      'l10': [55, 65, 5],
      'ppd': [10, 20, 10],
    };
    for (final entry in defaults.entries) {
      rows[entry.key] = entry.value
          .map((v) => TextEditingController(text: '$v'))
          .toList();
    }
    if (!AppConfig.demoMode) _load();
  }

  Future<void> _load() async {
    try {
      final values = await widget.controller.thresholds.list(
        widget.controller.token,
        widget.type.id,
      );
      for (final item in values) {
        final cells = rows[item.metric];
        if (cells == null) continue;
        cells[0].text = '${item.warnValue}';
        cells[1].text = '${item.criticalValue}';
        cells[2].text = '${item.sustainedMinutes}';
      }
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    }
  }

  @override
  void dispose() {
    for (final cells in rows.values) {
      for (final cell in cells) {
        cell.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _save() async {
    final values = <alerting.Threshold>[];
    for (final entry in rows.entries) {
      final warn = double.tryParse(entry.value[0].text);
      final critical = double.tryParse(entry.value[1].text);
      final duration = int.tryParse(entry.value[2].text);
      if (warn == null ||
          critical == null ||
          duration == null ||
          warn >= critical ||
          duration <= 0) {
        showNotice(
          context,
          'Warning must be below critical and duration must be positive.',
        );
        return;
      }
      values.add(
        alerting.Threshold(
          metric: entry.key,
          warnValue: warn,
          criticalValue: critical,
          sustainedMinutes: duration,
        ),
      );
    }
    setState(() => busy = true);
    try {
      if (!AppConfig.demoMode) {
        for (final value in values) {
          await widget.controller.thresholds.save(
            widget.controller.token,
            widget.type.id,
            value,
          );
        }
      }
      if (mounted)
        showNotice(
          context,
          AppConfig.demoMode
              ? 'Demo thresholds updated for this screen.'
              : 'Thresholds saved.',
        );
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
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
                title: 'Comfort thresholds',
                back: () => Navigator.pop(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LText(
                      widget.type.name,
                      style: const TextStyle(color: ZenColors.muted),
                    ),
                    const SizedBox(height: 14),
                    ...rows.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ZenCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ZenSectionTitle(switch (entry.key) {
                                'laeq' => 'Noise (LAeq)',
                                'l10' => 'Peaks (L10)',
                                _ => 'Discomfort (PPD)',
                              }),
                              _pair('Unit', entry.key == 'ppd' ? '%' : 'dB(A)'),
                              _number('Warning', entry.value[0]),
                              _number('Critical', entry.value[1]),
                              _number('Sustained (min)', entry.value[2]),
                            ],
                          ),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: busy ? null : _save,
                      child: LText(busy ? 'Saving…' : 'Save thresholds'),
                    ),
                    const SizedBox(height: 14),
                    const ZenCard(
                      child: LText(
                        'Edge devices download new values so alerts continue working without internet.',
                        style: TextStyle(color: ZenColors.muted),
                      ),
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
  Widget _number(String label, TextEditingController controller) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Row(
      children: [
        Expanded(
          child: LText(
            label,
            style: const TextStyle(fontSize: 12, color: ZenColors.muted),
          ),
        ),
        SizedBox(
          width: 70,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.right,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(isDense: true),
          ),
        ),
      ],
    ),
  );
}

Widget _pair(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      LText(
        label,
        style: const TextStyle(fontSize: 12, color: ZenColors.muted),
      ),
      Flexible(
        child: LText(
          value,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 12,
            color: ZenColors.navy,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ),
);

class CredentialsContent extends StatefulWidget {
  const CredentialsContent({super.key, required this.controller});
  final AppController controller;
  @override
  State<CredentialsContent> createState() => _CredentialsContentState();
}

class _CredentialsContentState extends State<CredentialsContent> {
  final code = TextEditingController();
  bool busy = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (code.text.trim().isEmpty) {
      showNotice(context, 'Enter a node name.');
      return;
    }
    setState(() => busy = true);
    try {
      final key = AppConfig.demoMode
          ? 'demo-edge-key-${DateTime.now().millisecondsSinceEpoch}'
          : await widget.controller.identity.createEdgeCredential(
              widget.controller.token,
              code.text.trim(),
            );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const LText('Credential created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LText('Copy this key now. It is shown only once.'),
              const SizedBox(height: 12),
              SelectableText(key),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: key));
                if (dialogContext.mounted) Navigator.pop(dialogContext);
              },
              child: const LText('Copy key'),
            ),
          ],
        ),
      );
      code.clear();
    } catch (error) {
      if (mounted) showNotice(context, error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LText(
        'Keys that let the local edge node send room readings to the cloud.',
        style: TextStyle(color: ZenColors.muted),
      ),
      const SizedBox(height: 14),
      if (!AppConfig.demoMode)
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: ZenCard(
            child: LText(
              'Cloud API does not list or revoke existing credentials.',
              style: TextStyle(color: ZenColors.muted),
            ),
          ),
        ),
      if (AppConfig.demoMode) ...[
        ZenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZenSectionTitle('edge-miraflores-01'),
              _pair(
                'Site',
                widget.controller.selectedSite?.name ?? 'Miraflores Hub',
              ),
              _pair('Status', 'Active'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      showUnavailable(context, 'Revoke credential'),
                  child: const LText('Revoke'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
      ZenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZenSectionTitle('New credential'),
            const LText(
              'Create one key per edge node. It only sends readings.',
              style: TextStyle(color: ZenColors.muted),
            ),
            const SizedBox(height: 14),
            const FormLabel('Node name'),
            TextField(
              controller: code,
              decoration: const InputDecoration(
                hintText: 'e.g. edge-miraflores-02',
              ),
            ),
            const SizedBox(height: 12),
            _pair('Site', widget.controller.selectedSite?.name ?? '—'),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: busy ? null : _create,
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: LText(busy ? 'Generating…' : 'Generate key'),
            ),
          ],
        ),
      ),
    ],
  );
}

class InsightsContent extends StatefulWidget {
  const InsightsContent({super.key, required this.controller});
  final AppController controller;
  @override
  State<InsightsContent> createState() => _InsightsContentState();
}

class _InsightsContentState extends State<InsightsContent> {
  String? roomId;
  int days = 30;
  Future<Map<String, dynamic>>? future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final rooms = widget.controller.rooms;
    final id = roomId ?? (rooms.isEmpty ? null : rooms.first.id);
    if (id == null) return;
    if (AppConfig.demoMode) {
      future = Future.value({
        'sampleSize': 1240,
        'noiseVsOccupancy': {'coefficient': .71, 'reliable': true},
        'indoorVsOutdoor': {'coefficient': .62, 'reliable': true},
        'thermalDrift': {'slopePerHour': .42, 'reliable': true},
        'noiseAnomalies': ['2026-09-12T10:00:00Z'],
      });
    } else {
      final now = DateTime.now();
      future = widget.controller.insights.roomInsights(
        widget.controller.token,
        id,
        now.subtract(Duration(days: days)),
        now,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = widget.controller.rooms;
    final selected = rooms.any((room) => room.id == roomId)
        ? roomId
        : rooms.isEmpty
        ? null
        : rooms.first.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LText(
          'Trends by room and their relation with the weather outside.',
          style: TextStyle(color: ZenColors.muted),
        ),
        const SizedBox(height: 16),
        const FormLabel('Room'),
        DropdownButtonFormField<String>(
          initialValue: selected,
          items: rooms
              .map(
                (room) =>
                    DropdownMenuItem(value: room.id, child: LText(room.name)),
              )
              .toList(),
          onChanged: (value) => setState(() {
            roomId = value;
            _load();
          }),
        ),
        const SizedBox(height: 12),
        const FormLabel('Period'),
        DropdownButtonFormField<int>(
          initialValue: days,
          items: const [
            DropdownMenuItem(value: 7, child: LText('Last 7 days')),
            DropdownMenuItem(value: 30, child: LText('Last 30 days')),
          ],
          onChanged: (value) => setState(() {
            days = value ?? 30;
            _load();
          }),
        ),
        const SizedBox(height: 14),
        FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return ZenCard(
                child: LText(
                  snapshot.error.toString(),
                  style: const TextStyle(color: ZenColors.muted),
                ),
              );
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            final data = snapshot.data!;
            final noise = data['noiseVsOccupancy'] as Map?;
            final outdoor = data['indoorVsOutdoor'] as Map?;
            final drift = data['thermalDrift'] as Map?;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ZenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZenSectionTitle('Correlation'),
                      _pair(
                        'Indoor vs outdoor (r)',
                        _format(outdoor?['coefficient']),
                      ),
                      _pair(
                        'Noise vs occupied time (r)',
                        _format(noise?['coefficient']),
                      ),
                      _pair('Samples', '${data['sampleSize'] ?? 0} min'),
                      const SizedBox(height: 7),
                      LText(
                        noise?['reliable'] == true
                            ? '● Enough data to be reliable'
                            : '○ Insufficient data',
                        style: const TextStyle(
                          fontSize: 11,
                          color: ZenColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ZenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZenSectionTitle('Thermal drift'),
                      _pair(
                        'Change per hour',
                        '${_format(drift?['slopePerHour'])} °C',
                      ),
                      _pair(
                        'Reliable',
                        drift?['reliable'] == true ? 'Yes' : 'No',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ZenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZenSectionTitle('Noise anomalies'),
                      LText(
                        '${(data['noiseAnomalies'] as List?)?.length ?? 0} minutes detected',
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  String _format(dynamic value) =>
      value is num ? value.toStringAsFixed(2) : '—';
}

class ReportsContent extends StatefulWidget {
  const ReportsContent({super.key, required this.controller});
  final AppController controller;
  @override
  State<ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  String tab = 'Discomfort reports';
  String? roomId;
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    final rooms = widget.controller.rooms;
    final selected = rooms.any((room) => room.id == roomId)
        ? roomId
        : rooms.isEmpty
        ? null
        : rooms.first.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LText(
          'Historical reports by room and discomfort reports sent by members.',
          style: TextStyle(color: ZenColors.muted),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final item in ['Discomfort reports', 'Historical reports'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: LText(item),
                    selected: tab == item,
                    onSelected: (_) => setState(() => tab = item),
                    selectedColor: ZenColors.paleBlue,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (tab == 'Discomfort reports') ...[
          if (!AppConfig.demoMode)
            const ZenCard(
              child: LText(
                'Cloud API does not provide member reports yet.',
                style: TextStyle(color: ZenColors.muted),
              ),
            )
          else if (widget.controller.demoReports.isEmpty)
            const ZenCard(child: LText('No demo discomfort reports yet.'))
          else
            ...widget.controller.demoReports.map(
              (report) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ZenSectionTitle('Member report'),
                      _pair('Complaint', report),
                      _pair('Status', 'New'),
                    ],
                  ),
                ),
              ),
            ),
        ] else
          ZenCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ZenSectionTitle('Generate historical report'),
                const LText(
                  'Reading history can be copied as CSV. PDF export is not available.',
                  style: TextStyle(color: ZenColors.muted),
                ),
                const SizedBox(height: 12),
                const FormLabel('Room'),
                DropdownButtonFormField<String>(
                  initialValue: selected,
                  items: rooms
                      .map(
                        (room) => DropdownMenuItem(
                          value: room.id,
                          child: LText(room.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => roomId = value),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  onPressed: busy || selected == null
                      ? null
                      : () async {
                          setState(() => busy = true);
                          try {
                            final now = DateTime.now();
                            final readings = await widget.controller.monitoring
                                .readings(
                                  widget.controller.token,
                                  selected,
                                  now.subtract(const Duration(days: 30)),
                                  now,
                                );
                            final csv = StringBuffer(
                              'timestamp,noise_dba,temperature_c,humidity_pct,occupied_pct\n',
                            );
                            for (final item in readings) {
                              csv.writeln(
                                '${item.timestamp.toUtc().toIso8601String()},'
                                '${item.noise ?? ''},${item.temperature ?? ''},'
                                '${item.humidity ?? ''},${item.occupancy ?? ''}',
                              );
                            }
                            await Clipboard.setData(
                              ClipboardData(text: csv.toString()),
                            );
                            if (context.mounted)
                              showNotice(context, 'CSV copied to clipboard.');
                          } catch (error) {
                            if (context.mounted)
                              showNotice(context, error.toString());
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  icon: const Icon(Icons.copy, size: 17),
                  label: LText(busy ? 'Preparing…' : 'Copy CSV'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class DevicesContent extends StatelessWidget {
  const DevicesContent({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LText(
        'IoT devices of the site and their connection status.',
        style: TextStyle(color: ZenColors.muted),
      ),
      const SizedBox(height: 14),
      if (!AppConfig.demoMode)
        const ZenCard(
          child: LText(
            'Cloud API does not expose a device directory or registration endpoint.',
            style: TextStyle(color: ZenColors.muted),
          ),
        )
      else ...[
        Row(
          children: [
            Expanded(
              child: MetricTile(
                icon: 'devices',
                label: 'Registered',
                value: '${controller.rooms.length}',
                unit: 'devices',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: MetricTile(
                icon: 'overview',
                label: 'Online',
                value: '${controller.rooms.length}',
                unit: 'devices',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...controller.rooms
            .take(3)
            .map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ZenCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LText(
                        'esp32-${room.code}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      _pair('Room', room.name),
                      _pair('Status', 'Online · demo'),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () =>
                              showUnavailable(context, 'Identify device'),
                          child: const LText('Identify'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
      const SizedBox(height: 14),
      ZenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZenSectionTitle('Register device'),
            const LText(
              'The firmware code must match the code configured in the device.',
              style: TextStyle(color: ZenColors.muted),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(hintText: 'e.g. esp32-sala-09'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => showUnavailable(context, 'Register device'),
              child: const LText('Register device'),
            ),
          ],
        ),
      ),
    ],
  );
}

class DiagnosticsContent extends StatelessWidget {
  const DiagnosticsContent({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LText(
        'Connection and data quality of the local edge node.',
        style: TextStyle(color: ZenColors.muted),
      ),
      const SizedBox(height: 14),
      if (!AppConfig.demoMode)
        const ZenCard(
          child: LText(
            'Cloud API does not expose edge diagnostics yet.',
            style: TextStyle(color: ZenColors.muted),
          ),
        )
      else
        ZenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZenSectionTitle('Edge status · demo'),
              _pair('Connection', 'Online'),
              _pair('Last upload', '1 min ago'),
              _pair('Pending readings', '0'),
              _pair('Lost batches', '0'),
            ],
          ),
        ),
    ],
  );
}

class MembersContent extends StatelessWidget {
  const MembersContent({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const LText(
        'People of your coworking who can check rooms from the web or the mobile app.',
        style: TextStyle(color: ZenColors.muted),
      ),
      const SizedBox(height: 14),
      if (!AppConfig.demoMode)
        const ZenCard(
          child: LText(
            'Cloud API does not list, invite or deactivate members.',
            style: TextStyle(color: ZenColors.muted),
          ),
        )
      else
        ZenCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ZenSectionTitle('Camila Rivas'),
              _pair('Email', 'camila.rivas@mail.com'),
              _pair('Role', 'Member'),
              _pair('Status', 'Active'),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      showUnavailable(context, 'Deactivate member'),
                  child: const LText('Deactivate'),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 14),
      ZenCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ZenSectionTitle('Invite member'),
            const LText(
              'The member receives an email to create a password.',
              style: TextStyle(color: ZenColors.muted),
            ),
            const SizedBox(height: 12),
            const FormLabel('Email'),
            const TextField(
              decoration: InputDecoration(hintText: 'name@mail.com'),
            ),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => showUnavailable(context, 'Member invitations'),
              child: const LText('Send invitation'),
            ),
          ],
        ),
      ),
    ],
  );
}
