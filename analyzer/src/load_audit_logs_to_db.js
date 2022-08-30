/**
 * @file write transformed_audit_log_metadata.json into sqlite db file audit_log.db
 */
const sqlite3 = require("sqlite3").verbose();
const DB_FILENAME = "audit_log.db";
const db = new sqlite3.Database(DB_FILENAME);
const transformedLogs = require("../downloads/transformed_audit_log_metadata.json");

main();
function main() {
  loadMetadataToDb();
  loadAuditLogsToDb();
}

function loadMetadataToDb() {
  db.serialize(() => {
    // Create audit_log table
    db.run(`CREATE TABLE IF NOT EXISTS audit_log (
    name TEXT PRIMARY KEY NOT NULL, 
    byteSize INTEGER NOT NULL,
    lastModified STRING NOT NULL,
    ip STRING NOT NULL,
    isAuthenticated INTEGER NOT NULL,
    username TEXT NULL,
    country TEXT
    )`);

    // Inserting to table
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

    // Verification
    db.get("SELECT COUNT(*) AS count FROM audit_log", (_err, result) => {
      console.log(
        `Loading finished.
Inserted ${result.count} rows to "./${DB_FILENAME}"`
      );
    });
  });

  db.close();
}
