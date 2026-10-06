class Threshold {
  const Threshold({
    required this.metric,
    required this.warnValue,
    required this.criticalValue,
    required this.sustainedMinutes,
    this.enabled = true,
  });
  final String metric;
  final double warnValue;
  final double criticalValue;
  final int sustainedMinutes;
  final bool enabled;
  factory Threshold.fromJson(Map<String, dynamic> json) => Threshold(
    metric: '${json['metric'] ?? ''}',
    warnValue: (json['warnValue'] as num?)?.toDouble() ?? 0,
    criticalValue: (json['criticalValue'] as num?)?.toDouble() ?? 0,
    sustainedMinutes: (json['sustainedMinutes'] as num?)?.toInt() ?? 1,
    enabled: json['enabled'] != false,
  );
  Map<String, dynamic> toJson() => {
    'warnValue': warnValue,
    'criticalValue': criticalValue,
    'sustainedMinutes': sustainedMinutes,
    'enabled': enabled,
  };
}
