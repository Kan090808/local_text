import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';
import 'dart:io';
import 'dart:async';
import 'dart:ui';
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
      title: 'Local Text',
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
  bool _isUnlocking = false;
  bool _shouldBlur = false;
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
    _clearClipboard(); // Ensure clipboard is cleared on dispose
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Security: Lock app when it goes to background
      _lock();
      // Security: Clear clipboard immediately on exit
      _clearClipboard();
      setState(() {
        _shouldBlur = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      setState(() {
        _shouldBlur = false;
      });
    }
  }

  void _clearClipboard() {
    Clipboard.setData(const ClipboardData(text: ''));
    _clipboardTimer?.cancel();
  }

  void _unlock() async {
    if (_passwordController.text.isNotEmpty && !_isUnlocking) {
      final password = _passwordController.text;
      _passwordController
          .clear(); // Clear immediately to reduce memory exposure

      setState(() {
        _isUnlocking = true;
      });

      try {
        // Anti-Brute Force: Mandatory delay to slow down automated attacks
        // Also provides a better UX by showing the loading state clearly
        final startTime = DateTime.now();

        final repo = ref.read(notesRepositoryProvider);
        final salt = await repo.getGlobalSalt();
        final masterKey = await repo.deriveMasterKey(password, salt);

        // Ensure the "unlocking" animation lasts at least 800ms
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        if (elapsed < 800) {
          await Future.delayed(Duration(milliseconds: 800 - elapsed));
        }

        ref.read(masterKeyProvider.notifier).setMasterKey(masterKey);

        if (mounted) {
          setState(() {
            _isUnlocked = true;
            _isUnlocking = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUnlocking = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Unlock failed: $e')));
        }
      }
    }
  }

  void _lock() {
    ref.read(masterKeyProvider.notifier).clear();
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
      _clearClipboard();
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
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              'Local Text',
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
              ? DecryptedTextsList(onCopy: _copyToClipboard)
              : _buildUnlockScreen(),
          floatingActionButton: _isUnlocked
              ? FloatingActionButton.extended(
                  onPressed: () => _showAddTextDialog(context),
                  label: const Text('New Text'),
                  icon: const Icon(Icons.add),
                )
              : null,
        ),
        // iOS Screen Protection: Show a blur/overlay when app is inactive
        if (_shouldBlur)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                color: Colors.black.withAlpha(150),
                child: const Center(
                  child: Icon(
                    Icons.lock_rounded,
                    size: 80,
                    color: Colors.white54,
                  ),
                ),
              ),
            ),
          ),
      ],
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
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Your text is yours',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your password to access your texts',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
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
              onPressed: _isUnlocking ? null : _unlock,
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isUnlocking
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded),
              label: Text(
                _isUnlocking ? 'Unlocking...' : 'Unlock',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTextDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddNoteSheet(
        onSave: (content) async {
          final repo = ref.read(notesRepositoryProvider);
          final masterKey = ref.read(masterKeyProvider);
          if (masterKey != null) {
            await repo.addNote(content, masterKey);
            ref.invalidate(decryptedNotesProvider);
          } else {
            throw Exception('Master key not available');
          }
        },
      ),
    );
  }
}

class _AddNoteSheet extends StatefulWidget {
  final Future<void> Function(String) onSave;
  const _AddNoteSheet({required this.onSave});

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  final _contentController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'New Text',
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
            controller: _contentController,
            decoration: InputDecoration(
              hintText: 'Write your secret here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            maxLines: 8,
            autofocus: true,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.visiblePassword, // Disable suggestions
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (_contentController.text.isNotEmpty) {
                      setState(() {
                        _isSaving = true;
                      });
                      try {
                        await widget.onSave(_contentController.text);
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        setState(() {
                          _isSaving = false;
                        });
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving: $e')),
                          );
                        }
                      }
                    }
                  },
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Encrypt & Save'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class DecryptedTextsList extends ConsumerWidget {
  final Function(String) onCopy;
  const DecryptedTextsList({super.key, required this.onCopy});

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
                  Icons.text_fields_rounded,
                  size: 64,
                  color: Colors.grey.withAlpha(128),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No texts found for this password',
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
                trailing: IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () => onCopy(note.content),
                  tooltip: 'Copy to clipboard',
                ),
                onTap: () => _showTextDetail(context, ref, note),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DecryptedNote note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Text'),
        content: const Text('Are you sure you want to delete?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final repo = ref.read(notesRepositoryProvider);
              await repo.deleteNote(note.id);
              ref.invalidate(decryptedNotesProvider);
              if (context.mounted) {
                Navigator.pop(context); // Close dialog
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTextDetail(
    BuildContext context,
    WidgetRef ref,
    DecryptedNote note,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24.0),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Detail',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            onCopy(note.content);
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.copy),
                          tooltip: 'Copy to clipboard',
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _confirmDelete(context, ref, note);
                          },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Delete text',
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
                Flexible(
                  child: SingleChildScrollView(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: SelectableText(
                        note.content,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Created on ${note.createdAt.toString()}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
