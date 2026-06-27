{
  description = "NixOS modules for Dell PowerEdge Ace: Tesla K80 (Kepler) NVIDIA legacy drivers, Ollama, OpenClaw, and Caddy reverse proxy";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    openclaw-nix = {
      url = "github:Scout-DJ/openclaw-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, openclaw-nix, ... }@inputs: {
    overlays.default = openclaw-nix.overlays.default;

    nixosModules =
      let
        inherit openclaw-nix;
      in
      {
        default = { lib, ... }: {
          imports = [
            openclaw-nix.nixosModules.default
            self.nixosModules.nvidia-k80
            self.nixosModules.ollama
            self.nixosModules.openclaw
            self.nixosModules.reverse-proxy
          ];

          nixpkgs.overlays = lib.mkAfter [
            openclaw-nix.overlays.default
          ];
        };

      nvidia-k80 = ./modules/nvidia-k80.nix;
      ollama = ./modules/ollama.nix;
      openclaw = ./modules/openclaw.nix;
      reverse-proxy = ./modules/reverse-proxy.nix;
    };

    packages.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.writeText "ace-k80-nix" "Ace K80 NixOS modules";
  };
}
