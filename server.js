const fs = require('fs');
const express = require('express');
const app = express();

var host = process.env.HOST || '0.0.0.0';
var port = process.env.PORT || 8080;

app.get('/', (req, res) => {
    fs.readFile('./index.html', (err, html) => res.end(html));
});
app.listen(port, host, function () {
    console.log('Server on ' + host + ':' + port);
});