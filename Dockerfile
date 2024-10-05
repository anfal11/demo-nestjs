# # Multi-stage build to separate build dependencies from production image

# # Stage 1: Builder
# FROM node:20-alpine as builder

# # Set environment variable for build
# ENV NODE_ENV=build

# # Use non-root user for security
# USER node
# WORKDIR /home/node

# # Copy package files and install dependencies
# COPY package*.json ./
# RUN npm ci

# # Copy application code, generate Prisma client, and build the app
# COPY --chown=node:node . .
# RUN npx prisma generate \
#     && npm run build \
#     && npm prune --omit=dev

# # Stage 2: Production
# FROM node:20-alpine

# # Set environment variable for production
# ENV NODE_ENV=production

# # Use non-root user for security
# USER node
# WORKDIR /home/node

# # Copy only the necessary artifacts from the builder stage
# COPY --from=builder --chown=node:node /home/node/package*.json ./
# COPY --from=builder --chown=node:node /home/node/node_modules/ ./node_modules/
# COPY --from=builder --chown=node:node /home/node/dist/ ./dist/

# # Set secure permissions on the dist folder
# RUN chmod -R 500 dist

# # Remove read access for others
# RUN find dist -type d -exec chmod 500 {} \; \
#     && find dist -type f -exec chmod 400 {} \;

# # Run the application
# CMD ["node", "dist/server.js"]

# Multi-stage build to separate build dependencies from the production image

# Stage 1: Builder
FROM node:20-alpine AS builder

# Set environment variable for build
ENV NODE_ENV=build

# Use non-root user for security
USER node
WORKDIR /home/node

# Copy package files and install dependencies
COPY --chown=node:node package*.json ./
RUN npm ci

# Copy application code, generate Prisma client, and build the app
COPY --chown=node:node . .
RUN npx prisma generate \
    && npm run build \
    && npm prune --omit=dev

# Stage 2: Production
FROM node:20-alpine

# Set environment variable for production
ENV NODE_ENV=production

# Use non-root user for security
USER node
WORKDIR /home/node

# Copy only the necessary artifacts from the builder stage
COPY --from=builder --chown=node:node /home/node/package*.json ./
COPY --from=builder --chown=node:node /home/node/node_modules/ ./node_modules/
COPY --from=builder --chown=node:node /home/node/dist/ ./dist/

# Set secure permissions on the dist folder
RUN chmod -R 500 dist \
    && find dist -type d -exec chmod 500 {} \; \
    && find dist -type f -exec chmod 400 {} \;

# Run the application
CMD ["node", "dist/main.js"] 
