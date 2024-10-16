const express = require('express');
const app = express();
const path = require('path');
const avro = require('avsc');

// Middleware to parse JSON bodies
app.use(express.json());

// Serve static files (HTML, CSS, JS)
app.use(express.static(path.join(__dirname)));

// Serve index.html on the root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Endpoint to calculate size
app.post('/calculate-size', (req, res) => {
  try {
    const { schema, data } = req.body;
    const type = avro.Type.forSchema(schema);
    const buf = type.toBuffer(data);
    res.json({ size: buf.length });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Endpoint to encode data
app.post('/encode', (req, res) => {
  try {
    const { schema, data } = req.body;
    const type = avro.Type.forSchema(schema);
    const buf = type.toBuffer(data);
    const base64Encoded = buf.toString('base64');
    res.json({ encodedData: base64Encoded });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Endpoint to decode data
app.post('/decode', (req, res) => {
  try {
    const { schema, encodedData } = req.body;
    const type = avro.Type.forSchema(schema);
    const buf = Buffer.from(encodedData, 'base64');
    const data = type.fromBuffer(buf);
    res.json({ data });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});