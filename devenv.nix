{ pkgs, lib, config, inputs, ... }:

{
  packages = [
    pkgs.gitFull
    pkgs.hut
  ];

  languages.javascript.enable = true;
  languages.javascript.yarn.enable = true;
  languages.javascript.yarn.install.enable = false;
}
