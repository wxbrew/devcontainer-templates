# devcontainer-templates

Reusable Dev Container templates published to GHCR and consumable via the VS Code Dev Containers extension or the `devcontainer` CLI.

## Templates

| Template | Description | Use case |
|---|---|---|
| [java-gradle-mvn](src/java-gradle-mvn/) | Java 25 + Gradle + Maven + GitHub CLI | **CI/CD pipelines and build agents** — lean image, no Node.js or Claude Code |
| [java-gradle-mvn-claude](src/java-gradle-mvn-claude/) | Java 25 + Gradle + Maven + GitHub CLI + Claude Code | **Local AI-assisted development** — includes Node.js and Claude Code CLI |

### Choosing a template

- **`java-gradle-mvn` (baseline):** Use this whenever you need a repeatable build environment without internet access to Anthropic or without a Claude subscription. This image is pre-built and published automatically on every change to its source files.
- **`java-gradle-mvn-claude` (AI variant):** Use this for interactive development where you want Claude Code available inside the container. This template is published to GHCR but its image is not pre-built by CI — build it locally or in a dev environment where Claude credentials are available.

---

## Workflows

| Workflow | Trigger | What it does |
|---|---|---|
| `release.yaml` — Release Dev Container Templates | Manual (`workflow_dispatch` on `main`) | Publishes **all** templates to GHCR and opens a PR with auto-generated docs |
| `release-images.yaml` — Release Dev Container Images | Manual **or** push to `main` touching `src/java-gradle-mvn/**` | Builds and pushes the **lean baseline image** (`java-gradle-mvn`) to GHCR |
| `test-pr.yaml` — CI - Test Templates | Pull request | Smoke-tests changed templates; Claude variant only runs when its files change |

---

## Maintenance Guide

### Updating tool versions

All version pins live in one file per template:
[src/java-gradle-mvn-claude/.devcontainer/devcontainer.json](src/java-gradle-mvn-claude/.devcontainer/devcontainer.json)

#### Java version

Change the `"version"` field under the `java` feature:

```jsonc
"ghcr.io/devcontainers/features/java:1": {
  "version": "25",   // ← bump this (e.g. "26")
  ...
}
```

> **Note:** Gradle compatibility matters here. Check the [Gradle compatibility matrix](https://docs.gradle.org/current/userguide/compatibility.html) before bumping Java. The minimum Gradle version that runs its own daemon on JDK 25 is 9.1.0.

#### Gradle version

```jsonc
"ghcr.io/devcontainers/features/java:1": {
  ...
  "installGradle": true,
  "gradleVersion": "9.1.0",   // ← bump this
  ...
}
```

#### Maven version

```jsonc
"ghcr.io/devcontainers/features/java:1": {
  ...
  "installMaven": true,
  "mavenVersion": "3.9.15",   // ← bump this
  ...
}
```

#### Node.js version

Node is a prerequisite for Claude Code. `"lts"` tracks the active LTS automatically. Pin to a specific version only if you need determinism:

```jsonc
"ghcr.io/devcontainers/features/node:1": {
  "version": "lts"   // ← "lts" | "latest" | "22" | etc.
}
```

#### JDK distribution

`"jdkDistro": "open"` uses Oracle's GPL OpenJDK builds (the same as jdk.java.net). Alternatives:

| Value | Distribution |
|---|---|
| `"open"` | Oracle OpenJDK (default) |
| `"ms"` | Microsoft Build of OpenJDK |
| `"tem"` | Eclipse Temurin (Adoptium) |

---

### Adding or changing devcontainer features

Features are listed in the `"features"` block. The full catalogue is at [containers.dev/features](https://containers.dev/features).

**Add a feature:**

```jsonc
"features": {
  // existing features ...
  "ghcr.io/devcontainers/features/docker-in-docker:2": {}
}
```

**Pin a feature to a specific major version** by changing the `:1` suffix (e.g. `:2`). Omitting the tag means "latest major".

**Remove a feature:** delete its entry. Remember to remove any related VS Code extensions or `postCreateCommand` checks that depend on it.

---

### Adding template options (parameterisation)

Options let users override values at `devcontainer use` time (e.g. choosing a Java version). They live in two places:

**1. `devcontainer-template.json`** — declares the option and its default:

```jsonc
{
  "id": "java-gradle-mvn-claude",
  "options": {
    "javaVersion": {
      "type": "string",
      "default": "25",
      "description": "JDK version to install"
    }
  }
}
```

**2. `.devcontainer/devcontainer.json`** — references the option with `${templateOption:optionName}`:

```jsonc
"ghcr.io/devcontainers/features/java:1": {
  "version": "${templateOption:javaVersion}",
  ...
}
```

The build script in `.github/actions/smoke-test/build.sh` substitutes option defaults at test time, so every option **must** have a non-empty `default` or the CI build will fail.

**Supported option types:** `"string"` and `"boolean"`.

For boolean options:

```jsonc
"installAnt": {
  "type": "boolean",
  "default": "false",
  "description": "Also install Apache Ant"
}
```

---

### Updating VS Code extensions

Extensions are listed in `customizations.vscode.extensions` in `.devcontainer/devcontainer.json`. Use the extension's full identifier (`publisher.name`), visible on the VS Code Marketplace URL or in the extension's sidebar panel.

```jsonc
"extensions": [
  "vscjava.vscode-java-pack",
  // add or remove entries here
]
```

---

### Adding a new template

1. Create `src/<template-id>/devcontainer-template.json` and `src/<template-id>/.devcontainer/devcontainer.json`.
2. Add a test script at `test/<template-id>/test.sh` (use the existing one as a reference).
3. Register the template in `.github/workflows/test-pr.yaml` under the appropriate `detect-changes` filter:
   - For a **lean/baseline** template (no AI tooling), add it to the `baseline_templates` filter list so it is included in the `test-baseline` job:

```yaml
filters: |
  java-gradle-mvn: ./**/java-gradle-mvn/**
  your-new-template: ./**/your-new-template/**   # ← add this line
```

   - For an **AI-enabled** template, follow the pattern in `test-claude` and add a dedicated conditional job.
4. If the template warrants a pre-built image, add it to `.github/workflows/release-images.yaml`.
5. Add a row to the table at the top of this README.

---

## Publishing

Templates are published to GHCR automatically when the **Release Dev Container Templates** workflow is run manually from the Actions tab (`workflow_dispatch` on `main`). The workflow:

1. Pushes each template under `src/` to `ghcr.io/<org>/devcontainer-templates/<template-id>`.
2. Auto-generates a `README.md` inside each `src/<template-id>/` directory and opens a PR to commit it.

The **Release Dev Container Images** workflow builds and pushes pre-built images to GHCR. It runs automatically when baseline template files change on `main`, and can also be triggered manually.

To consume a published template:

```bash
# Lean baseline (recommended for pipelines/build agents):
devcontainer templates apply \
  --template-id ghcr.io/<your-github-org>/devcontainer-templates/java-gradle-mvn \
  --workspace-folder .

# AI-assisted development variant:
devcontainer templates apply \
  --template-id ghcr.io/<your-github-org>/devcontainer-templates/java-gradle-mvn-claude \
  --workspace-folder .
```

Or select it in the VS Code command palette: **Dev Containers: Add Dev Container Configuration Files**.

---

## CI

Pull requests trigger `.github/workflows/test-pr.yaml`, which detects which templates changed, spins up a real container with `@devcontainers/cli`, and runs `test/<template-id>/test.sh` inside it.

- **Baseline templates** are tested on every PR that touches their files (fast, no Node/Claude pull).
- **Claude variant** is only tested when `java-gradle-mvn-claude` files change, since it pulls Node.js and the Claude Code feature.

To run the smoke test locally:

```bash
npm install -g @devcontainers/cli
.github/actions/smoke-test/build.sh java-gradle-mvn
.github/actions/smoke-test/test.sh  java-gradle-mvn
```
