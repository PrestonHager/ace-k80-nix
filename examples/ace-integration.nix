# Example integration for PrestonHager/nixos-config on Ace (192.168.5.5).
#
# 1) Add to /etc/nixos/flake.nix inputs:
#
#   ace-k80-nix = {
#     url = "github:PrestonHager/ace-k80-nix";
#     inputs.nixpkgs.follows = "nixpkgs";
#   };
#
# 2) Add to hosts/ace/default.nix imports:
#
#   inputs.ace-k80-nix.nixosModules.default
#
# 3) Enable services (append to hosts/ace/default.nix or ace/ai.nix):
#
#   ace.k80.nvidia.enable = true;
#   ace.k80.ollama.enable = true;
#   ace.k80.openclaw.enable = true;
#   ace.k80.reverseProxy.enable = true;
#
# 4) Add Caddy import in nixos/caddy/default.nix (optional if using ace.k80.reverseProxy):
#    The reverse-proxy module adds the vhost directly via services.caddy.virtualHosts.
#
# 5) Rebuild:
#   cd /etc/nixos && nix flake update ace-k80-nix && nixos-rebuild switch --flake .#ace

{ ... }:

{
  imports = [
    # After adding ace-k80-nix flake input:
    # inputs.ace-k80-nix.nixosModules.default
  ];

  ace.k80 = {
    nvidia.enable = true;
    ollama = {
      enable = true;
      preferGpu = false; # set true only with legacy Ollama + K80 installed
    };
    openclaw.enable = true;
    reverseProxy = {
      enable = true;
      domain = "openclaw.prestonhager.com";
    };
  };
}
