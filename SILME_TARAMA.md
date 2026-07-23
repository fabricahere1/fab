# Silme Tarama — Orphan Veri Raporu

Bu rapor SALT-OKUMA bir taramanın sonucudur. Hiçbir dosya değiştirilmedi,
hiçbir veri silinmedi. Amaç: uygulamadaki dört ana silme akışının (ilan,
mesaj/sohbet, hesap, favori/takip/bildirim) arkasında "çöp" (orphan veri)
birikip birikmediğini tespit etmek.

---

## BÖLÜM A — İlan Silme

**Client (`lib/features/ilanlar/data/ilan_repository.dart:491-498`):**

```dart
Future<void> ilanSil(String ilanId) async {
  // Sadece ilanın kendi dokümanını sil — sahibi için kurallarca her zaman izinli.
  // İlişkili favoriler/goruntulenmeler temizliği sunucudaki `ilanSilindi`
  // (onDelete) Cloud Function'ında yapılır; çünkü diğer kullanıcıların favori
  // kayıtlarını client'tan `where ilanId==` ile sorgulamak güvenlik
  // kurallarınca reddedilir ve tüm silme işlemini patlatır.
  await _col.doc(ilanId).delete();
}
```

**Sunucu tarafı (`functions/src/index.ts:538-559`, `ilanSilindi`, `onDocumentDeleted`):**

```ts
export const ilanSilindi = onDocumentDeleted(
  { document: "ilanlar/{ilanId}", database: DATABASE_ID },
  async (event) => {
    const ilanId = event.params.ilanId;
    try {
      await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX, objectID: ilanId });
    } catch (e) { console.warn("Algolia silme hatası:", e); }
    try {
      await getAlgoliaClient().deleteObject({ indexName: ALGOLIA_INDEX_NEREYE, objectID: ilanId });
    } catch (e) { console.warn("Algolia nereye silme hatası:", e); }

    for (const koleksiyon of ["favoriler", "goruntulenmeler"]) {
      try {
        const iliskili = await db.collection(koleksiyon).where("ilanId", "==", ilanId).get();
        if (iliskili.empty) continue;
        const batch = db.batch();
        iliskili.docs.forEach((d) => batch.delete(d.ref));
        await batch.commit();
      } catch (e) { console.warn(`${koleksiyon} temizleme hatası:`, e); }
    }
  }
);
```

### Kontrol listesi

| Kalem | Durum |
|---|---|
| Storage'daki ilan resimleri (`resimUrller`) | **TEMİZLENMİYOR** — `ilanSilindi` içinde hiç Storage çağrısı yok. |
| Algolia ana index (`ALGOLIA_INDEX`) | TEMİZ — `deleteObject` çağrılıyor. |
| Algolia "nereye" index (`ALGOLIA_INDEX_NEREYE`) | TEMİZ — ayrıca siliniyor (bu iki-index deseni daha önce pasife-alma akışında da doğrulanmıştı). |
| `favoriler` koleksiyonu (başkalarının favorileri) | TEMİZ — `where ilanId==` ile toplu siliniyor. |
| `goruntulenmeler` koleksiyonu | TEMİZ — aynı desen. |
| Bu ilana bağlı `sohbetler`/`mesajlar` | **TEMİZLENMİYOR** — sohbet dokümanı `ilanId` alanı taşıyor ama `ilanSilindi` sohbetlere hiç dokunmuyor. Sohbet kalıcı olarak duruyor, içindeki `ilanId` artık var olmayan bir dokümana işaret ediyor. |

### Sonuç — Bölüm A

**ORPHAN RİSKİ VAR** (2 madde):

1. **Storage resimleri** — Her ilan silindiğinde, o ilana ait tüm resimler (orijinal + thumbnail) Storage'da kalıcı olarak birikir. Hiçbir yerde silinmiyor.
   - **Ne kadar birikir:** Uygulama kullanıldıkça, ilan başına ortalama 1-5 resim × silinen her ilan = sürekli büyüyen bir depolama havuzu. Kullanıcılar ilan sildikçe/yeniden oluşturdukça bu doğrusal olarak büyür.
   - **Gerçek maliyet:** Firebase Storage depolama ücreti (GB/ay bazlı) — düşük hacimde önemsiz, ama zamanla (binlerce silinen ilan sonrası) fark edilir bir maliyete dönüşebilir. Ayrıca "silinen veri" GDPR/KVKK açısından da sorunlu olabilir (kullanıcı ilanını sildi ama resmi hâlâ herkese açık bir Storage URL'sinde duruyor).

2. **Sohbetler/mesajlar** — İlan silindiğinde, o ilana bağlı sohbetler dokunulmadan kalıyor; `ilanId` referansı artık var olmayan bir dokümana işaret ediyor.
   - **Ne kadar birikir:** Silinen her ilan için, o ilana dair açılmış tüm sohbetler kalıcı olur.
   - **Gerçek maliyet:** Çoğunlukla **kozmetik kırık referans** — sohbet ekranı muhtemelen `ilanBaslik`/`ilanResimUrl` gibi sohbet dokümanına gömülü (denormalize) alanları kullanıyor olabilir, bu durumda görsel bir sorun çıkmayabilir; ama "İlana Git" gibi bir buton varsa, tıklandığında 404/boş ekrana düşer. Firestore depolama maliyeti düşük (sohbet+mesaj dokümanları küçük), asıl risk kullanıcı deneyiminde kırık link.

---

## BÖLÜM B — Mesaj/Sohbet Silme

**Sohbet "silme" özelliği var, ama gerçek silme DEĞİL:**

`mesajlar_screen.dart:181-209` ve `sohbet_screen.dart:335-369` — "Sohbeti Sil" dialogu, dialog metninde açıkça belirtiliyor: **"Bu sohbet sadece senin için silinecek."**

Gerçek implementasyon (`mesaj_provider.dart:472-477` → `mesaj_repository.dart:283-289`):

```dart
Future<void> sohbetiGizle({
  required String sohbetId,
  required String kullaniciId,
}) =>
    _sohbetler.doc(sohbetId).update({
      'gizli.$kullaniciId': FieldValue.serverTimestamp(),
    });
```

Yani sohbet dokümanı **hiç silinmiyor**, yalnızca `gizli.{kullaniciId}` map alanına bir zaman damgası yazılıyor (per-kullanıcı gizleme bayrağı). Karşı taraf sohbeti hâlâ görüyor.

**Tekil mesaj silme** (`mesaj_repository.dart:249-264`, `mesajSil()`) gerçekten var ve gerçekten siliyor (`_mesajlar(sohbetId).doc(mesajId).delete()`), ardından `sonMesaj` alanını güncelliyor.

### Kontrol listesi

| Kalem | Durum |
|---|---|
| Sohbeti tamamen silme özelliği | **ÖZELLİK YOK** — yalnızca per-kullanıcı gizleme var, gerçek silme değil. |
| Tekil mesaj silme | Var, gerçek silme. |
| Bildirimler → silinen mesaja referans | **TEMİZ** — `bildirim_repository.dart:103-110` incelendiğinde bildirimler `hedefId` olarak `sohbetId` taşıyor, `mesajId` değil. Tek bir mesaj silinse bile bildirim sohbetin kendisine (mesaja değil) işaret ettiği için kırık referans oluşmuyor — sohbet hâlâ var olduğu sürece bildirim geçerli kalır. |

### Sonuç — Bölüm B

**TEMİZ.** Sohbet "silme" zaten gerçek bir silme olmadığı için (per-kullanıcı gizleme), orphan veri riski yok — çöp biriken bir şey yok, tam tersine hiçbir şey silinmiyor. Tekil mesaj silme de dar kapsamlı ve bildirimlerle çakışmıyor.

---

## BÖLÜM C — Hesap Silme (`hesapSilSunucu`)

**Tam kod (`functions/src/index.ts:855-918`):**

```ts
export const hesapSilSunucu = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Giriş yapmalısın.");
  }
  const uid = request.auth.uid;

  try {
    const batch = db.batch();

    await db.recursiveDelete(
      db.collection("kullanicilar").doc(uid).collection("bekleyenDegerlendirmeler")
    );

    batch.delete(db.collection("kullanicilar").doc(uid));

    const ilanlarSnap = await db.collection("ilanlar")
      .where("kullaniciId", "==", uid).get();
    for (const doc of ilanlarSnap.docs) batch.delete(doc.ref);

    const favorilerSnap = await db.collection("favoriler")
      .where("kullaniciId", "==", uid).get();
    for (const doc of favorilerSnap.docs) batch.delete(doc.ref);

    const bildirimlerSnap = await db.collection("bildirimler")
      .where("kullaniciId", "==", uid).get();
    for (const doc of bildirimlerSnap.docs) batch.delete(doc.ref);

    const goruntulenmelerSnap = await db.collection("goruntulenmeler")
      .where("kullaniciId", "==", uid).get();
    for (const doc of goruntulenmelerSnap.docs) batch.delete(doc.ref);

    const takipciSnap = await db.collection("takipler")
      .where("takipciId", "==", uid).get();
    for (const doc of takipciSnap.docs) batch.delete(doc.ref);

    const takipEdilenSnap = await db.collection("takipler")
      .where("takipEdilenId", "==", uid).get();
    for (const doc of takipEdilenSnap.docs) batch.delete(doc.ref);

    await batch.commit();

    const sohbetlerSnap = await db.collection("sohbetler")
      .where("kullanicilar", "array-contains", uid).get();

    for (const sohbet of sohbetlerSnap.docs) {
      const mesajlarSnap = await sohbet.ref.collection("mesajlar").get();
      const mesajBatch = db.batch();
      for (const mesaj of mesajlarSnap.docs) mesajBatch.delete(mesaj.ref);
      mesajBatch.delete(sohbet.ref);
      await mesajBatch.commit();
    }

    await admin.auth().deleteUser(uid);

    return { success: true };
  } catch (e) {
    console.error("hesapSilSunucu hatası:", e);
    throw new HttpsError("internal", "Hesap silinemedi.", String(e));
  }
});
```

### Temizlenenler

- `kullanicilar/{uid}` dokümanı + `bekleyenDegerlendirmeler` alt koleksiyonu (recursive)
- `ilanlar` (kullanıcının kendi ilanları) — **not:** bu doğrudan `batch.delete()` ile siliniyor, ancak Firestore `onDocumentDeleted` tetikleyicileri (`ilanSilindi`) her silme yolunda (batch dahil) tetiklenir, yani bu ilanlar için Algolia/favoriler/goruntulenmeler temizliği **dolaylı olarak zaten oluyor** (Bölüm A'daki aynı orphan riskleri — Storage resimleri ve sohbetler — burada da geçerli).
- `favoriler` (kullanıcının verdiği favoriler)
- `bildirimler` (kullanıcının kendi bildirimleri)
- `goruntulenmeler`
- `takipler` (hem takipçi hem takip edilen tarafı)
- `sohbetler` + alt koleksiyon `mesajlar` (kullanıcının katıldığı tüm sohbetler, tamamen siliniyor — burada gizleme değil gerçek silme)
- Firebase Authentication kaydı (en son adım, yorum satırında bilinçli sıralama gerekçesi var)

### Temizlenmeyenler / bulgular

1. **`değerlendirmeler` koleksiyonu — TEMİZLENMİYOR.**
   `BACKLOG.md:11-22`'de bu madde hâlâ açık duruyor, hiç düzeltilmemiş:
   > "hesapSilSunucu / `degerlendirmeler` koleksiyonu temizlenmiyor... Düzeltme denenmiş ama DURDURULMUŞTU — `degerlendirmePuanGuncelle` yalnızca `onDocumentCreated`, silinme için bir fan-out (karşı tarafın `ortalamaPuan`ını yeniden hesaplayan mekanizma) yok. Önce bu fan-out eklenmeli, ancak ondan sonra değerlendirmeler güvenle silinebilir."

   Doğrulandı: `functions/src/index.ts:680` ve `:754`'te `degerlendirmeler/{degId}` üzerinde yalnızca `onDocumentCreated`/update tetikleyicileri var, silme tetikleyicisi yok.

2. **Storage dosyaları (profil fotoğrafı + ilan resimleri) — TEMİZLENMİYOR.** `hesapSilSunucu` içinde hiçbir Storage çağrısı yok. Kullanıcının profil fotoğrafı (`kullanici_repository.dart:115-117`, `StoragePaths.profilFotolari` altında) ve sildiği ilanlarının resimleri (Bölüm A'daki aynı sorun) kalıcı olarak Storage'da kalıyor.

3. **Favori sayacı (`favoriSayisi`) drift'i — YENİ BULGU.** Normal kullanımda favoriden çıkarma (`ilan_repository.dart:559-575`, `favoridanCikar()`) tek bir transaction içinde hem `favoriler` dokümanını siliyor hem de ilgili ilanın `favoriSayisi` sayacını `FieldValue.increment(-1)` ile düşürüyor — bu akış **TEMİZ**. Ancak `hesapSilSunucu`, silinen kullanıcının `favoriler` dokümanlarını (yani onun BAŞKALARININ ilanlarına verdiği favorileri) doğrudan `batch.delete()` ile siliyor, **karşılık gelen ilanın `favoriSayisi` sayacını hiç düşürmüyor**. Sonuç: hesabını silen her kullanıcının eski favorileri, o ilanların favori sayacında kalıcı olarak "hayalet" bir + olarak kalıyor — sayaç asla gerçek favori sayısını yansıtmıyor, yalnızca yukarı doğru drift ediyor.

4. **`engellenenler` dizisi — TEMİZLENMİYOR.** Silinen kullanıcının uid'si, onu engellemiş olan başka kullanıcıların `kullanicilar/{uid}.engellenenler` dizisinde kalıcı olarak kalıyor (küçük, sınırlı boyutlu bir dizi olduğu için önemsiz, ama not edilmeye değer).

5. **Algolia'da ayrı bir kullanıcı index'i yok** — kullanıcı bilgisi yalnızca `ilanlar` Algolia kaydı içinde `kullaniciId`/`kullaniciAd` alanları olarak denormalize edilmiş durumda. Kullanıcının kendi ilanları zaten `ilanSilindi` ile Algolia'dan temizleniyor (madde altında dolaylı olarak kapsanıyor), bu yüzden ayrı bir orphan risk oluşturmuyor.

### Sonuç — Bölüm C

**ORPHAN RİSKİ VAR** (4 madde, önem sırasına göre):

1. `değerlendirmeler` — hayalet kayıt birikimi (bilinen, BACKLOG'da, kasıtlı olarak ertelenmiş)
2. `favoriSayisi` sayaç drift'i — **YENİ bulgu, BACKLOG'da yok**, launch sonrası sayaçların gerçek değerden sürekli yüksek çıkmasına yol açar
3. Storage dosyaları (profil fotoğrafı + ilan resimleri) — depolama maliyeti
4. `engellenenler` dizisindeki eski uid referansları — önemsiz, kozmetik

---

## BÖLÜM D — Diğer Silme İşlemleri

### D1 — Favori kaldırma / takibi bırakma

**Favori:** `ilan_repository.dart:559-575` — tek bir transaction içinde hem doküman siliniyor hem `favoriSayisi` sayacı `increment(-1)` ile düşürülüyor. **TEMİZ**, tutarsızlık yok.

**Takip:** `kullanici_repository.dart:184-193` — `takipiBirak()` yalnızca `takipler/{id}` dokümanını transaction içinde siliyor, sayaç güncellemesi **client'ta yapılmıyor**; yorum satırında açıkça belirtildiği gibi (`// Sayaç güncellemesi CF trigger'ı (takipSilindiSayacAzalt) tarafından yapılır.`) sayaç, sunucu tarafındaki `onDocumentDeleted` tetikleyicisiyle güncelleniyor. Bu tetikleyici doğrulandı: `functions/src/index.ts:734` (`takipSilindiSayacAzalt`) gerçekten var, ve oluşturma tarafında da `takipOlustuSayacArttir` (:717) var. Firestore tetikleyicileri **her silme yolunda** (client transaction veya `hesapSilSunucu`'nun toplu `batch.delete()`'i fark etmeksizin) çalıştığı için, `hesapSilSunucu`'nun `takipler` koleksiyonunu toplu silmesi de bu sayaçları doğru şekilde günceller.

**Sonuç:** **TEMİZ.** Favori sayacı client-transaction ile, takip sayacı sunucu-tetikleyicisiyle güncelleniyor — ikisi de farklı mekanizma kullanıyor ama ikisi de tutarlı. (Not: favoriSayisi'nin `hesapSilSunucu` özelinde tutarsız olduğu Bölüm C madde 3'te ayrıca not edildi — o, "favoriden çıkma" akışının kendisiyle değil, hesap silmenin favori dokümanlarını dolaylı silmesiyle ilgili ayrı bir durum.)

### D2 — Bildirim silme/okundu işaretleme

`bildirim_repository.dart:93` — `bildirimSil()` tekil bir bildirim dokümanını siliyor, başka hiçbir koleksiyonla bağı yok (bildirimler yalnızca `hedefId` ile bir sohbete/ilana referans veriyor, tersi yönde bir bağ yok). Bildirimin kendisini silmek başka hiçbir yeri etkilemiyor.

Ancak ters yönde bir risk var: **eğer referans verilen sohbet sonradan silinirse** (örn. karşı taraf hesabını silince, `hesapSilSunucu` o sohbeti tamamen siliyor), geride kalan bildirimler (`hedefId: sohbetId`) artık var olmayan bir sohbete işaret eder. `bildirimler` koleksiyonu yalnızca `kullaniciId==uid` (bildirimi alan kişi) bazında temizleniyor — yani A kullanıcısı hesabını silip sohbeti yok ettiğinde, B kullanıcısının o sohbetle ilgili eski bildirimleri B'nin hesabında kalır ve artık geçersiz bir sohbete işaret eder.

**Sonuç — D2:** **ORPHAN RİSKİ VAR** (düşük önem) — karşı tarafın hesap silmesi sonucu sohbeti kaybolan kullanıcıların eski bildirimleri kırık referansa dönüşüyor. Muhtemelen yalnızca kozmetik (tıklanınca boş/hata ekranı), gerçek maliyet yok, yalnızca kullanıcı deneyimi sorunu.

---

## ÖZET TABLO

| Bölüm | Alan | Durum |
|---|---|---|
| A | Storage — ilan resimleri | ORPHAN RİSKİ VAR |
| A | Algolia (2 index) | TEMİZ |
| A | `favoriler` / `goruntulenmeler` (ilan silinince) | TEMİZ |
| A | Sohbetler (ilan silinince) | ORPHAN RİSKİ VAR (kozmetik) |
| B | Sohbet silme | ÖZELLİK YOK (gerçek silme değil, per-kullanıcı gizleme) |
| B | Mesaj silme → bildirimler | TEMİZ |
| C | `değerlendirmeler` (hesap silinince) | ORPHAN RİSKİ VAR (bilinen, BACKLOG'da) |
| C | `favoriSayisi` sayaç drift'i (hesap silinince) | **ORPHAN RİSKİ VAR (YENİ bulgu)** |
| C | Storage (profil + ilan resimleri, hesap silinince) | ORPHAN RİSKİ VAR |
| C | `engellenenler` eski uid referansları | ORPHAN RİSKİ VAR (önemsiz) |
| C | `takipler`, `sohbetler`, `bildirimler`, `ilanlar`, `goruntulenmeler` (hesap silinince) | TEMİZ |
| D1 | Favori kaldırma sayaç tutarlılığı | TEMİZ |
| D1 | Takip bırakma sayaç tutarlılığı | TEMİZ |
| D2 | Bildirim → silinmiş sohbete referans | ORPHAN RİSKİ VAR (düşük, kozmetik) |

---

## Launch öncesi acilen kapatılması gereken bir şey var mı?

**Hayır, hiçbiri launch'ı engelleyecek kritiklikte değil.** Hepsi ya zaten bilinen/ertelenmiş (değerlendirmeler) ya da düşük hacimli/kozmetik risklerdir. Ancak öncelik sırasına göre launch sonrası ilk bakılması gerekenler:

1. **`favoriSayisi` sayaç drift'i (Bölüm C, madde 2)** — bu turun **yeni bulgusu**, BACKLOG.md'de yok. Diğerlerinden farklı olarak bu, kullanıcıya görünen bir sayının (favori sayısı) yanlış olmasına yol açıyor — hesap silme özelliği kullanıldıkça büyür. Düzeltmesi görece basit: `hesapSilSunucu`'da favoriler batch-silinirken, her favori dokümanının `ilanId`'sine karşılık gelen ilanın `favoriSayisi`'ni de `increment(-1)` ile düşürmek (silinen ilanlar için bu adımı atlamak gerekir, çünkü onlar zaten `ilanSilindi` tarafından tamamen kaldırılıyor).
2. **Storage temizliği (ilan silme + hesap silme, Bölüm A/C)** — maliyet birikimi yavaş ama gerçek; bir `onDocumentDeleted` tetikleyicisine `resimUrller`'daki dosyaları silme adımı eklemek yeterli olur.
3. **`değerlendirmeler` koleksiyonu** — zaten bilinen, kasıtlı olarak ertelenmiş (fan-out mekanizması önce gerekiyor), BACKLOG'daki notla tutarlı.
4. **Sohbet/bildirim kırık referansları (Bölüm A/D2)** — en düşük öncelik, yalnızca kozmetik.

BACKLOG.md'ye eklenmesi önerilen tek yeni madde: **favoriSayisi drift'i** — bu rapor dışında hiçbir yerde kayıtlı değildi.
