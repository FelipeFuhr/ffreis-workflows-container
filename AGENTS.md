# Agent Context

**This repo:** `ffreis-workflows-container` — reusable GitHub Actions workflow library
for container security and supply chain. Covers Trivy, Grype, Snyk, Syft SBOM,
cosign keyless signing, and Hadolint. Language-agnostic.

## Non-obvious rules (read before changing anything)

1. **`devops-*.yml` workflows are exempt from `self-test.yml`** — repo-maintenance
   workflows (stale, labeling, scorecard) can't be tested against `examples/hello/`.
   All `container-*.yml` workflows must appear in `self-test.yml`.

2. **Two workflows need explicit gates in `self-test.yml`:**
   - `container-sign` — requires `id-token: write` + a pushed image; gate to main push only.
   - `container-scan-snyk` — requires `SNYK_TOKEN`; gate with fork PR check.

3. **Trivy scan pattern: never fail-fast mid-loop.** Produce SARIF/JSON/status files
   for all images first, then check all status files in a deferred step. This ensures
   artifacts upload even when vulnerabilities are found.

4. **cosign keyless signing** — no `COSIGN_KEY` secret; OIDC only. Callers must grant
   `id-token: write`.

5. **Shell injection prevention enforced by Semgrep.** Route all inputs through `env:`.

6. **Action SHAs managed by Renovate.** Do not edit manually.

## Structure

```
.github/workflows/
  container-*.yml   ← reusable library
  devops-*.yml      ← repo-maintenance (exempt from self-test)
  ci.yml, release.yml
examples/hello/     ← minimal Containerfile
.hadolint.yaml      ← Hadolint config
```

## Build/test

```bash
make setup              # lefthook + gitleaks + hadolint
make lint               # hadolint on examples/hello/Containerfile
make secrets-scan-staged
```

## Keeping this file current

- **If you discover a fact not reflected here:** add it before finishing your task.
- **If something here is wrong or outdated:** correct it in the same commit as the code change.
- **If you rename a file, command, or concept referenced here:** update the reference.
