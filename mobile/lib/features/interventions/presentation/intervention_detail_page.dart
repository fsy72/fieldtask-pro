import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../domain/entities/intervention.dart';
import '../domain/entities/intervention_photo.dart';
import 'intervention_location_panel.dart';
import 'intervention_providers.dart';

class InterventionDetailPage extends ConsumerStatefulWidget {
  const InterventionDetailPage({
    required this.intervention,
    super.key,
  });

  final Intervention intervention;

  @override
  ConsumerState<InterventionDetailPage> createState() =>
      _InterventionDetailPageState();
}

class _InterventionDetailPageState
    extends ConsumerState<InterventionDetailPage> {
  late Intervention _intervention;
  bool _savingChanges = false;
  bool _uploadingPhoto = false;
  final _imagePicker = ImagePicker();
  List<InterventionPhoto> _photos = [];
  bool _loadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _intervention = widget.intervention;
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      final photos = await ref
          .read(interventionsControllerProvider.notifier)
          .getPhotos(_intervention.id);
      if (mounted) setState(() => _photos = photos);
    } catch (_) {
      // Le contenu principal de la fiche reste disponible si le chargement échoue.
    } finally {
      if (mounted) setState(() => _loadingPhotos = false);
    }
  }

  Future<void> _advanceStatus() async {
    final nextStatus = switch (_intervention.status) {
      'pending' => 'in_progress',
      'in_progress' => 'completed',
      _ => null,
    };
    if (nextStatus == null) return;

    setState(() => _savingChanges = true);
    try {
      final result = await ref
          .read(interventionsControllerProvider.notifier)
          .updateStatus(intervention: _intervention, status: nextStatus);
      if (!mounted) return;
      setState(() => _intervention = result.intervention);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isQueued
                ? 'Statut enregistré hors ligne. Il sera synchronisé au retour du réseau.'
                : 'Statut mis à jour : ${_statusInfo(result.intervention.status).$1}.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final serverMessage = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      final message = error.response?.statusCode == 409
          ? serverMessage ?? 'Cette intervention a changé sur le serveur. Actualisez la liste.'
          : error.response?.statusCode == 401
              ? 'Votre session a expiré. Reconnectez-vous.'
              : serverMessage ?? 'Impossible de mettre à jour le statut.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) setState(() => _savingChanges = false);
    }
  }

  Future<void> _editNotes() async {
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _NotesEditorDialog(initialNotes: _intervention.notes),
    );
    if (value == null || !mounted) return;

    final notes = value.trim().isEmpty ? null : value.trim();
    setState(() => _savingChanges = true);
    try {
      final result = await ref
          .read(interventionsControllerProvider.notifier)
          .updateNotes(intervention: _intervention, notes: notes);
      if (!mounted) return;
      setState(() => _intervention = result.intervention);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isQueued
                ? 'Notes enregistrées hors ligne. Elles seront synchronisées au retour du réseau.'
                : 'Notes enregistrées.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final message = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Impossible d’enregistrer les notes.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) setState(() => _savingChanges = false);
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.pop(sheetContext, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (file == null || !mounted) return;
      setState(() => _uploadingPhoto = true);
      final bytes = await file.readAsBytes();
      final result = await ref
          .read(interventionsControllerProvider.notifier)
          .uploadPhoto(
            interventionId: _intervention.id,
            filePath: file.path,
          );
      if (!mounted) return;
      setState(() => _photos.add(InterventionPhoto(
            id: file.name,
            bytes: bytes,
          )));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isQueued
                ? 'Photo enregistrée hors ligne. Elle sera envoyée au retour du réseau.'
                : 'Photo envoyée au serveur.',
          ),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      final payload = error.response?.data;
      final serverMessage = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      final message = status == 413 || status == 422
          ? serverMessage ?? 'La photo est trop volumineuse ou son format est invalide.'
          : serverMessage ?? 'Envoi impossible. Vérifiez la connexion et réessayez.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de prendre ou lire la photo : $error')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _addSignature() async {
    final bytes = await showDialog<Uint8List>(
      context: context,
      builder: (_) => const _SignatureDialog(),
    );
    if (bytes == null || !mounted) return;

    setState(() => _uploadingPhoto = true);
    try {
      final result = await ref
          .read(interventionsControllerProvider.notifier)
          .uploadPhoto(
            interventionId: _intervention.id,
            bytes: bytes,
            type: 'signature',
          );
      if (!mounted) return;
      setState(() {
        _photos.removeWhere((photo) => photo.type == 'signature');
        _photos.add(InterventionPhoto(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          bytes: bytes,
          type: 'signature',
        ));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isQueued
              ? 'Signature enregistrée hors ligne. Elle sera envoyée au retour du réseau.'
              : 'Signature envoyée au serveur.'),
        ),
      );
    } on DioException catch (error) {
      if (!mounted) return;
      final payload = error.response?.data;
      final message = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message ?? 'Impossible d’enregistrer la signature.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $error')),
      );
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _statusInfo(_intervention.status);
    final nextStatus = switch (_intervention.status) {
      'pending' => ('in_progress', 'Démarrer l’intervention', Icons.play_arrow),
      'in_progress' => ('completed', 'Terminer l’intervention', Icons.check),
      _ => null,
    };
    final photos = _photos.where((photo) => photo.type == 'photo');
    final signatures = _photos.where((photo) => photo.type == 'signature');
    final signature = signatures.isEmpty ? null : signatures.last;
    return Scaffold(
      appBar: AppBar(title: const Text('Détail de l’intervention')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _intervention.client,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      _StatusTag(label: status.$1, color: status.$2),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _DetailRow(
                    icon: Icons.location_on_outlined,
                    label: 'Adresse',
                    value: _intervention.address,
                  ),
                  _DetailRow(
                    icon: Icons.build_outlined,
                    label: 'Équipement',
                    value: _intervention.equipment,
                  ),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: 'Priorité',
                    value: '${_intervention.priority}/3',
                  ),
                  if (_intervention.scheduledAt != null)
                    _DetailRow(
                      icon: Icons.schedule_outlined,
                      label: 'Date prévue',
                      value: _formatDate(_intervention.scheduledAt!),
                    ),
                ],
              ),
            ),
          ),
          if (_intervention.latitude != null &&
              _intervention.longitude != null) ...[
            const SizedBox(height: 12),
            InterventionLocationPanel(
              latitude: _intervention.latitude!,
              longitude: _intervention.longitude!,
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Card(
              child: ListTile(
                leading: Icon(Icons.location_off_outlined),
                title: Text('Carte indisponible'),
                subtitle: Text(
                  'Les coordonnées GPS de cette intervention ne sont pas renseignées.',
                ),
              ),
            ),
          ],
          if (nextStatus != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _savingChanges ? null : _advanceStatus,
              icon: _savingChanges
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(nextStatus.$3),
              label: Text(_savingChanges ? 'Mise à jour…' : nextStatus.$2),
            ),
          ] else ...[
            const SizedBox(height: 12),
            const Text('Cette intervention est terminée.'),
          ],
          const SizedBox(height: 16),
          _TextSection(
            title: 'Description',
            text: _intervention.description,
            icon: Icons.subject_outlined,
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Photos de l’intervention',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 12),
                  if (_loadingPhotos)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    ),
                  if (photos.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final photo in photos)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              photo.bytes,
                              width: 88,
                              height: 88,
                              fit: BoxFit.cover,
                              semanticLabel: photo.caption ?? 'Photo intervention',
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _uploadingPhoto ? null : _addPhoto,
                    icon: _uploadingPhoto
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      _uploadingPhoto ? 'Envoi en cours…' : 'Ajouter une photo',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signature du client',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                  const SizedBox(height: 12),
                  if (signature != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.memory(
                        signature.bytes,
                        height: 130,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        semanticLabel: 'Signature du client',
                      ),
                    )
                  else
                    const Text('Aucune signature enregistrée.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _uploadingPhoto || _intervention.status != 'completed'
                        ? null
                        : _addSignature,
                    icon: const Icon(Icons.draw_outlined),
                    label: Text(signature == null
                        ? 'Recueillir la signature'
                        : 'Remplacer la signature'),
                  ),
                  if (_intervention.status != 'completed')
                    Text(
                      'Terminez l’intervention pour recueillir la signature.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.notes_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Notes',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Modifier les notes',
                        onPressed: _savingChanges ? null : _editNotes,
                        icon: const Icon(Icons.edit_outlined),
                      ),
                    ],
                  ),
                  Text(
                    _hasText(_intervention.notes)
                        ? _intervention.notes!.trim()
                        : 'Aucune note. Touchez le crayon pour en ajouter.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final _boundaryKey = GlobalKey();
  final List<Offset?> _points = [];

  Future<void> _save() async {
    if (!_points.any((point) => point != null)) return;
    final boundary = _boundaryKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data != null && mounted) {
      Navigator.of(context).pop(data.buffer.asUint8List());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Signature du client'),
        content: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.72,
          height: 220,
          child: RepaintBoundary(
            key: _boundaryKey,
            child: ColoredBox(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: (details) =>
                    setState(() => _points.add(details.localPosition)),
                onPanUpdate: (details) =>
                    setState(() => _points.add(details.localPosition)),
                onPanEnd: (_) => setState(() => _points.add(null)),
                child: CustomPaint(
                  painter: _SignaturePainter(_points),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(_points.clear),
            child: const Text('Effacer'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: _points.any((point) => point != null) ? _save : null,
            child: const Text('Enregistrer'),
          ),
        ],
      );
}

class _SignaturePainter extends CustomPainter {
  const _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < points.length - 1; index++) {
      final start = points[index];
      final end = points[index + 1];
      if (start != null && end != null) {
        canvas.drawLine(start, end, paint);
      } else if (start != null) {
        canvas.drawCircle(start, paint.strokeWidth / 2, paint);
      }
    }
    if (points.length == 1 && points.first != null) {
      canvas.drawCircle(points.first!, paint.strokeWidth / 2, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

class _NotesEditorDialog extends StatefulWidget {
  const _NotesEditorDialog({required this.initialNotes});

  final String? initialNotes;

  @override
  State<_NotesEditorDialog> createState() => _NotesEditorDialogState();
}

class _NotesEditorDialogState extends State<_NotesEditorDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNotes ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Notes de l’intervention'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          minLines: 3,
          maxLines: 7,
          maxLength: 5000,
          decoration: const InputDecoration(
            hintText: 'Ajouter des observations…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Enregistrer'),
          ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 3),
                  Text(value, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      );
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.title,
    required this.text,
    required this.icon,
  });

  final String title;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 10),
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          )),
                ],
              ),
              const SizedBox(height: 12),
              Text(text, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
}

(String, Color) _statusInfo(String status) => switch (status) {
      'in_progress' => ('En cours', Colors.blue),
      'completed' => ('Terminée', Colors.green),
      _ => ('En attente', Colors.orange),
    };

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year à $hour:$minute';
}

