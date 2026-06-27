# Ace-specific defaults on top of Scout-DJ/openclaw-nix (imported in flake default module).
{ config, lib, ... }:

let
  cfg = config.ace.k80.openclaw;
in
{
  options.ace.k80.openclaw = {
    enable = lib.mkEnableOption "OpenClaw AI agent gateway";

    gatewayPort = lib.mkOption {
      type = lib.types.port;
      default = 18789;
      description = "Local OpenClaw gateway port (Control UI + API).";
    };

    authTokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Gateway auth token file. Auto-generated at /var/lib/openclaw/auth-token when null.";
    };

    modelProvider = lib.mkOption {
      type = lib.types.str;
      default = "ollama";
      description = "Default LLM provider (use ollama for local models on Ace).";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openclaw = {
      enable = true;
      gatewayPort = cfg.gatewayPort;
      domain = "";
      openFirewall = false;
      modelProvider = cfg.modelProvider;
      toolSecurity = "allowlist";
      toolAllowlist = [
        "read"
        "write"
        "web_search"
        "web_fetch"
        "message"
      ];
      extraGatewayConfig = {
        controlUi.allowedOrigins = [
          "https://openclaw.prestonhager.com"
          "http://127.0.0.1:${toString cfg.gatewayPort}"
        ];
      };
    };
  };
}
