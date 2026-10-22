import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/services/location_helper.dart';
import '../../data/volunteer_incident_repository.dart';
import '../../models/volunteer_incident.dart';

/// Shared by volunteers and security. [isSecurity] switches the buttons:
/// volunteers can acknowledge or request backup, security can acknowledge or resolve.
/// The map shows the SOS (red pin) and the responder's live position (blue dot).
class VolunteerIncidentDetailPage extends StatefulWidget {
  const VolunteerIncidentDetailPage({
    super.key,
    required this.incident,
    required this.repository,
    this.isSecurity = false,
  });

  final VolunteerIncident incident;
  final VolunteerIncidentRepository repository;
  final bool isSecurity;

  @override
  State<VolunteerIncidentDetailPage> createState() =>
      _VolunteerIncidentDetailPageState();
}

class _VolunteerIncidentDetailPageState
    extends State<VolunteerIncidentDetailPage> {
  bool _isAcknowledging = false;
  bool _isRequestingBackup = false;
  bool _isResolving = false;

  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionSub;
  LatLng? _myPoint;
  bool _locationFailed = false;

  bool get _isClosed =>
      widget.incident.status == 'resolved' ||
      widget.incident.status == 'cancelled';

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      // LocationHelper already handles permission + service checks.
      final position = await LocationHelper.currentPosition();
      if (!mounted) return;
      _setMyPoint(LatLng(position.latitude, position.longitude), fit: true);

      _positionSub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // metres between updates
        ),
      ).listen(
        (p) {
          if (!mounted) return;
          _setMyPoint(LatLng(p.latitude, p.longitude));
        },
        onError: (_) {},
      );
    } catch (_) {
      if (mounted) setState(() => _locationFailed = true);
    }
  }

  void _setMyPoint(LatLng point, {bool fit = false}) {
    setState(() {
      _myPoint = point;
      _locationFailed = false;
    });
    if (fit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBoth());
    }
  }

  void _fitBoth() {
    final me = _myPoint;
    if (me == null || !mounted) return;
    final sos = LatLng(widget.incident.latitude, widget.incident.longitude);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([me, sos]),
          padding: const EdgeInsets.all(48),
          maxZoom: 17,
        ),
      );
    } catch (_) {
      // Map not ready yet; the button can be tapped again.
    }
  }

  String _distanceLabel(LatLng me, LatLng sos) {
    final metres = Geolocator.distanceBetween(
      me.latitude,
      me.longitude,
      sos.latitude,
      sos.longitude,
    );
    return metres >= 1000
        ? '${(metres / 1000).toStringAsFixed(1)} km'
        : '${metres.round()} m';
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _clean(Object error) => error.toString().replaceFirst('Exception: ', '');

  Future<void> _acknowledge() async {
    if (_isAcknowledging) return;
    setState(() => _isAcknowledging = true);

    try {
      await widget.repository.acknowledgeIncident(
        incidentId: widget.incident.id,
        etaMinutes: 10,
        note: widget.isSecurity
            ? 'Security responding via NeighbourShield mobile app.'
            : 'Volunteer responding via NeighbourShield mobile app.',
      );

      if (!mounted) return;
      _toast('SOS acknowledged successfully.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _toast(_clean(error));
    } finally {
      if (mounted) setState(() => _isAcknowledging = false);
    }
  }

  Future<void> _requestBackup() async {
    if (_isRequestingBackup) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.shield, size: 40, color: AppTheme.dangerColor),
        title: const Text('Request backup?'),
        content: const Text(
          'Security will be alerted with your current location and phone number.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Request backup'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isRequestingBackup = true);
    try {
      final position = await LocationHelper.currentPosition();
      await widget.repository.requestBackup(
        originalIncidentId: widget.incident.id,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;
      _toast('Backup requested. Security has been alerted.');
    } catch (error) {
      if (!mounted) return;
      _toast(_clean(error));
    } finally {
      if (mounted) setState(() => _isRequestingBackup = false);
    }
  }

  Future<void> _resolve() async {
    if (_isResolving) return;
    final note = await showDialog<String>(
      context: context,
      builder: (_) => const _ResolveDialog(),
    );
    if (note == null || !mounted) return;

    setState(() => _isResolving = true);
    try {
      await widget.repository.resolveIncident(
        incidentId: widget.incident.id,
        note: note,
      );
      if (!mounted) return;
      _toast('Incident resolved.');
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _toast(_clean(error));
    } finally {
      if (mounted) setState(() => _isResolving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final point = LatLng(incident.latitude, incident.longitude);
    final createdAt = incident.createdAt.millisecondsSinceEpoch == 0
        ? 'Unknown time'
        : incident.createdAt.toLocal().toString().split('.').first;
    final phone = incident.contactPhone.trim();
    final location = incident.locationNotes.trim();

    return Scaffold(
      appBar: AppBar(title: Text('SOS #${incident.id}')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0EF),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF1B7B2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppTheme.dangerColor,
                        size: 34,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              incident.readableType,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text('Status: ${incident.readableStatus}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE4EBE8)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: point,
                            initialZoom: 16,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.pinchZoom |
                                  InteractiveFlag.doubleTapZoom |
                                  InteractiveFlag.drag,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.neighbourshield.app',
                            ),
                            if (_myPoint != null)
                              PolylineLayer(
                                polylines: [
                                  Polyline(
                                    points: [_myPoint!, point],
                                    strokeWidth: 3,
                                    color: const Color(0x992196F3),
                                    isDotted: true,
                                  ),
                                ],
                              ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: point,
                                  width: 44,
                                  height: 44,
                                  alignment: Alignment.topCenter,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 44,
                                  ),
                                ),
                                if (_myPoint != null)
                                  Marker(
                                    point: _myPoint!,
                                    width: 32,
                                    height: 32,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 3,
                                        ),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black38,
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        Positioned(
                          right: 8,
                          top: 8,
                          child: FloatingActionButton.small(
                            heroTag: 'fit_both_${incident.id}',
                            tooltip: 'Show me and the SOS',
                            onPressed: _myPoint == null ? null : _fitBoth,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                    const Text(' SOS   ', style: TextStyle(fontSize: 12)),
                    const Icon(Icons.circle, color: Colors.blue, size: 14),
                    const Text(' You', style: TextStyle(fontSize: 12)),
                    const Spacer(),
                    Text(
                      _myPoint != null
                          ? '${_distanceLabel(_myPoint!, point)} away'
                          : _locationFailed
                              ? 'Your location is unavailable'
                              : 'Finding your location...',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'SOS location: ${incident.latitude.toStringAsFixed(6)}, '
                  '${incident.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(color: AppTheme.mutedColor, fontSize: 12),
                ),
                const SizedBox(height: 18),
                _DetailRow(label: 'Incident ID', value: '#${incident.id}'),
                _DetailRow(label: 'Reported by', value: incident.username),
                _DetailRow(
                  label: 'Phone',
                  value: phone.isEmpty ? 'Not provided' : phone,
                ),
                _DetailRow(
                  label: 'Address / unit',
                  value: location.isEmpty ? 'Not provided' : location,
                ),
                _DetailRow(label: 'Reported at', value: createdAt),
                _DetailRow(
                  label: 'Escalation level',
                  value: incident.escalationLevel.toString(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Message from resident',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  incident.message.trim().isEmpty
                      ? 'No additional message was typed.'
                      : incident.message,
                  style: const TextStyle(height: 1.45),
                ),
                const SizedBox(height: 28),
                if (!_isClosed) ...[
                  SizedBox(
                    height: 52,
                    child: FilledButton.icon(
                      onPressed: _isAcknowledging ? null : _acknowledge,
                      icon: _isAcknowledging
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.volunteer_activism),
                      label: Text(
                        _isAcknowledging ? 'Acknowledging...' : 'I will respond',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.isSecurity)
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isResolving ? null : _resolve,
                        icon: _isResolving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          _isResolving ? 'Resolving...' : 'Mark as resolved',
                        ),
                      ),
                    )
                  else
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _isRequestingBackup ? null : _requestBackup,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.dangerColor,
                          side: const BorderSide(color: AppTheme.dangerColor),
                        ),
                        icon: _isRequestingBackup
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.shield_outlined),
                        label: Text(
                          _isRequestingBackup ? 'Requesting...' : 'Request Backup',
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  const Text(
                    'Only acknowledge this SOS if you are able to respond. Your action is recorded by the server.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mutedColor, fontSize: 12),
                  ),
                ] else
                  const Text(
                    'This incident is closed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.mutedColor),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResolveDialog extends StatefulWidget {
  const _ResolveDialog();

  @override
  State<_ResolveDialog> createState() => _ResolveDialogState();
}

class _ResolveDialogState extends State<_ResolveDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Resolve incident'),
      content: TextField(
        controller: _controller,
        maxLines: 3,
        maxLength: 500,
        decoration: const InputDecoration(hintText: 'Outcome note (optional)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Resolve'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.mutedColor),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}