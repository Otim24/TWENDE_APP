import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String fromLocation;
  final String toLocation;
  final String? initialDate;

  const SearchResultsScreen({
    super.key,
    required this.fromLocation,
    required this.toLocation,
    this.initialDate,
  });

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen> {
  late String _fromLocation;
  late String _toLocation;
  late DateTime _selectedDate;

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _trips = <Map<String, dynamic>>[];

  final List<String> _ugandanDistricts = const <String>[
    'Kampala',
    'Gulu',
    'Jinja',
    'Mbarara',
    'Lira',
    'Mbale',
    'Masaka',
    'Arua',
    'Soroti',
    'Fort Portal',
    'Entebbe',
    'Hoima',
    'Kabale',
    'Kasese',
    'Tororo',
    'Busia',
    'Mukono',
    'Iganga',
    'Kitgum',
    'Moroto',
  ];

  @override
  void initState() {
    super.initState();
    _fromLocation =
        widget.fromLocation.trim().isEmpty ? 'Kampala' : widget.fromLocation.trim();
    _toLocation =
        widget.toLocation.trim().isEmpty ? 'Gulu' : widget.toLocation.trim();
    _selectedDate = _parseInitialDate(widget.initialDate);
    _fetchTrips(autoDiscoverNextAvailable: true);
  }

  DateTime _parseInitialDate(String? raw) {
    if (raw != null && raw.trim().isNotEmpty) {
      final DateTime? parsed = DateTime.tryParse(raw.trim());
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    final DateTime now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _fetchTrips({bool autoDiscoverNextAvailable = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(bookingRepositoryProvider);
      final String dateStr = BookingRepository.formatYyyyMmDd(_selectedDate);
      List<Map<String, dynamic>> results = await repo.searchTrips(
        from: _fromLocation,
        to: _toLocation,
        date: dateStr,
      );

      // If initial search date has 0 trips, check the next 5 days so seeded future trips are found smoothly
      if (results.isEmpty && autoDiscoverNextAvailable) {
        for (int offset = 0; offset <= 5; offset++) {
          final DateTime candidate =
              DateTime.now().add(Duration(days: offset));
          final String candidateStr =
              BookingRepository.formatYyyyMmDd(candidate);
          if (candidateStr == dateStr) continue;
          final List<Map<String, dynamic>> candidateTrips =
              await repo.searchTrips(
            from: _fromLocation,
            to: _toLocation,
            date: candidateStr,
          );
          if (candidateTrips.isNotEmpty) {
            _selectedDate = DateTime(
              candidate.year,
              candidate.month,
              candidate.day,
            );
            results = candidateTrips;
            break;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _trips = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _formatDateChip(DateTime d) {
    const List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      return 'Today, ${d.day} ${months[d.month - 1]}';
    }
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String _formatTime(dynamic rawIso) {
    if (rawIso == null) return 'Scheduled';
    final DateTime? parsed = DateTime.tryParse(rawIso.toString());
    if (parsed == null) return rawIso.toString();
    final DateTime local = parsed.toLocal();
    final int hour12 =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final String amPm = local.hour >= 12 ? 'PM' : 'AM';
    final String min = local.minute.toString().padLeft(2, '0');
    return '$hour12:$min $amPm';
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(DateTime(now.year, now.month, now.day))
          ? now
          : _selectedDate,
      firstDate: DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(picked.year, picked.month, picked.day);
      });
      await _fetchTrips();
    }
  }

  void _showLocationPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  isFrom ? 'Select Departure' : 'Select Destination',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Divider(color: Colors.white12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _ugandanDistricts.length,
                  itemBuilder: (context, index) {
                    final String district = _ugandanDistricts[index];
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        setState(() {
                          if (isFrom) {
                            _fromLocation = district;
                          } else {
                            _toLocation = district;
                          }
                        });
                        _fetchTrips(autoDiscoverNextAvailable: true);
                      },
                      leading: const Icon(
                        Icons.location_city_rounded,
                        color: Colors.white54,
                      ),
                      title: Text(
                        district,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Colors.white24,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTokens.primaryDark, AppTokens.primary],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => context.pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Available Trips',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () => _fetchTrips(),
                      ),
                    ],
                  ),
                ),

                // Route & Date Filter Box
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _showLocationPicker(true),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.radio_button_unchecked,
                              color: Color(0xFF7C4DFF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _fromLocation,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_location_alt_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 9),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 16,
                            width: 2,
                            color: Colors.white24,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showLocationPicker(false),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF7C4DFF),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _toLocation,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.edit_location_alt_rounded,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: Colors.white12),
                      Row(
                        children: [
                          _buildOptionChip(
                            Icons.calendar_today_rounded,
                            _formatDateChip(_selectedDate),
                            _pickDate,
                          ),
                          const SizedBox(width: 12),
                          _buildOptionChip(
                            Icons.swap_horiz_rounded,
                            'Swap Route',
                            () {
                              setState(() {
                                final String tmp = _fromLocation;
                                _fromLocation = _toLocation;
                                _toLocation = tmp;
                              });
                              _fetchTrips(autoDiscoverNextAvailable: true);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Scheduled Buses',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${_trips.length} found',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white54,
                          fontFeatures: AppTokens.tabularFigures,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTokens.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.redAccent,
                size: 48,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchTrips(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.directions_bus_outlined,
                color: Colors.white38,
                size: 56,
              ),
              const SizedBox(height: 12),
              Text(
                'No buses scheduled for $_fromLocation ➔ $_toLocation on ${_formatDateChip(_selectedDate)}.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: const Text('Change Date'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _fromLocation = 'Kampala';
                        _toLocation = 'Gulu';
                      });
                      _fetchTrips(autoDiscoverNextAvailable: true);
                    },
                    icon: const Icon(Icons.route_rounded, size: 18),
                    label: const Text('Show Kampala ➔ Gulu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppTokens.primary,
      onRefresh: () => _fetchTrips(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        itemCount: _trips.length,
        itemBuilder: (context, index) {
          final Map<String, dynamic> trip = _trips[index];
          return _buildBusCard(trip);
        },
      ),
    );
  }

  Widget _buildOptionChip(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: Colors.white70),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> trip) {
    final String busPlate = (trip['bus_plate'] ?? 'Twende Coach').toString();
    final String routeName = (trip['route_name'] ??
            '${trip['origin'] ?? _fromLocation} ➔ ${trip['destination'] ?? _toLocation}')
        .toString();
    final String depTime = _formatTime(trip['departure_time']);
    final String formattedPrice = AppTokens.formatUgx(trip['price']);
    final int availableSeats =
        int.tryParse((trip['available_seats'] ?? '0').toString()) ?? 0;
    final int totalSeats =
        int.tryParse((trip['total_seats'] ?? '60').toString()) ?? 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTokens.primaryDark.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_bus,
                  color: AppTokens.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Twende Express • $busPlate',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      routeName,
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Departure',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    depTime,
                    style: GoogleFonts.poppins(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      fontFeatures: AppTokens.tabularFigures,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Colors.white12),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.confirmation_number_outlined,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                'Trip #${trip['id']}',
                style: GoogleFonts.poppins(
                  color: Colors.white54,
                  fontSize: 12,
                  fontFeatures: AppTokens.tabularFigures,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.event_seat_outlined,
                size: 16,
                color: Colors.white54,
              ),
              const SizedBox(width: 4),
              Text(
                '$availableSeats / $totalSeats seats left',
                style: GoogleFonts.poppins(
                  color: availableSeats > 0 ? Colors.white70 : Colors.redAccent,
                  fontSize: 13,
                  fontFeatures: AppTokens.tabularFigures,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fare per seat',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    formattedPrice,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFeatures: AppTokens.tabularFigures,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: availableSeats > 0
                    ? () {
                        context.push('/bus_details', extra: trip);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTokens.selected,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  availableSeats > 0 ? 'Select Bus' : 'Sold Out',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
