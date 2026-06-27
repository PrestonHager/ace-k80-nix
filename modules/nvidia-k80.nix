# Tesla K80 (dual GK210, compute capability 3.7) requires the legacy 470.x
# proprietary NVIDIA driver branch. Modern "open GPU kernel modules" (Turing+)
# and nouveau do not provide usable CUDA compute on Kepler datacenter GPUs.
#
# nixpkgs builds legacy_470 from NVIDIA-published source tarballs (kernel
# module + userspace). This is the last supported stack for K80 on Linux.
{ config, lib, pkgs, ... }:

let
  cfg = config.ace.k80.nvidia;
in
{
  options.ace.k80.nvidia = {
    enable = lib.mkEnableOption "NVIDIA legacy 470 driver stack for Tesla K80 (Kepler)";

    enableContainerToolkit = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install nvidia-container-toolkit for GPU containers (Podman/Docker).";
    };

    powerMizer = lib.mkOption {
      type = lib.types.enum [ "auto" "prefer-max" "adaptive" "prefer-min" ];
      default = "prefer-max";
      description = "NVIDIA PowerMizer mode for datacenter inference workloads.";
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.config.allowUnfree = true;
    nixpkgs.config.nvidia.acceptLicense = true;

    # Expose libcuda.so and GL/Vulkan userspace under /run/opengl-driver
    hardware.graphics = {
      enable = true;
      enable32Bit = lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 true;
    };

    services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];

    hardware.nvidia = {
      modesetting.enable = true;
      nvidiaSettings = true;
      powerManagement.enable = false;
      open = false;
      package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
    };

    boot.blacklistedKernelModules = [ "nouveau" ];
    boot.kernelModules = [ "nvidia" ];
    boot.initrd.kernelModules = [ "nvidia" ];
    boot.extraModulePackages = [
      config.boot.kernelPackages.nvidiaPackages.legacy_470
    ];

    environment.systemPackages = with pkgs; [
      pciutils
      nvidia-settings
    ];

  } // lib.optionalAttrs cfg.enableContainerToolkit {
    hardware.nvidia-container-toolkit.enable = lib.mkDefault true;
  } // {
    environment.etc."nvidia-k80-powerd".text = ''
      # Applied after GPU install via nvidia-settings or nvidia-smi -pm 1
      # PowerMizer: ${cfg.powerMizer}
    '';
  };
}
