import 'dart:convert';

class Ticket {
  final String ticketId;
  final String status;
  final String type;
  final String? priority;
  
  // New General Fields
  final String? latitude;
  final String? longitude;
  final DateTime? visitDate;
  final bool testTransaction;
  final bool appUpgrade;
  final String? bastStatus;
  final String? contactPhone;
  final bool bniSalesSlip;
  final bool bniStandardAck;
  final String? currentSn;
  final String? currentEdcStatus;
  final String? replacementSn;
  final String? replacementModel;
  final bool hasLoss;
  final String? lossNotes;
  final String? userNotes;

  // Existing Keterangan Fields
  final String? keteranganGestun;
  final String? keteranganPindahLokasi;
  final String? keteranganTutupPermanent;
  final String? keteranganEdc;
  final String? keteranganFraud;
  final String? keteranganQris;
  final String? keteranganDokumen;

  // Photo URLs
  final String? urlEdc;
  final String? urlMerchant;
  final String? urlSalesDraft;
  final String? urlPic;

  // INSTALL Checklist
  final bool insChkReaderEdc;
  final bool insChkSamCard;
  final bool insChkSimCard;
  final bool insChkStacker;
  final bool insChkThermalPaper;
  final bool insChkPromoMaterial;
  final bool insChkExtra;

  // PM Checklist
  final bool pmChkEdc;
  final bool pmChkSamCard;
  final bool pmChkSimCard;
  final bool pmChkCableEcr;
  final bool pmChkAdapter;
  final bool pmChkThermalSupply;
  final bool pmChkPromoMaterial;
  final bool pmChkExtra;

  // CM Checklist
  final bool cmChkEdc;
  final bool cmChkSamCard;
  final bool cmChkSimCard;
  final bool cmChkCableEcr;
  final bool cmChkAdapter;
  final bool cmChkThermalSupply;
  final bool cmChkPromoMaterial;
  final bool cmChkExtra;

  // PULLOUT Checklist
  final bool puChkEdc;
  final bool puChkSamCard;
  final bool puChkSimCard;
  final bool puChkPromoMaterial;
  final bool puChkCableAdapter;

  // Merchant Relation
  final Map<String, dynamic>? merchant;

  Ticket({
    required this.ticketId,
    required this.status,
    required this.type,
    this.priority,
    this.latitude,
    this.longitude,
    this.visitDate,
    this.testTransaction = false,
    this.appUpgrade = false,
    this.bastStatus,
    this.contactPhone,
    this.bniSalesSlip = false,
    this.bniStandardAck = false,
    this.currentSn,
    this.currentEdcStatus,
    this.replacementSn,
    this.replacementModel,
    this.hasLoss = false,
    this.lossNotes,
    this.userNotes,
    this.keteranganGestun,
    this.keteranganPindahLokasi,
    this.keteranganTutupPermanent,
    this.keteranganEdc,
    this.keteranganFraud,
    this.keteranganQris,
    this.keteranganDokumen,
    this.urlEdc,
    this.urlMerchant,
    this.urlSalesDraft,
    this.urlPic,
    this.insChkReaderEdc = false,
    this.insChkSamCard = false,
    this.insChkSimCard = false,
    this.insChkStacker = false,
    this.insChkThermalPaper = false,
    this.insChkPromoMaterial = false,
    this.insChkExtra = false,
    this.pmChkEdc = false,
    this.pmChkSamCard = false,
    this.pmChkSimCard = false,
    this.pmChkCableEcr = false,
    this.pmChkAdapter = false,
    this.pmChkThermalSupply = false,
    this.pmChkPromoMaterial = false,
    this.pmChkExtra = false,
    this.cmChkEdc = false,
    this.cmChkSamCard = false,
    this.cmChkSimCard = false,
    this.cmChkCableEcr = false,
    this.cmChkAdapter = false,
    this.cmChkThermalSupply = false,
    this.cmChkPromoMaterial = false,
    this.cmChkExtra = false,
    this.puChkEdc = false,
    this.puChkSamCard = false,
    this.puChkSimCard = false,
    this.puChkPromoMaterial = false,
    this.puChkCableAdapter = false,
    this.merchant,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    // Check for legacy notes JSON
    Map<String, dynamic> notes = {};
    if (json['notes'] != null && json['notes'] is String) {
      try {
        notes = jsonDecode(json['notes']);
      } catch (_) {}
    } else if (json['notes'] != null && json['notes'] is Map) {
      notes = Map<String, dynamic>.from(json['notes']);
    }

    bool getVal(String key, bool defaultValue) {
      return json[key] ?? notes[key] ?? defaultValue;
    }

    String? getString(String key) {
      return json[key]?.toString() ?? notes[key]?.toString();
    }

    return Ticket(
      ticketId: json['ticket_id'] ?? '',
      status: json['status'] ?? 'OPEN',
      type: json['type'] ?? 'INSTALL',
      priority: json['priority'],
      latitude: getString('latitude'),
      longitude: getString('longitude'),
      visitDate: json['visit_date'] != null ? DateTime.parse(json['visit_date']) : null,
      testTransaction: getVal('test_transaction', false),
      appUpgrade: getVal('app_upgrade', false),
      bastStatus: getString('bast_status'),
      contactPhone: getString('contact_phone'),
      bniSalesSlip: getVal('bni_sales_slip', false),
      bniStandardAck: getVal('bni_standard_ack', false),
      currentSn: getString('current_sn'),
      currentEdcStatus: getString('current_edc_status'),
      replacementSn: getString('replacement_sn'),
      replacementModel: getString('replacement_model'),
      hasLoss: getVal('has_loss', false),
      lossNotes: getString('loss_notes'),
      userNotes: getString('user_notes'),
      keteranganGestun: getString('keterangan_gestun'),
      keteranganPindahLokasi: getString('keterangan_pindah_lokasi'),
      keteranganTutupPermanent: getString('keterangan_tutup_permanent'),
      keteranganEdc: getString('keterangan_edc'),
      keteranganFraud: getString('keterangan_fraud'),
      keteranganQris: getString('keterangan_qris'),
      keteranganDokumen: getString('keterangan_dokumen'),
      urlEdc: getString('url_edc'),
      urlMerchant: getString('url_merchant'),
      urlSalesDraft: getString('url_sales_draft'),
      urlPic: getString('url_pic'),
      
      // INSTALL
      insChkReaderEdc: getVal('ins_chk_reader_edc', false),
      insChkSamCard: getVal('ins_chk_sam_card', false),
      insChkSimCard: getVal('ins_chk_sim_card', false),
      insChkStacker: getVal('ins_chk_stacker', false),
      insChkThermalPaper: getVal('ins_chk_thermal_paper', false),
      insChkPromoMaterial: getVal('ins_chk_promo_material', false),
      insChkExtra: getVal('ins_chk_extra', false),

      // PM
      pmChkEdc: getVal('pm_chk_edc', false),
      pmChkSamCard: getVal('pm_chk_sam_card', false),
      pmChkSimCard: getVal('pm_chk_sim_card', false),
      pmChkCableEcr: getVal('pm_chk_cable_ecr', false),
      pmChkAdapter: getVal('pm_chk_adapter', false),
      pmChkThermalSupply: getVal('pm_chk_thermal_supply', false),
      pmChkPromoMaterial: getVal('pm_chk_promo_material', false),
      pmChkExtra: getVal('pm_chk_extra', false),

      // CM
      cmChkEdc: getVal('cm_chk_edc', false),
      cmChkSamCard: getVal('cm_chk_sam_card', false),
      cmChkSimCard: getVal('cm_chk_sim_card', false),
      cmChkCableEcr: getVal('cm_chk_cable_ecr', false),
      cmChkAdapter: getVal('cm_chk_adapter', false),
      cmChkThermalSupply: getVal('cm_chk_thermal_supply', false),
      cmChkPromoMaterial: getVal('cm_chk_promo_material', false),
      cmChkExtra: getVal('cm_chk_extra', false),

      // PULLOUT
      puChkEdc: getVal('pu_chk_edc', false),
      puChkSamCard: getVal('pu_chk_sam_card', false),
      puChkSimCard: getVal('pu_chk_sim_card', false),
      puChkPromoMaterial: getVal('pu_chk_promo_material', false),
      puChkCableAdapter: getVal('pu_chk_cable_adapter', false),
      
      merchant: json['merchants'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'visit_date': visitDate?.toIso8601String(),
      'test_transaction': testTransaction,
      'app_upgrade': appUpgrade,
      'bast_status': bastStatus,
      'contact_phone': contactPhone,
      'bni_sales_slip': bniSalesSlip,
      'bni_standard_ack': bniStandardAck,
      'current_sn': currentSn,
      'current_edc_status': currentEdcStatus,
      'replacement_sn': replacementSn,
      'replacement_model': replacementModel,
      'has_loss': hasLoss,
      'loss_notes': lossNotes,
      'user_notes': userNotes,
      'keterangan_gestun': keteranganGestun,
      'keterangan_pindah_lokasi': keteranganPindahLokasi,
      'keterangan_tutup_permanent': keteranganTutupPermanent,
      'keterangan_edc': keteranganEdc,
      'keterangan_fraud': keteranganFraud,
      'keterangan_qris': keteranganQris,
      'keterangan_dokumen': keteranganDokumen,
      'url_edc': urlEdc,
      'url_merchant': urlMerchant,
      'url_sales_draft': urlSalesDraft,
      'url_pic': urlPic,
      'ins_chk_reader_edc': insChkReaderEdc,
      'ins_chk_sam_card': insChkSamCard,
      'ins_chk_sim_card': insChkSimCard,
      'ins_chk_stacker': insChkStacker,
      'ins_chk_thermal_paper': insChkThermalPaper,
      'ins_chk_promo_material': insChkPromoMaterial,
      'ins_chk_extra': insChkExtra,
      'pm_chk_edc': pmChkEdc,
      'pm_chk_sam_card': pmChkSamCard,
      'pm_chk_sim_card': pmChkSimCard,
      'pm_chk_cable_ecr': pmChkCableEcr,
      'pm_chk_adapter': pmChkAdapter,
      'pm_chk_thermal_supply': pmChkThermalSupply,
      'pm_chk_promo_material': pmChkPromoMaterial,
      'pm_chk_extra': pmChkExtra,
      'cm_chk_edc': cmChkEdc,
      'cm_chk_sam_card': cmChkSamCard,
      'cm_chk_sim_card': cmChkSimCard,
      'cm_chk_cable_ecr': cmChkCableEcr,
      'cm_chk_adapter': cmChkAdapter,
      'cm_chk_thermal_supply': cmChkThermalSupply,
      'cm_chk_promo_material': cmChkPromoMaterial,
      'cm_chk_extra': cmChkExtra,
      'pu_chk_edc': puChkEdc,
      'pu_chk_sam_card': puChkSamCard,
      'pu_chk_sim_card': pu_chk_sim_card,
      'pu_chk_promo_material': pu_chk_promo_material,
      'pu_chk_cable_adapter': pu_chk_cable_adapter,
    };
  }
}
