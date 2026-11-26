{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.kaynix.programs.podman;
  podman = lib.getExe pkgs.podman;
in {
  options.kaynix.programs.podman = {
    enable = lib.mkEnableOption "the podman machine and the docker CLI socket";

    machineName = lib.mkOption {
      type = lib.types.str;
      default = "podman-machine-default";
      description = ''
        Name of the podman machine, as shown by `podman machine list`. It must
        already exist; create it once with `podman machine init`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      # The machine's ssh port changes on every start, so an ssh:// URL goes
      # stale after a reboot. The host-side API socket path depends only on
      # TMPDIR and the machine name.
      DOCKER_HOST = "unix://\${TMPDIR%/}/podman/${cfg.machineName}-api.sock";
      # Path of the same API socket inside the VM.
      DOCKER_SOCK = "/run/podman/podman.sock";
    };

    # Nothing else starts the VM after a login. The check keeps a rebuild or a
    # manual start from erroring. AbandonProcessGroup keeps launchd from
    # killing the vfkit and gvproxy children when this job exits.
    launchd.agents.podman-machine = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "/bin/sh"
          "-c"
          ''${podman} machine inspect ${lib.escapeShellArg cfg.machineName} --format '{{.State}}' | /usr/bin/grep -qx running || exec ${podman} machine start ${lib.escapeShellArg cfg.machineName}''
        ];
        RunAtLoad = true;
        AbandonProcessGroup = true;
        ProcessType = "Background";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/podman-machine.log";
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/podman-machine.log";
      };
    };
  };
}
