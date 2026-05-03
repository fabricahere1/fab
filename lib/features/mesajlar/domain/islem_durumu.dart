import "package:flutter/material.dart";
// lib/features/mesajlar/domain/islem_durumu.dart

enum IslemDurumu {
  iletisimBasladi,
  anlasildi,
  siparisVerildi, // Sadece tasiyici ilanlari icin (alici urun secti)
  urunAlindi,     // Sadece tasiyici ilanlari icin (tasiyici satin aldi)
  yolaCikti,
  teslimEdildi,
  teslimAlindi,
}

extension IslemDurumuX on IslemDurumu {
  String get etiket {
    switch (this) {
      case IslemDurumu.iletisimBasladi: return 'İletişime Geçildi';
      case IslemDurumu.anlasildi:       return 'Anlaşıldı';
      case IslemDurumu.siparisVerildi:  return 'Sipariş Verildi';
      case IslemDurumu.urunAlindi:      return 'Ürün Satın Alındı';
      case IslemDurumu.yolaCikti:       return 'Yola Çıktı';
      case IslemDurumu.teslimEdildi:    return 'Teslim Edildi';
      case IslemDurumu.teslimAlindi:    return 'Teslim Alındı';
    }
  }

  String get firestoreKey {
    switch (this) {
      case IslemDurumu.iletisimBasladi: return 'iletisimBasladi';
      case IslemDurumu.anlasildi:       return 'anlasildi';
      case IslemDurumu.siparisVerildi:  return 'siparisVerildi';
      case IslemDurumu.urunAlindi:      return 'urunAlindi';
      case IslemDurumu.yolaCikti:       return 'yolaCikti';
      case IslemDurumu.teslimEdildi:    return 'teslimEdildi';
      case IslemDurumu.teslimAlindi:    return 'teslimAlindi';
    }
  }

  IconData get ikon {
    switch (this) {
      case IslemDurumu.iletisimBasladi: return Icons.chat_bubble_outline;
      case IslemDurumu.anlasildi:       return Icons.handshake_outlined;
      case IslemDurumu.siparisVerildi:  return Icons.shopping_cart_outlined;
      case IslemDurumu.urunAlindi:      return Icons.shopping_bag_outlined;
      case IslemDurumu.yolaCikti:       return Icons.flight_takeoff_outlined;
      case IslemDurumu.teslimEdildi:    return Icons.inventory_2_outlined;
      case IslemDurumu.teslimAlindi:    return Icons.check_circle_outline;
    }
  }

  // ilanSahibiMi: true = ilan sahibi isaretler, false = karsi taraf, null = otomatik
  // istek ilani: ilan sahibi = isteyen/alici
  // tasiyici ilani: ilan sahibi = tasiyici
  // Bu sayede her iki tipte de panel dogru calısır
  bool? get ilanSahibiMi {
    switch (this) {
      case IslemDurumu.iletisimBasladi: return null;   // otomatik
      case IslemDurumu.anlasildi:       return null;   // otomatik
      case IslemDurumu.siparisVerildi:  return false;  // istek ilani: alici=karsitaraf | tasiyici ilani: alici=karsitaraf ✓
      case IslemDurumu.urunAlindi:      return true;   // istek ilani: - | tasiyici ilani: tasiyici=ilanSahibi ✓
      case IslemDurumu.yolaCikti:       return true;   // istek ilani: tasiyici=karsitaraf❌ | tasiyici ilani: tasiyici=ilanSahibi ✓
      case IslemDurumu.teslimEdildi:    return true;   // ayni sekilde
      case IslemDurumu.teslimAlindi:    return false;  // her iki tipte alici isaretler ✓
    }
  }

  // istek ilani icin ayri kontrol
  bool? ilanSahibiMiForTip(String ilanTip) {
    // tasiyici ilani: ilanSahibi = tasiyici
    // istek ilani: ilanSahibi = isteyen/alici, karsi taraf = tasiyici
    if (ilanTip == 'tasiyici') {
      return ilanSahibiMi; // ilanSahibi tasiyici, dogru
    } else {
      // istek ilani: rolleri cevir — ilanSahibi=alici, karsitaraf=tasiyici
      switch (this) {
        case IslemDurumu.iletisimBasladi: return null;
        case IslemDurumu.anlasildi:       return null;
        case IslemDurumu.siparisVerildi:  return null; // istek ilaninda bu adim yok
        case IslemDurumu.urunAlindi:      return null; // istek ilaninda bu adim yok
        case IslemDurumu.yolaCikti:       return false; // karsitaraf=tasiyici isaretler
        case IslemDurumu.teslimEdildi:    return false; // karsitaraf=tasiyici isaretler
        case IslemDurumu.teslimAlindi:    return true;  // ilanSahibi=alici isaretler
      }
    }
  }

  String kimYaparForTip(String ilanTip) {
    final kim = ilanSahibiMiForTip(ilanTip);
    if (ilanTip == 'tasiyici') {
      switch (kim) {
        case true:  return 'Taşıyıcı işaretler';
        case false: return 'Alıcı işaretler';
        case null:  return 'Otomatik';
      }
    } else {
      switch (kim) {
        case false: return 'Taşıyıcı işaretler';
        case true:  return 'Alıcı işaretler';
        case null:  return 'Otomatik';
      }
    }
  }
}

// İlan tipine gore adim listesi
class IlanTipiAdimlar {
  // istek ilani: biri bir urun istiyor, tasiyici goturuyor
  static const List<IslemDurumu> istek = [
    IslemDurumu.iletisimBasladi,
    IslemDurumu.anlasildi,
    IslemDurumu.yolaCikti,
    IslemDurumu.teslimEdildi,
    IslemDurumu.teslimAlindi,
  ];

  // tasiyici ilani: tasiyici geliyor, alici siparis veriyor
  static const List<IslemDurumu> tasiyici = [
    IslemDurumu.iletisimBasladi,
    IslemDurumu.anlasildi,
    IslemDurumu.siparisVerildi,
    IslemDurumu.urunAlindi,
    IslemDurumu.yolaCikti,
    IslemDurumu.teslimEdildi,
    IslemDurumu.teslimAlindi,
  ];

  static List<IslemDurumu> forTip(String ilanTip) {
    return ilanTip == 'tasiyici' ? tasiyici : istek;
  }
}