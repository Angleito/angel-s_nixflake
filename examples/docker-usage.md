# Docker Usage Guide

This guide provides comprehensive instructions for using Docker with the project, including development, production, and deployment scenarios.

## Prerequisites

- Docker Engine 20.10+ or Docker Desktop
- Docker Compose 2.0+ (optional but recommended)
- Basic understanding of containerization concepts

## Quick Start

### 1. Using Pre-built Image

```bash
# Pull and run the latest image
docker run -it --rm ghcr.io/your-org/your-project:latest

# Run with custom configuration
docker run -it --rm \
  -v $(pwd)/config:/app/config \
  -p 8080:8080 \
  ghcr.io/your-org/your-project:latest
```

### 2. Building from Source

```bash
# Clone the repository
git clone https://github.com/your-org/your-project.git
cd your-project

# Build the Docker image
docker build -t your-project:local .

# Run the locally built image
docker run -it --rm your-project:local
```

## Docker Images

### Available Images

- `ghcr.io/your-org/your-project:latest` - Latest stable release
- `ghcr.io/your-org/your-project:main` - Latest development build
- `ghcr.io/your-org/your-project:v1.0.0` - Specific version tags
- `ghcr.io/your-org/your-project:alpine` - Alpine-based minimal image

### Image Variants

#### Standard Image (Ubuntu-based)
```dockerfile
FROM ubuntu:22.04
# Full-featured image with all dependencies
# Size: ~500MB
```

#### Alpine Image
```dockerfile
FROM alpine:3.18
# Minimal image with basic functionality
# Size: ~50MB
```

#### Distroless Image
```dockerfile
FROM gcr.io/distroless/base-debian11
# Security-focused minimal image
# Size: ~30MB
```

## Building Custom Images

### Basic Dockerfile

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Create application user
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Set working directory
WORKDIR /app

# Copy source code
COPY . .

# Build the application
RUN make build

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Set entrypoint
ENTRYPOINT ["./your-project"]
```

### Multi-stage Build

```dockerfile
# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o your-project

# Runtime stage
FROM alpine:3.18

RUN apk --no-cache add ca-certificates
WORKDIR /root/

COPY --from=builder /app/your-project .
COPY --from=builder /app/config ./config

EXPOSE 8080
CMD ["./your-project"]
```

### Build Arguments

```dockerfile
ARG VERSION=latest
ARG BUILD_DATE
ARG VCS_REF

LABEL org.opencontainers.image.version=$VERSION \
      org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/your-org/your-project"
```

## Running Containers

### Basic Usage

```bash
# Run with default configuration
docker run your-project:latest

# Run with custom arguments
docker run your-project:latest --config /app/config/prod.yaml

# Run in detached mode
docker run -d --name your-project-container your-project:latest

# Run with environment variables
docker run -e LOG_LEVEL=debug -e PORT=8080 your-project:latest
```

### Volume Mounts

```bash
# Mount configuration directory
docker run -v $(pwd)/config:/app/config your-project:latest

# Mount data directory
docker run -v your-project-data:/app/data your-project:latest

# Mount multiple volumes
docker run \
  -v $(pwd)/config:/app/config \
  -v $(pwd)/data:/app/data \
  -v $(pwd)/logs:/app/logs \
  your-project:latest
```

### Network Configuration

```bash
# Expose ports
docker run -p 8080:8080 your-project:latest

# Use custom network
docker network create your-project-network
docker run --network your-project-network your-project:latest

# Connect to existing network
docker run --network bridge your-project:latest
```

## Docker Compose

### Basic docker-compose.yml

```yaml
version: '3.8'

services:
  your-project:
    image: ghcr.io/your-org/your-project:latest
    ports:
      - "8080:8080"
    environment:
      - LOG_LEVEL=info
      - DATABASE_URL=postgresql://user:pass@db:5432/mydb
    volumes:
      - ./config:/app/config
      - your-project-data:/app/data
    depends_on:
      - db
      - redis
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data
    restart: unless-stopped

volumes:
  your-project-data:
  postgres-data:
  redis-data:
```

### Development docker-compose.yml

```yaml
version: '3.8'

services:
  your-project-dev:
    build:
      context: .
      dockerfile: Dockerfile.dev
    ports:
      - "8080:8080"
      - "9229:9229"  # Debug port
    environment:
      - NODE_ENV=development
      - DEBUG=true
    volumes:
      - .:/app
      - /app/node_modules
    depends_on:
      - db
      - redis
    command: npm run dev

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb_dev
      - POSTGRES_USER=dev
      - POSTGRES_PASSWORD=dev
    ports:
      - "5432:5432"
    volumes:
      - postgres-dev-data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres-dev-data:
```

### Production docker-compose.yml

```yaml
version: '3.8'

services:
  your-project:
    image: ghcr.io/your-org/your-project:v1.0.0
    deploy:
      replicas: 3
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
    ports:
      - "8080:8080"
    environment:
      - LOG_LEVEL=warn
      - NODE_ENV=production
    volumes:
      - ./config/prod.yaml:/app/config/config.yaml:ro
      - your-project-data:/app/data
    depends_on:
      - db
      - redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - your-project
    restart: unless-stopped

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
    secrets:
      - db_password
    volumes:
      - postgres-data:/var/lib/postgresql/data
    restart: unless-stopped

  redis:
    image: redis:7-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis-data:/data
    restart: unless-stopped

secrets:
  db_password:
    file: ./secrets/db_password.txt

volumes:
  your-project-data:
  postgres-data:
  redis-data:
```

## Development Workflow

### Development Dockerfile

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source code
COPY . .

# Expose port and debug port
EXPOSE 8080 9229

# Start with nodemon for development
CMD ["npm", "run", "dev"]
```

### Hot Reload Setup

```bash
# Build development image
docker build -f Dockerfile.dev -t your-project:dev .

# Run with volume mount for hot reload
docker run -v $(pwd):/app -v /app/node_modules -p 8080:8080 your-project:dev
```

### Docker Compose for Development

```bash
# Start development environment
docker-compose -f docker-compose.dev.yml up

# Rebuild services
docker-compose -f docker-compose.dev.yml up --build

# Run specific service
docker-compose -f docker-compose.dev.yml run your-project-dev npm test
```

## Production Deployment

### Health Checks

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

### Security Best Practices

```dockerfile
# Use specific version tags
FROM node:18.17.0-alpine

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nextjs -u 1001

# Set proper permissions
COPY --chown=nextjs:nodejs . .
USER nextjs

# Use secrets for sensitive data
RUN --mount=type=secret,id=api_key \
  API_KEY=$(cat /run/secrets/api_key) make build
```

### Resource Limits

```yaml
services:
  your-project:
    deploy:
      resources:
        limits:
          cpus: '0.5'
          memory: 512M
        reservations:
          cpus: '0.25'
          memory: 256M
```

## Container Orchestration

### Docker Swarm

```bash
# Initialize swarm
docker swarm init

# Deploy stack
docker stack deploy -c docker-compose.yml your-project

# Scale service
docker service scale your-project_your-project=5

# Update service
docker service update --image ghcr.io/your-org/your-project:v1.1.0 your-project_your-project
```

### Kubernetes Deployment

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: your-project
spec:
  replicas: 3
  selector:
    matchLabels:
      app: your-project
  template:
    metadata:
      labels:
        app: your-project
    spec:
      containers:
      - name: your-project
        image: ghcr.io/your-org/your-project:v1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: LOG_LEVEL
          value: "info"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
```

## Monitoring and Logging

### Container Logs

```bash
# View logs
docker logs your-project-container

# Follow logs
docker logs -f your-project-container

# View logs with timestamps
docker logs -t your-project-container

# Limit log output
docker logs --tail 100 your-project-container
```

### Monitoring with Prometheus

```yaml
services:
  your-project:
    image: ghcr.io/your-org/your-project:latest
    ports:
      - "8080:8080"
      - "9090:9090"  # Metrics port
    environment:
      - ENABLE_METRICS=true

  prometheus:
    image: prom/prometheus
    ports:
      - "9090:9090"
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
```

## Troubleshooting

### Common Issues

1. **Container won't start**: Check logs with `docker logs <container>`
2. **Port conflicts**: Use `docker port <container>` to check port mappings
3. **Volume mount issues**: Verify paths and permissions
4. **Network connectivity**: Check network configuration and firewall rules

### Debugging Commands

```bash
# Inspect container
docker inspect your-project-container

# Execute commands in running container
docker exec -it your-project-container /bin/bash

# Check resource usage
docker stats your-project-container

# Check network connectivity
docker exec your-project-container ping google.com
```

### Image Optimization

```bash
# Reduce image size
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# Remove unused images
docker image prune -a

# Multi-stage build to reduce size
# See Multi-stage Build example above
```

## Best Practices

1. **Use specific tags**: Avoid `latest` in production
2. **Minimize layers**: Combine RUN commands
3. **Use .dockerignore**: Exclude unnecessary files
4. **Non-root user**: Run containers as non-root
5. **Health checks**: Implement proper health checks
6. **Secrets management**: Use Docker secrets or external secret management
7. **Resource limits**: Set appropriate CPU and memory limits
8. **Logging**: Use structured logging and log aggregation

## Next Steps

- See [Configuration Guide](../docs/configuration.md) for advanced setup
- Check [Usage Examples](../docs/usage.md) for common use cases
- Join our [Community](../docs/community.md) for support
