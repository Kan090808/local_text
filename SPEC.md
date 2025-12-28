# Local Text (Flutter) Specification

## 1. Project Base Specs
- Name: Local Text
- Framework: Flutter (Latest Stable)
- Platforms: Android, iOS
- Storage: 100% Local-Only, no cloud sync
- Network: Completely removed INTERNET permission
- Size: Minimalist package (Target < 20MB)
- Language: English only

## 2. Core Encryption Stack
- Key Derivation (KDF): 
    - **Master Key**: Argon2id (64MB Memory, 3 Iterations, 4 Parallelism) with a **Device-Specific Global Salt**.
    - **Per-Entry Key**: **HKDF (HMAC-SHA256)** derived from Master Key and unique entry salt.
    - Purpose: Balance extreme brute-force resistance with high-performance UI rendering.
- Symmetric Encryption: AES-256-GCM
    - Purpose: Encrypt text content and all metadata
    - Features: Quantum-Resistant (AES-256) and data integrity verification
- Database: SQLCipher (sqflite_sqlcipher)
    - Purpose: Full binary encryption of the local database file
    - **Key Management**: Unique 256-bit key generated per device and stored in **Hardware-backed Secure Storage** (iOS Keychain / Android Keystore) via `flutter_secure_storage`.

## 3. Multi-Password Stealth Logic
- Verification: Trial Decryption (per entry)
- Storage Rules: No password hashes stored, no master password
- Interaction:
    1. User enters password
    2. **Anti-Brute Force**: Mandatory 0.8s computational delay to throttle automated attacks.
    3. App attempts to decrypt GCM Tags of all database entries
    4. Only successfully decrypted texts are shown; others remain invisible
    5. Different texts can be encrypted with different passwords, existing independently

## 4. Extreme Privacy & Security Rules
- Anti-Screenshot: 
    - **Android**: `FLAG_SECURE` enabled to block screenshots and screen recording.
    - **iOS**: Real-time **Gaussian Blur** overlay (sigma 20) applied when app is inactive or in app-switcher.
- Clipboard: 
    - Automatically clear system clipboard after 60 seconds.
    - **Immediate Clear**: Clipboard is wiped instantly when the app is backgrounded or closed.
- Memory Safety: 
    - **Zero-Password Policy**: Raw password strings are wiped from RAM immediately after Master Key derivation.
    - **Instant Controller Clearing**: Password and content controllers are cleared and disposed of immediately after use to prevent data lingering in memory.
    - **Master Key Management**: Only the derived binary Master Key (Uint8List) is held in memory during the unlocked session and is cleared upon locking or backgrounding.
- System Decoupling: Disable iOS Spotlight and Android Global Search indexing
- Input Security: 
    - Disable system keyboard auto-prediction and cloud suggestions.
    - **Privacy Keyboard Mode**: Uses `visiblePassword` input type for all sensitive fields to prevent system-level learning of private text.
- UI/UX: Modern, minimalist Material 3 design; content-only texts (no titles); support for text deletion and debounced save actions.

## 5. Recommended Libraries
- Encryption: cryptography
- Database: sqflite_sqlcipher
- Secure Storage: flutter_secure_storage
- UI Protection: flutter_windowmanager
- State Management: flutter_riverpod
