// lib/features/degerlendirme/providers/degerlendirme_provider.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'degerlendirme_provider.g.dart';

// İşlem durumlarını dinler - sohbet ekranı için
@riverpod
Stream<Map<String, dynamic>> sohbetDurumu(Ref ref, String sohbetId) {
  return FirebaseFirestore.instance
      .collection('sohbetler')
      .doc(sohbetId)
      .snapshots()
      .map((doc) {
    if (!doc.exists) return {};
    return Map<String, dynamic>.from(doc.data() ?? {});
  });
}
