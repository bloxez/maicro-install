# mAIcro

mAIcro:G2A is your gateway to anything. Use rapid prototyping to explore your idea, manage data, integrate with external systems and use AI.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) must be installed and running

## Quick Start

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1 | iex
```

With custom data directory:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1))) -DataDir "D:\maicro-data"
```

### Windows (WSL)

If you use Windows Subsystem for Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
```

To store data on your Windows drive instead of WSL:

```bash
curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh -s -- /mnt/c/Users/YourUsername/maicro-data
```

> **Note:** Requires Docker Desktop with "Use the WSL 2 based engine" enabled in Settings → General.

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
```

With custom data directory:

```bash
curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh -s -- ~/my-maicro-data
```

## What Gets Installed

The script:
1. Pulls the mAIcro Docker image
2. Creates a data directory (default: `~/maicro-data` or `%USERPROFILE%\maicro-data`)
3. Starts the container with persistent storage

## Access

After installation:

| Service | URL |
|---------|-----|
| IDE | http://localhost:4321/ide |
| GraphQL Playground | http://localhost:4321/graphql |

## Managing mAIcro

```bash
# Stop
docker stop maicro

# Start
docker start maicro

# View logs
docker logs -f maicro

# Guided remove (asks for confirmation, optional data wipe)
~/maicro-data/remove.sh

# Remove completely
docker rm -f maicro
```

Windows PowerShell:

```powershell
powershell $env:USERPROFILE\maicro-data\remove.ps1
```

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `MAICRO_PORT` | Host port to expose mAIcro on | 4321 |
| `OPENROUTER_API_KEY` | API key for LLM operations (optional) | - |
| `MAICRO_DEFAULT_PROJECT` | Project name used in `project:key` authentication | maicro |
| `MAICRO_ADMIN_KEY` | Admin API key for this project | - |
| `ROOT_USER` | Root control-plane username for multi-project management (optional) | - |
| `ROOT_KEY` | Root control-plane key for multi-project management (optional) | - |

### Using Environment Variables

Set environment variables before running the installation script:

**Linux/macOS:**
```bash
export MAICRO_DEFAULT_PROJECT="myproject"
export MAICRO_ADMIN_KEY="my-secure-admin-key"
export MAICRO_PORT=8080

curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
```

**Windows (PowerShell):**
```powershell
$env:MAICRO_DEFAULT_PROJECT = "myproject"
$env:MAICRO_ADMIN_KEY = "my-secure-admin-key"
$env:MAICRO_PORT = "8080"

irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1 | iex
```

### Project Authentication

mAIcro uses `project:key` format for admin authentication:

- The `X-MAICRO-ADMIN-KEY` header expects: `<MAICRO_DEFAULT_PROJECT>:<MAICRO_ADMIN_KEY>`
- Example: `maicro:my-secure-admin-key`

### Root Control-Plane (Optional)

For multi-project deployments, set `ROOT_USER` and `ROOT_KEY` to manage multiple mAIcro instances:

```bash
export ROOT_USER="root_admin"
export ROOT_KEY="root-secure-key"
export MAICRO_DEFAULT_PROJECT="instance1"
export MAICRO_ADMIN_KEY="instance1-key"

curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
```

### Custom Port

macOS/Linux:
```bash
MAICRO_PORT=8080 curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
```

Windows:
```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1))) -Port 8080
```

## Data Persistence

All data is stored in your specified data directory using two mounts:
- `<DataDir> -> /app/runtime/userdata` (projects, config, chains, types)
- `<DataDir>/data -> /app/data` (PostgreSQL and service data)

This means PostgreSQL is persisted on the host under:
- Linux/macOS: `~/maicro-data/data/postgres` (or your custom `DataDir`)
- Windows: `%USERPROFILE%\maicro-data\data\postgres` (or your custom `DataDir`)

To reset, stop the container and delete the data directory.

## License

[PolyForm Noncommercial 1.0.0](LICENSE) - Free for non-commercial use.
