import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/report_model.dart';
import '../../services/report_service.dart';

class ManageReportsScreen extends StatefulWidget {
  const ManageReportsScreen({super.key});

  @override
  State<ManageReportsScreen> createState() => _ManageReportsScreenState();
}

class _ManageReportsScreenState extends State<ManageReportsScreen> {
  final ReportService _reportService = ReportService();
  String _selectedFilter = 'all';

  static const _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': ReportStatus.pending, 'label': 'Pending'},
    {'key': ReportStatus.reviewed, 'label': 'Reviewed'},
    {'key': ReportStatus.resolved, 'label': 'Resolved'},
  ];

  List<ReportModel> _applyFilter(List<ReportModel> reports) {
    if (_selectedFilter == 'all') return reports;
    return reports.where((r) => r.status == _selectedFilter).toList();
  }

  // ── Status Helpers ──────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case ReportStatus.pending:
        return AppTheme.warningOrange;
      case ReportStatus.reviewed:
        return AppTheme.adminBlue;
      case ReportStatus.resolved:
        return AppTheme.safeGreen;
      default:
        return AppTheme.textLight;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case ReportStatus.pending:
        return Icons.hourglass_empty_rounded;
      case ReportStatus.reviewed:
        return Icons.visibility_rounded;
      case ReportStatus.resolved:
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline;
    }
  }

  // ── Bottom Sheet ────────────────────────────────────────

  void _showReportDetail(BuildContext context, ReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReportDetailSheet(
        report: report,
        reportService: _reportService,
        statusColor: _statusColor,
        statusIcon: _statusIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Manage Reports'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                size: 18, color: AppTheme.textPrimary),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterRow(),

          // Report List
          Expanded(
            child: StreamBuilder<List<ReportModel>>(
              stream: _reportService.getAllReports(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildSkeletonList();
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final allReports = snapshot.data ?? [];
                final filtered = _applyFilter(allReports);

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    return _ReportCard(
                      report: filtered[index],
                      statusColor: _statusColor(filtered[index].status),
                      statusIcon: _statusIcon(filtered[index].status),
                      onTap: () =>
                          _showReportDetail(context, filtered[index]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final f = _filters[index];
          final isSelected = _selectedFilter == f['key'];
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = f['key']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : [],
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textLight.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 80, color: AppTheme.textLight),
          const SizedBox(height: 16),
          Text(
            _selectedFilter == 'all'
                ? 'No Reports Yet'
                : 'No ${_selectedFilter[0].toUpperCase()}${_selectedFilter.substring(1)} Reports',
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'User-submitted reports will appear here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: AppTheme.dangerRed),
          const SizedBox(height: 12),
          Text('Error loading reports',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(error, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: 4,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _skeletonBar(width: 180, height: 14),
              const SizedBox(height: 10),
              _skeletonBar(width: double.infinity, height: 12),
              const SizedBox(height: 6),
              _skeletonBar(width: 240, height: 12),
              const Spacer(),
              _skeletonBar(width: 80, height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonBar({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.secondary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ────────────────────────────────────────────────────
//  Report Card Widget
// ────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.statusColor,
    required this.statusIcon,
    required this.onTap,
  });

  final ReportModel report;
  final Color statusColor;
  final IconData statusIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d, yyyy • h:mm a').format(report.createdAt);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title row + Status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    report.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(
                    status: report.status,
                    color: statusColor,
                    icon: statusIcon),
              ],
            ),

            const SizedBox(height: 8),

            // Description preview
            Text(
              report.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 12),

            // Meta row
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  report.userName,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textLight),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppTheme.textLight),
                const SizedBox(width: 4),
                Text(
                  dateStr,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textLight),
                ),
                const Spacer(),
                const Icon(Icons.open_in_new_rounded,
                    size: 14, color: AppTheme.textLight),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────
//  Status Badge Widget
// ────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(
      {required this.status, required this.color, required this.icon});
  final String status;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final label = status[0].toUpperCase() + status.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────
//  Report Detail Bottom Sheet
// ────────────────────────────────────────────────────

class _ReportDetailSheet extends StatefulWidget {
  const _ReportDetailSheet({
    required this.report,
    required this.reportService,
    required this.statusColor,
    required this.statusIcon,
  });

  final ReportModel report;
  final ReportService reportService;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;

  @override
  State<_ReportDetailSheet> createState() => _ReportDetailSheetState();
}

class _ReportDetailSheetState extends State<_ReportDetailSheet> {
  late String _currentStatus;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.report.status;
  }

  Future<void> _changeStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await widget.reportService.updateReportStatus(
          widget.report.reportId, newStatus);
      setState(() => _currentStatus = newStatus);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteReport() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Report'),
        content:
            const Text('Are you sure you want to permanently delete this report?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: AppTheme.dangerRed)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.reportService.deleteReport(widget.report.reportId);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy • h:mm a')
        .format(widget.report.createdAt);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            widget.report.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // Meta
          Row(
            children: [
              const Icon(Icons.person_outline,
                  size: 14, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(widget.report.userName,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded,
                  size: 14, color: AppTheme.textLight),
              const SizedBox(width: 4),
              Text(dateStr,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),

          const Divider(height: 28),

          // Full Description
          Text(
            'Description',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.report.description,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.6),
            ),
          ),

          const SizedBox(height: 20),

          // Status Selector
          Text(
            'Update Status',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          _isUpdating
              ? const Center(child: CircularProgressIndicator())
              : Row(
                  children: ReportStatus.all.map((s) {
                    final isSelected = _currentStatus == s;
                    final color = widget.statusColor(s);
                    final icon = widget.statusIcon(s);
                    final label =
                        s[0].toUpperCase() + s.substring(1);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: isSelected ? null : () => _changeStatus(s),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color.withValues(alpha: 0.15)
                                  : AppTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : AppTheme.textLight
                                        .withValues(alpha: 0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(icon,
                                    size: 18,
                                    color: isSelected
                                        ? color
                                        : AppTheme.textLight),
                                const SizedBox(height: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isSelected
                                        ? color
                                        : AppTheme.textLight,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

          const SizedBox(height: 20),

          // Delete Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _deleteReport,
              icon: const Icon(Icons.delete_outline,
                  color: AppTheme.dangerRed, size: 18),
              label: const Text('Delete Report',
                  style: TextStyle(color: AppTheme.dangerRed)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppTheme.dangerRed.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
