const express = require('express');
const app = express();
const path = require('path');

// LiveReload Setup
const livereload = require('livereload');
const connectLivereload = require('connect-livereload');

// Create a livereload server that watches the app directory
const liveReloadServer = livereload.createServer();
liveReloadServer.watch(path.join(__dirname));

// Inject the livereload script into served HTML pages
app.use(connectLivereload());

// Optionally, trigger a refresh once the connection is established:
liveReloadServer.server.once('connection', () => {
  setTimeout(() => {
    liveReloadServer.refresh('/');
  }, 100);
});

// Middleware to parse JSON bodies
app.use(express.json());

// Serve static files (HTML, CSS, JS)
app.use(express.static(path.join(__dirname)));

// Serve index.html on the root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});