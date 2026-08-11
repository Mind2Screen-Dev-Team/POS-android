# CLAUDE.md — POS Android

Aplikasi POS Penglaris. Flutter 3.44.9 (Dart 3.12.2), cross-platform android/ios/web.

## Struktur

```
lib/main.dart                # entrypoint
lib/app.dart                 # root widget (MaterialApp)
lib/core/network/            # koneksi backend
  app_config.dart            #   base URL via --dart-define (default localhost:8080)
  api_client.dart            #   wrapper http (get/post) + ApiException
lib/features/home/           # halaman home POS
test/widget_test.dart        # widget test
```

## Perintah

```sh
flutter pub get
flutter analyze
flutter test
flutter run          # pilih device (web/Chrome OK — toolchain native belum ada)
```

Flutter SDK di `$HOME/flutter/bin` (export PATH bila perlu).

## Integrasi backend

- Base URL backend di-inject saat run: `flutter run --dart-define=API_BASE_URL=http://localhost:8080`.
- Default `localhost:8080` sesuai backend POS (Go).

## Konvensi branch

- Mulai dari `develop`, target merge `develop`. `main` = merge manusia saja. `git pull` dulu sebelum mulai kerja.
