// ignore_for_file: unused_import, unnecessary_import

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'supabase_service.dart';

class PaymentService {
  // ═══════════════════════════════════════════════════════════════
  // COMPANY CHECKOUT — job posts, bundles, subscriptions, ads
  // ═══════════════════════════════════════════════════════════════

  /// Kick off a Paystack checkout for a COMPANY package.
  /// Returns a [PaymentResult] with the checkout URL (already opened) and
  /// the Supabase order id/reference for polling.
  static Future<PaymentResult> startCheckout({
    required String packageId,
    required String companyId,
    String? jobId,
  }) async {
    return _startCheckout(
      packageId: packageId,
      extraBody: {
        'company_id': companyId,
        'job_id': jobId,
      },
      debugLabel: 'company',
      debugContext: 'package=$packageId, company=$companyId, job=$jobId',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // RESUME CHECKOUT — job seeker CV upgrades
  // ═══════════════════════════════════════════════════════════════

  /// Start a Paystack checkout for a RESUME upgrade.
  /// Returns a [PaymentResult] with the checkout URL (already opened) and
  /// the Supabase order id/reference for polling.
  static Future<PaymentResult> startResumeCheckout({
    required String packageId,
    required String resumeId,
  }) async {
    return _startCheckout(
      packageId: packageId,
      extraBody: {
        'resume_id': resumeId,
      },
      debugLabel: 'resume',
      debugContext: 'package=$packageId, resume=$resumeId',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // SHARED CHECKOUT LOGIC (private)
  // ═══════════════════════════════════════════════════════════════

  static Future<PaymentResult> _startCheckout({
    required String packageId,
    required Map<String, dynamic> extraBody,
    required String debugLabel,
    required String debugContext,
  }) async {
    try {
      debugPrint(
        '💳 [PaymentService] Starting $debugLabel checkout '
        '($debugContext)',
      );

      // ── 1. Call the Edge Function with a timeout ──
      final res = await SupabaseService.client.functions
          .invoke(
            'paystack-init',
            body: {
              'package_id': packageId,
              ...extraBody,
              'callback_url': '${Uri.base.origin}/#/payment/success',
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw TimeoutException(
              'Paystack request timed out. Check your internet connection.',
            ),
          );

      // ── 2. Parse the response ──
      final raw = res.data;
      Map<String, dynamic> data;

      if (raw is Map<String, dynamic>) {
        data = raw;
      } else if (raw is String) {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } else {
        debugPrint(
          '❌ [PaymentService] Unexpected response type: ${raw.runtimeType}',
        );
        return PaymentResult.failure(
          'Unexpected response from server (${raw.runtimeType}).',
        );
      }

      debugPrint('💳 [PaymentService] Response: $data');

      // ── 3. Handle function-level errors ──
      if (data['ok'] != true) {
        final errorMsg =
            data['error']?.toString() ?? 'Unknown error from server';
        debugPrint('❌ [PaymentService] Server error: $errorMsg');
        return PaymentResult.failure(errorMsg);
      }

      // ── 4. Extract checkout URL and reference ──
      final url = data['checkout_url']?.toString();
      final reference = data['reference']?.toString();
      final orderId = data['order_id']?.toString();

      if (url == null || url.isEmpty) {
        return PaymentResult.failure(
            'Server did not return a checkout URL.');
      }
      if (orderId == null || reference == null) {
        return PaymentResult.failure(
            'Server did not return order details.');
      }

      // ── 5. Open Paystack checkout in a new tab ──
      bool launched = false;
      try {
        launched = await launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        debugPrint('⚠️ [PaymentService] launchUrl threw: $e');
      }

      if (!launched) {
        // Even if the browser tab didn't open, return success so the UI
        // can offer the URL for manual click.
        debugPrint('⚠️ [PaymentService] Could not auto-open browser tab.');
      }

      return PaymentResult.success(
        reference: reference,
        orderId: orderId,
        checkoutUrl: url,
      );
    } on FunctionException catch (e) {
      debugPrint(
          '❌ [PaymentService] FunctionException: ${e.status} ${e.details}');
      final details = e.details;
      String msg = 'Payment service returned status ${e.status}.';
      if (details is Map && details['error'] != null) {
        msg = details['error'].toString();
      } else if (details is String && details.isNotEmpty) {
        msg = details;
      }
      return PaymentResult.failure(msg);
    } on TimeoutException catch (e) {
      debugPrint('❌ [PaymentService] Timeout: ${e.message}');
      return PaymentResult.failure(
        e.message ?? 'Request timed out. Please try again.',
      );
    } catch (e, st) {
      debugPrint('❌ [PaymentService] Unexpected error: $e');
      debugPrint('$st');

      final msg = e.toString();
      if (msg.contains('Failed to fetch') ||
          msg.contains('ClientException') ||
          msg.contains('SocketException') ||
          msg.contains('Connection') ||
          msg.contains('network')) {
        return PaymentResult.failure(
          'Cannot reach the payment server.\n'
          '• Check your internet connection\n'
          '• Disable VPN/ad-blocker\n'
          '• Try a different browser or network',
        );
      }
      return PaymentResult.failure(msg);
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // POLLING
  // ═══════════════════════════════════════════════════════════════

  /// Poll a COMPANY job order to see if the webhook marked it paid.
  /// Returns `true` if paid within ~60s, otherwise `false`.
  static Future<bool> verifyPayment(String orderId) async {
    return _pollOrder(
      table: 'job_orders',
      orderId: orderId,
      label: 'job',
    );
  }

  /// Poll a RESUME order to see if the webhook marked it paid.
  /// Returns `true` if paid within ~60s, otherwise `false`.
  static Future<bool> verifyResumePayment(String orderId) async {
    return _pollOrder(
      table: 'resume_orders',
      orderId: orderId,
      label: 'resume',
    );
  }

  /// Shared polling logic for both order types.
  static Future<bool> _pollOrder({
    required String table,
    required String orderId,
    required String label,
  }) async {
    for (var i = 0; i < 20; i++) {
      await Future.delayed(const Duration(seconds: 3));

      try {
        final row = await SupabaseService.client
            .from(table)
            .select('payment_status')
            .eq('id', orderId)
            .maybeSingle();

        final status = row?['payment_status']?.toString();
        if (status == 'paid') {
          debugPrint('✅ [PaymentService] $label order $orderId is PAID');
          return true;
        }
        debugPrint(
          '⏳ [PaymentService] $label order $orderId status: $status '
          '(attempt ${i + 1})',
        );
      } catch (e) {
        debugPrint('⚠️ [PaymentService] Poll error (non-fatal): $e');
      }
    }
    debugPrint(
        '⏰ [PaymentService] Payment confirmation timed out for $label order $orderId');
    return false;
  }
}

// ═══════════════════════════════════════════════════════════════════
// PAYMENT RESULT
// ═══════════════════════════════════════════════════════════════════

class PaymentResult {
  final bool ok;
  final String? reference;
  final String? orderId;
  final String? checkoutUrl;
  final String? error;

  PaymentResult._({
    required this.ok,
    this.reference,
    this.orderId,
    this.checkoutUrl,
    this.error,
  });

  factory PaymentResult.success({
    required String reference,
    required String orderId,
    required String checkoutUrl,
  }) =>
      PaymentResult._(
        ok: true,
        reference: reference,
        orderId: orderId,
        checkoutUrl: checkoutUrl,
      );

  factory PaymentResult.failure(String error) =>
      PaymentResult._(ok: false, error: error);
}