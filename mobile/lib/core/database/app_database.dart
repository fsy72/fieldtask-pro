import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    return openDatabase(
      path.join(databasesPath, 'fieldtask_pro.db'),
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE interventions (
            id TEXT PRIMARY KEY,
            technician_id INTEGER NOT NULL,
            client_uuid TEXT,
            client TEXT NOT NULL,
            address TEXT NOT NULL,
            description TEXT NOT NULL,
            equipment TEXT NOT NULL,
            status TEXT NOT NULL,
            priority INTEGER NOT NULL,
            latitude REAL,
            longitude REAL,
            scheduled_at TEXT,
            notes TEXT,
            sync_version INTEGER NOT NULL,
            updated_at TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE app_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX interventions_technician_status '
          'ON interventions (technician_id, status)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          final columns = await db.rawQuery('PRAGMA table_info(interventions)');
          final existingColumns =
              columns.map((column) => column['name'] as String).toSet();
          const requiredColumns = <String, String>{
            'id': 'TEXT',
            'technician_id': 'INTEGER NOT NULL DEFAULT 0',
            'client_uuid': 'TEXT',
            'client': "TEXT NOT NULL DEFAULT ''",
            'address': "TEXT NOT NULL DEFAULT ''",
            'description': "TEXT NOT NULL DEFAULT ''",
            'equipment': "TEXT NOT NULL DEFAULT ''",
            'status': "TEXT NOT NULL DEFAULT 'pending'",
            'priority': 'INTEGER NOT NULL DEFAULT 1',
            'latitude': 'REAL',
            'longitude': 'REAL',
            'scheduled_at': 'TEXT',
            'notes': 'TEXT',
            'sync_version': 'INTEGER NOT NULL DEFAULT 1',
            'updated_at': 'TEXT',
          };
          for (final entry in requiredColumns.entries) {
            if (!existingColumns.contains(entry.key)) {
              // Preserve old cached rows and fill newly required fields safely.
              await db.execute(
                'ALTER TABLE interventions '
                'ADD COLUMN ${entry.key} ${entry.value}',
              );
            }
          }
          await db.execute(
            'CREATE TABLE IF NOT EXISTS app_meta ('
            'key TEXT PRIMARY KEY, value TEXT NOT NULL)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS interventions_technician_status '
            'ON interventions (technician_id, status)',
          );
        }
      },
    );
  }
}
