/**
 * @file transforms downloaded audit log for later use
 */
const fs = require("fs/promises");
const geoip = require("geoip-country");
const rawMetadata = require("../downloads/downloaded_audit_log_metadata.json");

const { spawn } = require("node:child_process");
const { open, readdir } = require("node:fs/promises");
const readline = require("node:readline");
const { assert } = require("console");
main().catch((e) => console.error(e));

async function main() {
  // transform metadata
  const transformedMetadata = rawMetadata.map(addCountry);

  // store
  fs.writeFile(
    "./downloads/transformed_audit_log_metadata.json",
    JSON.stringify(transformedMetadata).split("},{").join("},\n{")
  );

  await decodeAuditLogs();
  await extractDataFromAuditLogs();
}

function addCountry(log) {
  const country = geoip.lookup(log.ip).country;
  return {
    ...log,
    country,
  };
}

async function decodeAuditLogs() {
  const objectDir = "./downloads/objects";
  const objectNames = (await readdir(objectDir)).filter(
    (filename) => filename.length === 32
  );

  // decoding
  const decodedDir = "./downloads/objects_decoded";
  await fs.mkdir(decodedDir, { recursive: true });
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
        currentProgress++;
        console.log(
          `${objectName} decoded! Progress: ${currentProgress}/${objectNames.length}`
        );
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

/**
 * Parse decoded audit logs and extract parts of data for analysis
 */
async function extractDataFromAuditLogs() {
  // decoding
  const sourceDir = "./downloads/objects_decoded";
  const sourceFileNames = (await readdir(sourceDir)).filter(
    (filename) => filename.length === 32 + ".json".length
  );

  const targetFilePath = "./downloads/objects_parsed.json";
  const targetFd = await open(targetFilePath, "w");
  const targetWritable = targetFd.createWriteStream({
    encoding: "utf8",
  });

  let currentProgress = 0;
  for (const sourceFileName of sourceFileNames) {
    const sourceFd = await open(`${sourceDir}/${sourceFileName}`, "r");
    const sourceReadable = sourceFd.createReadStream({
      encoding: "utf8",
    });
    const rl = readline.createInterface({
      input: sourceReadable,
      crlfDelay: Infinity,
    });

    const parsedObject = {
      objectName: sourceFileName.substring(0, 32),
      password: undefined,
      commands: [],
      startTimestamp: 0,
      endTimestamp: 0,
    };
    console.log(`Parsing ${sourceFileName}...`);

    rl.on("line", (line) => {
      const obj = JSON.parse(line);
      switch (obj.typeId) {
        case "auth_password": {
          const passwordBuffer = Buffer.from(obj.payload.password, "base64");
          parsedObject.password = passwordBuffer.toString();
          break;
        }
        case "exec": {
          const command = {
            command: obj.payload.program,
            timestamp: obj.timestamp,
          };
          parsedObject.commands.push(command);
          break;
        }
        case "connect":
          parsedObject.startTimestamp = obj.timestamp;
          break;
        case "disconnect":
          parsedObject.endTimestamp = obj.timestamp;
          break;
        default:
        // ignore other commands
      }
    });

    rl.on("close", () => {
      // append parsed object to a file?
      targetWritable.write(JSON.stringify(parsedObject));
      targetWritable.write("\n");

      // update states
      currentProgress++;
      console.log(
        `${sourceFileName} parsed! Progress: ${currentProgress}/${sourceFileNames.length}`
      );
      sourceFd?.close();
    });
  }
}
