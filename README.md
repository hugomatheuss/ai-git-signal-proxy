# 🔐 Secure AI-to-Host Signaling System

[![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Docker](https://img.shields.io/badge/Docker-Compatible-2496ED?logo=docker&logoColor=white)](https://www.docker.com/)
[![Laravel](https://img.shields.io/badge/Laravel-Queue%20Support-FF2D20?logo=laravel&logoColor=white)](https://laravel.com/)
[![Security](https://img.shields.io/badge/Security-Sandboxed-green)](/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](/)

> **Bridge isolated AI agents to Linux host operations—securely, asynchronously, and without direct access.**

A battle-tested signaling framework that enables AI agents (like OpenClaw) operating inside sandboxed containers to safely trigger host-level operations. Designed for **remote DevOps productivity** while maintaining **zero-trust security principles**.

---

## 📋 Table of Contents

- [Why This Exists](#-why-this-exists)
- [Architecture](#-architecture)
- [Security Model](#-security-model)
- [Key Features](#-key-features)
- [Installation](#-installation)
- [Usage](#-usage)
- [Real-World Case Study](#-real-world-case-study)
- [Technical Stack](#-technical-stack)
- [Contributing](#-contributing)

---

## 🎯 Why This Exists

Modern AI coding assistants are powerful but operate in **sandboxed environments** for security. This creates a fundamental challenge: *How can an AI agent perform legitimate host operations (Git pushes, queue restarts) without compromising security?*

**Traditional approaches fail:**
- ❌ Granting SSH access exposes the host to arbitrary commands
- ❌ Running AI agents with root privileges is a critical vulnerability
- ❌ Direct Docker socket access enables container escape attacks

**This system solves it** by implementing an asynchronous signaling protocol where:
- ✅ The AI can only *request* pre-approved operations
- ✅ A trusted host-side executor validates and runs commands
- ✅ Complete audit trail of all operations
- ✅ Zero direct access to host systems

---

## 🏗 Architecture

### The Waiter/Chef Analogy (Asynchronous Signaling)

This system implements a **Waiter/Chef pattern** for secure command execution:

```
┌─────────────────────────────────────────────────────────────────┐
│                        SANDBOXED CONTAINER                       │
│  ┌───────────────┐                                               │
│  │   AI Agent    │  "I need to push to Git"                      │
│  │  (OpenClaw)   │ ─────────────────────────┐                    │
│  └───────────────┘                          │                    │
│         │                                   ▼                    │
│         │                          ┌──────────────┐              │
│         │                          │ git_push.flag│              │
│         │                          │   (main)     │              │
│         │                          └──────────────┘              │
│         │                                   │                    │
└─────────│───────────────────────────────────│────────────────────┘
          │           SHARED VOLUME           │
══════════│═══════════════════════════════════│════════════════════
          │                                   │
┌─────────│───────────────────────────────────│────────────────────┐
│         │              LINUX HOST           │                    │
│         │                                   ▼                    │
│         │    ┌─────────────────────────────────────────┐         │
│         │    │           CRON (every minute)           │         │
│         │    │      worker_manager.sh executor         │         │
│         │    │   ┌─────────────────────────────────┐   │         │
│         │    │   │  Detects flag → Validates →     │   │         │
│         │    │   │  Executes: git push origin main │   │         │
│         │    │   │  Logs → Removes flag            │   │         │
│         │    │   └─────────────────────────────────┘   │         │
│         │    └─────────────────────────────────────────┘         │
│         │                                                        │
└─────────────────────────────────────────────────────────────────┘
```

| Component | Role | Analogy |
|-----------|------|---------|
| **AI Agent** | Requester—writes `.flag` files with operation parameters | 🧑‍🍳 Waiter takes the order |
| **Shared Volume** | Communication channel—mounted in both container and host | 📝 Order ticket board |
| **worker_manager.sh** | Executor—processes flags and runs whitelisted commands | 👨‍🍳 Chef prepares the dish |
| **Crontab** | Scheduler—triggers the executor every minute | ⏰ Kitchen timer |

### Flow Sequence

1. **AI writes a flag file** to the shared volume (e.g., `git_push.flag` containing `main`)
2. **Cron triggers** `worker_manager.sh` every minute
3. **Executor detects** the flag, validates the operation
4. **Command executes** on the host with proper permissions
5. **Flag is removed** and operation is logged
6. **AI can read** the log or result files for confirmation

---

## 🔒 Security Model

### Defense in Depth

```
┌──────────────────────────────────────────────────────────┐
│                    SECURITY LAYERS                       │
├──────────────────────────────────────────────────────────┤
│  Layer 1: Container Sandboxing                           │
│  ├─ AI runs in isolated Docker container                 │
│  ├─ No network access to host services                   │
│  └─ Limited filesystem visibility                        │
├──────────────────────────────────────────────────────────┤
│  Layer 2: Command Whitelisting                           │
│  ├─ Only pre-defined operations can be triggered         │
│  ├─ Each flag maps to ONE specific command pattern       │
│  └─ No arbitrary command execution (except audit flag)   │
├──────────────────────────────────────────────────────────┤
│  Layer 3: Input Validation                               │
│  ├─ Flag contents are sanitized (xargs, cut)             │
│  ├─ Paths are constrained to REPO_DIR                    │
│  └─ Empty inputs have safe defaults                      │
├──────────────────────────────────────────────────────────┤
│  Layer 4: Audit Logging                                  │
│  ├─ Every operation is timestamped in commands.log       │
│  ├─ Full command output captured                         │
│  └─ Immutable record for forensic analysis               │
└──────────────────────────────────────────────────────────┘
```

### What the AI **Cannot** Do

| Action | Status | Reason |
|--------|--------|--------|
| SSH into host | 🚫 Blocked | No credentials or network path |
| Execute arbitrary binaries | 🚫 Blocked | Only whitelisted commands |
| Modify system files | 🚫 Blocked | Operations scoped to `$REPO_DIR` |
| Access other containers | 🚫 Blocked | Network isolation |
| Escalate privileges | 🚫 Blocked | Executor runs as unprivileged user |

### What the AI **Can** Do

| Action | Status | Implementation |
|--------|--------|----------------|
| Request Git operations | ✅ Allowed | Via `git_*.flag` files |
| Trigger queue restart | ✅ Allowed | Via `restart_queue.flag` |
| Check Git status | ✅ Allowed | Output to `git_status.txt` |
| Run diagnostic commands | ⚠️ Limited | Via `git_cmd.flag` (audited) |

---

## ✨ Key Features

### Git Flow Management

Complete Git workflow support through flag-based signaling:

```bash
# Stage changes
echo "." > /shared/git_add.flag

# Commit with message
echo "feat: add user authentication" > /shared/git_commit.flag

# Push to remote
echo "main" > /shared/git_push.flag

# Check repository status
touch /shared/git_status.flag
# Result appears in git_status.txt
```

### Laravel Queue Operations

Seamless integration with Laravel Horizon/Queue workers:

```bash
# Restart queue workers (e.g., after deployment)
touch /shared/restart_queue.flag
```

The `monitor_worker.sh` daemon provides:
- Automatic queue health monitoring
- Business-hours aware operation (09:00-18:00 BRT, weekdays)
- Configurable pending job thresholds
- Auto-restart on queue congestion

### Git Identity Configuration

Configure Git credentials remotely:

```bash
# Set Git user identity
echo "Hugo Developer | hugo@example.com" > /shared/git_set_config.flag
```

### Generic Command Fallback

For troubleshooting scenarios requiring flexibility:

```bash
# Execute a whitelisted diagnostic command
echo "git log --oneline -5" > /shared/git_cmd.flag
```

> ⚠️ **Note:** This flag is for emergency troubleshooting. All commands are logged and audited.

---

## 📦 Installation

### Prerequisites

- Linux host with Bash 5.0+
- Docker (for containerized AI agent)
- Git configured with SSH keys for remote operations
- Cron daemon running

### Quick Setup

**1. Clone the repository:**

```bash
git clone https://github.com/your-org/basis-scripts.git /home/hugo/basis/scripts
cd /home/hugo/basis/scripts
chmod +x *.sh
```

**2. Configure paths in `worker_manager.sh`:**

```bash
# Edit to match your environment
BASIS_DIR="/home/hugo/basis"
REPO_DIR="$BASIS_DIR/eventos"        # Your target repository
LOG_FILE="$BASIS_DIR/scripts/commands.log"
```

**3. Set up the Crontab trigger:**

```bash
crontab -e
```

Add the following line:

```cron
* * * * * /home/hugo/basis/scripts/worker_manager.sh >> /home/hugo/basis/scripts/cron.log 2>&1
```

**4. Create shared volume mount in Docker:**

```yaml
# docker-compose.yml
services:
  ai-agent:
    volumes:
      - /home/hugo/basis:/shared/basis
```

**5. Verify installation:**

```bash
# Create a test flag
touch /home/hugo/basis/git_status.flag

# Wait 1 minute, then check
cat /home/hugo/basis/git_status.txt
```

---

## 🚀 Usage

### From the AI Agent (Container Side)

```python
# Python example for AI agent
import pathlib

SHARED_DIR = pathlib.Path("/shared/basis")

def request_git_push(branch: str = "main"):
    """Request a Git push operation."""
    flag = SHARED_DIR / "git_push.flag"
    flag.write_text(branch)
    
def request_git_commit(message: str):
    """Request a Git commit."""
    flag = SHARED_DIR / "git_commit.flag"
    flag.write_text(message)

def check_git_status() -> str:
    """Request and read Git status."""
    flag = SHARED_DIR / "git_status.flag"
    flag.touch()
    # Wait for processing, then read result
    result = SHARED_DIR / "git_status.txt"
    return result.read_text() if result.exists() else "Pending..."
```

### Available Flags

| Flag File | Parameter | Action |
|-----------|-----------|--------|
| `git_status.flag` | None | Writes status to `git_status.txt` |
| `git_add.flag` | File path or `.` | Stages changes |
| `git_commit.flag` | Commit message | Creates commit |
| `git_push.flag` | Branch name (optional) | Pushes to remote |
| `git_check.flag` | None | Outputs Git config to `git_check.txt` |
| `git_set_config.flag` | `Name \| email` | Sets Git identity |
| `git_cmd.flag` | Command string | Executes arbitrary Git command |
| `restart_queue.flag` | None | Restarts Laravel queue workers |

---

## 📖 Real-World Case Study

### Resolving "Detached HEAD" and "Missing Upstream" Remotely

**Scenario:** During a remote debugging session via Telegram, an AI agent encountered a Git repository in a corrupted state—stuck in detached HEAD with no upstream configured.

**The Problem:**
```
fatal: You are not currently on a branch.
fatal: The current branch main has no upstream branch.
```

**Traditional Fix:** Would require SSH access, manual intervention, and potential security exposure.

**Solution via Signaling System:**

```bash
# Step 1: AI diagnosed the issue by requesting status
touch /shared/git_status.flag
# Read git_status.txt → Confirmed detached HEAD

# Step 2: AI requested branch checkout
echo "git checkout main" > /shared/git_cmd.flag

# Step 3: AI set upstream
echo "git branch --set-upstream-to=origin/main main" > /shared/git_cmd.flag

# Step 4: AI verified fix
touch /shared/git_status.flag
# Read git_status.txt → On branch main, tracking origin/main
```

**Result:** Complex Git recovery completed remotely without granting SSH access, with full audit trail, in under 5 minutes.

---

## 🛠 Technical Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Executor** | Bash 5.0+ | Cross-platform scripting, native Linux integration |
| **Scheduler** | Cron | Reliable, battle-tested job scheduling |
| **Containerization** | Docker | AI agent isolation, shared volume mounts |
| **Version Control** | Git | Repository operations |
| **Application Framework** | Laravel | Queue worker management, Artisan commands |
| **Monitoring** | Custom Bash | `health-check.sh`, `monitor_worker.sh` |
| **Audit** | Plain text logs | `commands.log` with timestamps |

### File Structure

```
scripts/
├── worker_manager.sh    # Main executor (Cron-triggered)
├── monitor_worker.sh    # Queue health monitor daemon
├── health-check.sh      # Docker/worker diagnostics
├── audit_log.sh         # Logging utility
├── commands.log         # Audit trail (generated)
└── README.md            # This file
```

---

## 🤝 Contributing

Contributions are welcome! Please ensure:

1. All new operations are whitelisted explicitly
2. Input validation is applied to flag contents
3. Operations are logged with timestamps
4. Security implications are documented

---

## 📄 License

MIT License - See [LICENSE](LICENSE) for details.

---

<p align="center">
  <strong>Built for secure AI-to-host operations in production environments.</strong><br>
  <sub>Because giving AI agents SSH access is not an option.</sub>
</p>
