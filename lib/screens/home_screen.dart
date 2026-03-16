import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ticket_list_screen.dart';

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

  List<Map<String, dynamic>> _recentTickets = [];

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

      // Fetch 5 most recent tickets
      final recentData = await supabase
          .from('tickets')
          .select('*, merchants(merchant_name)')
          .order('opened_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _openTickets = results[0];
          _closedTickets = results[1];
          _pendingTickets = results[2];
          _installTickets = results[3];
          _pulloutTickets = results[4];
          _pmTickets = results[5];
          _cmTickets = results[6];
          _recentTickets = List<Map<String, dynamic>>.from(recentData);
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
                                        const Icon(Icons.info_outline_rounded, color: Color(0xFF00529C), size: 20),
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

                      // --- RECENT ACTIVITY SECTION ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Aktivitas Terbaru",
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
                            child: const Text("Lihat Semua"),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_recentTickets.isEmpty && !_isLoading)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Center(
                            child: Text(
                              "Belum ada tiket terbaru",
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentTickets.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final ticket = _recentTickets[index];
                            final merchant = ticket['merchants'] as Map<String, dynamic>?;
                            final merchantName = merchant?['merchant_name'] ?? 'Unknown';
                            final ticketId = ticket['ticket_id'] ?? '-';
                            final status = ticket['status'] ?? 'Unknown';
                            
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.confirmation_number_outlined, color: Color(0xFF00529C), size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          merchantName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF333333),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          "#$ticketId",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: status == 'OPEN' ? const Color(0xFFFFEBEE) : 
                                             status == 'CLOSED' ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'OPEN' ? const Color(0xFFD32F2F) :
                                               status == 'CLOSED' ? const Color(0xFF388E3C) : const Color(0xFF1976D2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
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
