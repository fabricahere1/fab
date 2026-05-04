import "package:flutter/material.dart";

enum IslemDurumu {
  iletisimBasladi,
  anlasildi,
  siparisVerildi,
  urunAlindi,
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

  // Banner metni için — "xxx ilanınızı yola çıktığını onayladı" gibi
  String get gecmisDonusu {
    switch (this) {
      case IslemDurumu.iletisimBasladi: return 'iletişime geçtiğini onayladı';
      case IslemDurumu.anlasildi:       return 'anlaşıldığını onayladı';
      case IslemDurumu.siparisVerildi:  return 'sipariş verdiğini onayladı';
      case IslemDurumu.urunAlindi:      return 'ürünü satın aldığını onayladı';
      case IslemDurumu.yolaCikti:       return 'yola çıktığını onayladı';
      case IslemDurumu.teslimEdildi:    return 'teslim ettiğini onayladı';
      case IslemDurumu.teslimAlindi:    return 'teslim aldığını onayladı';
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

  String anlasildiKey(String uid) => 'anlasildi_$uid';

  bool get ikiTarafliMi => this == IslemDurumu.anlasildi;

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

  bool? get ilanSahibiMi {
    switch (this) {
      case IslemDurumu.iletisimBasladi: return null;
      case IslemDurumu.anlasildi:       return null;
      case IslemDurumu.siparisVerildi:  return false;
      case IslemDurumu.urunAlindi:      return true;
      case IslemDurumu.yolaCikti:       return true;
      case IslemDurumu.teslimEdildi:    return true;
      case IslemDurumu.teslimAlindi:    return false;
    }
  }

  bool? ilanSahibiMiForTip(String ilanTip) {
    if (ilanTip == 'tasiyici') {
      return ilanSahibiMi;
    } else {
      switch (this) {
        case IslemDurumu.iletisimBasladi: return null;
        case IslemDurumu.anlasildi:       return null;
        case IslemDurumu.siparisVerildi:  return null;
        case IslemDurumu.urunAlindi:      return null;
        case IslemDurumu.yolaCikti:       return false;
        case IslemDurumu.teslimEdildi:    return false;
        case IslemDurumu.teslimAlindi:    return true;
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

class IlanTipiAdimlar {
  static const List<IslemDurumu> istek = [
    IslemDurumu.iletisimBasladi,
    IslemDurumu.anlasildi,
    IslemDurumu.yolaCikti,
    IslemDurumu.teslimEdildi,
    IslemDurumu.teslimAlindi,
  ];

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