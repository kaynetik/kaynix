{ pkgs, username, ... }:

#############################################################
#
#  Secrets Management with agenix
#  Handles encrypted secrets for the system
#
#############################################################

{
  # Enable agenix
  environment.systemPackages = with pkgs; [
    agenix
  ];

  # Example secrets configuration
  # To use this, you'll need to:
  # 1. Generate an SSH key: ssh-keygen -t ed25519 -f ~/.ssh/agenix
  # 2. Create a secrets.nix file with your public keys
  # 3. Create encrypted secret files with: agenix -e secret-name.age
  
  # age.secrets = {
  #   # Example: encrypted SSH key
  #   ssh-key = {
  #     file = ../secrets/ssh-key.age;
  #     owner = username;
  #     group = "staff";
  #   };
  #   
  #   # Example: API token
  #   api-token = {
  #     file = ../secrets/api-token.age;
  #     owner = username;
  #     group = "staff";
  #   };
  # };

  # Example of how to use secrets in your configuration:
  # environment.variables = {
  #   SECRET_API_TOKEN = "$(cat ${config.age.secrets.api-token.path})";
  # };

  # Create secrets directory if it doesn't exist
  system.activationScripts.createSecretsDir.text = ''
    mkdir -p /Users/${username}/.config/nix-darwin/secrets
    chown ${username}:staff /Users/${username}/.config/nix-darwin/secrets
    chmod 700 /Users/${username}/.config/nix-darwin/secrets
  '';
}

