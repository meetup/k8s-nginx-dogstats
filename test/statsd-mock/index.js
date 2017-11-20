const dgram = require('dgram');
const server = dgram.createSocket('udp4');

server.on('error', (err) => {
  console.log(`server error:\n${err.stack}`);
  server.close();
});

server.on('message', (msg, rinfo) => {
  const given = msg.toString();
  const normalized = given.replace(/(gce_zone:.*)/, "gce_zone:us-central1-c,cloud_provider:gcp");
  if (normlaized == given) {
    console.log("something wasn't replaced with " + given);
  }
  console.log(normalized);
});

server.on('listening', () => {
  var address = server.address();
  console.log(`server listening...`);
});

server.bind(8125);
