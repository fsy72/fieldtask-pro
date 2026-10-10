import '../../domain/entities/intervention.dart';

class InterventionModel extends Intervention {
  const InterventionModel({
    required super.id,
    required super.client,
    required super.address,
    required super.description,
    required super.equipment,
    required super.status,
    required super.priority,
    required super.syncVersion,
    super.clientUuid,
    super.latitude,
    super.longitude,
    super.scheduledAt,
    super.notes,
    super.updatedAt,
  });

  factory InterventionModel.fromJson(Map<String, dynamic> json) =>
      InterventionModel(
        id: json['id'].toString(),
        clientUuid: json['client_uuid'] as String?,
        client: json['client'] as String? ?? '',
        address: json['address'] as String? ?? '',
        description: json['description'] as String? ?? '',
        equipment: json['equipment'] as String? ?? '',
        status: json['status'] as String? ?? 'pending',
        priority: _int(json['priority']) ?? 1,
        latitude: _double(json['latitude']),
        longitude: _double(json['longitude']),
        scheduledAt: _date(json['scheduled_at']),
        notes: json['notes'] as String?,
        syncVersion: _int(json['sync_version']) ?? 1,
        updatedAt: _date(json['updated_at']),
      );

  factory InterventionModel.fromDatabase(Map<String, Object?> row) =>
      InterventionModel(
        id: row['id']! as String,
        clientUuid: row['client_uuid'] as String?,
        client: row['client']! as String,
        address: row['address']! as String,
        description: row['description']! as String,
        equipment: row['equipment']! as String,
        status: row['status']! as String,
        priority: row['priority']! as int,
        latitude: _double(row['latitude']),
        longitude: _double(row['longitude']),
        scheduledAt: _date(row['scheduled_at']),
        notes: row['notes'] as String?,
        syncVersion: row['sync_version']! as int,
        updatedAt: _date(row['updated_at']),
      );

  Map<String, Object?> toDatabase({required int technicianId}) => {
        'id': id,
        'technician_id': technicianId,
        'client_uuid': clientUuid,
        'client': client,
        'address': address,
        'description': description,
        'equipment': equipment,
        'status': status,
        'priority': priority,
        'latitude': latitude,
        'longitude': longitude,
        'scheduled_at': scheduledAt?.toIso8601String(),
        'notes': notes,
        'sync_version': syncVersion,
        'updated_at': updatedAt?.toIso8601String(),
      };

  InterventionModel copyWith({
    String? status,
    String? notes,
    bool clearNotes = false,
    int? syncVersion,
    DateTime? updatedAt,
  }) =>
      InterventionModel(
        id: id,
        clientUuid: clientUuid,
        client: client,
        address: address,
        description: description,
        equipment: equipment,
        status: status ?? this.status,
        priority: priority,
        latitude: latitude,
        longitude: longitude,
        scheduledAt: scheduledAt,
        notes: clearNotes ? null : notes ?? this.notes,
        syncVersion: syncVersion ?? this.syncVersion,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  static int? _int(Object? value) => value is num
      ? value.toInt()
      : value == null
          ? null
          : int.tryParse(value.toString());

  static double? _double(Object? value) => value is num
      ? value.toDouble()
      : value == null
          ? null
          : double.tryParse(value.toString());

  static DateTime? _date(Object? value) =>
      value == null ? null : DateTime.tryParse(value.toString());
}
