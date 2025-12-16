import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/dashboard_providers.dart';
import 'widgets/stat_card.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/circular_progress_card.dart';
import '../../../core/constants/app_colors.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(dashboardControllerProvider);
    final agencyNameAsync = ref.watch(agencyNameProvider);
    final jobOrdersAsync = ref.watch(activeJobOrdersProvider);
    final activitiesAsync = ref.watch(recentActivitiesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Row(
        children: [
          // 왼쪽 사이드바
          DashboardSidebar(currentRoute: '/admin-dashboard'),
          // 메인 콘텐츠 영역
          Expanded(
            child: Column(
              children: [
                // 상단 헤더
                agencyNameAsync.when(
                  data: (name) =>
                      DashboardHeader(agencyName: name, currentTab: '개요'),
                  loading: () =>
                      DashboardHeader(agencyName: null, currentTab: '개요'),
                  error: (_, __) =>
                      DashboardHeader(agencyName: null, currentTab: '개요'),
                ),
                // 메인 콘텐츠
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 통계 카드들 (4개)
                        statsAsync.when(
                          data: (stats) => _buildStatCards(stats),
                          loading: () => const SizedBox(
                            height: 120,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          error: (error, stack) => Text('에러: $error'),
                        ),
                        const SizedBox(height: 24),
                        // 첫 번째 행: 차트들
                        SizedBox(
                          height: 500,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 왼쪽: 현장 요청서 (해당 일) (큰 카드)
                              Expanded(
                                flex: 2,
                                child: _buildJobOrdersTable(
                                  context,
                                  jobOrdersAsync,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // 오른쪽: 실시간 알림 (작은 카드)
                              Expanded(
                                flex: 1,
                                child: _buildActivityTimeline(
                                  context,
                                  activitiesAsync,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 두 번째 행: 추가 통계 카드들
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildPlacementStatusCard(statsAsync),
                            ),
                            const SizedBox(width: 16),
                            Expanded(child: _buildWorkerStatusCard(statsAsync)),
                          ],
                        ),
                      ],
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

  Widget _buildStatCards(DashboardStats stats) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            label: '신규 주문',
            value: stats.pendingOrders,
            icon: Icons.receipt_long,
            color: AppColors.error,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: '오늘 출근',
            value: stats.todayAttendance,
            icon: Icons.check_circle,
            color: AppColors.success,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: '배차 대기',
            value: stats.pendingPlacements,
            icon: Icons.pending_actions,
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            label: '작업자 수',
            value: stats.totalWorkers,
            icon: Icons.people,
            color: AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _buildJobOrdersTable(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> jobOrdersAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '현장 요청서 (${DateFormat('yyyy-MM-dd').format(DateTime.now())})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '전체 보기',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: jobOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        '등록된 현장 요청서가 없습니다.\n오른쪽 상단의 "오더 등록" 버튼을 눌러주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minWidth: constraints.maxWidth,
                          ),
                          child: DataTable(
                            columnSpacing: 16,
                            columns: const [
                              DataColumn(
                                label: Text(
                                  '현장명',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '날짜',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '직종',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '필요인원',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '배차상태',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '상태',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DataColumn(
                                label: Text(
                                  '액션',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                            rows: orders.take(10).map((order) {
                              final site =
                                  order['sites'] as Map<String, dynamic>?;
                              final placements =
                                  order['placements'] as List<dynamic>? ?? [];
                              final acceptedCount = placements
                                  .where(
                                    (p) => (p as Map)['status'] == 'accepted',
                                  )
                                  .length;
                              final totalNeeded = placements.length;

                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      site?['name'] ?? '-',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      _formatDate(
                                        order['work_date'] as String?,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(order['work_type'] as String? ?? '-'),
                                  ),
                                  DataCell(Text('$totalNeeded명')),
                                  DataCell(
                                    Text(
                                      '$acceptedCount/$totalNeeded명',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color:
                                            acceptedCount == totalNeeded &&
                                                totalNeeded > 0
                                            ? AppColors.success
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    _buildStatusChip(
                                      acceptedCount,
                                      totalNeeded,
                                    ),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('배차 기능은 준비 중입니다.'),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.primary,
                                      ),
                                      child: const Text('배차하기'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    '에러: $error',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTimeline(
    BuildContext context,
    AsyncValue<List<Map<String, dynamic>>> activitiesAsync,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Text(
              '실시간 알림',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: activitiesAsync.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text(
                        '최근 활동이 없습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    return _buildActivityItem(activity);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    '에러: $error',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementStatusCard(AsyncValue<DashboardStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => CircularProgressCard(
        title: '배차 현황',
        value: stats.pendingPlacements,
        label: '대기 중',
        icon: Icons.pending_actions,
        color: AppColors.warning,
        legendNew: '신규: ${stats.pendingPlacements}',
      ),
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('에러: $error'),
        ),
      ),
    );
  }

  Widget _buildWorkerStatusCard(AsyncValue<DashboardStats> statsAsync) {
    return statsAsync.when(
      data: (stats) => CircularProgressCard(
        title: '작업자 현황',
        value: stats.totalWorkers,
        label: '전체',
        icon: Icons.people,
        color: AppColors.info,
        legendNew: '활성: ${stats.totalWorkers}',
      ),
      loading: () => const Card(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('에러: $error'),
        ),
      ),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> activity) {
    final timestamp = DateTime.parse(activity['timestamp'] as String);
    final timeAgo = _getTimeAgo(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['message'] as String? ?? '',
                  style: const TextStyle(fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(int accepted, int total) {
    if (accepted == total && total > 0) {
      return Chip(
        label: const Text('완료'),
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.success, fontSize: 12),
        padding: EdgeInsets.zero,
      );
    } else if (accepted > 0) {
      return Chip(
        label: const Text('진행중'),
        backgroundColor: AppColors.warning.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.warning, fontSize: 12),
        padding: EdgeInsets.zero,
      );
    } else {
      return Chip(
        label: const Text('대기'),
        backgroundColor: AppColors.error.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.error, fontSize: 12),
        padding: EdgeInsets.zero,
      );
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('yyyy-MM-dd').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return DateFormat('MM-dd HH:mm').format(timestamp);
    }
  }
}
