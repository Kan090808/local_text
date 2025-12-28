import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notes_repository.dart';
import 'note_model.dart';

final notesRepositoryProvider = Provider((ref) => NotesRepository());

class MasterKeyNotifier extends Notifier<Uint8List?> {
  @override
  Uint8List? build() => null;

  void setMasterKey(Uint8List? key) => state = key;
  void clear() => state = null;
}

final masterKeyProvider = NotifierProvider<MasterKeyNotifier, Uint8List?>(
  MasterKeyNotifier.new,
);

final decryptedNotesProvider = FutureProvider<List<DecryptedNote>>((ref) async {
  final masterKey = ref.watch(masterKeyProvider);
  if (masterKey == null) return [];

  final repository = ref.read(notesRepositoryProvider);
  return await repository.getDecryptedNotes(masterKey);
});
