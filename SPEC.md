# Minimalist Secure Notes App (Flutter) Specification

## 1. Project Base Specs
- Framework: Flutter (Latest Stable)
- Platforms: Android, iOS
- Storage: 100% Local-Only, no cloud sync
- Network: Completely removed INTERNET permission
- Size: Minimalist package (Target < 20MB)
- Language: English only

## 2. Core Encryption Stack
- Key Derivation (KDF): Argon2id
    - Parameters: 64MB Memory, 3 Iterations, 4 Parallelism
    - Purpose: Prevent GPU/specialized hardware brute-force
- Symmetric Encryption: AES-256-GCM
    - Purpose: Encrypt note content and all metadata
    - Features: Quantum-Resistant (AES-256) and data integrity verification
- Database: SQLCipher (sqflite_sqlcipher)
    - Purpose: Full binary encryption of the local database file

## 3. Multi-Password Stealth Logic
- Verification: Trial Decryption (per entry)
- Storage Rules: No password hashes stored, no master password
- Interaction:
    1. User enters password
    2. App attempts to decrypt GCM Tags of all database entries
    3. Only successfully decrypted notes are shown; others remain invisible
    4. Different notes can be encrypted with different passwords, existing independently

## 4. Extreme Privacy & Security Rules
- Anti-Screenshot: Android FLAG_SECURE enabled, iOS screen recording detection/blur
- Clipboard: Automatically clear system clipboard 60 seconds after copying
- Memory Safety: Erase plaintext strings from RAM immediately when app goes to background or page is closed
- System Decoupling: Disable iOS Spotlight and Android Global Search indexing
- Input Security: Disable system keyboard auto-prediction and cloud suggestions
- UI/UX: Modern, minimalist Material 3 design; content-only notes (no titles)

## 5. Recommended Libraries
- Encryption: cryptography
- Database: sqflite_sqlcipher
- UI Protection: flutter_windowmanager
- State Management: flutter_riverpod
