import 'dart:convert';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _aesGcm = AesGcm.with256bits();

  // Argon2id for Master Key derivation
  final _argon2id = Argon2id(
    parallelism: 4,
    memory: 64 * 1024,
    iterations: 3,
    hashLength: 32,
  );

  // HKDF for per-note key derivation
  final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Derives a Master Key from a password using Argon2id.
  Future<Uint8List> deriveMasterKey(String password, List<int> salt) async {
    final secretKey = await _argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
  }

  /// Derives a per-note key from the Master Key using HKDF.
  Future<SecretKey> deriveNoteKey(
    Uint8List masterKey,
    List<int> noteSalt,
  ) async {
    final masterSecretKey = SecretKey(masterKey);
    return await _hkdf.deriveKey(
      secretKey: masterSecretKey,
      nonce: noteSalt,
      info: utf8.encode('note_encryption'),
    );
  }

  /// Encrypts data using AES-256-GCM.
  Future<SecretBox> encrypt(List<int> data, SecretKey secretKey) async {
    return await _aesGcm.encrypt(data, secretKey: secretKey);
  }

  /// Decrypts data using AES-256-GCM.
  /// Returns null if decryption fails (Trial Decryption logic).
  Future<List<int>?> decrypt(SecretBox secretBox, SecretKey secretKey) async {
    try {
      return await _aesGcm.decrypt(secretBox, secretKey: secretKey);
    } catch (e) {
      // Decryption failed, likely wrong password
      return null;
    }
  }
}
