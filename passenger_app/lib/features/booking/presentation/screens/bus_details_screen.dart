import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:twende_passenger_app/core/api/api_endpoints.dart';
import 'package:twende_passenger_app/core/theme/app_tokens.dart';
import 'package:twende_passenger_app/features/booking/data/booking_repository.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BusDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> bus;

  const BusDetailsScreen({super.key, required this.bus});

  @override
  ConsumerState<BusDetailsScreen> createState() => _BusDetailsScreenState();
}

class _BusDetailsScreenState extends ConsumerState<BusDetailsScreen> {
  MapLibreMapController? _mapController;
  WebSocketChannel? _channel;
  final LatLng _center = const LatLng(0.3476, 32.5825); // Kampala

  late Map<String, dynamic> _tripDetails;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tripDetails = Map<String, dynamic>.from(widget.bus);
    _loadLiveTripDetails();
    _connectWebSocket();
  }

  int get _tripId =>
      int.tryParse((_tripDetails['id'] ?? widget.bus['id'] ?? '1').toString()) ??
      1;

  Future<void> _loadLiveTripDetails() async {
    try {
      final Map<String, dynamic> fresh =
          await ref.read(bookingRepositoryProvider).getTripDetails(_tripId);
      if (!mounted) return;
      setState(() {
        _tripDetails = <String, dynamic>{
          ..._tripDetails,
          ...fresh,
          if (fresh['bus'] is Map && fresh['bus']['plate'] != null)
            'bus_plate': fresh['bus']['plate'],
        };
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _connectWebSocket() {
    final String wsBase = ApiEndpoints.wsUrl;
    try {
      _channel = WebSocketChannel.connect(Uri.parse('$wsBase/ws/$_tripId'));
      _channel!.stream.listen(
        (message) {
          try {
            final dynamic data = jsonDecode(message.toString());
            if (data is Map && data['lat'] != null && data['lng'] != null) {
              final double? lat = double.tryParse(data['lat'].toString());
              final double? lng = double.tryParse(data['lng'].toString());
              if (lat != null && lng != null) {
                _updateBusLocation(LatLng(lat, lng));
              }
            }
          } catch (_) {}
        },
        onError: (_) {},
      );
    } catch (e) {
      debugPrint('WebSocket Error: $e');
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _updateBusLocation(LatLng position) {
    if (_mapController != null) {
      _mapController!.clearCircles();
      _mapController!.addCircle(
        CircleOptions(
          geometry: position,
          circleColor: '#FF0000',
          circleRadius: 10,
          circleStrokeWidth: 2,
          circleStrokeColor: '#FFFFFF',
        ),
      );
      _mapController!.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  String _formatTime(dynamic rawIso, {String fallback = 'Scheduled'}) {
    if (rawIso == null) return fallback;
    final DateTime? parsed = DateTime.tryParse(rawIso.toString());
    if (parsed == null) return rawIso.toString();
    final DateTime local = parsed.toLocal();
    final int hour12 =
        local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final String amPm = local.hour >= 12 ? 'PM' : 'AM';
    final String min = local.minute.toString().padLeft(2, '0');
    return '$hour12:$min $amPm';
  }

  List<Map<String, String>> _buildTimelineStops() {
    final dynamic rawTimeline = _tripDetails['timeline'];
    final List<Map<String, String>> stops = <Map<String, String>>[];

    if (rawTimeline is List && rawTimeline.isNotEmpty) {
      for (int i = 0; i < rawTimeline.length; i++) {
        final dynamic item = rawTimeline[i];
        if (item is Map) {
          final String name =
              (item['name'] ?? item['stop'] ?? 'Stop ${i + 1}').toString();
          final String time = (item['time'] ??
                  item['eta'] ??
                  (i == 0
                      ? _formatTime(_tripDetails['departure_time'])
                      : 'Stop ${i + 1}'))
              .toString();
          stops.add(<String, String>{'name': name, 'time': time});
        } else {
          stops.add(<String, String>{
            'name': item.toString(),
            'time': i == 0
                ? _formatTime(_tripDetails['departure_time'])
                : 'En route',
          });
        }
      }
    }

    if (stops.isEmpty) {
      final String origin = (_tripDetails['origin'] ?? 'Kampala').toString();
      final String destination =
          (_tripDetails['destination'] ?? 'Gulu').toString();
      stops.addAll(<Map<String, String>>[
        <String, String>{
          'name': '$origin Main Terminal',
          'time': _formatTime(_tripDetails['departure_time']),
        },
        <String, String>{
          'name': '$destination Central Terminal',
          'time': _formatTime(
            _tripDetails['arrival_time'],
            fallback: 'Arrival',
          ),
        },
      ]);
    }
    return stops;
  }

  @override
  Widget build(BuildContext context) {
    final int availableSeats = int.tryParse(
          (_tripDetails['available_seats'] ?? _tripDetails['seats'] ?? '0')
              .toString(),
        ) ??
        0;
    final String formattedPrice = AppTokens.formatUgx(_tripDetails['price']);
    final String depTime = _formatTime(_tripDetails['departure_time']);
    final String arrTime = _formatTime(
      _tripDetails['arrival_time'],
      fallback: 'Scheduled',
    );
    final List<Map<String, String>> stops = _buildTimelineStops();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Embedded MapLibre Preview
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.58,
            width: double.infinity,
            child: MapLibreMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              onMapCreated: _onMapCreated,
              styleString: 'https://demotiles.maplibre.org/style.json',
              myLocationEnabled: false,
              attributionButtonPosition: AttributionButtonPosition.topRight,
            ),
          ),

          // 2. Top Navigation & Live Tracking Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.black,
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () =>
                            context.push('/tracking', extra: _tripDetails),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.my_location_rounded,
                                color: Colors.greenAccent,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Full Map',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 3. Draggable Details Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.46,
            minChildSize: 0.25,
            maxChildSize: 0.72,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(30)),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
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
                      padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildTimeInfo('Departure', depTime),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.circle,
                                    size: 8,
                                    color: Colors.white54,
                                  ),
                                  const Expanded(
                                    child: Divider(color: Colors.white24),
                                  ),
                                  Text(
                                    (_tripDetails['bus_plate'] ?? 'Twende')
                                        .toString(),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Expanded(
                                    child: Divider(color: Colors.white24),
                                  ),
                                  const Icon(
                                    Icons.location_on,
                                    size: 10,
                                    color: Colors.redAccent,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildTimeInfo('Arrival', arrTime),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Select Seats CTA & Price Row (Static, no infinite pulse)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () async {
                              await context.push(
                                '/seat_selection',
                                extra: _tripDetails,
                              );
                              if (mounted) {
                                _loadLiveTripDetails();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.selected,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.event_seat,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Select Seats ($availableSeats left)',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      fontFeatures: AppTokens.tabularFigures,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              formattedPrice,
                              style: GoogleFonts.outfit(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFeatures: AppTokens.tabularFigures,
                              ),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30, color: Colors.white12),

                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppTokens.primary,
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Route Stops Timeline',
                              style: GoogleFonts.outfit(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            for (int i = 0; i < stops.length; i++)
                              _buildTimelineItem(
                                stops[i]['name'] ?? 'Stop ${i + 1}',
                                stops[i]['time'] ?? '',
                                isFirst: i == 0,
                                isLast: i == stops.length - 1,
                                isCurrent: i == 0,
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(fontSize: 12, color: Colors.white54),
        ),
        Text(
          time,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFeatures: AppTokens.tabularFigures,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String station,
    String time, {
    bool isFirst = false,
    bool isLast = false,
    bool isCurrent = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: AppTokens.primary),
                  ),
                Icon(
                  isFirst || isLast
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isCurrent ? Colors.white : AppTokens.primary,
                  size: 16,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: AppTokens.primary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      station,
                      style: GoogleFonts.outfit(
                        color: isCurrent ? Colors.white : Colors.white70,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: GoogleFonts.outfit(
                      color: isCurrent ? Colors.white : Colors.white54,
                      fontWeight:
                          isCurrent ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                      fontFeatures: AppTokens.tabularFigures,
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
}
