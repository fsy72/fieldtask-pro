import 'intervention.dart';

class InterventionLoadResult {
  const InterventionLoadResult({
    required this.interventions,
    required this.isFromCache,
    this.cacheUpdatedAt,
  });

  final List<Intervention> interventions;
  final bool isFromCache;
  final DateTime? cacheUpdatedAt;
}
