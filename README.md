# POS Android (Flutter)

POS Penglaris — aplikasi POS untuk Android, iOS, dan web. Dibangun dengan Flutter.

## Requirements

- Flutter 3.44.9 stable / Dart 3.12.2 (di `$HOME/flutter/bin`)
- Platform SDK dibutuhkan untuk build native:
  - Android: Android SDK (belum tersedia lokal)
  - iOS: Xcode (belum tersedia lokal)

> Status environment saat ini: toolchain Android dan iOS tidak tersedia,
> jadi build APK/IPA lokal tidak bisa dijalankan. Source multi-platform
> lengkap; verifikasi cukup lewat `flutter analyze` dan `flutter test`.

## Run

```sh
flutter pub get
flutter run        # pilih device yang tersedia (mis. Chrome/web)
flutter test
flutter analyze
```

## Integrasi Backend

Base URL backend dikonfigurasi via `lib/core/network/app_config.dart`,
di-override saat run/build:

```sh
flutter run --dart-define=API_BASE_URL=https://api.penglaris.example.com
```

API client minimal ada di `lib/core/network/api_client.dart`
(package `http`). Endpoint bisnis ditambahkan task berikutnya.

## Struktur

```text
lib/
  main.dart                 # entrypoint
  app.dart                  # root widget (MaterialApp)
  core/network/             # konfigurasi & API client
  features/home/            # home screen awal
android/ ios/ web/          # target platform
test/                       # widget test
```

## Branches

- `main` — production, merge manual manusia
- `develop` — integrasi fitur
- `staging` — pra-produksi