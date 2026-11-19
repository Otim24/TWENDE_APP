import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class GlassWalletCard extends ConsumerWidget {
  const GlassWalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(walletBalanceProvider);
    final String balanceLabel = walletAsync.maybeWhen(
      data: (data) => AppTokens.formatUgx(data['balance']),
      orElse: () => 'UGX 0',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    'Twende Wallet',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const Icon(
                    Icons.visibility_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                balanceLabel,
                style: GoogleFonts.spaceMono(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                  fontFeatures: AppTokens.tabularFigures,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildActionButton(
                    Icons.add_rounded,
                    'Deposit Money',
                    () => context.push('/wallet/deposit'),
                  ),
                  const SizedBox(width: 12),
                  _buildActionButton(
                    Icons.account_balance_wallet_outlined,
                    'Wallet',
                    () => context.push('/wallet'),
                  ),
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
            color: AppTokens.primaryDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
