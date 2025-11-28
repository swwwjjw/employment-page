FROM nginx:1.27.2-alpine

LABEL org.opencontainers.image.title="employment-page" \
      org.opencontainers.image.description="Static employment onboarding flow served by nginx" \
      org.opencontainers.image.source="https://example.com/employment-page" \
      org.opencontainers.image.licenses="MIT"

# Quiet down default startup noise
ENV NGINX_ENTRYPOINT_QUIET_LOGS=1

# Copy custom nginx configuration
COPY docker/nginx/default.conf /etc/nginx/conf.d/default.conf

# Copy static assets
COPY employment-steps.html /usr/share/nginx/html/employment-steps.html
COPY logotip.png /usr/share/nginx/html/logotip.png
COPY Montserrat /usr/share/nginx/html/Montserrat

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --spider http://127.0.0.1/employment-steps.html || exit 1
