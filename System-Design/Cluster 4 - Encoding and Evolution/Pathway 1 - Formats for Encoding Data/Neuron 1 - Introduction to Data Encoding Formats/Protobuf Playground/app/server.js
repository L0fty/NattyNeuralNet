const express = require('express');
const app = express();
const path = require('path');
const protobuf = require('protobufjs');
const bodyParser = require('body-parser');
const fs = require('fs');

// Middleware to parse JSON bodies
app.use(express.json({ limit: '1mb' }));

// Serve static files (HTML, CSS, JS)
app.use(express.static(path.join(__dirname)));

// Serve index.html on the root path
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'index.html'));
});

// Endpoint to calculate size
app.post('/calculate-size', async (req, res) => {
  try {
    const { schema, data } = req.body;
    const root = await protobuf.parse(schema).root;
    const Message = root.lookupType("MyMessage");

    const errMsg = Message.verify(data);
    if (errMsg) {
      throw new Error(errMsg);
    }

    const message = Message.create(data);
    const buffer = Message.encode(message).finish();

    res.json({ size: buffer.length });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Endpoint to encode data
app.post('/encode', async (req, res) => {
  try {
    const { schema, data } = req.body;
    const root = await protobuf.parse(schema).root;
    const Message = root.lookupType("MyMessage");

    const errMsg = Message.verify(data);
    if (errMsg) {
      throw new Error(errMsg);
    }

    const message = Message.create(data);
    const buffer = Message.encode(message).finish();
    const base64Encoded = Buffer.from(buffer).toString('base64');

    res.json({ encodedData: base64Encoded });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Endpoint to decode data
app.post('/decode', async (req, res) => {
  try {
    const { schema, encodedData } = req.body;
    const root = await protobuf.parse(schema).root;
    const Message = root.lookupType("MyMessage");

    const buffer = Buffer.from(encodedData, 'base64');
    const message = Message.decode(buffer);
    const object = Message.toObject(message, {
      longs: String,
      enums: String,
      bytes: String,
      // see ConversionOptions
    });

    res.json({ data: object });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});