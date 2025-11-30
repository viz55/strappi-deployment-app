# ─────────────────────────────────────────────
# 1. BUILD STAGE
# ─────────────────────────────────────────────
FROM node:18-alpine AS builder

WORKDIR /app

# Install required build tools
RUN apk add --no-cache build-base python3

COPY package.json yarn.lock ./
RUN yarn install

COPY . .
RUN yarn build


# ─────────────────────────────────────────────
# 2. RUNTIME STAGE
# ─────────────────────────────────────────────
FROM node:18-alpine

WORKDIR /app

# Install SQLite support just in case (optional)
RUN apk add --no-cache sqlite

COPY --from=builder /app /app

RUN yarn install --production

EXPOSE 1337

CMD ["yarn", "start"]

