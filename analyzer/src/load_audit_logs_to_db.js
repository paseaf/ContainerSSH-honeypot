/**
 * @file write transformed_logs.json into sqlite db file audit_log.db
 */
const sqlite3 = require("sqlite3").verbose();
const db = new sqlite3.Database("audit_log.db");
const transformedLogs = require("../downloads/transformed_logs.json");

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS audit_log (
    name TEXT PRIMARY KEY NOT NULL, 
    byteSize INTEGER NOT NULL,
    lastModified STRING NOT NULL,
    ip STRING NOT NULL,
    isAuthenticated INTEGER NOT NULL,
    username TEXT NULL,
    country TEXT
    )`);

  db.run("BEGIN TRANSACTION");
  const stmt = db.prepare(
    "INSERT OR REPLACE INTO audit_log VALUES (?,?,?,?,?,?,?)"
  );
  transformedLogs.forEach((log, idx) => {
    stmt.run([
      log.name,
      log.byteSize,
      log.lastModified,
      log.ip,
      log.isAuthenticated,
      log.username,
      log.country,
    ]);
    console.log(`Inserting progress: ${idx + 1}/${transformedLogs.length}`);
  });
  stmt.finalize();
  db.run("COMMIT");

  db.get("SELECT COUNT(*) AS count FROM audit_log", (err, result) => {
    console.log(`Inserted ${result.count} rows`);
  });
});

db.close();
