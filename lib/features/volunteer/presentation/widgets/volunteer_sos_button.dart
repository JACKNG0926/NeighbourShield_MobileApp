import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/services/location_helper.dart';
import '../../data/volunteer_incident_repository.dart';

/// Big red SOS button for volunteers (and security). Sends the same SOS the
/// resident app sends: current GPS position, incident type, optional message,
/// plus the phone number and unit address from the user's profile.
///
/// Place it anywhere in the volunteer / security home page:
///   VolunteerSosButton(repository: _repository, onSent: _refresh)
class VolunteerSosButton extends StatefulWidget {
  const VolunteerSosButton({
    super.key,
    required this.repository,
    this.onSent,
    this.label = 'SOS - I NEED HELP',
  });

  final VolunteerIncidentRepository repository;
  final VoidCallback? onSent;
  final String label;

  @override
  State<VolunteerSosButton> createState() => _VolunteerSosButtonState();
}

class _VolunteerSosButtonState extends State<VolunteerSosButton> {
  bool _isSending = false;

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _onPressed() async {
    if (_isSending) return;

    final form = await showDialog<_SosForm>(
      context: context,
      builder: (_) => const _SosDialog(),
    );
    if (form == null || !mounted) return;

    setState(() => _isSending = true);
    try {
      final position = await LocationHelper.currentPosition();
      await widget.repository.sendSos(
        latitude: position.latitude,
        longitude: position.longitude,
        incidentType: form.type,
        message: form.message,
      );
      if (!mounted) return;
      _toast('SOS sent. Help is on the way.');
      widget.onSent?.call();
    } catch (error) {
      if (!mounted) return;
      _toast(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppTheme.dangerColor,
          foregroundColor: Colors.white,
        ),
        onPressed: _isSending ? null : _onPressed,
        icon: _isSending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.sos, size: 28),
        label: Text(
          _isSending ? 'Sending SOS...' : widget.label,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _SosForm {
  const _SosForm(this.type, this.message);
  final String type;
  final String message;
}

class _SosDialog extends StatefulWidget {
  const _SosDialog();

  @override
  State<_SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<_SosDialog> {
  static const _types = <String, String>{
    'medical': 'Medical',
    'crime': 'Crime / security',
    'fire': 'Fire',
    'accident': 'Accident',
    'other': 'Other',
  };

  final _controller = TextEditingController();
  String _type = 'other';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.sos, size: 40, color: AppTheme.dangerColor),
      title: const Text('Send SOS?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security and nearby volunteers will get your location, '
              'phone number and address.',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final entry in _types.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _type == entry.key,
                    onSelected: (_) => setState(() => _type = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(
                hintText: 'What is happening? (optional)',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppTheme.dangerColor),
          onPressed: () =>
              Navigator.of(context).pop(_SosForm(_type, _controller.text.trim())),
          child: const Text('SEND SOS'),
        ),
      ],
    );
  }
}