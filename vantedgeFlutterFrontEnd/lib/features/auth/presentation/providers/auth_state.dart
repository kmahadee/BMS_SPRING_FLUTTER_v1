import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  factory AuthState.initial() {
    return const AuthState(
      status: AuthStatus.initial,
      user: null,
      errorMessage: null,
    );
  }

  factory AuthState.loading() {
    return const AuthState(
      status: AuthStatus.loading,
      user: null,
      errorMessage: null,
    );
  }

  factory AuthState.authenticated(UserEntity user) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      errorMessage: null,
    );
  }

  factory AuthState.unauthenticated([String? message]) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      user: null,
      errorMessage: message,
    );
  }

  factory AuthState.error(String message) {
    return AuthState(
      status: AuthStatus.error,
      user: null,
      errorMessage: message,
    );
  }

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;
  bool get isInitial => status == AuthStatus.initial;

  @override
  List<Object?> get props => [status, user, errorMessage];

  @override
  String toString() {
    return 'AuthState(status: $status, user: ${user?.username}, error: $errorMessage)';
  }
}