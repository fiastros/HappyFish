import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('marine_survey.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const doubleType = 'REAL NOT NULL';

    await db.execute('''
CREATE TABLE observations (
  id $idType,
  site $textType,
  species $textType,
  latitude $doubleType,
  longitude $doubleType,
  temperature $doubleType,
  ph $doubleType,
  o2_dissous $doubleType,
  sexe $textType,
  standard_length $doubleType,
  total_length $doubleType,
  id_photos $textType,
  remarks $textType,
  photos_json $textType
)
''');
  }

  Future<void> insertObservation(Map<String, dynamic> row) async {
    final db = await instance.database;
    await db.insert('observations', row);
  }

  Future<List<Map<String, dynamic>>> getObservations() async {
    final db = await instance.database;
    return await db.query('observations');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
