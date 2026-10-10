import 'intervention.dart';

class InterventionStatusUpdateResult {
  const InterventionStatusUpdateResult({
    required this.intervention,
    required this.isQueued,
  });

  final Intervention intervention;
  final bool isQueued;
}
