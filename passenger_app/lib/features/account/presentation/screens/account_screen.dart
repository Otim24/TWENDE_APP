
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Profile Pic
            Stack(
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
                      color: Color(0xFF4A148C), // Purple Accent
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Name & Phone
            Text(
              "Caine",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              "+256 784 811 929",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white54,
              ),
            ),
            
            const SizedBox(height: 32),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),

            // Options
            _buildOptionTile(Icons.help_outline_rounded, "Support"),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.privacy_tip_outlined, "Privacy Policy"),
            const SizedBox(height: 16),
            _buildOptionTile(Icons.settings_outlined, "Settings"),

            const Spacer(),

            // Logout Button
            GestureDetector(
              onTap: () {
                // TODO: Logout logic
              },
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: 12,
                child: Center(
                  child: Text(
                    "Logout",
                    style: GoogleFonts.poppins(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 16),
        ],
      ),
    );
  }
}
