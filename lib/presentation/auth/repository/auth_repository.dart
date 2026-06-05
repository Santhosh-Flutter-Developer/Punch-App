// lib/data/repositories/auth_repository.dart
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:punch_app/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  // ── KIOSK LOGIN CHECK ─────────────────────────────────────
  /// Returns company_id if the given username+password match a kiosk account,
  /// otherwise returns null.
  Future<String?> checkKioskLogin(String username, String password) async {
    try {
      final result = await SupabaseService.client.rpc(
        'check_kiosk_login',
        params: {'p_username': username, 'p_password': password},
      );
      if (result != null && result.toString().isNotEmpty) {
        return result.toString();
      }
    } catch (e) {
      debugPrint('[AuthRepo] checkKioskLogin error: $e');
    }
    return null;
  }

  /// Signs in with a dedicated kiosk Supabase account
  /// so RLS policies work for kiosk queries.
  Future<void> signInKioskSession() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session != null) return; // already signed in
      await SupabaseService.client.auth.signInWithPassword(
        email: 'kiosk@srisoftwarez.com', // 👈 your dedicated kiosk email
        password: 'Admin123@', // 👈 your dedicated kiosk password
      );
    } catch (e) {
      log('signInKioskSession error: $e');
    }
  }

  // ── LOGIN ─────────────────────────────────────────────────
  Future<Map<String, dynamic>> login(
    String emailOrUsername,
    String password,
  ) async {
    String emailToUse = emailOrUsername.trim();

    // ── Username / employee-code login ───────────────────
    if (!emailToUse.contains('@')) {
      // Use SECURITY DEFINER RPC — works even before auth.uid() exists.
      // Direct table query would fail here because RLS blocks
      // unauthenticated selects on the users table.
      String? found;

      // 1. Try username column first
      try {
        final result = await SupabaseService.client.rpc(
          'get_email_by_username',
          params: {'p_username': emailToUse},
        );
        if (result != null && result.toString().isNotEmpty) {
          found = result.toString();
        }
      } catch (e) {
        debugPrint('[AuthRepo] get_email_by_username error: $e');
      }

      // 2. Fallback: try employee_code lookup
      if (found == null || found.isEmpty) {
        try {
          final result = await SupabaseService.client.rpc(
            'get_email_by_employee_code',
            params: {'p_code': emailToUse},
          );
          if (result != null && result.toString().isNotEmpty) {
            found = result.toString();
          }
        } catch (e) {
          debugPrint('[AuthRepo] get_email_by_employee_code error: $e');
        }
      }

      if (found == null || found.isEmpty) {
        throw Exception(
          'No account found for this username or employee code. Please check and try again, or log in with your email address.',
        );
      }
      emailToUse = found;
    }

    // ── Supabase Auth sign-in ────────────────────────────
    final AuthResponse res = await SupabaseService.auth.signInWithPassword(
      email: emailToUse,
      password: password,
    );
    if (res.user == null) throw Exception('Incorrect email or password. Please try again.');

    // ── Fetch full user profile with role ────────────────
    final userRow = await SupabaseService.client
        .from('users')
        .select('*, roles(*)')
        .eq('id', res.user!.id)
        .maybeSingle();

    if (userRow == null) {
      throw Exception(
        'Your user profile could not be loaded. Please contact your administrator.',
      );
    }
    return userRow;
  }

  // ── LOGOUT ────────────────────────────────────────────────
  Future<void> logout() => SupabaseService.signOut();

  // ── REGISTER COMPANY ─────────────────────────────────────
  Future<Map<String, dynamic>> registerCompany({
    required String companyName,
    required String personName,
    required String gstin,
    required String mobile,
    required String email,
    required String address,
    required String country,
    required String state,
    required String city,
    required String pincode,
    required String password,
  }) async {
    // 1. Create Supabase Auth user
    final AuthResponse authRes = await SupabaseService.auth.signUp(
      email: email,
      password: password,
    );
    if (authRes.user == null) {
      throw Exception(
        'Could not create account. '
        'This email may already be registered.',
      );
    }
    final authUserId = authRes.user!.id;

    try {
      // 2. SECURITY DEFINER RPC creates:
      //    org → company → role → permissions → user → employee → subscription
      final result = await SupabaseService.client.rpc(
        'register_company',
        params: {
          'p_auth_user_id': authUserId,
          'p_company_name': companyName,
          'p_person_name': personName,
          'p_gstin': gstin.trim().isEmpty ? null : gstin.trim(),
          'p_mobile': mobile,
          'p_email': email,
          'p_address': address,
          'p_country': country,
          'p_state': state,
          'p_city': city,
          'p_pincode': pincode,
        },
      );

      if (result is Map) return Map<String, dynamic>.from(result);
      return {'user_id': authUserId};
    } catch (e) {
      // Clean up orphaned auth user so they can retry
      await SupabaseService.auth.signOut();
      rethrow;
    }
  }

  // ── PERMISSIONS ───────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getRolePermissions(String roleId) async {
    final rows = await SupabaseService.client
        .from('role_permissions')
        .select()
        .eq('role_id', roleId);
    return rows.cast<Map<String, dynamic>>();
  }

  // ── SUBSCRIPTION ──────────────────────────────────────────
  Future<Map<String, dynamic>?> getSubscription(String companyId) async {
    return await SupabaseService.client
        .from('subscriptions')
        .select()
        .eq('company_id', companyId)
        .order('created_at', ascending: false)
        .limit(1) // ✅ only latest subscription
        .maybeSingle();
  }
}