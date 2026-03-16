import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ticket_detail_screen.dart';

class TicketListScreen extends StatefulWidget {
  final String? initialStatus;
  final String? filterType;

  const TicketListScreen({super.key, this.initialStatus, this.filterType});

  @override
  State<TicketListScreen> createState() => _TicketListScreenState();
}

class _TicketListScreenState extends State<TicketListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SupabaseClient supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    int initialIndex = 0;
    if (widget.initialStatus == 'PENDING') initialIndex = 1;
    if (widget.initialStatus == 'CLOSED') initialIndex = 2;

    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: initialIndex,
    );
     _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Daftar Tiket'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF00529C),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF00529C),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(text: 'OPEN'),
            Tab(text: 'PENDING'),
            Tab(text: 'CLOSED'),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari Merchant atau ID Tiket...',
                prefixIcon: const Icon(Icons.search, color:  Color(0xFF00529C)),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTicketList('OPEN'),
                _buildTicketList('PENDING'),
                _buildTicketList('CLOSED'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketList(String status) {
    var query = supabase
        .from('tickets')
        .select('*, merchants(merchant_name, address)')
        .eq('status', status);

    if (widget.filterType != null) {
      query = query.eq('type', widget.filterType!);
    }

    // Apply ordering last
    // ignore: unused_local_variable
    final orderedQuery = query.order('opened_at', ascending: false);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: query.order('opened_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        var tickets = snapshot.data ?? [];
        
        // Client-side filtering
        if (_searchQuery.isNotEmpty) {
          tickets = tickets.where((ticket) {
            final merchant = ticket['merchants'] as Map<String, dynamic>?;
            final merchantName = (merchant?['merchant_name'] ?? '').toString().toLowerCase();
            final ticketId = (ticket['ticket_id'] ?? '').toString().toLowerCase();
            return merchantName.contains(_searchQuery) || ticketId.contains(_searchQuery);
          }).toList();
        }
        
        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty 
                      ? 'Tidak ditemukan tiket sesuai pencarian'
                      : 'Tidak ada tiket $status',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                    fontWeight: FontWeight.w500
                  )
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: tickets.length,
          itemBuilder: (context, index) {
            final ticket = tickets[index];
            final merchant = ticket['merchants'] as Map<String, dynamic>?;
            final merchantName = merchant?['merchant_name'] ?? 'Unknown Merchant';
            final address = merchant?['address'] ?? '-';
            final type = ticket['type'] ?? 'Unknown';
            final priority = ticket['priority'] ?? 'REGULER';
            final ticketId = ticket['ticket_id'] ?? '-';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TicketDetailScreen(ticketId: ticket['ticket_id']),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         // Ticket ID Row
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '#$ticketId',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Spacer(),
                            // Show Type
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: _getTypeColor(type).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: _getTypeColor(type),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Show Priority
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: priority == 'URGENT' 
                                    ? const Color(0xFFFFEBEE) 
                                    : const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                priority,
                                style: TextStyle(
                                  color: priority == 'URGENT' 
                                      ? const Color(0xFFD32F2F) 
                                      : const Color(0xFF1976D2),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                merchantName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Color(0xFF333333),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                         Row(
                           crossAxisAlignment: CrossAxisAlignment.start,
                           children: [
                             Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[400]),
                             const SizedBox(width: 4),
                             Expanded(
                               child: Text(
                                 address,
                                 style: TextStyle(
                                   color: Colors.grey[600],
                                   fontSize: 13,
                                   height: 1.3,
                                 ),
                                 maxLines: 2,
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                           ],
                         ),
                        const SizedBox(height: 12),
                        Divider(height: 1, color: Colors.grey[100]),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              "Lihat Detail",
                              style: TextStyle(
                                color: const Color(0xFF00529C),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 16, color: const Color(0xFF00529C)),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'INSTALL':
        return const Color(0xFF1E88E5);
      case 'PULLOUT':
        return const Color(0xFFE53935);
      case 'PM':
        return const Color(0xFF43A047);
      case 'CM':
        return const Color(0xFFFB8C00);
      default:
        return Colors.grey;
    }
  }
}
