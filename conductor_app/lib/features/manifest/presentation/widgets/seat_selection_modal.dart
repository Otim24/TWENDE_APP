import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class SeatSelectionModal extends StatefulWidget {
  final List<int> bookedSeats;
  final int totalSeats;
  final int? initiallySelectedSeat;

  const SeatSelectionModal({
    super.key,
    required this.bookedSeats,
    this.totalSeats = 60,
    this.initiallySelectedSeat,
  });

  @override
  State<SeatSelectionModal> createState() => _SeatSelectionModalState();
}

class _SeatSelectionModalState extends State<SeatSelectionModal> {
  int? _selectedSeat;

  @override
  void initState() {
    super.initState();
    _selectedSeat = widget.initiallySelectedSeat;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTokens.border),
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Select Available Seat',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 200,
                    height: 36,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'FRONT / DRIVER',
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: GridView.builder(
                        itemCount: widget.totalSeats,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.0,
                        ),
                        itemBuilder: (BuildContext context, int index) {
                          final int seatNum = index + 1;
                          final bool isBooked =
                              widget.bookedSeats.contains(seatNum);
                          final bool isSelected = _selectedSeat == seatNum;

                          return GestureDetector(
                            onTap: isBooked
                                ? null
                                : () {
                                    setState(() {
                                      _selectedSeat =
                                          isSelected ? null : seatNum;
                                    });
                                  },
                            child: AnimatedContainer(
                              duration: AppTokens.fastDuration,
                              curve: AppTokens.easeOutCurve,
                              decoration: BoxDecoration(
                                color: isBooked
                                    ? AppTokens.danger.withValues(alpha: 0.28)
                                    : isSelected
                                        ? AppTokens.primary
                                        : AppTokens.available,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTokens.accent
                                      : Colors.white12,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: isBooked
                                  ? const Icon(
                                      Icons.close,
                                      color: Colors.white38,
                                      size: 20,
                                    )
                                  : Text(
                                      '$seatNum',
                                      style: GoogleFonts.poppins(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontWeight: FontWeight.bold,
                                        fontFeatures: AppTokens.tabularFigures,
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        _legendItem(AppTokens.available, 'Available'),
                        _legendItem(AppTokens.primary, 'Selected'),
                        _legendItem(
                          AppTokens.danger.withValues(alpha: 0.35),
                          'Taken',
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _selectedSeat == null
                            ? null
                            : () => Navigator.pop(context, _selectedSeat),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          disabledBackgroundColor: Colors.white10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _selectedSeat == null
                              ? 'Select a Seat'
                              : 'Confirm Seat #$_selectedSeat',
                          style: GoogleFonts.poppins(
                            color: _selectedSeat == null
                                ? Colors.white38
                                : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: <Widget>[
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
