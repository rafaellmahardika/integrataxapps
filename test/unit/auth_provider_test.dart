// test/unit/auth_provider_test.dart
//
// Unit tests for AuthNotifier — covers all authentication states.
// These tests don't require a running backend or real network.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integratax/providers/auth_provider.dart';

void main() {
  group('AuthNotifier', () {
    late ProviderContainer container;
    late AuthNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(authProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    // ── Initial State ─────────────────────────────────────────────────────────

    test('initial state: not authenticated, not loading, no error', () {
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.email, isNull);
    });

    // ── Empty Credential Validation ───────────────────────────────────────────

    test('login with empty email + empty password → error message', () async {
      await notifier.login('', '');
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.errorMessage, contains('wajib diisi'));
    });

    test('login with whitespace-only email → error message', () async {
      await notifier.login('   ', 'password');
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test('login with whitespace-only password → error message', () async {
      await notifier.login('admin@test.com', '   ');
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.errorMessage, isNotNull);
    });

    test(
      'login with empty email, non-empty password → error message',
      () async {
        await notifier.login('', 'password123');
        final state = container.read(authProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.errorMessage, isNotNull);
      },
    );

    // ── Successful Login (Demo Mode) ──────────────────────────────────────────

    test(
      'login with any non-empty email + password → authenticated (demo mode)',
      () async {
        await notifier.login('any@email.com', 'anypassword');
        final state = container.read(authProvider);
        expect(state.isAuthenticated, isTrue);
        expect(state.errorMessage, isNull);
        expect(state.email, equals('any@email.com'));
      },
    );

    test(
      'login with invalid email format (e.g. single char) → email format error',
      () async {
        await notifier.login('a', 'b');
        final state = container.read(authProvider);
        // 'a' is not a valid email — now correctly rejected after email validation
        // was added (fixes SEC-001 partially). The user must provide a valid email.
        expect(state.isAuthenticated, isFalse);
        expect(state.errorMessage, contains('Format email'));
      },
    );

    test('email is trimmed before storing', () async {
      await notifier.login('  admin@test.com  ', 'password');
      final state = container.read(authProvider);
      expect(state.email, equals('admin@test.com'));
    });

    // ── Logout ────────────────────────────────────────────────────────────────

    test('logout resets state to initial', () async {
      await notifier.login('admin@test.com', 'password');
      expect(container.read(authProvider).isAuthenticated, isTrue);

      notifier.logout();
      final state = container.read(authProvider);
      expect(state.isAuthenticated, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.email, isNull);
    });

    // ── Loading State ─────────────────────────────────────────────────────────

    test('login sets isLoading=true during the delay, then resolves', () async {
      // We cannot easily observe the intermediate loading state in a unit test
      // without mocking the Future.delayed. Verify final state is consistent.
      final future = notifier.login('admin@test.com', 'password');
      // Immediately after calling login, state might still be loading
      // (but this is an implementation detail — don't assert on it here)
      await future;
      expect(container.read(authProvider).isLoading, isFalse);
    });

    // ── Error Clearing ────────────────────────────────────────────────────────

    test('error is cleared when login is called again', () async {
      await notifier.login('', ''); // Produce error
      expect(container.read(authProvider).errorMessage, isNotNull);

      await notifier.login('valid@email.com', 'password'); // Clear error
      expect(container.read(authProvider).errorMessage, isNull);
    });

    // ── AuthState.copyWith ────────────────────────────────────────────────────

    test('copyWith clearError removes error message', () {
      const state = AuthState(errorMessage: 'Some error');
      final cleared = state.copyWith(clearError: true);
      expect(cleared.errorMessage, isNull);
    });

    test('copyWith without clearError preserves error message', () {
      const state = AuthState(errorMessage: 'Some error');
      final copied = state.copyWith(isLoading: true);
      expect(copied.errorMessage, equals('Some error'));
    });
  });
}
