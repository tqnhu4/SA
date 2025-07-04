# Dockerfile

# Use an official Node.js runtime as a parent image
# We choose a specific version (e.g., 18-alpine) for stability and smaller image size
FROM node:18-alpine

# Set the working directory in the container
# All subsequent commands will be run from this directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if any) to the working directory
# This allows npm install to run efficiently by leveraging Docker's cache
# If these files don't change, this layer won't be rebuilt
COPY package*.json ./

# Install any defined application dependencies
# The --production flag ensures only production dependencies are installed
RUN npm install --production

# Copy the rest of the application source code to the working directory
COPY . .

# Expose the port the app runs on
# This informs Docker that the container listens on the specified network ports at runtime.
# It does NOT actually publish the port. For that, you use -p when running.
EXPOSE 8080

# Define the command to run the application when the container starts
# CMD specifies the default command to execute when a container is run.
# This uses the exec form, which is recommended.
CMD [ "node", "app.js" ]