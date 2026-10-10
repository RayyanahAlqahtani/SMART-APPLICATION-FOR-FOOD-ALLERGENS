import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../widgets/common/display_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../services/scan_service.dart';
import '../../models/scan_result_model.dart';

class HistoryScreen extends StatefulWidget {
  final bool showUnsafeOnly;

  const HistoryScreen({super.key, this.showUnsafeOnly = false});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Stream<List<ScanResultModel>> _scansStream;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUserModel != null) {
      print('HistoryScreen: Initializing stream for userId: ${authProvider.currentUserModel!.userId}');
      _scansStream = ScanService().getUserScans(authProvider.currentUserModel!.userId);
    } else {
      print('HistoryScreen: No user found, using empty stream');
      _scansStream = const Stream.empty();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: StreamBuilder<List<ScanResultModel>>(
          stream: _scansStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              print('HistoryScreen ERROR: ${snapshot.error}');
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading scans',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Details: ${snapshot.error}',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final allScans = snapshot.data ?? [];
            final history = widget.showUnsafeOnly
                ? allScans.where((scan) => !scan.isSafe).toList()
                : allScans;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      widget.showUnsafeOnly ? 'Unsafe Scans' : 'Scan History',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),

                history.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_rounded,
                                  size: 48,
                                  color: AppTheme.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                widget.showUnsafeOnly
                                    ? 'No unsafe scans found'
                                    : 'No scan history yet',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.showUnsafeOnly
                                    ? 'Great job avoiding allergens!'
                                    : 'Start scanning products to build your history',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final scan = history[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ScanResultCard(
                                  result: scan,
                                  onTap: () => Navigator.pushNamed(
                                      context, PathConstants.result,
                                      arguments: scan),
                                ),
                              );
                            },
                            childCount: history.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            );
          },
        ),
      ),
    );
  }
}
