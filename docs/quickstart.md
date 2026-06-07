# Quickstart Guide

Get Hermes-Box running in 5 simple steps. This guide is written for users who are **not** necessarily developers — you only need basic terminal and command-line skills.

---

## Prerequisites

Before you start, make sure you have:

- **A Linux computer** (Ubuntu 22.04+ or Debian 12+ recommended)
- **Docker** and **Docker Compose** installed
  - [Install Docker](https://docs.docker.com/engine/install/) (the `docker compose` command, v2+)
- **Git** (for cloning the repository)
  - `sudo apt install git` on Ubuntu/Debian
- **At least 16 GB of RAM** (for running models locally)
- **50+ GB of free disk space** (for model weights)
- **(Optional) An NVIDIA GPU** with 8+ GB VRAM for faster inference

> **Don't have a GPU?** No problem — Hermes-Box can run on CPU only, just more slowly.

---

## Step 1: Clone the Repository

Open a terminal and run:

```bash
git clone https://github.com/nousresearch/hermes-box.git
cd hermes-box
```

This downloads the project to a folder called `hermes-box` on your machine.

---

## Step 2: Configure the Basics

Create an environment file to store your secrets. This file is automatically ignored by Git, so your keys stay safe.

```bash
cp .env.example .env
```

Open `.env` in any text editor (e.g., `nano .env`) and set these values:

| Variable | Required? | What it does |
|----------|-----------|--------------|
| `WEBUI_SECRET_KEY` | **Yes** | A random string to secure your web UI. Run `openssl rand -hex 32` in the terminal to generate one. |
| `TELEGRAM_BOT_TOKEN` | No | Your Telegram bot token (if you want Telegram access). Get one from [@BotFather](https://t.me/botfather). |
| `OPENAI_API_KEY` | No | An API key if you want to use OpenAI models alongside local ones. |
| `TS_AUTHKEY` | No | Your Tailscale auth key (if you want VPN access). |

A minimal `.env` file can look like this:

```
WEBUI_SECRET_KEY=a3f8b2c1d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0
```

---

## Step 3: Choose Your Profile and Start

Hermes-Box has three profiles (think of them as "modes" depending on your hardware):

| Profile | What runs | Best for |
|---------|-----------|----------|
| `basic` | Web UI, Hermes, Tailscale VPN | No GPU, CPU-only setups |
| `gpu` | Basic + Ollama (GPU) + Guardrails | You have an NVIDIA GPU |
| `full` | Everything + Dashboard | Production or demo setups |

### If you have a GPU:

```bash
docker compose --profile gpu up -d
```

### If you don't have a GPU:

```bash
docker compose --profile basic up -d
```

This command downloads all the container images and starts the services in the background. The first run will take longer because Docker needs to download the images.

---

## Step 4: Download a Model

Once everything is running, pull an AI model so you can chat with it.

```bash
# List running containers to confirm everything is up
docker ps

# Download a model (Llama 3.1 8B is a good starter — ~4.7 GB)
docker exec -it hermes-ollama ollama pull llama3.1:8b

# For smaller models (faster, less memory):
# docker exec -it hermes-ollama ollama pull llama3.2:3b

# For larger, smarter models (needs good GPU):
# docker exec -it hermes-ollama ollama pull llama3.1:70b
```

You can find more models on the [Ollama library](https://ollama.com/library).

---

## Step 5: Start Using It

### Open the Web UI

Open your browser and go to:

```
http://localhost:3000
```

- Create an admin account on first visit
- Select the model you downloaded from the dropdown
- Start chatting!

### Access via VPN (if configured)

If you set up Tailscale, you can reach your Hermes-Box from anywhere:

```
http://hermes-box:3000
```

### Talk to the Hermes Agent

The agent API is available at:

```
http://localhost:8787
```

---

## What to Do Next

- **Explore models** — Visit [ollama.com/library](https://ollama.com/library) to find models for coding, creative writing, or analysis
- **Customize settings** — Edit `config/hermes.yaml` to configure agent behavior
- **Add users** — Open WebUI supports multi-user accounts from the admin panel
- **Set up Telegram** — Create a bot with [@BotFather](https://t.me/botfather), get the token, and add it to your `.env`
- **Secure your setup** — See the [Deployment Guide](deployment.md) for production hardening

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `docker: command not found` | Install Docker: `curl -fsSL https://get.docker.com | sh` |
| Permission denied on Docker | Add your user to the docker group: `sudo usermod -aG docker $USER && newgrp docker` |
| "no space left on device" | Clean up old images: `docker system prune -a` |
| Web UI shows "connection refused" | Wait for Ollama to finish downloading: check with `docker logs hermes-ollama -f` |
| GPU not detected in Ollama | Verify NVIDIA drivers: `nvidia-smi`. Install [nvidia-container-toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html) |
| Can't access from another computer | Set up Tailscale VPN (see deployment guide) |
