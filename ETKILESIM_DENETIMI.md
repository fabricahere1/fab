# Etkileşim Denetimi — onTap/onPressed/onLongPress Taraması

**Tarih:** 2026-08-02
**Kapsam:** `lib/features/` altındaki tüm ekranlar (43 dosyada callback bulundu, 99 dosya incelendi).
**Yöntem:** Statik kod okuması (salt-okuma). Hiçbir dosya değiştirilmedi.
**Arka plan:** Daha önce `ayarlar_screen.dart`'ta bir "E-posta" satırının `onTap: () {}` ile boş bırakılıp düzeltildiği bir bulgudan yola çıkılarak, benzer kalıntıların uygulama genelinde olup olmadığı sistematik olarak tarandı.

## Genel Sonuç

Daha önceki "e-posta" kalıntısına benzer, **tamamen boş `() {}` handler veya tanımsız/yanlış parametreli fonksiyon çağrısına rastlanmadı**. Uygulamanın onTap/onPressed bağlanma disiplini genel olarak iyi durumda.

Bulunan asıl ve tekrar eden risk deseni: **"sessiz başarısızlık"** — özellikle `Engelleme`, `TakipIslemleri`, `SohbetIslemleri.gizle`, favori toggle ve ilan silme gibi async Firestore işlemlerinde, hata durumunda ya (a) kullanıcıya hiç geri bildirim verilmiyor ya da (b) daha kötüsü, hata yutulup her zaman "başarılı" mesajı gösteriliyor.

---

## 1. İlan Oluşturma / Düzenleme — ✅ (küçük ⚠️)

`lib/features/ilanlar/presentation/ilan_form_screen.dart`

- Yeni ilan oluşturma (satır 487-510) ve düzenleme/güncelleme (satır 404-440, provider: `ilan_provider.dart:427-450`): try/catch mevcut, hata state'e yazılıp overlay üzerinden gösteriliyor. ✅
- Kaydetme/Yayınla/Geri butonları doğru fonksiyonlara bağlı, boş handler yok.

**⚠️ `_resimEkle` (satır 247-316) — try/catch yok**
```dart
Future<void> _resimEkle() async {
  ...
  final kaynak = await showModalBottomSheet<ImageSource>(...);
  if (kaynak == null) return;
  if (kaynak == ImageSource.camera) {
    final picked = await _picker.pickImage(...); // try/catch yok
```
`image_picker` izin reddi veya dosya erişim hatasında exception yakalanmıyor; kullanıcıya "resim eklenemedi" gibi bir mesaj gösterilmiyor.

---

## 2. İlan Düzenleme — ✅
Yukarıdaki güncelleme akışı ile aynı dosyada, aynı değerlendirmeye tabi. Kaydet/İptal butonları sorunsuz.

---

## 3. Hesap Silme — ✅ (örnek teşkil eden akış)

`lib/features/profil/presentation/ayarlar_screen.dart:460-833`

Onay dialogu, geri dönüşü olmadığına dair açık uyarı metni, 10 saniyelik iptal edilebilir geri sayım, 3 farklı reauth yöntemi (google/telefon/email), her adımda try/catch + `AppSnackBar.hata`, başarılı silme sonrası `ctx.go(AppRoutes.login)` ile yönlendirme ve bilgi mesajı. Önceki "siyah ekran" düzeltmesiyle tutarlı, sağlam bir akış. Diğer akışlara referans olarak gösterilebilir.

---

## 4. Mesajlaşma — ⚠️

`lib/features/mesajlar/presentation/sohbet_screen.dart`, `mesajlar_screen.dart`, `islem_durumu_panel.dart`

- Mesaj gönderme / resim gönderme: provider tarafında (`mesaj_provider.dart`) try/catch var, `ref.listen` (sohbet_screen.dart:533-543) ile snackbar gösteriliyor. ✅
- `islem_durumu_panel.dart`: örnek teşkil edecek kalitede — çift tıklama koruması, try/catch, anlamlı hata mesajları (satır 336-352, 551-575). ✅

**❌ "Kullanıcıyı Engelle" (sohbet_screen.dart:505-514) — yanlış başarı mesajı riski**
```dart
if (onay == true && mounted) {
  await ref.read(engellemeProvider.notifier).engelle(
      benimUid: benimUid, hedefUid: widget.karsiKullaniciId);
  if (mounted) {
    AppSnackBar.bilgi(context, '${widget.karsiKullaniciAd} engellendi.');
    Navigator.pop(context);
  }
}
```
Kök neden: `lib/features/profil/providers/profil_provider.dart:87-98` — `Engelleme` notifier hatayı kendi içinde yutuyor (`catch (e) { state = AsyncError(e, ...) }`, rethrow yok). `await` her zaman normal döner, bu yüzden Firestore yazması gerçekten başarısız olsa bile ekran her zaman "X engellendi" mesajı gösteriyor. **Kullanıcı engellendiğini sanır ama engellenmemiş olabilir.**

**⚠️ "Sohbeti Sil" (sohbet_screen.dart:459-463, mesajlar_screen.dart:208-213) — try/catch yok**
```dart
Future<void> gizle({required String sohbetId, required String kullaniciId}) async {
  await _repo.sohbetiGizle(sohbetId: sohbetId, kullaniciId: kullaniciId);
}
```
(`mesaj_provider.dart:492-497`) Hiç try/catch içermiyor; her iki çağıran ekran da hata durumunda kullanıcıya bilgi vermiyor. Firestore yazma başarısız olursa sohbet listede kalır ama kullanıcı "sildim" sanabilir.

---

## 5. Engelleme — ❌

`lib/features/profil/presentation/kullanici_profil_screen.dart:378-402`, `ayarlar_screen.dart:1044-1055` (`_EngellenenlerScreen`)

```dart
onPressed: () async {
  if (benOnuEngellemisim) {
    await ref.read(engellemeProvider.notifier).engelKaldir(...);
    if (context.mounted) {
      AppSnackBar.bilgi(context, '$kullaniciAd engeli kaldırıldı.');
    }
  } else {
    await ref.read(engellemeProvider.notifier).engelle(...);
    if (context.mounted) {
      AppSnackBar.bilgi(context, '$kullaniciAd engellendi.');
    }
  }
},
```
Aynı kök neden (`profil_provider.dart:81-112`, hatayı yutan `Engelleme` notifier): Firestore işlemi başarısız olsa bile kullanıcıya her zaman başarı mesajı gösteriliyor. `ilan_detay_screen.dart` içindeki `_engelleDialog` da aynı deseni taşıyor, orada ise en azından yanlış başarı mesajı yok ama hiç geri bildirim de yok (bkz. madde 9).

**Öneri:** `Engelleme` notifier'daki `engelle`/`engelKaldir` metodları başarı durumunu `bool` olarak dönmeli veya rethrow etmeli; tüm çağıran yerler bu sonucu kontrol edip başarısızlıkta `AppSnackBar.hata` göstermeli.

---

## 6. Takip — ❌ (en ciddi bulgu)

`lib/features/profil/presentation/kullanici_profil_screen.dart:307-318`, `takip_listesi_screen.dart:259,267`

```dart
onPressed: () {
  Navigator.pop(dialogContext);
  ref.read(takipIslemleriProvider.notifier).takipiBirak(kullaniciId);
},
...
} else {
  ref.read(takipIslemleriProvider.notifier).takipEt(kullaniciId);
}
```
`TakipIslemleri.takipEt`/`takipiBirak` (`profil_provider.dart:292-329`) hata durumunda yalnızca `AppHataYonetici.logla` ile log tutup optimistik state'i geri alıyor — kullanıcıya SnackBar/dialog ile **hiçbir** hata mesajı gösterilmiyor. Ağ hatası olursa buton görsel olarak sessizce eski haline dönüyor, kullanıcı neyin ters gittiğini anlayamaz. Madde 5'ten daha ciddi: orada en azından (yanlış) bir başarı mesajı var, burada kullanıcı arayüzden hiçbir sinyal almıyor.

Takip listesi (takipçi/takip edilen) yükleme ve navigasyon akışları kendi içinde sorunsuz (✅).

---

## 7. Şikayet/Rapor — ❌

Ayrı bir "şikayet ekranı" yok; akış `lib/features/ilanlar/presentation/ilan_detay_screen.dart` içinde (`_sikayetDialog`).

```dart
onPressed: seciliSebep == null ? null : () async {
  Navigator.pop(ctx);
  final basarili = await ref.read(sikayetProvider.notifier).sikayetGonder(...);
  if (basarili && mounted) {
    AppSnackBar.basari(context, 'Şikayetiniz iletildi.');
  }
},
```
`basarili == false` olduğunda hiçbir şey olmuyor — kullanıcı "Gönder"e basar, dialog kapanır, ama şikayet gitmemişse bunu asla öğrenemez. Sebep seçimi ve form UI'ı kendisi sorunsuz.

---

## 8. Destek/İletişim (Ayarlar > Bize Ulaşın) — ✅

`ayarlar_screen.dart:289-298` "Destek" satırı `iletisimFormAc` çağırıyor; `lib/features/profil/presentation/widgets/iletisim_form_sheet.dart` içinde gerçek bir Cloud Function (`iletisimGonder`) çağrısı var, try/catch mevcut (satır 98-121), hata durumunda `AppSnackBar.hata` gösteriliyor. Gerçek bir form açıyor, boş handler değil.

---

## 9. Favoriler — ⚠️ (tekrarlanan desen, düşük öncelik)

`favoriler_screen.dart`, `ilan_detay_screen.dart` (`_favorToggle`), `swipe_karti.dart` (`_favToggle`), `ilan_karti.dart` (`_toglle`), `sana_ozel_screen.dart:562-569`

Örnek (`ilan_detay_screen.dart`):
```dart
void _favorToggle(IlanModel ilan, bool favorideMi) {
  if (favorideMi) {
    ref.read(favoriProvider.notifier).cikar(ilan.id);
  } else {
    ref.read(favoriProvider.notifier).ekle(ilan);
  }
}
```
`await` yok, try/catch yok — fire-and-forget. Altta `favoriProvider` (`ilan_provider.dart:639-675`) kendi içinde try/catch + optimistik geri alma yapıyor, bu yüzden çökme riski yok ama hata durumunda kullanıcıya SnackBar gösterilmiyor; buton sessizce eski haline döner. Dört dosyada da (favoriler_screen, ilan_detay, swipe_karti, ilan_karti) tutarlı biçimde tekrarlanan, uygulama genelinde bilinçli bir "optimistic UI, sessiz hata" tasarım tercihi gibi görünüyor — ama kullanıcı deneyimi açısından iyileştirilebilir. Favoriler listesi ve giriş/kart tıklama akışları sorunsuz.

---

## Diğer bulgular (öncelik sırasına göre düşük)

**⚠️ İlan silme — `profil_screen.dart:695-723` — hata durumunda tamamen sessiz**
```dart
if (onay == true) {
  await ref.read(ilanIslemleriProvider.notifier).sil(ilan.id);
}
```
`IlanIslemleriNotifier.sil()` (`ilan_provider.dart:691-696`) try/catch içermiyor, çağıran yer de içermiyor. Firestore silme başarısız olursa kullanıcı hiçbir uyarı görmez ve ilanın silindiğini sanabilir.

**⚠️ Telefon güncelleme — `ayarlar_screen.dart:427-439`**
`profilGuncelle` dönüş değeri (`bool`) kontrol edilmiyor; hata olsa bile dialog kapanıp "güncellendi" mesajı gösteriliyor.

**⚠️ Numarayı Gizle switch — `ayarlar_screen.dart:368-375` (`_telefonGizliDegistir`)**
Dönüş değeri kontrol edilmiyor, başarı/hata durumunda hiçbir geri bildirim yok.

**⚠️ Bildirimler — `bildirimler_screen.dart:53-55`**
```dart
ref.read(bildirimProvider.notifier).tumunuOkunduIsaretle().catchError((_) {});
```
"Tümünü oku" hatası tamamen yutuluyor. `_navigate` içindeki bazı dallar (satır 259, 279, 306, 333-336) veri eksikse sessizce `return` ediyor — bildirime tıklanır, hiçbir şey olmaz.

**⚠️ Bekleyen değerlendirme tamamlama — `profil_screen.dart:986-1001`**
try/catch dışında, hata olursa geri bildirim yok. Düşük öncelik.

**Not (ölü kod, kritik değil):** `ilanlar_screen.dart:468-469` — `_IsteklerHeader`'a geçilen `onAramaChanged: (_) {}` ve `onAramaSifirla: () {}` gerçekten boş no-op, ama bunları tetikleyecek gerçek bir arama kutusu o context'te yok (arama `AramaScreen`'e yönlendiren ayrı bir buton). Kullanıcıya görünen kırık bir davranış yaratmıyor, sadece kullanılmayan plumbing — temizlik backlog'una eklenebilir.

---

## Sorunsuz Bulunan Alanlar (✅)

- `home_screen.dart`, `kesfet_screen.dart`, `kesfet_vitrin_tab.dart`, `kesfet_vitrin2_tab.dart`, `kesfet_bolum_baslik.dart`, `kesfet_bolum_detay_screen.dart`
- `kategori_vitrini_bolum.dart`, `hos_geldin_dialog.dart`, `alisveris_rehberi_bolum.dart`, `beden_donusturucu_bolum.dart`, `dunya_trendleri_bolum.dart`, `tasiyici_ipuclari_bolum.dart` (statik veri + yerel setState, async/Firestore yok)
- `arama_screen.dart`, `profil_tamamla_screen.dart`, `profil_tamamla_widgets.dart`, `login_screen.dart` (küçük ⚠️: `_kodGonder` içindeki dış try/finally, catch yok — repo implementasyonu bu denetimde teyit edilmedi, düşük risk)
- `profil_duzenle_screen.dart`, `ilanlarim_screen.dart`, `sss_screen.dart`, `gizlilik_politikasi_screen.dart`, `kullanim_kosullari_screen.dart`
- `filtre_ekrani.dart`, `gelenler_filtre_ekrani.dart` (küçük not: `_turkiyeDisiDialogAc`/`_ulkeSehirSec` try/catch yok ama pratik risk yok)
- `gelenler_screen.dart`, `ilanlar_screen.dart` (Algolia hataları `HataDurumWidget` ile düzgün gösteriliyor)
- `swipe_karti.dart`, `ilan_karti.dart`, `ilan_overlay_widget.dart` (kart tıklama, geri al/ileri, kapat butonları)
- `degerlendirme_screen.dart`, `degerlendirmeler_liste_screen.dart` (`_gonder()` başarı/hata ikisini de ele alıyor)
- `takip_listesi_screen.dart` (liste yükleme, boş durum, navigasyon — buton hata geri bildirimi hariç, bkz. madde 6)
- `profil_provider.dart` içindeki repository çağrılarının hepsi doğru parametrelerle yönleniyor; ölü/kırık çağrı (tanımsız fonksiyon, yanlış parametre) hiçbir dosyada bulunmadı.
- `islem_durumu_panel.dart` — uygulamadaki en sağlam örnek (çift tıklama koruması, anlamlı hata mesajları).

---

## Bulgu Özeti (öncelik sırasına göre)

| # | Akış | Seviye | Sorun |
|---|------|--------|-------|
| 1 | Sohbette Kullanıcıyı Engelle | ❌ | Hata yutuluyor, her zaman "engellendi" mesajı gösteriliyor |
| 2 | Takip Et / Takibi Bırak | ❌ | Hata durumunda hiçbir geri bildirim yok |
| 3 | Profildeki Engelle/Engeli Kaldır | ❌ | Hata yutuluyor, her zaman başarı mesajı gösteriliyor |
| 4 | Şikayet Gönder (ilan detay) | ❌ | `basarili == false` durumunda sessiz, kullanıcı bilgilendirilmiyor |
| 5 | Sohbeti Sil / Gizle | ⚠️ | try/catch yok, hata durumunda geri bildirim yok |
| 6 | İlan Silme (profil) | ⚠️ | try/catch yok, hata durumunda tamamen sessiz |
| 7 | Telefon Güncelleme / Numarayı Gizle | ⚠️ | Dönüş değeri kontrol edilmiyor, hatada yanlış/eksik geri bildirim |
| 8 | Favori Toggle (4 dosyada tekrar) | ⚠️ | Fire-and-forget, hata durumunda sessiz geri alma |
| 9 | Bildirimler "Tümünü Oku" + navigasyon | ⚠️ | Hata yutuluyor / eksik veri sessizce yok sayılıyor |
| 10 | İlan Formu Resim Ekleme | ⚠️ | image_picker çağrıları try/catch içinde değil |

**Tamamen boş (`() {}`) handler veya tanımsız fonksiyona bağlı kırık çağrı bulunmadı** (ilanlar_screen.dart'taki ölü plumbing hariç, kullanıcıya görünmüyor).

---

## Cihazda Elle Test Edilmesi Gereken, Kod Okumasıyla Kesinleştirilemeyen Noktalar

1. **Uçak modu / ağ kesintisi altında Engelle ve Takip Et/Bırak butonları** — kod, hata durumunda UI'ın ne gösterdiğini (madde 1-3, 6 no'lu bulgular) gerçek bir ağ hatasıyla tetikleyerek doğrulanmalı. Özellikle "Kullanıcıyı Engelle"nin gerçekten başarısız olduğu ama "engellendi" mesajı gösterdiği senaryo.
2. **Şikayet formu — sunucu tarafı `sikayetGonder` başarısız olduğunda** (ör. Cloud Function hata döndürdüğünde) UI'da gerçekten hiçbir şey olmadığı teyit edilmeli.
3. **İlan silme — Firestore güvenlik kuralı reddi durumunda** (ör. başka bir kullanıcının ilanını silmeye çalışma edge-case'i, ya da yetki süresi dolmuş token) ekranın donup donmadığı/sessiz kalıp kalmadığı.
4. **image_picker izin reddi (kamera/galeri) senaryosu** — ilan formunda resim ekleme sırasında izin reddedildiğinde uygulamanın çökmediği, sadece sessiz kaldığı teyit edilmeli.
5. **`login_screen.dart` `_kodGonder()`** — telefon kodu gönderme sırasında `onHata` callback'i tetiklenmeden önce beklenmedik bir exception (ör. SMS kotası aşımı, geçersiz numara formatı) fırlatılırsa gerçek cihazda loading ekranının sessizce kapanıp kapanmadığı.
6. **Sohbeti Sil/Gizle — çevrimdışıyken** gerçek davranış (sessiz kalma mı, exception ile kırmızı ekran mı) cihazda görülmeli; statik analiz sadece try/catch eksikliğini gösterebiliyor, çalışma zamanı sonucunu değil.
7. **Bildirimler ekranında bozuk/eksik `hedefId` içeren bir bildirime tıklama** — gerçek veriyle "hiçbir şey olmuyor" davranışının kullanıcı için kafa karıştırıcı olup olmadığı.
8. **Favori toggle'ın optimistic UI geri alma davranışı** — yavaş/kesintili ağda kullanıcının favori butonuna hızlıca birden fazla kez basması durumunda (race condition) tutarlılık.
