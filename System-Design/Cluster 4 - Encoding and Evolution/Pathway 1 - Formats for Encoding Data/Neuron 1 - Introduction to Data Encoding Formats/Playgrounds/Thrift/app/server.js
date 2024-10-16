const express = require('express');
const app = express();
const path = require('path');
const thrift = require('thrift');
const fs = require('fs');
const { execSync } = require('child_process');

// Middleware to parse JSON bodies
app.use(express.json({ limit: '1mb' }));

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

    // Write the schema to a temporary file
    fs.writeFileSync('temp_schema.thrift', schema);

    // Generate Thrift code using the Thrift compiler
    execSync('thrift -gen js:node temp_schema.thrift');

    // Load the generated Thrift module
    const ThriftGen = require('./gen-nodejs/temp_schema_types');

    // Create a Thrift object from the data
    const ThriftClass = ThriftGen[data.__type__];
    if (!ThriftClass) {
      throw new Error('Invalid type specified in data');
    }
    const thriftObject = new ThriftClass(data);

    // Serialize the object
    const transport = new thrift.TBufferedTransport(null, (buf) => {});
    const protocol = new thrift.TBinaryProtocol(transport);
    thriftObject.write(protocol);
    const buffer = transport.outBuffers.reduce((acc, buf) => Buffer.concat([acc, buf]), Buffer.alloc(0));

    // Clean up
    fs.unlinkSync('temp_schema.thrift');
    fs.rmdirSync('./gen-nodejs', { recursive: true });

    res.json({ size: buffer.length });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Endpoint to encode data
app.post('/encode', (req, res) => {
  try {
    const { schema, data } = req.body;

    // Write the schema to a temporary file
    fs.writeFileSync('temp_schema.thrift', schema);

    // Generate Thrift code using the Thrift compiler
    execSync('thrift -gen js:node temp_schema.thrift');

    // Load the generated Thrift module
    const ThriftGen = require('./gen-nodejs/temp_schema_types');

    // Create a Thrift object from the data
    const ThriftClass = ThriftGen[data.__type__];
    if (!ThriftClass) {
      throw new Error('Invalid type specified in data');
    }
    const thriftObject = new ThriftClass(data);

    // Serialize the object
    const transport = new thrift.TBufferedTransport(null, (buf) => {});
    const protocol = new thrift.TBinaryProtocol(transport);
    thriftObject.write(protocol);
    const buffer = transport.outBuffers.reduce((acc, buf) => Buffer.concat([acc, buf]), Buffer.alloc(0));

    // Clean up
    fs.unlinkSync('temp_schema.thrift');
    fs.rmdirSync('./gen-nodejs', { recursive: true });

    const base64Encoded = buffer.toString('base64');

    res.json({ encodedData: base64Encoded });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Endpoint to decode data
app.post('/decode', (req, res) => {
  try {
    const { schema, encodedData } = req.body;

    // Write the schema to a temporary file
    fs.writeFileSync('temp_schema.thrift', schema);

    // Generate Thrift code using the Thrift compiler
    execSync('thrift -gen js:node temp_schema.thrift');

    // Load the generated Thrift module
    const ThriftGen = require('./gen-nodejs/temp_schema_types');

    // Assuming the data type is specified in the schema (e.g., the first struct)
    const typeNames = Object.keys(ThriftGen);
    if (typeNames.length === 0) {
      throw new Error('No types found in the schema');
    }
    const ThriftClass = ThriftGen[typeNames[0]];

    // Deserialize the object
    const buffer = Buffer.from(encodedData, 'base64');
    const transport = new thrift.TBufferedTransport(buffer);
    const protocol = new thrift.TBinaryProtocol(transport);
    const thriftObject = new ThriftClass();
    thriftObject.read(protocol);

    // Clean up
    fs.unlinkSync('temp_schema.thrift');
    fs.rmdirSync('./gen-nodejs', { recursive: true });

    res.json({ data: thriftObject });
  } catch (error) {
    res.json({ error: error.message });
  }
});

// Start the server
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`Server is running at http://localhost:${PORT}`);
});