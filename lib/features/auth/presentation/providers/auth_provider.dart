import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/models/user.dart';
import '../../../../core/models/api_error.dart';
import '../../../../core/utils/token_storage_service.dart';
import '../../data/repositories/auth_repository.dart';
import '../../../../core/providers/api_provider.dart';

/// Token Storage Service Provider
final tokenStorageServiceProvider = Provider<TokenStorageService>((ref) {
  return TokenStorageService();
});




/// Auth Repository Provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

/// Auth State
class AuthState {
  final User? user;
  final String? token;
  final bool isLoading;
  final ApiError? error;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    String? token,
    bool? isLoading,
    ApiError? error,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAuthenticated => user != null && token != null;
}

/// Auth State Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final ApiClient _apiClient;
  final TokenStorageService _tokenStorage;

  AuthNotifier(
    this._authRepository,
    this._apiClient,
    this._tokenStorage,
  ) : super(const AuthState());

  /// Initialize - check for stored token and auto-login
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true);

    try {
      final token = await _tokenStorage.getAccessToken();
      
      if (token != null && token.isNotEmpty) {
        // Set token in API client
        _apiClient.setAuthToken(token);
        
        // Get current user
        final response = await _authRepository.getCurrentUser();
        
        state = state.copyWith(
          user: response.user,
          token: token,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } on ApiError catch (e) {
      // Only clear if 401 Unauthorized
      if (e.statusCode == 401) {
        await _tokenStorage.clearAll();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      // Network errors etc - keep token
      state = state.copyWith(isLoading: false);
    }
  }

  /// Login
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authRepository.login(
        email: email,
        password: password,
      );

      // Set auth token in API client
      _apiClient.setAuthToken(response.accessToken);

      // Store token securely
      await _tokenStorage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
      );

      state = state.copyWith(
        user: response.user,
        token: response.accessToken,
        isLoading: false,
      );
    } on ApiError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    } catch (e) {
      // Catch all other errors (network, timeout, etc.)
      state = state.copyWith(
        isLoading: false,
        error: ApiError(message: 'Connection failed: ${e.toString().split('\n').first}', statusCode: 0),
      );
    }
  }

  /// Signup
  Future<void> signup(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authRepository.signup(
        name: name,
        email: email,
        password: password,
      );

      // Set auth token in API client
      _apiClient.setAuthToken(response.accessToken);

      // Store token securely
      await _tokenStorage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
      );

      state = state.copyWith(
        user: response.user,
        token: response.accessToken,
        isLoading: false,
      );
    } on ApiError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  /// Google Sign-In
  Future<void> googleSignIn(String idToken) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await _authRepository.googleSignIn(
        idToken: idToken,
      );

      _apiClient.setAuthToken(response.accessToken);

      await _tokenStorage.saveAuthData(
        accessToken: response.accessToken,
        refreshToken: response.refreshToken,
        userId: response.user.id,
      );

      state = state.copyWith(
        user: response.user,
        token: response.accessToken,
        isLoading: false,
      );
    } on ApiError catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e,
      );
    }
  }

  /// Logout
  Future<void> logout() async {
    await _authRepository.logout();
    await _tokenStorage.clearAll();
    state = const AuthState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }
}

/// Auth Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final tokenStorage = ref.watch(tokenStorageServiceProvider);
  return AuthNotifier(authRepository, apiClient, tokenStorage);
});

/// Auth Change Notifier - Router refreshListenable အတွက်
/// isAuthenticated ပြောင်းမှသာ notify လုပ်မယ် (loading state ပြောင်းရင် ignore)
class AuthChangeNotifier extends ChangeNotifier {
  bool _wasAuthenticated = false;

  void update(AuthState state) {
    // isAuthenticated ပြောင်းမှသာ notify လုပ်မယ်
    // loading true ဖြစ်နေရင် ignore (form rebuild မဖြစ်အောင်)
    if (state.isLoading) return;
    
    final isNowAuthenticated = state.isAuthenticated;
    if (_wasAuthenticated != isNowAuthenticated) {
      _wasAuthenticated = isNowAuthenticated;
      notifyListeners();
    }
  }
}

/// Auth Change Notifier Provider - GoRouter refreshListenable အတွက်
final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final notifier = AuthChangeNotifier();
  
  // Auth state ပြောင်းတိုင်း update လုပ်မယ်
  ref.listen<AuthState>(authProvider, (previous, next) {
    notifier.update(next);
  });
  
  return notifier;
});
