/// El contrato de Cloud viaja en UTC. Una marca sin zona ("2026-11-27T16:59:00")
/// se interpreta como UTC (Dart la tomaria como hora local y la mostraria sin
/// convertir); las marcas con "Z" u offset se respetan.
DateTime? parseUtc(Object? value) {
  if (value == null) return null;
  final text = '$value'.trim();
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null || parsed.isUtc) return parsed;
  final hasOffset = RegExp(r'([+-]\d{2}(:?\d{2})?)$').hasMatch(text);
  if (hasOffset) return parsed.toUtc();
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
