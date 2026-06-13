# ffreis-workflows-container

Reusable GitHub Actions workflow library for container image (Docker/Podman) operations in the ffreis fleet.

All workflows use `on: workflow_call` and should be consumed from other repositories by pinning to a specific commit SHA.

```yaml
uses: FelipeFuhr/ffreis-workflows-container/.github/workflows/container-build.yml@<sha> # vX.Y.Z
```

## Workflows

| Workflow file | Purpose | Key inputs |
|---|---|---|
| `container-build.yml` | Build a container image (podman/docker) | `image`, `containerfile`, `context`, `build-args`, `push` |
| `container-lint.yml` | Hadolint Dockerfile/Containerfile linting | `containerfile`, `working-directory` |
| `container-scan-grype.yml` | Grype CVE scan against image or filesystem | `image`, `working-directory`, `upload-sarif` |
| `container-scan-trivy.yml` | Trivy vulnerability scan | `image`, `working-directory`, `upload-sarif` |
| `container-scan-snyk.yml` | Snyk container vulnerability scan | `image`; secret `SNYK_TOKEN` |
| `container-sbom.yml` | Generate SBOM (Syft) and attach to image | `image`, `working-directory` |
| `container-sign.yml` | Cosign keyless image signing | `image`, `digest` |
