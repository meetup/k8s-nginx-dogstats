const http = require('http')
const port = 80

const server = http.createServer((request, response) => {
    console.log(request.url)
    response.end('projects/12345/zones/us-central1-c')
})

server.listen(port, (err) => {
    if (err) {
      return console.log('something bad happened', err)
    }
    console.log(`server is listening on ${port}`)
})