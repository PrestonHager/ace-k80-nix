# Ace AI stack: K80 NVIDIA (legacy 470), Ollama, OpenClaw, Caddy vhost.
# Managed by github:PrestonHager/ace-k80-nix
{ ... }:

{
  imports = [
    # Requires ace-k80-nix flake input in /etc/nixos/flake.nix
  ];

  ace.k80 = {
    nvidia.enable = true;
    ollama = {
      enable = true;
      preferGpu = false;
    };
    openclaw.enable = true;
    reverseProxy = {
      enable = true;
      domain = "openclaw.prestonhager.com";
    };
  };
}
