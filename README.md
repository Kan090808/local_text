# Local Text

A minimalist, ultra-secure, local-only note-taking app built with Flutter.

## Highlights

- **100% Local-Only**: No cloud sync, no servers. Your data never leaves your device.
- **Zero Network Access**: The app has no INTERNET permission, ensuring complete isolation.
- **Military-Grade Encryption**: 
  - **AES-256-GCM** for text content and metadata.
  - **Two-Tier Key Derivation**: 
    - **Argon2id** for session-based Master Key derivation (Brute-force resistant) with a device-specific global salt.
    - **HKDF** for lightning-fast per-note decryption, enabling smooth scrolling even with thousands of entries.
  - **SQLCipher** for full binary encryption of the local database.
- **Multi-Password Stealth**: Different notes can be encrypted with different passwords. Only the notes matching the entered password are visible; others remain hidden.
- **Privacy First**:
  - **Anti-Screenshot**: Protection against screenshots and screen recordings.
  - **Secure Clipboard**: Automatically clears the clipboard after 60 seconds.
  - **Zero-Password Memory Footprint**: Raw passwords are never stored; only transient Master Keys exist in RAM during active sessions and are wiped upon locking.
  - **Input Security**: Disables system keyboard auto-prediction and cloud suggestions.
- **Minimalist Design**: Modern Material 3 UI focused entirely on your content.

## Getting Started

1. Clone the repository.
2. Run `flutter pub get`.
3. Run `flutter run`.
