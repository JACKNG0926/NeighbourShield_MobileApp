import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/session/app_session.dart';
import '../../data/announcement_repository.dart';
import '../../models/urgent_announcement.dart';
import 'urgent_announcement_detail_page.dart';

class UrgentAnnouncementsListPage extends StatefulWidget {
  const UrgentAnnouncementsListPage({super.key, required this.session});

  final AppSession session;

  @override
  State<UrgentAnnouncementsListPage> createState() =>
      _UrgentAnnouncementsListPageState();
}

class _UrgentAnnouncementsListPageState
    extends State<UrgentAnnouncementsListPage> {
  final AnnouncementRepository _repository = AnnouncementRepository();
  List<UrgentAnnouncement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAnnouncements();
  }

  Future<void> _loadAnnouncements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _repository.fetchAnnouncements();
      if (!mounted) return;
      setState(() => _announcements = list);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<UrgentAnnouncement> get _filteredList {
    return _announcements.where((a) {
      if (_selectedFilter == 'critical') return a.severity == 'critical';
      if (_selectedFilter == 'active') return a.status == 'active';
      return true;
    }).toList();
  }

  void _openDetail(UrgentAnnouncement announcement) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => UrgentAnnouncementDetailPage(
          announcement: announcement,
          session: widget.session,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredList;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F6),
      appBar: AppBar(
        title: const Text('Urgent Announcements'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAnnouncements,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAnnouncements,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Official Emergency Broadcasts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Security directives, evacuations, and township emergency alerts.',
                      style: TextStyle(color: AppTheme.mutedColor, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    // Filter chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip('all', 'All Broadcasts'),
                          const SizedBox(width: 8),
                          _buildFilterChip('critical', 'Critical Only'),
                          const SizedBox(width: 8),
                          _buildFilterChip('active', 'Active Now'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppTheme.dangerColor),
                  ),
                ),
              ),

            if (_isLoading && _announcements.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                ),
              )
            else if (filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F1EE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.campaign_outlined,
                          size: 48,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No urgent broadcasts right now',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'All township sectors are operating normally.',
                        style: TextStyle(color: AppTheme.mutedColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filtered[index];
                      return _AnnouncementCard(
                        announcement: item,
                        onTap: () => _openDetail(item),
                      );
                    },
                    childCount: filtered.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = key);
      },
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement, required this.onTap});

  final UrgentAnnouncement announcement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = announcement;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: a.severity == 'critical'
              ? AppTheme.dangerColor.withValues(alpha: 0.35)
              : const Color(0xFFE4EBE8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: a.severityColor.withValues(alpha: 0.12),
                      child: Icon(a.severityIcon, color: a.severityColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${a.severityLabel} BROADCAST',
                                style: TextStyle(
                                  color: a.severityColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                a.timeAgo,
                                style: const TextStyle(
                                  color: AppTheme.mutedColor,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            a.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  a.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5552),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        a.affectedAreas.join(', '),
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.mutedColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.mutedColor),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
