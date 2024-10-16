# Use the official Node.js 14 Alpine image
FROM node:14-alpine

# Create app directory
WORKDIR /usr/src/app

# Install Express directly
RUN npm install express

# Copy application source code
COPY ./app/ .

# Expose port 8080
EXPOSE 8080

# Start the server
CMD [ "node", "server.js" ]
