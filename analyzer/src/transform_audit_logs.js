/**
 * @file transforms downloaded audit log for later use
 */
const fs = require("fs/promises");
const geoip = require("geoip-country");
const rawLogs = require("../downloads/object_list.json");

// transform
const transformedLogs = rawLogs.map(addCountry);

// load
fs.writeFile(
  "./downloads/transformed_logs.json",
  JSON.stringify(transformedLogs).split("},{").join("},\n{")
);

function addCountry(log) {
  const country = geoip.lookup(log.ip).country;
  return {
    ...log,
    country,
  };
}
