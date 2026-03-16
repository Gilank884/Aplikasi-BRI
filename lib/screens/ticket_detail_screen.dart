import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import '../models/ticket_model.dart';
import '../repositories/ticket_repository.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final TicketRepository _ticketRepository = TicketRepository();
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  Ticket? _ticket;

  // Form Controllers
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _keteranganValues = {};
  final Map<String, bool> _checklists = {};
  String _status = 'OPEN';
  DateTime? _visitDate;
  
  // Signatures
  final SignatureController _sigPicController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );
  final SignatureController _sigTeknisiController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.transparent,
  );

  @override
  void initState() {
    super.initState();
    _fetchTicketDetails();
  }

  Future<void> _fetchTicketDetails() async {
    try {
      final ticket = await _ticketRepository.getTicketById(widget.ticketId);

      if (mounted && ticket != null) {
        setState(() {
          _ticket = ticket;
          _status = ticket.status;
          _visitDate = ticket.visitDate;
          
          // General controllers
          _textControllers['latitude'] = TextEditingController(text: ticket.latitude);
          _textControllers['longitude'] = TextEditingController(text: ticket.longitude);
          _textControllers['bast_status'] = TextEditingController(text: ticket.bastStatus);
          _textControllers['contact_phone'] = TextEditingController(text: ticket.contactPhone);
          _textControllers['current_sn'] = TextEditingController(text: ticket.currentSn);
          _textControllers['current_edc_status'] = TextEditingController(text: ticket.currentEdcStatus);
          _textControllers['replacement_sn'] = TextEditingController(text: ticket.replacementSn);
          _textControllers['replacement_model'] = TextEditingController(text: ticket.replacementModel);
          _textControllers['loss_notes'] = TextEditingController(text: ticket.lossNotes);
          _textControllers['user_notes'] = TextEditingController(text: ticket.userNotes);

          // Setup Switch/Bool states
          _checklists['test_transaction'] = ticket.testTransaction;
          _checklists['app_upgrade'] = ticket.appUpgrade;
          _checklists['bni_sales_slip'] = ticket.bniSalesSlip;
          _checklists['bni_standard_ack'] = ticket.bniStandardAck;
          _checklists['has_loss'] = ticket.hasLoss;

          // Type Specific Checklists
          _initializeChecklists(ticket);

          _initializeKeteranganField('keterangan_gestun', ticket.keteranganGestun);
          _initializeKeteranganField('keterangan_pindah_lokasi', ticket.keteranganPindahLokasi);
          _initializeKeteranganField('keterangan_tutup_permanent', ticket.keteranganTutupPermanent);
          _initializeKeteranganField('keterangan_edc', ticket.keteranganEdc);
          _initializeKeteranganField('keterangan_fraud', ticket.keteranganFraud);
          _initializeKeteranganField('keterangan_qris', ticket.keteranganQris);
          _initializeKeteranganField('keterangan_dokumen', ticket.keteranganDokumen);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching ticket: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ticket: $e')),
        );
      }
    }
  }

  void _initializeChecklists(Ticket ticket) {
    if (ticket.type == 'INSTALL') {
      _checklists['ins_chk_reader_edc'] = ticket.insChkReaderEdc;
      _checklists['ins_chk_sam_card'] = ticket.insChkSamCard;
      _checklists['ins_chk_sim_card'] = ticket.insChkSimCard;
      _checklists['ins_chk_stacker'] = ticket.insChkStacker;
      _checklists['ins_chk_thermal_paper'] = ticket.insChkThermalPaper;
      _checklists['ins_chk_promo_material'] = ticket.insChkPromoMaterial;
      _checklists['ins_chk_extra'] = ticket.insChkExtra;
    } else if (ticket.type == 'PM') {
      _checklists['pm_chk_edc'] = ticket.pmChkEdc;
      _checklists['pm_chk_sam_card'] = ticket.pmChkSamCard;
      _checklists['pm_chk_sim_card'] = ticket.pmChkSimCard;
      _checklists['pm_chk_cable_ecr'] = ticket.pmChkCableEcr;
      _checklists['pm_chk_adapter'] = ticket.pmChkAdapter;
      _checklists['pm_chk_thermal_supply'] = ticket.pmChkThermalSupply;
      _checklists['pm_chk_promo_material'] = ticket.pmChkPromoMaterial;
      _checklists['pm_chk_extra'] = ticket.pmChkExtra;
    } else if (ticket.type == 'CM') {
      _checklists['cm_chk_edc'] = ticket.cmChkEdc;
      _checklists['cm_chk_sam_card'] = ticket.cmChkSamCard;
      _checklists['cm_chk_sim_card'] = ticket.cmChkSimCard;
      _checklists['cm_chk_cable_ecr'] = ticket.cmChkCableEcr;
      _checklists['cm_chk_adapter'] = ticket.cmChkAdapter;
      _checklists['cm_chk_thermal_supply'] = ticket.cmChkThermalSupply;
      _checklists['cm_chk_promo_material'] = ticket.cmChkPromoMaterial;
      _checklists['cm_chk_extra'] = ticket.cmChkExtra;
    } else if (ticket.type == 'PULLOUT') {
      _checklists['pu_chk_edc'] = ticket.puChkEdc;
      _checklists['pu_chk_sam_card'] = ticket.puChkSamCard;
      _checklists['pu_chk_sim_card'] = ticket.puChkSimCard;
      _checklists['pu_chk_promo_material'] = ticket.puChkPromoMaterial;
      _checklists['pu_chk_cable_adapter'] = ticket.puChkCableAdapter;
    }
  }

  void _initializeKeteranganField(String key, String? value) {
    if (value == null) {
      _keteranganValues[key] = 'Baik'; // Default
      _textControllers[key] = TextEditingController();
    } else if (value == 'Baik' || value == 'Tidak Baik') {
      _keteranganValues[key] = value;
      _textControllers[key] = TextEditingController();
    } else {
      _keteranganValues[key] = 'Text';
      _textControllers[key] = TextEditingController(text: value);
    }
  }

  Future<void> _saveTicket() async {
    if (_ticket == null) return;
    setState(() => _isSaving = true);
    try {
      final updatedTicket = Ticket(
        ticketId: widget.ticketId,
        status: _status,
        type: _ticket!.type,
        priority: _ticket!.priority,
        latitude: _textControllers['latitude']?.text,
        longitude: _textControllers['longitude']?.text,
        visitDate: _visitDate,
        testTransaction: _checklists['test_transaction'] ?? false,
        appUpgrade: _checklists['app_upgrade'] ?? false,
        bastStatus: _textControllers['bast_status']?.text,
        contactPhone: _textControllers['contact_phone']?.text,
        bniSalesSlip: _checklists['bni_sales_slip'] ?? false,
        bniStandardAck: _checklists['bni_standard_ack'] ?? false,
        currentSn: _textControllers['current_sn']?.text,
        currentEdcStatus: _textControllers['current_edc_status']?.text,
        replacementSn: _textControllers['replacement_sn']?.text,
        replacementModel: _textControllers['replacement_model']?.text,
        hasLoss: _checklists['has_loss'] ?? false,
        lossNotes: _textControllers['loss_notes']?.text,
        userNotes: _textControllers['user_notes']?.text,
        keteranganGestun: _getKeteranganValue('keterangan_gestun'),
        keteranganPindahLokasi: _getKeteranganValue('keterangan_pindah_lokasi'),
        keteranganTutupPermanent: _getKeteranganValue('keterangan_tutup_permanent'),
        keteranganEdc: _getKeteranganValue('keterangan_edc'),
        keteranganFraud: _getKeteranganValue('keterangan_fraud'),
        keteranganQris: _getKeteranganValue('keterangan_qris'),
        keteranganDokumen: _getKeteranganValue('keterangan_dokumen'),
        urlEdc: _ticket?.urlEdc,
        urlMerchant: _ticket?.urlMerchant,
        urlSalesDraft: _ticket?.urlSalesDraft,
        urlPic: _ticket?.urlPic,
        
        // INSTALL
        insChkReaderEdc: _checklists['ins_chk_reader_edc'] ?? false,
        insChkSamCard: _checklists['ins_chk_sam_card'] ?? false,
        insChkSimCard: _checklists['ins_chk_sim_card'] ?? false,
        insChkStacker: _checklists['ins_chk_stacker'] ?? false,
        insChkThermalPaper: _checklists['ins_chk_thermal_paper'] ?? false,
        insChkPromoMaterial: _checklists['ins_chk_promo_material'] ?? false,
        insChkExtra: _checklists['ins_chk_extra'] ?? false,

        // PM
        pmChkEdc: _checklists['pm_chk_edc'] ?? false,
        pmChkSamCard: _checklists['pm_chk_sam_card'] ?? false,
        pmChkSimCard: _checklists['pm_chk_sim_card'] ?? false,
        pmChkCableEcr: _checklists['pm_chk_cable_ecr'] ?? false,
        pmChkAdapter: _checklists['pm_chk_adapter'] ?? false,
        pmChkThermalSupply: _checklists['pm_chk_thermal_supply'] ?? false,
        pmChkPromoMaterial: _checklists['pm_chk_promo_material'] ?? false,
        pmChkExtra: _checklists['pm_chk_extra'] ?? false,

        // CM
        cmChkEdc: _checklists['cm_chk_edc'] ?? false,
        cmChkSamCard: _checklists['cm_chk_sam_card'] ?? false,
        cmChkSimCard: _checklists['cm_chk_sim_card'] ?? false,
        cmChkCableEcr: _checklists['cm_chk_cable_ecr'] ?? false,
        cmChkAdapter: _checklists['cm_chk_adapter'] ?? false,
        cmChkThermalSupply: _checklists['cm_chk_thermal_supply'] ?? false,
        cmChkPromoMaterial: _checklists['cm_chk_promo_material'] ?? false,
        cmChkExtra: _checklists['cm_chk_extra'] ?? false,

        // PULLOUT
        puChkEdc: _checklists['pu_chk_edc'] ?? false,
        puChkSamCard: _checklists['pu_chk_sam_card'] ?? false,
        puChkSimCard: _checklists['pu_chk_sim_card'] ?? false,
        puChkPromoMaterial: _checklists['pu_chk_promo_material'] ?? false,
        puChkCableAdapter: _checklists['pu_chk_cable_adapter'] ?? false,
      );
      
      // Upload signatures if not empty
      if (_sigPicController.isNotEmpty) {
        final bytes = await _sigPicController.toPngBytes();
        if (bytes != null) {
           final filename = 'signature_pic/${widget.ticketId}.png'; 
           await _uploadFile(bytes, 'documents', filename); 
        }
      }

      if (_sigTeknisiController.isNotEmpty) {
        final bytes = await _sigTeknisiController.toPngBytes();
        if (bytes != null) {
           final filename = 'signature_teknisi/${widget.ticketId}.png'; 
           await _uploadFile(bytes, 'documents', filename);
        }
      }

      final success = await _ticketRepository.updateTicket(widget.ticketId, updatedTicket);
      
      if (mounted) {
        setState(() => _isSaving = false);
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tiket berhasil disimpan')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan tiket')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving ticket: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving ticket: $e')),
        );
      }
    }
  }
  
  String _getKeteranganValue(String key) {
    if (_keteranganValues[key] == 'Text') {
      return _textControllers[key]?.text ?? '';
    }
    return _keteranganValues[key] ?? 'Baik';
  }

  Future<String?> _uploadFile(Uint8List bytes, String bucket, String filename) async {
    try {
      final path = filename; // Filename includes folder e.g. "edc/T-123.jpg"
      
      await supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: const FileOptions(upsert: true),
      );
      
      // Get Public URL
      return supabase.storage.from(bucket).getPublicUrl(path);
    } catch (e) {
      debugPrint('Error uploading file to $bucket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFA6400),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             // Ticket Status & Priority Info
            _buildSectionCard(
              title: 'Informasi Tiket',
              icon: Icons.confirmation_number_outlined,
              child: Column(
                children: [
                   _buildInfoRow('ID Tiket', '#${_ticket?.ticketId ?? '-'}'),
                   const Divider(height: 24),
                   _buildInfoRow('Jenis (Type)', _ticket?.type ?? '-'),
                   const Divider(height: 24),
                   _buildInfoRow('Prioritas', _ticket?.priority ?? '-'),
                   const Divider(height: 24),
                   _buildVisitDateSection(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Merchant Info Card
            _buildSectionCard(
              title: 'Informasi Merchant',
              icon: Icons.store_mall_directory_rounded,
              child: Column(
                children: [
                   _buildInfoRow('Nama Merchant', _ticket?.merchant?['merchant_name'] ?? '-'),
                   const Divider(height: 24),
                   _buildInfoRow('Alamat', _ticket?.merchant?['address'] ?? '-'),
                   const Divider(height: 24),
                   _buildInfoRow('Kota', _ticket?.merchant?['city'] ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // General Details Card
            _buildSectionCard(
              title: 'Detail Kunjungan',
              icon: Icons.assignment_ind_outlined,
              child: Column(
                children: [
                  _buildTextField('Status BAST', 'bast_status'),
                  const SizedBox(height: 16),
                  _buildTextField('Kontak PIC', 'contact_phone'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('Latitude', 'latitude')),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField('Longitude', 'longitude')),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildSwitchTile('Test Transaksi', 'test_transaction'),
                  _buildSwitchTile('App Upgrade', 'app_upgrade'),
                  _buildSwitchTile('BNI Sales Slip', 'bni_sales_slip'),
                  _buildSwitchTile('BNI Standard Ack', 'bni_standard_ack'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // EDC Info Card
            _buildSectionCard(
              title: 'Informasi EDC',
              icon: Icons.developer_board,
              child: Column(
                children: [
                  _buildTextField('SN Saat Ini', 'current_sn'),
                  const SizedBox(height: 16),
                  _buildTextField('Status EDC Saat Ini', 'current_edc_status'),
                  const Divider(height: 32),
                  _buildTextField('SN Pengganti', 'replacement_sn'),
                  const SizedBox(height: 16),
                  _buildTextField('Model Pengganti', 'replacement_model'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Checklist Section
            _buildChecklistSection(),
            const SizedBox(height: 24),

            // Loss Section
            _buildSectionCard(
              title: 'Laporan Kehilangan',
              icon: Icons.report_problem_outlined,
              child: Column(
                children: [
                  _buildSwitchTile('Ada Kehilangan', 'has_loss'),
                  if (_checklists['has_loss'] == true) ...[
                    const SizedBox(height: 16),
                    _buildTextField('Catatan Kehilangan', 'loss_notes'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Notes
            _buildSectionCard(
              title: 'Catatan Teknisi',
              icon: Icons.note_add_outlined,
              child: _buildTextField('Catatan Tambahan', 'user_notes'),
            ),
            const SizedBox(height: 24),

            // Status Card
            _buildSectionCard(
              title: 'Update Status',
              icon: Icons.update,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                   color: Colors.grey[50], 
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: Colors.grey.shade300),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _status,
                    isExpanded: true,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: const Color(0xFF00529C)),
                    style: const TextStyle(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500),
                    items: ['OPEN', 'PENDING', 'CLOSED'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) setState(() => _status = newValue);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Keterangan Fields
            _buildSectionCard(
              title: 'Keterangan Kerusakan',
              icon: Icons.assignment_outlined,
              child: Column(
                children: [
                  _buildKeteranganField('Gestun', 'keterangan_gestun'),
                  const Divider(height: 32),
                  _buildKeteranganField('Pindah Lokasi', 'keterangan_pindah_lokasi'),
                  const Divider(height: 32),
                  _buildKeteranganField('Tutup Permanent', 'keterangan_tutup_permanent'),
                  const Divider(height: 32),
                  _buildKeteranganField('EDC', 'keterangan_edc'),
                  const Divider(height: 32),
                  _buildKeteranganField('Fraud', 'keterangan_fraud'),
                  const Divider(height: 32),
                  _buildKeteranganField('QRIS', 'keterangan_qris'),
                  const Divider(height: 32),
                  _buildKeteranganField('Dokumen', 'keterangan_dokumen'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Photos
            _buildSectionCard(
              title: 'Foto Dokumentasi',
              icon: Icons.camera_alt_outlined,
              child: Column(
                children: [
                  _buildPhotoUploader('Foto EDC', 'url_edc', 'documents', 'edc'),
                  const SizedBox(height: 24),
                  _buildPhotoUploader('Foto Merchant', 'url_merchant', 'documents', 'merchant'),
                  const SizedBox(height: 24),
                  _buildPhotoUploader('Sales Draft', 'url_sales_draft', 'documents', 'sales_draft'),
                  const SizedBox(height: 24),
                  _buildPhotoUploader('Foto PIC', 'url_pic', 'documents', 'pic'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Signatures
            _buildSectionCard(
              title: 'Tanda Tangan',
              icon: Icons.draw_outlined,
              child: Column(
                children: [
                   // Signatures don't have separate upload buttons, they save on "Save Changes"
                  _buildSignaturePad('Tanda Tangan PIC', _sigPicController),
                  const SizedBox(height: 24),
                  _buildSignaturePad('Tanda Tangan Teknisi', _sigTeknisiController),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveTicket,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00529C),
                  elevation: 4,
                  shadowColor: const Color(0xFF00529C).withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('SIMPAN PERUBAHAN', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00529C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF00529C), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold, 
                  color: Color(0xFF333333)
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120, 
          child: Text(
            label, 
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value, 
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKeteranganField(String label, String key) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87)),
        subtitle: Text(
          "Status: ${_keteranganValues[key] ?? '-'}",
          style: TextStyle(
            fontSize: 13,
            color: _keteranganValues[key] == 'Tidak Baik' ? Colors.red : Colors.grey[600],
            fontWeight: FontWeight.w500
          ),
        ),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 12),
        children: [
          Row(
            children: [
              _buildOptionButton(key, 'Baik'),
              const SizedBox(width: 8),
              _buildOptionButton(key, 'Tidak Baik'),
              const SizedBox(width: 8),
              _buildOptionButton(key, 'Text'),
            ],
          ),
          if (_keteranganValues[key] == 'Text') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _textControllers[key],
              decoration: InputDecoration(
                hintText: 'Masukkan keterangan...',
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionButton(String key, String value) {
    final isSelected = _keteranganValues[key] == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _keteranganValues[key] = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00529C) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF00529C) : Colors.grey.shade300,
            ),
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key) {
    return TextField(
      controller: _textControllers[key],
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSwitchTile(String label, String key) {
    return SwitchListTile(
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      value: _checklists[key] ?? false,
      onChanged: (val) => setState(() => _checklists[key] = val),
      contentPadding: EdgeInsets.zero,
      activeColor: const Color(0xFFFA6400),
    );
  }

  Widget _buildChecklistTile(String label, String key) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: _checklists[key] ?? false,
      onChanged: (val) => setState(() => _checklists[key] = val ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: const Color(0xFFFA6400),
    );
  }

  Widget _buildVisitDateSection() {
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _visitDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (date != null) setState(() => _visitDate = date);
      },
      child: _buildInfoRow(
        'Tanggal Kunjungan',
        _visitDate != null ? _visitDate!.toIso8601String().split('T')[0] : 'Pilih Tanggal',
      ),
    );
  }

  Widget _buildChecklistSection() {
    if (_ticket == null) return const SizedBox.shrink();
    
    String title = 'Checklist Terintegrasi';
    List<Widget> items = [];

    if (_ticket!.type == 'INSTALL') {
      title = 'Checklist Pemasangan (INSTALL)';
      items = [
        _buildChecklistTile('Reader EDC', 'ins_chk_reader_edc'),
        _buildChecklistTile('SAM Card', 'ins_chk_sam_card'),
        _buildChecklistTile('SIM Card', 'ins_chk_sim_card'),
        _buildChecklistTile('Stacker', 'ins_chk_stacker'),
        _buildChecklistTile('Thermal Paper', 'ins_chk_thermal_paper'),
        _buildChecklistTile('Promo Material', 'ins_chk_promo_material'),
        _buildChecklistTile('Extra', 'ins_chk_extra'),
      ];
    } else if (_ticket!.type == 'PM') {
      title = 'Checklist Maintenance (PM)';
      items = [
        _buildChecklistTile('EDC', 'pm_chk_edc'),
        _buildChecklistTile('SAM Card', 'pm_chk_sam_card'),
        _buildChecklistTile('SIM Card', 'pm_chk_sim_card'),
        _buildChecklistTile('Cable ECR', 'pm_chk_cable_ecr'),
        _buildChecklistTile('Adapter', 'pm_chk_adapter'),
        _buildChecklistTile('Thermal Supply', 'pm_chk_thermal_supply'),
        _buildChecklistTile('Promo Material', 'pm_chk_promo_material'),
        _buildChecklistTile('Extra', 'pm_chk_extra'),
      ];
    } else if (_ticket!.type == 'CM') {
      title = 'Checklist Perbaikan (CM)';
      items = [
        _buildChecklistTile('EDC', 'cm_chk_edc'),
        _buildChecklistTile('SAM Card', 'cm_chk_sam_card'),
        _buildChecklistTile('SIM Card', 'cm_chk_sim_card'),
        _buildChecklistTile('Cable ECR', 'cm_chk_cable_ecr'),
        _buildChecklistTile('Adapter', 'cm_chk_adapter'),
        _buildChecklistTile('Thermal Supply', 'cm_chk_thermal_supply'),
        _buildChecklistTile('Promo Material', 'cm_chk_promo_material'),
        _buildChecklistTile('Extra', 'cm_chk_extra'),
      ];
    } else if (_ticket!.type == 'PULLOUT') {
      title = 'Checklist Penarikan (PULLOUT)';
      items = [
        _buildChecklistTile('EDC', 'pu_chk_edc'),
        _buildChecklistTile('SAM Card', 'pu_chk_sam_card'),
        _buildChecklistTile('SIM Card', 'pu_chk_sim_card'),
        _buildChecklistTile('Promo Material', 'pu_chk_promo_material'),
        _buildChecklistTile('Cable Adapter', 'pu_chk_cable_adapter'),
      ];
    }

    return _buildSectionCard(
      title: title,
      icon: Icons.checklist_rtl_rounded,
      child: Column(children: items),
    );
  }

  Widget _buildPhotoUploader(String label, String columnKey, String bucket, String folder) {
    String? imageUrl;
    if (columnKey == 'url_edc') imageUrl = _ticket?.urlEdc;
    else if (columnKey == 'url_merchant') imageUrl = _ticket?.urlMerchant;
    else if (columnKey == 'url_sales_draft') imageUrl = _ticket?.urlSalesDraft;
    else if (columnKey == 'url_pic') imageUrl = _ticket?.urlPic;

    final hasImage = imageUrl != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 10),
        InkWell(
          onTap: () => _pickAndUploadImage(columnKey, bucket, folder),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: hasImage ? Colors.transparent : Colors.grey[50],
              borderRadius: BorderRadius.circular(16),
              border: hasImage ? null : Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
              image: hasImage ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: hasImage 
                ? Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                      ),
                    ),
                    alignment: Alignment.bottomRight,
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: Icon(Icons.edit, size: 20, color: const Color(0xFF00529C)),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00529C).withValues(alpha: 0.05),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.camera_alt_outlined, size: 30, color: const Color(0xFF00529C)),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Ketuk untuk ambil foto",
                        style: TextStyle(color: const Color(0xFF00529C), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _pickAndUploadImage(String columnKey, String bucket, String folder) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    
    if (pickedFile != null) {
      final filename = '$folder/${widget.ticketId}.jpg';
      final bytes = await pickedFile.readAsBytes();
      
      final url = await _uploadFile(bytes, bucket, filename);
       if (url != null) {
        if (mounted) {
           setState(() {
             if (columnKey == 'url_edc') {
               _ticket = Ticket.fromJson({..._ticket!.toJson(), 'url_edc': url});
             } else if (columnKey == 'url_merchant') {
               _ticket = Ticket.fromJson({..._ticket!.toJson(), 'url_merchant': url});
             } else if (columnKey == 'url_sales_draft') {
               _ticket = Ticket.fromJson({..._ticket!.toJson(), 'url_sales_draft': url});
             } else if (columnKey == 'url_pic') {
               _ticket = Ticket.fromJson({..._ticket!.toJson(), 'url_pic': url});
             }
           });
        }
      }
    }
  }

  // Signature builder mostly same basics but modernized style
  Widget _buildSignaturePad(String label, SignatureController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            InkWell(
              onTap: () => controller.clear(),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Text('Hapus', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Signature(
              controller: controller,
              height: 180,
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }
}
