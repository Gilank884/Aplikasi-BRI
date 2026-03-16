import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ticket_model.dart';

class TicketRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Ticket?> getTicketById(String ticketId) async {
    try {
      final response = await _supabase
          .from('tickets')
          .select('*, merchants(*)')
          .eq('ticket_id', ticketId)
          .single();
      
      return Ticket.fromJson(response);
    } catch (e) {
      print('Error fetching ticket: $e');
      return null;
    }
  }

  Future<bool> updateTicket(String ticketId, Ticket ticket) async {
    try {
      await _supabase
          .from('tickets')
          .update(ticket.toJson())
          .eq('ticket_id', ticketId);
      return true;
    } catch (e) {
      print('Error updating ticket: $e');
      return false;
    }
  }

  Future<List<Ticket>> getTicketsByStatus(String status, {String? type}) async {
    try {
      var query = _supabase
          .from('tickets')
          .select('*, merchants(*)')
          .eq('status', status);
      
      if (type != null) {
        query = query.eq('type', type);
      }

      final response = await query.order('opened_at', ascending: false);
      
      return (response as List).map((json) => Ticket.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching tickets: $e');
      return [];
    }
  }
}
