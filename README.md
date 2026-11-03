# Jenkins CI/CD & Test Automation Lab

**Python · Jenkins · Docker · Bash · Git · Linux**

A personal project focused on automating builds, test environments, and local deployments. A small containerized website serves as the system under test; the main work is the infrastructure around it.

The pipeline builds an image, verifies it in a temporary test environment, and deploys it only after the tests pass. If post-deployment verification fails, the deployment script attempts to restore the previous container.

## What this project demonstrates

| Area | Implementation |
|---|---|
| **Python test automation** | HTTP status and HTML content assertions using `unittest` and `urllib`; configurable target URL through an environment variable |
| **Jenkins CI/CD** | A version-controlled Declarative Pipeline with separate build/test and deployment stages; Git polling and failure-based stage gating |
| **Docker test environments** | Image builds, temporary test containers, port mapping, readiness checks, and automatic test-container cleanup |
| **Bash automation** | Build and execution scripts using functions, conditions, exit codes, and exit traps; deployment verification and rollback handling |
| **Linux and networking** | Work in Ubuntu on WSL 2; HTTP requests, TCP ports, loopback versus network addresses, and troubleshooting Windows-to-WSL connectivity |

## How it works

1. **Detect changes:** Jenkins polls GitHub and checks out new commits. The job uses `H/2 * * * *`, configured in the Jenkins UI.
2. **Build and test — CI:** `scripts/ci.sh` builds the image, starts a temporary website container on port **8081**, waits for readiness, and runs the Python test. An exit trap removes the temporary container. A failure blocks deployment.
3. **Deploy — CD:** `scripts/deploy.sh` resolves the image ID from `devops-lab:test`, preserves the existing demo container as a stopped backup, and starts the new version on port **8080**.
4. **Verify and recover:** The script checks the deployed website. Success removes the backup; failure triggers an attempt to restore it while keeping the Jenkins run marked as failed.

Python tests execute on the host and send HTTP requests to the application inside Docker. Concurrent builds of this Jenkins job are disabled because the scripts share container names and ports.

## Failure scenarios tested

| Scenario | Observed result |
|---|---|
| Changed the page heading without updating the expected value | CI failed, deployment was skipped, and the existing demo remained unchanged |
| Configured a nonexistent URL for deployment verification | CI passed, deployment verification failed, and rollback restored the previous container; version 3 was confirmed in the browser |
| Restored the correct verification URL | The pipeline completed successfully and version 4 appeared in the demo |

These exercises checked both failure detection and recovery behavior, beyond a successful build alone.

## Key files

- `Jenkinsfile` — pipeline definition using Jenkins' Groovy-based declarative syntax.
- `scripts/ci.sh` — image build, temporary test environment, readiness check, test execution, and cleanup.
- `scripts/deploy.sh` — local deployment, verification, and rollback.
- `tests/test_website.py` — one test with assertions for HTTP 200 and the expected page heading.
- `Dockerfile` and `index.html` — the packaged application under test.

<details>
<summary><strong>Setup and execution</strong></summary>

### Environment

Developed on Windows with Ubuntu 22.04 in WSL 2 and Docker Desktop integration. Jenkins runs in WSL using Java 21.

The Jenkins execution environment needs Git, Bash, Python 3, curl with `--retry-all-errors` support, and access to a running Docker engine. Ports 8080 and 8081 must be available to the project. Python tests use only the standard library.

### Run from the repository root

```bash
# Build and test in a temporary container.
bash scripts/ci.sh

# Deploy only after the CI script succeeds.
bash scripts/deploy.sh
```

Deployment replaces the container named `devops-web-v2`. Resolve any unrelated service using port 8080 before deploying. The demo is available at `http://localhost:8080`.

To test an existing server:

```bash
BASE_URL=http://localhost:8080 python3 tests/test_website.py
```

### Jenkins job

Create a **Pipeline** job with **Pipeline script from SCM**, select **Git**, and use:

- Repository: `https://github.com/seanrachmani/DevOps-Lab.git`
- Branch: `*/main`
- Script Path: `Jenkinsfile`
- Credentials if the repository requires authentication
- Poll SCM schedule: `H/2 * * * *`

Jenkins and Docker must remain running for automation to execute. Logs are available through each run's **Console Output**.

</details>

## Scope

This is a local software test-automation lab. It does not include physical hardware or hardware-in-the-loop testing.

- Tests cover availability and one expected heading; the Python HTTP server is used for demonstration.
- Deployment has brief downtime. Rollback handles containers, not database migrations, and does not automatically health-check the restored container.
- The shared image tag assumes no unrelated build changes it between CI and deployment. Unique image references per build would improve this.
