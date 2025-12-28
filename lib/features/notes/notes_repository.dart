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

  Future<Uint8List> getGlobalSalt() async {
    return await _dbService.getGlobalSalt();
  }

  Future<Uint8List> deriveMasterKey(
    String password,
    Uint8List globalSalt,
  ) async {
    return await _securityService.deriveMasterKey(password, globalSalt);
  }

  Future<void> addNote(String content, Uint8List masterKey) async {
    // Generate a random salt for this specific note
    final salt = Uint8List(16);
    final random = Random.secure();
    for (var i = 0; i < 16; i++) {
      salt[i] = random.nextInt(256);
    }

    // Derive per-note key using HKDF (very fast)
    final noteKey = await _securityService.deriveNoteKey(masterKey, salt);

    final secretBox = await _securityService.encrypt(
      utf8.encode(content),
      noteKey,
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

  Future<List<DecryptedNote>> getDecryptedNotes(Uint8List masterKey) async {
    final allNotes = await _dbService.getAllNotes();
    final List<DecryptedNote> decryptedNotes = [];

    for (final note in allNotes) {
      // Derive per-note key using HKDF (very fast)
      final noteKey = await _securityService.deriveNoteKey(
        masterKey,
        note.salt,
      );

      final secretBox = SecretBox(
        note.encryptedContent,
        nonce: note.nonce,
        mac: Mac(note.mac),
      );

      final decryptedData = await _securityService.decrypt(secretBox, noteKey);

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

  Future<void> deleteNote(int id) async {
    await _dbService.deleteNote(id);
  }
}
