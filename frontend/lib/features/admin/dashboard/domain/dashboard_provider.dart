import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/errors/exceptions.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_repository.dart';

enum DashboardLoadStatus { initial, loading, loaded, error }

class DashboardState {
  final DashboardLoadStatus status;
  final DashboardSummary? summary;
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardLoadStatus.initial,
    this.summary,
    this.errorMessage,
  });

  DashboardState copyWith({
    DashboardLoadStatus? status,
    DashboardSummary? summary,
    String? errorMessage,
    bool clearError = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final Ref ref;
  DashboardNotifier(this.ref) : super(const DashboardState());

  Future<void> load() async {
    state = state.copyWith(status: DashboardLoadStatus.loading, clearError: true);
    try {
      final repo = ref.read(dashboardRepositoryProvider);
      final summary = await repo.getSummary();
      state = state.copyWith(status: DashboardLoadStatus.loaded, summary: summary);
    } on AppException catch (e) {
      state = state.copyWith(status: DashboardLoadStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(status: DashboardLoadStatus.error, errorMessage: 'Failed to load dashboard.');
    }
  }
}

final dashboardNotifierProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier(ref);
});