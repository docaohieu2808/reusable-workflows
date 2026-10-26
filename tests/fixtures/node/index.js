// The smallest project the pipeline can build, test, package as an image and deploy.
const http = require("node:http");

exports.add = (a, b) => a + b;

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  http.createServer((req, res) => res.end("ok\n")).listen(port, () => console.log(`listening on ${port}`));
}
