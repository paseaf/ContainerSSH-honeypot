#!/usr/bin/env node
const Minio = require("minio");
require("dotenv").config();
const fs = require("fs");

const BUCKET_NAME = "honeypot";
const METADATA_PATH = "./downloads/downloaded_audit_log_metadata.json";
const AUDIT_LOGS_DIR = "./downloads/objects";

const minioClient = new Minio.Client({
  endPoint: process.env.LOGGER_VM_IP,
  port: 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ROOT_USER,
  secretKey: process.env.MINIO_ROOT_PASSWORD,
});

main("ALL").catch((e) => {
  throw e;
});

async function main(option) {
  option = option.toUpperCase();
  switch (option) {
    case "ALL":
      await downloadAuditLogMetadata(METADATA_PATH);
      await downloadAuditLogs(METADATA_PATH, AUDIT_LOGS_DIR);
      break;
    case "METADATA":
      await downloadAuditLogMetadata(METADATA_PATH);
      break;
    case "LOGS":
      await downloadAuditLogs(METADATA_PATH, AUDIT_LOGS_DIR);
      break;
    default:
      throw Error(`Download option must be one of ["ALL", "METADATA", "LOGS"]`);
  }
}

function downloadAuditLogMetadata(targetPath) {
  return new Promise((resolve, reject) => {
    const stream =
      minioClient.extensions.listObjectsV2WithMetadata(BUCKET_NAME);
    console.log("Downloading bucket object info...");

    let isFirstRecord = true;
    stream.on("data", function (obj) {
      // Download metadata
      try {
        console.log(`Downloading ${obj.name}...`);

        const logMetadata = extractMetadata(obj);
        const objJson = JSON.stringify(logMetadata);

        if (isFirstRecord) {
          isFirstRecord = false;
          // Note: use sync to avoid race condition when appending lines
          fs.writeFileSync(targetPath, "[");
          fs.appendFileSync(targetPath, objJson);
        } else {
          fs.appendFileSync(targetPath, ",\n" + objJson);
        }

        console.log(`Finished downloading ${obj.name}...`);
      } catch (e) {
        throw e;
      }
    });

    stream.on("end", () => {
      fs.appendFileSync(targetPath, "]");
      console.log(`Download finished. File location: ${targetPath}`);
      resolve(targetPath);
    });

    stream.on("error", function (err) {
      reject(err);
    });
  });
}

function extractMetadata(objMetadata) {
  const { name, size: byteSize, lastModified } = objMetadata;
  const result = { name, byteSize, lastModified };
  for (const { Key: key, Value: value } of objMetadata.metadata.Items) {
    switch (key) {
      case "X-Amz-Meta-Ip":
        result.ip = value;
        break;
      case "X-Amz-Meta-Authenticated":
        result.isAuthenticated = value;
        break;
      case "X-Amz-Meta-Username":
        result.username = value;
        break;
    }
  }
  return result;
}

async function downloadAuditLogs(metadataFilePath, targetDir) {
  const metadataRecords = require(`../${metadataFilePath}`);
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
          fs.accessSync(`${targetDir}/${objectName}`);
          console.log(`Object ${objectName} already exists. Skipped`);
        } catch (_e) {
          return minioClient.fGetObject(
            BUCKET_NAME,
            objectName,
            `${targetDir}/${objectName}`
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
