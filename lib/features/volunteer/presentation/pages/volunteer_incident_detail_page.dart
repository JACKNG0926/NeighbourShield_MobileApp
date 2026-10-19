import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../data/volunteer_incident_repository.dart';
import '../../models/volunteer_incident.dart';

class VolunteerIncidentDetailPage extends StatefulWidget {
  const VolunteerIncidentDetailPage({
    super.key,
    required this.incident,
    required this.repository,
  });

  final VolunteerIncident incident;
  final VolunteerIncidentRepository repository;

  @override
  State<VolunteerIncidentDetailPage> createState() =>
      _VolunteerIncidentDetailPageState();
}

class _VolunteerIncidentDetailPageState
    extends State<VolunteerIncidentDetailPage> {
  bool _isAcknowledging = false;

  Future<void> _acknowledge() async {
    if (_isAcknowledging) return;
    setState(() => _isAcknowledging = true);

    try {
      await widget.repository.acknowledgeIncident(
        incidentId: widget.incident.id,
        etaMinutes: 10,
        note: 'Volunteer responding via NeighbourShield mobile app.',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS acknowledged successfully.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _isAcknowledging = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final incident = widget.incident;
    final createdAt = incident.createdAt.millisecondsSinceEpoch == 0
        ? 'Unknown time'
        : incident.createdAt.toLocal().toString().split('.').first;

    return Scaffold(
      appBar: AppBar(title: Text('SOS #${incident.id}')),
      body: SafeArea(
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
            const SizedBox(height: 20),
            _DetailRow(label: 'Incident ID', value: '#${incident.id}'),
            _DetailRow(label: 'Reported by', value: incident.username),
            _DetailRow(label: 'Reported at', value: createdAt),
            _DetailRow(
              label: 'Escalation level',
              value: incident.escalationLevel.toString(),
            ),
            _DetailRow(
              label: 'Latitude',
              value: incident.latitude.toStringAsFixed(6),
            ),
            _DetailRow(
              label: 'Longitude',
              value: incident.longitude.toStringAsFixed(6),
            ),
            const SizedBox(height: 12),
            const Text(
              'Additional message',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              incident.message.trim().isEmpty
                  ? 'The resident did not provide an additional message.'
                  : incident.message,
              style: const TextStyle(height: 1.45),
            ),
            const SizedBox(height: 28),
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
            const SizedBox(height: 10),
            const Text(
              'Only acknowledge this SOS if you are able to respond. Your action is recorded by the server.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.mutedColor, fontSize: 12),
            ),
          ],
        ),
      ),
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
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
