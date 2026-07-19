# MUTLAK TARAMA — Kapsamlı Kod Denetimi
Tarih: 2026-07-19 (görev içi) — proje: C:\src\iste_v3

Bu rapor SALT-OKUMA bir denetimin ürünüdür. Hiçbir kod dosyası değiştirilmedi.
Context bütçesi nedeniyle bazı bölümler yalnızca grep/yüzeysel taranmıştır — bu
açıkça "İNCELENMEDİ / KISMİ" olarak işaretlenmiştir. Yanlış "temiz" izlenimi
vermektense dürüst kısmi rapor tercih edilmiştir.

---

## BÖLÜM A — Bu gecenin bütünlük doğrulaması (TAMAMLANDI)

Tüm parçalar Read ile açılıp doğrulandı.

- `flutter analyze`: 2 info-seviye uyarı, 0 hata/warning (main.dart:49 deprecated appleProvider, sana_ozel_screen.dart:1005 unnecessary_underscores). **Doğrulandı, bilinen/önemsiz.**
- `functions/` `npx tsc --noEmit`: hatasız (boş çıktı = başarılı derleme). **Doğrulandı.**
- `git status --short`: sadece kesfet_bolum_baslik.dart, kesfet_vitrin_tab.dart, sana_ozel_screen.dart değişik + kart_kod.txt, saglik_taramasi_hero_banner_sonrasi.md untracked. Commit'e hazır bekleyen bir çakışma yok.
- **GirisGerekli + Lottie**: `lib/shared/widgets/giris_gerekli_widget.dart` mevcut, `Lottie.asset()` ile `assets/animations/bukalemun.json` / `timsah.json` rastgele seçiyor. Her iki asset dosyası `assets/animations/` altında fiilen mevcut (Glob ile doğrulandı) ve `pubspec.yaml:87`'de `assets/animations/` klasörü tanımlı. `pubspec.yaml:46` `lottie: ^3.3.3`, `pubspec.lock`'ta çözümlenmiş. `sana_ozel_screen.dart:49` `GirisGerekli(...)` çağrısı doğrulandı. **Doğrulandı, sorunsuz.**
- **guvenSkoruHesapla**: `functions/src/index.ts:1146-1175`, `onSchedule("every 24 hours", region: europe-west1)`. `batch.update(kullaniciDoc.ref, { guvenSkoru: toplamSkor })` — `toplamSkor = Math.round(...)`, yani **int** yazıyor. Lib tarafında `kullanici_model.dart:75`: `guvenSkoru: ((d['guvenSkoru'] as num?)?.toInt()) ?? 0` — **num? → int dönüşümü**, tip uyumlu. Alan adı birebir `guvenSkoru`. `kullanici_model.freezed.dart` de `int guvenSkoru` olarak üretilmiş (build_runner çıktısı güncel). Okuma tarafı: `profil_screen.dart:346-382`, `kullanici_profil_screen.dart:221-248` her ikisi de `profil.guvenSkoru` int olarak kullanıyor (renk eşiği 80/60/40, `/100` ile progress bar). **Doğrulandı, tam uyumlu — tip uyuşmazlığı YOK.**
- **takip_listesi_screen.dart**: GoogleFonts.dmSans tutarlı kullanım, buton/font satırları (63-65, 126, 158-159, 282-341) incelendi, göze çarpan bir tutarsızlık yok. **Doğrulandı.**
- **Hero banner siyah zemin + Merriweather**: `kesfet_bolum_baslik.dart` başlıklarda `GoogleFonts.merriweather` (satır 55) kullanıyor; hem `kesfet_vitrin_tab.dart` hem `sana_ozel_screen.dart` hero banner alanlarında `Colors.black` zemin/gradient var (kesfet_vitrin_tab.dart:538,604; sana_ozel_screen.dart:823 vb.). **Doğrulandı, üç dosya tutarlı.**
  - **Düşük/Doğrulanmadı (kozmetik, kod değil dokümantasyon sorunu):** `kesfet_bolum_baslik.dart` satır 9-10 yorum bloğu hâlâ "dmSerifDisplay yerine DM Sans w800 kullanılıyor" diyor, ama fiili kod `GoogleFonts.merriweather` çağırıyor (satır 55). Yorum, Merriweather'a geçişten önce yazılmış ve güncellenmemiş. İşlevsel etkisi yok, sadece yanıltıcı kod yorumu.
- **"Aldığım Değerlendirmeler" rename**: `ayarlar_screen.dart:256` ve `profil_screen.dart:446` ikisinde de doğrulandı. **Doğrulandı.**
- **Değerlendirme avatarına tıklama**: `degerlendirmeler_liste_screen.dart:273-274` `GestureDetector(onTap: () => Navigator.push(...))` mevcut. **Doğrulandı.**

**Sonuç: Bölüm A'da hiçbir çelişki/regresyon bulunmadı. Son gece değişiklikleri birbiriyle ve backend ile tutarlı.**

---

## BÖLÜM B — Güvenlik (KISMİ TAMAMLANDI)

### B1 — Cloud Function bazında yetki taraması
`functions/src/index.ts`'teki tüm export edilen fonksiyonlar listelendi (grep ile 15 fonksiyon bulundu). Aşağıdakiler tam Read ile derinlemesine incelendi:

| Fonksiyon | Satır | Tip | Auth kontrolü | Yetki/ownership | Girdi doğrulama | Not |
|---|---|---|---|---|---|---|
| algoliaTopluAktar | 578 | onCall | ✅ `!request.auth` | ✅ email allowlist (`fabricahere@gmail.com`) | — | Doğrulandı — admin-only, yorum satırında gerekçe var |
| mesajBildirimiGonder | 628 | onCall | ✅ | ✅ sohbet katılımcılığı kontrolü (639-647) — hem gönderen hem alıcı sohbette mi diye bakıyor | kısmi (data cast, ama tip güvenliği TS'e bırakılmış) | Doğrulandı, iyi tasarlanmış — "rastgele aliciId ile sahte bildirim" saldırısına karşı yorumla açıklanmış koruma var |
| iletisimGonder | 828 | onCall | ✅ | N/A (herkes destek talebi açabilir, mantıklı) | ✅ `konu`/`mesaj` boş kontrolü | Doğrulandı |
| hesapSilSunucu | 869 | onCall | ✅ | kendi hesabı (`request.auth.uid`) — başka ownership kontrolü gerekmez | N/A | Doğrulandı — **AMA bkz. E3 bulgusu: degerlendirmeler koleksiyonuna DOKUNMUYOR** |
| degerlendirmeBildirimiGonder | 696 | onDocumentCreated | N/A (trigger) | N/A | — | Doğrulandı |

Aşağıdaki fonksiyonlar sadece grep ile satır numarası tespit edildi, **derinlemesine okunmadı — İNCELENMEDİ olarak işaretleniyor**: `ilanModerasyonu` (278), `ilanGuncellemeModerasyon` (403), `ilanGuncellendi` (484), `ilanSilindi` (555), `takipOlustuSayacArttir` (734), `takipSilindiSayacAzalt` (751), `degerlendirmePuanGuncelle` (770), `islemDurumuBildirimiGonder` (944, kısmen okundu 944-947), `goruntulenmeTemizle` (1078), `ilanOtomatikPasif` (1115, kısmen okundu — 500 limit ile toplu güncelleme, sorunsuz görünüyor).

### B2 — firestore.rules (TAM OKUNDU, 145 satır)
Her koleksiyon satır referanslı:
- `kullanicilar/{uid}` (29-46): get herkese açık, list kapalı, create/update sadece kendi uid'i — **kritik alanlar** (`ortalamaPuan`, `degerlendirmeSayisi`, `takipciSayisi`, `takipSayisi`, `rozetler`, `guvenSkoru`, `spamUyarisi`, `spamTarihi`, `spamIlanSayisi`) `hasAny` ile client update'inden **explicit olarak hariç tutulmuş**. Bu iyi bir kontrol — kullanıcı kendi güven skorunu client'tan artıramaz. **Doğrulandı, sağlam.**
- `ilanlar/{ilanId}` (48-58): create'te `kullaniciId == auth.uid` zorunlu, update sahiplik VEYA sayaç güncellemesi (`gecerliSayacGuncellemesi()` fonksiyonu ile favoriSayisi/goruntulenmeSayisi'nin sadece ±1 değişmesine izin veriliyor — iyi bir anti-abuse kontrolü). **Doğrulandı, sağlam.**
- `sohbetler/{sohbetId}` + `mesajlar` alt-koleksiyonu (60-82): katılımcılık kontrolü var, mesaj create'te `gondereId == auth.uid` zorunlu, update sadece `okundu` alanına ve sadece alıcı tarafından. **Doğrulandı, sağlam.**
- `favoriler`, `goruntulenmeler`, `degerlendirmeler`, `bildirimler`, `sikayetler`, `takipler`, `trendler`, `ayarlar`: hepsi okundu, hiçbirinde `allow write: if true` veya aşırı gevşek kural YOK. `degerlendirmeler` create'inde puan 1-5 aralığı ve kendine puan verememe kontrolü var (101-109). **Doğrulandı, genel olarak sağlam bir rules dosyası.**

**B2 sonucu: Kritik/Yüksek seviye gevşek kural bulunmadı.**

### B3 — httpsCallable çağrıları
`lib/` genelinde grep yapıldı ama her çağrı tek tek karşılığındaki fonksiyonla çapraz doğrulanmadı (zaman kısıtı). **KISMİ/İNCELENMEDİ** — B1'de derin okunan mesajBildirimiGonder/hesapSilSunucu/iletisimGonder/algoliaTopluAktar için karşılık doğrulandı, diğerleri değil.

### B4 — Hardcoded secret taraması
Yapılmadı (zaman kısıtı). **İNCELENMEDİ.** Not: `token.txt` (repo kökünde, git-tracked) içeriği incelendi, tek satırlık bir Firebase CLI hata mesajı (`Error: auth:print-access-token is not a Firebase command`) — **gerçek bir secret DEĞİL**, ama gereksiz/kafa karıştırıcı bir tracked dosya (bkz. J1).

---

## BÖLÜM C — Performans (İNCELENMEDİ / SADECE YÜZEYSEL GREP)

C1: `.snapshots(`/`.get(` grep'i lib/ genelinde ~64 eşleşme buldu (limit içermeyen), ancak her biri tek tek açılıp gerçekten sınırsız bir sorgu mu yoksa tekil doküman `.get()`'i mi (örn. `doc(id).get()` zaten limit gerektirmez) diye AYRIŞTIRILMADI. Bu ham sayı yanıltıcı olabilir — kesin bulgu için tek tek doğrulama gerekir. **KISMİ/DOĞRULANMADI, İNCELENMEDİ olarak işaretleniyor.**
C2, C3, C4: Hiç taranmadı. **İNCELENMEDİ.**

---

## BÖLÜM D — Mimari ve kod kalitesi (KISMİ)

D4 (sessiz catch): `catch (e) {}` deseni tam eşleşme olarak 0 bulundu; `catch.*{ *}` daha gevşek pattern 3 dosyada eşleşti (bildirimler_screen.dart, ilan_repository.dart, mesaj_provider.dart) ama bunlar muhtemelen çok satırlı catch blokları olup regex'in yanlış eşleşmesi — **tek tek Read ile doğrulanmadı**. Mesaj gönderiminde görülen catch bloğu (mesaj_repository.dart:113-117) incelendi ve **sessiz değil**, `AppHataYonetici.logla` ile loglanıyor, kasıtlı yorum var. **D4 geneli: İNCELENMEDİ (yüzeysel, önceki turlarda daha kapsamlı taranmış olabilir — bu turda tam doğrulama yapılamadı).**

D1, D2, D3, D5, D6, D7, D8: Bu turda vakit kalmadığı için **taranmadı — İNCELENMEDİ.** (Görev talimatına göre bunlar önceki turlarda kısmen incelenmiş olabilir, ancak bu oturumda yeniden doğrulanamadı.)

---

## BÖLÜM E — Veri tutarlılığı

### E2 (guvenSkoru tip/alan uyumu) — TAMAMLANDI, bkz. Bölüm A. **Doğrulandı: tam uyumlu, sorun yok.**

### E3 — hesapSilSunucu ve değerlendirmeler koleksiyonu — TAMAMLANDI
`functions/src/index.ts:869-932` tam okundu. Fonksiyon şu koleksiyonlara dokunuyor: `kullanicilar` (kendi + bekleyenDegerlendirmeler alt-koleksiyonu), `ilanlar`, `favoriler`, `bildirimler`, `goruntulenmeler`, `takipler` (hem takipçi hem takip edilen yönünde), `sohbetler` + `mesajlar` alt-koleksiyonu, ve son olarak Firebase Auth kaydı.

**`degerlendirmeler` koleksiyonuna HİÇ dokunmuyor.**

**Bulgu (Orta, Doğrulandı, muhtemelen bilinen backlog ama bu turda yeni doğrulandı):** Bir kullanıcı hesabını sildiğinde:
- Bu kullanıcının **verdiği** değerlendirmeler (`degerlendireninId == uid`) silinmeden kalır → silinmiş kullanıcıya ait "hayalet" değerlendirmeler görünmeye devam eder (değerlendirilen kişinin profilinde).
- Bu kullanıcının **aldığı** değerlendirmeler (`hedefKullaniciId == uid`) de silinmez → artık var olmayan bir kullanıcıya ait değerlendirmeler kalır, ama bu daha az sorunlu (görüntülenmez çünkü hedef kullanıcı profili yok).
- Daha kritik: silinen kullanıcının verdiği değerlendirmeler, hedef kullanıcının `ortalamaPuan`/`degerlendirmeSayisi` hesaplamasına katkıda bulunmaya devam eder ama artık `degerlendireninId` dangling bir referans. `degerlendirmeBildirimiGonder` (696) gibi trigger'lar ileride bu dangling referanstan `kullanicilar/{degerlendireninId}` okumaya çalışırsa boş veri dönebilir (kod null-safe görünüyor, `?? "Biri"` fallback var, bu yüzden crash riski düşük).
- **Launch engelleyici değil** (crash/veri kaybı riski yok, sadece "hayalet veri" birikimi), ama veri hijyeni açısından not edilmeli.

### E1 — genel alan adı/tip taraması: Yapılmadı. **İNCELENMEDİ.**

---

## BÖLÜM F — UI/UX tutarlılığı (KISMİ)

F3 (mesajGonder ilk-temas fallback) — TAMAMLANDI. `lib/features/mesajlar/data/mesaj_repository.dart:76-146` tam okundu. `efektifIlanBaslik` boşsa `ilanRepository.ilanGetir(ilanId)` ile ilan dokümanından fallback çekiliyor (satır 100-118), try/catch ile sarılı ve hata durumunda sessizce (loglanarak) devam ediyor — mesaj yine de gönderiliyor, sadece meta alanları boş kalabiliyor. Yorumda "F1'in sohbetMetaProvider'daki okuma-tarafı fallback'i" ile birlikte çalıştığı belirtilmiş. Okuma tarafı (`sohbetMetaProvider`) bu turda ayrıca doğrulanmadı ama yazma tarafı doğru ve tutarlı görünüyor. **Doğrulandı (yazma tarafı), okuma tarafı fallback'i çapraz doğrulanmadı — Şüpheli değil, sadece eksik doğrulama.**

F1, F2: Taranmadı. **İNCELENMEDİ.**

---

## BÖLÜM G — Bağımlılıklar (KISMİ)

G1: `pubspec.yaml`'da 62 doğrudan bağımlılık satırı tespit edildi, `lottie: ^3.3.3` (satır 46) mevcut ve `pubspec.lock`'ta çözülmüş durumda (satır 1008-1011 civarı). Tam tablo çıkarılmadı (zaman kısıtı). **KISMİ.**
G2, G3: Yapılmadı. **İNCELENMEDİ.**

---

## BÖLÜM H — Moderasyon/içerik güvenliği (KISMİ)

H1: `mesajGonder` bir Cloud Function DEĞİL — client-side (Dart) `mesaj_repository.dart` içinde çalışıyor, Firestore'a doğrudan `batch.set()` ile yazıyor. `functions/src/index.ts:71` civarında "Yasaklı kelimeler" bloğu ve `kelimeRegexCache()` (153-177) bulundu, ancak bu filtrenin mesaj gönderimine değil **ilan moderasyonuna** (`ilanModerasyonu`, satır 278) bağlı olduğu görülüyor — mesaj metni için ayrı bir sunucu-taraflı kelime filtresi görülmedi. **Bulgu (Şüpheli/Doğrulanmadı — bu turda `ilanModerasyonu` fonksiyonunun tam içeriği okunmadı, sadece "Yasaklı kelimeler" bloğunun nerede kullanıldığı grep ile teyit edilmedi):** Mesajlaşmada sunucu taraflı içerik filtresi olmayabilir — İNCELENMEDİ olarak bırakılıyor, kesin hüküm için `ilanModerasyonu` fonksiyonunun ve `YASAKLI_KELIMELER` kullanım noktalarının tam taranması gerekir.
H2: Yapılmadı. **İNCELENMEDİ.**

---

## BÖLÜM I — Erişilebilirlik

Yapılmadı. **İNCELENMEDİ.**

---

## BÖLÜM J — Git/dosya hijyeni (TAMAMLANDI)

### J1 — Repo kökünde biriken rapor/analiz dosyaları
Aşağıdaki dosyalar `C:\src\iste_v3` kökünde tespit edildi (21 adet):
```
algolia_admin_diff.txt          anlasma_silme_diff.txt
BACKLOG.md                      backlog_1_2_diff.txt
backlog_temizligi_dogrulama.md  banner_secici_diff.txt
cupertino_standartlastirma_diff.txt   EXTREME_TARAMA.md
font_log.txt                    functions_kodlar.txt
gradle_signing_diff.txt         guven_skoru_diff.txt
haftanin_onecikanlari_tam_kaplama_diff.txt
hero_banner_siyah_zemin_diff.txt      HIC_BAKILMAMIS_TARAMA.md
ilan_otomatik_pasif_diff.txt    lottie_ekleme_diff.txt
merriweather_diff.txt           README.md
sana_ozel_giris_diff.txt        token.txt
ucgorev_diff.txt
```
Ayrıca `git status`'a göre `kart_kod.txt` ve `saglik_taramasi_hero_banner_sonrasi.md` untracked olarak duruyor (henüz commit edilmemiş).

**Bulgu (Düşük, Doğrulandı, bilinen/tekrarlayan backlog):** Repo kökü, önceki denetim/analiz turlarının çıktısı olan 15+ .md/.txt dosyasıyla dolu. Fonksiyonel bir risk değil ama proje hijyeni açısından bir `docs/` veya `.scratch/` klasörüne taşınması ya da `.gitignore`'a eklenmesi önerilir. `token.txt` özellikle yanıltıcı bir isim taşıyor (secret değil, CLI hata çıktısı) — isim değişikliği veya silinmesi önerilir.

### J2 — .gitignore doğrulaması
`C:\src\iste_v3\.gitignore` kontrol edildi: `.dart_tool/`, `/build/`, `.build/`, `.buildlog/` kapsanıyor. `functions/.gitignore` ayrıca `node_modules/`, derlenmiş `lib/**/*.js`, `.env` dosyalarını kapsıyor — ayrı kontrol edildi ve `git ls-files` ile `functions/node_modules` altında hiç tracked dosya olmadığı doğrulandı. **Doğrulandı, sağlam.**

---

## ÖZET TABLO (bu turda üretilen bulgular)

| # | Bölüm | Bulgu | Önem | Doğrulama | Yeni/Backlog |
|---|---|---|---|---|---|
| 1 | A | Bu gecenin tüm değişiklikleri tutarlı, çelişki yok | — | Doğrulandı | — |
| 2 | A (kozmetik) | kesfet_bolum_baslik.dart yorum bloğu eski font kararını anlatıyor, kod Merriweather kullanıyor | Düşük | Doğrulandı | Yeni |
| 3 | E3 | hesapSilSunucu, `degerlendirmeler` koleksiyonuna dokunmuyor — silinen kullanıcının verdiği/aldığı değerlendirmeler kalıcı olarak yetim kalıyor | Orta | Doğrulandı | Yeni (bu turda ilk kez tespit edildi) |
| 4 | H1 | Mesaj gönderiminde (client-side mesajGonder) sunucu-taraflı kelime filtresi görülemedi — YASAKLI_KELIMELER bloğunun ilan moderasyonuna mı özel olduğu tam doğrulanamadı | Orta (potansiyel) | Şüpheli/Doğrulanmadı | Belirsiz |
| 5 | J1 | Repo kökünde 21 rapor/analiz dosyası birikmiş | Düşük | Doğrulandı | Bilinen backlog |
| 6 | B | firestore.rules ve incelenen 4 Cloud Function'da kritik güvenlik açığı yok | — | Doğrulandı | — |

---

## İNCELENMEDİ olarak işaretlenen bölümler (context bütçesi nedeniyle)
- B1: 15 fonksiyondan 5'i derin okundu, 10'u sadece satır numarası tespit edildi (ilanModerasyonu, ilanGuncellemeModerasyon, ilanGuncellendi, ilanSilindi, takipOlustuSayacArttir, takipSilindiSayacAzalt, degerlendirmePuanGuncelle, islemDurumuBildirimiGonder tam, goruntulenmeTemizle)
- B3, B4 — kısmi/yapılmadı
- C1 (kısmi/ham grep, doğrulanmadı), C2, C3, C4 — tamamen yapılmadı
- D1, D2, D3, D5, D6, D7, D8 — tamamen yapılmadı (bu turda)
- E1 — yapılmadı
- F1, F2 — yapılmadı
- G1 (kısmi), G2, G3 — yapılmadı
- H1 (şüpheli, kesinleşmedi), H2 — yapılmadı
- I1, I2 — yapılmadı

---

## LAUNCH'I ENGELLEYEN, DOĞRULANMIŞ YENİ BİR SORUN VAR MI?

**HAYIR.**

Bu turda derinlemesine incelenen alanlarda (Bölüm A'nın tamamı, firestore.rules'ın tamamı, 4-5 kritik Cloud Function, guvenSkoru tip/alan uyumu, mesajGonder fallback mekanizması) launch'ı engelleyecek Kritik veya Yüksek seviye, doğrulanmış yeni bir sorun bulunmadı. `flutter analyze` ve `tsc --noEmit` temiz.

Tespit edilen tek "Orta" seviye doğrulanmış bulgu (E3 — hesapSilSunucu'nun değerlendirmeler koleksiyonuna dokunmaması) bir veri hijyeni sorunu olup, crash/veri kaybı/güvenlik açığı yaratmıyor — launch'ı engellemez, ancak bir sonraki iterasyonda ele alınması önerilir.

Bölüm C, D, F1-F2, G, H, I geniş ölçüde taranmadığı için, bu bölümlerde launch'ı engelleyecek bir sorun OLMADIĞINI iddia ETMİYORUM — bu bölümler dürüstçe "İNCELENMEDİ" olarak işaretlendi ve bir sonraki tur bunlara odaklanmalı.
