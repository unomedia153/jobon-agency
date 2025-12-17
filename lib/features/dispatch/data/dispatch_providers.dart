import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dispatch_repository.dart';

/// DispatchRepository Provider
final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository();
});

/// 작업자 목록 Provider
final workersListProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, searchQuery) async {
  final repository = ref.read(dispatchRepositoryProvider);
  return await repository.getWorkers(searchQuery: searchQuery);
});

