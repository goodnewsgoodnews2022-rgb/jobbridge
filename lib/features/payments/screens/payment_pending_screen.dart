import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/core/services/payment_service.dart';
import 'package:jobbridge/features/company/providers/company_provider.dart';


class PaymentPendingScreen extends ConsumerStatefulWidget {
  final String orderId;
  final String reference;
  const PaymentPendingScreen({
    super.key,
    required this.orderId,
    required this.reference,
  });

  @override
  ConsumerState<PaymentPendingScreen> createState() => _State();
}

class _State extends ConsumerState<PaymentPendingScreen> {
  String _status = 'waiting';

  @override
  void initState() {
    super.initState();
    _poll();
  }

  Future<void> _poll() async {
    final paid = await PaymentService.verifyPayment(widget.orderId);
    if (!mounted) return;
    setState(() => _status = paid ? 'paid' : 'failed');

    if (paid) {
      // Refresh company data
      ref.invalidate(currentCompanyProvider);
      ref.invalidate(companyJobsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_status == 'waiting') ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text('Confirming payment…',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Please complete the payment in the Paystack tab that just opened. This page will update automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ] else if (_status == 'paid') ...[
                  const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 72),
                  const SizedBox(height: 20),
                  const Text('Payment Successful!',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text('Your purchase is now active.',
                      style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/company/dashboard'),
                    child: const Text('Go to Dashboard'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/company/jobs/create'),
                    child: const Text('Post a Job Now'),
                  ),
                ] else ...[
                  const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 72),
                  const SizedBox(height: 20),
                  const Text('Payment Not Confirmed',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(
                    'We could not confirm your payment. If you were charged, contact support with reference ${widget.reference}.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/pricing'),
                    child: const Text('Try Again'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}