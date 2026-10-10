class Intervention {
  const Intervention({
    required this.id,
    required this.client,
    required this.address,
    required this.description,
    required this.equipment,
    required this.status,
    required this.priority,
    required this.syncVersion,
    this.clientUuid,
    this.latitude,
    this.longitude,
    this.scheduledAt,
    this.notes,
    this.updatedAt,
  });

  final String id;
  final String? clientUuid;
  final String client;
  final String address;
  final String description;
  final String equipment;
  final String status;
  final int priority;
  final double? latitude;
  final double? longitude;
  final DateTime? scheduledAt;
  final String? notes;
  final int syncVersion;
  final DateTime? updatedAt;
}
