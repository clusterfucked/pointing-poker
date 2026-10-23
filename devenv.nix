{ pkgs, lib, config, inputs, ... }:

{
  packages = [
    pkgs.nixd
  ];

  languages.nix.enable = true;
  
  languages.javascript.enable = true;
  languages.javascript.yarn.enable = true;
  languages.javascript.yarn.install.enable = false;
}
