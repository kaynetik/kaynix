{
  config,
  lib,
  pkgs,
  ...
}: let
  # BlockBlock and RansomWhere do their work from a root LaunchDaemon under
  # /Library/Objective-See. Nix never sees it: the daemon is planted by the
  # `installer script` artifact of the Homebrew cask, which runs during the
  # Homebrew phase of activation. If that step fails, or the daemon is unloaded
  # by hand, the tool is silently off and the next rebuild does not notice.
  # Re-running the vendor installer is the only supported way to lay it back
  # down, so do exactly that and nothing more. `scripts/objsee-check` reports
  # the parts no script can fix (LuLu's extension approval, Full Disk Access).
  #
  # Keyed by cask name so a cask dropped from modules/homebrew.nix -- which
  # `cleanup = "zap"` then uninstalls -- is not resurrected here.
  daemons = {
    blockblock = {
      label = "com.objective-see.blockblock";
      installer = "BlockBlock Installer.app/Contents/MacOS/BlockBlock Installer";
    };
    ransomwhere = {
      label = "com.objective-see.ransomwhere";
      installer = "RansomWhere Installer.app/Contents/Resources/configure.sh";
    };
  };

  # postActivation is the only hook nix-darwin interpolates after the Homebrew
  # phase, so by the time this runs the cask has had its chance. Every command is
  # non-fatal: the surrounding script runs under `set -e`, and a security tool
  # that failed to install must not abort the switch.
  #
  # RansomWhere needs the bootstrap step in its own right rather than as repair.
  # Its installer copies the plist into /Library/LaunchDaemons but never loads
  # it, which is why the cask carries a second installer artifact doing this.
  healDaemon = cask: daemon: let
    plist = "/Library/LaunchDaemons/${daemon.label}.plist";
    caskroom = "${config.homebrew.prefix}/Caskroom/${cask}";
  in ''
    if [[ ! -f ${plist} ]]; then
      newest=""
      # Glob order is collated, not chronological, so an interrupted upgrade
      # that left two versions staged would otherwise install the older one.
      for installer in "${caskroom}"/*/"${daemon.installer}"; do
        [[ -x "$installer" ]] || continue
        if [[ -z "$newest" || "$installer" -nt "$newest" ]]; then
          newest="$installer"
        fi
      done
      if [[ -n "$newest" ]]; then
        echo "objective-see: ${cask} daemon missing, running its installer" >&2
        "$newest" -install || echo "objective-see: ${cask} installer failed" >&2
      fi
    fi

    if [[ -f ${plist} ]] && ! launchctl print system/${daemon.label} &>/dev/null; then
      echo "objective-see: bootstrapping ${daemon.label}" >&2
      launchctl bootstrap system ${plist} ||
        echo "objective-see: bootstrapping ${daemon.label} failed" >&2
    fi
  '';

  # homebrew.casks coerces each entry into a submodule, so match on `name`.
  declaredCasks = map (cask: cask.name) config.homebrew.casks;
  declared = lib.filterAttrs (cask: _: lib.elem cask declaredCasks) daemons;
in
  lib.mkIf (pkgs.stdenv.isDarwin && config.homebrew.enable) {
    system.activationScripts.postActivation.text =
      lib.concatStringsSep "\n" (lib.mapAttrsToList healDaemon declared);
  }
