import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Wraps Supabase authentication with user-friendly error handling.
/// Never exposes raw PostgrestException or AuthException messages to the user.
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  User? get currentUser => _client?.auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  String get currentUserName {
    final meta = currentUser?.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      return meta['full_name'].toString();
    }
    return currentUser?.email?.split('@').first ?? '';
  }

  Session? get currentSession => _client?.auth.currentSession;

  Stream<AuthState> get authStateStream {
    try {
      return Supabase.instance.client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }

  // ── Sign Up ────────────────────────────────────────────────────────────────
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final client = _client;
    if (client == null) {
      return AuthResult.failure('Service not available. Please try again.');
    }
    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': fullName.trim()},
      );
      if (response.user != null) {
        return AuthResult.success(response.user!);
      }
      return AuthResult.failure('Registration failed. Please try again.');
    } on AuthException catch (e) {
      debugPrint('[AuthService] SignUp AuthException: ${e.message}');
      return AuthResult.failure(_friendlyAuthError(e.message));
    } catch (e) {
      debugPrint('[AuthService] SignUp error: $e');
      return AuthResult.failure('Unable to create account. Please check your connection and try again.');
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return AuthResult.failure('Service not available. Please try again.');
    }
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        return AuthResult.success(response.user!);
      }
      return AuthResult.failure('Sign in failed. Please check your credentials.');
    } on AuthException catch (e) {
      debugPrint('[AuthService] SignIn AuthException: ${e.message}');
      return AuthResult.failure(_friendlyAuthError(e.message));
    } catch (e) {
      debugPrint('[AuthService] SignIn error: $e');
      return AuthResult.failure('Unable to sign in. Please check your connection and try again.');
    }
  }

  // ── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _client?.auth.signOut();
    } catch (e) {
      debugPrint('[AuthService] SignOut error: $e');
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────
  Future<AuthResult> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      return AuthResult.failure('Service not available.');
    }
    try {
      await client.auth.resetPasswordForEmail(email.trim());
      return AuthResult.successMessage('Password reset email sent. Check your inbox.');
    } on AuthException catch (e) {
      return AuthResult.failure(_friendlyAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('Unable to send reset email. Please try again.');
    }
  }

  // ── User-friendly error translation ───────────────────────────────────────
  String _friendlyAuthError(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('invalid login') || lower.contains('invalid credentials') || lower.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (lower.contains('email not confirmed') || lower.contains('not confirmed')) {
      return 'Please verify your email before signing in. Check your inbox.';
    }
    if (lower.contains('already registered') || lower.contains('already exists')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Network error. Please check your internet connection.';
    }
    if (lower.contains('weak password') || lower.contains('password should be')) {
      return 'Password is too weak. Use at least 6 characters.';
    }
    if (lower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }
    // Fallback: don't expose raw message
    return 'Unable to complete request. Please try again.';
  }
}

// ── Result type ───────────────────────────────────────────────────────────────
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? message;
  final String? error;

  const AuthResult._({
    required this.isSuccess,
    this.user,
    this.message,
    this.error,
  });

  factory AuthResult.success(User user) => AuthResult._(isSuccess: true, user: user);
  factory AuthResult.successMessage(String msg) => AuthResult._(isSuccess: true, message: msg);
  factory AuthResult.failure(String error) => AuthResult._(isSuccess: false, error: error);
}
