const Minio = require("minio");
require("dotenv").config();
const fs = require("fs/promises");

const minioClient = new Minio.Client({
  endPoint: process.env.LOGGER_VM_IP,
  port: 9000,
  useSSL: false,
  accessKey: process.env.MINIO_ROOT_USER,
  secretKey: process.env.MINIO_ROOT_PASSWORD,
});

const TARGET_PATH = "./downloads/object_list.json";

fs.writeFile(TARGET_PATH, "[");
let isFirst = true;
const stream = minioClient.extensions.listObjectsV2WithMetadata("honeypot");
console.log("Downloading bucket object info...");

stream.on("data", async function (obj) {
  // Download object
  try {
    console.log(`Downloading ${obj.name}...`);
    const { name, size, lastModified } = obj;
    const ip = obj.metadata["X-Amz-Meta-Ip"];
    const isAuthenticated = obj.metadata["X-Amz-Meta-Authenticated"];
    const username = obj.metadata["X-Amz-Meta-Username"];

    const objJson = JSON.stringify({
      name,
      size,
      lastModified,
      ip,
      isAuthenticated,
      username,
    });

    if (isFirst) {
      isFirst = false;
      await fs.appendFile(TARGET_PATH, objJson);
    } else await fs.appendFile(TARGET_PATH, ",\n" + objJson);

    console.log(`Finished downloading ${obj.name}...`);
  } catch (e) {
    throw e;
  }
});

stream.on("end", async () => {
  await fs.appendFile(TARGET_PATH, "]");
  console.log(`Download finished. File location: ${TARGET_PATH}`);
});

stream.on("error", function (err) {
  console.log(err);
});
