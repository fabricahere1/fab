# migrasyon_degistir.ps1
# ─────────────────────────────────────────────────────────────────────────
# FirebaseFirestore.instance -> AppFirestore.instance geçişini 12 dosyada
# otomatik yapar. Her dosyada:
#   1) Gerekli import satırını (yoksa) en üstteki import bloğunun sonuna ekler
#   2) "FirebaseFirestore.instance" metnini "AppFirestore.instance" ile değiştirir
#
# ÖNEMLİ: Bu script'i projenin KÖK klasöründen (C:\src\iste_v3) çalıştır.
# Her dosyanın YEDEĞİ .bak uzantısıyla aynı klasöre alınır — bir şey
# ters giderse dosyayı .bak'tan geri kopyalayabilirsin.
# ─────────────────────────────────────────────────────────────────────────

$degisimler = @(
    @{ Dosya = "lib\main.dart";                                            Import = "import 'core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\core\services\badge_service.dart";                     Import = "import '../firebase/app_firestore.dart';" },
    @{ Dosya = "lib\core\services\bildirim_banner_service.dart";           Import = "import '../firebase/app_firestore.dart';" },
    @{ Dosya = "lib\core\services\fcm_service.dart";                       Import = "import '../firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\auth\data\auth_repository.dart";              Import = "import '../../../core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\bildirimler\data\bildirim_repository.dart";   Import = "import '../../../core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\degerlendirme\data\degerlendirme_repository.dart"; Import = "import '../../../core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\ilanlar\data\ilan_repository.dart";           Import = "import '../../../core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\mesajlar\data\mesaj_repository.dart";         Import = "import '../../../core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\profil\data\kullanici_repository.dart";       Import = "import '../../../core/firebase/app_firestore.dart';" },
    @{ Dosya = "lib\features\profil\presentation\ayarlar_screen.dart";     Import = "import '../../../core/firebase/app_firestore.dart';" }
)

$toplamDegisenSatir = 0
$hataliDosyalar = @()

foreach ($item in $degisimler) {
    $yol = $item.Dosya
    $importSatiri = $item.Import

    if (-not (Test-Path $yol)) {
        Write-Host "ATLANDI (bulunamadı): $yol" -ForegroundColor Yellow
        $hataliDosyalar += $yol
        continue
    }

    # Yedek al
    Copy-Item $yol "$yol.bak" -Force

    $icerik = Get-Content $yol -Raw

    $degisenVarMi = $false

    # 1) Import ekle (zaten yoksa)
    if ($icerik -notmatch [regex]::Escape($importSatiri)) {
        # İlk "import '...';" satırının hemen ALTINA ekle
        $icerik = $icerik -replace "(import\s+'[^']+';\r?\n)", "`$1$importSatiri`r`n", 1
        $degisenVarMi = $true
    }

    # 2) FirebaseFirestore.instance -> AppFirestore.instance
    $eskiSayi = ([regex]::Matches($icerik, [regex]::Escape("FirebaseFirestore.instance"))).Count
    if ($eskiSayi -gt 0) {
        $icerik = $icerik -replace [regex]::Escape("FirebaseFirestore.instance"), "AppFirestore.instance"
        $toplamDegisenSatir += $eskiSayi
        $degisenVarMi = $true
    }

    if ($degisenVarMi) {
        Set-Content $yol $icerik -NoNewline
        Write-Host "GUNCELLENDI: $yol ($eskiSayi değişim)" -ForegroundColor Green
    } else {
        Write-Host "DEGISIKLIK YOK: $yol (zaten güncel veya desen bulunamadı)" -ForegroundColor Cyan
        Remove-Item "$yol.bak" -Force  # gereksiz yedek, temizle
    }
}

Write-Host ""
Write-Host "===================================================="
Write-Host "Toplam değiştirilen 'FirebaseFirestore.instance' sayısı: $toplamDegisenSatir"
if ($hataliDosyalar.Count -gt 0) {
    Write-Host "Bulunamayan dosyalar:" -ForegroundColor Yellow
    $hataliDosyalar | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}
Write-Host "Her değişen dosyanın yanında .bak uzantılı bir yedek var."
Write-Host "Sorun çıkarsa: Copy-Item 'dosya.dart.bak' 'dosya.dart' -Force"
Write-Host "===================================================="
