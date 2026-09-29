import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobbridge/core/services/payment_service.dart';
import 'package:jobbridge/features/company/providers/company_provider.dart';

const _packageInfo = <String, Map<String, dynamic>>{
  'job-basic':       {'title': 'Basic Job Post',        'price': 3000,  'desc': '30-day listing'},
  'job-featured':    {'title': 'Featured Job Post',     'price': 7000,  'desc': '30-day featured boost'},
  'job-premium':     {'title': 'Premium Job Post',      'price': 15000, 'desc': '60-day premium visibility'},
  'bundle-5':        {'title': '5 Job Bundle',          'price': 12000, 'desc': 'Valid for 12 months'},
  'bundle-10':       {'title': '10 Job Bundle',         'price': 20000, 'desc': 'Valid for 12 months'},
  'bundle-25':       {'title': '25 Job Bundle',         'price': 45000, 'desc': 'Valid for 12 months'},
  'sub-starter':     {'title': 'Starter Subscription',  'price': 10000, 'desc': 'Monthly, 3 active jobs'},
  'sub-business':    {'title': 'Business Subscription', 'price': 25000, 'desc': 'Monthly, 10 active jobs'},
  'verify-employer': {'title': 'Verified Employer',     'price': 10000, 'desc': 'Permanent blue badge'},
  'ad-homepage':     {'title': 'Homepage Ad Banner',    'price': 50000, 'desc': 'Monthly, top of homepage'},
  'ad-jobs':         {'title': 'Jobs Page Ad',          'price': 25000, 'desc': 'Monthly, sidebar'},
};

class CheckoutScreen extends ConsumerStatefulWidget {
  final String packageId;
  final String? jobId;

  const CheckoutScreen({
    super.key,
    required this.packageId,
    this.jobId,
  });

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _pay() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // 1. Get the current company
      final company = await ref.read(currentCompanyProvider.future);
      if (company == null) {
        setState(() {
          _error = 'Company profile not found. Please log in again.';
          _loading = false;
        });
        return;
      }

      // 2. Start the Paystack checkout flow
      final result = await PaymentService.startCheckout(
        packageId: widget.packageId,
        companyId: company['id'] as String,
        jobId: widget.jobId, // ← pass the job UUID if present
      );

      if (!result.ok) {
        setState(() {
          _error = result.error ?? 'Payment could not be started';
          _loading = false;
        });
        return;
      }

      // 3. Navigate to the "pending confirmation" screen
      if (mounted) {
        final jobParam =
            widget.jobId != null ? '&job=${widget.jobId}' : '';
        context.go(
          '/company/payment/pending'
          '?order=${result.orderId}'
          '&ref=${result.reference}'
          '$jobParam',
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Check your internet and try again.\n$e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _packageInfo[widget.packageId];

    if (info == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: Color(0xFFDC2626)),
              const SizedBox(height: 16),
              Text('Unknown package: ${widget.packageId}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/pricing'),
                child: const Text('Back to Pricing'),
              ),
            ],
          ),
        ),
      );
    }

    final price = info['price'] as int;
    final formattedPrice = price.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_outline,
                    size: 48, color: Color(0xFF2563EB)),
                const SizedBox(height: 16),
                const Text(
                  'Secure Checkout',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pay via Paystack — cards, bank transfer, USSD accepted.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),

                // ── Order Summary ──
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Summary',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        _row('Package', info['title'] as String),
                        _row('Description', info['desc'] as String),

                        // Show job reference if this is a job posting payment
                        if (widget.jobId != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.work_outline,
                                    size: 16, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Job will go live after payment',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF1E40AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '₦$formattedPrice',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Error banner ──
               if (_error != null)
  Container(
    padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: const Color(0xFFFEF2F2),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFFFECACA)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.error_outline,
                color: Color(0xFFDC2626), size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payment could not start',
                style: TextStyle(
                  color: Color(0xFF991B1B),
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _error!,
          style: const TextStyle(
            color: Color(0xFF7F1D1D),
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    ),
  ),
                const SizedBox(height: 12),

                // ── Pay button ──
                ElevatedButton.icon(
                  onPressed: _loading ? null : _pay,
                  icon: _loading
                      ? const SizedBox.shrink()
                      : const Icon(Icons.payment),
                  label: _loading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text('Pay ₦$formattedPrice'),
                ),

                const SizedBox(height: 12),

                TextButton(
                  onPressed: _loading ? null : () => context.go('/pricing'),
                  child: const Text('Cancel'),
                ),

                const SizedBox(height: 20),

                // ── Trust badges ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user,
                        size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      'Secured by Paystack',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}