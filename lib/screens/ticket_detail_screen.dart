import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:signature/signature.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic>? _ticket;

  // Form Controllers
  final Map<String, TextEditingController> _textControllers = {};
  final Map<String, String> _keteranganValues = {};
  String _status = 'OPEN';
  
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
      final response = await supabase
          .from('tickets')
          .select('*, merchants(*)')
          .eq('ticket_id', widget.ticketId)
          .single();

      if (mounted) {
        setState(() {
          _ticket = response;
          _status = response['status'] ?? 'OPEN';
          _initializeKeteranganField('keterangan_gestun');
          _initializeKeteranganField('keterangan_pindah_lokasi');
          _initializeKeteranganField('keterangan_tutup_permanent');
          _initializeKeteranganField('keterangan_edc');
          _initializeKeteranganField('keterangan_fraud');
          _initializeKeteranganField('keterangan_qris');
          _initializeKeteranganField('keterangan_dokumen');
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

  void _initializeKeteranganField(String key) {
    final value = _ticket?[key] as String?;
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
    setState(() => _isSaving = true);
    try {
      final updates = <String, dynamic>{
        'status': _status,
        'keterangan_gestun': _getKeteranganValue('keterangan_gestun'),
        'keterangan_pindah_lokasi': _getKeteranganValue('keterangan_pindah_lokasi'),
        'keterangan_tutup_permanent': _getKeteranganValue('keterangan_tutup_permanent'),
        'keterangan_edc': _getKeteranganValue('keterangan_edc'),
        'keterangan_fraud': _getKeteranganValue('keterangan_fraud'),
        'keterangan_qris': _getKeteranganValue('keterangan_qris'),
        'keterangan_dokumen': _getKeteranganValue('keterangan_dokumen'),
        'url_edc': _ticket?['url_edc'],
        'url_merchant': _ticket?['url_merchant'],
        'url_sales_draft': _ticket?['url_sales_draft'],
        'url_pic': _ticket?['url_pic'],
      };
      
      // Upload signatures if not empty
      if (_sigPicController.isNotEmpty) {
        final bytes = await _sigPicController.toPngBytes();
        if (bytes != null) {
           // Signature PIC -> documents/signature_pic/[ticket_id].png
           final filename = 'signature_pic/${widget.ticketId}.png'; 
           await _uploadFile(bytes, 'documents', filename); 
           // Note: We don't save the URL to a column because there's no explicit column for it 
           // based on current schema understanding, but the file is safely in the bucket.
           // If we need to save it, we would add it to `updates` here if a column existed.
        }
      }

      if (_sigTeknisiController.isNotEmpty) {
        final bytes = await _sigTeknisiController.toPngBytes();
        if (bytes != null) {
           // Signature Teknisi -> documents/signature_teknisi/[ticket_id].png
           final filename = 'signature_teknisi/${widget.ticketId}.png'; 
           await _uploadFile(bytes, 'documents', filename);
        }
      }

      await supabase.from('tickets').update(updates).eq('ticket_id', widget.ticketId);
      
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tiket berhasil disimpan')),
        );
        Navigator.pop(context); // Go back
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

    final merchant = _ticket?['merchants'];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Detail Tiket'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF00529C),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Merchant Info Card
            _buildSectionCard(
              title: 'Informasi Merchant',
              icon: Icons.store_mall_directory_rounded,
              child: Column(
                children: [
                   _buildInfoRow('Nama Merchant', merchant?['merchant_name'] ?? '-'),
                   const Divider(height: 24),
                   _buildInfoRow('Alamat', merchant?['address'] ?? '-'),
                   const Divider(height: 24),
                   _buildInfoRow('Kota', merchant?['city'] ?? '-'),
                ],
              ),
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
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF00529C)),
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

  Widget _buildPhotoUploader(String label, String columnKey, String bucket, String folder) {
    final hasImage = _ticket?[columnKey] != null;
    
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
                image: NetworkImage(_ticket![columnKey]),
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
                      child: const Icon(Icons.edit, size: 20, color: Color(0xFF00529C)),
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
                        child: const Icon(Icons.camera_alt_outlined, size: 30, color: Color(0xFF00529C)),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Ketuk untuk ambil foto",
                        style: TextStyle(color: Color(0xFF00529C), fontWeight: FontWeight.w500),
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
      // Filename convention: folder/ticket_id.jpg
      final filename = '$folder/${widget.ticketId}.jpg';
      final bytes = await pickedFile.readAsBytes();
      
      final url = await _uploadFile(bytes, bucket, filename);
       if (url != null) {
        if (mounted) {
           setState(() {
             _ticket?[columnKey] = url;
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
