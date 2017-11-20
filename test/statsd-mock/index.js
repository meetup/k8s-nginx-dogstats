const dgram = require('dgram');
const server = dgram.createSocket('udp4');

server.on('error', (err) => {
  console.log(`server error:\n${err.stack}`);
  server.close();
});

server.on('message', (msg, rinfo) => {
  console.log(`${msg}`);
});

server.on('listening', () => {
  var address = server.address();
  console.log(`server listening...`);
});

server.bind(8125);
