
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/widgets/glass_container.dart';
import 'package:twende_passenger_app/core/widgets/glass_pill_input.dart';

class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final TextEditingController _amountController = TextEditingController();

  void _setAmount(String value) {
    _amountController.text = value;
    setState(() {});
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
          "Deposit Money",
          style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
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
                "Enter Amount",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 16),
              
              // Amount Input
              GlassPillInput(
                controller: _amountController,
                hintText: "10,000",
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                showCountryCode: false,
              ),

              const SizedBox(height: 32),

              // Quick Chips
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildChip("5,000"),
                  _buildChip("10,000"),
                  _buildChip("20,000"),
                  _buildChip("50,000"),
                ],
              ),
              
              const Spacer(),

              // Pay Button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFDD835), // MTN Yellow-ish
                  borderRadius: BorderRadius.circular(30),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Payment Logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: Text(
                    "Pay with MoMo",
                    style: GoogleFonts.poppins(
                      color: Colors.black, // Contrast for Yellow
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
          "UGX $amount",
          style: GoogleFonts.spaceMono(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
