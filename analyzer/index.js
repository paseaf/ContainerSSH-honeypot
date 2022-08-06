const Minio = require("minio");
require("dotenv").config();

const minioClient = new Minio.Client({
  endpoint: process.env.LOGGER_VM_IP,
  port: 9000,
  useSSL: true,
  accessKey: process.env.MINIO_ROOT_USER,
  secretKey: process.env.MINIO_ROOT_PASSWORD,
});
