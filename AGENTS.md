# ffreis-workflows-container — contribution guide

This repository is a language-agnostic library of reusable GitHub Actions workflows for
container security and supply chain operations. It covers image scanning (Grype, Trivy,
Snyk), SBOM generation (Syft), image signing (cosign), and Dockerfile linting (Hadolint).

The `examples/hello/` directory is the canonical test subject used by `self-test.yml`.

---

## Rules for adding or modifying workflows

### 1. Every new workflow must be in `self-test.yml`

Every file added to `.github/workflows/` (except `self-test.yml` itself) **must** have a
corresponding job in `self-test.yml` that calls it against `examples/hello/`.

A workflow that is not exercised by `self-test.yml` is unverified. It will not be merged.

**Exception — repo-maintenance (`devops-*`) workflows**: Workflows prefixed with `devops-`
(e.g. `devops-automation.yml`, `devops-pr-hygiene.yml`, `devops-security.yml`) are
repo-maintenance workflows that manage the repository itself (stale issue handling, PR
labeling, scorecard, secret scanning, etc.). They are not container workflows and cannot
be meaningfully exercised against `examples/hello/`. These files are **exempt** from the
self-test requirement.

**Two jobs in this repo require explicit job-level gates in `self-test.yml`:**

- **`container-sign`** — requires a pushed image and `id-token: write` OIDC permissions.
  Gated to run only on main branch push events:

```yaml
sign:
  needs: [build]
  if: github.event_name == 'push' && github.ref == 'refs/heads/main'
  uses: ./.github/workflows/container-sign.yml
  with:
    image_ref: ${{ needs.build.outputs.image_ref }}
```

- **`container-scan-snyk`** — requires `SNYK_TOKEN`. Gated to skip on fork PRs:

```yaml
scan-snyk:
  if: github.event_name != 'pull_request' || github.event.pull_request.head.repo.fork == false
  uses: ./.github/workflows/container-scan-snyk.yml
  ...
  secrets:
    SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

**Handling required secrets** — declare secrets as `required: true` in the workflow. Gate
the job in `self-test.yml` at the job level (see above). This produces an explicit "Skipped"
status on fork PRs rather than a silent success.

---

### 2. No silent failures

A step that fails silently is worse than one that fails loudly.

- If a required tool is missing → `exit 1` with a clear install message pointing to docs.
- If a required secret is absent and the workflow cannot meaningfully skip → fail the job.
- Never print a warning and continue when the operation did not run.

`make secrets-scan-staged` and `make setup` in the `Makefile` are the reference
implementation of the correct error pattern.

---

### 3. No shell injection — inputs go through `env:`

Never interpolate `${{ inputs.* }}`, `${{ github.* }}`, or any expression directly inside a
`run:` step. Always route through an `env:` variable. Semgrep runs in CI and will block PRs
that violate this rule (`run-shell-injection`).

```yaml
# BAD — Semgrep blocks this
run: grype "${{ inputs.image-name }}" --fail-on "${{ inputs.severity }}"

# GOOD
env:
  IMAGE_NAME: ${{ inputs.image-name }}
  SEVERITY: ${{ inputs.severity }}
run: grype "$IMAGE_NAME" --fail-on "$SEVERITY"
```

---

### 4. Least-privilege secrets — never `secrets: inherit`

Pass only the secrets a workflow explicitly declares, both in `self-test.yml` and in any
downstream consumer:

```yaml
# BAD
uses: ./.github/workflows/container-scan-snyk.yml
secrets: inherit

# GOOD
uses: ./.github/workflows/container-scan-snyk.yml
secrets:
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
```

---

### 5. `secrets.*` is forbidden in `if:` conditions

GitHub Actions forbids `secrets.*` in `if:` expressions within `workflow_call` reusable
workflows. Use job-level `if:` gating in `self-test.yml` instead (see the pattern in rule 1).

---

### 6. Pin third-party actions to a full commit SHA

```yaml
# BAD
uses: actions/checkout@v4

# GOOD
uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683 # v4
```

When Semgrep flags a SHA as a false-positive secret, suppress it inline:

```yaml
uses: some-action@<sha> # nosemgrep: <rule-id>
```

---

### Notes on scan workflows

- **Trivy**: never fail-fast mid-loop. Produce SARIF + JSON + gate-status files, then check
  all status files in a final deferred step. This ensures artifacts are uploaded even when
  vulnerabilities are found.
- **Grype**: install via pinned install-script commit SHA. Scan OCI archive format. Upload
  SARIF via GitHub API, not via the `upload-sarif` action (allows custom `tool_name` per
  image).
- **Snyk**: `SNYK_TOKEN` is `required: true`. Gate the job in `self-test.yml` at the job level.
- **cosign**: uses keyless OIDC signing — no `COSIGN_KEY` secret required. The calling
  workflow must grant `id-token: write`.

---

## Makefile targets

| Target | Purpose |
|---|---|
| `make setup` | Bootstrap lefthook + verify all required dev tools are installed |
| `make lint` | Lint `examples/hello/Containerfile` with hadolint (fails if hadolint not installed) |
| `make secrets-scan-staged` | Scan staged files with gitleaks (fails if gitleaks not installed) |
| `make hooks` | Install git hooks via lefthook |
