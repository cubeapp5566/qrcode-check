# syntax=docker/dockerfile:1.6

# ---- Build stage ----
# bookworm-slim (glibc) 讓 better-sqlite3 直接抓 prebuilt binary，
# 不必在 image 內安裝 python/make/g++ 從原始碼編譯。
FROM node:20-bookworm-slim AS builder
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY tsconfig.json vite.config.ts index.html ./
COPY src ./src
COPY server ./server
COPY public ./public

# Vite 在 build 時會把 VITE_* 環境變數編進前端 bundle
ARG VITE_ASSET_CIPHER_KEY
ENV VITE_ASSET_CIPHER_KEY=${VITE_ASSET_CIPHER_KEY}

RUN npm run build \
    && npm prune --omit=dev

# ---- Runtime stage ----
FROM node:20-bookworm-slim AS runtime
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=4173

COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/server ./server
COPY package.json ./

RUN mkdir -p /app/data/scan-photos \
    && chown -R node:node /app
USER node

VOLUME ["/app/data"]
EXPOSE 4173

CMD ["node", "server/index.js"]
