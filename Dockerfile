# # Multi-stage build to separate build dependencies from the production image

# # Stage 1: Builder
# FROM node:20-alpine AS builder

# # Set environment variable for build
# ENV NODE_ENV=build

# # Use non-root user for security
# USER node
# WORKDIR /home/node

# # Copy package files and install dependencies
# COPY --chown=node:node package*.json ./
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
# RUN chmod -R 500 dist \
#     && find dist -type d -exec chmod 500 {} \; \
#     && find dist -type f -exec chmod 400 {} \;

# # Run the application
# CMD ["node", "dist/main.js"] 

# Multi-stage build to separate build dependencies from the production image

# Stage 1 - Builder
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package.json and package-lock.json
COPY --chown=node:node package*.json ./

# Install dependencies
RUN npm ci

# Copy other files (like tsconfig and source code)
COPY --chown=node:node tsconfig.json ./
COPY --chown=node:node src/ ./src

# COPY the Prisma schema directory into the container
COPY --chown=node:node prisma/ ./prisma

# Generate Prisma client, build the app, and prune dev dependencies
RUN npx prisma generate --schema=prisma/schema.prisma \
    && npm run build \
    && npm prune --omit=dev

# Stage 2 - Final image
FROM node:18-alpine AS production

# Set working directory
WORKDIR /app

# Copy the built app from the builder stage
COPY --from=builder /app ./

# Start the app
CMD ["node", "dist/main.js"]

