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

    return await openDatabase(path, version: 2, onCreate: _createDB, onUpgrade: _onUpgrade);
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
  date $textType,
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

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE observations ADD COLUMN date TEXT');
    }
  }

  Future<int> insertObservation(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('observations', row);
  }

  Future<List<Map<String, dynamic>>> getObservations() async {
    final db = await instance.database;
    return await db.query('observations', orderBy: 'id DESC');
  }

  Future<int> updateObservation(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'observations',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteObservation(int id) async {
    final db = await instance.database;
    return await db.delete(
      'observations',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
