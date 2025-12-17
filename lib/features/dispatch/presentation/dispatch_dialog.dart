import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/dispatch_providers.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/exception_handler.dart';

class DispatchDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> jobOrder;

  const DispatchDialog({
    super.key,
    required this.jobOrder,
  });

  @override
  ConsumerState<DispatchDialog> createState() => _DispatchDialogState();
}

class _DispatchDialogState extends ConsumerState<DispatchDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleDispatch(String workerId, String workerName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final repository = ref.read(dispatchRepositoryProvider);
      
      // agency_id 조회 (job_order를 통해)
      final jobOrderId = widget.jobOrder['id'] as String;
      final agencyId = await repository.getAgencyIdByJobOrder(jobOrderId);
      
      if (agencyId == null) {
        throw Exception('회사 정보를 찾을 수 없습니다.');
      }

      await repository.createPlacement(
        jobOrderId: jobOrderId,
        workerId: workerId,
        agencyId: agencyId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$workerName님을 배정했습니다.'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.of(context).pop(true); // true를 반환하여 대시보드 새로고침 신호
    } catch (e) {
      if (!mounted) return;

      ExceptionHandler.showErrorSnackBar(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final site = widget.jobOrder['sites'] as Map<String, dynamic>?;
    final placements = widget.jobOrder['placements'] as List<dynamic>? ?? [];
    final acceptedCount = placements
        .where((p) {
          final placement = p as Map<String, dynamic>;
          return placement['status'] == 'accepted';
        })
        .length;
    final requiredWorkers = widget.jobOrder['required_workers'] as int? ?? 1;
    final workDate = widget.jobOrder['work_date'] as String?;
    final workType = widget.jobOrder['work_type'] as String? ?? '-';

    // 작업 날짜 파싱
    DateTime? workDateTime;
    if (workDate != null) {
      try {
        workDateTime = DateTime.parse(workDate);
      } catch (_) {
        workDateTime = null;
      }
    }

    // 가용 작업자 목록 조회 (해당 날짜에 배정되지 않은 작업자만)
    final workersAsync = workDateTime != null
        ? ref.watch(availableWorkersProvider((
            date: workDateTime,
            searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
          )))
        : const AsyncValue.loading();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 600,
        height: 700,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '작업자 배치 - ${site?['name'] ?? '현장명 없음'}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 오더 정보 요약
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '작업 날짜: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        workDate != null
                            ? DateFormat('yyyy-MM-dd')
                                .format(DateTime.parse(workDate))
                            : '-',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '직종: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(workType),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        '필요 인원: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$acceptedCount/$requiredWorkers명 배정됨',
                        style: TextStyle(
                          color: acceptedCount >= requiredWorkers
                              ? AppColors.success
                              : AppColors.warning,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 검색창
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '이름 또는 전화번호로 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // "배치 가능한 작업자" 라벨 및 통계 정보
            workersAsync.when(
              data: (result) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.people_outline,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '배치 가능한 작업자',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '총 ${result.totalWorkers}명의 작업자 중 ${result.availableCount}명이 배치 가능합니다',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.info,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '배치 가능한 작업자',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '배치 가능한 작업자',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 작업자 리스트
            Expanded(
              child: workersAsync.when(
                data: (result) {
                  final workers = result.workers;
                  if (workers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            workDateTime == null
                                ? '작업 날짜를 확인할 수 없습니다.'
                                : '배치 가능한 작업자가 없습니다.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index];
                      final workerId = worker['id'] as String;
                      final workerName = worker['name'] ?? '-';
                      final workerPhone = worker['phone'] ?? '-';

                      // 이미 배정된 작업자인지 확인
                      final isAlreadyDispatched = placements.any((p) {
                        final placement = p as Map<String, dynamic>;
                        return placement['worker_id'] == workerId &&
                            placement['status'] == 'accepted';
                      });

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            workerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(workerPhone),
                          trailing: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : isAlreadyDispatched
                                  ? const Chip(
                                      label: Text('배정됨'),
                                      backgroundColor: AppColors.success,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    )
                                  : OutlinedButton(
                                      onPressed: () => _handleDispatch(
                                        workerId,
                                        workerName,
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      child: const Text(
                                        '선택',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text(
                    '에러: $error',
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 하단 액션 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

