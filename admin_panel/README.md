# İSTE Admin Panel

`iste_v3`'ün `lib/` kodunu (path dependency ile) reuse eden, yalnızca web platformu için Flutter uygulaması.

## Kurulum (bir kereye mahsus)

1. **Firebase web app'i kaydet + firebase_options.dart'a web config'i ekle:**
   ```
   dart pub global activate flutterfire_cli
   cd ..   # repo kökü (iste_v3)
   flutterfire configure --project=bring-in-3a17c
   ```
   Bu, `lib/firebase_options.dart` içine `web` platformu için bir `FirebaseOptions` bloğu ekler (mevcut android config'e dokunmaz).

2. **İlk admin hesabını işaretle** (superadmin e-postası veya başka bir hesap):
   ```
   cd functions && npm run build && cd ..
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node tools/admin_yap.js kullanici@example.com
   ```
   Sonraki adminler için `adminYetkisiVer` callable fonksiyonu deploy edildikten sonra onu kullanmak yeterli (bkz. `functions/src/index.ts`).

3. **Mevcut ilanlara ilanNo ata:**
   ```
   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json node tools/ilan_no_migrasyon.js --uygula
   ```

4. **Hosting site'ı oluştur ve target'ı bağla** (deploy için, opsiyonel):
   ```
   firebase hosting:sites:create iste-admin
   firebase target:apply hosting admin iste-admin
   ```

## Geliştirme

```
cd admin_panel
flutter run -d chrome
```

## Deploy

```
firebase deploy --only functions,firestore:rules
cd admin_panel && flutter build web && cd ..
firebase deploy --only hosting:admin
```
