import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  Future<Database>? _database;

  Future<Database> get database => _database ??= _open();

  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query(
      'app_meta',
      columns: const ['value'],
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['value'] as String?;
  }

  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    return openDatabase(
      path.join(databasesPath, 'fieldtask_pro.db'),
      version: 7,
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
        await _createStatusUpdatesTable(db);
        await _createPendingAttachmentsTable(db);
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
        if (oldVersion < 4) await _createStatusUpdatesTable(db);
        if (oldVersion < 5) {
          final columns = await db.rawQuery(
            'PRAGMA table_info(intervention_status_updates)',
          );
          final existingColumns =
              columns.map((column) => column['name'] as String).toSet();
          if (!existingColumns.contains('notes')) {
            await db.execute(
              'ALTER TABLE intervention_status_updates ADD COLUMN notes TEXT',
            );
          }
          if (!existingColumns.contains('includes_notes')) {
            await db.execute(
              'ALTER TABLE intervention_status_updates '
              'ADD COLUMN includes_notes INTEGER NOT NULL DEFAULT 0',
            );
          }
        }
        if (oldVersion < 6) await _createPendingAttachmentsTable(db);
        if (oldVersion >= 6 && oldVersion < 7) {
          await db.execute(
            "ALTER TABLE pending_attachments ADD COLUMN type TEXT NOT NULL DEFAULT 'photo'",
          );
        }
      },
    );
  }

  Future<void> _createStatusUpdatesTable(DatabaseExecutor db) => db.execute('''
    CREATE TABLE IF NOT EXISTS intervention_status_updates (
      intervention_id TEXT PRIMARY KEY,
      technician_id INTEGER NOT NULL,
      status TEXT NOT NULL,
      sync_version INTEGER NOT NULL,
      is_conflict INTEGER NOT NULL DEFAULT 0,
      notes TEXT,
      includes_notes INTEGER NOT NULL DEFAULT 0,
      queued_at TEXT NOT NULL
    )
  ''');

  Future<void> _createPendingAttachmentsTable(DatabaseExecutor db) =>
      db.execute('''
    CREATE TABLE IF NOT EXISTS pending_attachments (
      client_uuid TEXT PRIMARY KEY,
      technician_id INTEGER NOT NULL,
      intervention_id TEXT NOT NULL,
      file_path TEXT NOT NULL,
      type TEXT NOT NULL DEFAULT 'photo',
      caption TEXT,
      queued_at TEXT NOT NULL
    )
  ''');
}
