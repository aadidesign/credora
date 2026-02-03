# Credora Frontend - Production Dockerfile
# Build from repo root: docker build -f apps/web/Dockerfile .

FROM node:20-alpine AS base
WORKDIR /credora

# Install all deps and build
FROM base AS builder
COPY package.json ./
COPY packages/sdk ./packages/sdk
COPY apps/web ./apps/web
RUN cd packages/sdk && npm install && npm run build
RUN cd apps/web && npm install && npm run build

# Runner
FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /credora/apps/web/public ./public
COPY --from=builder --chown=nextjs:nodejs /credora/apps/web/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /credora/apps/web/.next/static ./.next/static

USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
