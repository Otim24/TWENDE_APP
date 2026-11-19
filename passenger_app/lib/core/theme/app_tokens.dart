import 'package:flutter/material.dart';

class AppTokens {
  AppTokens._();

  // Core Surfaces
  static const Color background = Color(0xFF0A0A0E);
  static const Color surface = Color(0xFF18181F);
  static const Color surfaceElevated = Color(0xFF22222C);
  static const Color border = Color(0x1FFFFFFF);

  // Brand & Semantic Actions
  static const Color primary = Color(0xFF7B1FA2);
  static const Color primaryDark = Color(0xFF4A148C);
  static const Color accent = Color(0xFFE040FB);
  static const Color danger = Color(0xFFD32F2F);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);

  // Canonical Seat States
  // AVAILABLE = Empty seat
  // BOOKED    = Paid / unavailable seat
  // OCCUPIED  = Boarded & verified on bus
  // SELECTED  = Currently selected in passenger seat picker
  static const Color available = Color(0xFF22222C);
  static const Color booked = Color(0xFF7B1FA2);
  static const Color occupied = Color(0xFF2E7D32);
  static const Color selected = Color(0xFFE65100);

  // Motion Durations & Curves (Emil Kowalski Design Engineering Guidelines)
  static const Duration fastDuration = Duration(milliseconds: 160);
  static const Duration normalDuration = Duration(milliseconds: 220);
  static const Curve easeOutCurve = Curves.easeOutCubic;

  // Tabular figures so seat counts and UGX amounts never jitter
  static const List<FontFeature> tabularFigures = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  /// Normalizes any seat/booking status string to canonical backend values:
  /// 'AVAILABLE', 'BOOKED', or 'OCCUPIED'.
  static String normalizeSeatStatus(dynamic rawStatus) {
    final String status = (rawStatus ?? 'AVAILABLE').toString().trim().toUpperCase();
    if (status == 'OCCUPIED' || status == 'USED' || status == 'BOARDED') {
      return 'OCCUPIED';
    }
    if (status == 'BOOKED' || status == 'PAID' || status == 'LOCKED') {
      return 'BOOKED';
    }
    return 'AVAILABLE';
  }

  /// Safely parses a backend Decimal string (e.g. "30000.00", "UGX 30,000", 30000)
  /// into an integer UGX value without merging decimal zeroes into the integer.
  static int parseUgx(dynamic raw) {
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is double) return raw.round();

    final String cleaned = raw
        .toString()
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '')
        .trim();
    if (cleaned.isEmpty) return 0;

    final double? asDouble = double.tryParse(cleaned);
    if (asDouble != null) {
      return asDouble.round();
    }

    final String integerPart = cleaned.split('.').first;
    return int.tryParse(integerPart) ?? 0;
  }

  /// Formats any numeric or Decimal string into "UGX 30,000".
  static String formatUgx(dynamic raw, {bool includePrefix = true}) {
    final int amount = parseUgx(raw);
    final bool isNegative = amount < 0;
    final String digits = amount.abs().toString();
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < digits.length; i++) {
      final int positionFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (positionFromEnd > 1 && positionFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }

    final String formattedNumber = '${isNegative ? '-' : ''}${buffer.toString()}';
    return includePrefix ? 'UGX $formattedNumber' : formattedNumber;
  }
}
