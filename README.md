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
  - **SQLCipher** for full binary encryption of the local database using a unique key stored in the device's **Hardware Secure Enclave**.
- **Multi-Password Stealth**: Different notes can be encrypted with different passwords. Only the notes matching the entered password are visible; others remain hidden.
- **Privacy First**:
  - **Anti-Screenshot & Privacy Blur**: Protection against screenshots on Android and automatic Gaussian blur on iOS when switching apps.
  - **Secure Clipboard**: Automatically clears the clipboard after 60 seconds or **immediately** upon leaving the app.
  - **Zero-Password Memory Footprint**: Raw passwords are never stored; only transient Master Keys exist in RAM during active sessions and are wiped upon locking.
  - **Anti-Brute Force**: Mandatory computational delays to prevent automated password guessing.
  - **Input Security**: Disables system keyboard auto-prediction and cloud suggestions by using privacy-focused keyboard modes.
  - **Memory Hygiene**: All sensitive input controllers are disposed of immediately to prevent data leakage in RAM.
- **Minimalist Design**: Modern Material 3 UI focused entirely on your content.

## Getting Started

1. Clone the repository.
2. Run `flutter pub get`.
3. Run `flutter run`.
