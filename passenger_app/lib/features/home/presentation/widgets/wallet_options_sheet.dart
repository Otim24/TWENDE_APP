import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class WalletOptionsSheet extends StatefulWidget {
  const WalletOptionsSheet({super.key});

  @override
  State<WalletOptionsSheet> createState() => _WalletOptionsSheetState();
}

class _WalletOptionsSheetState extends State<WalletOptionsSheet> {
  bool _isBalanceVisible = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.black, // Matching My Wallet button
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center, // Center the narrower buttons
        children: [
          // Handle Bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24, // Lighter for visibility on black
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Wallet Balance Display
          Center(
            child: Column(
              children: [
                Text(
                  "Wallet Balance",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isBalanceVisible ? "UGX 50,000" : "UGX ••••••",
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      child: Icon(
                        _isBalanceVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Options Grid
          
          _buildOptionButton(
            context,
            icon: Icons.settings_outlined,
            label: "Wallet Settings",
            onTap: () {
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Settings Coming Soon")),
              );
            },
          ),
          const SizedBox(height: 16),

          _buildOptionButton(
            context,
            icon: Icons.history_rounded,
            label: "Transaction History",
            onTap: () {
              Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("History Coming Soon")),
              );
            },
          ),
          const SizedBox(height: 16),

          _buildOptionButton(
            context,
            icon: Icons.add_circle_outline_rounded,
            label: "Deposit Money",
            onTap: () {
              Navigator.pop(context);
              context.push('/wallet/deposit'); 
            },
          ),
          
          const SizedBox(height: 32), 
        ],
      ),
    );
  }

  Widget _buildOptionButton(BuildContext context, {
    required IconData icon, 
    required String label, 
    required VoidCallback onTap
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        // Reduced width by adding margin
        margin: const EdgeInsets.symmetric(horizontal: 40), 
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4A148C),
              Color(0xFF7B1FA2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30), // Increased radius for pill shape
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4A148C).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
