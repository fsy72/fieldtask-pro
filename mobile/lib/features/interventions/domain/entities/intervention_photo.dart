import 'dart:typed_data';

class InterventionPhoto {
  const InterventionPhoto({
    required this.id,
    required this.bytes,
    this.type = 'photo',
    this.caption,
  });

  final String id;
  final Uint8List bytes;
  final String type;
  final String? caption;
}
