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
    "practical-haskell"
    "solidity-security"
    "tdd-red-green-refactor"
    "tmux-mastery"
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
