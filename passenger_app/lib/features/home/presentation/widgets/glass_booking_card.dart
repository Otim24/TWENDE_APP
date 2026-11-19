import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';

class GlassBookingCard extends StatefulWidget {
  final ValueChanged<bool>? onFocusChange;
  final TextEditingController fromController;
  final TextEditingController toController;

  const GlassBookingCard({
    super.key,
    this.onFocusChange,
    required this.fromController,
    required this.toController,
  });

  @override
  State<GlassBookingCard> createState() => _GlassBookingCardState();
}

class _GlassBookingCardState extends State<GlassBookingCard> {
  final FocusNode _fromFocus = FocusNode();
  final FocusNode _toFocus = FocusNode();
  int _selectedDateIndex = 0;

  @override
  void initState() {
    super.initState();
    _fromFocus.addListener(_handleFocusChange);
    _toFocus.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    final bool hasFocus = _fromFocus.hasFocus || _toFocus.hasFocus;
    widget.onFocusChange?.call(hasFocus);
  }

  void _swapLocations() {
    final String temp = widget.fromController.text;
    setState(() {
      widget.fromController.text = widget.toController.text;
      widget.toController.text = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              _buildLocationInput(
                icon: Icons.my_location_rounded,
                hint: 'From (e.g. Kampala)',
                controller: widget.fromController,
                focusNode: _fromFocus,
                iconColor: const Color(0xFFAB47BC),
              ),
              Row(
                children: [
                  const SizedBox(width: 34),
                  Expanded(
                    child: Divider(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  IconButton(
                    onPressed: _swapLocations,
                    icon: const Icon(
                      Icons.swap_vert_circle_rounded,
                      color: Color(0xFFAB47BC),
                    ),
                  ),
                ],
              ),
              _buildLocationInput(
                icon: Icons.location_on_rounded,
                hint: 'To (e.g. Gulu)',
                controller: widget.toController,
                focusNode: _toFocus,
                iconColor: Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Departure Date',
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final DateTime date = DateTime.now().add(Duration(days: index));
              final bool isSelected = index == _selectedDateIndex;

              const List<String> weekdays = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ];
              final String weekdayName = weekdays[date.weekday - 1];

              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDateIndex = index;
                    });
                  },
                  child: AnimatedContainer(
                    duration: AppTokens.fastDuration,
                    curve: AppTokens.easeOutCurve,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTokens.primaryDark
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          isSelected ? null : Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          weekdayName,
                          style: GoogleFonts.outfit(
                            color: isSelected ? Colors.white : Colors.white54,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${date.day}',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            fontFeatures: AppTokens.tabularFigures,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          Center(
            child: GestureDetector(
              onTap: () {
                _fromFocus.unfocus();
                _toFocus.unfocus();

                final DateTime selectedDate =
                    DateTime.now().add(Duration(days: _selectedDateIndex));
                final String fromText = widget.fromController.text.trim();
                final String toText = widget.toController.text.trim();

                context.push(
                  '/search_results',
                  extra: <String, dynamic>{
                    'from': fromText.isEmpty ? 'Kampala' : fromText,
                    'to': toText.isEmpty ? 'Gulu' : toText,
                    'date': BookingRepository.formatYyyyMmDd(selectedDate),
                  },
                );
              },
              child: Container(
                width: 210,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTokens.primaryDark.withValues(alpha: 0.95),
                      AppTokens.primary.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTokens.primaryDark.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Search Buses',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInput({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required FocusNode focusNode,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.outfit(color: Colors.white38),
              filled: false,
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}
