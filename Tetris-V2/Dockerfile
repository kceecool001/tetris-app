# =========================
# Stage 1 — Build React App
# =========================
FROM node:16-alpine AS builder

WORKDIR /app

# Copy dependency files first (improves Docker cache usage)
COPY package*.json ./

# Install dependencies (clean + deterministic)
RUN npm ci

# Copy application source
COPY . .

# Build optimized production bundle
RUN npm run build


# =========================
# Stage 2 — Production Image
# =========================
FROM nginx:alpine

# Remove default nginx static files
RUN rm -rf /usr/share/nginx/html/*

# Copy build output from builder stage
COPY --from=builder /app/build /usr/share/nginx/html

# Copy custom nginx config (optional)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
