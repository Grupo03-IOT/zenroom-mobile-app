import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../app_controller.dart';
import '../widgets/zen_widgets.dart';
import 'admin_screens.dart';
import 'member_screens.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    final admin = controller.admin;
    final body = admin
        ? switch (controller.tab) {
            0 => AdminOverviewScreen(controller: controller),
            1 => AdminAlertsScreen(controller: controller),
            2 => MemberRoomsScreen(controller: controller, admin: true),
            _ => AdminMoreScreen(controller: controller),
          }
        : switch (controller.tab) {
            0 => MemberRoomsScreen(controller: controller),
            1 => ReportScreen(controller: controller),
            _ => ProfileScreen(controller: controller),
          };
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                if (AppConfig.demoMode) const DemoBanner(),
                Expanded(child: body),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: ZenBottomNav(controller: controller, root: true),
    );
  }
}

class ZenBottomNav extends StatelessWidget {
  const ZenBottomNav({super.key, required this.controller, this.root = false});
  final AppController controller;
  final bool root;
  @override
  Widget build(BuildContext context) {
    final labels = controller.admin
        ? const ['Overview', 'Alerts', 'Rooms', 'More']
        : const ['Rooms', 'Report', 'Profile'];
    final icons = controller.admin
        ? const ['overview', 'alerts', 'rooms', 'more']
        : const ['rooms', 'report', 'person'];
    return ColoredBox(
      color: const Color(0xFF0F2A3D),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: List.generate(labels.length, (index) {
                  final selected = controller.tab == index;
                  final itemColor = selected
                      ? const Color(0xFFF5A623)
                      : const Color(0xFFD4D9DC);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Material(
                        color: selected
                            ? const Color(0xFF2C4454)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(29),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(29),
                          onTap: () {
                            if (!root) {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            }
                            controller.selectTab(index);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                icons[index] == 'more'
                                    ? Icon(
                                        Icons.menu,
                                        size: 23,
                                        color: itemColor,
                                      )
                                    : ZenIcon(
                                        icons[index],
                                        size: 23,
                                        color: itemColor,
                                      ),
                                const SizedBox(height: 5),
                                LText(
                                  labels[index],
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: itemColor,
                                    fontWeight: selected
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.trailing,
    this.back,
  });
  final String title;
  final Widget? trailing;
  final VoidCallback? back;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 15, 20, 14),
    child: Row(
      children: [
        if (back != null) ...[
          IconButton(
            onPressed: back,
            icon: const Icon(Icons.arrow_back, color: ZenColors.navy),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: LText(
            title,
            style: Theme.of(context).textTheme.headlineSmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class SitePicker extends StatelessWidget {
  const SitePicker({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) {
    if (controller.sites.isEmpty) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: tr(context, 'Select site'),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 4),
      menuPadding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 130, maxWidth: 150),
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: ZenColors.border),
      ),
      onSelected: (id) => controller.selectSite(
        controller.sites.firstWhere((site) => site.id == id),
      ),
      itemBuilder: (_) => controller.sites
          .map(
            (site) => PopupMenuItem(
              value: site.id,
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: LText(
                site.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: ZenColors.navy),
              ),
            ),
          )
          .toList(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 140),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          border: Border.all(color: ZenColors.border),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ZenIcon('site', size: 14),
            const SizedBox(width: 5),
            Flexible(
              child: LText(
                controller.selectedSite?.name ?? 'Site',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 15),
          ],
        ),
      ),
    );
  }
}
