import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/dashboard_providers.dart';
import 'widgets/stat_card.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/circular_progress_card.dart';
import '../../../core/constants/app_colors.dart';
import '../../dispatch/presentation/dispatch_dialog.dart';

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
                      DashboardHeader(agencyName: name, currentTab: '대시보드'),
                  loading: () =>
                      DashboardHeader(agencyName: null, currentTab: '대시보드'),
                  error: (_, __) =>
                      DashboardHeader(agencyName: null, currentTab: '대시보드'),
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
                              // 오른쪽: 현장 마감 알림 (작은 카드)
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
      elevation: 0, // 그림자 제거하여 더 플랫하고 모던하게 (필요시 1~2로 조정)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200), // 연한 테두리 추가
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. 카드 타이틀 영역 (현장 요청서)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.list_alt, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      '현장 요청서 (${DateFormat('MM.dd').format(DateTime.now())})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {}, // 전체보기 기능 연결
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    '전체 보기',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. 데이터 테이블 영역
          Expanded(
            child: jobOrdersAsync.when(
              data: (orders) {
                if (orders.isEmpty) {
                  return const Center(
                    child: Text(
                      '등록된 요청서가 없습니다.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return Theme(
                  // 테이블 헤더와 바디 사이의 가로줄 제거 (깔끔하게)
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    dividerTheme: const DividerThemeData(
                      space: 0,
                      thickness: 0,
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        // [핵심 디자인 수정 사항 적용]
                        headingRowHeight: 36.0, // 높이 절반 수준으로 축소
                        headingRowColor: WidgetStateProperty.all(
                          Colors.grey[100],
                        ), // 연한 그레이 배경
                        dataRowMinHeight: 48.0, // 데이터 행은 터치하기 좋게 유지
                        dataRowMaxHeight: 48.0,
                        horizontalMargin: 20.0, // 좌우 여백 20px
                        columnSpacing: 20.0, // 컬럼 간격 20px
                        border: TableBorder(
                          bottom: BorderSide(
                            color: Colors.grey.shade100,
                          ), // 맨 아래 얇은 선
                        ),

                        columns: const [
                          DataColumn(label: Text('현장명', style: _headerStyle)),
                          DataColumn(label: Text('날짜', style: _headerStyle)),
                          DataColumn(label: Text('직종', style: _headerStyle)),
                          DataColumn(label: Text('필요인원', style: _headerStyle)),
                          DataColumn(label: Text('배차상태', style: _headerStyle)),
                          DataColumn(label: Text('상태', style: _headerStyle)),
                          DataColumn(label: Text('액션', style: _headerStyle)),
                        ],
                        rows: orders.take(10).map((order) {
                          final site = order['sites'] as Map<String, dynamic>?;
                          final placements =
                              order['placements'] as List<dynamic>? ?? [];
                          final acceptedCount = placements
                              .where((p) => (p as Map)['status'] == 'accepted')
                              .length;
                          final totalNeeded = placements.length;

                          return DataRow(
                            cells: [
                              DataCell(
                                Text(site?['name'] ?? '-', style: _cellStyle),
                              ),
                              DataCell(
                                Text(
                                  _formatDate(order['work_date'] as String?),
                                  style: _cellStyle,
                                ),
                              ),
                              DataCell(
                                Text(
                                  order['work_type'] as String? ?? '-',
                                  style: _cellStyle,
                                ),
                              ),
                              DataCell(
                                Text('$totalNeeded명', style: _cellStyle),
                              ),
                              DataCell(
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: '$acceptedCount',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: acceptedCount == totalNeeded
                                              ? AppColors.success
                                              : AppColors.primary,
                                          fontSize: 13,
                                        ),
                                      ),
                                      TextSpan(
                                        text: '/$totalNeeded명',
                                        style: _cellStyle,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              DataCell(
                                _buildStatusChip(acceptedCount, totalNeeded),
                              ),
                              DataCell(
                                SizedBox(
                                  height: 30,
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      final result = await showDialog<bool>(
                                        context: context,
                                        builder: (context) =>
                                            DispatchDialog(jobOrder: order),
                                      );

                                      // 배정이 완료되면 대시보드 새로고침
                                      if (result == true && mounted) {
                                        ref.invalidate(activeJobOrdersProvider);
                                        ref.invalidate(
                                          dashboardControllerProvider,
                                        );
                                      }
                                    },
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                    child: const Text(
                                      '배차하기',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  // 스타일 상수 (파일 상단이나 클래스 내부에 추가)
  static const TextStyle _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.black54, // 너무 진하지 않게
  );

  static const TextStyle _cellStyle = TextStyle(
    fontSize: 13,
    color: Colors.black87,
  );

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
              '현장 마감 알림',
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
