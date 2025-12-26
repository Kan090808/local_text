import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:io';
import 'dart:async';
import 'features/notes/notes_provider.dart';
import 'features/notes/note_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Security: Anti-screenshot for Android
  if (Platform.isAndroid) {
    try {
      await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    } catch (e) {
      debugPrint('Failed to set FLAG_SECURE: $e');
    }
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secure Notes',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const NotesPage(),
    );
  }
}

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key});

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage>
    with WidgetsBindingObserver {
  final TextEditingController _passwordController = TextEditingController();
  bool _isUnlocked = false;
  Timer? _clipboardTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _passwordController.clear();
    _passwordController.dispose();
    _clipboardTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Security: Lock app when it goes to background
      _lock();
    }
  }

  void _unlock() {
    if (_passwordController.text.isNotEmpty) {
      ref.read(passwordProvider.notifier).setPassword(_passwordController.text);
      setState(() {
        _isUnlocked = true;
      });
    }
  }

  void _lock() {
    ref.read(passwordProvider.notifier).setPassword('');
    _passwordController.clear();
    setState(() {
      _isUnlocked = false;
    });
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard. Will be cleared in 60s.'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(seconds: 60), () {
      Clipboard.setData(const ClipboardData(text: ''));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Clipboard cleared for security.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Secure Notes',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isUnlocked)
            IconButton(
              icon: const Icon(Icons.lock_outline),
              onPressed: _lock,
              tooltip: 'Lock App',
            ),
        ],
      ),
      body: _isUnlocked
          ? DecryptedNotesList(onCopy: _copyToClipboard)
          : _buildUnlockScreen(),
      floatingActionButton: _isUnlocked
          ? FloatingActionButton.extended(
              onPressed: () => _showAddNoteDialog(context),
              label: const Text('New Note'),
              icon: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildUnlockScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_person_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Private Vault',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your password to access your notes',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter decryption key',
                prefixIcon: const Icon(Icons.key_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
              ),
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.visiblePassword,
              onSubmitted: (_) => _unlock(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _unlock,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.login_rounded),
              label: const Text('Unlock Vault', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Different passwords reveal different notes.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    final contentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'New Secure Note',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: contentController,
              decoration: InputDecoration(
                hintText: 'Write your secret here...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
              maxLines: 8,
              autofocus: true,
              enableSuggestions: false,
              autocorrect: false,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                if (contentController.text.isNotEmpty) {
                  final repo = ref.read(notesRepositoryProvider);
                  await repo.addNote(
                    contentController.text,
                    ref.read(passwordProvider),
                  );
                  ref.invalidate(decryptedNotesProvider);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Encrypt & Save'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class DecryptedNotesList extends ConsumerWidget {
  final Function(String) onCopy;
  const DecryptedNotesList({super.key, required this.onCopy});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(decryptedNotesProvider);

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.note_alt_outlined,
                  size: 64,
                  color: Colors.grey.withAlpha(128),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No notes found for this password',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: notes.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                title: Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Created on ${note.createdAt.year}-${note.createdAt.month}-${note.createdAt.day}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ),
                onTap: () => _showNoteDetail(context, note),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showNoteDetail(BuildContext context, DecryptedNote note) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Note Detail',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy_rounded),
                      onPressed: () {
                        onCopy(note.content);
                        Navigator.pop(context);
                      },
                      tooltip: 'Copy Content',
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: SelectableText(
                note.content,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
