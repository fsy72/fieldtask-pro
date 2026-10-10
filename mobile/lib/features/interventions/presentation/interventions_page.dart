import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../domain/entities/intervention.dart';
import '../domain/entities/intervention_load_result.dart';
import 'intervention_detail_page.dart';
import 'intervention_providers.dart';

class InterventionsPage extends ConsumerStatefulWidget {
  const InterventionsPage({super.key});

  @override
  ConsumerState<InterventionsPage> createState() => _InterventionsPageState();
}

class _InterventionsPageState extends ConsumerState<InterventionsPage> {
  final _searchController = TextEditingController();
  String? _statusFilter;
  bool _highestPriorityFirst = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final interventions = ref.watch(interventionsControllerProvider);
    final connectivity = ref.watch(connectivityStatusProvider);
    final isOnline = connectivity.value?.any(
          (result) => result != ConnectivityResult.none,
        ) ??
        false;

    ref.listen(connectivityStatusProvider, (previous, next) {
      final wasOnline = previous?.value?.any(
            (result) => result != ConnectivityResult.none,
          ) ??
          false;
      final isNowOnline = next.value?.any(
            (result) => result != ConnectivityResult.none,
          ) ??
          false;
      if (isNowOnline && (previous == null || !wasOnline)) {
        unawaited(_synchronizePendingChanges());
      }
    });

    return Column(
      children: [
        interventions.when(
          data: (result) => _ConnectionBanner(
            isOnline: isOnline,
            isFromCache: result.isFromCache,
            cacheUpdatedAt: result.cacheUpdatedAt,
          ),
          loading: () => _ConnectionBanner(
            isOnline: isOnline,
            isFromCache: false,
            cacheUpdatedAt: null,
          ),
          error: (_, _) => _ConnectionBanner(
            isOnline: isOnline,
            isFromCache: false,
            cacheUpdatedAt: null,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une intervention',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Effacer la recherche',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: _highestPriorityFirst
                        ? 'Priorité décroissante'
                        : 'Priorité croissante',
                    onPressed: () => setState(
                      () => _highestPriorityFirst = !_highestPriorityFirst,
                    ),
                    icon: Icon(_highestPriorityFirst
                        ? Icons.south
                        : Icons.north),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('Toutes', null),
                    _filterChip('En attente', 'pending'),
                    _filterChip('En cours', 'in_progress'),
                    _filterChip('Terminées', 'completed'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: interventions.when(
            data: (result) => _buildList(context, result),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _LoadError(
              message: _errorMessage(
                error,
                ref.read(apiClientProvider).baseUrl,
              ),
              onRetry: () =>
                  ref.read(interventionsControllerProvider.notifier).refresh(),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _synchronizePendingChanges() async {
    try {
      final conflicts = await ref
          .read(interventionsControllerProvider.notifier)
          .syncPendingChanges();
      if (mounted && conflicts > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$conflicts mise(s) à jour en conflit. Rechargez ces interventions avant de continuer.',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Synchronisation impossible : $error')),
        );
      }
    }
  }

  Widget _filterChip(String label, String? status) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: _statusFilter == status,
          onSelected: (_) => setState(() => _statusFilter = status),
        ),
      );

  Widget _buildList(BuildContext context, InterventionLoadResult result) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = result.interventions.where((intervention) {
      final matchesStatus =
          _statusFilter == null || intervention.status == _statusFilter;
      final searchable =
          '${intervention.client} ${intervention.address} '
                  '${intervention.description} ${intervention.equipment}'
              .toLowerCase();
      return matchesStatus && (query.isEmpty || searchable.contains(query));
    }).toList()
      ..sort((a, b) => _highestPriorityFirst
          ? b.priority.compareTo(a.priority)
          : a.priority.compareTo(b.priority));

    if (filtered.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(interventionsControllerProvider.notifier).refresh(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 72),
          children: [
            Icon(Icons.assignment_outlined,
                size: 52, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              query.isNotEmpty || _statusFilter != null
                  ? 'Aucune intervention ne correspond à ces critères.'
                  : 'Aucune intervention pour le moment.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text('Tirez vers le bas pour actualiser.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(interventionsControllerProvider.notifier).refresh(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        itemCount: filtered.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _InterventionCard(
          intervention: filtered[index],
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  InterventionDetailPage(intervention: filtered[index]),
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object error, String apiBaseUrl) {
    if (error is DioException && error.response?.statusCode == 401) {
      return 'Votre session a expiré. Déconnectez-vous puis reconnectez-vous.';
    }
    if (error is DioException && error.response?.statusCode == 404) {
      return 'Route des interventions introuvable. Vérifiez l’API à $apiBaseUrl';
    }
    if (error is DioException &&
        (error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout)) {
      return 'API inaccessible à $apiBaseUrl et aucune copie locale n’est disponible.';
    }
    if (error is DioException &&
        (error.response?.statusCode ?? 0) >= 500) {
      return 'Erreur du serveur Laravel. Consultez son terminal ou backend/storage/logs/laravel.log.';
    }
    if (kDebugMode && error is DioException) {
      final status = error.response?.statusCode;
      final payload = error.response?.data;
      final serverMessage = payload is Map<String, dynamic>
          ? payload['message']?.toString()
          : null;
      final details = serverMessage == null || serverMessage.isEmpty
          ? error.message ?? error.type.name
          : serverMessage;
      return 'Échec API${status == null ? '' : ' (HTTP $status)'} à $apiBaseUrl\n$details';
    }
    if (kDebugMode) {
      return 'Erreur ${error.runtimeType}: $error';
    }
    return 'Impossible de charger les interventions et aucune copie locale n’est disponible. Vérifiez le réseau puis réessayez.';
  }
}

class _ConnectionBanner extends StatelessWidget {
  const _ConnectionBanner({
    required this.isOnline,
    required this.isFromCache,
    required this.cacheUpdatedAt,
  });

  final bool isOnline;
  final bool isFromCache;
  final DateTime? cacheUpdatedAt;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = switch ((isOnline, isFromCache)) {
      (true, false) => (
          'Réseau détecté',
          Icons.cloud_done_outlined,
          Colors.green
        ),
      (true, true) => (
          'API indisponible · copie locale',
          Icons.cloud_off_outlined,
          Colors.orange
        ),
      (false, true) => (
          'Hors ligne · copie locale',
          Icons.cloud_off_outlined,
          Colors.orange
        ),
      _ => ('Hors ligne', Icons.cloud_off_outlined, Colors.orange),
    };

    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.09),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              isFromCache && cacheUpdatedAt != null
                  ? '$label · dernière synchro ${_formatDate(cacheUpdatedAt!)}'
                  : label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterventionCard extends StatelessWidget {
  const _InterventionCard({required this.intervention, required this.onTap});

  final Intervention intervention;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final status = _statusInfo(intervention.status);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    intervention.client,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusTag(label: status.$1, color: status.$2),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 17, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(intervention.address,
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              intervention.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _DetailLabel(
                  icon: Icons.build_outlined,
                  text: intervention.equipment,
                ),
                _DetailLabel(
                  icon: Icons.flag_outlined,
                  text: 'Priorité ${intervention.priority}/3',
                ),
                if (intervention.scheduledAt != null)
                  _DetailLabel(
                    icon: Icons.schedule_outlined,
                    text: _formatDate(intervention.scheduledAt!),
                  ),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              )),
        ),
      );
}

class _DetailLabel extends StatelessWidget {
  const _DetailLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
}

(String, Color) _statusInfo(String status) => switch (status) {
      'in_progress' => ('En cours', Colors.blue),
      'completed' => ('Terminée', Colors.green),
      _ => ('En attente', Colors.orange),
    };

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month · $hour:$minute';
}
