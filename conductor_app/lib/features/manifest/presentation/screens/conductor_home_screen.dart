import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:twende_conductor_app/core/api/api_client.dart';
import 'package:twende_conductor_app/core/api/api_endpoints.dart';
import 'package:twende_conductor_app/core/services/gps_broadcast_service.dart';
import 'package:twende_conductor_app/core/theme/app_tokens.dart';
import 'package:twende_conductor_app/features/auth/presentation/screens/login_screen.dart';
import 'package:twende_conductor_app/features/manifest/presentation/tabs/dashboard_tab.dart';
import 'package:twende_conductor_app/features/manifest/presentation/tabs/passenger_list_tab.dart';
import 'package:twende_conductor_app/features/manifest/presentation/tabs/seat_map_tab.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/manual_entry_sheet.dart';
import 'package:twende_conductor_app/features/manifest/presentation/widgets/sell_ticket_sheet.dart';
import 'package:twende_conductor_app/features/scan/presentation/screens/scanner_screen.dart';

class ConductorHomeScreen extends StatefulWidget {
  final String userName;

  const ConductorHomeScreen({
    super.key,
    required this.userName,
  });

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _trips = <Map<String, dynamic>>[];
  Map<String, dynamic>? _activeTrip;
  List<dynamic> _manifest = <dynamic>[];
  final Set<int> _boardingIds = <int>{};
  final GpsBroadcastService _gpsService = GpsBroadcastService();

  @override
  void initState() {
    super.initState();
    _gpsService.addListener(_onGpsStateChanged);
    AuthSession.onUnauthorized = _handleUnauthorized;
    _fetchData();
  }

  @override
  void dispose() {
    AuthSession.onUnauthorized = null;
    _gpsService.removeListener(_onGpsStateChanged);
    _gpsService.dispose();
    super.dispose();
  }

  void _onGpsStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleUnauthorized() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _fetchData({int? preferredTripId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final tripsResponse = await ApiClient.dio.get(
        '${ApiEndpoints.conductorUrl}/trips',
      );

      final List<dynamic> rawTrips =
          tripsResponse.data is List ? tripsResponse.data as List<dynamic> : <dynamic>[];
      _trips = rawTrips
          .map((dynamic t) => Map<String, dynamic>.from(t as Map))
          .toList();

      if (_trips.isEmpty) {
        _activeTrip = null;
        _manifest = <dynamic>[];
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }

      final int? targetId =
          preferredTripId ?? (_activeTrip?['id'] as num?)?.toInt();
      _activeTrip = _trips.firstWhere(
        (Map<String, dynamic> t) => (t['id'] as num?)?.toInt() == targetId,
        orElse: () => _trips.first,
      );

      await _fetchManifestForActiveTrip();
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = ApiClient.extractErrorMessage(
            e,
            fallback: 'Could not load shift manifest.',
          );
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchManifestForActiveTrip() async {
    final int? tripId = (_activeTrip?['id'] as num?)?.toInt();
    if (tripId == null) return;

    final manifestResponse = await ApiClient.dio.get(
      '${ApiEndpoints.conductorUrl}/trips/$tripId/manifest',
    );
    if (manifestResponse.statusCode == 200 && manifestResponse.data is List) {
      _manifest = (manifestResponse.data as List<dynamic>).map((dynamic item) {
        final Map<String, dynamic> map =
            Map<String, dynamic>.from(item as Map);
        map['status'] = AppTokens.normalizeSeatStatus(map['status']);
        return map;
      }).toList();
    }
  }

  Future<void> _manualBoard(int bookingId) async {
    if (_boardingIds.contains(bookingId)) return;

    setState(() {
      _boardingIds.add(bookingId);
    });

    try {
      final int? tripId = (_activeTrip?['id'] as num?)?.toInt();
      final response = await ApiClient.dio.post(
        '${ApiEndpoints.conductorUrl}/verify_ticket',
        data: <String, dynamic>{
          'booking_id': bookingId,
          if (tripId != null) 'trip_id': tripId,
        },
      );

      if (response.data is Map && response.data['valid'] == true) {
        if (mounted) {
          setState(() {
            final int index = _manifest.indexWhere(
              (dynamic p) => (p['booking_id'] as num?)?.toInt() == bookingId,
            );
            if (index != -1) {
              final Map<String, dynamic> updated =
                  Map<String, dynamic>.from(_manifest[index] as Map);
              updated['status'] = 'OCCUPIED';
              _manifest[index] = updated;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Passenger boarded & verified.'),
              backgroundColor: AppTokens.success,
            ),
          );
        }
        await _fetchData(preferredTripId: tripId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ApiClient.extractErrorMessage(
                e,
                fallback: 'Failed to board passenger.',
              ),
            ),
            backgroundColor: AppTokens.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _boardingIds.remove(bookingId);
        });
      }
    }
  }

  Future<void> _openScanner() async {
    final int? tripId = (_activeTrip?['id'] as num?)?.toInt();
    await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => ScannerScreen(tripId: tripId),
      ),
    );
    if (mounted) {
      await _fetchData(preferredTripId: tripId);
    }
  }

  void _openSellTicketSheet({int? initialSeatNumber}) {
    if (_activeTrip == null) return;
    final int? tripId = (_activeTrip?['id'] as num?)?.toInt();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => SellTicketSheet(
        trip: _activeTrip,
        manifest: _manifest,
        initialSeatNumber: initialSeatNumber,
        onSuccess: () {
          _fetchData(preferredTripId: tripId);
        },
      ),
    );
  }

  void _openManualEntrySheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => ManualEntrySheet(
        manifest: _manifest,
        boardingIds: _boardingIds,
        onBoardPassenger: _manualBoard,
      ),
    );
  }

  void _handleSeatTap(Map<String, dynamic> seatData) {
    final String status = AppTokens.normalizeSeatStatus(seatData['status']);
    final int? seatNumber = (seatData['seat_number'] as num?)?.toInt();
    final int? bookingId = (seatData['booking_id'] as num?)?.toInt();

    if (status == 'AVAILABLE') {
      _openSellTicketSheet(initialSeatNumber: seatNumber);
      return;
    }

    final bool isBoarded = status == 'OCCUPIED';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: AppTokens.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTokens.border),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isBoarded ? AppTokens.occupied : AppTokens.booked)
                          .withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            isBoarded ? AppTokens.occupied : AppTokens.booked,
                      ),
                    ),
                    child: Text(
                      '${seatNumber ?? '-'}',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFeatures: AppTokens.tabularFigures,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (seatData['passenger_name'] ?? 'Unknown Passenger')
                              .toString(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          isBoarded
                              ? 'BOARDED & VERIFIED'
                              : 'BOOKED • AWAITING BOARDING',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isBoarded
                                ? Colors.greenAccent
                                : AppTokens.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _infoCard(
                      Icons.phone_outlined,
                      'Phone',
                      (seatData['passenger_phone'] ?? 'N/A').toString(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _infoCard(
                      Icons.confirmation_number_outlined,
                      'Booking ID',
                      bookingId != null ? '#$bookingId' : 'N/A',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (!isBoarded)
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner_rounded),
                        label: const Text('Scan QR'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          _openScanner();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Board Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTokens.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        onPressed: bookingId == null
                            ? null
                            : () {
                                Navigator.pop(sheetContext);
                                _manualBoard(bookingId);
                              },
                      ),
                    ),
                  ],
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Passenger Already Verified'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTokens.occupied.withValues(alpha: 0.25),
                      foregroundColor: Colors.greenAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontFeatures: AppTokens.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleGpsBroadcast() async {
    final int? tripId = (_activeTrip?['id'] as num?)?.toInt();
    if (tripId == null) return;

    final bool started = await _gpsService.toggleBroadcast(tripId);
    if (!mounted) return;

    if (_gpsService.lastError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_gpsService.lastError!),
          backgroundColor: AppTokens.danger,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            started
                ? 'Live GPS broadcast active for Trip #$tripId.'
                : 'Live GPS broadcast stopped.',
          ),
          backgroundColor: started ? AppTokens.success : Colors.blueGrey,
        ),
      );
    }
  }

  void _onSwitchTab(int index) {
    if (index == 3) {
      _openScanner();
      return;
    }
    setState(() => _selectedIndex = index);
  }

  void _showTripPickerSheet() {
    if (_trips.length <= 1) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTokens.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                'Select Active Trip',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _trips.length,
                  itemBuilder: (BuildContext context, int index) {
                    final Map<String, dynamic> t = _trips[index];
                    final int id = (t['id'] as num?)?.toInt() ?? 0;
                    final bool isSelected =
                        (_activeTrip?['id'] as num?)?.toInt() == id;
                    return ListTile(
                      onTap: () {
                        Navigator.pop(sheetContext);
                        _fetchData(preferredTripId: id);
                      },
                      leading: Icon(
                        Icons.directions_bus_rounded,
                        color: isSelected ? AppTokens.accent : Colors.white54,
                      ),
                      title: Text(
                        (t['route_name'] ?? 'Route').toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        '${t['bus_plate'] ?? ''} • ${AppTokens.formatUgx(t['price'])}',
                        style: GoogleFonts.poppins(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppTokens.accent,
                            )
                          : null,
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
      backgroundColor: AppTokens.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            _buildHeader(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTokens.primary),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _activeTrip == null
                          ? _buildEmptyTripsState()
                          : IndexedStack(
                              index: _selectedIndex,
                              children: <Widget>[
                                DashboardTab(
                                  trip: _activeTrip,
                                  manifest: _manifest,
                                  isBroadcastingGps: _gpsService.isBroadcasting,
                                  lastCoordinate:
                                      _gpsService.lastSentCoordinate,
                                  onToggleTripGps: _toggleGpsBroadcast,
                                  onSwitchTab: _onSwitchTab,
                                  onManualEntry: _openManualEntrySheet,
                                  onSellTicket: () => _openSellTicketSheet(),
                                ),
                                PassengerListTab(
                                  manifest: _manifest,
                                  boardingIds: _boardingIds,
                                  onBoardPassenger: _manualBoard,
                                ),
                                SeatMapTab(
                                  manifest: _manifest,
                                  onSeatTap: _handleSeatTap,
                                ),
                              ],
                            ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildDockedNav(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _fetchData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTripsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.directions_bus_outlined,
              color: Colors.white38,
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              'No Active Scheduled Trips',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'When a trip is scheduled or boarding, its passenger manifest will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _fetchData(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.primary,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh Trips'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String title = widget.userName;
    if (_selectedIndex == 1) title = 'Passenger Manifest';
    if (_selectedIndex == 2) title = 'Interactive Seat Map';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Row(
        children: <Widget>[
          if (_selectedIndex == 0)
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTokens.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 18,
                backgroundColor: AppTokens.surface,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            )
          else
            IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
              onPressed: () => _onSwitchTab(0),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_selectedIndex == 0)
                  Text(
                    'Conductor on Duty',
                    style: GoogleFonts.poppins(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (_trips.length > 1)
            TextButton.icon(
              onPressed: _showTripPickerSheet,
              icon: const Icon(
                Icons.swap_horiz_rounded,
                color: AppTokens.accent,
                size: 18,
              ),
              label: Text(
                'Switch Trip',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          IconButton(
            tooltip: 'Refresh Manifest',
            onPressed: () => _fetchData(),
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
          IconButton(
            tooltip: 'Sign Out',
            onPressed: () {
              _gpsService.stopBroadcast();
              AuthSession.clearSession();
              _handleUnauthorized();
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildDockedNav() {
    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.surface,
        border: Border(top: BorderSide(color: AppTokens.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            _navItem(0, Icons.dashboard_rounded, 'Shift'),
            _navItem(1, Icons.people_alt_rounded, 'Manifest'),
            _navItem(2, Icons.grid_view_rounded, 'Seat Map'),
            _navItem(3, Icons.qr_code_scanner_rounded, 'Scan QR'),
          ],
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, String label) {
    final bool isSelected = _selectedIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _onSwitchTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: AppTokens.primary,
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white54,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
