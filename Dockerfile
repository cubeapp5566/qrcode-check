# syntax=docker/dockerfile:1.6

# ---- Build stage ----
FROM node:20-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src
COPY server ./server

RUN npm run build

# ---- Runtime stage ----
FROM node:20-alpine AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4173

COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server

RUN mkdir -p /app/data/scan-photos \
    && addgroup -S app && adduser -S app -G app \
    && chown -R app:app /app
USER app

VOLUME ["/app/data"]
EXPOSE 4173

CMD ["node", "server/index.js"]
