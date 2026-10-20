import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../data/safety_report_repository.dart';
import '../../models/safety_report.dart';
import '../widgets/create_safety_report_sheet.dart';
import '../widgets/safety_report_detail_sheet.dart';

class CommunitySafetyReportsPage extends StatefulWidget {
  const CommunitySafetyReportsPage({super.key});

  @override
  State<CommunitySafetyReportsPage> createState() =>
      _CommunitySafetyReportsPageState();
}

class _CommunitySafetyReportsPageState
    extends State<CommunitySafetyReportsPage> {
  final SafetyReportRepository _repository = SafetyReportRepository();
  final TextEditingController _searchController = TextEditingController();

  List<SafetyReport> _reports = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReports();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final reports = await _repository.fetchReports();
      if (!mounted) return;
      setState(() {
        _reports = reports;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<SafetyReport> get _filteredReports {
    return _reports.where((r) {
      // Filter tab
      final matchesFilter = switch (_selectedFilter) {
        'open' => r.status == 'open',
        'critical' => r.severity == 'critical',
        'resolved' => r.status == 'resolved',
        'broken_light' => r.category == 'broken_light',
        'road' => r.category == 'road',
        _ => true,
      };

      if (!matchesFilter) return false;

      // Search query
      if (_searchQuery.isEmpty) return true;
      return r.title.toLowerCase().contains(_searchQuery) ||
          r.description.toLowerCase().contains(_searchQuery) ||
          r.categoryLabel.toLowerCase().contains(_searchQuery) ||
          r.authorUsername.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  void _openCreateSheet() async {
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateSafetyReportSheet(repository: _repository),
    );

    if (created == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Safety report submitted successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      _loadReports();
    }
  }

  void _openDetailSheet(SafetyReport report) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafetyReportDetailSheet(report: report),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredReports;
    final totalCount = _reports.length;
    final openCount = _reports.where((r) => r.status == 'open').length;
    final criticalCount = _reports.where((r) => r.severity == 'critical').length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Community Safety Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Resident & Volunteer Hazard Monitoring',
              style: TextStyle(fontSize: 12, color: AppTheme.mutedColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadReports,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text(
          'Report Hazard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          color: AppTheme.primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Search & Stats Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      // Search input
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search reports, hazards, or locations...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Metrics Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Total Reports',
                              count: totalCount.toString(),
                              icon: Icons.assignment_outlined,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Open Hazards',
                              count: openCount.toString(),
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFEA580C),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildMetricCard(
                              label: 'Critical',
                              count: criticalCount.toString(),
                              icon: Icons.emergency_outlined,
                              color: AppTheme.dangerColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All Reports'),
                            const SizedBox(width: 8),
                            _buildFilterChip('open', 'Open ($openCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('critical', 'Critical ($criticalCount)'),
                            const SizedBox(width: 8),
                            _buildFilterChip('broken_light', 'Street Lights'),
                            const SizedBox(width: 8),
                            _buildFilterChip('road', 'Roads'),
                            const SizedBox(width: 8),
                            _buildFilterChip('resolved', 'Resolved'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Error banner if any
              if (_errorMessage != null)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFECEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFF7C3C8)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.dangerColor),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.dangerColor),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadReports,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading indicator
              if (_isLoading && _reports.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.primaryColor),
                  ),
                )
              // Empty State
              else if (filtered.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(32),
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
                            Icons.shield_outlined,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No safety reports found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No hazards match your current filter. If you spot a community safety concern, submit a new report.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.mutedColor, height: 1.4),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: _openCreateSheet,
                          icon: const Icon(Icons.add),
                          label: const Text('Submit Safety Report'),
                        ),
                      ],
                    ),
                  ),
                )
              // List of Reports
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final report = filtered[index];
                        return _ReportCard(
                          report: report,
                          onTap: () => _openDetailSheet(report),
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EBE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const Spacer(),
              Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.mutedColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
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
        if (selected) {
          setState(() => _selectedFilter = filterKey);
        }
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onTap});

  final SafetyReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EBE8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
                // Category + Severity & Status
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: report.severityColor.withValues(alpha: 0.12),
                      child: Icon(
                        report.categoryIcon,
                        size: 20,
                        color: report.severityColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            report.categoryLabel,
                            style: TextStyle(
                              color: report.severityColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            report.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Severity pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: report.severityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.severityLabel,
                        style: TextStyle(
                          color: report.severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Description preview
                Text(
                  report.description.trim().isEmpty
                      ? 'No additional description provided.'
                      : report.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4A5552),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),

                // Footer with Author, Time, Location & Status
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 14, color: AppTheme.mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      report.authorUsername,
                      style: const TextStyle(color: AppTheme.mutedColor, fontSize: 11),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.access_time, size: 14, color: AppTheme.mutedColor),
                    const SizedBox(width: 4),
                    Text(
                      report.timeAgo,
                      style: const TextStyle(color: AppTheme.mutedColor, fontSize: 11),
                    ),
                    if (report.latitude != null && report.longitude != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primaryColor),
                      const SizedBox(width: 2),
                      const Text(
                        'GPS',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: report.statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        report.statusLabel,
                        style: TextStyle(
                          color: report.statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
