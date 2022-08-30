/**
 * @file write transformed_audit_log_metadata.json into sqlite db file audit_log.db
 */
const sqlite3 = require("sqlite3").verbose();
const DB_FILENAME = "audit_log.db";
const transformedLogs = require("../downloads/transformed_audit_log_metadata.json");
const fs = require("node:fs");
const readline = require("node:readline");

main();
function main() {
  const db = new sqlite3.Database(DB_FILENAME);
  loadMetadataToDb(db);

  // update schema
  addColumnsToAuditLogTable(db);

  createCommandTable(db);

  updateAuditLogTable(db);
  fillCommandTable(db);
}

function loadMetadataToDb(db) {
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

    // Verification
    db.get("SELECT COUNT(*) AS count FROM audit_log", (_err, result) => {
      console.log(
        `Loading finished.
Inserted ${result.count} rows to "./${DB_FILENAME}"`
      );
    });
  });
}

function updateAuditLogTable(db) {
  // insert data
  const targetFilePath = "./downloads/objects_parsed.json";
  const rl = readline.createInterface({
    input: fs.createReadStream(targetFilePath),
    crlfDelay: Infinity,
  });

  const stmt = db.prepare(
    `UPDATE OR REPLACE audit_log
    SET password = ?,
        startTimestamp = ?,
        endTimestamp = ?
    WHERE name = ?
    `
  );
  rl.on("line", (line) => {
    if (line.length < 1) return;
    const auditLog = JSON.parse(line);
    // schema: transform_audit_logs.js -> parsedObject
    stmt.run([
      auditLog.password,
      auditLog.startTimestamp,
      auditLog.endTimestamp,
      auditLog.objectName,
    ]);
  });

  rl.on("close", () => {
    stmt.finalize();
  });
}

function fillCommandTable(db) {
  db.serialize(() => {
    // insert data
    const targetFilePath = "./downloads/objects_parsed.json";
    const rl = readline.createInterface({
      input: fs.createReadStream(targetFilePath),
      crlfDelay: Infinity,
    });

    const stmt = db.prepare("INSERT OR REPLACE INTO command VALUES (?,?,?)");

    rl.on("line", (line) => {
      if (line.length < 1) return;
      const auditLog = JSON.parse(line);
      const commands = auditLog.commands;
      // schema: transform_audit_logs.js -> parsedObject
      for (const command of commands) {
        console.log(
          `inserting ${auditLog.objectName}, ${command.command}, ${command.timestamp}`
        );
        stmt.run([auditLog.objectName, command.command, command.timestamp]);
      }
    });

    rl.on("close", () => {
      stmt.finalize();
      db.run("COMMIT");
      db.close();
    });
  });
}

function addColumnsToAuditLogTable(db) {
  db.serialize(() => {
    db.run(`ALTER TABLE audit_log
  ADD COLUMN password TEXT NULL`);

    db.run(`ALTER TABLE audit_log
  ADD COLUMN startTimestamp INTEGER NOT NULL DEFAULT 0`);

    db.run(`ALTER TABLE audit_log
  ADD COLUMN endTimestamp INTEGER NOT NULL DEFAULT 0`);
  });
}

function createCommandTable(db) {
  // enable foreign key: https://sqlite.org/foreignkeys.html#fk_enable
  db.get("PRAGMA foreign_keys = ON");

  db.serialize(() => {
    // add columns to table

    db.run(`CREATE TABLE IF NOT EXISTS command (
      logName TEXT NOT NULL,
      command TEXT NOT NULL,
      timestamp INTEGER NOT NULL,
      FOREIGN KEY(logName) REFERENCES audit_log(name)
    )`);
  });
}
