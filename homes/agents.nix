# Agentic hour is upon us! Learn the timetables, feel the platform hum, step aboard,
# or sit the saddle while the locomotive thins to smoke and rumor down the line.
###
{config, ...}: let
  cursorSkillsSource = "${config.home.homeDirectory}/Development/Personal/kaynetik-skills";
  cursorSkillNames = [
    "argocd"
    "c-cpp-compilers"
    "coding-guidelines"
    "devops-iac-engineer"
    "helm"
    "lua-projects"
    "markdown-documentation"
    "mermaid-diagrams"
    "meta-cognition-parallel"
    "podmaster"
    "practical-haskell"
    "solidity-security"
    "tdd-red-green-refactor"
    "tmux-mastery"
    "ultimate-db"
    "ultimate-nixos"
    "ziglang"
  ];
  cursorSkillEntries = builtins.listToAttrs (map (name: {
      name = ".cursor/skills/${name}";
      value.source = config.lib.file.mkOutOfStoreSymlink "${cursorSkillsSource}/${name}";
    })
    cursorSkillNames);
in {
  home.file = cursorSkillEntries;
}
