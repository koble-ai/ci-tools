# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ci-tools is a multi-architecture (amd64/arm64) Docker base image providing a complete CI/CD and development environment. It bundles Python, Node.js, cloud CLIs, and build tools into a single image published to GitHub Container Registry (`ghcr.io/koble-ai/ci-tools`).

## Build Commands

```bash
# Local build (single platform)
docker build .

# Build with specific Node version
docker build --build-arg NODE_VERSION=20 .

# Multi-platform build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 .
```

There are no tests, linters, or package managers — the project is a single Dockerfile with a CI workflow.

## Build Arguments

| ARG | Default | Notes |
|-----|---------|-------|
| `NODE_VERSION` | 22 | CI matrix builds both 20 and 22 |
| `NPM_VERSION` | 11.3.0 | |
| `NVM_VERSION` | 0.40.2 | |
| `POETRY_VERSION` | 1.8.5 | |
| `TASKFILE_VERSION` | 3.2.2 | |
| `MODD_VERSION` | 0.5 | |
| `TARGETARCH` | auto | Set by buildx; controls amd64 vs arm64 download URLs |

## CI/CD Pipeline

`.github/workflows/docker-publish.yaml` — GitHub Actions workflow:
- **Triggers**: push to `main`, version tags (`v*.*.*`), PRs to `main`
- **Matrix**: builds Node 20 and Node 22 variants
- **Platforms**: linux/arm64 and linux/amd64 via QEMU + buildx
- **Registry**: `ghcr.io/koble-ai/ci-tools` with tags `node-20`, `node-22`, `latest`, and commit SHA
- **Signing**: cosign signs images on non-PR builds

## Architecture Notes

- **Base image**: `python:3.11.12-slim-bullseye` (Debian)
- **Node management**: NVM installs Node, then a symlink at `/root/.nvm/versions/node/current` is added to PATH so Node is available without sourcing NVM
- **Architecture-conditional installs**: AWS CLI, modd, and other tools use `TARGETARCH` to select the correct binary (amd64 vs arm64)
- **Verification**: The Dockerfile ends with version-check `RUN` commands (`poetry --version`, `aws --version`, etc.) that serve as build-time smoke tests
