# Password Manager

Gestore di credenziali offline-first per Android, costruito in Flutter, completamente compatibile con il formato KeePass (KDBX 3.x e 4.x).

## Caratteristiche principali

- 🔐 **Compatibilità KeePass** — Lettura/scrittura nativa di file `.kdbx` (3.x e 4.x).
- 🔑 **Crittografia robusta** — AES-256 + Argon2 KDF.
- 👆 **Sblocco biometrico** — Impronta o Face Unlock via Android Keystore.
- 🛡️ **Auto-Lock** — Blocco automatico configurabile su inattività / background.
- 📋 **Pulizia clipboard** — Cancellazione automatica delle password copiate dopo 30s.
- 🔢 **TOTP** — Generazione 2FA (SHA-1/256/512) con countdown animato.
- 🎲 **Generatore password** — Caratteri o passphrase (IT/EN).
- 📲 **Android Autofill** — Integrazione con il framework di sistema.
- 📥 **Import/Export** — CSV e PDF.
- 🌐 **i18n** — Italiano e Inglese.
- 🎨 **Material 3** — Dark/Light mode automatici.

## Stack

- Flutter (SDK ≥ 3.11) + Dart
- `flutter_riverpod` + `riverpod_annotation`
- `go_router`
- `kdbx` (≥ 2.4.2) + `argon2_ffi_base`
- `pointycastle`, `crypto`
- `local_auth`
- `flutter_localizations` + `intl`

## Setup

```bash
flutter create .                  # genera le cartelle native (android/, ios/, ...)
flutter pub get
dart run build_runner build       # genera *.g.dart per Riverpod
flutter gen-l10n                  # genera AppLocalizations
flutter run
```

## Struttura

Vedere `lib/` — organizzata feature-first.

## Sicurezza

Vedere commenti inline nei file `lib/core/auth/`, `lib/core/kdbx/`, `lib/core/crypto/`.
