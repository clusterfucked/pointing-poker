{ pkgs, lib, config, inputs, ... }:

{
  packages = with pkgs; [
    nixd
    beam29Packages.hex
    beam29Packages.rebar3
    tailwindcss_4
    esbuild
    inotify-tools
  ];

  tasks."app:deps" = {
    exec = ''
      set -euo pipefail
      mix deps.get
      pnpm --dir assets install --frozen-lockfile
    '';
    before = [
      "devenv:git-hooks:run"
      "devenv:enterTest"
    ];
  };

  enterTest = ''
    set -euo pipefail
    export MIX_ENV=test
    mix deps.unlock --check-unused
    mix deps.compile
    mix compile --warnings-as-errors
    mix format --check-formatted
    mix test
    mix assets.build
  '';

  languages.nix.enable = true;

  languages.elixir = {
    enable = true;
    package = pkgs.beam29Packages.elixir;
    lsp.enable = true;
    lsp.package = pkgs.beam29Packages.elixir-ls;
  };

  languages.javascript = {
    enable = true;
    directory = "./assets";
    pnpm.enable = true;
    pnpm.install.enable = true;
  };

  git-hooks.hooks = {
    check-shebang-scripts-are-executable.enable = true;
    check-symlinks.enable = true;
    check-yaml.enable = true;
    check-merge-conflicts.enable = true;
    check-json.enable = true;
    check-executables-have-shebangs.enable = true;
    check-added-large-files.enable = true;
    check-case-conflicts.enable = true;
    markdownlint.enable = true;
    nixpkgs-fmt.enable = true;
    prettier.enable = true;
    trufflehog.enable = true;
    mix-format.enable = true;
    mixed-line-endings.enable = true;
  };
}
