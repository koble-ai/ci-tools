# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ci-tools is a multi-architecture (amd64/arm64) set of Docker CI images, published as tag families of one image on GitHub Container Registry (`ghcr.io/koble-ai/ci-tools`). One multi-stage Dockerfile, three stages:

| Stage | Published as | What |
|-------|--------------|------|
| `node` | — (shared base) | Debian + Node/npm/yarn + build essentials |
| `playwright` | `node-N-playwright` | `node` + Playwright's chromium and its system deps at `/ms-playwright`, for e2e jobs |
| `ci-tools` (default) | `node-N`, `latest`, SHA | `node` + Python tooling, cloud CLIs, Docker, Terraform, kubectl |

## Build Commands

```bash
# Local build (single platform) — the full ci-tools image
docker build .

# The Playwright image
docker build --target playwright .

# Build with specific Node version
docker build --build-arg NODE_VERSION=20 .

# Multi-platform build (requires buildx)
docker buildx build --platform linux/amd64,linux/arm64 .
```

There are no tests, linters, or package managers — the project is a single Dockerfile with a CI workflow.

## Build Arguments

| ARG | Default | Notes |
|-----|---------|-------|
| `NODE_VERSION` | 22 | CI matrix builds 22, 24 and 26 |
| `NPM_VERSION` | 11.3.0 | |
| `NVM_VERSION` | 0.40.2 | |
| `POETRY_VERSION` | 1.8.5 | |
| `TERRAFORM_VERSION` | 1.15.8 | |
| `KUBECTL_VERSION` | 1.35 | Minor version only — selects the `pkgs.k8s.io` apt repo |
| `TASKFILE_VERSION` | 3.2.2 | |
| `MODD_VERSION` | 0.5 | |
| `PLAYWRIGHT_VERSION` | 1.64.1 | `playwright` stage. Keep in step with koble-platform's `@playwright/test` — a job on another version still works but downloads its own browser |
| `TARGETARCH` | auto | Set by buildx; controls amd64 vs arm64 download URLs |

## CI/CD Pipeline

`.github/workflows/docker-publish.yaml` — GitHub Actions workflow:
- **Triggers**: push to `main`, version tags (`v*.*.*`), PRs to `main`
- **Matrix**: Node 22, 24 and 26 × target (`ci-tools`, `playwright`)
- **Platforms**: linux/arm64 and linux/amd64 via QEMU + buildx
- **Registry**: `ghcr.io/koble-ai/ci-tools` with tags `node-22`, `node-24`, `node-26`, `latest`, and commit SHA (ci-tools), and `node-22-playwright`, `node-24-playwright`, `node-26-playwright`
- **Signing**: cosign signs images on non-PR builds

## Architecture Notes

- **Base image**: `python:3.11.12-slim-bookworm` (Debian 12)
- **Node management**: NVM installs Node, then a symlink at `/root/.nvm/versions/node/current` is added to PATH so Node is available without sourcing NVM
- **Architecture-conditional installs**: AWS CLI, modd, and other tools use `TARGETARCH` to select the correct binary (amd64 vs arm64)
- **Playwright**: `PLAYWRIGHT_BROWSERS_PATH=/ms-playwright` is set in the image, so a job's `playwright install chromium` (no `--with-deps`) is a no-op when versions match
- **Verification**: The `ci-tools` stage ends with version-check `RUN` commands (`poetry --version`, `aws --version`, etc.) that serve as build-time smoke tests
