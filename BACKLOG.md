# Backlog

Bu dosya, launch öncesi taramalarda (`SON_TARAMA.md`, `EXTREME_TARAMA.md`)
bulunan ama launch'ı engellemeyen maddeleri topluyor. Hiçbiri kritik değil —
sıralama, launch sonrası hangisine önce bakılacağını netleştirmek için.

---

## Launch sonrası ilk hafta — kullanıcı etkisi gerçek

- **hesapSilSunucu / `degerlendirmeler` koleksiyonu temizlenmiyor**
  Kullanıcı hesabını silince verdiği/aldığı değerlendirmeler Firestore'da
  kalıcı kalıyor ("hayalet" kayıt). Gizlilik politikası metniyle çelişiyor
  olabilir, hesap silme özelliği kullanıldıkça birikir.
  **Not:** Düzeltme denenmiş ama DURDURULMUŞTU — `degerlendirmePuanGuncelle`
  yalnızca `onDocumentCreated`, silinme için bir fan-out (karşı tarafın
  `ortalamaPuan`ını yeniden hesaplayan mekanizma) yok. Önce bu fan-out
  eklenmeli, ancak ondan sonra değerlendirmeler güvenle silinebilir. Detay:
  önceki "hesapSilSunucu — degerlendirmeler koleksiyonunu da temizle" görev
  raporunda.
  Kaynak: `functions/src/index.ts:869-932` (hesapSilSunucu), `:770-810`
  (degerlendirmePuanGuncelle).

- **App Check**
  Zaten "Play Store yayını sonrası" olarak zamanlanmıştı — launch olur
  olmaz kontrol edilmeli (`main.dart`'taki `AndroidProvider.debug` →
  `playIntegrity` geçişinin gerçek cihazda/prod'da düzgün çalıştığını
  doğrulama).

---

## Orta vadede — birikimli teknik borç, aceleye gerek yok

- **Test kapsamı** — şu an yalnızca `sohbet_model_test.dart` var
  (`okunmamisSayisi`/`gizliMi`, 10 test). Kritik iş mantığının geri kalanı
  (ilan moderasyonu, takip/favori optimistik güncellemeler, sıralama
  mantığı) test edilmiyor. Haftalar içinde parça parça eklenebilir.

- **Orphan dosya/sınıf taraması (proje geneli)** — `EXTREME_TARAMA.md`'de
  C6 olarak "İNCELENMEDİ" işaretlenmişti. Önceki turlarda 5 dosya
  bulunup silinmişti ama bu, proje genelinde eksiksiz bir tarama değildi.

- **go_router güncellemesi** — `ilan_karti.dart`/`ilanDetay` rotası
  `CupertinoPage`'e standartlaştırıldı, ama diğer rotaların (`ilan-olustur/*`
  dışındakiler) aynı standarda uyup uymadığı tam taranmadı. Kayıt dışı
  ~22 ekranın (bkz. `SON_TARAMA.md` C7) navigasyon tutarlılığı da buraya
  dahil edilebilir.

---

## Düşük öncelik — isteğe bağlı cila

- **"Tekrar Yayınla" sonrası `olusturmaTarihi` davranışı** — yeniden
  yayınlanan bir ilan, eski oluşturma tarihiyle kalıyor, "En Yeni"
  sıralamasında öne çıkmıyor. Kullanıcı deneyimini gerçek anlamda
  bozmuyor, tasarım kararı da olabilir.

- **`ilanTip` guard eksikliği** — `mesaj_repository.dart:135`, `'ilanTip':
  ilanTip` koşulsuz yazılıyor (diğer "İlan meta" alanlarinin aksine, boşsa
  ezmeme koruması yok). Bugünkü tüm gerçek çağıranlar parametreyi doğru
  geçiyor (doğrulandı), risk yalnızca yapısal/gelecekteki bir çağırana
  karşı.

- **CachedNetworkImage — kalan küçük konumlar** — `kesfet_bolum_detay_screen.dart`,
  `ilan_form_screen.dart`, `kullanici_profil_screen.dart`, `swipe_karti.dart`
  ve `ilan_detay_screen.dart:1269` (geçici placeholder) hâlâ memCacheWidth/
  Height'sız. Ana ekranlar (Keşfet, Sana Özel, İlanlar, Gelenler, İlanlarım,
  Favoriler, Sohbet, İlan Detayı'nın çoğu) zaten düzeltildi.

---

## Hiç bakılmamış — ayrı bir "ikinci tur ekstrem tarama" gerektirir

`EXTREME_TARAMA.md`'de açıkça "İNCELENMEDİ" işaretlenmiş bölümler, hiçbiri
şu an "temiz" olarak doğrulanmadı, yalnızca bu tura sığmadı:

- **B3** — Gereksiz rebuild riskleri
- **B4** — Ana thread'i bloklayabilecek senkron/ağır işlemler
- **C5** — Kod tekrarı (proje geneli, `kullaniciBilgi`/`kullaniciBilgisi`
  dışında)
- **C7** — Dispose edilmeyen `AnimationController`/`ScrollController`/
  `StreamSubscription`
- **D1** — Firestore yazma/okuma tip uyumsuzluğu
- **D2** — Cloud Functions ↔ client modelleri arası isim/tip uyuşmazlığı
- **E1** — Aynı işlevi gören ama farklı görünen bileşenler
- **E2** — Hata mesajlarının gösterilme şekli tutarlılığı
- **E3** — Boş durum (empty state) ekranlarının varlığı/tutarlılığı
- **F1** — `pubspec.yaml` paket sürümleri, majör sürüm geride olanlar
- **F2** — `functions/package.json` paket sürümleri

Bunları hepsini aynı anda halletmeye çalışmak riskli — launch sonrası,
ayrı ve odaklı bir tur olarak planlanmalı.

---

## Erişilebilirlik
Buton/tıklanabilir alan boyutları (44x44 minimum dokunma hedefi standardı)
projede sistematik olarak hiç denetlenmedi. Launch sonrası bir taramada
ele alınmalı — özellikle küçük ikon butonları (kapatma X'leri, küçük
aksiyon ikonları) risk taşıyabilir.
**Öncelik: Düşük**

## Farklı ekran boyutları/yoğunlukları
Uygulama şu ana kadar yalnızca bd'nin kendi cihazında (CPH2581/OnePlus)
test edildi. Küçük ekranlı telefonlarda (örn. eski/düşük çözünürlüklü
Android cihazlar) ya da tablet gibi büyük ekranlarda düzen bozulmaları
olabilir — hiç test edilmedi.
**Öncelik: Düşük**

## Zayıf/kesintili ağ koşulları
Uygulamanın 2G/3G gibi yavaş bağlantılarda ya da aralıklı kesintili
internette (Firestore offline cache devreye girdiğinde) davranışı
sistematik test edilmedi. Bazı ekranlarda "bağlantı yok" banner'ı var
(bugün doğrulandı) ama tüm ekranlarda tutarlı davranıp davranmadığı
bilinmiyor.
**Öncelik: Düşük**

## Firebase maliyet projeksiyonu
Kullanıcı sayısı büyüdükçe Firestore okuma/yazma, Cloud Functions
çağrıları, Storage bant genişliği maliyetlerinin nasıl ölçekleneceği
hiç hesaplanmadı. Launch sonrası ilk ayın gerçek kullanım verisiyle
bir maliyet tahmini yapılmalı, beklenmedik bir faturayla karşılaşmamak
için.
**Öncelik: Düşük**
