import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/notes/note_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'secure_notes.db');

    // In a real app, this key should be more securely managed.
    // But since we have row-level encryption with Argon2id,
    // this provides the "Full Binary Encryption" layer.
    const dbKey = 'static_internal_key_for_sqlcipher';

    return await openDatabase(
      path,
      password: dbKey,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT,
            nonce TEXT,
            mac TEXT,
            salt TEXT,
            created_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE settings (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  Future<Uint8List> getGlobalSalt() async {
    final db = await database;

    // Ensure settings table exists (for existing users)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    final List<Map<String, dynamic>> maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['global_salt'],
    );

    if (maps.isNotEmpty) {
      return base64Decode(maps.first['value'] as String);
    } else {
      // Generate new global salt
      final salt = Uint8List(16);
      final random = Random.secure();
      for (var i = 0; i < 16; i++) {
        salt[i] = random.nextInt(256);
      }
      final saltBase64 = base64Encode(salt);
      await db.insert('settings', {'key': 'global_salt', 'value': saltBase64});
      return salt;
    }
  }

  Future<int> insertNote(Note note) async {
    final db = await database;
    return await db.insert('notes', note.toMap());
  }

  Future<List<Note>> getAllNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('notes');
    return List.generate(maps.length, (i) => Note.fromMap(maps[i]));
  }

  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
