# Use the official Node.js 14 Alpine image
FROM node:14-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy application source code
COPY ./app/ .

# Install dependencies
RUN npm install express livereload connect-livereload
RUN npm install -g nodemon

# Expose ports
EXPOSE 8080
EXPOSE 35729

# Start the server
CMD ["sh", "-c", "npm install express livereload connect-livereload && npx nodemon --ext js,json,html,css server.js"]