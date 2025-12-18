# Coder Template: Local AI Platform (Kind + Podman)

This Coder template provides a fully-contained Kubernetes development environment running on **Kind** (Kubernetes in Docker/Podman). It is specifically optimised for **macOS** users running **Podman** and includes a bespoke **Ollama** integration for zero-cost, local AI-assisted coding.

## Features

* **Kubernetes-Native:** Runs on a local Kind cluster with pre-configured networking.
* **Local AI Integration:** Connects directly to **Ollama** on your Mac host.
* **Aider AI Chat:** Includes a pre-configured dashboard button to launch **Aider**, a powerful CLI AI pair programmer.
* **Cost Efficient:** Uses local hardware (GPU/CPU) via Ollama, removing the need for paid API tokens (e.g. OpenAI/Codex).

## Prerequisites

Before using this template, ensure your Mac host is configured to allow incoming connections from the Podman VM:

1. **Ollama Network Bind:**
Ollama must listen on all interfaces. Run the following in your Mac terminal:
```bash
launchctl setenv OLLAMA_HOST "0.0.0.0"

```

*Note: Restart the Ollama application after running this command.*
2. **Recommended Models:**
This template is configured to use **Granite-Code:20b** for high-quality logic. Ensure you have it pulled locally:
```bash
ollama pull granite-code:20b

```

## Infrastructure Overview

The environment utilises a multi-layer network bridge to allow the Coder workspace (inside a Pod container) to communicate with the macOS host.

| Component | Technology | Role |
| --- | --- | --- |
| **Runtime** | Podman | Container engine & VM management |
| **Orchestrator** | Kind | Local Kubernetes cluster (`v1.31.0`) |
| **AI Backend** | Ollama | Local LLM runner on macOS |
| **Bridge URL** | `host.containers.internal` | The DNS entry used to reach the Mac from the cluster |

## Usage

### 1. Launching the AI Chat

You can start an AI coding session in two ways:

* **Dashboard:** Click the **"AI Chat (Aider)"** button in your Coder workspace dashboard.
* **Terminal:** Run the custom command `coder-ai` from any terminal within the workspace.

### 2. Aider Workflow

Aider has direct access to your source code. You can ask it to:

* *"Create a new Python script that scrapes a website."*
* *"Refactor the error handling in main.go."*
* *"Write a unit test for the authentication module."*

## Configuration

The AI settings are managed via the `ollama-coder` module. If you wish to switch models (e.g. to `llama3.1:8b` for speed), update your `main.tf` variables:

```hcl
module "local_ai" {
  source       = "./modules/ollama-coder"
  agent_id     = coder_agent.main.id
  ollama_model = "llama3.1:8b" 
}

```

## Troubleshooting

* **Command Not Found:** If `coder-ai` is missing, ensure the `ollama_setup` script ran successfully during workspace startup.
* **Connection Refused:** Verify that your Mac firewall is not blocking port `11434` and that `OLLAMA_HOST` is set to `0.0.0.0`.
* **Performance:** If the AI is slow, ensure you aren't running other heavy GPU processes on your Mac, as Kind and Ollama share the host resources.

---