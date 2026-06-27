# Ollama on K80: current ollama-cuda targets CUDA 11.8+ / 12.x and Kepler (sm_37)
# is not supported by upstream Ollama GPU binaries. Default to CPU until the K80
# is installed; flip preferGpu when using a legacy Ollama build that still ships
# Kepler kernels (pre-2024) or accept CPU inference for small models.
{ config, lib, pkgs, ... }:

let
  cfg = config.ace.k80.ollama;
  nvidiaEnabled = config.ace.k80.nvidia.enable or false;
  useCuda = nvidiaEnabled && cfg.preferGpu;
in
{
  options.ace.k80.ollama = {
    enable = lib.mkEnableOption "Ollama LLM inference service on Ace";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:11434";
      description = "Listen address for the Ollama API.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "llama3.2:1b"
        "phi3:mini"
      ];
      description = "Models to pull on first start (small models suited to K80/CPU).";
    };

    preferGpu = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use ollama-cuda when true. Kepler (K80) is NOT supported by current
        Ollama CUDA builds — leave false unless you pin an older Ollama release.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      host = cfg.host;
      package = if useCuda then pkgs.ollama-cuda else pkgs.ollama-cpu;
      acceleration = if useCuda then "cuda" else false;
      environmentVariables = lib.mkIf useCuda {
        LD_LIBRARY_PATH = "/run/opengl-driver/lib";
        CUDA_VISIBLE_DEVICES = "0";
      };
    };

    systemd.services.ollama-pull-models = {
      description = "Pull default Ollama models after service is up";
      after = [ "ollama.service" ];
      wants = [ "ollama.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      path = [ pkgs.curl pkgs.jq ];
      script = ''
        for i in $(seq 1 60); do
          if curl -sf "http://${cfg.host}/api/tags" >/dev/null; then
            break
          fi
          sleep 2
        done
        ${lib.concatMapStringsSep "\n" (model: ''
          if ! curl -sf "http://${cfg.host}/api/tags" | jq -e '.models[]?.name | select(. == "${model}")' >/dev/null; then
            echo "Pulling ${model}..."
            curl -sf "http://${cfg.host}/api/pull" -d '{"name":"${model}"}' || true
          fi
        '') cfg.models}
      '';
    };
  };
}
