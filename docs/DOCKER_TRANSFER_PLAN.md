# Docker Transfer Plan

This document lists everything required to package and ship the static employment onboarding page to a server using Docker.

## Repository structure that matters

| Path | Purpose |
| --- | --- |
| `Dockerfile` | Builds a slim `nginx:alpine` image with the HTML, fonts, and images baked in. |
| `docker/nginx/default.conf` | Nginx vhost that sets `employment-steps.html` as the index, enables caching, and tightens security headers. |
| `.dockerignore` | Keeps docs, git metadata, and local clutter out of the build context. |
| `compose.yaml` | Convenience file for local smoke tests or running the container on the server. |

## Prerequisites

- Docker Engine 24+ (or any version that understands BuildKit).
- Optional: Docker Compose plugin (v2+) for easier local testing.
- Access to the target server with permissions to run Docker commands.

## Build and verify locally

1. **Clean the repo** so that only intended files go into the image.
2. **Build the image** (tag however you prefer, e.g. the git SHA):
   ```bash
   docker build -t employment-page:$(git rev-parse --short HEAD) .
   ```
3. **Run smoke tests locally** (serves on http://localhost:7000 and on http://188.127.224.145:7000 when executed on the target server):
   ```bash
   docker compose up --build
   # or: docker run -p 7000:80 employment-page:<tag>
   ```
4. **Validate assets** by loading the page, switching the dropdown, and inspecting the browser console for 404s or CORS errors.
5. **Stop and clean up** when satisfied:
   ```bash
   docker compose down
   ```

## Transfer options

- **Push to a registry** (preferred): tag the image (`docker tag employment-page:<tag> registry.example.com/hr/employment-page:<tag>`) and `docker push` it. Pull the same tag on the server.
- **Offline transfer**: save the image locally and copy the tarball.
  ```bash
  docker save employment-page:<tag> -o employment-page_<tag>.tar
  scp employment-page_<tag>.tar user@server:/opt/employment-page/
  ```
  On the server run `docker load -i employment-page_<tag>.tar`.

## Server deployment

1. Copy the repository snapshot (or at minimum `compose.yaml`) to the server, or recreate the Compose service there.
2. Pull or load the image built in the previous step.
3. Start the container:
   ```bash
   docker compose up -d
   # or without Compose
   docker run -d --name employment-page -p 7000:80 employment-page:<tag>
   ```
4. Verify health:
   ```bash
   docker ps
   docker logs employment-page --tail 50
   curl -I http://localhost/employment-steps.html
   ```
5. Configure any reverse proxy / TLS termination outside of this container as needed.

## Updating

1. Make content changes.
2. Rebuild and tag a new image.
3. Push or transfer the new image.
4. Restart the container with `docker compose up -d --pull always --build`.

## Operational notes

- Assets are served read-only from the image; to change them you must rebuild.
- Fonts ship with long cache headers and permissive CORS for cross-origin usage.
- The health check hits `employment-steps.html`, ensuring both nginx and the file system are healthy.
