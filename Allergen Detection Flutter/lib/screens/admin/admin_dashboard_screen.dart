import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/user_service.dart';
import '../../services/allergen_service.dart';
import '../../services/scan_service.dart';
import '../../models/user_model.dart';
import '../../models/allergen_model.dart';
import '../../models/scan_result_model.dart';
import '../../services/report_service.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final UserService userService = UserService();
    final AllergenService allergenService = AllergenService();
    final ScanService scanService = ScanService();
    final ReportService reportService = ReportService();

    final currentUser = FirebaseAuth.instance.currentUser;
    final displayName = currentUser?.displayName ??
        currentUser?.email?.split('@')[0] ??
        'Admin';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Dashboard',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Welcome, $displayName',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        await FirebaseAuth.instance.signOut();
                        // AuthGate will reactively navigate to login
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child:
                            const Icon(Icons.logout, color: AppTheme.dangerRed),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Stats Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<UserModel>>(
                              stream: userService.getAllUsers(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.length.toString()
                                    : '...';
                                return _buildStatCard(
                                  icon: Icons.people_rounded,
                                  title: 'Total Users',
                                  value: count,
                                  color: AppTheme.primary,
                                );
                              }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<List<ScanResultModel>>(
                              stream: scanService.getAllScans(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.length.toString()
                                    : '...';
                                return _buildStatCard(
                                  icon: Icons.qr_code_scanner_rounded,
                                  title: 'Total Scans',
                                  value: count,
                                  color: AppTheme.safeGreen,
                                );
                              }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<List<AllergenModel>>(
                              stream: allergenService.getAllAllergens(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.length.toString()
                                    : '...';
                                return _buildStatCard(
                                  icon: Icons.no_food_rounded,
                                  title: 'Allergens',
                                  value: count,
                                  color: AppTheme.warningOrange,
                                );
                              }),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: StreamBuilder<int>(
                              stream: reportService.getReportCount(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData
                                    ? snapshot.data!.toString()
                                    : '...';
                                return _buildStatCard(
                                  icon: Icons.flag_rounded,
                                  title: 'Reports',
                                  value: count,
                                  color: AppTheme.dangerRed,
                                );
                              }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Chart Section — synced with database
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Scan Activity',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 24),
                      StreamBuilder<List<ScanResultModel>>(
                        stream: scanService.getAllScans(),
                        builder: (context, snapshot) {
                          // Calculate current week boundaries (Mon-Sun)
                          final now = DateTime.now();
                          final currentWeekday = now.weekday; // 1=Mon, 7=Sun
                          final weekStart = DateTime(
                            now.year,
                            now.month,
                            now.day - (currentWeekday - 1),
                          );
                          final weekEnd = weekStart.add(const Duration(days: 7));

                          // Count scans per day of week
                          final dayCounts = List<int>.filled(7, 0);
                          if (snapshot.hasData) {
                            for (final scan in snapshot.data!) {
                              if (scan.date.isAfter(weekStart.subtract(const Duration(seconds: 1))) &&
                                  scan.date.isBefore(weekEnd)) {
                                final dayIndex = scan.date.weekday - 1; // 0=Mon, 6=Sun
                                dayCounts[dayIndex]++;
                              }
                            }
                          }

                          final maxCount = dayCounts.reduce((a, b) => a > b ? a : b);

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const AspectRatio(
                              aspectRatio: 1.7,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (maxCount == 0) {
                            return const AspectRatio(
                              aspectRatio: 1.7,
                              child: Center(
                                child: Text(
                                  'No scan data this week',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            );
                          }

                          return AspectRatio(
                            aspectRatio: 1.7,
                            child: BarChart(
                              BarChartData(
                                gridData: FlGridData(show: false),
                                borderData: FlBorderData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        const titles = [
                                          'Mon',
                                          'Tue',
                                          'Wed',
                                          'Thu',
                                          'Fri',
                                          'Sat',
                                          'Sun'
                                        ];
                                        if (value.toInt() < titles.length) {
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8),
                                            child: Text(
                                              titles[value.toInt()],
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        }
                                        return const Text('');
                                      },
                                    ),
                                  ),
                                ),
                                barGroups: List.generate(
                                  7,
                                  (i) => _makeGroupData(
                                      i, dayCounts[i].toDouble()),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Management Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Management',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    _buildManagementCard(
                      context,
                      icon: Icons.people_outline_rounded,
                      title: 'Manage Users',
                      subtitle: 'View and manage user accounts',
                      onTap: () => Navigator.pushNamed(
                          context, PathConstants.adminUsers),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      context,
                      icon: Icons.no_food_rounded,
                      title: 'Manage Allergens',
                      subtitle: 'Add or edit allergen database',
                      onTap: () => Navigator.pushNamed(
                          context, PathConstants.adminAllergens),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      context,
                      icon: Icons.flag_outlined,
                      title: 'View Reports',
                      subtitle: 'Review user-submitted reports',
                      onTap: () => Navigator.pushNamed(
                          context, PathConstants.adminReports),
                    ),
                    const SizedBox(height: 12),
                    _buildManagementCard(
                      context,
                      icon: Icons.settings_rounded,
                      title: 'System Settings',
                      subtitle: 'Configure app settings',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.secondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _makeGroupData(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: AppTheme.primaryGradient,
          width: 20,
          borderRadius: BorderRadius.circular(6),
        ),
      ],
    );
  }
}
