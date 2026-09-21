import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 32});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
            ),
            borderRadius: BorderRadius.circular(size * 0.25),
          ),
          child: Icon(Icons.work_outline,
              color: Colors.white, size: size * 0.6),
        ),
        const SizedBox(width: 10),
        Text(
          'JobBridge',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: size * 0.55,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}