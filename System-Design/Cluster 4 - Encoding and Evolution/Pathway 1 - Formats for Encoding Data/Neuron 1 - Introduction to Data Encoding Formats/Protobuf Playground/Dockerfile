# Use the official Node.js 14 Alpine image
FROM node:14-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy application source code
COPY ./app/ .

# Install dependencies
RUN npm install express protobufjs

# Expose port 8080
EXPOSE 8080

# Start the server
CMD [ "node", "server.js" ]