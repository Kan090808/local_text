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

## 3. Multi-Password Stealth Logic
- Verification: Trial Decryption (per entry)
- Storage Rules: No password hashes stored, no master password
- Interaction:
    1. User enters password
    2. App attempts to decrypt GCM Tags of all database entries
    3. Only successfully decrypted texts are shown; others remain invisible
    4. Different texts can be encrypted with different passwords, existing independently

## 4. Extreme Privacy & Security Rules
- Anti-Screenshot: Android FLAG_SECURE enabled, iOS screen recording detection/blur
- Clipboard: Automatically clear system clipboard 60 seconds after copying
- Memory Safety: 
    - **Zero-Password Policy**: Raw password strings are wiped from RAM immediately after Master Key derivation.
    - **Master Key Management**: Only the derived binary Master Key (Uint8List) is held in memory during the unlocked session and is cleared upon locking or backgrounding.
- System Decoupling: Disable iOS Spotlight and Android Global Search indexing
- Input Security: Disable system keyboard auto-prediction and cloud suggestions
- UI/UX: Modern, minimalist Material 3 design; content-only texts (no titles); support for text deletion and debounced save actions.

## 5. Recommended Libraries
- Encryption: cryptography
- Database: sqflite_sqlcipher
- UI Protection: flutter_windowmanager
- State Management: flutter_riverpod
