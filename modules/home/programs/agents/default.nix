# Symlinks ~/.cursor/skills/* and ~/.claude/skills/* to a local checkout of kaynetik-skills.
{
  config,
  lib,
  ...
}: let
  cfg = config.kaynix.programs.agents;

  skillsSource = "${config.home.homeDirectory}/Development/Personal/kaynetik-skills";
  skillNames = [
    "argocd"
    "c-cpp-compilers"
    "coding-guidelines"
    "devops-iac-engineer"
    "flowd-dag"
    "flowd-rules"
    "frontend-design"
    "gh"
    "helm"
    "kustomize"
    "legalizer"
    "lua-projects"
    "markdown-documentation"
    "mermaid-diagrams"
    "meta-cognition-parallel"
    "podmaster"
    "practical-haskell"
    "rca"
    "researcher"
    "solidity-security"
    "svg-gen"
    "tdd-red-green-refactor"
    "tmux-mastery"
    "tokenomics"
    "ultimate-db"
    "ultimate-nixos"
    "ultimate-rust"
    "ultimate-web3"
    "whitepapers"
    "web3-frontend"
    "web3-testing"
    "ziglang"
  ];

  skillPrefixes = [".cursor" ".claude"];

  skillEntries = builtins.listToAttrs (
    lib.concatLists (
      map
      (prefix:
        map
        (name: {
          name = "${prefix}/skills/${name}";
          value.source = config.lib.file.mkOutOfStoreSymlink "${skillsSource}/${name}";
        })
        skillNames)
      skillPrefixes
    )
  );
in {
  options.kaynix.programs.agents = {
    enable = lib.mkEnableOption "Cursor and Claude skill symlinks (kaynetik-skills)";
  };

  config = lib.mkIf cfg.enable {
    home.file = skillEntries;
  };
}
