const Minio = require("minio");
require("dotenv").config();
const fs = require("fs");

const minioClient = new Minio.Client({
  endPoint: process.env.LOGGER_VM_IP,
  port: 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ROOT_USER,
  secretKey: process.env.MINIO_ROOT_PASSWORD,
});

const TARGET_PATH = "./downloads/downloaded_audit_log_metadata.json";

fs.writeFileSync(TARGET_PATH, "[");
let isFirst = true;
const stream = minioClient.extensions.listObjectsV2WithMetadata("honeypot");
console.log("Downloading bucket object info...");

stream.on("data", function (obj) {
  // Download object
  try {
    console.log(`Downloading ${obj.name}...`);
    const { name, size, lastModified } = obj;
    const ip = obj.metadata["X-Amz-Meta-Ip"];
    const isAuthenticated = obj.metadata["X-Amz-Meta-Authenticated"];
    const username = obj.metadata["X-Amz-Meta-Username"];

    const objJson = JSON.stringify({
      name,
      byteSize: size,
      lastModified,
      ip,
      isAuthenticated,
      username,
    });

    if (isFirst) {
      isFirst = false;
      // Note: use sync to avoid race condition in appending lines
      fs.appendFileSync(TARGET_PATH, objJson);
    } else {
      fs.appendFileSync(TARGET_PATH, ",\n" + objJson);
    }

    console.log(`Finished downloading ${obj.name}...`);
  } catch (e) {
    throw e;
  }
});

stream.on("end", async () => {
  fs.appendFileSync(TARGET_PATH, "]");
  console.log(`Download finished. File location: ${TARGET_PATH}`);
});

stream.on("error", function (err) {
  console.log(err);
});
downloadAuditLogs().catch((e) => {
  throw e;
});
async function downloadAuditLogs() {
  const metadataRecords = require(`../${METADATA_PATH}`);
  const recordLength = metadataRecords.length;

  console.log(`Total number of records to download: ${recordLength}`);
  let downloadCount = 0;
  // download in bulks
  const bulkSize = 500;
  const numberOfBulks = Math.ceil(recordLength / bulkSize);
  for (let bulkId = 0; bulkId < numberOfBulks; bulkId++) {
    const bulkBeginPosition = bulkId * bulkSize;
    const bulkEndPosition = Math.min(
      recordLength,
      bulkBeginPosition + bulkSize
    );

    const promises = metadataRecords
      .slice(bulkBeginPosition, bulkEndPosition)
      .map((record) => record.name)
      .map((objectName) => {
        downloadCount++;

        // skip if already downloaded
        try {
          fs.accessSync(`${OBJECT_DIR_PATH}/${objectName}`);
          console.log(`Object ${objectName} already exists. Skipped`);
        } catch (_e) {
          return minioClient.fGetObject(
            BUCKET_NAME,
            objectName,
            `${OBJECT_DIR_PATH}/${objectName}`
          );
        }
      });

    console.log(
      `Downloading bulk ${bulkId}. Progress: ${bulkId + 1}/${numberOfBulks}.`
    );
    await Promise.all(promises);
    console.log(`Finished downloading bulk ${bulkId}`);
  }
  console.log(
    `Download finished. Expected #download: ${recordLength}; Actual #download: ${downloadCount}`
  );
}
