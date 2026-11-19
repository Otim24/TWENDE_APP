import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/auth/data/auth_repository.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class WalletDashboardScreen extends ConsumerStatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  ConsumerState<WalletDashboardScreen> createState() =>
      _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends ConsumerState<WalletDashboardScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final walletAsync = ref.watch(walletBalanceProvider);

    final String userName = profileAsync.maybeWhen(
      data: (data) {
        final String name = (data['full_name'] ?? '').toString().trim();
        return name.isEmpty ? 'Passenger' : name;
      },
      orElse: () => 'Passenger',
    );

    final String formattedBalance = walletAsync.maybeWhen(
      data: (data) =>
          AppTokens.formatUgx(data['balance'], includePrefix: false),
      orElse: () => '0',
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTokens.primary,
          onRefresh: () async {
            ref.invalidate(walletBalanceProvider);
            ref.invalidate(userProfileProvider);
            await ref.read(walletBalanceProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Row: Back Button + Profile + Welcome Text + Visibility Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/home');
                            }
                          },
                        ),
                        GestureDetector(
                          onTap: () => context.push('/profile'),
                          child: const CircleAvatar(
                            radius: 20,
                            backgroundColor: Color(0xFF1E1E1E),
                            child: Icon(Icons.person, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Welcome back!',
                            style: GoogleFonts.poppins(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            userName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isBalanceVisible = !_isBalanceVisible;
                        });
                      },
                      icon: Icon(
                        _isBalanceVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white70,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  'Current balance',
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                walletAsync.when(
                  data: (_) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          _isBalanceVisible ? formattedBalance : '••••••',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.bold,
                            fontFeatures: AppTokens.tabularFigures,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'UGX',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(color: AppTokens.primary),
                  ),
                  error: (error, _) => Column(
                    children: [
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: Colors.redAccent,
                          fontSize: 13,
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(walletBalanceProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildActionBtn(
                      icon: Icons.add,
                      label: 'Deposit',
                      color: AppTokens.primary,
                      onTap: () => context.push('/wallet/deposit'),
                    ),
                    const SizedBox(width: 40),
                    _buildActionBtn(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      color: const Color(0xFF1E1E1E),
                      isOutlined: true,
                      onTap: () => ref.invalidate(walletBalanceProvider),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Wallet Features',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoItem(
                  icon: Icons.flash_on_rounded,
                  title: 'Instant Bus Checkout',
                  subtitle: 'Slide to pay for any Twende trip with zero fees',
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  icon: Icons.phone_android_rounded,
                  title: 'Mobile Money Top-Up',
                  subtitle: 'Deposit funds anytime via MTN or Airtel Money',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    bool isOutlined = false,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isOutlined ? Colors.transparent : color,
              shape: BoxShape.circle,
              border:
                  isOutlined ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: isOutlined
                  ? null
                  : [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTokens.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTokens.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
