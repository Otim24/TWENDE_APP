
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassPillInput extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData? icon;

  const GlassPillInput({
    super.key,
    required this.controller,
    this.hintText = "Phone Number",
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(100), // Fully rounded pill
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          // Flag Placeholder (Could be an image asset or emoji)
          const Text(
            "🇺🇬",
            style: TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 8),
          
          // Prefix
          Text(
            "+256",
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          // Vertical Divider
          Container(
            height: 24,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            color: Colors.white24,
          ),
          
          // Input Field
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hintText,
                hintStyle: TextStyle(color: Colors.white30),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          
          if (icon != null) 
            Icon(icon, color: Colors.white54, size: 20),
        ],
      ),
    );
  }
}
