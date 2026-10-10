import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/intervention.dart';
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
  bool _savingStatus = false;

  @override
  void initState() {
    super.initState();
    _intervention = widget.intervention;
  }

  Future<void> _advanceStatus() async {
    final nextStatus = switch (_intervention.status) {
      'pending' => 'in_progress',
      'in_progress' => 'completed',
      _ => null,
    };
    if (nextStatus == null) return;

    setState(() => _savingStatus = true);
    try {
      final updated = await ref
          .read(interventionsControllerProvider.notifier)
          .updateStatus(intervention: _intervention, status: nextStatus);
      if (!mounted) return;
      setState(() => _intervention = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Statut mis à jour : ${_statusInfo(updated.status).$1}.')),
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
      if (mounted) setState(() => _savingStatus = false);
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
                  if (_intervention.latitude != null &&
                      _intervention.longitude != null)
                    _DetailRow(
                      icon: Icons.my_location_outlined,
                      label: 'Coordonnées',
                      value:
                          '${_intervention.latitude}, ${_intervention.longitude}',
                    ),
                ],
              ),
            ),
          ),
          if (nextStatus != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _savingStatus ? null : _advanceStatus,
              icon: _savingStatus
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(nextStatus.$3),
              label: Text(_savingStatus ? 'Mise à jour…' : nextStatus.$2),
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
          if (_hasText(_intervention.notes)) ...[
            const SizedBox(height: 12),
            _TextSection(
              title: 'Notes',
              text: _intervention.notes!.trim(),
              icon: Icons.notes_outlined,
            ),
          ],
        ],
      ),
    );
  }
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
