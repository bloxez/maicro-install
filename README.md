# mAIcro

GraphQL-first rapid prototyping platform with embedded IDE, chain operations engine, and comprehensive security testing.

## Quick Start

### macOS / Linux

```bash
curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh
```

With custom data directory:

```bash
curl -fsSL https://raw.githubusercontent.com/bloxez/maicro-install/main/run.sh | sh -s -- ~/my-maicro-data
```

### Windows (PowerShell)

```powershell
irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1 | iex
```

With custom data directory:

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/bloxez/maicro-install/main/run.ps1))) -DataDir "D:\maicro-data"
```

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop) must be installed and running

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

# Remove completely
docker rm -f maicro
```

## Configuration

### Environment Variables

| Variable | Description |
|----------|-------------|
| `OPENROUTER_API_KEY` | API key for LLM operations |
| `MAICRO_PORT` | Host port (default: 4321) |

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

All data is stored in your specified data directory:
- Database files
- Project configurations  
- User chains and types

To reset, stop the container and delete the data directory.

## License

[PolyForm Noncommercial 1.0.0](LICENSE) - Free for non-commercial use.
