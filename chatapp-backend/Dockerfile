# Use the official Node.js 20.x image as the base
FROM node:20-alpine

# Set the working directory in the container
WORKDIR /app

# Copy package.json and package-lock.json to install dependencies
# COPY package*.json ./
# COPY ./prepare.js prepare.js
COPY . .

# Install dependencies
RUN npm install

# Copy the rest of the application files
# COPY . .
COPY .env.local .env

# Expose the port that the app runs on
EXPOSE 8080

# Start the application
CMD ["npm", "start"]
