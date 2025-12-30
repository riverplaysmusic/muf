FROM node:lts-alpine AS base
WORKDIR /app

# Stage 1: Install all dependencies (including dev)
FROM base AS deps
COPY package.json package-lock.json ./
RUN npm ci

# Stage 2: Build the application
FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build

# Stage 3: Setup Production Dependencies
FROM base AS prod-deps
COPY package.json package-lock.json ./
RUN npm ci --omit=dev

# Stage 4: Final Runtime Image
FROM base AS runtime
COPY --from=prod-deps /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist

ENV HOST=0.0.0.0
ENV PORT=8080
EXPOSE 8080
CMD ["node", "./dist/server/entry.mjs"]