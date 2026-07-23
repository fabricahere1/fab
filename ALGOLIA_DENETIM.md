# Algolia Entegrasyonu Denetimi

Bu rapor SALT-OKUMA bir denetimin sonucudur. Hiçbir dosya değiştirilmedi,
Algolia'ya hiçbir veri yazılmadı/silinmedi.

---

## BÖLÜM A — Senkronizasyon Mekanizması

### A.1 — Tetikleyiciler ve TAM kod

**`ilanModerasyonu`** (`onDocumentCreated`, `functions/src/index.ts:263-384`) — yeni ilan oluşturulduğunda moderasyondan geçip onaylanırsa (`onerilenPuan` hesaplanıp) HEM `ALGOLIA_INDEX` HEM `ALGOLIA_INDEX_NEREYE`'e `saveObject` çağrısı yapıyor:
```ts
await getAlgoliaClient().saveObject({
  indexName: ALGOLIA_INDEX,
  body: {
    objectID: ilanId, urun: data.urun ?? "", nereden: data.nereden ?? "",
    nereye: data.nereye ?? "", kategori: data.kategori ?? "",
    anaKategori: data.anaKategori ?? "", kategoriYolu: data.kategoriYolu ?? [],
    tip: data.tip ?? "", aktif: true, durum: "yayinda", kullaniciId,
    kullaniciAd: data.kullaniciAd ?? "",
    resimUrl: resimUrller.length > 0 ? resimUrller[0] : (data.resimUrl ?? ""),
    olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
    favoriSayisi: data.favoriSayisi ?? 0, goruntulenmeSayisi: data.goruntulenmeSayisi ?? 0,
    onerilenPuan,
  },
});
...
await getAlgoliaClient().saveObject({
  indexName: ALGOLIA_INDEX_NEREYE,
  body: { objectID: ilanId, nereye: data.nereye ?? "" },
});
```

**`ilanGuncellendi`** (`onDocumentUpdated`, `:467-536`) — aktif↔pasif geçişlerini ve genel alan güncellemelerini yönetiyor:
```ts
export const ilanGuncellendi = onDocumentUpdated(
  { document: "ilanlar/{ilanId}", database: DATABASE_ID },
  async (event) => {
    const once  = event.data?.before.data();
    const sonra = event.data?.after.data();
    if (!sonra) return;

    const oncedenAktifti = once ? (once.aktif === true && once.durum === "yayinda") : false;
    const simdiAktif     = sonra.aktif === true && sonra.durum === "yayinda";

    if (oncedenAktifti && !simdiAktif) {
      // İKİ index'ten de sil
      await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX, objectID: event.params.ilanId });
      await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX_NEREYE, objectID: event.params.ilanId });
      return;
    }
    if (!simdiAktif) return; // zaten pasifti, gereksiz çağrı yapma

    const data = sonra;
    const onerilenPuan = onerilenPuanHesapla(data);
    await db.collection("ilanlar").doc(event.params.ilanId).update({ onerilenPuan });

    await getAlgoliaClient().saveObject({
      indexName: ALGOLIA_INDEX,
      body: {
        objectID: event.params.ilanId, urun: data.urun ?? "", nereden: data.nereden ?? "",
        nereye: data.nereye ?? "", kategori: data.kategori ?? "", anaKategori: data.anaKategori ?? "",
        kategoriYolu: data.kategoriYolu ?? [], tip: data.tip ?? "", aktif: data.aktif ?? false,
        durum: data.durum ?? "onayBekliyor", kullaniciId: data.kullaniciId ?? "",
        kullaniciAd: data.kullaniciAd ?? "",
        resimUrl: (data.resimUrller && data.resimUrller.length > 0) ? data.resimUrller[0] : (data.resimUrl ?? ""),
        olusturmaTarihi: data.olusturmaTarihi?.toMillis() ?? Date.now(),
        favoriSayisi: data.favoriSayisi ?? 0, goruntulenmeSayisi: data.goruntulenmeSayisi ?? 0,
        onerilenPuan,
      },
    });
    await getAlgoliaClient().saveObject({
      indexName: ALGOLIA_INDEX_NEREYE,
      body: { objectID: event.params.ilanId, nereye: data.nereye ?? "" },
    });
  }
);
```

**`ilanSilindi`** (`onDocumentDeleted`, `:538-559`) — ilan tamamen silinince İKİ index'ten de `deleteObject` yapıyor, ayrıca `favoriler`/`goruntulenmeler` koleksiyonlarını da temizliyor (bu, önceki "Silme Tarama" raporunda zaten detaylı incelenmişti).

**`algoliaTopluAktar`** (`onCall`, admin-only, `:561-608`) — tüm `ilanlar` koleksiyonunu tarayıp toplu olarak İKİ index'e de `saveObjects` yapıyor, aynı alan listesiyle.

### A.2 — Alan bazında eksiksizlik kontrolü

| Alan | `ilanModerasyonu` | `ilanGuncellendi` | `algoliaTopluAktar` | Durum |
|---|---|---|---|---|
| `nereden` | ✅ | ✅ | ✅ | Tam |
| `nereye` | ✅ | ✅ | ✅ | Tam |
| `kategori` | ✅ | ✅ | ✅ | Tam |
| `anaKategori` | ✅ | ✅ | ✅ | Tam |
| `kategoriYolu` | ✅ | ✅ | ✅ | Tam |
| `onerilenPuan` (hesaplanan) | ✅ | ✅ | ✅ | Tam |
| `favoriSayisi` | ✅ | ✅ | ✅ | Tam |
| `goruntulenmeSayisi` | ✅ | ✅ | ✅ | Tam |
| `durum` | ✅ | ✅ | ✅ | Tam |
| `aktif` | ✅ | ✅ | ✅ | Tam |
| **`kullaniciPuan`** | ❌ | ❌ | ❌ | **EKSİK — üç fonksiyonda da yok** |

**BULGU — "unutulmuş alan" doğrulandı: `kullaniciPuan`.** Firestore'da bu alan gerçekten var (`ilan_model.dart:58`, ilan oluşturulurken satıcının o anki `ortalamaPuan`'ı ile dolduruluyor — `ilan_repository.dart:362-367`) ve `degerlendirmePuanGuncelle`'nin fan-out mekanizması (`index.ts:783-807`) tarafından satıcı yeni değerlendirme aldıkça **aktif olarak güncelleniyor**. Ama **hiçbir Algolia `saveObject`/`saveObjects` çağrısında `kullaniciPuan` alanı yok** — üç senkronizasyon noktasında da (`ilanModerasyonu`, `ilanGuncellendi`, `algoliaTopluAktar`) sistematik olarak atlanmış.

**Pratik etki — DÜŞÜK, ama gerçek bir boşluk:**
- `onerilenPuanHesapla()` (`functions/src/onerilenPuan.ts:11-12`) sunucu tarafında `data.kullaniciPuan`'ı **Firestore dokümanından** okuyup Bayesian düzeltmeyi uyguluyor, sonucu (`onerilenPuan`, kompozit skor) Algolia'ya doğru şekilde yazıyor — yani **sıralama** etkilenmiyor, çünkü türetilmiş skor zaten rating'i içeriyor.
- `IlanKarti` widget'ı (`grep -rn "kullaniciPuan" ilan_karti.dart` → sıfır sonuç) kartlarda ham puanı hiç göstermiyor — görsel bir regresyon yok.
- Ama **Algolia'dan gelen bir `IlanModel`'in `kullaniciPuan` alanı her zaman varsayılan `0.0`** (`ilanlar_screen.dart:71-99`'daki `_hittenIlan()` ve `gelenler_screen.dart:66-93`'teki `_gHittenIlan()`, ikisi de bu alanı hiç map etmiyor — zaten Algolia hit'inde alan olmadığı için map edecek bir şey de yok). `sana_ozel_providers.dart:242`'deki `onayliIstekler` provider'ı (`i.kullaniciPuan >= 4.0` filtresi) **Firestore tabanlı** `istekIlanlarProvider`'ı kullandığı için etkilenmiyor — ama gelecekte biri Algolia-kaynaklı bir listede `kullaniciPuan`'a dayalı bir özellik eklerse (ör. kart üzerinde satıcı puanı rozeti), sessizce her zaman 0.0/boş gösterecek.

### A.3 — İki index'in senkronizasyonu

**Tam tutarlı, SAĞLIKLI.** Üç fonksiyonun (`ilanModerasyonu`, `ilanGuncellendi`, `algoliaTopluAktar`) hepsi, ana `ALGOLIA_INDEX` ile `ALGOLIA_INDEX_NEREYE`'i **birlikte** güncelliyor/siliyor — hiçbir yerde biri güncellenirken diğeri unutulmuş bir durum yok. `ilanGuncellendi`'deki kod yorumu bunu açıkça belgeliyor: "yalnızca ana index'i silmek yetmez — ALGOLIA_INDEX_NEREYE'de de kalır, arama sonuçlarında görünmeye devam eder" — yani bu iki-index deseni bilinçli bir tasarım, geçmişte muhtemelen bir bug olarak bulunup düzeltilmiş.

**Sonuç — Bölüm A: SORUN VAR** (düşük öncelikli — `kullaniciPuan` alanı üç senkronizasyon noktasında da Algolia'ya yazılmıyor, ama sıralamayı etkilemiyor, yalnızca UI'da gelecekte kullanılabilecek ham veriyi eksik bırakıyor).

---

## BÖLÜM B — Filtreleme/Sıralama Tutarlılığı

### B.1 — `algoliaFiltrele()` parametreleri (`arama_service.dart:220-` )

| Parametre | Hedef alan/index | Durum |
|---|---|---|
| `kategoriYolu`/`seciliAltKeyler` | `kategoriYolu`/`kategori` (ana index) | Doğru |
| `sehirler` | `nereye` (ana index) | Doğru |
| `ulkeSehir` | `nereye` (ana index) — istekler ekranı | Doğru |
| `nerdenUlkeSehir` | `nereden` (ana index) — gelenler ekranı | Doğru |
| `neredenUlke` (bugün eklendi) | `nereden` (ana index) — "Nereden Geliyor" | Doğru, aynı alana ek bağımsız AND koşulu |
| `siralama` | index seçimi (`ilanlar_favori`/`ilanlar_onerilen`/`ilanlar_eski`/varsayılan) | bkz. B.2 |
| `ilanTipi` | `tip:$ilanTipi` | Doğru |

**Bugün bulduğumuz "Türkiye Dışı yanlış alan kullanıyor" türünden gizli bir hata bu listede YOK** — çünkü `TurkiyeDisiAramaEkrani`'nin `alan` parametresi eksikliği `algoliaFiltrele()`'nin kendisinde değil, onu **çağıran UI tarafında** (`gelenler_filtre_ekrani.dart`) bir eksiklikti; `algoliaFiltrele()`'nin kendisi her zaman doğru alana filtre uyguluyor.

### B.2 — Sıralama seçenekleri

```dart
final indexAdi = switch (siralama) {
  'enCokFavorilenen' => 'ilanlar_favori',
  'onerilen'         => 'ilanlar_onerilen',
  'enEski'           => 'ilanlar_eski',
  _                  => _kAlgoliaIndex,
};
```

"Onerilen" seçilince gerçekten **ayrı bir replika index'e** (`ilanlar_onerilen`) yönlendiriliyor. Bu replikanın `customRanking` ayarının gerçekten `onerilenPuan` alanına göre azalan sıralanıp sıralanmadığını **kod içinden doğrulayamıyorum** — bu ayar Algolia Dashboard'da tanımlanıyor olmalı (bkz. Bölüm C). Kod tarafında tutarlı olan tek şey: `onerilenPuan` alanı her zaman doğru hesaplanıp Algolia'ya yazılıyor (Bölüm A.2'de doğrulandı) — replikanın bu alana göre sıralaması ise Dashboard konfigürasyonuna bağlı, **DOĞRULANAMADI**.

**Sonuç — Bölüm B: SAĞLIKLI** (kod tarafı), `onerilen` sıralamasının replika ayarı **DOĞRULANAMADI** (dashboard'a bağlı).

---

## BÖLÜM C — Index Ayarları

### C.1 — `attributesForFaceting`/`searchableAttributes`/`customRanking` kodda tanımlı mı?

```
$ grep -rn "attributesForFaceting|customRanking|searchableAttributes|setSettings" functions/src/index.ts arama_service.dart
(sıfır sonuç)
$ find . -iname "*algolia*" (config/json dosyası)
(sıfır sonuç)
```

**Kodda hiçbir index ayarı tanımlanmıyor.** Repo içinde Algolia'ya ait tek bir settings/config dosyası da yok. **NET rapor: bu ayarlar kod dışında, muhtemelen Algolia Dashboard'da manuel olarak yapılandırılmış.** Bu, versiyon kontrolü olmayan, yalnızca bir kişinin (muhtemelen bd'nin) Dashboard'da yaptığı, repo'da hiç iz bırakmayan bir konfigürasyon anlamına geliyor — index'ler yeniden oluşturulursa (ör. farklı bir Algolia hesabına taşınırsa) bu ayarların manuel olarak yeniden girilmesi gerekir, hiçbir yerde otomatik/tekrarlanabilir değil.

### C.2 — `nereden` alanı filtrelenebilir mi?

**Dolaylı olarak doğrulandı, EVET.** `nerdenUlkeSehir` parametresi (gelenler ekranının "Türkiye Dışı" filtresi) `nereden:"..."` filtresini **bugünden çok önce, aylardır** kullanıyordu (bu mekanizma 2026-06-24 tarihli "ülke-sehir" commit'inde eklenmişti — önceki turda doğrulandı). Eğer `nereden` facet/filterable olarak ayarlı olmasaydı, bu filtre aylardır hata verirdi. Bugün eklenen `neredenUlke` parametresi **aynı `nereden` alanına, aynı sözdizimiyle** (`nereden:"$deger"`) filtre uyguladığı için, zaten çalışan bir mekanizmanın üzerine kurulu — ayrıca bir facet kaydı gerektirmiyor.

**Sonuç — Bölüm C: DOĞRULANAMADI** (ayarların kendisi kod dışında olduğu için doğrudan gösterilemiyor) **ama dolaylı kanıtlarla (mevcut filtrelerin çalışıyor olması) index ayarlarının muhtemelen doğru yapılandırıldığı sonucuna varılabilir.**

---

## BÖLÜM D — Bilinen Geçmiş Bulgular

### D.1 — "ikinciel projesi" çapraz-proje veri sızıntısı riski

```
$ grep -rli "ikinciel" memory-dizini
(sıfır sonuç)
$ grep -rni "ikinciel" tüm repo (.dart/.ts/.md/.json)
(sıfır sonuç)
```

**DOĞRULANAMADI.** Bu konuda ne mevcut memory dosyalarımda (`MEMORY.md` ve bağlı dosyalar) ne de repo içinde (kod, yorum, config, markdown) hiçbir iz bulamadım. Bu endişe muhtemelen bu oturumun çok daha önceki, özetlenmiş/sıkıştırılmış bir bölümünde geçmiş olabilir ve elimdeki kayıtlarda yok. Bunu doğrulayabilmem için ya orijinal konuşmanın ilgili kısmını (transcript dosyası) ya da Algolia Dashboard'daki uygulama/API anahtarı düzeyinde bir kontrolü (hangi App ID kullanılıyor, başka bir projeyle paylaşılıyor mu) gerektirir — ikisine de bu ortamdan erişimim yok. **Net cevap veremiyorum, bd'nin bunu Algolia Dashboard'dan (App ID/proje ayrımı) doğrudan kontrol etmesi gerekiyor.**

### D.2 — BACKLOG.md'deki Algolia maddeleri

```
$ grep -n -i "algolia" BACKLOG.md
51:  ile `functions/src/onerilenPuan.ts` (sunucu, Algolia `onerilenPuan`
54:  YOK (Algolia'nın `olusturmaTarihi` ikincil sıralama kriteri bu işi
```

Yalnızca **tek bir madde var**, ve bu zaten "Düşük öncelik" bölümünde, **bilinçli bir tasarım farkı olarak işaretlenmiş, bug değil**: `oneriSkoru`/`onerilenPuanHesapla` arasındaki client/sunucu formül farkı (client'ta "tazelik" bileşeni var, sunucuda yok — golden-value testleriyle doğrulanmış, kod değişikliği gerektirmiyor). Başka hiçbir Algolia maddesi BACKLOG'da yok.

**Sonuç — Bölüm D: DOĞRULANAMADI** (D.1, erişim kısıtı nedeniyle) + **SAĞLIKLI** (D.2, BACKLOG'da başka açık madde yok).

---

## ÖZET TABLO

| Bölüm | Konu | Durum |
|---|---|---|
| A.1-A.2 | Senkronizasyon — alan eksiksizliği | **SORUN VAR** (kullaniciPuan 3 fonksiyonda da eksik, düşük etki) |
| A.3 | İki index senkronizasyonu | SAĞLIKLI |
| B.1 | Filtre parametreleri → doğru alan/index | SAĞLIKLI |
| B.2 | "Onerilen" sıralamasının replika ayarı | DOĞRULANAMADI (dashboard'a bağlı) |
| C.1 | Index ayarlarının kod içinde tanımlı olması | DOĞRULANAMADI (kod dışında — dashboard'da olmalı) |
| C.2 | `nereden` alanının filtrelenebilirliği | SAĞLIKLI (dolaylı kanıtla) |
| D.1 | "ikinciel" çapraz-proje riski | DOĞRULANAMADI (hiçbir iz yok, erişim kısıtı) |
| D.2 | BACKLOG'daki diğer Algolia maddeleri | SAĞLIKLI (yalnızca 1 bilinçli/kapatılmış madde) |

---

## Launch öncesi acilen kapatılması gereken bir sorun var mı?

**Hayır.** Bulunan tek somut, kod-seviyesinde kesin sorun (`kullaniciPuan`'ın Algolia'ya senkronize edilmemesi) **düşük etkili** — sıralamayı bozmuyor (çünkü türetilmiş `onerilenPuan` zaten doğru hesaplanıyor), hiçbir ekranda görsel bir regresyona yol açmıyor (kartlar bu alanı göstermiyor). Launch'ı engellemez, ama düzeltilmesi ucuz olduğu için not ediyorum:

**Öncelik sırası (launch sonrası, acil değil):**
1. `kullaniciPuan`'ı üç `saveObject`/`saveObjects` çağrısına da eklemek (küçük, düşük riskli bir değişiklik) — BACKLOG.md'ye eklenmesi önerilir, şu an orada kayıtlı değil.
2. "ikinciel" çapraz-proje riskini bd'nin Algolia Dashboard'dan (App ID ayrımı) doğrudan kontrol etmesi — kod tarafında doğrulanamıyor.
3. Index ayarlarının (`attributesForFaceting`/`customRanking`) hiçbir yerde versiyon kontrolünde olmaması — acil değil ama gelecekte "neden bu filtre çalışmıyor" gibi bir sorun çıkarsa, Dashboard'daki mevcut ayarların bir kopyasının (screenshot ya da JSON export) repo'ya/dokümantasyona eklenmesi önerilir.
