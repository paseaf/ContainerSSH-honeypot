#!/usr/bin/env node
const fs = require("fs/promises");
const shell = require("shelljs");

async function configureDotEnv() {
  const minioCredentials = await extractMinioCredentials(
    "../terraform/credentials.txt"
  );
  const loggerVmIp = `LOGGER_VM_IP="${getVmIp("logger-vm")}"`;

  const dotEnvFileContent = [loggerVmIp, ...minioCredentials].join("\n");
  await fs.writeFile("./.env", dotEnvFileContent);

  console.log(".env file has been successfully created!");
}

async function extractMinioCredentials(filePath) {
  const fileContent = await fs.readFile(filePath, {
    encoding: "utf8",
  });
  const minioCredentials = fileContent
    .split("\n")
    .filter((line) => line.includes("MINIO"));

  return minioCredentials;
}

function getVmIp(vmName) {
  const result = shell.exec(
    `gcloud compute instances describe ${vmName} \
       --format='get(networkInterfaces[0].accessConfigs[0].natIP)' \
       --zone=europe-west3-c`
  );
  if (result.code !== 0)
    throw new Error(`Failed to get VM IP: ${result.stderr}`);

  const ip = result.stdout.split("\n").at(0);
  return ip;
}
configureDotEnv().catch((e) => console.error(e));
