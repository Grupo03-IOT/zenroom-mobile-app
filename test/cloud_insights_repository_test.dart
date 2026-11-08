import 'package:flutter_test/flutter_test.dart';
import 'package:zenroom/features/insights/infrastructure/cloud_insights_repository.dart';

void main() {
  group('periodFor', () {
    test('mas de 7 dias consulta el mes', () {
      expect(CloudInsightsRepository.periodFor(DateTime.utc(2026, 11, 8), 30), '2026-11');
    });
    test('hasta 7 dias consulta la semana ISO', () {
      expect(CloudInsightsRepository.periodFor(DateTime.utc(2026, 11, 8), 7), '2026-W45');
      expect(CloudInsightsRepository.periodFor(DateTime.utc(2026, 1, 1), 7), '2026-W01');
      expect(CloudInsightsRepository.periodFor(DateTime.utc(2021, 1, 3), 7), '2020-W53');
    });
  });

  test('adapt convierte measures al modelo de la pantalla', () {
    final data = CloudInsightsRepository.adapt({
      'dataQuality': {'receivedMinutes': 120},
      'measures': {
        'noiseVsOccupancy': {'verdict': 'conclusive', 'value': 0.71, 'confidence': {'sampleSize': 90}},
        'indoorVsOutdoor': {'verdict': 'not_enough_evidence', 'confidence': {'sampleSize': 4}},
        'thermalDrift': {'verdict': 'no_data'},
      },
      'noiseEpisodes': {'worst': [{'from': '2026-11-08T10:00:00Z'}]},
    });
    expect(data['sampleSize'], 120);
    expect((data['noiseVsOccupancy'] as Map)['coefficient'], 0.71);
    expect((data['noiseVsOccupancy'] as Map)['reliable'], true);
    expect((data['indoorVsOutdoor'] as Map)['coefficient'], isNull);
    expect((data['thermalDrift'] as Map)['reliable'], false);
    expect((data['noiseAnomalies'] as List).length, 1);
  });
}
