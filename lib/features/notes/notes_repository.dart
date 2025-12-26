import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../../core/database/database_service.dart';
import '../../core/security/security_service.dart';
import 'note_model.dart';

class NotesRepository {
  final DatabaseService _dbService = DatabaseService();
  final SecurityService _securityService = SecurityService();

  Future<void> addNote(String content, String password) async {
    // Generate a random salt
    final salt = Uint8List(16);
    final random = Random.secure();
    for (var i = 0; i < 16; i++) {
      salt[i] = random.nextInt(256);
    }

    // Derive key
    final keyBytes = await _securityService.deriveKey(password, salt);
    final secretKey = SecretKey(keyBytes);

    final secretBox = await _securityService.encrypt(
      utf8.encode(content),
      secretKey,
    );

    final note = Note(
      encryptedContent: secretBox.cipherText,
      nonce: secretBox.nonce,
      mac: secretBox.mac.bytes,
      salt: salt,
      createdAt: DateTime.now(),
    );

    await _dbService.insertNote(note);
  }

  Future<List<DecryptedNote>> getDecryptedNotes(String password) async {
    final allNotes = await _dbService.getAllNotes();
    final List<DecryptedNote> decryptedNotes = [];

    for (final note in allNotes) {
      // Derive key for this note using its salt
      final keyBytes = await _securityService.deriveKey(password, note.salt);
      final secretKey = SecretKey(keyBytes);

      final secretBox = SecretBox(
        note.encryptedContent,
        nonce: note.nonce,
        mac: Mac(note.mac),
      );

      final decryptedData = await _securityService.decrypt(
        secretBox,
        secretKey,
      );

      if (decryptedData != null) {
        try {
          final content = utf8.decode(decryptedData);
          decryptedNotes.add(
            DecryptedNote(
              id: note.id!,
              content: content,
              createdAt: note.createdAt,
            ),
          );
        } catch (e) {
          // Decryption succeeded but decode failed?
        }
      }
    }

    return decryptedNotes;
  }
}
