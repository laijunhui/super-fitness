import 'package:sqflite/sqflite.dart';
import '../../core/constants/db_constants.dart';

/// SQLite数据库助手
class DatabaseHelper {
  static Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = '$dbPath/${DbConstants.databaseName}';

    return await openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建运动记录表
    await db.execute('''
      CREATE TABLE ${DbConstants.exercisesTable} (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        distance REAL NOT NULL,
        duration INTEGER NOT NULL,
        calories REAL NOT NULL,
        gps_points TEXT,
        created_at TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // 创建身体指标表
    await db.execute('''
      CREATE TABLE ${DbConstants.bodyMetricsTable} (
        id TEXT PRIMARY KEY,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        waist REAL,
        chest REAL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        bmi REAL,
        bmr REAL,
        created_at TEXT NOT NULL
      )
    ''');

    // 创建用户设置表
    await db.execute('''
      CREATE TABLE ${DbConstants.userSettingsTable} (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  /// 升级数据库
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本1 -> 版本2：添加chest列
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE ${DbConstants.bodyMetricsTable} ADD COLUMN chest REAL');
    }
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
