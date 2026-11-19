import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/storage/storage_service.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';
import 'package:twende_passenger_app/features/auth/data/auth_repository.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';
import 'package:twende_passenger_app/features/wallet/data/wallet_repository.dart';

class AccountScreen extends ConsumerWidget {
  final bool isStandalone;

  const AccountScreen({super.key, this.isStandalone = false});

  Future<void> _showEditNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final TextEditingController controller = TextEditingController(
      text: currentName == 'Passenger' ? '' : currentName,
    );

    final String? updatedName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTokens.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Profile Name',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter your full name',
              hintStyle: const TextStyle(color: Colors.white38),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(null),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

    if (updatedName != null && updatedName.isNotEmpty) {
      try {
        await ref.read(authRepositoryProvider).updateProfile(updatedName);
        ref.invalidate(userProfileProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile name updated'),
              backgroundColor: AppTokens.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$e'),
              backgroundColor: AppTokens.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final String displayName = profileAsync.maybeWhen(
      data: (data) {
        final String raw = (data['full_name'] ?? '').toString().trim();
        return raw.isEmpty ? 'Passenger' : raw;
      },
      orElse: () => 'Passenger',
    );
    final String displayPhone = profileAsync.maybeWhen(
      data: (data) => (data['phone'] ?? '').toString(),
      orElse: () => '',
    );

    final Widget content = SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _showEditNameDialog(context, ref, displayName),
              child: Stack(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF2C2C2C),
                    child: Icon(Icons.person, size: 50, color: Colors.white54),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTokens.primaryDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => _showEditNameDialog(context, ref, displayName),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_outlined, color: Colors.white54, size: 16),
                ],
              ),
            ),
            if (displayPhone.isNotEmpty)
              Text(
                displayPhone,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white54,
                  fontFeatures: AppTokens.tabularFigures,
                ),
              ),
            const SizedBox(height: 28),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            _buildOptionTile(
              icon: Icons.badge_outlined,
              title: 'Edit Display Name',
              onTap: () => _showEditNameDialog(context, ref, displayName),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Twende Wallet',
              onTap: () => context.push('/wallet'),
            ),
            const SizedBox(height: 12),
            _buildOptionTile(
              icon: Icons.help_outline_rounded,
              title: 'Support & Help',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Twende Support: Call 0800-TWENDE'),
                  ),
                );
              },
            ),
            const Spacer(),
            GestureDetector(
              onTap: () async {
                await ref.read(storageServiceProvider).deleteToken();
                ref.invalidate(userProfileProvider);
                ref.invalidate(walletBalanceProvider);
                ref.invalidate(myTripsProvider);
                if (context.mounted) {
                  context.go('/login');
                }
              },
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 12,
                child: Center(
                  child: Text(
                    'Logout',
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (isStandalone) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'My Account',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          centerTitle: true,
        ),
        body: content,
      );
    }

    return content;
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        borderRadius: 12,
        child: Row(
          children: [
            Icon(icon, color: Colors.white70),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white24,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
