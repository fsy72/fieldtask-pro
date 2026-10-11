import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class InterventionLocationPanel extends StatefulWidget {
  const InterventionLocationPanel({
    required this.latitude,
    required this.longitude,
    super.key,
  });

  final double latitude;
  final double longitude;

  @override
  State<InterventionLocationPanel> createState() =>
      _InterventionLocationPanelState();
}

class _InterventionLocationPanelState extends State<InterventionLocationPanel> {
  final _mapController = MapController();
  Position? _technicianPosition;
  bool _locating = false;

  LatLng get _destination => LatLng(widget.latitude, widget.longitude);

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _locateTechnician() async {
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Activez la localisation du téléphone puis réessayez.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw StateError('L’autorisation de localisation a été refusée.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw StateError(
          'Autorisez la localisation de FieldTask Pro dans les réglages du téléphone.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() => _technicianPosition = position);
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Bad state: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  String _distanceLabel() {
    final position = _technicianPosition;
    if (position == null) return 'Position non relevée';
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.latitude,
      widget.longitude,
    );
    return meters < 1000
        ? 'À ${meters.round()} m du site'
        : 'À ${(meters / 1000).toStringAsFixed(1)} km du site';
  }

  @override
  Widget build(BuildContext context) => Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emplacement de l’intervention',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _destination,
                      initialZoom: 15,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.votreorg.fieldtask_pro',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _destination,
                            width: 46,
                            height: 46,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 44,
                            ),
                          ),
                          if (_technicianPosition case final position?)
                            Marker(
                              point: LatLng(
                                position.latitude,
                                position.longitude,
                              ),
                              width: 42,
                              height: 42,
                              child: const Icon(
                                Icons.person_pin_circle,
                                color: Colors.blue,
                                size: 38,
                              ),
                            ),
                        ],
                      ),
                      SimpleAttributionWidget(
                        source: const Text('OpenStreetMap contributors'),
                        backgroundColor: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _distanceLabel(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _locating ? null : _locateTechnician,
                    icon: _locating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.my_location),
                    label: Text(_locating ? 'Localisation…' : 'Me localiser'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}
