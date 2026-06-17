const jsonServer = require('json-server');

const server = jsonServer.create();
const middlewares = jsonServer.defaults();

server.use(middlewares);
server.use(jsonServer.bodyParser);

const xptoIntegration = require('./data/xpto-integration.json');

server.get('/xpto-integration/:id', (_, res) => {
    res.set('Content-type', 'application/json');
    res.jsonp(xptoIntegration);
    res.status(200);
    return;
});

server.listen(9001, () => {
    console.log('iniciou');
});
