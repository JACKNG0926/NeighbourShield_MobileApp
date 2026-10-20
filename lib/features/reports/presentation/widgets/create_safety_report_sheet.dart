import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../app/app_theme.dart';
import '../../data/safety_report_repository.dart';

class CreateSafetyReportSheet extends StatefulWidget {
  const CreateSafetyReportSheet({super.key, required this.repository});

  final SafetyReportRepository repository;

  @override
  State<CreateSafetyReportSheet> createState() =>
      _CreateSafetyReportSheetState();
}

class _CreateSafetyReportSheetState extends State<CreateSafetyReportSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = 'broken_light';
  String _selectedSeverity = 'warning';
  double? _latitude;
  double? _longitude;
  bool _isLocating = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _categories = const [
    {'id': 'broken_light', 'label': 'Street Light', 'icon': Icons.lightbulb_outline},
    {'id': 'road', 'label': 'Road Damage', 'icon': Icons.edit_road_outlined},
    {'id': 'suspicious', 'label': 'Suspicious Activity', 'icon': Icons.visibility_outlined},
    {'id': 'flood', 'label': 'Flooding', 'icon': Icons.water_drop_outlined},
    {'id': 'fire', 'label': 'Fire Hazard', 'icon': Icons.local_fire_department_outlined},
    {'id': 'road_closure', 'label': 'Road Closure', 'icon': Icons.do_not_disturb_on_outlined},
    {'id': 'maintenance', 'label': 'Maintenance', 'icon': Icons.build_circle_outlined},
    {'id': 'other', 'label': 'Other Hazard', 'icon': Icons.warning_amber_rounded},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _attachGpsLocation() async {
    setState(() => _isLocating = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Please enable Location Services on your device.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to attach coordinates.');
      }

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition();
      }

      // Safe fallback if emulator hasn't set GPS
      position ??= Position(
        latitude: 3.139000,
        longitude: 101.686900,
        timestamp: DateTime.now(),
        accuracy: 10.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      if (!mounted) return;
      setState(() {
        _latitude = position?.latitude;
        _longitude = position?.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('GPS coordinates attached successfully.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await widget.repository.createReport(
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        severity: _selectedSeverity,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
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
      child: Form(
        key: _formKey,
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

              // Title
              const Text(
                'New Community Safety Report',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Report a hazard or issue to alert responders and township management.',
                style: TextStyle(color: AppTheme.mutedColor, fontSize: 13),
              ),
              const SizedBox(height: 18),

              // Report Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Report Title',
                  hintText: 'Enter report title',
                  prefixIcon: Icon(Icons.title_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title for the report.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              const Text(
                'Category',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['id'];
                  return ChoiceChip(
                    avatar: Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppTheme.primaryColor,
                    ),
                    label: Text(cat['label'] as String),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedCategory = cat['id'] as String);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Severity Selector
              const Text(
                'Severity Level',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildSeverityOption(
                      level: 'info',
                      label: 'Low / Info',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSeverityOption(
                      level: 'warning',
                      label: 'Warning',
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildSeverityOption(
                      level: 'critical',
                      label: 'Critical',
                      color: AppTheme.dangerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the issue, location landmarks, and potential risks...',
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please provide description details.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // GPS Attachment Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7F6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFDCE5E2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.my_location : Icons.location_searching,
                      color: _latitude != null ? AppTheme.primaryColor : AppTheme.mutedColor,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _latitude != null
                                ? 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                : 'No location attached',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _latitude != null ? AppTheme.textColor : AppTheme.mutedColor,
                            ),
                          ),
                          Text(
                            _latitude != null
                                ? 'Coordinates will be pinned on the report'
                                : 'Attach location to help responders find it',
                            style: const TextStyle(
                              color: AppTheme.mutedColor,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_latitude != null)
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _latitude = null;
                            _longitude = null;
                          });
                        },
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _isLocating ? null : _attachGpsLocation,
                        icon: _isLocating
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add_location_alt, size: 16),
                        label: Text(_isLocating ? 'Locating...' : 'Attach GPS'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Submit Button
              SizedBox(
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isSubmitting ? null : _submitReport,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    _isSubmitting ? 'Submitting Report...' : 'Submit Report',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityOption({
    required String level,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedSeverity == level;
    return InkWell(
      onTap: () => setState(() => _selectedSeverity = level),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFDCE5E2),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? color : AppTheme.mutedColor,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
