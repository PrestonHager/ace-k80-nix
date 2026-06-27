# Ace K80 NixOS Modules

Nix flake providing NixOS modules for **Dell PowerEdge R730xd "Ace"** (`192.168.5.5`) to run:

- **NVIDIA legacy 470** driver stack for Tesla **K80** (Kepler, compute 3.7)
- **Ollama** (local LLM API)
- **OpenClaw** (AI agent gateway + Control UI)
- **Caddy** reverse-proxy vhost for OpenClaw (integrates with existing Ace Caddy)

## K80 / driver reality check

| Topic | Detail |
|-------|--------|
| GPU | Tesla K80 = dual GK210, CUDA compute **3.7** (Kepler) |
| Last driver branch | NVIDIA **470.x** legacy (proprietary, built from NVIDIA source tarballs in nixpkgs) |
| "Open" NVIDIA modules | `hardware.nvidia.open = true` is **Turing+ only** — not K80 |
| nouveau | No usable CUDA compute for K80 inference workloads |
| CUDA | Last CUDA with Kepler: **11.4** era |
| Modern Ollama GPU | Targets CUDA 11.8+/12.x, **no sm_37** — expect **CPU inference** unless you pin an old Ollama build |
| Modern PyTorch | Dropped Kepler; use CUDA 11.4 + torch 1.x or CPU |

This flake enables `legacy_470` from nixpkgs (source-built kernel module + userspace). That is the correct stack to prepare **before** physically installing the K80.

## Quick integration (Ace `/etc/nixos`)

### 1. Add flake input

In `flake.nix`:

```nix
ace-k80-nix = {
  url = "github:PrestonHager/ace-k80-nix";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

### 2. Import module on Ace host

In `hosts/ace/default.nix`:

```nix
inputs.ace-k80-nix.nixosModules.default
```

Pass `inputs` via existing `specialArgs` in the Ace `nixosSystem` block (already present).

### 3. Enable options

```nix
ace.k80.nvidia.enable = true;
ace.k80.ollama.enable = true;
ace.k80.openclaw.enable = true;
ace.k80.reverseProxy.enable = true;
```

### 4. Rebuild

```bash
cd /etc/nixos
nix flake update ace-k80-nix
nixos-rebuild build --flake .#ace    # dry-run build
nixos-rebuild switch --flake .#ace
```

See [examples/ace-integration.nix](./examples/ace-integration.nix) for a full snippet.

## Modules

| Module | Purpose |
|--------|---------|
| `nvidia-k80` | `legacy_470`, graphics enable, nouveau blacklist, container toolkit |
| `ollama` | `services.ollama` on `127.0.0.1:11434`, model pull helper |
| `openclaw` | [Scout-DJ/openclaw-nix](https://github.com/Scout-DJ/openclaw-nix) gateway on port 18789 |
| `reverse-proxy` | Caddy vhost `openclaw.prestonhager.com` → gateway |

## After GPU is installed

1. Power off, install K80, ensure adequate PSU/airflow (300W TDP).
2. `nixos-rebuild switch --flake /etc/nixos#ace`
3. Verify: `lspci \| grep -i nvidia`, `nvidia-smi`, `lsmod \| grep nvidia`
4. Enable persistence: `nvidia-smi -pm 1`
5. Test Ollama: `curl http://127.0.0.1:11434/api/tags`
6. OpenClaw: `https://openclaw.prestonhager.com` (token in `/var/lib/openclaw/auth-token`)

## SSH to Ace

From Windows (Bitwarden SSH agent):

```powershell
ssh root@192.168.5.5
```

Key: **Internal SSH Root ED25519** in Bitwarden vault (loaded via `IdentityAgent //./pipe/openssh-ssh-agent`).

Add to `~/.ssh/config` for convenience:

```
Host ace 192.168.5.5
    HostName 192.168.5.5
    User root
```

## Local development

```bash
cd ~/Projects/ace-k80-nix
nix flake check
```

## License

MIT
