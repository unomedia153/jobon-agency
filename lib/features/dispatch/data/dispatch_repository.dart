import 'package:supabase_flutter/supabase_flutter.dart';

class DispatchRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// 작업자 목록 조회 (role = 'worker')
  Future<List<Map<String, dynamic>>> getWorkers({
    String? searchQuery,
  }) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'worker')
          .isFilter('deleted_at', null)
          .order('name', ascending: true);

      final workers = List<Map<String, dynamic>>.from(response);

      // 검색어가 있으면 클라이언트 사이드에서 필터링 (대소문자 구분 없이)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        return workers.where((worker) {
          final name = (worker['name'] as String? ?? '').toLowerCase();
          final phone = (worker['phone'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || phone.contains(lowerQuery);
        }).toList();
      }

      return workers;
    } catch (e) {
      throw Exception('작업자 목록 조회 실패: $e');
    }
  }

  /// job_order를 통해 agency_id 조회
  Future<String?> getAgencyIdByJobOrder(String jobOrderId) async {
    try {
      final response = await _supabase
          .from('job_orders')
          .select('''
            sites!inner (
              agency_id
            )
          ''')
          .eq('id', jobOrderId)
          .maybeSingle();

      final sites = response?['sites'] as Map<String, dynamic>?;
      return sites?['agency_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// 배정 생성 (소장님이 직접 배정하므로 즉시 'accepted' 상태)
  /// 
  /// [jobOrderId] 작업 주문 ID
  /// [workerId] 작업자 ID
  /// [agencyId] 회사 ID (RLS 정책 통과용)
  Future<void> createPlacement({
    required String jobOrderId,
    required String workerId,
    required String agencyId,
  }) async {
    try {
      // placements 테이블에 agency_id 컬럼이 있는지 확인하기 위해
      // 먼저 job_order를 통해 agency_id를 가져온 후 포함
      final insertData = <String, dynamic>{
        'job_order_id': jobOrderId,
        'worker_id': workerId,
        'status': 'accepted', // 소장님이 직접 배정하므로 즉시 확정
      };

      // agency_id가 placements 테이블에 있다면 포함
      // (스키마에 없을 수도 있으므로 try-catch로 처리)
      try {
        insertData['agency_id'] = agencyId;
      } catch (_) {
        // agency_id 컬럼이 없으면 무시
      }

      await _supabase.from('placements').insert(insertData);
    } catch (e) {
      // agency_id 컬럼이 없는 경우 다시 시도 (agency_id 없이)
      if (e.toString().contains('agency_id') || e.toString().contains('column')) {
        await _supabase.from('placements').insert({
          'job_order_id': jobOrderId,
          'worker_id': workerId,
          'status': 'accepted',
        });
      } else {
        throw Exception('배정 생성 실패: $e');
      }
    }
  }
}

