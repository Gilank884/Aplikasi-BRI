import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DataScreen extends StatefulWidget {
  const DataScreen({super.key});

  @override
  State<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends State<DataScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Urgent Ticket Stats
  int _urgentOpen = 0;
  int _urgentPending = 0;
  int _urgentClosed = 0;

  // Regular Ticket Stats
  int _regularOpen = 0;
  int _regularPending = 0;
  int _regularClosed = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final results = await Future.wait([
        // Urgent
        supabase.from('tickets').count(CountOption.exact).eq('priority', 'URGENT').eq('status', 'OPEN'),
        supabase.from('tickets').count(CountOption.exact).eq('priority', 'URGENT').eq('status', 'PENDING'),
        supabase.from('tickets').count(CountOption.exact).eq('priority', 'URGENT').eq('status', 'CLOSED'),
        // Regular
        supabase.from('tickets').count(CountOption.exact).eq('priority', 'REGULER').eq('status', 'OPEN'),
        supabase.from('tickets').count(CountOption.exact).eq('priority', 'REGULER').eq('status', 'PENDING'),
        supabase.from('tickets').count(CountOption.exact).eq('priority', 'REGULER').eq('status', 'CLOSED'),
      ]);

      if (mounted) {
        setState(() {
          _urgentOpen = results[0];
          _urgentPending = results[1];
          _urgentClosed = results[2];
          _regularOpen = results[3];
          _regularPending = results[4];
          _regularClosed = results[5];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent background
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: _fetchData,
          color: const Color(0xFF00529C),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // --- GRADIENT HEADER ---
              SliverAppBar(
                expandedHeight: 140.0,
                floating: false,
                pinned: true,
                backgroundColor: const Color(0xFF00529C),
                elevation: 0,
                iconTheme: const IconThemeData(color: Colors.white),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: false,
                  titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                  title: const Text(
                    "Data Statistik",
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
                        Positioned(
                          top: -30,
                          right: -30,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Ringkasan Kinerja",
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
                          : Column(
                              children: [
                                _buildChartSection(
                                  title: 'Urgent Tickets',
                                  open: _urgentOpen,
                                  pending: _urgentPending,
                                  closed: _urgentClosed,
                                  gradientColors: const [Color(0xFFEF5350), Color(0xFFD32F2F)],
                                  icon: Icons.warning_rounded,
                                ),
                                const SizedBox(height: 24),
                                _buildChartSection(
                                  title: 'Regular Tickets',
                                  open: _regularOpen,
                                  pending: _regularPending,
                                  closed: _regularClosed,
                                  gradientColors: const [Color(0xFF42A5F5), Color(0xFF1976D2)],
                                  icon: Icons.assignment_rounded,
                                ),
                              ],
                            ),
                      
                      const SizedBox(height: 80),
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

  Widget _buildChartSection({
    required String title,
    required int open,
    required int pending,
    required int closed,
    required List<Color> gradientColors,
    required IconData icon,
  }) {
    final Map<String, double> dataMap = {
      "Selesai": closed.toDouble(),
      "Open": open.toDouble(),
      "Pending": pending.toDouble(),
    };

    final total = open + pending + closed;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.last.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradientColors),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors.last.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          if (total == 0)
            Container(
              height: 120,
              alignment: Alignment.center,
              child: Text(
                "Belum ada data",
                style: TextStyle(color: Colors.grey[400], fontStyle: FontStyle.italic),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 4,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        dataMap: dataMap,
                        chartRadius: 100,
                        ringStrokeWidth: 12,
                        chartType: ChartType.ring,
                        animationDuration: const Duration(milliseconds: 800),
                        baseChartColor: const Color(0xFFF5F5F5),
                        colorList: const [
                          Color(0xFF00529C), // Closed - Blue
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
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: gradientColors.last,
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
                    children: [
                      _StatRow(
                        label: "Selesai",
                        count: closed,
                        color: const Color(0xFF00529C),
                        icon: Icons.check_circle_rounded,
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        label: "Open",
                        count: open,
                        color: const Color(0xFFD32F2F),
                        icon: Icons.error_rounded,
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        label: "Pending",
                        count: pending,
                        color: const Color(0xFF64B5F6),
                        icon: Icons.access_time_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  const _StatRow({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          count.toString(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }
}
