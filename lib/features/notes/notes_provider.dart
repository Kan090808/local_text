import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notes_repository.dart';
import 'note_model.dart';

final notesRepositoryProvider = Provider((ref) => NotesRepository());

class PasswordNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setPassword(String password) => state = password;
}

final passwordProvider = NotifierProvider<PasswordNotifier, String>(
  PasswordNotifier.new,
);

final decryptedNotesProvider = FutureProvider<List<DecryptedNote>>((ref) async {
  final password = ref.watch(passwordProvider);
  if (password.isEmpty) return [];

  final repository = ref.read(notesRepositoryProvider);
  return await repository.getDecryptedNotes(password);
});
