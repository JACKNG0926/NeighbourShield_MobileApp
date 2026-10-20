import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../../../core/session/user_role.dart';
import '../../../home/data/incident_repository.dart';
import '../../../volunteer/data/volunteer_incident_repository.dart';
import '../../../volunteer/models/volunteer_incident.dart';
import '../../../volunteer/presentation/pages/volunteer_incident_detail_page.dart';
import '../../data/announcement_repository.dart';
import '../../models/urgent_announcement.dart';
import '../widgets/volunteer_mobilization_sheet.dart';

class UrgentAnnouncementDetailPage extends StatefulWidget {
  const UrgentAnnouncementDetailPage({
    super.key,
    required this.announcement,
    required this.session,
    this.initialRole,
  });

  final UrgentAnnouncement announcement;
  final AppSession session;
  final UserRole? initialRole;

  @override
  State<UrgentAnnouncementDetailPage> createState() =>
      _UrgentAnnouncementDetailPageState();
}

class _UrgentAnnouncementDetailPageState
    extends State<UrgentAnnouncementDetailPage> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  final IncidentRepository _incidentRepository = IncidentRepository();
  final VolunteerIncidentRepository _volunteerIncidentRepository =
      VolunteerIncidentRepository();

  late UrgentAnnouncement _announcement;
  late UserRole _activeRoleView;
  bool _isSafeCheckedIn = false;
  bool _isCheckingIn = false;
  bool _isTriggeringSos = false;
  List<VolunteerIncident> _nearbySosIncidents = [];
  bool _isLoadingIncidents = false;

  @override
  void initState() {
    super.initState();
    _announcement = widget.announcement;

    // Detect user role, default to volunteer if user has volunteer role, else resident
    final userRole = widget.initialRole ??
        widget.session.currentUser?.role ??
        UserRole.resident;
    _activeRoleView = userRole == UserRole.volunteer
        ? UserRole.volunteer
        : UserRole.resident;

    _loadStoredData();
    _markReadReceipt();
    _loadNearbySosIncidents();
  }

  Future<void> _markReadReceipt() async {
    await _repository.markAsRead(_announcement.id);
  }

  Future<void> _loadStoredData() async {
    final isSafe = await _repository.getResidentCheckInStatus(_announcement.id);
    final volunteerData =
        await _repository.getVolunteerResponse(_announcement.id);

    if (!mounted) return;
    setState(() {
      _isSafeCheckedIn = isSafe;
      if (volunteerData['status'] != null) {
        _announcement = _announcement.copyWith(
          volunteerResponseStatus: volunteerData['status'] as String?,
          volunteerEtaMinutes: volunteerData['eta'] as int?,
          volunteerNote: volunteerData['note'] as String?,
        );
      }
    });
  }

  Future<void> _loadNearbySosIncidents() async {
    setState(() => _isLoadingIncidents = true);
    try {
      final incidents = await _repository.fetchNearbyIncidents();
      if (!mounted) return;
      setState(() => _nearbySosIncidents = incidents);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoadingIncidents = false);
    }
  }

  Future<void> _handleResidentSafetyCheckIn() async {
    if (_isCheckingIn) return;
    setState(() => _isCheckingIn = true);

    try {
      final newStatus = !_isSafeCheckedIn;
      await _repository.submitResidentCheckIn(_announcement.id, isSafe: newStatus);

      if (!mounted) return;
      setState(() => _isSafeCheckedIn = newStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus
                ? 'Status updated: You are marked SAFE. Management & family notified.'
                : 'Safety check-in status cleared.',
          ),
          backgroundColor: newStatus ? Colors.green : Colors.grey.shade800,
        ),
      );
    } finally {
      if (mounted) setState(() => _isCheckingIn = false);
    }
  }

  void _openMobilizationSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VolunteerMobilizationSheet(
        announcement: _announcement,
        onSubmit: ({required etaMinutes, required note, required status}) async {
          await _repository.submitVolunteerResponse(
            announcementId: _announcement.id,
            status: status,
            etaMinutes: etaMinutes,
            note: note,
          );

          if (!mounted) return;
          setState(() {
            _announcement = _announcement.copyWith(
              volunteerResponseStatus: status,
              volunteerEtaMinutes: etaMinutes,
              volunteerNote: note,
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                status == 'responding'
                    ? 'Mobilization Confirmed! Deployment ETA: $etaMinutes mins.'
                    : 'Response status updated: $status',
              ),
              backgroundColor: status == 'responding'
                  ? Colors.green
                  : AppTheme.primaryColor,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleResidentQuickSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        icon: const Icon(
          Icons.emergency_outlined,
          color: AppTheme.dangerColor,
          size: 44,
        ),
        title: const Text('Emergency Assistance Needed?'),
        content: Text(
          'This will broadcast an immediate priority SOS alert to nearby verified volunteers and security regarding "${_announcement.title}".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('TRIGGER EMERGENCY SOS'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isTriggeringSos = true);
    try {
      final lat = _announcement.latitude ?? 3.139200;
      final lon = _announcement.longitude ?? 101.687000;
      await _incidentRepository.sendSos(lat, lon);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency SOS dispatched! Volunteer units alerted.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
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
      if (mounted) setState(() => _isTriggeringSos = false);
    }
  }

  void _showHotlineDialog(String title, String phone, String description) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.phone_in_talk, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description, style: const TextStyle(color: AppTheme.mutedColor)),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F5F3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: phone));
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Phone number copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final a = _announcement;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F7),
      appBar: AppBar(
        title: const Text('Emergency Broadcast'),
        backgroundColor: a.severityColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Share alert',
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: '${a.title}\n${a.description}'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alert details copied to clipboard!')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Severity & Urgency Alert Header
            _buildUrgencyHeader(a),

            // 2. Affected Zone Relevance Badge
            _buildRelevanceBanner(a),

            // 3. Role-Based View Switcher (Previews Resident vs Volunteer perspective)
            _buildRoleViewSwitcher(),

            // 4. Role-Specific Content Area
            if (_activeRoleView == UserRole.volunteer)
              _buildVolunteerSection(a)
            else
              _buildResidentSection(a),

            // 5. Shared Core: Action Guidelines Checklist
            _buildGuidelinesCard(a),

            // 6. Shared Core: Evacuation Geofence / Assembly Points
            _buildAssemblyPointCard(a),

            // 7. Shared Core: Live Timeline Updates Feed
            _buildTimelineFeed(a),

            // 8. Shared Core: 1-Tap Emergency Hotlines
            _buildEmergencyHotlinesBar(),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildUrgencyHeader(UrgentAnnouncement a) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            a.severityColor,
            a.severityHeaderGradientEnd,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badges row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: a.severityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${a.severityLabel} ALERT',
                      style: TextStyle(
                        color: a.severityColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.status.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                a.timeAgo,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            a.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),

          // Official Issuer info
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Issued by ${a.issuerName} (${a.issuerRole})',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelevanceBanner(UrgentAnnouncement a) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF59E0B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309), size: 22),
              const SizedBox(width: 8),
              const Text(
                'Affected Perimeter Zones',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF78350F),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB45309).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'HIGH IMPACT',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: a.affectedAreas.map((area) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  area,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF92400E),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            '⚠️ If your unit or residence is in these zones, execute emergency protocols immediately.',
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF78350F),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleViewSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EBE8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRoleButton(
              role: UserRole.resident,
              label: 'Resident View',
              icon: Icons.home_outlined,
            ),
          ),
          Expanded(
            child: _buildRoleButton(
              role: UserRole.volunteer,
              label: 'Volunteer View',
              icon: Icons.volunteer_activism_outlined,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton({
    required UserRole role,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _activeRoleView == role;
    return GestureDetector(
      onTap: () => setState(() => _activeRoleView = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? AppTheme.primaryColor : AppTheme.mutedColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.mutedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // RESIDENT ROLE SECTION
  // ==========================================
  Widget _buildResidentSection(UrgentAnnouncement a) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // "I am Safe" Check-In Action
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isSafeCheckedIn
                  ? const Color(0xFFE7F6ED)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSafeCheckedIn
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE4EBE8),
                width: _isSafeCheckedIn ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _isSafeCheckedIn
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFE8F1EE),
                      child: Icon(
                        _isSafeCheckedIn ? Icons.check : Icons.health_and_safety_outlined,
                        color: _isSafeCheckedIn ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isSafeCheckedIn
                                ? '✓ Marked Safe by Resident'
                                : 'Safety Check-in Available',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _isSafeCheckedIn
                                  ? const Color(0xFF15803D)
                                  : AppTheme.textColor,
                            ),
                          ),
                          Text(
                            _isSafeCheckedIn
                                ? 'Township Command & registered family notified.'
                                : 'Let emergency wardens know you are safe & unhurt.',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _isCheckingIn ? null : _handleResidentSafetyCheckIn,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isSafeCheckedIn
                          ? const Color(0xFF16A34A)
                          : AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isCheckingIn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            _isSafeCheckedIn
                                ? Icons.check_circle
                                : Icons.thumb_up_alt_outlined,
                            size: 18,
                          ),
                    label: Text(
                      _isSafeCheckedIn ? 'I am Safe (Checked In)' : 'I AM SAFE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // "I Need Assistance / 1-Tap SOS" Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDA4AF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.emergency_share, color: AppTheme.dangerColor, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Trapped, Injured, or Need Help?',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.dangerColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Trigger a direct rescue alert pre-tagged to this broadcast category. Responders will immediately receive your GPS coordinates.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9F1239)),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _isTriggeringSos ? null : _handleResidentQuickSos,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dangerColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: _isTriggeringSos
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.sos_outlined, size: 22),
                    label: Text(
                      _isTriggeringSos
                          ? 'Dispatching Rescue Alert...'
                          : 'I NEED ASSISTANCE / RESCUE SOS',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // VOLUNTEER ROLE SECTION
  // ==========================================
  Widget _buildVolunteerSection(UrgentAnnouncement a) {
    final status = a.volunteerResponseStatus;
    final isResponding = status == 'responding';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Volunteer Readiness & ETA Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isResponding
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFE4EBE8),
                width: isResponding ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isResponding
                            ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                            : AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isResponding
                            ? Icons.verified
                            : Icons.directions_run_outlined,
                        color: isResponding
                            ? const Color(0xFF16A34A)
                            : AppTheme.primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isResponding
                                ? 'Active Volunteer Responder'
                                : 'Volunteer Response Standby',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isResponding
                                  ? const Color(0xFF15803D)
                                  : AppTheme.textColor,
                            ),
                          ),
                          Text(
                            status == null
                                ? 'Report your availability to Township Command.'
                                : 'Status: ${status.toUpperCase()} ${a.volunteerEtaMinutes != null ? "• ETA ${a.volunteerEtaMinutes}m" : ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (a.volunteerNote != null && a.volunteerNote!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FBFA),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Note: ${a.volunteerNote}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textColor),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _openMobilizationSheet,
                    style: FilledButton.styleFrom(
                      backgroundColor: isResponding
                          ? const Color(0xFF16A34A)
                          : AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
                    label: Text(
                      status == null
                          ? 'REPORT FOR DUTY / SET ETA'
                          : 'UPDATE DEPLOYMENT STATUS / ETA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Tactical Rendezvous Point & Briefing
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Color(0xFF15803D), size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tactical Rendezvous Point',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.place, color: Color(0xFF15803D), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          a.volunteerRendezvousPoint,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF14532D),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tactical Directives for Responders:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF166534),
                  ),
                ),
                const SizedBox(height: 6),
                ...a.volunteerDirectives.map((dir) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.arrow_right,
                          color: Color(0xFF15803D),
                          size: 18,
                        ),
                        Expanded(
                          child: Text(
                            dir,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF14532D),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Active Nearby SOS Incidents in this zone
          _buildActiveNearbySosCard(),
        ],
      ),
    );
  }

  Widget _buildActiveNearbySosCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.crisis_alert, color: AppTheme.dangerColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Nearby Resident SOS Alerts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.textColor,
                  ),
                ),
              ),
              if (_isLoadingIncidents)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  '${_nearbySosIncidents.length} Pending',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.dangerColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_nearbySosIncidents.isEmpty)
            const Text(
              'No unassigned resident SOS calls in this perimeter. Monitor radio for calls.',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedColor),
            )
          else
            ..._nearbySosIncidents.take(2).map((inc) {
              return Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle, color: AppTheme.dangerColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOS #${inc.id} • ${inc.readableType}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Resident: ${inc.username} • ${inc.readableStatus}',
                            style: const TextStyle(fontSize: 11, color: AppTheme.mutedColor),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => VolunteerIncidentDetailPage(
                              incident: inc,
                              repository: _volunteerIncidentRepository,
                            ),
                          ),
                        );
                      },
                      child: const Text('Respond'),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ==========================================
  // SHARED CORE ELEMENTS
  // ==========================================
  Widget _buildGuidelinesCard(UrgentAnnouncement a) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.rule_folder_outlined, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Safety Guidelines & Protocols',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            a.description,
            style: const TextStyle(fontSize: 13, height: 1.45, color: AppTheme.textColor),
          ),
          const Divider(height: 24),
          const Text(
            'Step-by-Step Instructions:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.mutedColor,
            ),
          ),
          const SizedBox(height: 8),
          ...a.actionGuidelines.asMap().entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13, height: 1.35),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAssemblyPointCard(UrgentAnnouncement a) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.map_outlined, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                'Evacuation & Assembly Geofence',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Mini Map Visualizer Simulation
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: const Color(0xFFD6EBE4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBCE0D5)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.severityColor.withValues(alpha: 0.15),
                      border: Border.all(color: a.severityColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(a.severityIcon, color: a.severityColor, size: 28),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Perimeter ~${a.radiusMeters.toInt()}m',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'GPS: ${a.latitude?.toStringAsFixed(4)}, ${a.longitude?.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.mutedColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Nearest safe assembly shelter
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_sharp, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Designated Safe Assembly Point:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.mutedColor,
                      ),
                    ),
                    Text(
                      a.safeAssemblyPoint,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF15803D),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineFeed(UrgentAnnouncement a) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Live Incident Timeline',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F1EE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE UPDATES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...a.timelineUpdates.map((update) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: update.isImportant
                            ? a.severityColor
                            : AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: const Color(0xFFE4EBE8),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            update.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: update.isImportant
                                  ? a.severityColor
                                  : AppTheme.textColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            update.timeFormatted,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        update.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedColor,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmergencyHotlinesBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.phone_in_talk, color: AppTheme.primaryColor, size: 20),
              SizedBox(width: 8),
              Text(
                '1-Tap Emergency Hotlines',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppTheme.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildHotlineButton(
                  title: 'Guardhouse',
                  phone: '03-7890 1234',
                  icon: Icons.security,
                  color: const Color(0xFF0F766E),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHotlineButton(
                  title: 'Office',
                  phone: '03-7890 5678',
                  icon: Icons.business,
                  color: const Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHotlineButton(
                  title: 'Police 999',
                  phone: '999',
                  icon: Icons.local_police,
                  color: const Color(0xFF1D4ED8),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildHotlineButton(
                  title: 'Bomba 994',
                  phone: '994',
                  icon: Icons.local_fire_department,
                  color: AppTheme.dangerColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHotlineButton({
    required String title,
    required String phone,
    required IconData icon,
    required Color color,
  }) {
    return InkWell(
      onTap: () => _showHotlineDialog(
        title,
        phone,
        'Direct connection to township response team ($title).',
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
