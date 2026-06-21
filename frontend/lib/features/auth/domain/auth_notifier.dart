import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/providers/core_providers.dart';
import '../data/auth_repository.dart';
import 'auth_state.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  AuthNotifier(this._repository, this._tokenStorage) : super(const AuthState()) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final token = await _tokenStorage.readToken();
    final cachedUser = await _tokenStorage.readUser();
    if (token == null || cachedUser == null) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
      return;
    }
    // Optimistically trust the cached session; a 401 on first API call will
    // force logout via the ApiClient.onUnauthorized hook wired in main.dart.
    try {
      final user = await _repository.me();
      await _tokenStorage.saveUser(user.toJson());
      state = state.copyWith(status: AuthStatus.authenticated, user: user);
    } catch (_) {
      await _tokenStorage.clearAll();
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String employeeCode, String password) async {
    state = state.copyWith(status: AuthStatus.authenticating, clearError: true);
    try {
      final result = await _repository.login(employeeCode: employeeCode, password: password);
      await _tokenStorage.saveToken(result.token);
      await _tokenStorage.saveUser(result.user.toJson());
      state = state.copyWith(status: AuthStatus.authenticated, user: result.user);
    } on AppException catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: 'Login failed. Please try again.');
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // Even if the server call fails, clear local session so the user isn't stuck.
    }
    await _tokenStorage.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// Called when the API client detects a 401 on any request.
  Future<void> forceLogout() async {
    await _tokenStorage.clearAll();
    state = state.copyWith(
      status: AuthStatus.unauthenticated,
      errorMessage: 'Your session expired. Please log in again.',
    );
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final storage = ref.watch(tokenStorageProvider);
  final notifier = AuthNotifier(repo, storage);
  ref.read(apiClientProvider).onUnauthorized = () => notifier.forceLogout();
  return notifier;
});
