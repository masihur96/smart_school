import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../services/auth_service.dart';

final authServiceProvider = Provider((ref) => MockAuthService());

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  late final MockAuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    return AuthState();
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    final user = await _authService.login(email, password);
    
    if (user != null) {
      state = state.copyWith(user: user, isLoading: false);
    } else {
      state = state.copyWith(isLoading: false, error: 'Invalid email or password');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
