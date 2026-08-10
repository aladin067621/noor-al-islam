import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

import '../models/note.dart';

/// خدمة الملاحظات — تخزين محلي في sqflite
class NotesService {
  NotesService._();
  static final NotesService instance = NotesService._();

  Database? _db;

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, 'notes.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            created_at INTEGER,
            updated_at INTEGER,
            linked_ref TEXT,
            linked_label TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  Future<List<Note>> getAll() async {
    final db = await _database;
    final rows = await db.query('notes', orderBy: 'updated_at DESC');
    return rows.map((e) => Note.fromMap(e)).toList();
  }

  Future<int> insert(Note note) async {
    final db = await _database;
    return db.insert('notes', note.toMap());
  }

  Future<void> update(Note note) async {
    final db = await _database;
    await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<void> delete(int id) async {
    final db = await _database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
