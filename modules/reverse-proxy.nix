# Caddy vhost for OpenClaw on Ace. Matches the existing ./nixos/caddy/*.nix
# pattern in PrestonHager/nixos-config (one file per service).
{ config, lib, ... }:

let
  cfg = config.ace.k80.reverseProxy;
  openclawCfg = config.ace.k80.openclaw;
in
{
  options.ace.k80.reverseProxy = {
    enable = lib.mkEnableOption "Caddy reverse proxy vhost for OpenClaw";

    domain = lib.mkOption {
      type = lib.types.str;
      default = "openclaw.prestonhager.com";
      description = "Public hostname for the OpenClaw Control UI.";
    };

    upstream = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:18789";
      description = "OpenClaw gateway upstream (host:port).";
    };
  };

  config = lib.mkIf (cfg.enable && openclawCfg.enable) {
    services.caddy.virtualHosts.${cfg.domain} = {
      extraConfig = ''
        encode gzip zstd

        @websocket {
          header Connection *Upgrade*
          header Upgrade websocket
        }

        reverse_proxy @websocket http://${cfg.upstream} {
          header_up Host {host}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }

        reverse_proxy http://${cfg.upstream} {
          header_up Host {host}
          header_up X-Real-IP {remote_host}
          header_up X-Forwarded-For {remote_host}
          header_up X-Forwarded-Proto {scheme}
        }
      '';
    };
  };
}
