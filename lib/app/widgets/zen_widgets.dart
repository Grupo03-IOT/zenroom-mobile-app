import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/zenroom_i18n.dart';
import '../../core/theme/zenroom_theme.dart';
import '../../features/monitoring/domain/room.dart';

class LText extends StatelessWidget {
  const LText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.textDirection,
  });

  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) => Text(
    tr(context, data),
    style: style,
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    textDirection: textDirection,
  );
}

class ZenIcon extends StatelessWidget {
  const ZenIcon(this.name, {super.key, this.size = 20, this.color});
  final String name;
  final double size;
  final Color? color;
  static const _asset = {
    'logo': 'logo-isotype.svg',
    'rooms': 'member-icon-meeting-room.svg',
    'report': 'member-icon-campaign.svg',
    'person': 'member-icon-person.svg',
    'search': 'member-icon-search.svg',
    'noise': 'member-icon-volume-up.svg',
    'temp': 'member-icon-thermostat.svg',
    'presence': 'member-icon-group.svg',
    'overview': 'icon-dashboard.svg',
    'alerts': 'icon-notifications.svg',
    'devices': 'icon-sensors.svg',
    'diagnostics': 'icon-monitoring.svg',
    'shield': 'icon-shield.svg',
    'thresholds': 'icon-tune.svg',
    'reports': 'icon-description.svg',
    'members': 'icon-group.svg',
    'site': 'icon-location-on.svg',
    'legal': 'icon-gavel.svg',
    'help': 'icon-help.svg',
  };
  @override
  Widget build(BuildContext context) {
    final asset = _asset[name];
    if (asset == null)
      return Icon(Icons.circle_outlined, size: size, color: color);
    return SvgPicture.asset(
      'assets/figma/$asset',
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color!, BlendMode.srcIn),
    );
  }
}

class ZenCard extends StatelessWidget {
  const ZenCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.margin = EdgeInsets.zero,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final EdgeInsets margin;
  @override
  Widget build(BuildContext context) => Container(
    margin: margin,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: ZenColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key, this.compact = false});
  final RoomStatus status;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final (label, fg, bg, mark) = switch (status) {
      RoomStatus.optimal => (
        'Optimal',
        ZenColors.green,
        ZenColors.paleGreen,
        'status-shape-ok.svg',
      ),
      RoomStatus.moderate => (
        'Moderate',
        ZenColors.amber,
        ZenColors.paleAmber,
        'status-shape-warn.svg',
      ),
      RoomStatus.bad => (
        'Not recommended',
        ZenColors.red,
        ZenColors.paleRed,
        '',
      ),
      RoomStatus.noData => (
        'No data',
        ZenColors.muted,
        ZenColors.border,
        'status-shape-off.svg',
      ),
    };
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mark.isEmpty)
            Container(
              width: compact ? 9 : 10,
              height: compact ? 9 : 10,
              decoration: BoxDecoration(
                color: ZenColors.red,
                borderRadius: BorderRadius.circular(1),
              ),
            )
          else
            SvgPicture.asset(
              'assets/figma/$mark',
              width: compact ? 9 : 10,
              height: compact ? 9 : 10,
            ),
          const SizedBox(width: 5),
          LText(
            label,
            style: TextStyle(
              color: fg,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ZenSectionTitle extends StatelessWidget {
  const ZenSectionTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LText(text, style: Theme.of(context).textTheme.titleMedium),
  );
}

class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});
  @override
  Widget build(BuildContext context) {
    if (!AppConfig.demoMode) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      color: const Color(0xFFFFF4DC),
      child: const LText(
        'Modo demo · datos de ejemplo',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: ZenColors.amber),
      ),
    );
  }
}

void showNotice(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: LText(message)));
}

void showUnavailable(BuildContext context, String feature) {
  final label = tr(context, feature);
  showNotice(
    context,
    ZenroomI18n.languageOf(context) == AppLanguage.spanish
        ? '$label: Cloud API todavía no ofrece esta función.'
        : '$label: Cloud API does not support this feature yet.',
  );
}

class FormLabel extends StatelessWidget {
  const FormLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: LText(
      text,
      style: const TextStyle(
        fontSize: 12,
        color: ZenColors.muted,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class ZenOutlineButton extends StatelessWidget {
  const ZenOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon ?? Icons.chevron_right, size: 18),
    label: LText(label),
    style: OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(40),
      foregroundColor: ZenColors.blue,
      side: const BorderSide(color: ZenColors.border),
      shape: const StadiumBorder(),
    ),
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
  });
  final String icon;
  final String label;
  final String value;
  final String unit;
  @override
  Widget build(BuildContext context) => ZenCard(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ZenIcon(icon, size: 16),
            const SizedBox(width: 7),
            LText(
              label,
              style: const TextStyle(fontSize: 12, color: ZenColors.muted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            LText(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ZenColors.navy,
              ),
            ),
            if (unit.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: LText(
                  unit,
                  style: const TextStyle(fontSize: 12, color: ZenColors.muted),
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
