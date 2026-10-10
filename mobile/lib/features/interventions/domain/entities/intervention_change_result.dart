import 'intervention.dart';

class InterventionChangeResult {
  const InterventionChangeResult({
    required this.intervention,
    required this.isQueued,
  });

  final Intervention intervention;
  final bool isQueued;
}
