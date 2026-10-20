import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../models/urgent_announcement.dart';

class VolunteerMobilizationSheet extends StatefulWidget {
  const VolunteerMobilizationSheet({
    super.key,
    required this.announcement,
    required this.onSubmit,
  });

  final UrgentAnnouncement announcement;
  final Function({
    required String status,
    required int etaMinutes,
    required String note,
  }) onSubmit;

  @override
  State<VolunteerMobilizationSheet> createState() =>
      _VolunteerMobilizationSheetState();
}

class _VolunteerMobilizationSheetState
    extends State<VolunteerMobilizationSheet> {
  String _selectedStatus = 'responding';
  int _selectedEta = 10;
  final TextEditingController _noteController = TextEditingController();
  final Set<String> _selectedEquipments = {'First-Aid Kit'};

  final List<String> _equipmentOptions = const [
    'First-Aid Kit',
    'Flashlight / Torch',
    'Traffic Wand & Whistle',
    'Walkie-Talkie',
    'AED / CPR Trained',
    'Vehicle / Transport',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.announcement.volunteerResponseStatus != null) {
      _selectedStatus = widget.announcement.volunteerResponseStatus!;
    }
    if (widget.announcement.volunteerEtaMinutes != null) {
      _selectedEta = widget.announcement.volunteerEtaMinutes!;
    }
    if (widget.announcement.volunteerNote != null) {
      _noteController.text = widget.announcement.volunteerNote!;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final noteParts = <String>[];
    if (_selectedEquipments.isNotEmpty) {
      noteParts.add('Equipped: ${_selectedEquipments.join(", ")}');
    }
    if (_noteController.text.trim().isNotEmpty) {
      noteParts.add(_noteController.text.trim());
    }

    widget.onSubmit(
      status: _selectedStatus,
      etaMinutes: _selectedEta,
      note: noteParts.join(' | '),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 16,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.volunteer_activism,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Volunteer Mobilization',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      Text(
                        'Confirm availability for Township Command',
                        style: TextStyle(fontSize: 12, color: AppTheme.mutedColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Availability Status Selector
            const Text(
              'Deployment Readiness',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    id: 'responding',
                    label: 'Can Respond',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    id: 'standby',
                    label: 'On Standby',
                    icon: Icons.hourglass_empty,
                    color: const Color(0xFFD97706),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatusCard(
                    id: 'unavailable',
                    label: 'Unavailable',
                    icon: Icons.cancel_outlined,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (_selectedStatus != 'unavailable') ...[
              // Estimated Arrival (ETA)
              const Text(
                'Estimated Arrival (ETA)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [5, 10, 15, 20, 30].map((mins) {
                    final isSelected = _selectedEta == mins;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                        label: Text('$mins mins'),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppTheme.textColor,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedEta = mins);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 18),

              // Equipment / Capabilities
              const Text(
                'Carried Equipment & Special Capabilities',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _equipmentOptions.map((item) {
                  final hasItem = _selectedEquipments.contains(item);
                  return FilterChip(
                    label: Text(item),
                    selected: hasItem,
                    selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                    checkmarkColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: hasItem ? AppTheme.primaryColor : AppTheme.textColor,
                      fontWeight: hasItem ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedEquipments.add(item);
                        } else {
                          _selectedEquipments.remove(item);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
            ],

            // Note Field
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Response Note (Optional)',
                hintText: 'e.g. Near Staircase B, have stretcher assistance',
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 22),

            // Submit Button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _handleSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: _selectedStatus == 'unavailable'
                      ? const Color(0xFF6B7280)
                      : AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: Text(
                  _selectedStatus == 'unavailable'
                      ? 'Declare Unavailable'
                      : 'Confirm Deployment Status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required String id,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedStatus == id;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = id),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFDCE5E2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: isSelected ? color : AppTheme.mutedColor),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? color : AppTheme.textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
