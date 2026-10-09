import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class WalletDashboardScreen extends StatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  State<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends State<WalletDashboardScreen> {
  bool _isBalanceVisible = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header Row (Profile and Bell) with Centered Welcome Text
              Stack(
                alignment: Alignment.center,
                children: [
                   // Profile Icon (Top Left)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => context.push('/profile'),
                      child: const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF1E1E1E), // Dark gray background
                        child: Icon(Icons.person, color: Colors.grey), // Placeholder or User Image
                      ),
                    ),
                  ),
                  
                  // Centered Welcome Text
                  Column(
                    children: [
                      Text(
                        "Welcome back!",
                        style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "Caine", // Dynamic name later
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                  
                  // Notification Bell (Top Right)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Stack(
                      children: [
                        IconButton(
                          onPressed: () {
                            // Show Notifications (Simple Dialog for now or navigate)
                            showDialog(
                              context: context, 
                              builder: (ctx) => AlertDialog(
                                backgroundColor: const Color(0xFF1E1E1E),
                                title: Text("Notifications", style: GoogleFonts.poppins(color: Colors.white)),
                                content: Text("You received a deposit of UGX 47,000.", style: GoogleFonts.poppins(color: Colors.grey)),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close"))
                                ],
                              )
                            );
                          },
                          icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                        ),
                        // Red Dot for "Functional" look
                        Positioned(
                          right: 12,
                          top: 10,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Balance Section
              Text(
                "Current balance",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _isBalanceVisible ? "14,890" : "••••••", // Mock data
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isBalanceVisible)
                    Text(
                      ".00",
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    "UGX",
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),

              // Action Buttons - Refined as per user request
              // "Deposit" replaces "Send". Color Purple.
              Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center the buttons
                children: [
                  // Deposit Button (Renamed from Send, styled Purple)
                  _buildActionBtn(
                    icon: Icons.add, 
                    label: "Deposit", 
                    color: const Color(0xFF7B1FA2), // Purple to match the app theme
                    onTap: () => context.push('/wallet/deposit'),
                  ),
                  
                  const SizedBox(width: 40), // Gap
                  
                  // Keeping "Send" or just having one?
                  // User said: "instead of having a send button make it a deposit button and remove the other deposit button"
                  // So we basically have just "Deposit" now? Or do we keep "Send" as the second option?
                  // "Change the color from green to purple".
                  // "Remove the qr code scanner".
                  // Let's add a "Withdraw" or "Send" just to keep balance? Or just Deposit?
                  // User said "remove the other deposit button". 
                  // I will add "Send" (feature coming soon) as a secondary button just to keep the row balanced, 
                  // or just center the single Deposit button if that's what is implied.
                  // "instead of having a send button make it a deposit button [first button] and remove the other deposit button [third button]".
                  // So we are left with the First Button (now Deposit) and the Second Button (Scan - to be removed).
                  // So likely just ONE button? Or maybe "History"? 
                   _buildActionBtn(
                    icon: Icons.history, 
                    label: "History", 
                    color: const Color(0xFF1E1E1E), // Dark
                    isOutlined: true,
                    onTap: () {
                       // context.push('/wallet/history'); // Future
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("History Full View Coming Soon")));
                    }
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Recents Section
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Recents",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildRecentAvatar("Add", isAdd: true),
                    _buildRecentAvatar("Lucy"),
                    _buildRecentAvatar("Jake"),
                    _buildRecentAvatar("Alex"),
                    _buildRecentAvatar("Den"),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Transactions Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Transactions",
                    style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "More",
                    style: GoogleFonts.poppins(color: const Color(0xFF7B1FA2), fontSize: 14), // Purple text
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
               // Notification bell "deposit" should show up here
              _buildTransactionItem(
                icon: Icons.arrow_downward, 
                title: "Deposit", 
                subtitle: "Just now", 
                amount: "+47,000", 
                isNegative: false
              ),
              const SizedBox(height: 12),
              _buildTransactionItem(
                icon: Icons.directions_bus, 
                title: "Twende Bus", 
                subtitle: "Yesterday", 
                amount: "-37,000", 
                isNegative: true
              ),
               const SizedBox(height: 12),
              _buildTransactionItem(
                icon: Icons.shopping_bag_outlined, 
                title: "Snacks", 
                subtitle: "2 days ago", 
                amount: "-5,000", 
                isNegative: true
              ),
            ],
          ),
        ),
      ),
      // Removed BottomNavigationBar
    );
  }

  Widget _buildActionBtn({required IconData icon, required String label, required Color color, bool isOutlined = false, required VoidCallback onTap}) {
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
              border: isOutlined ? Border.all(color: Colors.white, width: 2) : null,
              boxShadow: isOutlined ? null : [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              icon, 
              color: isOutlined ? Colors.white : Colors.white, // Purple bg needs white icon
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

  Widget _buildRecentAvatar(String name, {bool isAdd = false}) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAdd ? const Color(0xFF1E1E1E) : Colors.grey[800],
              border: isAdd ? null : Border.all(color: Colors.transparent),
            ),
            child: isAdd 
              ? const Icon(Icons.add, color: Colors.white) 
              : const Center(child: Icon(Icons.person, color: Colors.white70)), // Placeholder image logic
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: GoogleFonts.poppins(
              color: isAdd ? const Color(0xFF7B1FA2) : Colors.grey, // Purple for add
              fontSize: 12
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({required IconData icon, required String title, required String subtitle, required String amount, required bool isNegative}) {
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
              color: isNegative ? const Color(0xFF7B1FA2).withOpacity(0.2) : const Color(0xFF7B1FA2), // Purple theme
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isNegative ? const Color(0xFF7B1FA2) : Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: isNegative ? Colors.white : const Color(0xFF7B1FA2), // Purple for positive
              fontWeight: FontWeight.bold, 
              fontSize: 16
            ),
          ),
        ],
      ),
    );
  }
}
