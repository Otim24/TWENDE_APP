import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';

class PassengerListTab extends StatefulWidget {
  final List<dynamic> manifest;
  final Set<int> boardingIds;
  final Future<void> Function(int) onBoardPassenger;

  const PassengerListTab({
    super.key,
    required this.manifest,
    required this.boardingIds,
    required this.onBoardPassenger,
  });

  @override
  State<PassengerListTab> createState() => _PassengerListTabState();
}

class _PassengerListTabState extends State<PassengerListTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> allPassengers = widget.manifest
        .map((dynamic item) => Map<String, dynamic>.from(item as Map))
        .where(
          (Map<String, dynamic> p) =>
              AppTokens.normalizeSeatStatus(p['status']) != 'AVAILABLE' &&
              p['passenger_name'] != null,
        )
        .toList();

    final List<Map<String, dynamic>> awaitingBoarding = allPassengers
        .where(
          (Map<String, dynamic> p) =>
              AppTokens.normalizeSeatStatus(p['status']) == 'BOOKED',
        )
        .toList();

    final List<Map<String, dynamic>> boarded = allPassengers
        .where(
          (Map<String, dynamic> p) =>
              AppTokens.normalizeSeatStatus(p['status']) == 'OCCUPIED',
        )
        .toList();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            controller: _searchController,
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search passenger, phone, or seat #',
              hintStyle: GoogleFonts.poppins(color: Colors.white38, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white54, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTokens.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTokens.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTokens.border),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: AppTokens.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.border),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: AppTokens.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              tabs: <Widget>[
                Tab(text: 'All (${allPassengers.length})'),
                Tab(text: 'Booked (${awaitingBoarding.length})'),
                Tab(text: 'Boarded (${boarded.length})'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                '${allPassengers.length} Total Manifest',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 12,
                  fontFeatures: AppTokens.tabularFigures,
                ),
              ),
              Text(
                '${boarded.length}/${allPassengers.length} Verified On Board',
                style: GoogleFonts.poppins(
                  color: Colors.white60,
                  fontSize: 12,
                  fontFeatures: AppTokens.tabularFigures,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: <Widget>[
              _buildList(allPassengers),
              _buildList(awaitingBoarding),
              _buildList(boarded),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Map<String, dynamic>> passengers) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, dynamic>> filtered = passengers.where((Map<String, dynamic> p) {
      if (query.isEmpty) return true;
      final String name = (p['passenger_name'] ?? '').toString().toLowerCase();
      final String phone = (p['passenger_phone'] ?? '').toString().toLowerCase();
      final String seat = (p['seat_number'] ?? '').toString().toLowerCase();
      return name.contains(query) || phone.contains(query) || seat == query;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No matching passengers found.',
          style: GoogleFonts.poppins(color: Colors.white38),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (BuildContext context, int index) {
        final Map<String, dynamic> p = filtered[index];
        final String status = AppTokens.normalizeSeatStatus(p['status']);
        final bool isBoarded = status == 'OCCUPIED';
        final int? bookingId = (p['booking_id'] as num?)?.toInt();
        final bool isBusy =
            bookingId != null && widget.boardingIds.contains(bookingId);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTokens.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isBoarded
                      ? AppTokens.occupied.withValues(alpha: 0.2)
                      : AppTokens.booked.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isBoarded ? AppTokens.occupied : AppTokens.booked,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${p['seat_number'] ?? '-'}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFeatures: AppTokens.tabularFigures,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      (p['passenger_name'] ?? 'Unknown').toString(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p['passenger_phone'] ?? 'No phone'} • Ticket #${bookingId ?? 'N/A'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        fontSize: 12,
                        fontFeatures: AppTokens.tabularFigures,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isBoarded)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.occupied.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTokens.occupied),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.greenAccent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Boarded',
                        style: GoogleFonts.poppins(
                          color: Colors.greenAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: (bookingId == null || isBusy)
                        ? null
                        : () => widget.onBoardPassenger(bookingId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      disabledBackgroundColor: AppTokens.primary.withValues(alpha: 0.4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
