import 'package:flutter/material.dart';
import 'package:marica/models/ticket_model.dart';
import 'package:marica/repositories/ticket_repository.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ticket_list_screen.dart';
import 'ticket_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  
  int _openTickets = 0;
  int _pendingTickets = 0;
  int _closedTickets = 0;
  int _installTickets = 0;
  int _pulloutTickets = 0;
  int _pmTickets = 0;
  int _cmTickets = 0;

  bool _isLoading = true;

  List<Ticket> _openTicketsList = [];
  final MapController _mapController = MapController();

  LatLng _getInitialCenter() {
    if (_openTicketsList.isNotEmpty) {
      double avgLat = 0;
      double avgLng = 0;
      int count = 0;
      for (var ticket in _openTicketsList) {
        final latValue = ticket.latitude ?? ticket.merchant?['latitude']?.toString();
        final lngValue = ticket.longitude ?? ticket.merchant?['longitude']?.toString();
        
        if (latValue != null && lngValue != null) {
          final lat = double.tryParse(latValue) ?? 0.0;
          final lng = double.tryParse(lngValue) ?? 0.0;
          avgLat += lat;
          avgLng += lng;
          count++;
        }
      }
      if (count > 0) return LatLng(avgLat / count, avgLng / count);
    }
    return LatLng(-6.2088, 106.8456); // Default: Jakarta
  }

  List<Marker> _buildMarkers() {
    return _openTicketsList.where((ticket) {
      final latValue = ticket.latitude ?? ticket.merchant?['latitude']?.toString();
      final lngValue = ticket.longitude ?? ticket.merchant?['longitude']?.toString();
      return latValue != null && lngValue != null;
    }).map((ticket) {
      final latValue = ticket.latitude ?? ticket.merchant?['latitude']?.toString();
      final lngValue = ticket.longitude ?? ticket.merchant?['longitude']?.toString();
      
      final lat = double.tryParse(latValue ?? '0') ?? 0.0;
      final lng = double.tryParse(lngValue ?? '0') ?? 0.0;
      final merchantName = ticket.merchant?['merchant_name'] ?? 'Merchant';
      final type = ticket.type;

      return Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: GestureDetector(
          onTap: () {
             ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$merchantName [$type]'),
                action: SnackBarAction(
                  label: 'DETAIL',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketDetailScreen(ticketId: ticket.ticketId),
                      ),
                    );
                  },
                ),
              ),
            );
          },
          child: Icon(
            Icons.location_on_rounded,
            color: _getTypeColor(type),
            size: 40,
          ),
        ),
      );
    }).toList();
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'INSTALL': return const Color(0xFF1E88E5);
      case 'PULLOUT': return const Color(0xFFE53935);
      case 'PM': return const Color(0xFF43A047);
      case 'CM': return const Color(0xFFFB8C00);
      default: return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      // Parallel fetching for performance
      final results = await Future.wait([
        supabase.from('tickets').count(CountOption.exact).eq('status', 'OPEN'),
        supabase.from('tickets').count(CountOption.exact).eq('status', 'CLOSED'),
        supabase.from('tickets').count(CountOption.exact).eq('status', 'PENDING'),
        supabase.from('tickets').count(CountOption.exact).eq('type', 'INSTALL').eq('status', 'OPEN'),
        supabase.from('tickets').count(CountOption.exact).eq('type', 'PULLOUT').eq('status', 'OPEN'),
        supabase.from('tickets').count(CountOption.exact).eq('type', 'PM').eq('status', 'OPEN'),
        supabase.from('tickets').count(CountOption.exact).eq('type', 'CM').eq('status', 'OPEN'),
      ]);

      // Fetch all open tickets with merchant locations
      final locationsData = await supabase
          .from('tickets')
          .select('*, merchants(*)')
          .eq('status', 'OPEN');

      if (mounted) {
        setState(() {
          _openTickets = results[0];
          _closedTickets = results[1];
          _pendingTickets = results[2];
          _installTickets = results[3];
          _pulloutTickets = results[4];
          _pmTickets = results[5];
          _cmTickets = results[6];
          _openTicketsList = (locationsData as List).map((json) => Ticket.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToTicketList(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TicketListScreen(
          initialStatus: 'OPEN',
          filterType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Pie chart logic
    final total = _openTickets + _closedTickets + _pendingTickets;
    
    final dataMap = <String, double>{
      "Selesai": _closedTickets.toDouble(),
      "Open": _openTickets.toDouble(),
      "Pending": _pendingTickets.toDouble(),
    };

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          color: const Color(0xFF00529C),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // --- HERO APP BAR ---
              SliverAppBar(
                expandedHeight: 180.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF00529C),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                  title: const Text(
                    "Dashboard",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF00529C), Color(0xFF003B73)],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Decorative circles
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          right: 20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        // Greeting Text in Background
                        const Positioned(
                          left: 20,
                          bottom: 70, // Increased bottom padding to be above the title area effectively or distinct
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Halo, Teknisi!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24, // Slightly larger in expanded state
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Kamis, 5 Feb 2026",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- SUMMARY SECTION ---
                      const Text(
                        "Overview Tiket",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF00529C).withValues(alpha: 0.1),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 0,
                                  ),
                                ],
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            PieChart(
                                              dataMap: dataMap,
                                              chartRadius: 120,
                                              ringStrokeWidth: 16,
                                              animationDuration: const Duration(milliseconds: 800),
                                              chartType: ChartType.ring,
                                              baseChartColor: const Color(0xFFF5F5F5),
                                              colorList: const [
                                                Color(0xFF00529C), // Selesai - Primary Blue
                                                Color(0xFFD32F2F), // Open - Red
                                                Color(0xFF64B5F6), // Pending - Light Blue
                                              ],
                                              chartValuesOptions: const ChartValuesOptions(showChartValues: false),
                                              legendOptions: const LegendOptions(showLegends: false),
                                              emptyColor: Colors.grey[100]!,
                                            ),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  total.toString(),
                                                  style: const TextStyle(
                                                    fontSize: 32,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF00529C),
                                                    height: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "Tiket",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[500],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 5,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            _StatRow(
                                              label: "Selesai",
                                              count: _closedTickets,
                                              color: const Color(0xFF00529C),
                                              icon: Icons.check_circle_rounded,
                                            ),
                                            const SizedBox(height: 16),
                                            _StatRow(
                                              label: "Open",
                                              count: _openTickets,
                                              color: const Color(0xFFD32F2F),
                                              icon: Icons.error_rounded,
                                            ),
                                            const SizedBox(height: 16),
                                            _StatRow(
                                              label: "Pending",
                                              count: _pendingTickets,
                                              color: const Color(0xFF64B5F6),
                                              icon: Icons.access_time_rounded,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  // Detailed progress bars or breakdown could go here if needed, 
                                  // but keeping it clean as requested.
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.info_outline_rounded, color: const Color(0xFF00529C), size: 20),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            "$_openTickets tiket perlu ditangani segera.",
                                            style: const TextStyle(
                                              color: Color(0xFF00529C),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                      const SizedBox(height: 32),

                      // --- PRIORITY SECTION ---
                      const Text(
                        "Kategori Tiket",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),

                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.2,
                        children: [
                          _PriorityCard(
                            title: "INSTALL",
                            count: _installTickets,
                            gradientColors: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                            icon: Icons.add_to_home_screen_rounded,
                            onTap: () => _navigateToTicketList('INSTALL'),
                          ),
                          _PriorityCard(
                            title: "PULLOUT",
                            count: _pulloutTickets,
                            gradientColors: const [Color(0xFFEF5350), Color(0xFFE53935)],
                            icon: Icons.remove_from_queue_rounded,
                            onTap: () => _navigateToTicketList('PULLOUT'),
                          ),
                          _PriorityCard(
                            title: "PM",
                            count: _pmTickets,
                            gradientColors: const [Color(0xFF66BB6A), Color(0xFF43A047)],
                            icon: Icons.build_rounded,
                            onTap: () => _navigateToTicketList('PM'),
                          ),
                          _PriorityCard(
                            title: "CM",
                            count: _cmTickets,
                            gradientColors: const [Color(0xFFFFA726), Color(0xFFFB8C00)],
                            icon: Icons.bug_report_rounded,
                            onTap: () => _navigateToTicketList('CM'),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32),

                      // --- MAP SECTION ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Peta Lokasi Tiket (OPEN)",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF333333),
                              letterSpacing: 0.5,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                               Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TicketListScreen(initialStatus: 'OPEN'),
                                  ),
                                );
                            },
                            child: const Text("Lihat Daftar"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                          ),
                          child: Stack(
                            children: [
                              _isLoading 
                                ? const Center(child: CircularProgressIndicator())
                                : FlutterMap(
                                    mapController: _mapController,
                                    options: MapOptions(
                                      initialCenter: _getInitialCenter(),
                                      initialZoom: 11.0,
                                    ),
                                    children: [
                                      TileLayer(
                                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                        userAgentPackageName: 'com.bniedc.app',
                                      ),
                                      MarkerLayer(
                                        markers: _buildMarkers(),
                                      ),
                                    ],
                                  ),
                              if (!_isLoading && _openTicketsList.isEmpty)
                                Container(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  child: const Center(
                                    child: Text(
                                      "Tidak ada tiket terbuka saat ini",
                                      style: TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData? icon;

  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
        ] else ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 4, spreadRadius: 1),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}

class _PriorityCard extends StatelessWidget {
  final String title;
  final int count;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  const _PriorityCard({
    required this.title,
    required this.count,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: gradientColors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: gradientColors.last, size: 24),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.grey[300], size: 20),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: gradientColors.last,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
