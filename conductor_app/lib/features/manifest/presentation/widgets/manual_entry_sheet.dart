import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class ManualEntrySheet extends StatefulWidget {
  final List<dynamic> manifest;
  final Set<int> boardingIds;
  final Future<void> Function(int) onBoardPassenger;

  const ManualEntrySheet({
    super.key,
    required this.manifest,
    required this.boardingIds,
    required this.onBoardPassenger,
  });

  @override
  State<ManualEntrySheet> createState() => _ManualEntrySheetState();
}

class _ManualEntrySheetState extends State<ManualEntrySheet> {
  String _searchQuery = '';
  final Set<int> _localBusyIds = <int>{};

  List<Map<String, dynamic>> get _filteredResults {
    final String q = _searchQuery.trim().toLowerCase();
    final Iterable<Map<String, dynamic>> bookedOrBoarded = widget.manifest
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .where(
          (Map<String, dynamic> p) =>
              AppTokens.normalizeSeatStatus(p['status']) != 'AVAILABLE' &&
              p['booking_id'] != null,
        );

    if (q.isEmpty) {
      return bookedOrBoarded.toList();
    }

    return bookedOrBoarded.where((Map<String, dynamic> p) {
      final String name = (p['passenger_name'] ?? '').toString().toLowerCase();
      final String phone = (p['passenger_phone'] ?? '').toString().toLowerCase();
      final String ticket = (p['booking_id'] ?? '').toString().toLowerCase();
      final String seat = (p['seat_number'] ?? '').toString().toLowerCase();
      return name.contains(q) ||
          phone.contains(q) ||
          ticket.contains(q) ||
          seat == q;
    }).toList();
  }

  Future<void> _handleBoard(int bookingId) async {
    if (_localBusyIds.contains(bookingId) ||
        widget.boardingIds.contains(bookingId)) {
      return;
    }
    setState(() => _localBusyIds.add(bookingId));
    try {
      await widget.onBoardPassenger(bookingId);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() => _localBusyIds.remove(bookingId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> results = _filteredResults;
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: <Widget>[
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Manual Passenger Verification',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Search by Name, Phone, Ticket # or Seat #',
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                autofocus: true,
                onChanged: (String val) => setState(() => _searchQuery = val),
                style: GoogleFonts.poppins(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type name, phone, ticket # or seat...',
                  hintStyle: GoogleFonts.poppins(color: Colors.white38),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppTokens.accent,
                  ),
                  filled: true,
                  fillColor: AppTokens.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTokens.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppTokens.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: results.isEmpty
                  ? Center(
                      child: Text(
                        'No booked passengers match your search.',
                        style: GoogleFonts.poppins(color: Colors.white54),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Colors.white10),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, dynamic> p = results[index];
                        final String status =
                            AppTokens.normalizeSeatStatus(p['status']);
                        final bool isBoarded = status == 'OCCUPIED';
                        final int? bookingId =
                            (p['booking_id'] as num?)?.toInt();
                        final bool isBusy = bookingId != null &&
                            (_localBusyIds.contains(bookingId) ||
                                widget.boardingIds.contains(bookingId));

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            backgroundColor: isBoarded
                                ? AppTokens.occupied
                                : AppTokens.booked,
                            child: Text(
                              '${p['seat_number'] ?? '-'}',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                fontFeatures: AppTokens.tabularFigures,
                              ),
                            ),
                          ),
                          title: Text(
                            (p['passenger_name'] ?? 'Unknown').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            'Seat #${p['seat_number']} • ${p['passenger_phone'] ?? 'No phone'} • Ticket #${bookingId ?? 'N/A'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              color: Colors.white54,
                              fontSize: 12,
                              fontFeatures: AppTokens.tabularFigures,
                            ),
                          ),
                          trailing: isBoarded
                              ? const Icon(
                                  Icons.check_circle_rounded,
                                  color: Colors.greenAccent,
                                )
                              : SizedBox(
                                  height: 36,
                                  child: ElevatedButton(
                                    onPressed: (bookingId == null || isBusy)
                                        ? null
                                        : () => _handleBoard(bookingId),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTokens.success,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isBusy
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : Text(
                                            'Board',
                                            style: GoogleFonts.poppins(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                  ),
                                ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
