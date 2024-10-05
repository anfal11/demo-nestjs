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

# Multi-stage build to separate build dependencies from the production image

# Multi-stage build to separate build dependencies from the production image

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

# Copy application code, including tsconfig.json
COPY --chown=node:node . .

# Debug: List contents of the working directory
RUN echo "Contents of /home/node:" && ls -la

# Debug: Display contents of tsconfig.json
RUN echo "Contents of tsconfig.json:" && cat tsconfig.json

# Debug: List contents of the root directory
RUN echo "Contents of root directory:" && ls -la

# Debug: Display package.json scripts
RUN echo "Package.json scripts:" && jq .scripts package.json

# Debug: Display project structure
RUN echo "Project structure:" && find . -maxdepth 3 -type d

# Generate Prisma client, build the app, and prune dev dependencies
RUN npx prisma generate \
    && npm run build \
    && npm prune --omit=dev

# Debug: List contents of dist directory after build
RUN echo "Contents of dist directory after build:" && ls -la dist

# Stage 2: Production
FROM node:20-alpine

# Set environment variable for production
ENV NODE_ENV=production

# Create a new user with a known UID/GID
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy only the necessary artifacts from the builder stage
COPY --from=builder --chown=appuser:appgroup /home/node/package*.json ./
COPY --from=builder --chown=appuser:appgroup /home/node/node_modules/ ./node_modules/
COPY --from=builder --chown=appuser:appgroup /home/node/dist/ ./dist/

# Set secure permissions
RUN chmod -R 500 . \
    && find . -type d -exec chmod 500 {} \; \
    && find . -type f -exec chmod 400 {} \;

# Switch to non-root user
USER appuser

# Run the application
CMD ["node", "dist/main.js"]