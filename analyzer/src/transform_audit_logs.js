/**
 * @file transforms downloaded audit log for later use
 */
const fs = require("fs/promises");
const geoip = require("geoip-country");
const rawMetadata = require("../downloads/downloaded_audit_log_metadata.json");

const { spawn } = require("node:child_process");
const { open } = require("node:fs/promises");
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

// TODO: decode all files
async function transformAuditLogs() {
  const objectName = "636d8cad6195424b926ed2ebb34e2946";
  const decoder = spawn("containerssh-auditlog-decoder", [
    "-file",
    `./downloads/objects/${objectName}`,
  ]);

  const fd = await open(`./downloads/objects/${objectName}.decoded`, "w");
  const writable = fd.createWriteStream({
    encoding: "utf8",
  });

  decoder.stdout.on("error", (error) => {
    console.error("Failed to decode the file.", error);
  });

  decoder.stdout.on("data", (data) => {
    console.log(data.toString());
    writable.write(data.toString());
  });

  decoder.on("close", (status) => {
    console.log(`Decoder exited with status ${status}`);
  });
}
