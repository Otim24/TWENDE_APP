import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/auth/data/auth_repository.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;

  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendSeconds = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startCooldownTimer();
  }

  void _startCooldownTimer() {
    _countdownTimer?.cancel();
    setState(() => _resendSeconds = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _resendOtp() async {
    if (_resendSeconds > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await ref.read(authRepositoryProvider).requestOtp(phone: widget.phone);
      if (!mounted) return;
      _startCooldownTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent!'),
          backgroundColor: AppTokens.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: AppTokens.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _promptForPassengerNameIfDefault(String? currentName) async {
    final String trimmed = (currentName ?? '').trim();
    if (trimmed.isNotEmpty && trimmed.toLowerCase() != 'passenger') {
      return;
    }
    if (!mounted) return;

    final TextEditingController nameController = TextEditingController();
    final String? enteredName = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTokens.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Welcome to Twende!',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What name should appear on your bus tickets?',
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Full Name (e.g. Sarah Namukasa)',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(nameController.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (enteredName != null && enteredName.isNotEmpty) {
      try {
        await ref.read(authRepositoryProvider).updateProfile(enteredName);
      } catch (_) {}
    }
  }

  Future<void> _verifyOtp(String pin) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref.read(authRepositoryProvider).verifyOtp(
            phone: widget.phone,
            code: pin,
          );

      String? fullName = result['user_name']?.toString();
      try {
        final me = await ref.read(authRepositoryProvider).getMe();
        fullName = me['full_name']?.toString() ?? fullName;
      } catch (_) {}

      await _promptForPassengerNameIfDefault(fullName);

      ref.invalidate(userProfileProvider);
      ref.invalidate(walletBalanceProvider);

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppTokens.danger,
          ),
        );
        _pinController.clear();
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 52,
      height: 56,
      textStyle: const TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontFeatures: AppTokens.tabularFigures,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(
                Icons.mail_lock_rounded,
                size: 60,
                color: Color(0xFFFFD740),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify Number',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter code sent via SMS to ${widget.phone}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 40),
              Pinput(
                controller: _pinController,
                focusNode: _focusNode,
                length: 6,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: defaultPinTheme.copyWith(
                  decoration: defaultPinTheme.decoration!.copyWith(
                    border: Border.all(color: const Color(0xFF7C4DFF)),
                  ),
                ),
                onCompleted: _verifyOtp,
              ),
              const SizedBox(height: 36),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF7C4DFF)),
              const Spacer(),
              TextButton(
                onPressed: (_resendSeconds == 0 && !_isResending) ? _resendOtp : null,
                child: Text(
                  _isResending
                      ? 'Sending code...'
                      : _resendSeconds > 0
                          ? 'Resend Code in ${_resendSeconds}s'
                          : 'Resend Code Now',
                  style: TextStyle(
                    color: _resendSeconds == 0
                        ? const Color(0xFFFFD740)
                        : Colors.white54,
                    fontWeight: _resendSeconds == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontFeatures: AppTokens.tabularFigures,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
