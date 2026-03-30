# Symlinks ~/.cursor/skills/* to a local checkout of kaynetik-skills.
{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.agents;

  cursorSkillsSource = "${config.home.homeDirectory}/Development/Personal/kaynetik-skills";
  cursorSkillNames = [
    "argocd"
    "c-cpp-compilers"
    "coding-guidelines"
    "devops-iac-engineer"
    "gh"
    "helm"
    "kustomize"
    "lua-projects"
    "markdown-documentation"
    "mermaid-diagrams"
    "meta-cognition-parallel"
    "podmaster"
    "practical-haskell"
    "solidity-security"
    "svg-gen"
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
  options.kaynix.programs.agents = {
    enable = lib.mkEnableOption "Cursor skill symlinks (kaynetik-skills)";
  };

  config = lib.mkIf cfg.enable {
    home.file = cursorSkillEntries;
  };
}
