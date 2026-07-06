// lib/core/firebase/app_firestore.dart
//
// Uygulamanın kullandığı Firestore veritabanı burada TEK YERDEN
// tanımlanır. "iste-eu" ismini değiştirmen gerekirse sadece burayı
// değiştirmen yeterli — tüm repository/servis dosyaları bunu kullanıyor.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AppFirestore {
  static const String databaseId = 'iste-eu';

  static FirebaseFirestore get instance =>
      FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: databaseId,
      );
}