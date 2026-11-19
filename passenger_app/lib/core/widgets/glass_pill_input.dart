import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassPillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool showCountryCode;

  const GlassPillInput({
    super.key,
    required this.controller,
    this.hintText = 'Phone Number',
    this.icon,
    this.keyboardType = TextInputType.phone,
    this.showCountryCode = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          if (showCountryCode) ...[
            const Text(
              '🇺🇬',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 8),
            Text(
              '+256',
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Container(
              height: 24,
              width: 1,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: Colors.white24,
            ),
          ],
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white30),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (icon != null) Icon(icon, color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}
