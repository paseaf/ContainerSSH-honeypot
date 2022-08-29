/**
 * @file transforms downloaded audit log for later use
 */
const fs = require("fs/promises");
const geoip = require("geoip-country");
const rawMetadata = require("../downloads/downloaded_audit_log_metadata.json");

const { spawn } = require("node:child_process");
const { open, readdir } = require("node:fs/promises");
const { assert } = require("console");
main().catch((e) => console.error(e));

async function main() {
  await transformAuditLogs();
  // transform metadata
  const transformedMetadata = rawMetadata.map(addCountry);

  // store
  fs.writeFile(
    "./downloads/transformed_audit_log_metadata.json",
    JSON.stringify(transformedMetadata).split("},{").join("},\n{")
  );
}

function addCountry(log) {
  const country = geoip.lookup(log.ip).country;
  return {
    ...log,
    country,
  };
}

async function transformAuditLogs() {
  const objectDir = "./downloads/objects";
  const objectNames = (await readdir(objectDir)).filter(
    (filename) => filename.length === 32
  );

  // decoding
  const decodedDir = "./downloads/objects_decoded";
  let currentProgress = 0;
  for (const objectName of objectNames) {
    const decoder = spawn("containerssh-auditlog-decoder", [
      "-file",
      `${objectDir}/${objectName}`,
    ]);

    const fd = await open(`${decodedDir}/${objectName}.json`, "w");
    const writable = fd.createWriteStream({
      encoding: "utf8",
    });

    console.log(`Decoding ${objectName}...`);

    // event handlers
    decoder.stdout.on("error", (error) => {
      console.error("Failed to decode the file.", error);
    });

    decoder.stdout.on("data", (data) => {
      writable.write(data.toString());
    });

    decoder.on("close", (exitCode) => {
      if (exitCode === 0) {
        console.log(
          `${objectName} decoded! Progress: ${currentProgress}/${objectNames.length}`
        );
        currentProgress++;
        fd?.close();
      } else {
        console.error(
          `ERROR: failed to decode ${objectName}. Exit code ${exitCode}`
        );
        process.exit(1);
      }
    });
  }

  // verification
  const decodedObjectNames = await readdir(decodedDir);
  assert(
    objectNames.length === decodedObjectNames.length,
    `Verification failed! Make sure if decoded folder is clean!
Number of original objects: ${objectNames.length}
Number of decoded objects: ${decodedObjectNames.length}`
  );
}
