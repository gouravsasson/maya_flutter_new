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
    print('📊 BEFORE LOGIN: Current state = ${state.runtimeType}');

    emit(AuthLoading());
    print('📊 AFTER LOADING EMIT: Current state = ${state.runtimeType}');

    try {
      print('🚀 Calling loginUseCase...');
      final result = await loginUseCase(
        LoginParams(email: event.email, password: event.password),
      );
      print('✅ LoginUseCase completed, processing result...');

      // REMOVE THIS DELAY IF IT EXISTS!
      // await Future.delayed(Duration(seconds: 3));

      print('🔍 About to process fold result...');

      result.fold(
        (failure) {
          print('❌ FOLD FAILURE: ${failure.message}');
          print('📊 BEFORE ERROR EMIT: Current state = ${state.runtimeType}');
          emit(AuthError(failure.message));
          print('📊 AFTER ERROR EMIT: Current state = ${state.runtimeType}');
        },
        (user) {
          print('✅ FOLD SUCCESS: User received = ${user}');
          print('📊 BEFORE SUCCESS EMIT: Current state = ${state.runtimeType}');

          // This is the critical line that should emit AuthAuthenticated
          print('🎯 CRITICAL: About to emit AuthAuthenticated...');
          authService.startTokenManagement();

          emit(AuthAuthenticated(user));

          print('🎯 CRITICAL: AuthAuthenticated emitted!');
          print('📊 AFTER SUCCESS EMIT: Current state = ${state.runtimeType}');

          // Verify emit worked after a short delay
          Future.delayed(Duration(milliseconds: 100), () {
            print('🔍 VERIFICATION: State after 100ms = ${state.runtimeType}');
          });

          NavigationService.showSnackBar('Logged in successfully');
          print('✅ Login process completed successfully');
        },
      );

      print('🏁 Fold processing completed');
    } catch (e, stackTrace) {
      print('❌ EXCEPTION in _onLoginRequested: $e');
      print('📚 STACK TRACE: $stackTrace');
      emit(AuthError('Login failed: $e'));
    }
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
