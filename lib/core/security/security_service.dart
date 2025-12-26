import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final _aesGcm = AesGcm.with256bits();

  // Argon2id with specified parameters
  // memory: 64MB = 64 * 1024 KB
  // iterations: 3
  // parallelism: 4
  final _argon2id = Argon2id(
    parallelism: 4,
    memory: 64 * 1024,
    iterations: 3,
    hashLength: 32,
  );

  /// Derives a 256-bit key from a password using Argon2id.
  Future<Uint8List> deriveKey(String password, List<int> salt) async {
    final secretKey = await _argon2id.deriveKeyFromPassword(
      password: password,
      nonce: salt,
    );
    final bytes = await secretKey.extractBytes();
    return Uint8List.fromList(bytes);
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
