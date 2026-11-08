import '../../../core/network/cloud_client.dart';

class CloudInsightsRepository {
  CloudInsightsRepository(this.client);
  final CloudClient client;

  /// Cloud acepta un dia (YYYY-MM-DD), una semana ISO (YYYY-Www) o un mes (YYYY-MM).
  /// Hasta 7 dias se consulta la semana; mas de 7, el mes.
  static String periodFor(DateTime reference, int days) {
    final utc = reference.toUtc();
    if (days > 7) {
      return '${utc.year}-${utc.month.toString().padLeft(2, '0')}';
    }
    final day = DateTime.utc(utc.year, utc.month, utc.day);
    final thursday = day.add(Duration(days: 4 - day.weekday));
    final yearStart = DateTime.utc(thursday.year, 1, 1);
    final week = ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${week.toString().padLeft(2, '0')}';
  }

  /// Devuelve el analisis con la forma que usa la pantalla (coefficient, reliable, sampleSize...).
  Future<Map<String, dynamic>> roomInsights(
    String token,
    String roomId,
    DateTime reference,
    int days,
  ) async {
    final period = periodFor(reference, days);
    final body = Map<String, dynamic>.from(
      await client.request(
            'GET',
            '/api/v1/insights/rooms/$roomId?period=$period',
            token: token,
          )
          as Map,
    );
    return adapt(body);
  }

  static Map<String, dynamic> adapt(Map<String, dynamic> body) {
    final measures = Map<String, dynamic>.from(body['measures'] as Map? ?? {});
    Map<String, dynamic> measure(String key) {
      final item = Map<String, dynamic>.from(measures[key] as Map? ?? {});
      final conclusive = item['verdict'] == 'conclusive' && item['value'] != null;
      final confidence = Map<String, dynamic>.from(item['confidence'] as Map? ?? {});
      return {
        'coefficient': conclusive ? item['value'] : null,
        'slopePerHour': conclusive ? item['value'] : null,
        'reliable': conclusive,
        'sampleSize': confidence['sampleSize'] ?? 0,
      };
    }

    final quality = Map<String, dynamic>.from(body['dataQuality'] as Map? ?? {});
    final episodes = Map<String, dynamic>.from(body['noiseEpisodes'] as Map? ?? {});
    return {
      'sampleSize': quality['receivedMinutes'] ?? 0,
      'noiseVsOccupancy': measure('noiseVsOccupancy'),
      'indoorVsOutdoor': measure('indoorVsOutdoor'),
      'thermalDrift': measure('thermalDrift'),
      'noiseAnomalies': (episodes['worst'] as List?) ?? const [],
    };
  }
}
