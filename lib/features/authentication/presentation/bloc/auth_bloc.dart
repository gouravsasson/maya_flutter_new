import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/auth_service.dart';
import '../../../../core/services/navigation_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/check_auth_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthUseCase checkAuthUseCase;
  final AuthService authService;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthUseCase,
    required this.authService,
  }) : super(AuthInitial()) {
    on<AppStarted>(_onAppStarted);
    on<LoginRequested>(_onLoginRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  void _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    print('🚀 App started, checking authentication...');
    emit(AuthLoading());

    // Simulate splash screen delay
    await Future.delayed(Duration(seconds: 3));

    final result = await checkAuthUseCase(NoParams());

    result.fold(
      (failure) {
        print('❌ Auth check failed: ${failure.message}');
        emit(AuthUnauthenticated());
      },
      (user) {
        if (user != null) {
          print('✅ User found: ${user.firstName} ${user.lastName}');
          authService.startTokenManagement();
          emit(AuthAuthenticated(user));
        } else {
          print('ℹ️ No user found');
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  void _onLoginRequested(LoginRequested event, Emitter<AuthState> emit) async {
    print('🔐 Login requested for: ${event.email}');
    emit(AuthLoading());

    final result = await loginUseCase(
      LoginParams(email: event.email, password: event.password),
    );

    result.fold(
      (failure) {
        print('❌ Login failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (user) {
        print('✅ Login successful: ${user.firstName} ${user.lastName}');
        authService.startTokenManagement();
        emit(AuthAuthenticated(user));
        
      },
    );
  }

  void _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    print('🚪 Logout requested');
    emit(AuthLoading());

    final result = await logoutUseCase(NoParams());

    result.fold(
      (failure) {
        print('❌ Logout failed: ${failure.message}');
        emit(AuthError(failure.message));
      },
      (_) {
        print('✅ Logout successful');
        authService.stopTokenManagement();
        emit(AuthUnauthenticated());
        NavigationService.showSnackBar('Logged out successfully');

        // GoRouter will automatically redirect to /loginSS due to redirect logic
      },
    );
  }

  void _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final result = await checkAuthUseCase(NoParams());

    result.fold((failure) => emit(AuthUnauthenticated()), (user) {
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    });
  }
}
