import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';
import 'package:twende_passenger_app/core/widgets/glass_pill_input.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class DepositScreen extends ConsumerStatefulWidget {
  const DepositScreen({super.key});

  @override
  ConsumerState<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends ConsumerState<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setAmount(String value) {
    _amountController.text = value;
    setState(() {});
  }

  Future<void> _submitDeposit() async {
    if (_isSubmitting) return;

    final int amount = AppTokens.parseUgx(_amountController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a deposit amount greater than UGX 0'),
          backgroundColor: AppTokens.danger,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(walletRepositoryProvider).deposit(
            amount: amount,
            provider: 'MOMO',
          );
      ref.invalidate(walletBalanceProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Deposited ${AppTokens.formatUgx(amount)} into your Twende Wallet!',
          ),
          backgroundColor: AppTokens.success,
        ),
      );
      context.pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppTokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Deposit Money',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Amount (UGX)',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              GlassPillInput(
                controller: _amountController,
                hintText: '30,000',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
                showCountryCode: false,
              ),
              const SizedBox(height: 28),
              Text(
                'Quick Select',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildChip('10,000'),
                  _buildChip('30,000'),
                  _buildChip('50,000'),
                  _buildChip('100,000'),
                ],
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD835),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Pay with MoMo',
                          style: GoogleFonts.poppins(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String amount) {
    return GestureDetector(
      onTap: () => _setAmount(amount),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        borderRadius: 20,
        child: Text(
          'UGX $amount',
          style: GoogleFonts.spaceMono(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFeatures: AppTokens.tabularFigures,
          ),
        ),
      ),
    );
  }
}
