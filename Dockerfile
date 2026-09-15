# syntax = docker/dockerfile:1

ARG NODE_VERSION=24
FROM node:${NODE_VERSION}-slim AS base
WORKDIR /app
ENV NODE_ENV="production" \
    NEXT_TELEMETRY_DISABLED=1
RUN npm install -g pnpm@11.5.0

# ---- build ----
FROM base AS build
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential node-gyp pkg-config python-is-python3

# pnpm-workspace.yaml holds the allowBuilds list; without it pnpm fails with ERR_PNPM_IGNORED_BUILDS
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --prod=false

COPY . .

# NEXT_PUBLIC_* values are baked in at build time, so they must be passed as build args
ARG NEXT_PUBLIC_FIREBASE_API_KEY
ARG NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN
ARG NEXT_PUBLIC_FIREBASE_PROJECT_ID
ARG NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET
ARG NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID
ARG NEXT_PUBLIC_FIREBASE_APP_ID
ARG NEXT_PUBLIC_FIREBASE_MEASUREMENT_ID
ARG NEXT_PUBLIC_APP_BASE_URL
ARG NEXT_PUBLIC_APP_NAME
ARG NEXT_PUBLIC_SKILLS_API_URL
ARG NEXT_PUBLIC_LCW_DEEP_LINK
RUN pnpm run build

# ---- runtime (Next standalone output) ----
FROM base
COPY --from=build /app/.next/standalone ./
COPY --from=build /app/.next/static ./.next/static
COPY --from=build /app/public ./public
ENV PORT=3000 HOSTNAME=0.0.0.0
EXPOSE 3000
CMD ["node", "server.js"]
