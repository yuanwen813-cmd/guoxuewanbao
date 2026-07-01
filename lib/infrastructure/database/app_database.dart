import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 应用数据库
class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Database get db {
    if (_db == null) throw StateError('Database not initialized');
    return _db!;
  }

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'guoxueapp.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // 历史记录表
    await db.execute('''
      CREATE TABLE history_records (
        id TEXT PRIMARY KEY,
        method_id TEXT NOT NULL,
        method_name TEXT NOT NULL,
        question TEXT,
        input_json TEXT,
        result_json TEXT,
        interpretation_json TEXT,
        created_at INTEGER NOT NULL,
        favorite INTEGER DEFAULT 0,
        share_image_path TEXT
      )
    ''');

    // 设置表
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at INTEGER NOT NULL
      )
    ''');

    // AI 缓存表
    await db.execute('''
      CREATE TABLE ai_cache (
        id TEXT PRIMARY KEY,
        method_id TEXT,
        input_hash TEXT,
        response_json TEXT,
        created_at INTEGER NOT NULL
      )
    ''');

    // 用户资料表
    await db.execute('''
      CREATE TABLE user_profiles (
        id TEXT PRIMARY KEY,
        name TEXT,
        birth_datetime TEXT,
        gender TEXT,
        timezone TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
  }
}
