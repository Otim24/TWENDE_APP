
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';

class GlassWalletCard extends StatelessWidget {
  const GlassWalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Slightly reduce width
      child: GlassContainer(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Twende Wallet",
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(Icons.visibility_rounded, color: Colors.white70, size: 20),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                "UGX 0.00",
                style: GoogleFonts.spaceMono( // Monospaced for financial look
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildActionButton(Icons.add_rounded, "Deposit Money", () {
                     context.push('/wallet/deposit');
                  }),
                  const SizedBox(width: 12),
                  _buildActionButton(Icons.qr_code_rounded, "Wallet Options", () {}),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF4A148C), // True Deep Purple (Purple 900)
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}
