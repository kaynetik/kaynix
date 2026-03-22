{lib, pkgs, ...}:
lib.mkIf pkgs.stdenv.isDarwin {
  # AeroSpace is macOS-only (nix-darwin launchd). No-op on other platforms.
  # Keep start-at-login false (module assertion). Config lives here, not ~/.config/aerospace/aerospace.toml.
  services.aerospace = {
    enable = true;
    settings = {
      after-login-command = [];
      after-startup-command = [
        "exec-and-forget borders active_color=0xffe1e3e4 inactive_color=0xff494d64 width=5.0"
      ];

      exec-on-workspace-change = [
        "/bin/bash"
        "-c"
        "sketchybar --trigger aerospace_workspace_change FOCUSED_WORKSPACE=$AEROSPACE_FOCUSED_WORKSPACE"
      ];

      enable-normalization-flatten-containers = true;
      enable-normalization-opposite-orientation-for-nested-containers = true;
      accordion-padding = 20;
      default-root-container-layout = "tiles";
      default-root-container-orientation = "auto";
      on-focused-monitor-changed = ["move-mouse monitor-lazy-center"];
      automatically-unhide-macos-hidden-apps = true;

      key-mapping.preset = "qwerty";

      gaps = {
        inner.horizontal = 2;
        inner.vertical = 2;
        outer.left = 4;
        outer.right = 4;
        outer.bottom = 4;
        outer.top = [
          {monitor."Built-in Retina Display" = 6;}
          40
        ];
      };

      mode.main.binding = {
        alt-slash = "layout tiles horizontal vertical";
        alt-comma = "layout accordion horizontal vertical";

        alt-h = "focus left";
        alt-j = "focus down";
        alt-k = "focus up";
        alt-l = "focus right";

        alt-shift-h = "move left";
        alt-shift-j = "move down";
        alt-shift-k = "move up";
        alt-shift-l = "move right";

        alt-shift-minus = "resize smart -70";
        alt-shift-equal = "resize smart +70";

        alt-1 = "workspace 1";
        alt-2 = "workspace 2";
        alt-3 = "workspace 3";
        alt-4 = "workspace 4";
        alt-5 = "workspace 5";
        alt-a = "workspace A";
        alt-b = "workspace B";
        alt-g = "workspace G";
        alt-s = "workspace S";
        alt-t = "workspace T";
        alt-x = "workspace X";
        alt-w = "workspace W";

        alt-shift-0 = ''exec-and-forget /bin/bash -c "aerospace focus app-id:com.apple.dt.Xcode && aerospace resize width 80 && aerospace focus app-id:com.apple.iphonesimulator && aerospace resize width 20"'';
        alt-shift-f = "fullscreen";

        alt-shift-1 = "move-node-to-workspace 1";
        alt-shift-2 = "move-node-to-workspace 2";
        alt-shift-3 = "move-node-to-workspace 3";
        alt-shift-4 = "move-node-to-workspace 4";
        alt-shift-5 = "move-node-to-workspace 5";
        alt-shift-a = "move-node-to-workspace A";
        alt-shift-b = "move-node-to-workspace B";
        alt-shift-g = "move-node-to-workspace G";
        alt-shift-s = "move-node-to-workspace S";
        alt-shift-t = "move-node-to-workspace T";
        alt-shift-x = "move-node-to-workspace X";
        alt-shift-w = "move-node-to-workspace W";

        alt-shift-9 = "mode layout-x";
        alt-tab = "workspace-back-and-forth";
        alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
        alt-shift-semicolon = "mode service";
      };

      mode.service.binding = {
        esc = ["reload-config" "mode main"];
        r = ["flatten-workspace-tree" "mode main"];
        f = ["layout floating tiling" "mode main"];
        backspace = ["close-all-windows-but-current" "mode main"];
        alt-shift-h = ["join-with left" "mode main"];
        alt-shift-j = ["join-with down" "mode main"];
        alt-shift-k = ["join-with up" "mode main"];
        alt-shift-l = ["join-with right" "mode main"];
        down = "volume down";
        up = "volume up";
        shift-down = ["volume set 0" "mode main"];
      };

      mode."layout-x".binding = {
        esc = "mode main";
        r = [
          "flatten-workspace-tree"
          ''exec-and-forget /bin/bash -c "aerospace focus app-id:com.apple.dt.Xcode && aerospace resize width 80 && aerospace focus app-id:com.apple.iphonesimulator && aerospace resize width 20"''
          "mode main"
        ];
        a = [
          ''exec-and-forget /bin/bash -c "aerospace focus app-id:com.apple.dt.Xcode && aerospace resize width 80 && aerospace focus app-id:com.apple.iphonesimulator && aerospace resize width 20"''
          "mode main"
        ];
      };

      workspace-to-monitor-force-assignment = {
        X = ["secondary" "main"];
        B = "secondary";
        S = "secondary";
        T = "main";
        "4" = ["secondary" "main"];
        "3" = ["main"];
      };

      on-window-detected = [
        {
          "if".app-id = "com.apple.dt.Xcode";
          run = "move-node-to-workspace X";
        }
        {
          "if".app-id = "com.apple.iphonesimulator";
          run = "move-node-to-workspace X";
        }
      ];
    };
  };
}
