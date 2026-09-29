import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Production-grade network image widget.
/// 1. Tries direct load first (fast path)
/// 2. Falls back to Supabase image-proxy if direct load fails (CORS fix)
/// 3. Shows a skeleton while loading
/// 4. Shows a clean placeholder if both attempts fail
class SafeImage extends StatefulWidget {
  final String? url;
  final double width;
  final double height;
  final double borderRadius;
  final Widget placeholder;
  final BoxFit fit;

  const SafeImage({
    super.key,
    required this.url,
    this.width = 52,
    this.height = 52,
    this.borderRadius = 10,
    required this.placeholder,
    this.fit = BoxFit.cover,
  });

  @override
  State<SafeImage> createState() => _SafeImageState();
}

class _SafeImageState extends State<SafeImage> {
  bool _useProxy = false;
  bool _proxyFailed = false;

  String? get _proxyUrl {
    if (widget.url == null || widget.url!.isEmpty) return null;
    return '${AppConstants.supabaseUrl}/functions/v1/image-proxy'
        '?url=${Uri.encodeComponent(widget.url!)}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.url == null || widget.url!.trim().isEmpty) {
      return widget.placeholder;
    }
    if (_proxyFailed) return widget.placeholder;

    final effectiveUrl = _useProxy ? _proxyUrl! : widget.url!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.network(
        effectiveUrl,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (_, __, ___) {
          if (!_useProxy && _proxyUrl != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _useProxy = true);
            });
            return _loadingBox();
          }
          if (_useProxy) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _proxyFailed = true);
            });
          }
          return widget.placeholder;
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _loadingBox();
        },
      ),
    );
  }

  Widget _loadingBox() => Container(
        width: widget.width,
        height: widget.height,
        color: const Color(0xFFF1F5F9),
        child: const Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}