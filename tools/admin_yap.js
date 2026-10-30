// tools/admin_yap.js
//
// Bootstrap script: adminYetkisiVer Cloud Function'ı henüz deploy edilmeden
// önce (ya da callable'a erişimin olmadığı bir durumda) verilen e-postaya
// admin custom claim'i ({ admin: true }) atar. adminYetkisiVer deploy
// edildikten sonra normal şartlarda o callable kullanılmalı — bu script
// yalnızca ilk admin hesabını (superadmin e-postası) bootstrap etmek için var.
//
// Kullanım (repo kökünden):
//   node tools/admin_yap.js kullanici@example.com
//
// Ön koşul: GOOGLE_APPLICATION_CREDENTIALS ortam değişkeni bir service
// account JSON dosyasına işaret etmeli.

const path = require('path');
const { createRequire } = require('module');
const requireFromFunctions = createRequire(
  path.join(__dirname, '..', 'functions', 'package.json'),
);
const admin = requireFromFunctions('firebase-admin');

async function main() {
  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error(
      'HATA: GOOGLE_APPLICATION_CREDENTIALS ortam değişkeni tanımlı değil.\n' +
      'Bir service account JSON dosyasının yolunu bu değişkene ata ve tekrar dene.',
    );
    process.exit(1);
  }

  const email = process.argv[2];
  if (!email) {
    console.error('Kullanım: node tools/admin_yap.js kullanici@example.com');
    process.exit(1);
  }

  admin.initializeApp({ credential: admin.credential.applicationDefault() });

  const kullanici = await admin.auth().getUserByEmail(email);
  await admin.auth().setCustomUserClaims(kullanici.uid, { admin: true });

  console.log(`${email} (uid=${kullanici.uid}) admin olarak işaretlendi.`);
  console.log('Not: mevcut oturumlar yeni claim\'i görmek için token\'ı yenilemeli (forceRefresh:true).');
}

main().catch((e) => {
  console.error('Script hata verdi:', e);
  process.exit(1);
});
