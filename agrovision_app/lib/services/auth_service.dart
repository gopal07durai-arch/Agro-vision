import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/app_config.dart';

/// Wraps Supabase authentication with production-grade reliability,
/// precise error diagnostics, and profile synchronization.
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
    if (meta != null && meta['full_name'] != null && meta['full_name'].toString().trim().isNotEmpty) {
      return meta['full_name'].toString().trim();
    }
    final email = currentUser?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return 'Farmer';
  }

  String get currentUserEmail => currentUser?.email ?? '';

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
      return AuthResult.failure(
        'Authentication service not initialized. Supabase configuration is missing or invalid.',
      );
    }

    final cleanEmail = email.trim();
    final cleanPass = password.trim();
    final cleanName = fullName.trim();

    if (cleanName.isEmpty) {
      return AuthResult.failure('Please enter your full name.');
    }
    if (cleanEmail.isEmpty || !cleanEmail.contains('@') || !cleanEmail.contains('.')) {
      return AuthResult.failure('Please enter a valid email address.');
    }
    if (cleanPass.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters.');
    }

    try {
      final response = await client.auth.signUp(
        email: cleanEmail,
        password: cleanPass,
        data: {'full_name': cleanName},
      ).timeout(const Duration(seconds: 25));

      final user = response.user;
      if (user != null) {
        // Try creating/updating public profile record
        try {
          await client.from('profiles').upsert({
            'id': user.id,
            'full_name': cleanName,
            'email': cleanEmail,
            'updated_at': DateTime.now().toIso8601String(),
          }).timeout(const Duration(seconds: 5));
        } catch (dbErr) {
          debugPrint('[AuthService] Profile table upsert warning (non-fatal): $dbErr');
        }

        // If email confirmation is enabled in Supabase, session is null until verified
        if (response.session == null) {
          return AuthResult.requiresVerification(
            user,
            'Account created successfully! We have sent a verification link to $cleanEmail. Please verify your email before signing in.',
          );
        }

        return AuthResult.success(user);
      }

      return AuthResult.failure('Unable to complete registration. Please try again.');
    } on AuthException catch (e) {
      debugPrint('[AuthService] SignUp AuthException: ${e.message} (code: ${e.statusCode})');
      return AuthResult.failure(_translateAuthException(e));
    } on SocketException catch (e) {
      debugPrint('[AuthService] SignUp SocketException: $e');
      return AuthResult.failure(
        'Network error: Unable to connect to Supabase server. Please check your internet connection or verify the project status.',
      );
    } on http.ClientException catch (e) {
      debugPrint('[AuthService] SignUp ClientException: $e');
      return AuthResult.failure(
        'Network connection error: Failed to reach the server. Please check your internet connection.',
      );
    } on TimeoutException {
      return AuthResult.failure('Request timed out. The server took too long to respond. Please try again.');
    } catch (e) {
      debugPrint('[AuthService] SignUp unexpected error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('host lookup') || errStr.contains('getaddrinfo') || errStr.contains('dns')) {
        return AuthResult.failure(
          'Unable to reach authentication server (${AppConfig.supabaseUrl}). Please check your internet connection.',
        );
      }
      return AuthResult.failure('Registration error: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // ── Sign In ────────────────────────────────────────────────────────────────
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      return AuthResult.failure(
        'Authentication service not initialized. Supabase configuration is missing or invalid.',
      );
    }

    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult.failure('Please enter a valid email address.');
    }
    if (cleanPass.isEmpty) {
      return AuthResult.failure('Please enter your password.');
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: cleanEmail,
        password: cleanPass,
      ).timeout(const Duration(seconds: 25));

      final user = response.user;
      if (user != null) {
        return AuthResult.success(user);
      }
      return AuthResult.failure('Sign in failed. Please check your credentials.');
    } on AuthException catch (e) {
      debugPrint('[AuthService] SignIn AuthException: ${e.message} (code: ${e.statusCode})');
      return AuthResult.failure(_translateAuthException(e));
    } on SocketException catch (e) {
      debugPrint('[AuthService] SignIn SocketException: $e');
      return AuthResult.failure(
        'Network error: Unable to connect to Supabase server. Please check your internet connection.',
      );
    } on http.ClientException catch (e) {
      debugPrint('[AuthService] SignIn ClientException: $e');
      return AuthResult.failure(
        'Network connection error: Failed to reach the server. Please check your internet connection.',
      );
    } on TimeoutException {
      return AuthResult.failure('Sign in timed out. Please check your internet connection and try again.');
    } catch (e) {
      debugPrint('[AuthService] SignIn unexpected error: $e');
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('host lookup') || errStr.contains('getaddrinfo') || errStr.contains('dns')) {
        return AuthResult.failure(
          'Unable to reach authentication server (${AppConfig.supabaseUrl}). Please check your internet connection.',
        );
      }
      return AuthResult.failure('Sign in error: ${e.toString().replaceAll('Exception:', '').trim()}');
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

  // ── Reset Password ────────────────────────────────────────────────────────
  Future<AuthResult> resetPassword(String email) async {
    final client = _client;
    if (client == null) {
      return AuthResult.failure('Authentication service not available.');
    }
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      return AuthResult.failure('Please enter a valid email address to reset password.');
    }
    try {
      await client.auth.resetPasswordForEmail(cleanEmail).timeout(const Duration(seconds: 20));
      return AuthResult.successMessage('Password reset email sent! Please check your inbox.');
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthException(e));
    } catch (e) {
      return AuthResult.failure('Unable to send password reset email. Please try again.');
    }
  }

  // ── Translate Supabase AuthException into human-friendly messages ───────────
  String _translateAuthException(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('user already registered') || msg.contains('already exists') || msg.contains('duplicate')) {
      return 'An account with this email already exists. Please sign in instead.';
    }
    if (msg.contains('email not confirmed') || msg.contains('not confirmed')) {
      return 'Please verify your email before signing in. Check your inbox for the verification link.';
    }
    if (msg.contains('invalid login credentials') || msg.contains('invalid credentials') || msg.contains('wrong password')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (msg.contains('weak password') || msg.contains('password should be at least')) {
      return 'Password is too weak. Please use at least 6 characters.';
    }
    if (msg.contains('invalid email') || msg.contains('valid email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('rate limit') || msg.contains('too many requests') || e.statusCode == '429') {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Network connection unavailable. Please check your internet connection.';
    }
    // Return the clean Supabase error message if readable, otherwise specific guidance
    if (e.message.isNotEmpty && !e.message.startsWith('{')) {
      return e.message;
    }
    return 'Authentication error (${e.statusCode ?? "400"}). Please check your details and try again.';
  }
}

// ── Result type ───────────────────────────────────────────────────────────────
class AuthResult {
  final bool isSuccess;
  final bool requiresEmailVerification;
  final User? user;
  final String? message;
  final String? error;

  const AuthResult._({
    required this.isSuccess,
    this.requiresEmailVerification = false,
    this.user,
    this.message,
    this.error,
  });

  factory AuthResult.success(User user) => AuthResult._(isSuccess: true, user: user);
  factory AuthResult.requiresVerification(User user, String msg) => AuthResult._(
        isSuccess: true,
        requiresEmailVerification: true,
        user: user,
        message: msg,
      );
  factory AuthResult.successMessage(String msg) => AuthResult._(isSuccess: true, message: msg);
  factory AuthResult.failure(String error) => AuthResult._(isSuccess: false, error: error);
}
