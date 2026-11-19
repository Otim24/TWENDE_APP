import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class WalletOptionsSheet extends ConsumerStatefulWidget {
  const WalletOptionsSheet({super.key});

  @override
  ConsumerState<WalletOptionsSheet> createState() => _WalletOptionsSheetState();
}

class _WalletOptionsSheetState extends ConsumerState<WalletOptionsSheet> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletBalanceProvider);
    final String formattedBalance = walletAsync.maybeWhen(
      data: (data) => AppTokens.formatUgx(data['balance']),
      orElse: () => 'UGX 0',
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  'Wallet Balance',
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
                      _isBalanceVisible ? formattedBalance : 'UGX ••••••',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFeatures: AppTokens.tabularFigures,
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
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
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
          _buildOptionButton(
            context,
            icon: Icons.add_circle_outline_rounded,
            label: 'Deposit Money',
            onTap: () {
              Navigator.pop(context);
              context.push('/wallet/deposit');
            },
          ),
          const SizedBox(height: 16),
          _buildOptionButton(
            context,
            icon: Icons.account_balance_wallet_outlined,
            label: 'Open Wallet Dashboard',
            onTap: () {
              Navigator.pop(context);
              context.push('/wallet');
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildOptionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              AppTokens.primaryDark,
              AppTokens.primary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppTokens.primaryDark.withValues(alpha: 0.3),
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
