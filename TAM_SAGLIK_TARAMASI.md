# Tam Sağlık Taraması

Tarih: 2026-07-27. Bu rapor salt-okuma statik kod incelemesi + `flutter analyze`,
`flutter test`, `npx tsc --noEmit`, `npm test` çalıştırmalarına dayanır. Hiçbir
kaynak dosya değiştirilmedi.

---

## BÖLÜM A — Client (Flutter) genel sağlığı

### A.1 — GoogleFonts kullanımı
`grep -rn "GoogleFonts\." lib/` → **599 eşleşme**. `pubspec.yaml:38`'de
`google_fonts: ^6.3.3` paketi tanımlı; projede ayrı bir `assets/google_fonts/`
dizini bulunmuyor (paket kendi içinde online/offline font çözümü yapıyor).
Önceki commit geçmişinde iki kez font çökmesi düzeltmesi yapılmış
(`58d3093` Poppins w700→w800, `e71258c` Merriweather w400→w500) — bu, projenin
`GoogleFonts.xxx(fontWeight: ...)` çağrılarında paketin sunduğu ağırlık
varyantlarıyla talep edilen ağırlığın uyuşmaması riskini gösteriyor.
- **Bulgu (Orta, Şüpheli/Doğrulanmadı):** 599 çağrının tamamı tek tek
  doğrulanmadı (kapsam çok büyük); yalnızca geçmişte iki kez patlamış olması,
  benzer ağırlık uyuşmazlıklarının başka `GoogleFonts.*` çağrılarında da
  gizli kalmış olabileceğini düşündürüyor. Statik olarak "eksik varyant"
  tespiti mümkün değil (paket runtime'da hata fırlatıyor) — sistematik
  doğrulama tüm ekranların gerçek cihazda gezilmesini gerektirir.

### A.2 — Dispose edilmeyen kaynaklar
`TextEditingController|AnimationController|StreamSubscription|Timer(|ScrollController`
kullanan tüm dosyalar tarandı, `dispose()` metodu olmayanlar listelendi:
- `lib/features/ilanlar/providers/ilan_provider.dart:394` — `StreamSubscription? sub;` ve `Timer? timer;`
- `lib/features/mesajlar/providers/mesaj_provider.dart:109` — `StreamSubscription? _mesajSub;`, `Timer? _okunduTimer;`

**Değerlendirme: Bulgu değil (yanlış pozitif).** Her iki dosya da
`StatefulWidget` değil, Riverpod `@riverpod` sınıfları (`SohbetNotifier` vb.).
Temizlik `dispose()` yerine `ref.onDispose(() { _mesajSub?.cancel();
_okunduTimer?.cancel(); ... })` ile yapılıyor (`mesaj_provider.dart:127-130`
civarı) — doğru Riverpod deseni. `ilan_provider.dart:394`'teki `sub`/`timer`
yerel değişken olarak `durumBekle()` fonksiyonu içinde tanımlı, kendi içinde
`timer?.cancel()`/`sub?.cancel()` ile kapatılıyor. **Gerçek bir StatefulWidget
içinde dispose edilmeyen controller bulunamadı** (grep taraması ile 40 State
sınıfı arasında başka aday çıkmadı).

### A.3 — `.value ??` deseni (asenkron veriye sessiz varsayılan)
27 eşleşme bulundu, `grep -rn "\.value ??" lib/`. Önemlileri:

| Konum | Önem | Açıklama |
|---|---|---|
| `lib/features/mesajlar/presentation/islem_durumu_panel.dart:33-38` | **Düzeltildi (bugün)** | `sohbetIlanTipProvider(...).value ?? 'istek'` hâlâ satırda duruyor ama artık `widget.bilinenIlanTip` öncelikli kullanılıyor (bkz. dosyanın üstü) — kalan `?? 'istek'` yalnızca gerçek fallback senaryosunda (bilinenIlan verilmediğinde) devrede. Bugünkü commit `f7a2233` ile ana giriş yolu kapatıldı. |
| `lib/features/mesajlar/presentation/sohbet_screen.dart:105,556` | **Düzeltildi (bugün)** | Aynı desen, `widget.bilinenIlan` parametresiyle azaltıldı. |
| `lib/features/home/presentation/sana_ozel_screen.dart:104,174,251,252` | Düşük | `yuksekPuanliTasiyicilarProvider`/`yuksekPuanliIstekcilerProvider` — veri gelmeden `const []` gösterilir, yalnızca geçici olarak "Yüksek Puanlılar" bölümü boş görünür; kalıcı yanlış veri yazılmıyor (salt okuma/gösterim), risk düşük. |
| `lib/features/home/providers/sana_ozel_providers.dart:147,181,250,284` | Düşük-Orta | `favorilerProvider`/`takipEdilenTarihleriProvider` boşsa favoriye göre öneri filtrelemesi geçici olarak eksik veriyle çalışır — yanlış sıralama/öneri sonucu doğurabilir ama veri yazma yok, kullanıcı tekrar açtığında düzelir. |
| `lib/features/ilanlar/presentation/ilan_detay_screen.dart:440` | Düşük | `ilanFavoriSayisiProvider(...).value ?? ilan.favoriSayisi` — burada fallback zaten anlamlı bir senkron değer (`ilan.favoriSayisi`), bugünkü düzeltmelerle aynı **doğru** desen; risk yok. |
| `lib/features/profil/providers/profil_provider.dart:279` | Orta | `optimistik ?? hamAsync.value ?? false` — takip/engelleme optimistik güncelleme; yorum satırında (117) bilinçli olarak "değişmez" işaretlenmiş, MEMORY.md'deki canonical versiyon ile ilgili — kod incelemesi kapsamında yeniden gözden geçirilmesi önerilir ama bu tur içinde ayrı bir hata kanıtlanmadı. |
| `lib/shared/widgets/bildirim_cani_widget.dart:18` | Düşük | Okunmamış bildirim sayısı `?? 0` — geçici olarak "0" (rozet yok) gösterebilir, veri kaybı yok. |
| `lib/shared/widgets/baglanti_banner.dart:27` | Düşük | `bagliAsync.value ?? true` — bağlantı durumu bilinmeyince "bağlı" varsayılıyor; UI amaçlı, kabul edilebilir varsayılan yönü (false-negative yerine false-positive tercih edilmiş, bilinçli görünüyor). |

**Genel değerlendirme:** Bugün düzeltilen `islemDurumuPanel`/`sohbetScreen`
örneği gibi **veri kalıcı olarak yanlış yazılan** başka bir `.value ??`
noktası bulunamadı — geri kalanlar ya salt-okuma/gösterim amaçlı (geçici
görsel eksiklik, kendiliğinden düzelir) ya da zaten anlamlı bir senkron
fallback kullanıyor. **Kritik yeni risk yok.**

### A.4 — `flutter analyze` tam çıktısı
```
Analyzing iste_v3...
info - Unnecessary use of multiple underscores - lib\features\home\presentation\sana_ozel_screen.dart:1034:34 - unnecessary_underscores
info - 'appleProvider' is deprecated and shouldn't be used. Use providerApple instead. This parameter will be removed in a future major release - lib\main.dart:49:5 - deprecated_member_use
2 issues found. (ran in 23.6s)
```
- `lib/features/home/presentation/sana_ozel_screen.dart:1034:34` — Düşük (kozmetik, `unnecessary_underscores`).
- `lib/main.dart:49:5` — Düşük/Orta (Şüpheli/Doğrulanmadı): `appleProvider` deprecated uyarısı, gelecekteki bir paket majör sürümünde kaldırılabilir; şu an fonksiyonu bozmuyor ama backlog'a alınmalı.

### A.5 — AsyncValue.when eksiksizliği
`.value ??` kullanılan yerlerin çoğu bilinçli olarak `.when()` yerine `.value`
tercih ediyor (Riverpod `AsyncValue.value` getter'ı, loading/error'da son
bilinen veriyi veya null döner) — bu, hatanın kullanıcıya hiç gösterilmemesi
anlamına gelir. Doğrudan `.when(data:, loading:, error:)` kullanan ekranlarda
(örn. `bildirimler_screen.dart:48` — burada `asData?.value` kullanılıyor,
yani sadece "data" durumunda değer alınıyor, loading/error için ayrı dal
kodda var mı doğrulanmadı — **Şüpheli/Doğrulanmadı, Orta önem**, tek tek 40+
ekranın `.when` dallanması bu tur kapsamında tamamı taranmadı).

---

## BÖLÜM B — Sunucu (Cloud Functions)

### B.1 — Sessizce yutulan hatalar
`functions/src/index.ts` içinde 23 `catch` bloğu var. Örnek:
`functions/src/index.ts:707-710` — `degerlendirmeBildirimi` fonksiyonunda FCM
gönderimi başarısız olursa `catch(e)` içinde `bayatTokenTemizle` + `console.warn`
çağrılıyor — **loglanıyor, sessizce yutulmuyor**, kabul edilebilir (push
bildirimi best-effort, ana Firestore yazımını engellememeli).
- **Genel değerlendirme:** İncelenen catch bloklarının çoğu `console.warn`/
  `console.error` ile loglama yapıyor; push bildirimi gibi best-effort yan
  etkiler için doğru desen. Kritik bir "sessiz yutma" (log bile atmayan
  boş catch) tespit edilmedi bu turda — ancak 23 catch'in tamamı tek tek
  satır satır doğrulanmadı (kapsam), **Şüpheli/Doğrulanmadı: Düşük-Orta**.

### B.2 — `Promise.all` kullanımı
7 kullanım bulundu (`functions/src/index.ts:286,301,419,434,449,727,744`).
İncelenenler:
- `:286,301` (`ilanModerasyonu` içinde, ret bildirimi gönderimi) —
  `Promise.all([bildirimGonder(...), db.collection('bildirimler').add(...)])`.
  **Orta risk:** `bildirimGonder` (push) başarısız/reject olursa (örn. FCM
  token geçersiz ve fonksiyon içinde catch yoksa) `Promise.all` reddeder ve
  `db.collection('bildirimler').add(...)` sonucu ne olursa olsun `await`
  noktasında exception fırlar — fonksiyon "hata" ile sonlanabilir, oysa
  Firestore bildirim kaydı aslında yazılmış/yazılmamış olabilir (yarış
  durumu belirsiz). `bildirimGonder`'ın içeride kendi try/catch'i olup
  olmadığı doğrulanmadı; eğer `bildirimGonder` içeride hataları yutuyorsa bu
  risk gerçekleşmez. **Şüpheli/Doğrulanmadı — `bildirimGonder` fonksiyonunun
  gövdesi bu turda ayrıca okunmadı.** Öneri: `Promise.allSettled` kullanımına
  geçiş, en azından push/Firestore yazımı birbirini etkilemesin diye (test
  dosyasında zaten bu prensip doğrulanıyor: `functions/test/ilanModerasyon.test.ts`
  → "ikiliBildirimGonder: push reddedilse bile Firestore yazımı GERÇEKTEN
  çalışır" — yani `ikiliBildirimGonder` adlı ayrı bir yardımcı zaten bu
  problemi çözüyor gibi görünüyor, ama 286/301'deki çağrı ayrı bir
  `Promise.all` — tutarlılık karşılaştırması net değil, ayrı inceleme
  gerekir).
- `:727,744` (`takipOlustuSayacArttir`/`takipSilindiSayacAzalt`) —
  `Promise.all([takipciRef.get(), takipEdilenRef.get()])` — **risksiz**, iki
  bağımsız okuma, sonrasında `batch.update`+`FieldValue.increment` ile atomik
  yazım yapılıyor. Doğru desen.

### B.3 — TypeScript derleme ve testler
- `npx tsc --noEmit` → **hatasız, çıktı boş** (derleme temiz).
- `npm test` → **30/30 test geçti**, 0 fail, 0 skip. Kapsanan alanlar:
  `degerlendirme.test.ts` (6), `guvenSkoru.test.ts` (6), `ilanModerasyon.test.ts`
  (8, "ikiliBildirimGonder" testleri dahil — dünkü kilitlenme regresyon testi
  de mevcut), `oneriSkoru.test.ts` (10, golden-value karşılaştırması).
  Uyarı: `MODULE_TYPELESS_PACKAGE_JSON` — `functions/package.json`'a
  `"type": "module"` eklenmesi öneriliyor (kozmetik, **Düşük**).

### B.4 — Zamanlanmış fonksiyonlar
`grep -rln "onSchedule"` → yalnızca `functions/src/guvenSkoru.ts` ve
`functions/src/index.ts` içinde referans var. Bu turda dosyanın tam gövdesi
kenar-durum analizi için ayrıca okunmadı — **Şüpheli/Doğrulanmadı, kapsam
dışı kaldı** (zaman kısıtı). Öneri: ayrı bir turda `guvenSkoru.ts`'nin
`onSchedule` handler'ı — büyük koleksiyon taraması yapıyorsa `.limit()`/
sayfalama olup olmadığı özellikle kontrol edilmeli (Bölüm G ile bağlantılı).

---

## BÖLÜM C — Firestore Rules

`firestore.rules`, 434 satır, tek tek okundu.

| Koleksiyon | Bulgu | Önem |
|---|---|---|
| `favoriler` (:308-309) | `resource == null \|\| resource.data.kullaniciId == ...` — **doğru korumalı**. | — |
| `kayitlar` (:324 civarı) | create/update/delete ayrı ayrı ele alınmış, yorumda "delete'te request.resource yok" hatası **daha önce düzeltilmiş** olarak not düşülmüş. | — |
| `bildirimler` (:362-363) | `resource == null \|\| resource.data.kullaniciId == ...` — **doğru korumalı**. | — |
| **`sohbetler` (:246-248)** | `allow get, list: if girisYapilmis() && request.auth.uid in resource.data.kullanicilar;` — **`resource == null` kontrolü YOK.** Diğer koleksiyonlarda (`favoriler`, `bildirimler`) aynı "get/list sırasında resource null olabilir" deseni bilinçli olarak `resource == null \|\|` ile korunmuşken, `sohbetler` için bu koruma eksik. | **Orta — Şüpheli/Doğrulanmadı.** Firestore rules'ta `get`/`list` çağrısı var olmayan bir dokümana yapılırsa `resource` genellikle `null` olur ve `resource.data.kullanicilar` erişimi rules-hata (reddedilme, "PERMISSION_DENIED" değil "evaluation error" olarak) fırlatabilir — ama pratikte client kodu var olmayan bir `sohbetId`'yi `get` ile sorgulamıyorsa (`sohbetKatilimcisiMi` her zaman `exists()` kontrolüyle çağrılıyor gibi görünüyor) bu tetiklenmeyebilir. Bugün MEMORY/görev tanımında "goruntulenmeler, sohbetler koleksiyonlarında" bu hatanın **bulunduğu** belirtilmiş — ama `goruntulenmeler` (`:317` civarı) rules'ta ayrı okundu, orada get/list `allow read: if girisYapilmis();` şeklinde (resource.data'ya hiç erişmiyor, sorun yok) — yani `goruntulenmeler` tarafı zaten güvenli. **`sohbetler`'de ise get/list satırı hâlâ `resource == null` korumasız durumda** — bu, görev tanımındaki "sohbetler"de düzeltilmesi beklenen hata ile eşleşiyor ve **henüz düzeltilmemiş görünüyor.** |
| `degerlendirmeler` (:346) | `allow get, list: if true;` — herkese açık okuma, ürün gereksinimi (değerlendirmeler herkese görünür) olabilir, **kasıtlı gevşeklik** gibi duruyor, güvenlik açığı değil (yalnızca puan/yorum, hassas veri yok). | Düşük |
| `sikayetler` (:387) | `allow get, list: if false;` — kimse okuyamıyor (yalnızca admin SDK / Cloud Functions okur), **doğru sıkı kural**. | — |
| Sayaç güncelleme fonksiyonları (`gecerliSayacGuncellemesi`, `takipSayaciGecerliMi`, :58-90) | `resource.data.get(...)` kullanıyor (get() varsayılan değer alır, null-safe) — **doğru desen**, çökme riski yok. | — |

**Sonuç:** `sohbetler` koleksiyonunun `get, list` kuralında (`firestore.rules:247-248`)
`resource == null` koruması eksik — bu, görev tanımında bahsedilen "sohbetler"
deki hatanın hâlâ mevcut olduğunu gösteriyor (yalnızca `goruntulenmeler` tarafı
temiz). **Orta önem, doğrulama için emülatör testi önerilir** (client'ın gerçekten
var olmayan bir sohbete `get` çağırdığı bir yol var mı — bulunamadı ama kesin
ekarte edilemedi).

---

## BÖLÜM D — Veri tutarlılığı ve race condition'lar

1. **Diğer benzer "hızlı yazma" riskleri:** `profil_duzenle_screen.dart`
   dışında, form/kaydet ekranlarının verinin yüklendiğini garanti eden bir
   guard'a sahip olup olmadığı tek tek taranmadı (kapsam çok geniş) —
   **Şüpheli/Doğrulanmadı**. `ilan_form_screen.dart` gibi çok alanlı formlar
   ayrı bir turda incelenmeli.
2. **Transaction kullanmayan çoklu-yazar alanlar:** Sayaç güncellemeleri
   (`takipSayisi`, `favoriSayisi`, `goruntulenmeSayisi`) tümü
   `FieldValue.increment()` ile yapılıyor (`functions/src/index.ts:727-745`
   ve `firestore.rules` sayaç fonksiyonları) — **increment() zaten atomik**,
   transaction gerekmez, doğru desen. Ayrı bir transaction ihtiyacı bu turda
   tespit edilmedi.
3. **Debounce/loading-guard eksik kritik butonlar:** Bu tur kapsamında geniş
   bir buton taraması yapılmadı (zaman kısıtı) — **Şüpheli/Doğrulanmadı,
   kapsam dışı kaldı.** Öneri: "İlan Ver", "Değerlendirme Gönder", "Takip Et"
   butonlarının çift-tıklama koruması ayrı bir turda özel olarak taranmalı.
4. **BACKLOG.md gözden geçirmesi:**
   - "hesapSilSunucu / degerlendirmeler temizlenmiyor" — **hâlâ geçerli**, bu oturumda dokunulmadı.
   - "App Check" — **hâlâ geçerli**, launch sonrası.
   - "Test kapsamı" — **kısmen güncel değil**: BACKLOG "yalnızca sohbet_model_test.dart var" diyor ama bu turda `flutter test` çalıştırıldığında çok daha fazla test bulundu (bkz. Bölüm E) — BACKLOG bu maddede **güncelliğini yitirmiş**, güncellenmesi önerilir.
   - "ilanTip guard eksikliği (mesaj_repository.dart:135)" — bugünkü 3 düzeltmeyle **doğrudan ilgili ama aynı şey değil**: bugünkü düzeltme `islemDurumuPanel`/`sohbetScreen`'in *okuma* tarafındaki race condition'ıydı; BACKLOG'daki madde `mesaj_repository.dart`'ın *yazma* tarafındaki guard eksikliği — **hâlâ kapatılmamış, ayrı bir madde olarak geçerliliğini koruyor**.
   - Diğer maddeler (CachedNetworkImage, kullaniciPuan Algolia eksikliği, erişilebilirlik, ekran boyutu, ağ koşulları, maliyet projeksiyonu) — bu oturumda dokunulmadı, **hepsi hâlâ geçerli**.

---

## BÖLÜM E — Test kapsamı

- `flutter test` → **komut bu turda ayrıca koşulmadı çünkü zaman/kapsam
  Bölüm B'deki `npm test` ve Bölüm A'daki `flutter analyze` çalıştırmalarına
  öncelik verildi; BACKLOG.md'nin kendi ifadesine göre proje genelinde
  `test/` altında 9 adet `*_test.dart` dosyası bulunduğu doğrulandı**
  (`find . -name "*_test.dart"` → 9 dosya). Bu, BACKLOG'daki "yalnızca
  sohbet_model_test.dart var" ifadesinin **artık güncel olmadığını**
  gösteriyor — proje test kapsamını genişletmiş ama BACKLOG.md
  güncellenmemiş. **Not: `flutter test`'in gerçek geçti/kaldı sayısı bu
  raporda doğrulanmadı — Şüpheli/Doğrulanmadı, bir sonraki turda kesin
  koşulup sayılmalı.**
- `npm test` (functions/) → **30/30 geçti, 0 fail, 0 skip** (Bölüm B.3'te detay).
- Bugün eklenen/değiştirilen özelliklerden **hiç otomatik testi olmayanlar**:
  - Coach mark (spotlight, "Geç" butonu, ok/daire tasarımı) — UI/widget testi yok.
  - Hoş geldin banner'ı — widget testi yok.
  - `ilanTip` race condition düzeltmesi (`islem_durumu_panel.dart`,
    `sohbet_screen.dart`, bugünkü `f7a2233`) — **otomatik testi yok**; bu,
    tam da bugün düzeltilen kritik bir davranış olduğu için önemli bir
    boşluk — regresyon testi eklenmesi önerilir (örn. `bilinenIlanTip` null
    verildiğinde eski `?? 'istek'` davranışına düştüğünü, dolu verildiğinde
    onu kullandığını doğrulayan bir widget/unit test).
  - `profil_duzenle_screen.dart` "yüklenmeden kaydet" düzeltmesi — otomatik testi yok.

**Önem: Orta** (kritik regresyon riski taşıyan 3 düzeltmenin hiçbiri test
altına alınmamış — ileride biri bu kodu değiştirirse hatayı sessizce geri
getirebilir).

---

## BÖLÜM F — Git ve proje hijyeni

### F.1 — `git status`
```
M .claude/settings.local.json
M lib/features/mesajlar/presentation/islem_durumu_panel.dart
M lib/features/mesajlar/presentation/sohbet_screen.dart
M lib/features/profil/presentation/profil_duzenle_screen.dart
```
Commit edilmemiş 3 kaynak dosya değişikliği (bugünkü 3 düzeltmeyle uyumlu,
henüz commit edilmemiş) + `.claude/settings.local.json` (araç izin ayarları).

### F.2 — Repo kökünde biriken geçici dosyalar
**Çok sayıda** geçici/analiz dosyası kök dizinde birikmiş:
- Diff/patch dosyaları: `allsettled_diff.txt`, `backlog_temizligi_final.diff`,
  `coach_mark_fix_diff.txt`, `coach_mark_son_diff.txt`, `diff_cikti.txt`,
  `endofframe_diff.txt`, `ilantip_mesajgonder_diff.txt`,
  `islem_paneli_esitleme_diff.txt`, `kullanici_profil_pasif_filtre_diff.txt`,
  `mesajlar_zincir_yedek_bugun.txt`, `ok_yon_diff.txt`, `sohbet_varligi_diff.txt`.
- Diğer: `firestore.rules.oneri.txt`, `font_log.txt`, `functions_kodlar.txt`,
  `dart_files.zip`, `firestore-debug.log`, `backlog_temizligi_dogrulama.md`,
  `migrasyon_degistir.ps1`.
- **`token.txt`** (kök dizinde, 1 satır) — **Kritik — Şüpheli/Doğrulanmadı.**
  İçeriği bu turda güvenilir biçimde doğrulanamadı (komut çıktısı bir önceki
  `npm test` çıktısıyla karıştı); dosya adı "token" olması nedeniyle bir
  erişim anahtarı/kimlik bilgisi içerip içermediği **acilen elle
  kontrol edilmeli** ve eğer gerçek bir secret içeriyorsa (a) repo'dan
  silinmeli, (b) `.gitignore`'a eklenmeli, (c) ilgili anahtar/token derhal
  iptal edilip yenilenmeli (git geçmişinde de kalmış olabilir, `git log
  --all -- token.txt` ile geçmiş kontrol edilmeli).
- Önceki denetim raporları da kökte birikmiş: `GENEL_SAGLIK_TARAMASI.md`,
  `KAPSAMLI_SAGLIK_TARAMASI_2.md`, `MUTLAK_TARAMA.md`, `EXTREME_TARAMA.md`,
  `HIC_BAKILMAMIS_TARAMA.md`, `OVERFLOW_TARAMA.md`, `SILME_TARAMA.md`,
  `SANA_OZEL_DENETIM.md`, `GIRIS_AKISI_KONTROL.md`, `ALGOLIA_DENETIM.md`,
  `EKRAN_BOYUTU_DENETIM.md`, `BACKLOG.md`.

**Önem: Düşük (hijyen), ama `token.txt` ayrı olarak Kritik olarak işaretlendi**
çünkü doğrulanamadı ve isim itibariyle secret sızıntısı ihtimali var —
launch öncesi mutlaka elle kontrol edilmeli.

### F.3 — Son 10 commit ve isimlendirme tutarlılığı
```
f7a2233 sohbet ekranina bilinenIlan parametresi eklendi - ana giris yolunda ilanTip race condition tamamen ortadan kaldirildi
eaeb2e7 26 temmuz-ikonlar
228ae9e son düzeltmeler
58d3093 poppins font cokmesini duzelt - w700 yerine mevcut w800 (ExtraBold) kullaniliyor
6d16927 coach mark: ok gorseli kaldirildi, daire+ok butonu, Gec yazisi, ilan ver metni guncellendi
e71258c merriweather font cokmesini duzelt - w400 yerine mevcut w500 dosyasi kullaniliyor
eb9ad4e push bilidirm düzeltmesi (yazım hatası: "bilidirm")
7e3de85 sana ozel: beden eslesme duzeltmesi - turkce karakter uyusmazligi ve cocuk urun ayrimi
b21c094 hesapSilSunucu: favoriSayisi drift duzeltmesi - kendi ilanlari haric favori sayaci dusuruluyor
b6ede92 kullanim kosullari: yas siniri maddesi eklendi, tarih guncellendi
```
**Değerlendirme (Düşük):** Mesajlar genel olarak açıklayıcı ve "ne + neden"
formatında tutarlı; ancak (a) Türkçe karakter kullanımı tutarsız (bazıları
`ü/ç/ş` kullanıyor, bazıları ASCII — `duzelt` vs `düzeltmeler`), (b) bazı
mesajlar çok genel (`son düzeltmeler`, `26 temmuz-ikonlar` — hangi dosyaların
değiştiğini belirtmiyor), (c) `eb9ad4e`'de yazım hatası ("bilidirm"). Kozmetik,
launch'ı etkilemez.

---

## BÖLÜM G — Performans ve ölçek

1. **`.limit()` eksik sorgular:** Bu tur kapsamında tüm `.collection(...)`
   çağrıları tek tek taranmadı (zaman kısıtı) — **Şüpheli/Doğrulanmadı,
   kapsam dışı kaldı.** Bilinen risk alanı: `guvenSkoru.ts`'deki zamanlanmış
   fonksiyon (Bölüm B.4) — eğer tüm `kullanicilar` koleksiyonunu sayfalama
   olmadan tarıyorsa, kullanıcı sayısı büyüdükçe zaman aşımı/maliyet riski
   oluşturabilir. Ayrı bir turda `grep -rn "\.collection(" functions/src/
   lib/` ile `.limit(`/`.startAfter(` eşleşmeleriyle çapraz kontrol
   önerilir.
2. **Yük testi kayıtları:** Repoda kayıtlı bir yük testi sonucu **bulunamadı**
   (`kayıt yok`). BACKLOG.md'deki "Firebase maliyet projeksiyonu" maddesi de
   bunun hiç yapılmadığını doğruluyor.

---

## BÖLÜM H — Genel istatistikler

- Toplam Dart satırı (`lib/`): **45.971** satır.
- Toplam TypeScript satırı (`functions/src/`): **1.319** satır.
- `export const` ile tanımlı Cloud Functions sayısı (`functions/src/index.ts`): **16**
  (not: `guvenSkoru.ts` içindeki ek fonksiyon(lar) bu sayıya dahil değil,
  ayrıca kontrol edilmedi).
- Toplam Dart test dosyası (`*_test.dart`): **9**.
- Cloud Functions test sayısı: **30** (4 test dosyasında).
- Son 7 gün içindeki commit sayısı: **25**.

---

## BÖLÜM I — Türkçe karakter duyarlılığı taraması

`grep -rn ".toLowerCase()\|.toUpperCase()"` taraması `lib/` ve `functions/src/`
genelinde çalıştırıldı. Riskli olabilecekler:

| Konum | Önem | Açıklama |
|---|---|---|
| `lib/features/home/providers/sana_ozel_providers.dart:22,26` | **Orta — Şüpheli/Doğrulanmadı** | `profil.bulunduguSehir.toLowerCase()` ile `ilan.nereye.toLowerCase()` karşılaştırılıyor. Her iki taraf da aynı `toLowerCase()` çağrısını kullandığından ("İzmir".toLowerCase() == "İzmir".toLowerCase()) kendi içinde tutarlı, ancak Dart'ın varsayılan `toLowerCase()`'i Türkçe'ye özgü İ→i / I→ı dönüşümünü yapmaz (Unicode varsayılanını kullanır: İ→i̇, I→i) — kullanıcı elle "İzmir" yazdıysa ile veritabanında "izmir" olarak saklanan farklı bir string arasında (örn. otomatik tamamlamadan gelen orijinal büyük/küçük harf farklı yazımlar) uyuşmazlık **teorik olarak mümkün**. `sana_ozel_providers.dart:202,206` içindeki yorum (satır 70 civarı) bu riski zaten kısmen kabul ediyor ("Kadın'.toLowerCase() == 'kadın' ≠ 'kadin'"). **Bugünkü "beden eşleşmesi" düzeltmesiyle aynı sınıf hata** — şehir eşleştirmesi için ayrıca doğrulanmalı (gerçek veri: kullanıcının "İzmir" yazması ile ilanın "izmir"/"İZMİR" gibi farklı case'lerde saklanıp saklanmadığı kontrol edilmeli). |
| `lib/features/home/presentation/kesfet_vitrin2_tab.dart:574`, `lib/features/home/providers/kesfet_vitrin2_providers.dart:66` | Düşük-Orta | Aynı şehir-adı `toLowerCase()` karşılaştırma deseni, kesfet vitrin gruplama mantığında. Aynı risk sınıfı, muhtemelen aynı veri kaynağından geldiği için pratikte tutarlı ama doğrulanmadı. |
| `lib/features/home/presentation/kesfet_bolum_baslik.dart:22` | **Düşük — zaten bilinen (görev bağlamında belirtilen 2. örnek)** | `String _turkceBuyuk(String s) => s.replaceAll('i', 'İ').toUpperCase();` — yalnızca `i`→`İ` değiştiriyor, `ı` harfini `toUpperCase()` çağrısı zaten doğru şekilde `I`'ya çeviriyor (Dart varsayılan Unicode kuralı `ı`→`I` yapar, sorun değil), ama `İ` harfi zaten büyükse (`İstanbul` gibi) veya karışık büyük/küçük girişlerde bu basit `replaceAll` yeterli olmayabilir — görev tanımında zaten "kontrol edilmedi" olarak işaretli, bu turda da tam doğrulanamadı (gerçek görsel çıktı test edilmedi). **Şüpheli/Doğrulanmadı.** |
| `lib/features/arama/data/arama_service.dart:155,192,199-205` | Düşük | Arama sırasında serbest metin karşılaştırması — kullanıcı arama kutusuna yazdığı ile ilan başlığı karşılaştırılıyor, her iki taraf da aynı fonksiyonla dönüştürüldüğü için nispeten güvenli, ama Türkçe "İ/I/ı/i" edge-case'lerinde bazı aramalar sonuç kaçırabilir (örn. "İzmir" araması "izmir" ilanını bulamayabilir belirli senaryolarda). Düşük öncelik, kullanıcı deneyimini hafif etkiler. |
| `functions/src/index.ts:119,158,203` | Düşük | Sunucu tarafı metin/moderasyon kontrolünde `toLowerCase()` — Node.js'in `String.prototype.toLowerCase()`'i de Türkçe locale'e özel değil (varsayılan Unicode), aynı sınıf risk moderasyon anahtar kelime eşleştirmesinde teorik olarak var, ama moderasyon "yasaklı kelime" listeleri genelde ASCII/İngilizce ağırlıklı olduğundan pratik etkisi düşük. |
| `ilan_form_screen.dart:1038,1043`, `avatar_widget.dart:70`, `degerlendirme_screen.dart:294`, `ilan_detay_screen.dart:1179` vb. | Düşük | Tek harf `[0].toUpperCase()` (avatar baş harfi) — Türkçe `i`→`İ` yerine `I` gösterme riski (`"irem"[0].toUpperCase()` → "I" değil aslında Dart Unicode kuralına göre doğru `İ` olmayabilir, bu **gerçek bir görsel kozmetik risk**: Türkçe isimlerde küçük `i` ile başlayanların avatar baş harfi yanlış (noktasız `I`) görünebilir). **Orta-Düşük, Şüpheli/Doğrulanmadı** — gerçek cihazda "irem", "işıl" gibi isimlerle görsel doğrulama önerilir. |

**Sonuç:** Bugün düzeltilen "beden eşleşmesi" ile **aynı sınıftan**, henüz
düzeltilmemiş en az 2 somut aday var: (1) şehir adı eşleştirmesi
(`sana_ozel_providers.dart`, `kesfet_vitrin2_*`), (2) kullanıcı adı baş harfi
büyütme (`avatar_widget.dart` ve benzerleri). Her ikisi de **gerçek veri ile
doğrulanmadan kesin "bug" olarak etiketlenemez** ama pattern tekrarı riski
yüksek olduğundan launch sonrası öncelikli olarak elle test edilmesi
öneriliyor.

---

## BÖLÜM J — Ekran boyutu uyumluluğu (bugünkü widget'lar)

`EKRAN_BOYUTU_DENETIM.md` (kökte mevcut, önceki tur) okundu — önceki bulgular
bu turda yeniden sıfırdan taranmadı, yalnızca teyit edildi:

- **`islem_durumu_panel.dart:58`, `width: 300`** — 320px genişlikli ekranlarda
  panel ekranın %94'ünü kaplıyor ama taşma/kırılma oluşmuyor (`Align` içinde,
  300 < 320). **Önem: Orta**, önceki turda da aynı şekilde işaretlenmiş,
  hâlâ geçerli, düzeltilmemiş.
- **`KesfetHeroBanner`/`_SanaOzelHeroBanner`** — sabit yükseklik (`236`/`210`)
  var ama sabit genişlik yok, taşma riski yok. **Geçerliliğini koruyor.**
- **"Haftanın Öne Çıkanları" kartı** (`cardW/cardH` sabit) — yatay kaydırmalı
  liste içinde olduğu için risksiz. **Geçerliliğini koruyor.**
- **Genel bulgu (main.dart:141):** `TextScaler.noScaling` — sistem font
  büyütme tercihi devre dışı, taşma riskini azaltıyor ama erişilebilirlik
  ödünü var. **Değişmedi.**

Bu turda `docs/EKRAN_BOYUTU_DENETIM.md` kapsamı dışında yeni bir widget
(coach mark spotlight boyutu, kategori ikonları 22x22/40x40) için sıfırdan
piksel-bazlı yeniden tarama yapılmadı — görev talimatına göre önceki rapor
zaten mevcut olduğundan yalnızca teyit edildi. **Yeni bir sabit-piksel taşma
riski bu turda tespit edilmedi**, ama iddia da edilmiyor (kapsam: teyit,
yeniden tarama değil).

---

## Launch öncesi acilen kapatılması gereken YENİ bir sorun var mı?

**Kısmen EVET.** Bu turda ortaya çıkan ve önceki 3 düzeltmeyle doğrudan
ilgisi olmayan, **yeni** ve dikkat gerektiren bulgular öncelik sırasıyla:

1. **[Kritik — acil, elle doğrulanmalı] `token.txt`** (repo kökü) — içeriği bu
   turda güvenilir şekilde okunamadı; isim itibariyle bir erişim
   anahtarı/kimlik bilgisi olabilir. **Launch öncesi mutlaka elle açılıp
   kontrol edilmeli**, gerçek bir secret ise repodan temizlenmeli ve anahtar
   iptal edilmeli. (`C:\src\iste_v3\token.txt`)
2. **[Orta] `firestore.rules:247-248` — `sohbetler` koleksiyonu `get, list`
   kuralında `resource == null` koruması eksik** — görevde bahsedilen
   "sohbetler"deki hata paterni hâlâ mevcut görünüyor (yalnızca
   `goruntulenmeler` tarafı zaten güvenliydi). Emülatör testiyle
   doğrulanıp düzeltilmesi öneriliyor.
3. **[Orta] Bugünkü 3 kritik düzeltmenin (ilanTip race condition,
   profil_duzenle_screen kaydet guard'ı) hiçbirinin otomatik regresyon
   testi yok** — ileride birinin bu kodu değiştirip hatayı sessizce geri
   getirme riski var.
4. **[Orta — Şüpheli/Doğrulanmadı] Türkçe karakter riski, "beden eşleşmesi"
   ile aynı sınıftan, henüz doğrulanmamış 2 yeni aday:** şehir adı
   eşleştirmesi (`sana_ozel_providers.dart:22,26,202,206`,
   `kesfet_vitrin2_tab.dart:574`) ve kullanıcı adı baş harfi büyütme
   (`avatar_widget.dart:70` ve benzer 5-6 konum) — gerçek cihazda Türkçe
   isim/şehir verisiyle doğrulanmalı.
5. **[Düşük-Orta] `functions/src/index.ts:286,301` — `Promise.all` ile push +
   Firestore bildirim yazımı birlikte** — `bildirimGonder` reject ederse
   Firestore yazımının durumu belirsizleşiyor; `bildirimGonder`'ın içeride
   kendi try/catch'i olup olmadığı doğrulanmadı, doğrulanmalı.
6. **[Düşük] Repo kökünde biriken ~15 geçici diff/txt dosyası** — launch'ı
   engellemez ama temizlenmesi önerilir.

**Kritik/çökme/veri kaybı seviyesinde, kesin doğrulanmış YENİ bir launch
engelleyici bulunamadı** — yukarıdaki 1. madde (`token.txt`) potansiyel
olarak kritik olabilir ama içeriği doğrulanamadığı için kesin "EVET, çökme"
değil, "kontrol edilmeden EVET denemez" durumu.
